function output = runStaticStudy(phase, configFile, localFile)
%runStaticStudy Execute one explicit phase of the static four-method comparison.
% Relative configuration and data paths are always relative to Code v2.
arguments
    phase (1,1) string = "help"
    configFile (1,1) string = "workflows/static_comparison/configs/study.json"
    localFile (1,1) string = "workflows/static_comparison/configs/local.example.json"
end
output = [];
% prints the syntx of the function. return terminates the function without
% doing something
if phase == "help"
    fprintf(['Static comparison: mlp, rbf, pod_mlp, pod_gpr; 6 inputs, 1575 outputs.\n' ...
        'runStaticStudy(phase, configFile, localFile)\n' ...
        'Phases: init, generate, tune, train, freeze, evaluate, benchmark, report.\n' ...
        'Run each phase explicitly; report only reads existing results.\n' ...
        'All relative paths are resolved from Code v2, never from pwd.\n']);
    return
end
% Add the study and FEM folders to the MATLAB path.
setupProject;
%root is the path to the folder
root = fileparts(mfilename('fullpath'));

% some data management
% reads both json files configfile and localfile
cfg = staticstudy.configure(root, configFile, localFile);
out = cfg.paths.output_dir;

% Prepare the study run: check resources and data, create the output folder,
% and record the configuration and environment.
if phase == "init"
    staticstudy.initialize(root,out,cfg);
    output = out;
    return
end
% verifies that nothing changed in the code during studyexecution
staticstudy.verify(root,out,cfg);
% makes sure we have the right model for evaluate, benchmark and report
frozenPhase = any(phase == ["evaluate","benchmark","report"]);
if frozenPhase
    staticstudy.checkFrozen(out);
end


switch phase
    case "generate"
        % checks if file is already frozen
        assert(~isfile(fullfile(out,'freeze_manifest.csv')), ...
            'study:AlreadyFrozen','Reference generation is forbidden after freeze.');
        % generates validation and testdata
        if cfg.reference_mode == "generate"
            staticstudy.generate(root,out,cfg,["val","interpolation","extrapolation"]);
        end
        % checks test and validationdata
        staticstudy.validateReferences(out,cfg);
    % tests the candidates of the json file and takes the best one for val data     
    case "tune"
        staticstudy.validateReferences(out,cfg);
        staticstudy.tuning(root,out,cfg);
    % trains the model with the parameters from tuning
    case "train"
        staticstudy.validateReferences(out,cfg);
        staticstudy.training(root,out,cfg);
    % freeze makes sure that trained models which trained models are now
    % for evaluating, benchmark etc...
    case "freeze"
        staticstudy.freeze(root,out,cfg);
    % test data is compared with actual FEM Solutions    
    case "evaluate"
        staticstudy.evaluation(root,out,cfg);
    % benchmarking the time to solve with FEM and also surrogate models    
    case "benchmark"
        staticstudy.benchmark(root,out,cfg);
    % evaluations are saved as tables, summary and figures    
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
