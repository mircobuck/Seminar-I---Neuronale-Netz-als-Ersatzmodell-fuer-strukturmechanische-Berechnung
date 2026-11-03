% Compare saved models on the same static validation split.
% Edit this list after adding further contract-compatible model artifacts.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
modelFile=fullfile(root,'..','..','pod_mlp_pilot.mat');
model=surrogate.loadModel(modelFile);
assert(string(model.methodId)=="pod_mlp" && ...
    isfield(model.state,'settings') && model.state.settings.hiddenWidth==64, ...
    'surrogate:plot:Label','POD_MLP_ADAM_64 requires a POD-MLP with 64 hidden neurons.');
models=struct('label',"POD_MLP_ADAM_64",'model',model);
% Add more entries here once their models implement the surrogate contract.

reference=surrogate.loadDataset(fullfile(root,'data_generation','data','static','val.mat'));
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
[figures,results]=surrogate.plotStaticComparison(models,reference,metricConfig);
