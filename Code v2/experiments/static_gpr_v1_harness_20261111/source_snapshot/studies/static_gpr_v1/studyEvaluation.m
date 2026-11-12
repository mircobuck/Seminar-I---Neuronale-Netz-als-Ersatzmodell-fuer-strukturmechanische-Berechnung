function studyEvaluation(root,out,cfg)
% Test references are inaccessible here until the complete freeze is checked.
studyCheckFrozen(out);
refs=struct('interpolation',studyReference(out,"evaluate","interpolation"), ...
    'extrapolation',studyReference(out,"evaluate","extrapolation"));
paths=strings(0,1);
for branch=["runs","controlled","distribution"]
    files=dir(fullfile(out,branch,'**','result.mat'));
    paths=[paths;string(fullfile({files.folder},{files.name}))']; %#ok<AGROW>
end
assert(~isempty(paths),'study:NoModels','No trained models found.');
prior=rng; cleanup=onCleanup(@()rng(prior)); rng(20261115,'twister'); paths=paths(randperm(numel(paths))); %#ok<NASGU>
for k=1:numel(paths)
    checkpoint=char(paths(k)); a=load(checkpoint,'result'); fit=a.result;
    modelFile=fullfile(fileparts(checkpoint),'model.mat');
    relative=extractAfter(string(fileparts(checkpoint)),strlength(string(out))+1);
    resultFolder=fullfile(out,'evaluation',relative); if ~isfolder(resultFolder), mkdir(resultFolder); end
    for role=["interpolation","extrapolation"]
        filename=fullfile(resultFolder,role+'.mat');
        if isfile(filename)
            hashFile=filename+'.sha256';
            assert(isfile(hashFile) && strcmp(studyHash(filename),strtrim(fileread(hashFile))), ...
                'study:EvaluationChanged','Evaluation checkpoint changed or incomplete.');
            continue
        end
        data=refs.(role); n=numel(data.caseIds);
        observed=struct('method',fit.method,'role',role,'status',fit.status, ...
            'message',fit.message,'fitSeconds',fit.fitSeconds,'report',fit.report, ...
            'trainingIds',fit.trainingIds,'config',fit.config,'caseIds',data.caseIds, ...
            'absolute',nan(n,1),'referenceNorm',nan(n,1),'relative',nan(n,1), ...
            'tipError',nan(n,1),'maxMagnitudeError',nan(n,1), ...
            'projectionSquared',nan(n,1),'regressionSquared',nan(n,1), ...
            'reconstructionSquared',nan(n,1),'decompositionResidual',nan(n,1), ...
            'singleTimes',[],'batchTimes',[],'loadSeconds',NaN,'modelBytes',NaN);
        if fit.status=="ok"
            try
                started=tic; model=surrogate.loadModel(modelFile); observed.loadSeconds=toc(started);
                fileInfo=dir(modelFile); observed.modelBytes=fileInfo.bytes;
                request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                    'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
                prediction=surrogate.predictModel(model,request);
                eval=surrogate.evaluatePrediction(prediction,data, ...
                    struct('staticReferenceFloor',cfg.reference_floor,'frequencyReferenceFloorHz',0));
                observed.absolute=eval.absoluteWeightedFieldError; observed.referenceNorm=eval.referenceWeightedFieldNorm;
                observed.relative=eval.relativeWeightedFieldError;
                grid=data.normalizedGridCoordinates; tip=find(all(abs(grid-[1;.5;.5])<1e-12,1));
                assert(numel(tip)==1,'study:Tip','Tip grid location is not unique.');
                predicted=prediction.displacementFields; reference=data.displacementFields;
                observed.tipError=(predicted(1050+tip,:)-reference(1050+tip,:))';
                P=reshape(predicted,525,3,n); R=reshape(reference,525,3,n);
                observed.maxMagnitudeError=squeeze(max(sqrt(sum(P.^2,2)),[],1)-max(sqrt(sum(R.^2,2)),[],1));
                observed.maxMagnitudeError=observed.maxMagnitudeError(:);
                if startsWith(fit.method,"pod_")
                    diagnostic=surrogate.models.shared.podDiagnostics(model.state,reference,predicted);
                    observed.projectionSquared=diagnostic.projectionSquared;
                    observed.regressionSquared=diagnostic.regressionSquared;
                    observed.reconstructionSquared=diagnostic.reconstructionSquared;
                    observed.decompositionResidual=diagnostic.decompositionResidual;
                end
                if role=="interpolation"
                    one=request; one.inputParameters=one.inputParameters(1,:); one.caseIds=one.caseIds(1);
                    batch=request; batch.inputParameters=batch.inputParameters(1:128,:); batch.caseIds=batch.caseIds(1:128);
                    surrogate.predictModel(model,one); surrogate.predictModel(model,batch);
                    observed.singleTimes=zeros(cfg.prediction_repetitions,1); observed.batchTimes=observed.singleTimes;
                    for t=1:cfg.prediction_repetitions
                        start=tic; surrogate.predictModel(model,one); observed.singleTimes(t)=toc(start);
                        start=tic; surrogate.predictModel(model,batch); observed.batchTimes(t)=toc(start);
                    end
                end
            catch err
                observed.status="failed"; observed.message=string(err.identifier)+": "+string(err.message);
            end
        end
        temporary=[tempname(resultFolder),'.mat']; save(temporary,'observed','-v7.3');
        [ok,msg]=movefile(temporary,filename); assert(ok,'study:EvaluationWrite','%s',msg);
        writelines(string(studyHash(filename)),filename+'.sha256');
    end
end
writelines("test evaluation completed",fullfile(out,'evaluation.complete'));
end
