function run_study(stage)
%RUN_STUDY Main entry point for the current static/modal comparison.
% Stages: prepare, train, evaluate, plot, all.
if nargin==0
    fprintf(['Usage:\n' ...
        '  run_study("prepare")  Create/seal designs and FEM training/validation data\n' ...
        '  run_study("train")    Fit all static and modal models\n' ...
        '  run_study("evaluate") Evaluate frozen models on final test cases\n' ...
        '  run_study("plot")     Export MATLAB plots and a PDF summary\n' ...
        '  run_study("all")      Run all stages in the required order\n']);
    return
end
stage=validatestring(char(stage),{'prepare','train','evaluate','plot','all'});
switch stage
    case 'prepare'
        prepare_study_data();
    case 'train'
        train_study_models();
    case 'evaluate'
        evaluate_study_models();
    case 'plot'
        plot_study_results();
    case 'all'
        prepare_study_data();
        train_study_models();
        evaluate_study_models();
        plot_study_results();
end
end
