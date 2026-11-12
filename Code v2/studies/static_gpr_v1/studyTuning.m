function studyTuning(root,out,cfg)
% Tune against validation only. Each attempt is an immutable checkpoint.
assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen', ...
    'Tuning is forbidden after the freeze.');
globalTimer=tic; globalStart=string(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
globalCleanup=onCleanup(@()studyRecordSearch(out,"all",globalStart,globalTimer));
train=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
val=studyReference(out,"tune","val"); surrogate.validateTrainingSplits(train,val);
subsets=surrogate.study.nestedTrainingSubsets(train.caseIds,train.caseIds<=810460, ...
    cfg.training_sizes,cfg.seeds_selection); data=studySubset(train,subsets{4,1});
methods=["mlp","rbf","pod_mlp","pod_gpr"]; selections=struct;
for method=methods
    candidates=studyCandidates(method); scores=nan(numel(candidates),1); p95=scores; attempted=0;
    familyFolder=fullfile(out,'tuning',method); if ~isfolder(familyFolder), mkdir(familyFolder); end
    sessionsFile=fullfile(familyFolder,'search_sessions.csv'); previous=0;
    if isfile(sessionsFile), old=readtable(sessionsFile,'TextType','string'); previous=sum(old.elapsed_seconds); end
    timer=tic; startUtc=string(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
    searchCleanup=onCleanup(@()studyRecordSearch(familyFolder,method,startUtc,timer));
    for k=1:numel(candidates)
        folder=fullfile(out,'tuning',method,sprintf('candidate_%03d_seed42',k));
        if ~isfile(fullfile(folder,'result.mat')) && previous+toc(timer)>=0.6*cfg.search_budget_seconds_per_family, break; end
        result=studyFitCheckpoint(folder,method,data,val,candidates{k});
        attempted=attempted+1;
        if result.status=="ok", scores(k)=result.meanError; p95(k)=result.p95Error; end
    end
    valid=find(isfinite(scores)); assert(~isempty(valid),'study:NoCandidate','No valid candidate for %s.',method);
    [~,order]=sortrows([scores(valid),p95(valid),valid],[1 2 3]); best=valid(order(1:min(2,numel(order))));
    confirmation=nan(numel(best),1); confirmationP95=confirmation;
    for n=1:numel(best)
        k=best(n); vals=[]; tails=[];
        if method=="pod_gpr"
            vals=scores(k); tails=p95(k);
        else
            for seed=cfg.seeds_network(:)'
                c=candidates{k}; c.seed=seed;
                folder=fullfile(out,'tuning',method,sprintf('candidate_%03d_seed%d',k,seed));
                if ~isfile(fullfile(folder,'result.mat')) && previous+toc(timer)>=cfg.search_budget_seconds_per_family, break; end
                result=studyFitCheckpoint(folder,method,data,val,c);
                if seed~=42, attempted=attempted+1; end
                if result.status=="ok", vals(end+1)=result.meanError; tails(end+1)=result.p95Error; end %#ok<AGROW>
            end
        end
        if method=="pod_gpr" || numel(vals)==numel(cfg.seeds_network)
            confirmation(n)=mean(vals); confirmationP95(n)=mean(tails);
        end
    end
    valid=find(isfinite(confirmation));
    assert(~isempty(valid),'study:ConfirmationIncomplete', ...
        'No candidate with all required confirmations for %s within budget.',method);
    [~,order]=sortrows([confirmation(valid),confirmationP95(valid),best(valid)],[1 2 3]);
    winner=best(valid(order(1))); selections.(method)=candidates{winner};
    summary=table((1:numel(candidates))',scores,p95,'VariableNames',{'Candidate','MeanError','P95Error'});
    folder=fullfile(out,'tuning',method); writetable(summary,fullfile(folder,'candidate_summary.csv'));
    info=struct('attempted',attempted,'candidates',numel(candidates),'spentSeconds',previous+toc(timer), ...
        'winner',winner,'confirmedCandidates',best,'confirmation',confirmation,'confirmationP95',confirmationP95);
    save(fullfile(folder,'search_summary.mat'),'info');
    clear searchCleanup
end
selectionFile=fullfile(out,'selections.mat');
if isfile(selectionFile)
    old=load(selectionFile,'selections'); assert(isequaln(old.selections,selections),'study:SelectionChanged','Selection changed on resume.');
else
    save(selectionFile,'selections','-v7.3');
end
writelines(string(studyHash(selectionFile)),fullfile(out,'selections.sha256'));
clear globalCleanup
end
