function [model,report] = fitModel(methodId,trainingData,config)
%fitModel Fit one registered implementation on a training split.
%   Expects contract data from surrogate.loadDataset or validateDataset.
assert(string(trainingData.split)=="train",'surrogate:fit:Split', ...
    'Only a training split may be passed to fitModel.');
methodId=string(methodId);
assert(isscalar(methodId) && ~isempty(regexp(char(methodId),'^[a-z][a-z0-9_]*$','once')), ...
    'surrogate:fit:Method','Invalid method identifier.');
fn="surrogate.models."+methodId+".fit";
assert(~isempty(which(fn)),'surrogate:fit:Method','Unknown method: %s',methodId);
stateBefore=rng; cleanup=onCleanup(@()rng(stateBefore));
rng(double(config.seed),'twister');
[state,report]=feval(char(fn),trainingData,config);
c=surrogate.contract(trainingData.modality);
model=struct('contractVersion',c.version,'methodId',methodId,'task',c.task, ...
    'parameterNames',c.parameterNames,'parameterUnits',c.parameterUnits, ...
    'outputUnit',c.outputUnit,'config',config,'trainingCaseIds',trainingData.caseIds, ...
    'matlabVersion',string(version),'state',state);
if c.task=="static", model.normalizedGridCoordinates=c.grid; end
end
