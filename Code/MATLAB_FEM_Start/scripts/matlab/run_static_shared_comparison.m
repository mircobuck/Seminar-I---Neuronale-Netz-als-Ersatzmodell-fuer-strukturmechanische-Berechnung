function run_static_shared_comparison(stage)
%RUN_STATIC_SHARED_COMPARISON Resumable shared n=384 static field comparison.
% Stages: prepare, import_fit, freeze, probe, final_data, final_evaluate.
if nargin==0
    fprintf(['Stages:\n' ...
        '  run_static_shared_comparison("prepare")\n' ...
        '  run_static_shared_comparison("import_fit")\n' ...
        '  run_static_shared_comparison("freeze")\n' ...
        '  run_static_shared_comparison("probe")  % known IDs 19-24 only\n' ...
        '  run_static_shared_comparison("final_data")  % resume approved holdout references\n' ...
        '  run_static_shared_comparison("final_evaluate")  % evaluate frozen models\n']);
    return
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
configPath=fullfile(root,'configs','static_shared_comparison_20261028_v1.json');
cfg=jsondecode(fileread(configPath));
out=fullfile(root,'experiments','active',cfg.study);
assert(isfolder(out),'femstudy:shared:StudyMissing','Study folder is missing: %s',out);
switch validatestring(char(stage), ...
        {'prepare','import_fit','freeze','probe','final_data','final_evaluate'})
    case 'prepare'
        prepareStudy(root,out,cfg,configPath);
    case 'import_fit'
        prepared=loadPrepared(root,out,cfg);
        importAndFit(root,out,cfg,prepared);
    case 'freeze'
        prepared=loadPrepared(root,out,cfg);
        freezeModels(root,out,cfg,configPath,prepared);
    case 'probe'
        prepared=loadPrepared(root,out,cfg);
        manifest=verifyFrozen(root,out,cfg,configPath,prepared);
        runEvaluation(root,out,cfg,prepared,manifest,"probe");
    case 'final_data'
        prepared=loadPrepared(root,out,cfg);
        verifyFrozen(root,out,cfg,configPath,prepared);
        createFinalReferences(root,out,cfg,prepared);
    case 'final_evaluate'
        prepared=loadPrepared(root,out,cfg);
        manifest=verifyFrozen(root,out,cfg,configPath,prepared);
        runEvaluation(root,out,cfg,prepared,manifest,"final");
end
end

function prepareStudy(root,out,cfg,configPath)
[train,val,knownTest,trainFile,valFile,testFile]=sourceSplits(root,cfg);
knownX=[train.X;val.X;knownTest.X];
knownIDs=[train.id(:);val.id(:);knownTest.id(:)];
[extraX,extraIDs]=knownDesigns(root,cfg);
knownX=[knownX;extraX];
knownIDs=[knownIDs;extraIDs];
assert(numel(unique(knownIDs))==numel(knownIDs), ...
    'femstudy:shared:KnownIDDuplicate','Known source designs contain duplicate IDs.');
assert(all(ismember(cfg.validationIds(:),val.id(:))) && ...
    isequal(knownTest.id(:),cfg.previousKnownTestIds(:)), ...
    'femstudy:shared:SplitMismatch','Known split IDs differ from the configuration.');
assert(all(ismember(train.id(:),knownIDs)),'femstudy:shared:TrainingIDs', ...
    'Expected training IDs are missing from the known design.');

designPath=fullfile(out,'holdout_design.csv');
preparedPath=fullfile(out,'prepared.mat');
if isfile(preparedPath)
    old=load(preparedPath,'value');
    value=old.value;
    assert(isequaln(value.config,cfg),'femstudy:shared:PreparedConfigConflict', ...
        'Prepared artifact config conflicts with the versioned config.');
    assert(isequal(value.trainIDs,train.id(:)) && ...
        isequal(value.validationIDs,val.id(:)) && ...
        isequal(value.knownTestIDs,knownTest.id(:)), ...
        'femstudy:shared:PreparedSplitConflict','Prepared split IDs conflict.');
    assert(isfile(designPath),'femstudy:shared:HoldoutDesignMissing', ...
        'Prepared artifact exists but its holdout design is missing.');
    saved=readtable(designPath,TextType="string");
    savedX=saved{:,cfg.parameterNames};
    assert(isequal(saved.id,value.holdoutIDs) && ...
        isequal(size(savedX),size(value.holdoutX)) && ...
        all(abs(savedX(:)-value.holdoutX(:))<= ...
        1e-12*max(1,abs(value.holdoutX(:)))), ...
        'femstudy:shared:HoldoutDesignConflict', ...
        'Stored holdout design differs from its immutable prepared artifact.');
    fprintf('Preparation already exists and matches the current sources.\n');
    return
end
assert(~isfile(designPath),'femstudy:shared:OrphanDesign', ...
    'Holdout design exists without prepared.mat; refusing to replace it.');

rng(cfg.holdout.seed,'twister');
U=lhsdesign(cfg.holdout.count,numel(cfg.parameterNames), ...
    'Criterion',cfg.holdout.criterion,'Iterations',cfg.holdout.iterations);
lower=reshape(cfg.lower,1,[]); upper=reshape(cfg.upper,1,[]);
holdoutX=lower+U.*(upper-lower);
holdoutIDs=(cfg.holdout.idStart:cfg.holdout.idStart+cfg.holdout.count-1)';
assert(isempty(intersect(holdoutIDs,knownIDs)), ...
    'femstudy:shared:HoldoutIDOverlap','Holdout IDs overlap known IDs.');
scaledKnown=(knownX-lower)./(upper-lower);
scaledHoldout=(holdoutX-lower)./(upper-lower);
distance=pdist2(scaledHoldout,scaledKnown,'chebychev');
assert(min(distance,[],'all')>cfg.holdout.normalizedChebyshevMinimumDistance, ...
    'femstudy:shared:HoldoutParameterOverlap', ...
    'Holdout parameter design overlaps a known parameter combination.');
within=pdist2(scaledHoldout,scaledHoldout,'chebychev');
within(1:size(within,1)+1:end)=Inf;
assert(min(within,[],'all')>cfg.holdout.normalizedChebyshevMinimumDistance, ...
    'femstudy:shared:HoldoutDuplicate','Holdout contains duplicate parameters.');

value=struct('schema',"static-shared-prepared-v1",'config',cfg, ...
    'trainIDs',train.id(:),'validationIDs',val.id(:), ...
    'knownTestIDs',knownTest.id(:),'knownIDs',knownIDs, ...
    'holdoutIDs',holdoutIDs,'holdoutX',holdoutX, ...
    'trainingDataFile',string(trainFile),'validationDataFile',string(valFile), ...
    'knownTestDataFile',string(testFile),'knownDesignCount',numel(knownIDs), ...
    'minimumKnownDistance',min(distance,[],'all'), ...
    'minimumHoldoutDistance',min(within,[],'all'), ...
    'configSHA256',sha256(configPath));
parameterNames=reshape(string(cfg.parameterNames),1,[]);
tableOut=array2table([holdoutIDs holdoutX], ...
    'VariableNames',[{'id'},cellstr(parameterNames)]);
tableOut.split=repmat("sealed_holdout",height(tableOut),1);
writetable(tableOut,designPath);
try
    femstudy.data.saveNew(preparedPath,value);
catch err
    if isfile(designPath), delete(designPath); end
    rethrow(err);
end
fprintf('Prepared 384 training IDs, %d validation IDs, and a sealed 64-case design; no holdout labels accessed.\n', ...
    numel(val.id));
end

function importAndFit(root,out,cfg,prepared)
[train,val]=sourceSplits(root,cfg);
assert(isequal(train.id(:),prepared.trainIDs) && ...
    isequal(val.id(:),prepared.validationIDs), ...
    'femstudy:shared:SplitChanged','Train/validation IDs changed after preparation.');
modelDir=fullfile(out,'models');
if ~isfolder(modelDir), mkdir(modelDir); end
neuralRoot=fullfile(root,cfg.neuralSource);
for seed=cfg.neuralSeeds(:)'
    for modelID=["pod","residual"]
        sourceFile=fullfile(neuralRoot,"seed"+seed,modelID+'.mat');
        assert(isfile(sourceFile),'femstudy:shared:NeuralSourceMissing', ...
            'Missing frozen neural artifact: %s',sourceFile);
        source=load(sourceFile,'value'); model=source.value;
        assert(isequal(model.trainIDs(:),train.id(:)) && ...
            isequal(model.validationIDs(:),val.id(:)), ...
            'femstudy:shared:NeuralSplitMismatch', ...
            'Neural artifact %s has unexpected training/validation IDs.',sourceFile);
        assert(model.seed==seed && model.kind==modelID, ...
            'femstudy:shared:NeuralIdentityMismatch', ...
            'Neural artifact model or seed does not match its path: %s',sourceFile);
        assert(isequal(model.xi,train.xi) && isequal(model.pod.w(:),train.w(:)), ...
            'femstudy:shared:NeuralFieldMismatch', ...
            'Neural artifact field grid or weights disagree with the source data.');
        model.comparisonSource=string(sourceFile);
        destination=fullfile(modelDir,"neural_"+modelID+"_seed"+seed+".mat");
        imported=struct('id',modelID,'seed',seed,'model',model, ...
            'sourceFile',string(sourceFile),'sourceSHA256',sha256(sourceFile));
        saveImmutable(destination,imported,@(v) ...
            isequal(v.sourceSHA256,imported.sourceSHA256) && ...
            isequal(v.model.trainIDs(:),train.id(:)) && ...
            isequal(v.model.validationIDs(:),val.id(:)));
    end
end

sourceModelsFile=fullfile(root,cfg.trainingSource,'models.mat');
assert(isfile(sourceModelsFile),'femstudy:shared:PODGPRSourceMissing', ...
    'Existing POD-GPR model artifact is missing: %s',sourceModelsFile);
source=load(sourceModelsFile,'models');
indices=find(cellfun(@(m)m.name=="POD_GP",source.models));
assert(isscalar(indices),'femstudy:shared:PODGPRIdentity', ...
    'Expected exactly one POD_GP model in the historical n=384 artifact.');
model=source.models{indices};
assert(model.type=="field" && model.pod.r>=1, ...
    'femstudy:shared:PODGPRArtifact','Stored POD-GPR model is incomplete.');
model.trainIDs=train.id(:); model.validationIDs=val.id(:); model.seed=cfg.podGprSeed;
model.provenance="Imported from the n384 models.mat produced by train_models(train.mat,val.mat).";
destination=fullfile(modelDir,'pod_gpr.mat');
imported=struct('id',"POD_GPR",'seed',cfg.podGprSeed,'model',model, ...
    'sourceFile',string(sourceModelsFile),'sourceSHA256',sha256(sourceModelsFile), ...
    'sourceTrainIDs',train.id(:),'sourceValidationIDs',val.id(:));
saveImmutable(destination,imported,@(v) ...
    isequal(v.sourceSHA256,imported.sourceSHA256) && ...
    isequal(v.model.trainIDs(:),train.id(:)) && ...
    isequal(v.model.validationIDs(:),val.id(:)));

beamFile=fullfile(modelDir,'beam_residual_gpr.mat');
fitConfig=cfg.residualGpr;
if isfile(beamFile)
    old=load(beamFile,'value');
    m=old.value;
    assert(isequaln(m.fitConfig,fitConfig) && ...
        isequal(m.model.trainIDs(:),train.id(:)) && ...
        isequal(m.model.validationIDs(:),val.id(:)) && ...
        isequal(m.model.ranks(:),unique(fitConfig.podRanks(:))) && ...
        isequal(m.model.kernels(:),string(fitConfig.kernels(:))), ...
        'femstudy:shared:RestGPRConflict', ...
        'Existing residual-GPR fit conflicts with its preregistered config or split.');
    fprintf('Residual-field GPR fit exists and matches its preregistered config.\n');
else
    rng(fitConfig.seed,'twister');
    options=struct('ranks',fitConfig.podRanks,'kernels',string(fitConfig.kernels));
    model=femstudy.models.fitBeamField(train,val,options);
    value=struct('id',"Beam_Field_POD_GPR",'seed',cfg.beamResidualGprSeed, ...
        'model',model,'fitConfig',fitConfig, ...
        'trainingDataSHA256',sha256(fullfile(root,cfg.trainingSource,'train.mat')), ...
        'validationDataSHA256',sha256(fullfile(root,cfg.trainingSource,'val.mat')));
    femstudy.data.saveNew(beamFile,value);
    fprintf('Fit residual GPR: rank=%d kernel=%s validation=%.8g time=%.1fs\n', ...
        model.selectedRank,model.kernel,model.validationError,model.trainingSeconds);
end
fprintf('Imported six neural models and the existing POD-GPR; no neural model was retrained.\n');
end

function freezeModels(root,out,cfg,configPath,prepared)
preparedPath=fullfile(out,'prepared.mat');
assert(isfile(preparedPath),'femstudy:shared:NotPrepared','Run prepare first.');
records=loadModelRecords(root,out,cfg);
assert(numel(records)==1+2*numel(cfg.neuralSeeds)+2, ...
    'femstudy:shared:ModelCount','Model/seed collection is incomplete.');
freezePath=fullfile(out,'freeze_manifest.mat');
if isfile(freezePath)
    verifyFrozen(root,out,cfg,configPath,prepared);
    fprintf('Freeze manifest already exists and all recorded hashes match.\n');
    return
end
paths=sourceFiles(root,out,cfg,configPath,preparedPath);
roles=repmat("source",numel(paths),1);
for i=1:numel(paths)
    if contains(paths(i),string(filesep)+"models"+string(filesep)), roles(i)="model"; end
    if paths(i)==string(fullfile(out,'holdout_design.csv')), roles(i)="sealed-design"; end
end
hashes=strings(numel(paths),1);
for i=1:numel(paths)
    assert(isfile(paths(i)),'femstudy:shared:SourceMissing', ...
        'Required source artifact missing before freeze: %s',paths(i));
    hashes(i)=sha256(paths(i));
end
hashTable=table(paths(:),hashes,roles, ...
    'VariableNames',{'Path','SHA256','Role'});
[revStatus,revision]=system(sprintf('git -C "%s" rev-parse HEAD',root));
assert(revStatus==0,'femstudy:shared:GitRevision', ...
    'Could not determine the Git revision for the freeze manifest.');
[statusCode,gitStatus]=system(sprintf('git -C "%s" status --short --untracked-files=no',root));
assert(statusCode==0,'femstudy:shared:GitStatus','Could not determine Git worktree status.');
manifest=struct('schema',"static-shared-freeze-v1",'study',cfg.study, ...
    'created',string(datetime('now','TimeZone','local')), ...
    'configSHA256',sha256(configPath),'holdoutDesignSHA256', ...
    sha256(fullfile(out,'holdout_design.csv')),'gitRevision',strtrim(string(revision)), ...
    'gitTrackedWorktreeStatus',strtrim(string(gitStatus)), ...
    'gitTrackedWorktreeDirty',~isempty(strtrim(gitStatus)), ...
    'trainingIDs',prepared.trainIDs,'validationIDs',prepared.validationIDs, ...
    'knownProbeIDs',prepared.knownTestIDs,'holdoutIDs',prepared.holdoutIDs, ...
    'fieldPointCount',cfg.fieldPointCount,'fieldComponents',string(cfg.fieldComponents), ...
    'componentOrder',cfg.componentOrder,'fieldUnits',cfg.fieldUnits, ...
    'hashes',hashTable,'models',manifestModels(records,cfg));
femstudy.data.saveNew(freezePath,manifest);
writeManifestMarkdown(fullfile(out,'MODEL_MANIFEST.md'),manifest);
fprintf('Froze %d model variants before any new holdout labels were created or read.\n', ...
    numel(records));
end

function manifest=verifyFrozen(root,out,cfg,configPath,prepared)
path=fullfile(out,'freeze_manifest.mat');
assert(isfile(path),'femstudy:shared:NotFrozen', ...
    'No freeze manifest exists; run import_fit and freeze first.');
a=load(path,'value'); manifest=a.value;
assert(manifest.configSHA256==sha256(configPath) && ...
    isequal(manifest.holdoutIDs,prepared.holdoutIDs) && ...
    manifest.holdoutDesignSHA256==sha256(fullfile(out,'holdout_design.csv')), ...
    'femstudy:shared:FreezeIdentityConflict', ...
    'Config or sealed holdout design changed after freeze.');
for i=1:height(manifest.hashes)
    file=manifest.hashes.Path(i);
    assert(isfile(file),'femstudy:shared:FrozenFileMissing', ...
        'A frozen input/model file is missing: %s',file);
    actual=sha256(file);
    assert(actual==manifest.hashes.SHA256(i), ...
        'femstudy:shared:FrozenFileChanged', ...
        'Frozen input/model hash differs; refusing use: %s',file);
end
records=loadModelRecords(root,out,cfg);
assert(numel(records)==9 && numel(manifest.models)==9, ...
    'femstudy:shared:FrozenModelCount', ...
    'Freeze manifest and imported model set must each contain exactly nine variants.');
liveKeys=sort(string({records.id})'+"|"+string([records.seed]'));
frozenKeys=sort(string({manifest.models.id})'+"|"+ ...
    string([manifest.models.seed]'));
assert(isequal(liveKeys,frozenKeys), ...
    'femstudy:shared:FrozenModelSetMismatch', ...
    'Frozen manifest model/seed keys do not match the available model artifacts.');
end

function runEvaluation(root,out,cfg,prepared,manifest,mode)
records=loadModelRecords(root,out,cfg);
if mode=="probe"
    resultFile=fullfile(out,'probe_evaluation.mat');
    if isfile(resultFile)
        a=load(resultFile,'value');
        assert(isequal(a.value.testIDs,prepared.knownTestIDs), ...
            'femstudy:shared:ProbeResultConflict','Existing probe result IDs conflict.');
        ensureEvaluationTables(out,a.value.testLabel,a.value);
        fprintf('Technical probe already exists for known IDs 19-24; preserved unchanged.\n');
        return
    end
    source=load(fullfile(root,cfg.trainingSource,'test.mat'),'D');
    test=source.D;
    assert(isequal(test.id(:),prepared.knownTestIDs) && ...
        isequal(test.xi,records(1).xi), ...
        'femstudy:shared:ProbeSplitMismatch','Known technical probe data differ.');
    testIDs=test.id(:); X=test.X; S=test.S; xi=test.xi; w=test.w;
    seconds=test.seconds(:);
    testLabel="technical_probe_known_ids_19_24";
else
    resultFile=fullfile(out,'final_evaluation.mat');
    if isfile(resultFile)
        a=load(resultFile,'value');
        assert(isequal(a.value.testIDs,prepared.holdoutIDs), ...
            'femstudy:shared:FinalResultConflict','Existing final result IDs conflict.');
        ensureEvaluationTables(out,a.value.testLabel,a.value);
        fprintf('Final evaluation already exists and matches the sealed IDs; preserved unchanged.\n');
        return
    end
    [X,S,seconds,xi,w]=readFinalReferences(out,prepared,cfg);
    testIDs=prepared.holdoutIDs;
    testLabel="independent_holdout";
end
assert(~isempty(records),'femstudy:shared:NoModels','No model records were loaded.');
for i=1:numel(records)
    assert(isequal(records(i).xi,xi) && isequal(records(i).weights(:),w(:)), ...
        'femstudy:shared:FieldContract', ...
        'Model %s uses a different field grid or weighting.',records(i).id);
end
[caseMetrics,summary,seedSpread,paired,timings]= ...
    evaluateRecords(records,X,S,xi,w,testIDs,seconds,cfg);
value=struct('schema',"static-shared-evaluation-v1",'mode',mode, ...
    'testLabel',testLabel,'testIDs',testIDs,'holdoutDesignSHA256', ...
    manifest.holdoutDesignSHA256,'modelIDs',string({records.id}), ...
    'caseMetrics',caseMetrics,'summaryByModelSeed',summary, ...
    'seedSpread',seedSpread,'pairedCaseDifferences',paired, ...
    'predictionTimings',timings,'MATLAB',version,'Toolboxes',ver, ...
    'Computer',computer);
femstudy.data.saveNew(resultFile,value);
ensureEvaluationTables(out,testLabel,value);
disp(summary);
fprintf('%s completed for %d reference cases and %d model/seed variants.\n', ...
    testLabel,numel(testIDs),numel(records));
end

function [caseMetrics,summary,seedSpread,paired,timingTable]= ...
        evaluateRecords(records,X,S,~,w,testIDs,referenceSeconds,cfg)
caseRows=cell(0,8); timingRows=cell(0,8); errors=cell(numel(records),1);
for k=1:numel(records)
    prediction= predictModel(records(k),X);
    assert(isequal(size(prediction),size(S)) && ...
        all(isfinite(prediction),'all'), ...
        'femstudy:shared:PredictionShape','Invalid prediction from %s.',records(k).id);
    met=femstudy.metrics.field(S,prediction,w,X);
    errors{k}=met.relative;
    repeats=zeros(numel(testIDs),cfg.timing.predictionRepeatsPerCase);
    for i=1:numel(testIDs)
        predictModel(records(k),X(i,:));
        for rep=1:size(repeats,2)
            started=tic;
            predictModel(records(k),X(i,:));
            repeats(i,rep)=toc(started);
        end
        for rep=1:size(repeats,2)
            timingRows(end+1,:)={records(k).id,records(k).seed,testIDs(i), ...
                rep,repeats(i,rep),median(repeats(i,:)), ...
                records(k).trainingSeconds,referenceSeconds(i)}; %#ok<AGROW>
        end
    end
    for i=1:numel(testIDs)
        caseRows(end+1,:)={records(k).id,records(k).seed,testIDs(i), ...
            met.relative(i),met.absoluteRMS(i),met.physicalL2(i), ...
            median(repeats(i,:)),records(k).trainingSeconds}; %#ok<AGROW>
    end
end
caseMetrics=cell2table(caseRows,'VariableNames', ...
    {'Model','Seed','TestID','RelativeWeightedFieldError', ...
    'AbsoluteWeightedRMS_m','PhysicalL2_m52','PredictionMedianSeconds', ...
    'TrainingSeconds'});
timingTable=cell2table(timingRows,'VariableNames', ...
    {'Model','Seed','TestID','Repeat','PredictionSeconds', ...
    'CaseMedianSeconds','TrainingSeconds','ReferenceFEMSeconds'});

summaryRows=cell(0,9);
for k=1:numel(records)
    r=errors{k}; absr=caseMetrics.AbsoluteWeightedRMS_m( ...
        caseMetrics.Model==records(k).id & caseMetrics.Seed==records(k).seed);
    summaryRows(end+1,:)={records(k).id,records(k).seed,numel(r), ...
        nearestSummary(r,1),nearestSummary(r,2),nearestSummary(r,3), ...
        nearestSummary(absr,1),nearestSummary(absr,2),nearestSummary(absr,3)}; %#ok<AGROW>
end
summary=cell2table(summaryRows,'VariableNames', ...
    {'Model','Seed','Cases','MedianRelative','P95Relative','MaxRelative', ...
    'MedianAbsoluteRMS_m','P95AbsoluteRMS_m','MaxAbsoluteRMS_m'});

seedRows=cell(0,5);
modelNames=unique(string({records.id}),'stable');
for i=1:numel(modelNames)
    ix=find(string({records.id})==modelNames(i));
    medianBySeed=zeros(numel(ix),1);
    for j=1:numel(ix), medianBySeed(j)=nearestSummary(errors{ix(j)},1); end
    seedRows(end+1,:)={modelNames(i),numel(ix), ...
        min(medianBySeed),median(medianBySeed),max(medianBySeed)}; %#ok<AGROW>
end
seedSpread=cell2table(seedRows,'VariableNames', ...
    {'Model','SeedCount','MinSeedMedianRelative','MedianSeedMedianRelative', ...
    'MaxSeedMedianRelative'});

pairRows=cell(0,8);
for a=1:numel(records)
    for b=a+1:numel(records)
        for i=1:numel(testIDs)
            pairRows(end+1,:)={records(a).id,records(a).seed, ...
                records(b).id,records(b).seed,testIDs(i), ...
                errors{a}(i),errors{b}(i),errors{a}(i)-errors{b}(i)}; %#ok<AGROW>
        end
    end
end
paired=cell2table(pairRows,'VariableNames', ...
    {'ModelA','SeedA','ModelB','SeedB','TestID','RelativeErrorA', ...
    'RelativeErrorB','AminusBRelativeError'});
end

function out=nearestSummary(x,index)
x=sort(x(isfinite(x)));
assert(~isempty(x),'femstudy:shared:NoFiniteErrors','Metric has no finite values.');
switch index
    case 1, out=median(x);
    case 2, out=x(ceil(.95*numel(x)));
    case 3, out=max(x);
end
end

function H=predictModel(record,X)
switch record.kind
    case "analytic"
        H=femstudy.fem.beamField(X,record.xi);
    case "neural"
        H=femstudy.models.predictNeural(record.value,X);
    case "pod-gpr"
        H=record.value.pod.mean+record.value.pod.V*predict_reg(record.value.reg,X)';
    case "beam-residual-gpr"
        predicted=femstudy.models.predictBeamField(record.value,X);
        H=predicted.field;
    otherwise
        error('femstudy:shared:UnknownModel','Unknown model kind: %s',record.kind);
end
end

function records=loadModelRecords(root,out,cfg)
[train,~,~,~,~,~]=sourceSplits(root,cfg);
template=struct('id',"",'seed',0,'kind',"",'value',[],'xi',train.xi, ...
    'weights',train.w(:),'trainingSeconds',0,'trainingCostSource',"");
records=repmat(template,0,1);
r=template; r.id="Beam_theory_field"; r.kind="analytic"; r.seed=0;
r.trainingCostSource="not applicable; analytical baseline"; records(end+1)=r;
for kind=["pod","residual"]
    for seed=cfg.neuralSeeds(:)'
        file=fullfile(out,'models',"neural_"+kind+"_seed"+seed+".mat");
        assert(isfile(file),'femstudy:shared:ModelMissing','Missing imported model: %s',file);
        a=load(file,'value'); model=a.value.model;
        r=template; r.id=string(modelName(kind)); r.seed=seed; r.kind="neural";
        r.value=model; r.trainingSeconds=model.trainingSeconds;
        r.trainingCostSource="historical fitNeural time; all rank/width candidates, validation, and fitting; not remeasured";
        records(end+1)=r; %#ok<AGROW>
    end
end
file=fullfile(out,'models','pod_gpr.mat');
assert(isfile(file),'femstudy:shared:ModelMissing','Missing imported POD-GPR artifact.');
a=load(file,'value'); model=a.value.model;
r=template; r.id="POD_GPR"; r.seed=cfg.podGprSeed; r.kind="pod-gpr";
r.value=model; r.trainingSeconds=model.seconds;
r.trainingCostSource="historical train_models time; candidate ranks and validation selection; hardware/timing conditions not controlled";
records(end+1)=r;
file=fullfile(out,'models','beam_residual_gpr.mat');
assert(isfile(file),'femstudy:shared:ModelMissing','Missing new beam-residual GPR artifact.');
a=load(file,'value'); model=a.value.model;
r=template; r.id="Beam_Field_POD_GPR"; r.seed=cfg.beamResidualGprSeed;
r.kind="beam-residual-gpr"; r.value=model;
r.trainingSeconds=model.trainingSeconds;
r.trainingCostSource="new fitBeamField time in this MATLAB run; includes all preregistered rank/kernel candidates and validation";
records(end+1)=r;
end

function name=modelName(kind)
switch kind
    case "pod", name="POD_MLP";
    case "residual", name="Beam_Residual_MLP";
end
end

function models=manifestModels(records,cfg)
models=repmat(struct('id',"",'seed',0,'sourceArtifact',"", ...
    'representation',"",'fieldUnits',"m",'fieldPointCount',cfg.fieldPointCount, ...
    'componentOrder',cfg.componentOrder,'podRank',0,'scaling',"", ...
    'architectureOrKernel',"",'selectionRule',"",'trainingSeconds',NaN, ...
    'trainingTimeScope',""),numel(records),1);
for i=1:numel(records)
    r=records(i); m=models(i); m.id=r.id; m.seed=r.seed;
    m.trainingSeconds=r.trainingSeconds;
    m.trainingTimeScope=r.trainingCostSource;
    switch r.kind
        case "analytic"
            m.sourceArtifact="src/+femstudy/+fem/beamField.m";
            m.representation="full analytical Euler-Bernoulli displacement field";
            m.scaling="none; SI parameter inputs and metre-valued outputs";
            m.architectureOrKernel="closed-form cantilever beam field";
            m.selectionRule="no fitted parameters or validation selection";
        case "neural"
            model=r.value; m.sourceArtifact=string(model.comparisonSource);
            if model.kind=="pod"
                m.representation="weighted POD of full displacement field";
            else
                m.representation="analytical beam field plus weighted POD residual";
            end
            m.podRank=model.pod.r;
            m.scaling=sprintf("training-only weighted POD mean/basis; input and POD-coefficient mean/std in stored regressor");
            m.architectureOrKernel=sprintf("two fully connected tanh layers, width %d; Adam",model.reg.width);
            m.selectionRule="minimum validation mean relative weighted field L2 across stored POD ranks and widths; ties first";
        case "pod-gpr"
            model=r.value; m.sourceArtifact="experiments/active/training_size_12_24_48_20261023/n384/models.mat";
            m.representation="weighted POD of full displacement field";
            m.podRank=model.pod.r;
            m.scaling="training-only weighted POD; standardized inputs and POD coefficients from training data";
            m.architectureOrKernel="independent GPR coefficient regressors; ARD Matérn 5/2";
            m.selectionRule="historical minimum validation field error over the configured POD-rank candidates";
        case "beam-residual-gpr"
            model=r.value; m.sourceArtifact="fitBeamField(train,val,configured rank/kernel candidates)";
            m.representation="Euler-Bernoulli field plus weighted POD of residual field";
            m.podRank=model.pod.r;
            m.scaling="beam residual, weighted POD mean/basis, input and coefficient scaling use training data only";
            m.architectureOrKernel="independent GPR coefficient regressors; "+model.kernel;
            m.selectionRule="minimum validation mean relative weighted field L2 over preregistered ranks and kernels";
    end
    m.sourceArtifact=string(m.sourceArtifact);
    models(i)=m;
end
end

function writeManifestMarkdown(path,manifest)
if isfile(path)
    error('femstudy:shared:ManifestExists', ...
        'MODEL_MANIFEST.md exists without an absent freeze manifest; refusing overwrite.');
end
lines=["# Frozen model manifest"; ""; ...
    "Study: "+manifest.study; ...
    "Git revision: "+manifest.gitRevision; ...
    "Tracked worktree dirty at freeze: "+string(manifest.gitTrackedWorktreeDirty); ...
    "Config SHA-256: "+manifest.configSHA256; ...
    "Holdout-design SHA-256: "+manifest.holdoutDesignSHA256; ...
    "Training IDs: 384 (ranges 1–12, 25–396); validation IDs: 13–18."; ...
    "No final holdout labels were read or generated before this freeze."; ""; ...
    "| Model | Seed | Representation / POD rank | Scaling | Architecture / kernel | Selection | Training time (s), provenance |"; ...
    "|---|---:|---|---|---|---|---|"];
for i=1:numel(manifest.models)
    m=manifest.models(i);
    lines(end+1)="| "+m.id+" | "+string(m.seed)+" | "+m.representation+ ...
        " / "+string(m.podRank)+" | "+m.scaling+" | "+m.architectureOrKernel+ ...
        " | "+m.selectionRule+" | "+string(m.trainingSeconds)+"; "+m.trainingTimeScope+" |"; %#ok<AGROW>
end
lines=[lines; ""; "## SHA-256 inputs, source files, and model artifacts"; ...
    ""; "| Role | Path | SHA-256 |"; "|---|---|---|"];
for i=1:height(manifest.hashes)
    lines(end+1)="| "+manifest.hashes.Role(i)+" | `"+manifest.hashes.Path(i)+ ...
        "` | `"+manifest.hashes.SHA256(i)+"` |"; %#ok<AGROW>
end
writelines(lines,path);
end

function createFinalReferences(~,out,cfg,prepared)
assert(isfile(fullfile(out,'probe_evaluation.mat')), ...
    'femstudy:shared:ProbeRequired','Run the technical probe before final FEM generation.');
c=config('smoke'); c.meshDivisor=3; c.geometricOrder="quadratic";
c.saveRawMesh=false; c.maxDeflectionRatio=0.02;
caseDir=fullfile(out,'holdout_cases');
if ~isfolder(caseDir), mkdir(caseDir); end
for i=1:numel(prepared.holdoutIDs)
    id=prepared.holdoutIDs(i);
    path=fullfile(caseDir,sprintf('case_%06d.mat',id));
    X=prepared.holdoutX(i,:);
    if isfile(path)
        a=load(path,'value');
        assert(isequal(a.value.x,X),'femstudy:shared:FinalLabelConflict', ...
            'Existing FEM artifact has different parameters for sealed ID %d.',id);
        if a.value.status=="success"
            continue
        end
        assert(a.value.status=="failed",'femstudy:shared:FinalLabelConflict', ...
            'Existing holdout artifact has an unknown status: %s',path);
        [successfulPath,~]=successfulReference(caseDir,id,X,cfg);
        if successfulPath~=""
            continue
        end
        path=nextAttemptPath(caseDir,id);
    end
    started=tic;
    try
        result=solve_case(X,c);
        result.seconds=toc(started); result.status="success"; result.id=id;
        result.x=X;
        assert(isfield(result,'S') && isfield(result,'xi') && ...
            isfield(result,'w') && isfield(result,'Y') && ...
            all(isfinite(result.S)) && all(isfinite(result.Y)) && ...
            numel(result.S)==3*cfg.fieldPointCount, ...
            'femstudy:shared:InvalidFEMReference', ...
            'FEM reference for sealed ID %d is incomplete or nonfinite.',id);
        femstudy.data.saveNew(path,result);
    catch err
        failure=struct('status',"failed",'id',id,'x',X, ...
            'seconds',toc(started),'errorIdentifier',string(err.identifier), ...
            'error',string(getReport(err,'extended','hyperlinks','off')));
        if ~isfile(path), femstudy.data.saveNew(path,failure); end
        rethrow(err);
    end
    fprintf('Final holdout FEM %d/%d: %.2fs\n',i,numel(prepared.holdoutIDs),result.seconds);
end
fprintf('Generated all sealed holdout references only after model freeze.\n');
end

function [X,S,seconds,xi,w]=readFinalReferences(out,prepared,cfg)
caseDir=fullfile(out,'holdout_cases');
assert(isfolder(caseDir),'femstudy:shared:FinalLabelsMissing', ...
    'No holdout FEM references exist. Run final_data only after approval.');
X=prepared.holdoutX; ids=prepared.holdoutIDs; seconds=zeros(numel(ids),1);
for i=1:numel(ids)
    [path,v]=successfulReference(caseDir,ids(i),X(i,:),cfg);
    assert(path~="",'femstudy:shared:FinalLabelMissing', ...
        'No successful FEM reference exists for sealed ID %d.',ids(i));
    assert(v.id==ids(i) && isequal(v.x,X(i,:)) && v.status=="success", ...
        'femstudy:shared:FinalLabelMismatch', ...
        'Final reference does not match sealed ID/parameters: %s',path);
    if i==1
        xi=v.xi; w=v.w(:); S=zeros(numel(w),numel(ids));
    else
        assert(isequal(v.xi,xi) && isequal(v.w(:),w), ...
            'femstudy:shared:FinalFieldGridMismatch', ...
            'Final reference field grid or weights differ at ID %d.',ids(i));
    end
    S(:,i)=v.S(:); seconds(i)=v.seconds;
end
assert(size(S,1)==3*cfg.fieldPointCount, ...
    'femstudy:shared:FinalFieldShape','Final field has unexpected dimensions.');
end

function [path,value]=successfulReference(caseDir,id,X,cfg)
base=sprintf('case_%06d',id);
candidates=[string(fullfile(caseDir,[base '.mat'])); ...
    string(fullfile(caseDir,[base '_attempt_*.mat']))];
matches=dir(candidates(2));
files=candidates(1);
files=[files;string(fullfile({matches.folder}',{matches.name}'))];
path=""; value=[];
for i=1:numel(files)
    if ~isfile(files(i)), continue; end
    a=load(files(i),'value'); candidate=a.value;
    assert(isequal(candidate.x,X),'femstudy:shared:FinalLabelConflict', ...
        'Existing artifact parameters differ for sealed ID %d: %s',id,files(i));
    if candidate.status=="success"
        assert(path=="",'femstudy:shared:DuplicateSuccessfulReference', ...
            'Multiple successful FEM references exist for sealed ID %d.',id);
        path=files(i); value=candidate;
    end
end
if path~=""
    assert(numel(value.S)==3*cfg.fieldPointCount && ...
        all(isfinite(value.S)) && all(isfinite(value.Y)), ...
        'femstudy:shared:InvalidFEMReference', ...
        'Stored successful reference is incomplete for sealed ID %d.',id);
end
end

function path=nextAttemptPath(caseDir,id)
base=sprintf('case_%06d',id); attempt=2;
while true
    path=fullfile(caseDir,sprintf('%s_attempt_%03d.mat',base,attempt));
    if ~isfile(path), return; end
    attempt=attempt+1;
end
end

function prepared=loadPrepared(root,out,cfg)
path=fullfile(out,'prepared.mat');
assert(isfile(path),'femstudy:shared:NotPrepared','Run prepare first.');
a=load(path,'value'); prepared=a.value;
assert(isequaln(prepared.config,cfg), ...
    'femstudy:shared:PreparedConfigConflict','Prepared config differs from current config.');
[train,val,test]=sourceSplits(root,cfg);
assert(isequal(prepared.trainIDs,train.id(:)) && ...
    isequal(prepared.validationIDs,val.id(:)) && ...
    isequal(prepared.knownTestIDs,test.id(:)), ...
    'femstudy:shared:SplitChanged','Prepared split identity differs from source data.');
end

function [train,val,test,trainFile,valFile,testFile]=sourceSplits(root,cfg)
source=fullfile(root,cfg.trainingSource);
trainFile=fullfile(source,'train.mat'); valFile=fullfile(source,'val.mat');
testFile=fullfile(source,'test.mat');
assert(isfile(trainFile) && isfile(valFile) && isfile(testFile), ...
    'femstudy:shared:SourceDataMissing','n=384 train/val/test MAT data are incomplete.');
a=load(trainFile,'D'); train=a.D;
a=load(valFile,'D'); val=a.D;
a=load(testFile,'D'); test=a.D;
expected=[];
for i=1:size(cfg.trainingIdRanges,1)
    expected=[expected,cfg.trainingIdRanges(i,1):cfg.trainingIdRanges(i,2)]; %#ok<AGROW>
end
assert(numel(train.id)==cfg.trainingCases && isequal(train.id(:),expected(:)), ...
    'femstudy:shared:TrainingIDs','Training IDs disagree with the versioned ranges.');
assert(isequal(val.id(:),cfg.validationIds(:)) && ...
    isequal(test.id(:),cfg.previousKnownTestIds(:)), ...
    'femstudy:shared:ValidationTestIDs','Validation/test IDs disagree with config.');
assert(isempty(intersect(train.id(:),val.id(:))) && ...
    isempty(intersect(train.id(:),test.id(:))) && ...
    isempty(intersect(val.id(:),test.id(:))), ...
    'femstudy:shared:SplitOverlap','Source training, validation, and known test overlap.');
assert(isequal(train.xi,val.xi) && isequal(train.xi,test.xi) && ...
    isequal(train.w(:),val.w(:)) && isequal(train.w(:),test.w(:)), ...
    'femstudy:shared:SourceGridMismatch','Source data field grids or weights differ.');
assert(size(train.S,1)==3*cfg.fieldPointCount && size(train.X,2)==6 && ...
    all(isfinite(train.S),'all') && all(isfinite(val.S),'all') && ...
    all(isfinite(test.S),'all'), ...
    'femstudy:shared:SourceDataInvalid','Source data fields are invalid.');
end

function [X,ids]=knownDesigns(root,cfg)
X=zeros(0,6); ids=zeros(0,1);
files=[string(fullfile(root,'experiments','active','static_confirmation_v1','design.csv')); ...
    string(fullfile(root,'experiments','active','neural_comparison_20261027_v1','static_final_design.csv'))];
assert(all(isfile(files)),'femstudy:shared:KnownDesignMissing', ...
    'A known confirmation/test design is missing; cannot prove holdout exclusion.');
for i=1:numel(files)
    t=readtable(files(i),TextType="string");
    requiredNames=["id",reshape(string(cfg.parameterNames),1,[])];
    assert(all(ismember(requiredNames, ...
        string(t.Properties.VariableNames))), ...
        'femstudy:shared:KnownDesignColumns','Known design has unexpected columns: %s',files(i));
    ids=[ids;t.id(:)]; %#ok<AGROW>
    X=[X;t{:,cfg.parameterNames}]; %#ok<AGROW>
end
assert(all(isfinite(X),'all'),'femstudy:shared:KnownDesignInvalid', ...
    'Known designs contain nonfinite parameter combinations.');
end

function paths=sourceFiles(root,out,cfg,configPath,preparedPath)
source=fullfile(root,cfg.trainingSource);
neural=fullfile(root,cfg.neuralSource);
paths=[string(configPath);string(preparedPath); ...
    string(fullfile(out,'holdout_design.csv')); ...
    string(fullfile(source,'train.mat'));string(fullfile(source,'val.mat')); ...
    string(fullfile(source,'test.mat'));string(fullfile(source,'models.mat')); ...
    string(fullfile(neural,'seed42','pod.mat'));string(fullfile(neural,'seed42','residual.mat')); ...
    string(fullfile(neural,'seed43','pod.mat'));string(fullfile(neural,'seed43','residual.mat')); ...
    string(fullfile(neural,'seed44','pod.mat'));string(fullfile(neural,'seed44','residual.mat')); ...
    string(fullfile(out,'models','neural_pod_seed42.mat')); ...
    string(fullfile(out,'models','neural_residual_seed42.mat')); ...
    string(fullfile(out,'models','neural_pod_seed43.mat')); ...
    string(fullfile(out,'models','neural_residual_seed43.mat')); ...
    string(fullfile(out,'models','neural_pod_seed44.mat')); ...
    string(fullfile(out,'models','neural_residual_seed44.mat')); ...
    string(fullfile(out,'models','pod_gpr.mat')); ...
    string(fullfile(out,'models','beam_residual_gpr.mat'))];
relative=["src/+femstudy/+fem/beamField.m"; ...
    "src/+femstudy/+models/fitNeural.m";"src/+femstudy/+models/predictNeural.m"; ...
    "src/+femstudy/+models/fitBeamField.m";"src/+femstudy/+models/predictBeamField.m"; ...
    "src/+femstudy/+metrics/field.m";"src/pod_fit.m";"src/pod_encode.m"; ...
    "src/fit_gps.m";"src/predict_reg.m";"src/fit_mlp.m"; ...
    "scripts/matlab/run_training_size_study_impl.m";"src/train_models.m"];
paths=[paths;string(fullfile(root,relative))];
paths=[paths; ...
    string(fullfile(root,'experiments','active','static_confirmation_v1','design.csv')); ...
    string(fullfile(root,'experiments','active','neural_comparison_20261027_v1','static_final_design.csv'))];
paths=unique(paths,'stable');
end

function saveImmutable(path,value,validator)
if isfile(path)
    a=load(path,'value');
    assert(validator(a.value),'femstudy:shared:ArtifactConflict', ...
        'Existing artifact conflicts with requested import/fit: %s',path);
    return
end
femstudy.data.saveNew(path,value);
end

function ensureEvaluationTables(out,label,value)
suffixes=["case_metrics","summary_by_model_seed","seed_spread", ...
    "paired_case_differences","prediction_timings"];
tables={value.caseMetrics,value.summaryByModelSeed,value.seedSpread, ...
    value.pairedCaseDifferences,value.predictionTimings};
for i=1:numel(suffixes)
    path=fullfile(out,label+"_"+suffixes(i)+".csv");
    expected=tables{i};
    if ~isfile(path)
        writetable(expected,path);
        continue
    end
    actual=readtable(path,TextType="string");
    assert(tablesMatch(actual,expected), ...
        'femstudy:shared:EvaluationCSVConflict', ...
        'Existing evaluation CSV conflicts with the immutable MAT result: %s',path);
end
end

function matches=tablesMatch(actual,expected)
matches=isequal(actual.Properties.VariableNames,expected.Properties.VariableNames) && ...
    height(actual)==height(expected);
if ~matches, return; end
for i=1:width(expected)
    a=actual{:,i}; b=expected{:,i};
    if iscell(a), a=string(a); end
    if iscell(b), b=string(b); end
    if isnumeric(a) && isnumeric(b)
        if ~isequal(size(a),size(b)) || ...
                any(abs(a(:)-b(:))>1e-12*max(1,max(abs(b(:)))))
            matches=false; return
        end
    elseif ~isequaln(a,b)
        matches=false; return
    end
end
end

function h=sha256(path)
fid=fopen(path,'rb');
assert(fid>=0,'femstudy:shared:HashOpen','Cannot open file for hashing: %s',path);
cleanup=onCleanup(@()fclose(fid));
bytes=fread(fid,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(bytes(:),'int8'));
digest=typecast(md.digest(),'uint8');
h=string(lower(reshape(dec2hex(digest,2).',1,[])));
clear cleanup
end
