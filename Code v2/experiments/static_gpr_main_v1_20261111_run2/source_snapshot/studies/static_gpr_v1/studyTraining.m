function studyTraining(root,out,cfg)
assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen', ...
    'Training is forbidden after the freeze.');
train=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
val=studyReference(out,"train","val"); surrogate.validateTrainingSplits(train,val);
selectionFile=fullfile(out,'selections.mat');
assert(isfile(selectionFile) && strcmp(studyHash(selectionFile),strtrim(fileread(fullfile(out,'selections.sha256')))), ...
    'study:SelectionChanged','Selection missing or changed.');
a=load(selectionFile,'selections'); selections=a.selections;
subsets=surrogate.study.nestedTrainingSubsets(train.caseIds,train.caseIds<=810460, ...
    cfg.training_sizes,cfg.seeds_selection);
methods=["mlp","rbf","pod_mlp","pod_gpr"];
for n=1:numel(cfg.training_sizes)
    repeats=3; if cfg.training_sizes(n)==768, repeats=1; end
    for rep=1:repeats
        data=studySubset(train,subsets{n,rep});
        order=circshift(methods,[0,mod(n+rep,4)]);
        for method=order
            c=selections.(method); c.seed=42;
            folder=fullfile(out,'runs',sprintf('n%03d_rep%d_%s_seed%d',numel(data.caseIds),rep,method,c.seed));
            studyFitCheckpoint(folder,method,data,val,c);
        end
        for rank=[2 10 15]
            podFolder=fullfile(out,'bases',sprintf('n%03d_rep%d_rank%d',numel(data.caseIds),rep,rank));
            if ~isfolder(podFolder), mkdir(podFolder); end
            podFile=fullfile(podFolder,'pod.mat');
            pod=[];
            if isfile(podFile) && ~isfile(fullfile(podFolder,'pod.sha256'))
                movefile(podFile,fullfile(podFolder,'pod_incomplete.mat'));
            end
            if isfile(podFile)
                assert(strcmp(studyHash(podFile),strtrim(fileread(fullfile(podFolder,'pod.sha256')))), ...
                    'study:PodChanged','Saved basis changed.'); a=load(podFile,'pod','podSeconds');
                pod=a.pod; podSeconds=a.podSeconds;
            else
                try
                    studyRequireBudget(out,60); studyRequireSpace(out);
                    t=tic; pod=surrogate.models.shared.fitPod(data,rank,"pod_gpr",[]); podSeconds=toc(t);
                    save(podFile,'pod','podSeconds','-v7.3'); writelines(string(studyHash(podFile)),fullfile(podFolder,'pod.sha256'));
                catch err
                    if ~strcmp(err.identifier,'surrogate:pod_gpr:Rank'), rethrow(err); end
                    writelines(string(err.identifier)+": "+string(err.message),fullfile(podFolder,'invalid_rank.txt'));
                end
            end
            for method=["pod_mlp","pod_gpr"]
                c=selections.(method); c.rank=rank; c.seed=42;
                if ~isempty(pod), c.preparedPod=pod; end
                folder=fullfile(out,'controlled',sprintf('n%03d_rep%d_rank%d_%s',numel(data.caseIds),rep,rank,method));
                studyFitCheckpoint(folder,method,data,val,c);
            end
        end
    end
end
fullData=studySubset(train,subsets{end,1});
for method=["mlp","rbf","pod_mlp"]
    for seed=cfg.seeds_network(2:end)'
        c=selections.(method); c.seed=seed;
        folder=fullfile(out,'runs',sprintf('n768_rep1_%s_seed%d',method,seed));
        studyFitCheckpoint(folder,method,fullData,val,c);
    end
end
for repeat=2:3
    c=selections.pod_gpr; c.seed=42;
    folder=fullfile(out,'timing_repeats',sprintf('n768_pod_gpr_repeat%d',repeat));
    studyFitCheckpoint(folder,"pod_gpr",fullData,val,c);
end
[spaceIds,skewIds]=studyDistribution(train,subsets{4,1},cfg.lower,cfg.upper);
save(fullfile(out,'distribution_ids.mat'),'spaceIds','skewIds');
for method=methods
    for kind=["space","skew"]
        ids=spaceIds; if kind=="skew", ids=skewIds; end
        c=selections.(method); c.seed=42;
        folder=fullfile(out,'distribution',sprintf('%s_%s',kind,method));
        studyFitCheckpoint(folder,method,studySubset(train,ids),val,c);
    end
end
writelines("training phases completed",fullfile(out,'training.complete'));
end
