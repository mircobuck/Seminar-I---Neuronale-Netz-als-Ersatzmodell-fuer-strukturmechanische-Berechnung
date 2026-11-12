function studyEvaluationRepaired(root,out,cfg)
% Test references are inaccessible here until the complete freeze is checked.
studyCheckFrozen(out);
refs=struct('interpolation',studyReference(out,"evaluate","interpolation"), ...
    'extrapolation',studyReference(out,"evaluate","extrapolation"));
F=readtable(fullfile(out,'freeze_manifest.csv'),'TextType','string', ...
    'Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
paths=strings(0,1);
for j=1:height(F)
    candidate=F.Path(j); [folder,name,extension]=fileparts(candidate);
    if ~(name=="result" && extension==".mat"), continue; end
    [parent,leaf]=fileparts(folder); [~,branch]=fileparts(parent);
    eligible=(any(string(branch)==["runs","controlled"]) && startsWith(string(leaf),"n")) || ...
        (string(branch)=="distribution" && any(startsWith(string(leaf),["space_","skew_"])));
    if eligible, paths(end+1)=candidate; end %#ok<AGROW>
end
assert(~isempty(paths),'study:NoModels','No trained models found.');
prior=rng; cleanup=onCleanup(@()rng(prior)); rng(20261115,'twister'); paths=paths(randperm(numel(paths))); %#ok<NASGU>
for k=1:numel(paths)
    checkpoint=char(paths(k)); a=load(checkpoint,'result'); fit=a.result;
    modelFile=fullfile(fileparts(checkpoint),'model.mat');
    if fit.status=="ok", assert(any(F.Path==string(modelFile)),'study:FreezeInvalid','Model absent from freeze.'); end
    relative=extractAfter(string(fileparts(checkpoint)),strlength(string(out))+1);
    resultFolder=fullfile(out,'evaluation_repaired',relative); if ~isfolder(resultFolder), mkdir(resultFolder); end
    for role=["interpolation","extrapolation"]
        filename=fullfile(resultFolder,role+'.mat');
        hashFile=filename+'.sha256';
        if isfile(filename) && ~isfile(hashFile)
            movefile(filename,filename+'.incomplete');
        end
        if isfile(filename)
            assert(strcmp(studyHash(filename),strtrim(fileread(hashFile))), ...
                'study:EvaluationChanged','Evaluation checkpoint changed.');
            continue
        end
        studyRequireBudget(out,30); studyRequireSpace(out);
        data=refs.(role); n=numel(data.caseIds);
        observed=struct('method',fit.method,'role',role,'status',fit.status, ...
            'message',fit.message,'fitSeconds',fit.fitSeconds,'report',fit.report, ...
            'trainingIds',fit.trainingIds,'config',fit.config,'caseIds',data.caseIds, ...
            'absolute',nan(n,1),'referenceNorm',nan(n,1),'relative',nan(n,1), ...
            'tipError',nan(n,1),'maxMagnitudeError',nan(n,1), ...
            'projectionSquared',nan(n,1),'regressionSquared',nan(n,1), ...
            'reconstructionSquared',nan(n,1),'decompositionResidual',nan(n,1),'decompositionValid',nan(n,1), ...
            'singleTimes',[],'batchTimes',[],'loadSeconds',NaN,'saveSeconds',fit.saveSeconds,'modelBytes',NaN, ...
            'femTip',nan(n,1),'eulerBernoulliTip',nan(n,1),'timoshenkoTip',nan(n,1));
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
                observed.femTip=reference(1050+tip,:)'; X=data.inputParameters;
                L=X(:,1); b=X(:,2); h=X(:,3); E=X(:,4); nu=X(:,5); forceZ=X(:,6);
                I=b.*h.^3/12; G=E./(2*(1+nu));
                observed.eulerBernoulliTip=forceZ.*L.^3./(3*E.*I);
                observed.timoshenkoTip=observed.eulerBernoulliTip+forceZ.*L./((5/6)*G.*b.*h);
                P=reshape(predicted,525,3,n); R=reshape(reference,525,3,n);
                observed.maxMagnitudeError=squeeze(max(sqrt(sum(P.^2,2)),[],1)-max(sqrt(sum(R.^2,2)),[],1));
                observed.maxMagnitudeError=observed.maxMagnitudeError(:);
                if startsWith(fit.method,"pod_")
                    diagnostic=surrogate.models.shared.podDiagnostics(model.state,reference,predicted);
                    observed.projectionSquared=diagnostic.projectionSquared;
                    observed.regressionSquared=diagnostic.regressionSquared;
                    observed.reconstructionSquared=diagnostic.reconstructionSquared;
                    observed.decompositionResidual=diagnostic.decompositionResidual;
                    scale=max(diagnostic.reconstructionSquared+diagnostic.projectionSquared+diagnostic.regressionSquared,1e-28);
                    observed.decompositionValid=double(abs(diagnostic.decompositionResidual)<=1e-8*scale);
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
writelines("test evaluation completed",fullfile(out,'evaluation_repaired.complete'));
end
