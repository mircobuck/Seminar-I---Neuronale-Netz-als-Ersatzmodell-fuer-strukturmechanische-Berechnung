function runStatic768Study(outputRoot)
%runStatic768Study - Extend static training data and run the 768-case stage
%   runStatic768Study(OUTPUTROOT) adds static FEM cases in the existing data
%   folder and evaluates widths 64 and 128 with one to six hidden layers.
%   Each architecture uses seeds 42, 43, and 44 and the existing validation.

root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'scripts','matlab'),fullfile(root,'examples'));
if ~isfolder(outputRoot), mkdir(outputRoot); end
diary(fullfile(outputRoot,'run.log'));
cleanup=onCleanup(@()diary('off'));
try
    writelines("FEM generation running",fullfile(outputRoot,'STATUS.txt'));
    extend_static_training_768;
    training=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
    validation=surrogate.loadDataset(fullfile(root,'data_generation','data','static','val.mat'));
    assert(numel(training.caseIds)==768 && numel(validation.caseIds)==12);
    surrogate.validateTrainingSplits(training,validation);
    writelines("FEM complete; 36 POD-MLP training runs running",fullfile(outputRoot,'STATUS.txt'));
    combined=table;
    for width=[64 128]
        for layers=1:6
            folder=fullfile(outputRoot,sprintf('width_%d_layers_%d',width,layers));
            if isfile(fullfile(folder,'learning_curve.mat'))
                a=load(fullfile(folder,'learning_curve.mat'),'summary','details'); summary=a.summary;
                if ~ismember('MeanAbsoluteError_m',summary.Properties.VariableNames)
                    summary.MeanAbsoluteError_m=arrayfun( ...
                        @(detail)mean(detail.metrics.absoluteWeightedFieldError),a.details(:));
                end
                summary=summary(:,{'TrainingCases','Seed','MeanAbsoluteError_m', ...
                    'MedianRelativePercent','P95RelativePercent','UndefinedCount'});
            else
                if isfolder(folder)
                    % Keep partial models for diagnosis; retry in a fresh folder.
                    movefile(folder,[folder,'_interrupted_',char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
                end
                summary=runPodMlpLearningCurve(folder,layers,width,768,false);
            end
            assert(height(summary)==3 && all(summary.TrainingCases==768));
            summary.NeuronsPerLayer=repmat(width,height(summary),1);
            summary.HiddenLayers=repmat(layers,height(summary),1);
            combined=[combined;summary]; %#ok<AGROW>
            writetable(combined,fullfile(outputRoot,'summary_768.csv'));
            close all;
        end
    end
    writelines("COMPLETE: 384 new static FEM cases and 36 POD-MLP runs",fullfile(outputRoot,'STATUS.txt'));
catch exception
    writelines(string(getReport(exception,'extended','hyperlinks','off')),fullfile(outputRoot,'ERROR.txt'));
    writelines("FAILED - see ERROR.txt and run.log; rerun to resume",fullfile(outputRoot,'STATUS.txt'));
    rethrow(exception)
end
end
