function prediction = predictModel(model,request)
%predictModel Predict physical quantities without FEM or reference labels.
c=surrogate.contract(model.task);
assert(isequal(size(model.normalizedGridCoordinates),[3,525]) && ...
    max(abs(model.normalizedGridCoordinates-c.grid),[],'all')<1e-12, ...
    'surrogate:predict:Grid','Model grid differs from the contract.');
X=request.inputParameters;
assert(isequal(reshape(string(request.parameterNames),1,[]),c.parameterNames) && ...
    isequal(reshape(string(request.parameterUnits),1,[]),c.parameterUnits), ...
    'surrogate:predict:Parameters','Parameter names, order or units differ.');
ids=request.caseIds;
id=string(model.methodId);
assert(isscalar(id) && any(id==["mlp","rbf","pod_mlp","pod_gpr"]), ...
    'surrogate:predict:Method','Invalid method identifier.');
fn="surrogate.models."+id+".predict";
assert(~isempty(which(fn)),'surrogate:predict:Method','Missing method implementation: %s',id);
Y=feval(char(fn),model.state,X);
expected=[1575,size(X,1)];
assert(isnumeric(Y) && isreal(Y) && isequal(size(Y),expected) && all(isfinite(Y),'all'), ...
    'surrogate:predict:Output','Invalid output dimensions or values.');
prediction=struct('contractVersion',c.version,'task',c.task,'outputUnit',c.outputUnit,'caseIds',ids);
prediction.displacementFields=Y;
prediction.normalizedGridCoordinates=c.grid;
end
