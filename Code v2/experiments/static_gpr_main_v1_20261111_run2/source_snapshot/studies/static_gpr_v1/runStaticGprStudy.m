function runStaticGprStudy(phase,out)
%runStaticGprStudy Run a single reproducible phase of the static study.
studyRoot=fileparts(mfilename('fullpath')); root=fileparts(fileparts(studyRoot));
addpath(root,studyRoot); phase=string(phase); out=char(out);
cfg=jsondecode(fileread(fullfile(studyRoot,'study_config.json')));
if phase=="init"
    if ~isfolder(out)
        mkdir(out); T=studySources(root,studyRoot); writetable(T,fullfile(out,'source_manifest.csv'));
    else
        assert(isfile(fullfile(out,'source_manifest.csv')),'study:IncompleteInit', ...
            'Existing directory lacks a source manifest; choose a new directory.');
        studyVerify(root,studyRoot,out); T=studySources(root,studyRoot);
    end
    snapshot=fullfile(out,'source_snapshot'); if ~isfolder(snapshot), mkdir(snapshot); end
    for k=1:height(T)
        source=char(T.Path(k)); [~,~,ext]=fileparts(source);
        if ~any(string(ext)==[".m",".json",".md",".py"]), continue; end
        relative=extractAfter(string(source),strlength(string(root))+1);
        target=fullfile(snapshot,relative); parent=fileparts(target); if ~isfolder(parent), mkdir(parent); end
        if ~isfile(target), copyfile(source,target); end
        assert(strcmp(studyHash(source),studyHash(target)),'study:Snapshot','Snapshot mismatch.');
    end
    designFile=fullfile(out,'candidate_design.mat'); seal=fullfile(out,'candidate_design.sha256');
    if isfile(designFile) && ~isfile(seal)
        movefile(designFile,fullfile(out,'candidate_design_incomplete.mat'));
        csv=fullfile(out,'candidate_design.csv');
        if isfile(csv), movefile(csv,fullfile(out,'candidate_design_incomplete.csv')); end
    end
    if ~isfile(designFile)
        studyDesign(root,out,cfg); writelines(string(studyHash(designFile)),seal);
    end
    assert(isfile(seal) && strcmp(studyHash(designFile),strtrim(fileread(seal))), ...
        'study:DesignChanged','Candidate design changed.');
    if ~isfile(fullfile(out,'environment.mat'))
        python=fullfile(getenv('LOCALAPPDATA'),'Programs','Python','Python312','python.exe');
        assert(isfile(python),'study:PlotPython','The configured Python interpreter is unavailable.');
        command=sprintf('"%s" -c "import sys,matplotlib;print(sys.version.split()[0],matplotlib.__version__)"',python);
        [pythonStatus,pythonVersions]=system(command);
        assert(pythonStatus==0,'study:PlotPython','Matplotlib unavailable: %s',pythonVersions);
        nowPosix=posixtime(datetime('now','TimeZone','UTC'));
        metadata=struct('startedAt',string(datetime('now','TimeZone','UTC')), ...
            'startedPosix',nowPosix,'plotPython',string(python),'plotVersions',string(strtrim(pythonVersions)), ...
            'matlabVersion',string(version),'products',{ver},'computer',string(computer), ...
            'cpu',string(getenv('PROCESSOR_IDENTIFIER')), ...
            'pilotSpentSeconds',max(cfg.pilot_spent_seconds,nowPosix-cfg.budget_origin_posix), ...
            'budgetSeconds',cfg.total_budget_seconds);
        save(fullfile(out,'environment.mat'),'metadata');
    end
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
    case "report"
        studyReport(out,cfg);
        python=fullfile(getenv('LOCALAPPDATA'),'Programs','Python','Python312','python.exe');
        assert(isfile(python),'study:PlotPython','The configured Python interpreter is unavailable.');
        command=sprintf('"%s" "%s" "%s"',python,fullfile(studyRoot,'studyPlots.py'),out);
        [status,message]=system(command);
        assert(status==0,'study:PlotFailed','Plotting failed: %s',message);
        writelines("report and figures completed",fullfile(out,'report.complete'));
    otherwise, error('study:Phase','Unknown phase: %s',phase);
end
end
