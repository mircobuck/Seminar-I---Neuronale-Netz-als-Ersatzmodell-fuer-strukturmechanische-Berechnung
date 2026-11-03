function [model,report,metrics] = podMlpExample(modelFile)
%podMlpExample Train and validate a static POD-MLP and save its artifact.
%   Run from Code v2: podMlpExample('path/to/new_model.mat')
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
dataDir=fullfile(root,'data_generation','data','static');
training=surrogate.loadDataset(fullfile(dataDir,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataDir,'val.mat'));
surrogate.validateTrainingSplits(training,validation);

% The training split alone determines the POD basis and normalization.
config=struct('seed',42,'datasetId',"static-data-generation-v1", ...
    'rank',10,'hiddenWidth',64,'maxEpochs',200, ...
    'miniBatchSize',32,'learningRate',1e-3);
[model,report]=surrogate.fitModel("pod_mlp",training,config);
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames, ...
    'parameterUnits',validation.parameterUnits,'caseIds',validation.caseIds);
prediction=surrogate.predictModel(model,request);
metrics=surrogate.evaluatePrediction(prediction,validation, ...
    struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
fprintf('Validation weighted relative field error: median %.2f %%, mean %.2f %%\n', ...
    100*median(metrics.relativeWeightedFieldError), ...
    100*mean(metrics.relativeWeightedFieldError));
surrogate.saveModel(modelFile,model);
end
