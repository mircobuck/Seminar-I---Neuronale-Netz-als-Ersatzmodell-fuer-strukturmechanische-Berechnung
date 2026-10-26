function c=hybridContract(physics,transfer,pod,preprocessing,timing)
%HYBRIDCONTRACT Validate prerequisites for a future correction-field model.
assert(all(isfield(physics,{'id','version','loads','boundaryConditions'})));
assert(all(isfield(transfer,{'sourceSpace','targetSpace','method'})));
assert(all(isfield(pod,{'differenceBasis','trainingIDs'})));
assert(isfield(preprocessing,'trainingIDs') && isequal(pod.trainingIDs,preprocessing.trainingIDs));
assert(all(isfield(timing,{'physics','transfer','regression','reconstruction'})));
c=struct('schema',"hybrid-field-v1",'physics',physics,'transfer',transfer, ...
    'pod',pod,'preprocessing',preprocessing,'timing',timing);
end
