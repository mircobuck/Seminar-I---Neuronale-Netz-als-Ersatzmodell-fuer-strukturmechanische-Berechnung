function [observed,request] = observeModel(model,data,observed,method,cfg)
    %observeModel Compute physical case errors and POD diagnostics without checkpoint I/O.
    n=numel(data.caseIds);
    request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
        'parameterUnits',  data.parameterUnits,  'caseIds',  data.caseIds);
    prediction=surrogate.predictModel(model,request);
    metric=surrogate.evaluatePrediction(prediction,data,  struct('staticReferenceFloor',cfg.reference_floor, ...
        'frequencyReferenceFloorHz',0));
    observed.absolute=metric.absoluteWeightedFieldError;
    observed.referenceNorm=metric.referenceWeightedFieldNorm;
    observed.relative=metric.relativeWeightedFieldError;
    grid=data.normalizedGridCoordinates;
    tip=find(all(abs(grid-[1;.5;.5])<1e-12,1));
    assert(isscalar(tip),'study:Tip','Tip grid location is not unique.');
    predicted=prediction.displacementFields;
    reference=data.displacementFields;
    observed.tipError=(predicted(1050+tip,:)-reference(1050+tip,:))';
    observed.femTip=reference(1050+tip,:)';
    X=data.inputParameters;
    L=X(:,1);
    b=X(:,2);
    h=X(:,3);
    E=X(:,4);
    nu=X(:,5);
    forceZ=X(:,6);
    I=b.*h.^3/12;
    G=E./(2*(1+nu));
    observed.eulerBernoulliTip=forceZ.*L.^3./(3*E.*I);
    observed.timoshenkoTip=observed.eulerBernoulliTip+forceZ.*L./((5/6)*G.*b.*h);
    P=reshape(predicted,525,3,n);
    R=reshape(reference,525,3,n);
    observed.maxMagnitudeError=squeeze(max(sqrt(sum(P.^2,2)),[],1)-max(sqrt(sum(R.^2,2)),[],1));
    observed.maxMagnitudeError=observed.maxMagnitudeError(:);
    if startsWith(method,"pod_")
        diagnostic=surrogate.models.shared.podDiagnostics(model.state,reference,predicted);
        observed.projectionSquared=diagnostic.projectionSquared;
        observed.regressionSquared=diagnostic.regressionSquared;
        observed.reconstructionSquared=diagnostic.reconstructionSquared;
        observed.decompositionResidual=diagnostic.decompositionResidual;
        scale=max(diagnostic.reconstructionSquared+diagnostic.projectionSquared+diagnostic.regressionSquared,1e-28);
        observed.decompositionValid=double(abs(diagnostic.decompositionResidual)<=1e-8*scale);
    end
end
