function [model,report,metrics] = runDirectNeuralExample(method,task,config)
%runDirectNeuralExample Train MLP/RBF and evaluate the existing validation split.
%   Example: runDirectNeuralExample("rbf","modal",struct('seed',42)).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
dataFolder=fullfile(root,'data_generation','data',task);
training=surrogate.loadDataset(fullfile(dataFolder,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataFolder,'val.mat'));
surrogate.validateTrainingSplits(training,validation);
[model,report]=surrogate.fitModel(method,training,config);
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
prediction=surrogate.predictModel(model,request);
metrics=surrogate.evaluatePrediction(prediction,validation, ...
    struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
end
