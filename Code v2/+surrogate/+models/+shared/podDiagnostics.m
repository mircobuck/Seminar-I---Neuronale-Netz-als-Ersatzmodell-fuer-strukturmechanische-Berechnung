function result = podDiagnostics(state,reference,prediction)
%podDiagnostics Decompose squared weighted field reconstruction errors.
w=state.weights(:); B=state.basis; meanField=state.fieldMean;
assert(isequal(size(reference),size(prediction)) && size(reference,1)==numel(w) && ...
    all(isfinite(reference),'all') && all(isfinite(prediction),'all'), ...
    'surrogate:pod:DiagnosticsInput','Field dimensions or values are invalid.');
assert(norm(B'*(w.*B)-eye(size(B,2)),'fro')<1e-8, ...
    'surrogate:pod:DiagnosticsBasis','Basis is not weighted orthonormal.');
referenceCoefficients=B'*(w.*(reference-meanField));
predictionCoefficients=B'*(w.*(prediction-meanField));
projection=meanField+B*referenceCoefficients;
projectedPrediction=meanField+B*predictionCoefficients;
projectionSquared=sum(w.*(projection-reference).^2,1)';
regressionSquared=sum((predictionCoefficients-referenceCoefficients).^2,1)';
reconstructionSquared=sum(w.*(prediction-reference).^2,1)';
residualSquared=sum(w.*(prediction-projectedPrediction).^2,1)';
result=struct('projectionSquared',projectionSquared,'regressionSquared',regressionSquared, ...
    'reconstructionSquared',reconstructionSquared,'predictionOffBasisSquared',residualSquared, ...
    'decompositionResidual',reconstructionSquared-projectionSquared-regressionSquared);
end
