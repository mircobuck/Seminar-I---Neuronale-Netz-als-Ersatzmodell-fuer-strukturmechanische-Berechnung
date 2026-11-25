function prediction = predictModel(model,request)
%predictModel Predict physical quantities without FEM or reference labels.
% c = surrogate.contract(model.task) returns the contract for the model's task
c=surrogate.contract(model.task);
if c.task=="static"
assert(isequal(size(model.normalizedGridCoordinates),[3,525]) && ...
    max(abs(model.normalizedGridCoordinates-c.grid),[],'all')<1e-12, ...
    'surrogate:predict:Grid','Model grid differs from the contract.');
else
    assert(isequal(model.modeIndices,c.modeIndices),'surrogate:predict:Modes','Model frequency ranks differ.');
end
% data of the cantilever
X=request.inputParameters;
assert(isequal(reshape(string(request.parameterNames),1,[]),c.parameterNames) && ...
    isequal(reshape(string(request.parameterUnits),1,[]),c.parameterUnits), ...
    'surrogate:predict:Parameters','Parameter names, order or units differ.');
% wright id
ids=request.caseIds;
assert(isnumeric(X) && isreal(X) && ismatrix(X) && size(X,2)==6 && ...
    size(X,1)>0 && all(isfinite(X),'all') && isnumeric(ids) && ...
    isequal(size(ids),[size(X,1),1]) && all(isfinite(ids)) && ...
    all(ids==fix(ids)) && numel(unique(ids))==numel(ids), ...
    'surrogate:predict:Inputs','Expected finite N-by-6 inputs and unique N-by-1 integer IDs.');
if c.task=="modal"
    assert(all(X(:,[1:4 6])>0,'all') && all(X(:,5)>-1 & X(:,5)<.5), ...
        'surrogate:predict:Inputs','Invalid modal geometry, material or density.');
end
% methodname
id=string(model.methodId);
assert(isscalar(id) && any(id==["mlp","rbf","pod_mlp","pod_gpr"]), ...
    'surrogate:predict:Method','Invalid method identifier.');
% build functionname    
fn="surrogate.models."+id+".predict";
assert(~isempty(which(fn)),'surrogate:predict:Method','Missing method implementation: %s',id);
% calc Y with trained model and inputs
Y=feval(char(fn),model.state,X);
% right size and type of the output
expected=[1575,size(X,1)];
if c.task=="modal", expected=[6,size(X,1)]; end
assert(isnumeric(Y) && isreal(Y) && isequal(size(Y),expected) && all(isfinite(Y),'all'), ...
    'surrogate:predict:Output','Invalid output dimensions or values.');
% is a prediction struct with the contract version, task, output unit and the caseIds
prediction=struct('contractVersion',c.version,'task',c.task,'outputUnit',c.outputUnit,'caseIds',ids);
if c.task=="static"
    prediction.displacementFields=Y;
    prediction.normalizedGridCoordinates=c.grid;
else
    prediction.frequencyHz=Y';
    prediction.modeIndices=c.modeIndices;
end
end
