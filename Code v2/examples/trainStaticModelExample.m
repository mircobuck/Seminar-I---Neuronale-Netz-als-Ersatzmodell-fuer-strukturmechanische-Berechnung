function [model,report,metrics] = trainStaticModelExample(method,trainingFile,validationFile)
%trainStaticModelExample Fit one small model and evaluate validation only.
arguments
    method (1,1) string
    trainingFile (1,1) string
    validationFile (1,1) string
end
root=fileparts(fileparts(mfilename('fullpath')));
oldPath=path;
cleanup=onCleanup(@()path(oldPath)); %#ok<NASGU>
addpath(root);
train=surrogate.loadDataset(trainingFile);
val=surrogate.loadDataset(validationFile);
surrogate.validateTrainingSplits(train,val);
cfg=struct('seed',42,'datasetId',"example",'hiddenWidth',64,'hiddenLayers',2, ...
    'maxEpochs',200,'miniBatchSize',32,'learningRate',.001,'rank',2, ...
    'lossMode',"weighted_field_mse");
[model,report]=surrogate.fitModel(method,train,cfg);
request=struct('inputParameters',val.inputParameters,'parameterNames',val.parameterNames, ...
    'parameterUnits',val.parameterUnits,'caseIds',val.caseIds);
prediction=surrogate.predictModel(model,request);
metrics=surrogate.evaluatePrediction(prediction,val, ...
    struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
disp(surrogate.study.summarizeErrors(metrics.relativeWeightedFieldError));
end
