%% function gets the drei inputs: (the wanted method, the training data and the configuration)

function [model,report] = fitModel(methodId,trainingData,config)

%fitModel Fit one registered implementation on a training split.
%   Expects contract data from surrogate.loadDataset or validateDataset.
% Is it really a trainingset?
assert(string(trainingData.split)=="train",'surrogate:fit:Split', ...
    'Only a training split may be passed to fitModel.');    
methodId=string(methodId);
% check if wright mehodname
assert(isscalar(methodId) && any(methodId==["mlp","rbf","pod_mlp","pod_gpr"]), ...
    'surrogate:fit:Method','Invalid method identifier.');
% build the right methodname and check if it is registered in the path    
fn="surrogate.models."+methodId+".fit";
assert(~isempty(which(fn)),'surrogate:fit:Method','Unknown method: %s',methodId);
stateBefore=rng; cleanup=onCleanup(@()rng(stateBefore));
% seed the random number generator for reproducibility
rng(double(config.seed),'twister');
% feval calls the function handle of the method with the training data and the configuration
[state,report]=feval(char(fn),trainingData,config);
% build a struct with the model and some meta data - model comes from the feval function call
c=surrogate.contract(trainingData.modality);
model=struct('contractVersion',c.version,'methodId',methodId,'task',c.task, ...
    'parameterNames',c.parameterNames,'parameterUnits',c.parameterUnits, ...
    'outputUnit',c.outputUnit,'config',config,'trainingCaseIds',trainingData.caseIds, ...
    'matlabVersion',string(version),'state',state);
if c.task=="static"
    model.normalizedGridCoordinates=c.grid;
else
    model.modeIndices=c.modeIndices;
end
end
