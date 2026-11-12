function result = evaluatePrediction(prediction,reference,metricConfig)
%evaluatePrediction Evaluate aligned predictions with explicit zero thresholds.
%   Expects contract data from surrogate.loadDataset or validateDataset.
assert(isnumeric(metricConfig.staticReferenceFloor) && isscalar(metricConfig.staticReferenceFloor) && ...
    isfinite(metricConfig.staticReferenceFloor) && metricConfig.staticReferenceFloor>=0, ...
    'surrogate:evaluate:Config','A finite nonnegative static reference floor is required.');
c=surrogate.contract(reference.modality);
assert(isequal(string(prediction.contractVersion),c.version) && ...
    isequal(string(prediction.task),c.task) && isequal(string(prediction.outputUnit),c.outputUnit), ...
    'surrogate:evaluate:Prediction','Prediction metadata does not match reference.');
assert(isequal(prediction.caseIds,reference.caseIds), ...
    'surrogate:evaluate:CaseIds','Prediction and reference case IDs or order differ.');
n=size(reference.inputParameters,1);
result=struct('contractVersion',c.version,'task',c.task, ...
    'split',string(reference.split),'caseIds',reference.caseIds,'metricConfig',metricConfig);
assert(isequal(prediction.normalizedGridCoordinates,reference.normalizedGridCoordinates), ...
    'surrogate:evaluate:Grid','Prediction grid differs from reference.');
Y=prediction.displacementFields; R=reference.displacementFields;
assert(isnumeric(Y) && isreal(Y) && isequal(size(Y),[1575,n]) && all(isfinite(Y),'all'), ...
    'surrogate:evaluate:Output','Invalid static prediction.');
w=reference.displacementComponentWeights;
absError=sqrt(sum(w.*(Y-R).^2,1))';
refNorm=sqrt(sum(w.*R.^2,1))';
rel=nan(n,1); valid=refNorm>metricConfig.staticReferenceFloor;
rel(valid)=absError(valid)./refNorm(valid);
result.absoluteWeightedFieldError=absError;
result.referenceWeightedFieldNorm=refNorm;
result.relativeWeightedFieldError=rel;
result.relativeErrorDefined=valid;
end
