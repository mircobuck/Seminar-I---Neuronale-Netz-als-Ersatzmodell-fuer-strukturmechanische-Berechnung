function data = loadDataset(filePath)
%loadDataset Load and validate an existing Code v2 split.
% data is the variable for the actual datastructure, T is the design table 
[data, T] = loadFemDataset(filePath);
% gives the contract version and the parameter units of the dataset
c = surrogate.contract(data.modality);
% version of the contract and the parameter units of the dataset
data.contractVersion = c.version;
data.parameterUnits = c.parameterUnits;
% check data 
surrogate.validateDataset(data);
% A matching header alone does not establish that this CSV belongs to the MAT. it is checked
assert(ismember('id',T.Properties.VariableNames) && ...
    ismember('split',T.Properties.VariableNames) && ...
    numel(unique(T.id))==height(T), ...
    'surrogate:data:Design','Invalid or ambiguous design IDs.');
[found,rows]=ismember(data.caseIds,T.id);
assert(all(found) && all(string(T.split(rows))==string(data.split)), ...
    'surrogate:data:Design','Design IDs or splits do not match the MAT file.');
X=T{rows,cellstr(c.parameterNames)};
assert(isequal(size(X),size(data.inputParameters)) && ...
    all(abs(X-data.inputParameters)<=1e-14*max(1,abs(data.inputParameters)),'all'), ...
    'surrogate:data:Design','Design parameters do not match the MAT file.');
end
