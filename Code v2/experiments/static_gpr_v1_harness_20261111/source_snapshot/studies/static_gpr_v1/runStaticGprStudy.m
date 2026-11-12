function runStaticGprStudy(phase,out)
%runStaticGprStudy Run a single reproducible phase of the static study.
studyRoot=fileparts(mfilename('fullpath')); root=fileparts(fileparts(studyRoot));
addpath(root,studyRoot); phase=string(phase); out=char(out);
cfg=jsondecode(fileread(fullfile(studyRoot,'study_config.json')));
if phase=="init"
    assert(~isfolder(out),'study:Exists','Use a new study output directory.'); mkdir(out);
    T=studySources(root,studyRoot); writetable(T,fullfile(out,'source_manifest.csv'));
    snapshot=fullfile(out,'source_snapshot'); mkdir(snapshot);
    for k=1:height(T)
        source=char(T.Path(k)); [~,~,ext]=fileparts(source);
        if ~any(string(ext)==[".m",".json",".md"]), continue; end
        relative=extractAfter(string(source),strlength(string(root))+1);
        target=fullfile(snapshot,relative); parent=fileparts(target); if ~isfolder(parent), mkdir(parent); end
        copyfile(source,target); assert(strcmp(studyHash(source),studyHash(target)),'study:Snapshot','Snapshot mismatch.');
    end
    studyDesign(root,out,cfg);
    writelines(string(studyHash(fullfile(out,'candidate_design.mat'))),fullfile(out,'candidate_design.sha256'));
    metadata=struct('startedAt',string(datetime('now','TimeZone','UTC')), ...
        'startedPosix',posixtime(datetime('now','TimeZone','UTC')), ...
        'matlabVersion',string(version),'products',{ver},'computer',string(computer), ...
        'cpu',string(getenv('PROCESSOR_IDENTIFIER')),'pilotSpentSeconds',cfg.pilot_spent_seconds, ...
        'budgetSeconds',cfg.total_budget_seconds);
    save(fullfile(out,'environment.mat'),'metadata');
    return
end
studyVerify(root,studyRoot,out);
switch phase
    case "generate"
        assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen','Cannot generate after freeze.');
        studyGenerate(root,out,cfg,["val","interpolation","extrapolation"]);
    case "tune", studyTuning(root,out,cfg);
    case "train", studyTraining(root,out,cfg);
    case "freeze", studyFreeze(root,studyRoot,out);
    case "evaluate", studyEvaluation(root,out,cfg);
    case "report", studyReport(out,cfg);
    otherwise, error('study:Phase','Unknown phase: %s',phase);
end
end
