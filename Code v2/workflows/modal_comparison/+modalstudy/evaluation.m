function evaluation(out,cfg)
%evaluation Evaluate frozen models on the known 64-case test reference.
data=modalstudy.reference(out,"evaluate","test");
assert(numel(data.caseIds)==cfg.counts.test,'modalstudy:Count','Unexpected test count.');
[analytic,families]=modalstudy.analytical(data.inputParameters);
reference=struct('caseIds',data.caseIds,'inputParameters',data.inputParameters, ...
    'frequencyHz',data.frequencyHz,'analyticHz',analytic,'analyticFamilies',families, ...
    'historicalSeconds',data.computationTimeSeconds);
modalstudy.artifact(fullfile(out,'evaluation','test_reference.mat'),reference);
runs=modalstudy.artifact(fullfile(out,'run_plan.mat'));
request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
    'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
for k=1:numel(runs)
    r=runs(k); if r.role=="timing", continue; end
    file=fullfile(out,'evaluation',r.id,'observed.mat');
    if isfile(file), modalstudy.artifact(file); continue; end
    folder=fullfile(out,r.id); a=load(fullfile(folder,'result.mat'),'result'); fit=a.result;
    n=numel(data.caseIds);
    q=struct('id',r.id,'method',r.method,'role',r.role,'N',numel(r.ids),'config',r.config, ...
        'status',fit.status,'message',fit.message,'fitSeconds',fit.fitSeconds, ...
        'report',fit.report,'predictionHz',nan(n,6),'absoluteHz',nan(n,6),'relative',nan(n,6), ...
        'nonpositive',nan(n,6),'orderViolation',nan(n,1),'loadSeconds',NaN, ...
        'predictionSeconds',NaN,'modelBytes',NaN,'projectionSquared',nan(n,1), ...
        'regressionSquared',nan(n,1),'reconstructionSquared',nan(n,1),'decompositionResidual',nan(n,1));
    if fit.status=="ok"
        try
            modelFile=fullfile(folder,'model.mat'); timer=tic;
            model=surrogate.loadModel(modelFile); q.loadSeconds=toc(timer);
            info=dir(modelFile); q.modelBytes=info.bytes;
            timer=tic; prediction=surrogate.predictModel(model,request); q.predictionSeconds=toc(timer);
            e=surrogate.evaluatePrediction(prediction,data,struct);
            q.predictionHz=prediction.frequencyHz; q.absoluteHz=e.absoluteFrequencyErrorHz;
            q.relative=e.relativeFrequencyError; q.nonpositive=e.nonpositiveFrequency;
            q.orderViolation=e.orderViolation;
            if startsWith(r.method,"pod_")
                d=surrogate.models.shared.podDiagnostics(model.state,data.frequencyHz',prediction.frequencyHz');
                for key=["projectionSquared","regressionSquared","reconstructionSquared","decompositionResidual"]
                    q.(key)=d.(key);
                end
            end
        catch err
            q.status="failed"; q.message=string(err.identifier)+": "+string(err.message);
        end
    end
    modalstudy.artifact(file,q);
end
writelines("Frozen test evaluation completed; inspect individual statuses.",fullfile(out,'evaluation.complete'));
end
