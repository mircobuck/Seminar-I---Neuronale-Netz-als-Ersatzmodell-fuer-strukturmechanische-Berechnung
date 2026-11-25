function output = runModalStudy(phase,configFile,localFile)
%runModalStudy Explicit phases for the six-frequency, four-method comparison.
arguments
    phase (1,1) string = "help"
    configFile (1,1) string = "workflows/modal_comparison/configs/study.json"
    localFile (1,1) string = "workflows/modal_comparison/configs/local.example.json"
end
output=[];
if phase=="help"
    fprintf('runModalStudy(phase, configFile, localFile)\n');
    fprintf('Phases: init, generate, tune, train, freeze, evaluate, benchmark, report.\n');
    fprintf('Six ranked frequencies in Hz; mlp, rbf, pod_mlp, pod_gpr. No phase runs automatically.\n');
    return
end
assert(any(phase==["init","generate","tune","train","freeze","evaluate","benchmark","report"]), ...
    'modalstudy:Phase','Unknown phase.');
setupProject;
root=fileparts(mfilename('fullpath'));
cfg=modalstudy.configure(root,configFile,localFile); out=cfg.paths.output_dir;
if phase=="init"
    modalstudy.initialize(root,out,cfg); output=out; return
end
modalstudy.verify(root,out,cfg);
frozen=any(phase==["evaluate","benchmark","report"]);
if frozen
    modalstudy.checkFrozen(out);
elseif any(phase==["generate","tune","train"])
    assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen','Run is frozen.');
end
switch phase
    case "generate", modalstudy.generate(out,cfg);
    case "tune", modalstudy.tuning(out,cfg);
    case "train", modalstudy.training(out,cfg);
    case "freeze", modalstudy.freeze(out,cfg);
    case "evaluate", modalstudy.evaluation(out,cfg);
    case "benchmark", modalstudy.benchmark(out,cfg);
    case "report", modalstudy.report(out,cfg);
end
modalstudy.verify(root,out,cfg);
if frozen, modalstudy.checkFrozen(out); end
output=out;
end
