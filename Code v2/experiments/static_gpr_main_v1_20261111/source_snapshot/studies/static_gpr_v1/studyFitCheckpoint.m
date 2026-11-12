function result=studyFitCheckpoint(folder,method,training,validation,config)
% One immutable fit, with failure and validation metrics persisted.
method=string(method); outputFile=fullfile(folder,'result.mat'); modelFile=fullfile(folder,'model.mat');
if isfile(outputFile)
    seal=fullfile(folder,'result.sha256');
    assert(isfile(seal) && strcmp(studyHash(outputFile),strtrim(fileread(seal))), ...
        'study:CheckpointChanged','Checkpoint checksum mismatch.');
    a=load(outputFile,'result'); result=a.result;
    assert(result.method==method && isequaln(result.config,config) && ...
        isequal(result.trainingIds,training.caseIds) && isequal(result.validationIds,validation.caseIds) && ...
        strcmp(result.trainingFingerprint,surrogate.models.shared.podFingerprint(training)) && ...
        strcmp(result.validationFingerprint,surrogate.models.shared.podFingerprint(validation)), ...
        'study:CheckpointChanged','Existing checkpoint mismatches requested fit.');
    if result.status=="ok"
        assert(isfile(modelFile) && strcmp(studyHash(modelFile),result.modelHash), ...
            'study:CheckpointChanged','Saved model changed or disappeared.');
    end
    return
end
assert(~isfolder(folder),'study:CheckpointIncomplete','Incomplete checkpoint exists: %s',folder);
rootFolder=folder;
while ~isfile(fullfile(rootFolder,'environment.mat'))
    parentFolder=fileparts(rootFolder); assert(~strcmp(parentFolder,rootFolder),'study:Environment','Study environment missing.');
    rootFolder=parentFolder;
end
estimate=120;
if method=="pod_gpr", estimate=20+15*config.rank*(numel(training.caseIds)/384)^2; end
studyRequireBudget(rootFolder,estimate); studyRequireSpace(rootFolder);
studyRoot=fileparts(mfilename('fullpath')); projectRoot=fileparts(fileparts(studyRoot));
if isfile(fullfile(rootFolder,'source_manifest.csv')), studyVerify(projectRoot,studyRoot,rootFolder); end
parent=fileparts(folder); if ~isfolder(parent), mkdir(parent); end
stage=tempname(parent); mkdir(stage); started=tic; fitSeconds=NaN; report=struct;
result=struct('method',method,'config',config,'trainingIds',training.caseIds, ...
    'validationIds',validation.caseIds, ...
    'trainingFingerprint',surrogate.models.shared.podFingerprint(training), ...
    'validationFingerprint',surrogate.models.shared.podFingerprint(validation),'status',"failed",'errorId',"",'message',"", ...
    'fitSeconds',NaN,'saveSeconds',NaN,'wallSeconds',NaN,'meanError',NaN,'medianError',NaN, ...
    'p95Error',NaN,'maxError',NaN,'undefinedCount',NaN,'modelHash',"", ...
    'report',report,'caseErrors',[]);
try
    fitStarted=tic; [model,report]=surrogate.fitModel(method,training,config); fitSeconds=toc(fitStarted);
    request=struct('inputParameters',validation.inputParameters,'parameterNames',validation.parameterNames, ...
        'parameterUnits',validation.parameterUnits,'caseIds',validation.caseIds);
    prediction=surrogate.predictModel(model,request);
    metric=surrogate.evaluatePrediction(prediction,validation, ...
        struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
    e=metric.relativeWeightedFieldError; valid=e(isfinite(e)); sorted=sort(valid);
    assert(numel(valid)==numel(e) && ~isempty(valid),'study:UndefinedMetric','Undefined validation metrics.');
    saveStarted=tic; surrogate.saveModel(fullfile(stage,'model.mat'),model);
    result.saveSeconds=toc(saveStarted);
    result.status="ok"; result.fitSeconds=fitSeconds; result.report=report;
    result.meanError=mean(valid); result.medianError=median(valid);
    result.p95Error=sorted(ceil(.95*numel(sorted))); result.maxError=max(valid);
    result.undefinedCount=numel(e)-numel(valid); result.caseErrors=metric;
    result.modelHash=string(studyHash(fullfile(stage,'model.mat')));
catch err
    if isnan(fitSeconds), fitSeconds=toc(fitStarted); end
    result.fitSeconds=fitSeconds; result.errorId=string(err.identifier); result.message=string(err.message);
end
if isfile(fullfile(rootFolder,'source_manifest.csv')), studyVerify(projectRoot,studyRoot,rootFolder); end
result.wallSeconds=toc(started); save(fullfile(stage,'result.mat'),'result','-v7.3');
writelines(string(studyHash(fullfile(stage,'result.mat'))),fullfile(stage,'result.sha256'));
[ok,msg]=movefile(stage,folder); assert(ok,'study:CheckpointWrite','%s',msg);
end
