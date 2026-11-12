function output = runStaticStudy(phase, configFile, localFile)
%runStaticStudy Execute one explicit phase of the static four-method comparison.
% Relative configuration and data paths are always relative to Code v2.
arguments
    phase (1,1) string = "help"
    configFile (1,1) string = "workflows/static_comparison/configs/study.json"
    localFile (1,1) string = "workflows/static_comparison/configs/local.example.json"
end
output = [];
if phase == "help"
    fprintf(['Static comparison: mlp, rbf, pod_mlp, pod_gpr; 6 inputs, 1575 outputs.\n' ...
        'runStaticStudy(phase, configFile, localFile)\n' ...
        'Phases: init, generate, tune, train, freeze, evaluate, benchmark, report.\n' ...
        'Run each phase explicitly; report only reads existing results.\n' ...
        'All relative paths are resolved from Code v2, never from pwd.\n']);
    return
end
cleanup = setupProject; %#ok<NASGU>
root = fileparts(mfilename('fullpath'));
cfg = staticstudy.configure(root, configFile, localFile);
out = cfg.paths.output_dir;
if phase == "init"
    staticstudy.initialize(root,out,cfg);
    output = out;
    return
end
staticstudy.verify(root,out,cfg);
frozenPhase = any(phase == ["evaluate","benchmark","report"]);
if frozenPhase
    staticstudy.checkFrozen(out);
end
switch phase
    case "generate"
        assert(~isfile(fullfile(out,'freeze_manifest.csv')), ...
            'study:AlreadyFrozen','Reference generation is forbidden after freeze.');
        if cfg.reference_mode == "generate"
            staticstudy.generate(root,out,cfg,["val","interpolation","extrapolation"]);
        end
        staticstudy.validateReferences(out,cfg);
    case "tune"
        staticstudy.validateReferences(out,cfg);
        staticstudy.tuning(root,out,cfg);
    case "train"
        staticstudy.validateReferences(out,cfg);
        staticstudy.training(root,out,cfg);
    case "freeze"
        staticstudy.freeze(root,out,cfg);
    case "evaluate"
        staticstudy.evaluation(root,out,cfg);
    case "benchmark"
        staticstudy.benchmark(root,out,cfg);
    case "report"
        staticstudy.report(out,cfg);
        command = sprintf('"%s" "%s" "%s"',cfg.paths.python, ...
            fullfile(root,'workflows','static_comparison','studyPlots.py'),out);
        [status,message] = system(command);
        assert(status==0,'study:PlotFailed','Plotting failed: %s',message);
        staticstudy.comparePrevious(out,cfg);
        writelines("report and figures completed",fullfile(out,'report.complete'));
    otherwise
        error('study:Phase','Unknown phase: %s. Call runStaticStudy without arguments for help.',phase);
end
% Full checks surround each phase, not every model fit or reference read.
staticstudy.verify(root,out,cfg);
if frozenPhase
    staticstudy.checkFrozen(out);
end
output = out;
end
