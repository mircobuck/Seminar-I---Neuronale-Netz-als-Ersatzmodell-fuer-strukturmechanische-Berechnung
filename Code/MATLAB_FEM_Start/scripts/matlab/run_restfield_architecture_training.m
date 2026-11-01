function run_restfield_architecture_training(stage)
%RUN_RESTFIELD_ARCHITECTURE_TRAINING Controlled, resumable neural study.
% Stages: prepare, amend_provenance, pilot, architecture, select_architecture, optimizer,
% select_optimizer, gpr, final_fit, evaluate.
if nargin==0
    fprintf(['Stages:\n' ...
        '  run_restfield_architecture_training("prepare")\n' ...
        '  run_restfield_architecture_training("amend_provenance")\n' ...
        '  run_restfield_architecture_training("pilot")\n' ...
        '  run_restfield_architecture_training("architecture")\n' ...
        '  run_restfield_architecture_training("select_architecture")\n' ...
        '  run_restfield_architecture_training("optimizer")\n' ...
        '  run_restfield_architecture_training("select_optimizer")\n' ...
        '  run_restfield_architecture_training("gpr")\n' ...
        '  run_restfield_architecture_training("final_fit")\n' ...
        '  run_restfield_architecture_training("evaluate")\n']);
    return
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
configPath=fullfile(root,'configs','restfield_mlp_architecture_training_20261028_v1.json');
cfg=jsondecode(fileread(configPath));
out=fullfile(root,'experiments','active',cfg.study);
assert(isfolder(out),'femstudy:restfieldStudy:Missing','Study folder is missing: %s',out);
switch validatestring(char(stage), ...
        {'prepare','amend_provenance','pilot','architecture','select_architecture','optimizer', ...
        'select_optimizer','gpr','final_fit','evaluate'})
    case 'prepare'
        prepareStudy(root,out,cfg,configPath);
    case 'amend_provenance'
        amendProvenance(root,out,cfg,configPath);
    case 'pilot'
        prep=verifyPrepared(root,out,cfg,configPath);
        runPilot(root,out,cfg,prep);
    case 'architecture'
        prep=verifyPrepared(root,out,cfg,configPath);
        runArchitectureStage(root,out,cfg,prep);
    case 'select_architecture'
        prep=verifyPrepared(root,out,cfg,configPath);
        selectArchitecture(root,out,cfg,prep);
    case 'optimizer'
        prep=verifyPrepared(root,out,cfg,configPath);
        runOptimizerStage(root,out,cfg,prep);
    case 'select_optimizer'
        prep=verifyPrepared(root,out,cfg,configPath);
        selectOptimizer(root,out,cfg,prep);
    case 'gpr'
        prep=verifyPrepared(root,out,cfg,configPath);
        runGprStage(root,out,cfg,prep);
    case 'final_fit'
        prep=verifyPrepared(root,out,cfg,configPath);
        runFinalFits(root,out,cfg,prep);
    case 'evaluate'
        prep=verifyPrepared(root,out,cfg,configPath);
        analyzeStudy(root,out,cfg,prep);
end
end

function prepareStudy(root,out,cfg,configPath)
protocolPath=fullfile(out,'PROTOCOL.md');
assert(isfile(protocolPath),'femstudy:restfieldStudy:ProtocolMissing', ...
    'Save the preregistered protocol before preparation or any training run.');
source=fullfile(root,cfg.source);
assert(isfile(source),'femstudy:restfieldStudy:TrainingDataMissing', ...
    'Training data file is missing: %s',source);
provenance=currentProvenance(root,configPath,protocolPath,source);
preparedPath=fullfile(out,'prepared.mat');
if isfile(preparedPath)
    loaded=loadLatestPrepared(out);
    assert(isequaln(loaded.provenance,provenance), ...
        'femstudy:restfieldStudy:ProvenanceConflict', ...
        'Existing prepared manifest conflicts with current data, code, or configuration.');
    verifyFoldPreprocessing(out,loaded);
    return
end
a=load(source,'D'); D=a.D;
assert(numel(D.id)==cfg.trainingCaseCount && size(D.X,2)==6 && ...
    size(D.S,2)==cfg.trainingCaseCount && all(isfinite(D.X),'all') && ...
    all(isfinite(D.S),'all') && numel(unique(D.id))==numel(D.id), ...
    'femstudy:restfieldStudy:TrainingDataInvalid','Expected 384 unique, finite training cases.');
expected=[(1:12)';(25:396)'];
assert(isequal(D.id(:),expected), ...
    'femstudy:restfieldStudy:TrainingIDs','Training IDs differ from the preregistered n=384 source.');
excluded=cfg.excludedKnownTestIdRanges;
for k=1:size(excluded,1)
    assert(~any(D.id>=excluded(k,1) & D.id<=excluded(k,2)), ...
        'femstudy:restfieldStudy:TestIDLeakage', ...
        'Training data contain a previously used test ID.');
end
assert(size(D.xi,2)==size(D.S,1)/3 && numel(D.w)==size(D.S,1), ...
    'femstudy:restfieldStudy:FieldShape','Training field grid or weights have invalid dimensions.');

fold=D.X;
lower=min(fold,[],1); span=max(fold,[],1)-lower; span(span==0)=1;
normalized=(fold-lower)./span;
tol=cfg.validation.duplicateGroupingToleranceNormalized;
[~,~,group]=unique(round(normalized/tol)*tol,'rows');
rng(cfg.validation.foldSeed,'twister');
groupOrder=randperm(max(group));
foldCounts=zeros(1,cfg.validation.foldCount);
foldId=zeros(numel(D.id),1);
for g=groupOrder
    [~,which]=min(foldCounts);
    rows=group==g;
    foldId(rows)=which;
    foldCounts(which)=foldCounts(which)+nnz(rows);
end
assert(all(foldId>=1 & foldId<=cfg.validation.foldCount) && ...
    sum(foldCounts)==cfg.trainingCaseCount, ...
    'femstudy:restfieldStudy:FoldAssignment','Fold assignment is incomplete.');
for g=unique(group(:))'
    assert(isscalar(unique(foldId(group==g))), ...
        'femstudy:restfieldStudy:DuplicateAcrossFolds', ...
        'Duplicate normalized parameter combinations cross fold boundaries.');
end
folds=table(D.id(:),foldId,D.X(:,1),D.X(:,2),D.X(:,3),D.X(:,4),D.X(:,5),D.X(:,6), ...
    'VariableNames',{'ID','Fold','L_m','b_m','h_m','E_Pa','nu','Fz_N'});
coverage=foldCoverage(folds,cfg.parameterNames);
value=struct('schema',string(cfg.schema),'folds',folds,'foldCounts',foldCounts, ...
    'parameterCoverage',coverage,'groups',group,'provenance',provenance, ...
    'matlabVersion',version,'toolboxes',ver, ...
    'computer',computer,'numCores',feature('numcores'), ...
    'processorIdentifier',string(getenv('PROCESSOR_IDENTIFIER')), ...
    'createdAt',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
writeImmutableTable(fullfile(out,'fold_assignments.csv'),folds);
writeImmutableTable(fullfile(out,'fold_parameter_coverage.csv'),coverage);
for f=1:cfg.validation.foldCount
    preprocessing=fitFoldPreprocessing(D,folds,cfg,f);
    path=fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f));
    if isfile(path)
        old=load(path,'value');
        assert(isequaln(old.value,preprocessing), ...
            'femstudy:restfieldStudy:FoldPreprocessingConflict', ...
            'Existing fold preprocessing differs; refusing replacement.');
    else
        femstudy.data.saveNew(path,preprocessing);
    end
end
writeImmutableJson(fullfile(out,'provenance.json'),provenance);
femstudy.data.saveNew(preparedPath,value);
verifyFoldPreprocessing(out,value);
fprintf('Prepared %d cases into grouped folds with sizes %s; no FEM or holdout labels read.\n', ...
    numel(D.id),mat2str(foldCounts));
end

function amendProvenance(root,out,cfg,configPath)
basePath=fullfile(out,'prepared.mat');
assert(isfile(basePath),'femstudy:restfieldStudy:AmendmentState', ...
    'Original prepared manifest is missing.');
base=loadLatestPrepared(out);
revisions=dir(fullfile(out,'prepared_revision_*.mat'));
revisionNumber=numel(revisions)+1;
revisionPath=fullfile(out,sprintf('prepared_revision_%02d.mat',revisionNumber));
protocolPath=fullfile(out,'PROTOCOL.md');
source=fullfile(root,cfg.source);
updated=currentProvenance(root,configPath,protocolPath,source);
assert(strcmp(base.provenance.configSHA256,updated.configSHA256) && ...
    strcmp(base.provenance.trainingDataSHA256,updated.trainingDataSHA256) && ...
    base.provenance.gitRevision==updated.gitRevision && ...
    base.matlabVersion==updated.matlabVersion, ...
    'femstudy:restfieldStudy:AmendmentScope', ...
    'Amendment cannot change config, training data, Git revision, or MATLAB version.');
files=dir(fullfile(out,'runs','*.mat'));
acceptedHashes=acceptedCodeHashes(out,base);
knownStages=["pilot","architecture","optimizer","gpr","final_fit"];
knownPrefixes=["PILOT_","A_","B_LBFGS_","GPR_","FINAL_"];
for i=1:numel(files)
    a=load(fullfile(files(i).folder,files(i).name),'value');
    record=a.value;
    stageIndex=find(knownStages==record.metadata.stage,1);
    isKnownRun=~isempty(stageIndex) && ...
        startsWith(record.runID,knownPrefixes(stageIndex)) && ...
        any(record.status==["completed","failed"]);
    assert(isKnownRun && ...
        strcmp(record.metadata.configSHA256,base.provenance.configSHA256) && ...
        strcmp(record.metadata.dataSHA256,base.provenance.trainingDataSHA256) && ...
        any(acceptedHashes==record.metadata.codeSHA256), ...
        'femstudy:restfieldStudy:AmendmentAfterCandidates', ...
        'Only terminal study runs with verified historical provenance may be amended.');
end
verifyFoldPreprocessing(out,base);
original=load(basePath,'value');
updatedManifest=base;
if isfield(base,'previousProvenance')
    updatedManifest.previousProvenance=base.previousProvenance;
else
    updatedManifest.previousProvenance=original.value.provenance;
end
updatedManifest.provenance=updated;
updatedManifest.amendment=struct('number',revisionNumber, ...
    'reason',"A technical study-evaluation grid check was corrected; all prior run and selection artifacts are retained and verified against their recorded provenance. Data, models, hyperparameters, and selection rules are unchanged.", ...
    'createdAt',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
femstudy.data.saveNew(revisionPath,updatedManifest);
writeImmutableJson(fullfile(out,sprintf('provenance_revision_%02d.json',revisionNumber)),updated);
fprintf('Recorded provenance amendment %d; earlier manifests and pilot artifacts remain unchanged.\n',revisionNumber);
end

function prepared=loadLatestPrepared(out)
revisions=dir(fullfile(out,'prepared_revision_*.mat'));
if ~isempty(revisions)
    [~,order]=sort({revisions.name});
    a=load(fullfile(out,revisions(order(end)).name),'value');
else
    a=load(fullfile(out,'prepared.mat'),'value');
end
prepared=a.value;
end

function hashes=acceptedCodeHashes(out,prepared)
files=[dir(fullfile(out,'prepared.mat'));dir(fullfile(out,'prepared_revision_*.mat'))];
hashes=strings(numel(files)+1,1);
for i=1:numel(files)
    a=load(fullfile(files(i).folder,files(i).name),'value');
    hashes(i)=combinedCodeHash(a.value.provenance);
end
hashes(end)=combinedCodeHash(prepared.provenance);
hashes=unique(hashes,'stable');
end

function provenance=currentProvenance(root,configPath,protocolPath,source)
codePaths={ ...
    fullfile(root,'scripts','matlab','run_restfield_architecture_training.m'), ...
    fullfile(root,'scripts','matlab','analyze_restfield_architecture_training.m'), ...
    fullfile(root,'src','+femstudy','+models','fitControlledRestMLP.m'), ...
    fullfile(root,'src','+femstudy','+models','predictNeural.m'), ...
    fullfile(root,'src','+femstudy','+fem','beamField.m'), ...
    fullfile(root,'src','+femstudy','+data','saveNew.m'), ...
    fullfile(root,'src','fit_gps.m'),fullfile(root,'src','fit_mlp.m'), ...
    fullfile(root,'src','predict_reg.m'),fullfile(root,'src','pod_fit.m'), ...
    fullfile(root,'src','pod_encode.m'),fullfile(root,'src','field_error.m')};
hashes=strings(numel(codePaths),2);
for i=1:numel(codePaths)
    assert(isfile(codePaths{i}),'femstudy:restfieldStudy:SourceMissing', ...
        'Required source file is missing: %s',codePaths{i});
    hashes(i,:)=[string(relativePath(root,codePaths{i})),sha256File(codePaths{i})];
end
[~,revision]=system(sprintf('git -C "%s" rev-parse HEAD',root));
[~,gitStatus]=system(sprintf('git -C "%s" status --short',root));
dl=ver('Deep Learning Toolbox'); sm=ver('Statistics and Machine Learning Toolbox');
provenance=struct('configSHA256',sha256File(configPath), ...
    'protocolSHA256',sha256File(protocolPath),'trainingDataSHA256',sha256File(source), ...
    'codePaths',hashes(:,1),'codeSHA256',hashes(:,2), ...
    'gitRevision',strtrim(string(revision)),'gitStatusAtPreparation',strtrim(string(gitStatus)), ...
    'matlabVersion',string(version),'deepLearningToolbox',toolboxVersion(dl), ...
    'statisticsToolbox',toolboxVersion(sm),'computer',string(computer), ...
    'processorIdentifier',string(getenv('PROCESSOR_IDENTIFIER')));
end

function name=toolboxVersion(toolbox)
if isempty(toolbox), name="not-installed"; else, name=string(toolbox(1).Version); end
end

function verify=verifyPrepared(root,out,cfg,configPath)
preparedPath=fullfile(out,'prepared.mat');
assert(isfile(preparedPath),'femstudy:restfieldStudy:NotPrepared', ...
    'Run the prepare stage first.');
protocolPath=fullfile(out,'PROTOCOL.md');
source=fullfile(root,cfg.source);
verify=loadLatestPrepared(out);
now=currentProvenance(root,configPath,protocolPath,source);
now.gitStatusAtPreparation=verify.provenance.gitStatusAtPreparation;
assert(isequaln(now,verify.provenance), ...
    'femstudy:restfieldStudy:ResumeConflict', ...
    'Configuration, protocol, source data, code, or MATLAB provenance changed; refusing resume.');
verifyFoldPreprocessing(out,verify);
end

function verifyFoldPreprocessing(out,prepared)
for f=1:numel(prepared.foldCounts)
    path=fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f));
    assert(isfile(path),'femstudy:restfieldStudy:FoldPreprocessingMissing', ...
        'Fold preprocessing artifact is missing: %s',path);
    p=load(path,'value'); v=p.value;
    assert(v.fold==f && numel(v.trainIDs)==sum(prepared.folds.Fold~=f) && ...
        numel(v.validationIDs)==sum(prepared.folds.Fold==f) && ...
        isempty(intersect(v.trainIDs,v.validationIDs)), ...
        'femstudy:restfieldStudy:FoldPreprocessingConflict', ...
        'Fold preprocessing IDs or role counts conflict.');
end
end

function preprocessing=fitFoldPreprocessing(D,folds,cfg,f)
isVal=folds.Fold==f;
trainIDs=folds.ID(~isVal); validationIDs=folds.ID(isVal);
[~,tr]=ismember(trainIDs,D.id); [~,va]=ismember(validationIDs,D.id);
assert(all(tr>0) && all(va>0) && isempty(intersect(trainIDs,validationIDs)));
beamTrain=femstudy.fem.beamField(D.X(tr,:),D.xi);
beamVal=femstudy.fem.beamField(D.X(va,:),D.xi);
residualTrain=D.S(:,tr)-beamTrain;
residualVal=D.S(:,va)-beamVal;
P=pod_fit(residualTrain,D.w,cfg.pod.maximumRank);
rank=find(P.energy>=cfg.pod.energyTolerance,1);
if isempty(rank), rank=min(cfg.pod.maximumRank,size(P.V,2)); end
P.V=P.V(:,1:rank); P.r=rank;
P.selectedEnergy=P.energy(rank);
Atrain=pod_encode(P,residualTrain);
Avalidation=pod_encode(P,residualVal);
projected=P.mean+P.V*Avalidation';
projection=fieldMetrics(D.S(:,va),beamVal+projected,D.w,D.X(va,:), ...
    cfg.selection.referenceNormFloor_m);
preprocessing=struct('fold',f,'trainIDs',trainIDs(:),'validationIDs',validationIDs(:), ...
    'trainX',D.X(tr,:),'validationX',D.X(va,:), ...
    'trainField',D.S(:,tr),'validationField',D.S(:,va), ...
    'xi',D.xi,'weights',D.w,'pod',P,'trainCoefficients',Atrain, ...
    'validationCoefficients',Avalidation,'projectionMetrics',projection, ...
    'projectionMeanRelativeError',mean(projection.RelativeWeightedFieldError), ...
    'projectionP95RelativeError',nearestRank(projection.RelativeWeightedFieldError,.95), ...
    'projectionMaxRelativeError',max(projection.RelativeWeightedFieldError), ...
    'podRank',rank,'podEnergyRetained',P.selectedEnergy, ...
    'rankCapReached',rank==cfg.pod.maximumRank && P.selectedEnergy<cfg.pod.energyTolerance);
end

function coverage=foldCoverage(folds,parameterNames)
rows=cell(0,7);
for f=unique(folds.Fold(:))'
    subset=folds(folds.Fold==f,:);
    for j=1:numel(parameterNames)
        x=subset.(parameterNames{j});
        rows(end+1,:)={f,string(parameterNames{j}),numel(x),min(x), ...
            median(x),max(x),std(x)}; %#ok<AGROW>
    end
end
coverage=cell2table(rows,'VariableNames', ...
    {'Fold','Parameter','CaseCount','Minimum','Median','Maximum','StandardDeviation'});
end

function runPilot(root,out,cfg,prepared)
pilot=cfg.technicalPilot;
p=load(fullfile(out,'preprocessing',sprintf('fold_%02d.mat',pilot.fold)),'value');
for optimizer=["adam","lbfgs"]
    budget=pilot.adamEpochs;
    if optimizer=="lbfgs", budget=pilot.lbfgsIterations; end
    base=sprintf('PILOT_%s_fold%02d_seed%d',upper(optimizer),pilot.fold,pilot.seed);
    if isempty(latestSuccessfulRun(out,base))
        runMlp(root,out,cfg,prepared,p.value,base,"pilot","[16]",16,optimizer,pilot.seed,budget);
    end
end
gprPilot=sprintf('PILOT_GPR_fold%02d_seed%d',pilot.fold,cfg.gprReference.seeds(1));
if isempty(latestSuccessfulRun(out,gprPilot))
    runGpr(root,out,cfg,prepared,p.value,gprPilot,pilot.fold);
end
pilotArtifacts=dir(fullfile(out,'runs','PILOT_*.mat'));
assert(~isempty(pilotArtifacts) && ...
    ~isempty(latestSuccessfulRun(out,sprintf('PILOT_ADAM_fold%02d_seed%d',pilot.fold,pilot.seed))) && ...
    ~isempty(latestSuccessfulRun(out,sprintf('PILOT_LBFGS_fold%02d_seed%d',pilot.fold,pilot.seed))) && ...
    ~isempty(latestSuccessfulRun(out,sprintf('PILOT_GPR_fold%02d_seed%d', ...
        pilot.fold,cfg.gprReference.seeds(1)))), ...
    'femstudy:restfieldStudy:PilotIncomplete', ...
    'The technical pilot must retain successful Adam, L-BFGS, and GPR runs.');
estimatePilotRuntime(out,cfg,p.value);
end

function runArchitectureStage(root,out,cfg,prepared)
for arch=1:numel(cfg.architectureStage.architectures)
    widths=cfg.architectureStage.architectures{arch};
    architecture=architectureText(widths);
    label=architectureID(widths);
    for f=1:cfg.validation.foldCount
        p=load(fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f)),'value');
        for seed=cfg.architectureStage.seeds(:)'
            base=sprintf('A_%s_fold%02d_seed%d',label,f,seed);
            runMlp(root,out,cfg,prepared,p.value,base,"architecture", ...
                architecture,widths,"adam",seed,cfg.architectureStage.maximumEpochs);
        end
    end
end
end

function selectArchitecture(~,out,cfg,prepared)
runs=loadRuns(out,"A_");
expected=numel(cfg.architectureStage.architectures)*cfg.validation.foldCount* ...
    numel(cfg.architectureStage.seeds);
assert(numel(runs)==expected && all(string({runs.status})=="completed"), ...
    'femstudy:restfieldStudy:ArchitectureRunsIncomplete', ...
    'Expected %d completed architecture runs; inspect attempt_ledger.csv.',expected);
rows=cell(0,9);
for arch=1:numel(cfg.architectureStage.architectures)
    widths=cfg.architectureStage.architectures{arch};
    label=architectureID(widths);
    metrics=collectRunMetrics(runs,string(label));
    rows(end+1,:)={string(label),architectureText(widths),mean(metrics.RelativeWeightedFieldError), ...
        median(metrics.RelativeWeightedFieldError),nearestRank(metrics.RelativeWeightedFieldError,.95), ...
        max(metrics.RelativeWeightedFieldError),mean(metrics.AbsoluteWeightedRMS_m), ...
        mean(metrics.PODProjectionRelativeError),numel(unique(metrics.CaseID))}; %#ok<AGROW>
end
summary=cell2table(rows,'VariableNames',{'ArchitectureID','Architecture', ...
    'MeanRelativeError','MedianRelativeError','P95RelativeError','MaximumRelativeError', ...
    'MeanAbsoluteRMS_m','MeanPODProjectionError','PhysicalCaseCount'});
best=min(summary.MeanRelativeError);
chosen=find(abs(summary.MeanRelativeError-best)<=1e-12,1,'first');
value=struct('stage',"architecture",'summary',summary, ...
    'chosenArchitectureID',summary.ArchitectureID(chosen), ...
    'chosenArchitecture',summary.Architecture(chosen), ...
    'tieBreak',"first listed, simplest architecture within absolute 1e-12", ...
    'candidateRunIDs',string({runs.runID}), ...
    'provenance',prepared.provenance,'selectedAt',string(datetime('now')));
femstudy.data.saveNew(fullfile(out,'architecture_selection.mat'),value);
writeImmutableTable(fullfile(out,'architecture_selection.csv'),summary);
end

function runOptimizerStage(root,out,cfg,prepared)
selection=loadSelection(out,'architecture_selection.mat',prepared);
widths=findArchitecture(cfg.architectureStage.architectures,selection.chosenArchitectureID);
architecture=architectureText(widths);
label=architectureID(widths);
for f=1:cfg.validation.foldCount
    p=load(fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f)),'value');
    for seed=cfg.optimizerStage.seeds(:)'
        base=sprintf('B_LBFGS_%s_fold%02d_seed%d',label,f,seed);
        runMlp(root,out,cfg,prepared,p.value,base,"optimizer", ...
            architecture,widths,"lbfgs",seed,cfg.optimizerStage.maximumLbfgsIterations);
        adam=latestSuccessfulRun(out,sprintf('A_%s_fold%02d_seed%d',label,f,seed));
        lbfgs=latestSuccessfulRun(out,base);
        if ~isempty(adam) && ~isempty(lbfgs)
            assert(strcmp(adam.model.initialWeightsHash,lbfgs.model.initialWeightsHash), ...
                'femstudy:restfieldStudy:InitialWeightsMismatch', ...
                'Adam/L-BFGS initial parameter hashes differ for fold %d seed %d.',f,seed);
        end
    end
end
end

function selectOptimizer(~,out,cfg,prepared)
architectureSelection=loadSelection(out,'architecture_selection.mat',prepared);
widths=findArchitecture(cfg.architectureStage.architectures, ...
    architectureSelection.chosenArchitectureID);
label=architectureID(widths);
adam=loadRuns(out,"A_"+label+"_");
lbfgs=loadRuns(out,"B_LBFGS_"+label+"_");
expected=cfg.validation.foldCount*numel(cfg.optimizerStage.seeds);
assert(numel(adam)==expected && numel(lbfgs)==expected && ...
    all(string({adam.status})=="completed") && all(string({lbfgs.status})=="completed"), ...
    'femstudy:restfieldStudy:OptimizerRunsIncomplete', ...
    'Expected paired Adam and L-BFGS runs for the selected architecture.');
assertSameInitialWeights(adam,lbfgs);
adamMetrics=collectRunMetrics(adam,string(label));
lbfgsMetrics=collectRunMetrics(lbfgs,string(label));
summary=optimizerSummary(adamMetrics,lbfgsMetrics,adam,lbfgs);
best=min(summary.MeanRelativeError);
chosen=find(abs(summary.MeanRelativeError-best)<=1e-12,1,'first');
value=struct('stage',"optimizer",'architectureID',string(label), ...
    'architecture',architectureText(widths),'summary',summary, ...
    'chosenOptimizer',summary.Optimizer(chosen), ...
    'tieBreak',"Adam is preferred within absolute 1e-12", ...
    'adamRunIDs',string({adam.runID}),'lbfgsRunIDs',string({lbfgs.runID}), ...
    'provenance',prepared.provenance,'selectedAt',string(datetime('now')));
femstudy.data.saveNew(fullfile(out,'optimizer_selection.mat'),value);
writeImmutableTable(fullfile(out,'optimizer_selection.csv'),summary);
end

function runGprStage(root,out,cfg,prepared)
for f=1:cfg.validation.foldCount
    p=load(fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f)),'value');
    base=sprintf('GPR_fold%02d_seed42',f);
    runGpr(root,out,cfg,prepared,p.value,base,f);
end
end

function runFinalFits(root,out,cfg,prepared)
architectureSelection=loadSelection(out,'architecture_selection.mat',prepared);
optimizerSelection=loadSelection(out,'optimizer_selection.mat',prepared);
widths=findArchitecture(cfg.architectureStage.architectures, ...
    architectureSelection.chosenArchitectureID);
optimizer=optimizerSelection.chosenOptimizer;
source=fullfile(root,cfg.source); a=load(source,'D'); D=a.D;
assert(numel(D.id)==cfg.trainingCaseCount);
prepPath=fullfile(out,'final_preprocessing.mat');
if isfile(prepPath)
    a=load(prepPath,'value'); finalPrep=a.value;
    assert(isequal(finalPrep.trainIDs,D.id(:)) && ...
        strcmp(finalPrep.provenance.configSHA256,prepared.provenance.configSHA256), ...
        'femstudy:restfieldStudy:FinalPreprocessingConflict', ...
        'Existing all-data preprocessing conflicts with current training data or config.');
else
    finalPrep=fitFinalPreprocessing(D,cfg,prepared.provenance);
    femstudy.data.saveNew(prepPath,finalPrep);
end
for seed=cfg.architectureStage.seeds(:)'
    base=sprintf('FINAL_%s_%s_seed%d',architectureID(widths),upper(optimizer),seed);
    runFinalMlp(root,out,cfg,prepared,finalPrep,base,widths,optimizer,seed);
end
end

function finalPrep=fitFinalPreprocessing(D,cfg,provenance)
beam=femstudy.fem.beamField(D.X,D.xi);
residual=D.S-beam;
P=pod_fit(residual,D.w,cfg.pod.maximumRank);
rank=find(P.energy>=cfg.pod.energyTolerance,1);
if isempty(rank), rank=min(cfg.pod.maximumRank,size(P.V,2)); end
P.V=P.V(:,1:rank); P.r=rank; P.selectedEnergy=P.energy(rank);
finalPrep=struct('trainIDs',D.id(:),'trainX',D.X,'xi',D.xi,'weights',D.w, ...
    'pod',P,'trainCoefficients',pod_encode(P,residual), ...
    'podRank',rank,'podEnergyRetained',P.selectedEnergy, ...
    'provenance',provenance);
end

function runMlp(~,out,cfg,prepared,p,base,stage,architecture,widths,optimizer,seed,budget)
meta=struct('baseRunID',string(base),'stage',string(stage),'model',"BeamResidualMLP", ...
    'architecture',string(architecture),'optimizer',string(optimizer), ...
    'fold',p.fold,'seed',seed,'trainingCount',numel(p.trainIDs), ...
    'validationCount',numel(p.validationIDs),'podRank',p.podRank, ...
    'configSHA256',prepared.provenance.configSHA256, ...
    'dataSHA256',prepared.provenance.trainingDataSHA256, ...
    'codeSHA256',combinedCodeHash(prepared.provenance), ...
    'acceptedCodeSHA256',acceptedCodeHashes(out,prepared));
[runID,path,shouldRun]=beginAttempt(out,meta);
if ~shouldRun, return; end
started=tic;
try
    options=mlpOptions(cfg,optimizer,seed,widths,budget);
    [reg,history]=femstudy.models.fitControlledRestMLP(p.trainX,p.trainCoefficients,options);
    coefficientPrediction=predict_reg(reg,p.validationX);
    prediction=addResidualField(p,coefficientPrediction);
    metrics=fieldMetrics(p.validationField,prediction,p.weights, ...
        p.validationX,cfg.selection.referenceNormFloor_m);
    metrics.PODProjectionRelativeError=p.projectionMetrics.RelativeWeightedFieldError;
    metrics.CaseID=p.validationIDs(:);
    metrics=addKeys(metrics,runID,stage,"BeamResidualMLP",architecture,optimizer,p.fold,seed);
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"completed",'metadata',meta,'model',reg,'history',history, ...
        'caseMetrics',metrics,'podRank',p.podRank, ...
        'podEnergyRetained',p.podEnergyRetained, ...
        'trainingSeconds',reg.trainingSeconds,'completedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"completed",toc(started),history, ...
            history.stopReason,"","",path);
catch err
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"failed",'metadata',meta,'errorIdentifier',string(err.identifier), ...
        'errorMessage',string(err.message),'errorReport',string(getReport(err,'extended','hyperlinks','off')), ...
        'trainingSeconds',toc(started),'failedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"failed",toc(started),struct, ...
        "exception",err.identifier,err.message,path);
    fprintf(2,'Failed %s: %s: %s\n',runID,err.identifier,err.message);
end
end

function runGpr(~,out,cfg,prepared,p,base,fold)
stage="gpr";
if startsWith(string(base),"PILOT_"), stage="pilot"; end
meta=struct('baseRunID',string(base),'stage',stage,'model',"GPRReference", ...
    'architecture',"shared-POD-coefficients",'optimizer',string(cfg.gprReference.kernel), ...
    'fold',fold,'seed',cfg.gprReference.seeds(1), ...
    'trainingCount',numel(p.trainIDs),'validationCount',numel(p.validationIDs), ...
    'podRank',p.podRank,'configSHA256',prepared.provenance.configSHA256, ...
    'dataSHA256',prepared.provenance.trainingDataSHA256, ...
    'codeSHA256',combinedCodeHash(prepared.provenance), ...
    'acceptedCodeSHA256',acceptedCodeHashes(out,prepared));
[runID,path,shouldRun]=beginAttempt(out,meta);
if ~shouldRun, return; end
started=tic;
try
    reg=fit_gps(p.trainX,p.trainCoefficients,cfg.gprReference.kernel);
    trainingSeconds=toc(started);
    prediction=predict_reg(reg,p.validationX);
    field=addResidualField(p,prediction);
    metrics=fieldMetrics(p.validationField,field,p.weights,p.validationX, ...
        cfg.selection.referenceNormFloor_m);
    metrics.PODProjectionRelativeError=p.projectionMetrics.RelativeWeightedFieldError;
    metrics.CaseID=p.validationIDs(:);
    metrics=addKeys(metrics,runID,"gpr","GPRReference", ...
        cfg.gprReference.kernel,"fixed-kernel",fold,cfg.gprReference.seeds(1));
    model=struct('kind',"residual",'reg',reg,'pod',p.pod,'xi',p.xi, ...
        'weights',p.weights,'trainIDs',p.trainIDs,'validationIDs',p.validationIDs, ...
        'kernel',string(cfg.gprReference.kernel));
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"completed",'metadata',meta,'model',model,'history',struct, ...
        'caseMetrics',metrics, ...
        'podRank',p.podRank,'podEnergyRetained',p.podEnergyRetained, ...
        'trainingSeconds',trainingSeconds, ...
        'completedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"completed",trainingSeconds,struct, ...
        "GPR fit completed","","",path);
catch err
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"failed",'metadata',meta,'errorIdentifier',string(err.identifier), ...
        'errorMessage',string(err.message),'errorReport',string(getReport(err,'extended','hyperlinks','off')), ...
        'trainingSeconds',toc(started),'failedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"failed",toc(started),struct, ...
        "exception",err.identifier,err.message,path);
    fprintf(2,'Failed %s: %s: %s\n',runID,err.identifier,err.message);
end
end

function estimatePilotRuntime(out,cfg,p)
optimizers=["ADAM","LBFGS","GPR"];
seconds=zeros(3,1);
for i=1:numel(optimizers)
    base=sprintf('PILOT_%s_fold%02d_seed%d',optimizers(i), ...
        cfg.technicalPilot.fold,cfg.technicalPilot.seed);
    if optimizers(i)=="GPR"
        base=sprintf('PILOT_GPR_fold%02d_seed%d', ...
            cfg.technicalPilot.fold,cfg.gprReference.seeds(1));
    end
    run=latestSuccessfulRun(out,base);
    assert(~isempty(run),'femstudy:restfieldStudy:PilotTimingMissing', ...
        'Expected a successful pilot timing for %s.',optimizers(i));
    seconds(i)=run.trainingSeconds;
end
adamPerEpoch=seconds(1)/cfg.technicalPilot.adamEpochs;
lbfgsPerIteration=seconds(2)/cfg.technicalPilot.lbfgsIterations;
rank=p.podRank;
architectures=cfg.architectureStage.architectures;
adamEstimate=0;
parameterCounts=zeros(numel(architectures),1);
for i=1:numel(architectures)
    parameterCounts(i)=mlpParameterCount(architectures{i},rank);
    adamEstimate=adamEstimate+cfg.validation.foldCount* ...
        numel(cfg.architectureStage.seeds)*cfg.architectureStage.maximumEpochs* ...
        adamPerEpoch*parameterCounts(i)/mlpParameterCount(16,rank);
end
lbfgsEstimate=cfg.validation.foldCount*numel(cfg.optimizerStage.seeds)* ...
    cfg.optimizerStage.maximumLbfgsIterations*lbfgsPerIteration* ...
    max(parameterCounts)/mlpParameterCount(16,rank);
gprEstimate=cfg.validation.foldCount*seconds(3);
finalAdamEstimate=numel(cfg.architectureStage.seeds)*cfg.architectureStage.maximumEpochs* ...
    adamPerEpoch*max(parameterCounts)/mlpParameterCount(16,rank)* ...
    cfg.campaign.finalTrainingCasesPerSeed/cfg.validation.expectedTrainingCasesPerFold;
finalLbfgsEstimate=numel(cfg.architectureStage.seeds)* ...
    cfg.optimizerStage.maximumLbfgsIterations*lbfgsPerIteration* ...
    max(parameterCounts)/mlpParameterCount(16,rank)* ...
    cfg.campaign.finalTrainingCasesPerSeed/cfg.validation.expectedTrainingCasesPerFold;
estimate=struct('pilotSeconds',seconds(:)','adamArchitectureStageSeconds',adamEstimate, ...
    'optimizerStageUpperEstimateSeconds',lbfgsEstimate, ...
    'gprStageSeconds',gprEstimate, ...
    'finalFitEstimateAdamSeconds',finalAdamEstimate, ...
    'finalFitEstimateLbfgsSeconds',finalLbfgsEstimate, ...
    'remainingTotalLowerEstimateSeconds',adamEstimate+lbfgsEstimate+gprEstimate+ ...
        min(finalAdamEstimate,finalLbfgsEstimate), ...
    'remainingTotalUpperEstimateSeconds',adamEstimate+lbfgsEstimate+gprEstimate+ ...
        max(finalAdamEstimate,finalLbfgsEstimate), ...
    'architectureParameterCounts',parameterCounts, ...
    'method',"linear scaling by parameter count, budget steps, and final/cv sample count; rough estimate, not a measured total", ...
    'foldTrainingCases',cfg.validation.expectedTrainingCasesPerFold);
estimatePath=fullfile(out,'pilot_runtime_estimate.json');
if isfile(estimatePath)
    actual=jsondecode(fileread(estimatePath));
    fields=fieldnames(estimate);
    for i=1:numel(fields)
        expected=estimate.(fields{i});
        stored=actual.(fields{i});
        if isnumeric(expected) && isnumeric(stored)
            assert(numel(expected)==numel(stored) && ...
                all(abs(double(expected(:))-double(stored(:)))<= ...
                1e-12*max(1,max(abs(double(expected(:))))), 'all'), ...
                'femstudy:restfieldStudy:PilotEstimateConflict', ...
                'Stored pilot estimate differs in field %s.',fields{i});
        else
            assert(isequal(string(stored),string(expected)), ...
                'femstudy:restfieldStudy:PilotEstimateConflict', ...
                'Stored pilot estimate differs in field %s.',fields{i});
        end
    end
else
    writeImmutableJson(estimatePath,estimate);
end
fprintf('Pilot-based remaining campaign estimate: %.1f-%.1f minutes.\n', ...
    estimate.remainingTotalLowerEstimateSeconds/60,estimate.remainingTotalUpperEstimateSeconds/60);
end

function count=mlpParameterCount(widths,outputWidth)
dimensions=[6,widths(:)',outputWidth];
count=sum(dimensions(1:end-1).*dimensions(2:end)+dimensions(2:end));
end

function runFinalMlp(~,out,cfg,prepared,p,base,widths,optimizer,seed)
meta=struct('baseRunID',string(base),'stage',"final_fit",'model',"BeamResidualMLP", ...
    'architecture',architectureText(widths),'optimizer',string(optimizer), ...
    'fold',0,'seed',seed,'trainingCount',numel(p.trainIDs),'validationCount',0, ...
    'podRank',p.podRank,'configSHA256',prepared.provenance.configSHA256, ...
    'dataSHA256',prepared.provenance.trainingDataSHA256, ...
    'codeSHA256',combinedCodeHash(prepared.provenance), ...
    'acceptedCodeSHA256',acceptedCodeHashes(out,prepared));
[runID,path,shouldRun]=beginAttempt(out,meta);
if ~shouldRun, return; end
started=tic;
try
    budget=cfg.architectureStage.maximumEpochs;
    if optimizer=="lbfgs", budget=cfg.optimizerStage.maximumLbfgsIterations; end
    options=mlpOptions(cfg,optimizer,seed,widths,budget);
    [reg,history]=femstudy.models.fitControlledRestMLP(p.trainX,p.trainCoefficients,options);
    reg.trainIDs=p.trainIDs; reg.validationIDs=zeros(0,1);
    reg.schema="controlled-restfield-coefficient-mlp-v1";
    model=struct('schema',"controlled-restfield-mlp-v1",'kind',"residual", ...
        'reg',reg,'pod',p.pod,'xi',p.xi,'weights',p.weights, ...
        'trainIDs',p.trainIDs,'validationIDs',zeros(0,1), ...
        'architecture',architectureText(widths),'optimizer',string(optimizer), ...
        'seed',seed);
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"completed",'metadata',meta,'model',model,'history',history, ...
        'caseMetrics',table(),'podRank',p.podRank,'podEnergyRetained',p.podEnergyRetained, ...
        'trainingSeconds',reg.trainingSeconds,'completedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"completed",toc(started),history, ...
            history.stopReason+"; all 384 established training cases; no holdout evaluated", ...
            "","",path);
catch err
    record=struct('runID',string(runID),'baseRunID',string(base), ...
        'status',"failed",'metadata',meta,'errorIdentifier',string(err.identifier), ...
        'errorMessage',string(err.message),'errorReport',string(getReport(err,'extended','hyperlinks','off')), ...
        'trainingSeconds',toc(started),'failedAt',string(datetime('now')));
    femstudy.data.saveNew(path,record);
    finishAttempt(out,runID,"failed",toc(started),struct, ...
        "exception",err.identifier,err.message,path);
    fprintf(2,'Failed %s: %s: %s\n',runID,err.identifier,err.message);
end
end

function options=mlpOptions(cfg,optimizer,seed,widths,budget)
options=struct('HiddenLayers',widths,'Optimizer',string(optimizer),'Seed',seed, ...
    'Budget',budget,'BatchSize',cfg.architectureStage.batchSize, ...
    'InitialLearnRate',cfg.architectureStage.initialLearningRate, ...
    'L2Regularization',cfg.architectureStage.l2Regularization, ...
    'HistorySize',cfg.optimizerStage.lbfgsHistorySize, ...
    'GradientTolerance',cfg.optimizerStage.lbfgsGradientTolerance, ...
    'StepTolerance',cfg.optimizerStage.lbfgsStepTolerance);
end

function field=addResidualField(p,coefficients)
beam=femstudy.fem.beamField(p.validationX,p.xi);
field=beam+p.pod.mean+p.pod.V*coefficients';
end

function metrics=fieldMetrics(reference,prediction,weights,X,denominatorFloor)
assert(isequal(size(reference),size(prediction)) && ...
    all(isfinite(reference),'all') && all(isfinite(prediction),'all'), ...
    'femstudy:restfieldStudy:PredictionInvalid','Predicted field is invalid or has wrong shape.');
absolute=sqrt(sum(weights(:).*(prediction-reference).^2,1))';
referenceNorm=sqrt(sum(weights(:).*reference.^2,1))';
relative=absolute./max(referenceNorm,denominatorFloor);
metrics=table(relative,absolute,referenceNorm, ...
    'VariableNames',{'RelativeWeightedFieldError','AbsoluteWeightedRMS_m','ReferenceWeightedNorm_m'});
metrics.ParameterVolume_m3=prod(X(:,1:3),2);
end

function metrics=addKeys(metrics,runID,stage,model,architecture,optimizer,fold,seed)
n=height(metrics);
metrics=addvars(metrics,repmat(string(runID),n,1),repmat(string(stage),n,1), ...
    repmat(string(model),n,1),repmat(string(architecture),n,1), ...
    repmat(string(optimizer),n,1),repmat(fold,n,1),repmat(seed,n,1), ...
    'Before','RelativeWeightedFieldError', ...
    'NewVariableNames',{'RunID','Stage','Model','Architecture','Optimizer','Fold','Seed'});
end

function [runID,path,shouldRun]=beginAttempt(out,meta)
runs=fullfile(out,'runs');
if ~isfolder(runs), mkdir(runs); end
existing=dir(fullfile(runs,[char(meta.baseRunID),'*.mat']));
attempt=1; shouldRun=true; runID=string(meta.baseRunID);
for i=1:numel(existing)
    oldPath=fullfile(existing(i).folder,existing(i).name);
    old=load(oldPath,'value'); value=old.value;
    assert(value.metadata.baseRunID==meta.baseRunID && ...
        strcmp(value.metadata.configSHA256,meta.configSHA256) && ...
        strcmp(value.metadata.dataSHA256,meta.dataSHA256) && ...
        (strcmp(value.metadata.codeSHA256,meta.codeSHA256) || ...
        any(string(meta.acceptedCodeSHA256)==value.metadata.codeSHA256)), ...
        'femstudy:restfieldStudy:RunArtifactConflict', ...
        'Existing run artifact has conflicting config, data, or unrecognized historical code: %s',oldPath);
    if value.status=="completed"
        recoverLedgerSuccess(out,value,oldPath);
        shouldRun=false; runID=value.runID; path=oldPath;
        return
    elseif value.status=="failed"
        recoverLedgerFailure(out,value,oldPath);
    end
    attempt=attempt+1;
end
ledgerPath=fullfile(out,'attempt_ledger.csv');
if isfile(ledgerPath)
    ledger=readAttemptLedger(ledgerPath);
    previous=ledger(ledger.BaseRunID==meta.baseRunID,:);
    for i=1:height(previous)
        if previous.Status(i)=="running" || previous.Status(i)=="planned"
            previous.Status(i)="aborted";
            previous.ErrorMessage(i)="Process ended before a terminal run artifact was recorded.";
            rowIndex=find(ledger.RunID==previous.RunID(i),1);
            ledger(rowIndex,:)=previous(i,:);
        end
    end
    writeMutableLedger(ledgerPath,ledger);
    attempt=max(attempt,1+height(previous));
end
if attempt>1, runID=string(meta.baseRunID)+sprintf('_attempt_%02d',attempt); end
path=fullfile(runs,runID+'.mat');
if isfile(path)
    error('femstudy:restfieldStudy:AttemptPathConflict', ...
        'Refusing to overwrite existing attempt artifact: %s',path);
end
started=string(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
row=ledgerRow(runID,meta,started,0,0,0,"planned","","","","");
upsertLedger(out,row);
row.Status="running";
upsertLedger(out,row);
end

function row=ledgerRow(runID,meta,started,seconds,epochs,iterations,status,stopReason, ...
        errorIdentifier,errorMessage,artifact)
row=table(oneString(runID),oneString(meta.baseRunID),oneString(meta.stage), ...
    oneString(meta.model),oneString(meta.architecture),oneString(meta.optimizer), ...
    double(meta.fold),double(meta.seed),double(meta.trainingCount), ...
    double(meta.validationCount),oneString(started),double(seconds),double(epochs), ...
    double(iterations),oneString(stopReason),oneString(status),oneString(errorIdentifier), ...
    oneString(errorMessage),oneString(artifact),oneString(meta.configSHA256), ...
    oneString(meta.dataSHA256),oneString(meta.codeSHA256), ...
    'VariableNames',{'RunID','BaseRunID','Stage','Model','Architecture','Optimizer', ...
    'Fold','Seed','TrainingCases','ValidationCases','StartedAt','ElapsedSeconds', ...
    'EpochsCompleted','IterationsCompleted','StopReason','Status','ErrorIdentifier', ...
    'ErrorMessage','Artifact','ConfigSHA256','DataSHA256','CodeSHA256'});
end

function value=oneString(value)
value=string({char(value)});
end

function finishAttempt(out,runID,status,seconds,history,stopReason,errorIdentifier,errorMessage,artifact)
path=fullfile(out,'attempt_ledger.csv');
assert(isfile(path),'femstudy:restfieldStudy:LedgerMissing','Attempt ledger disappeared.');
ledger=readAttemptLedger(path);
idx=find(ledger.RunID==string(runID),1);
assert(~isempty(idx),'femstudy:restfieldStudy:LedgerKey','Run ID missing from ledger.');
ledger.ElapsedSeconds(idx)=seconds;
ledger.Status(idx)=string(status);
ledger.StopReason(idx)=string(stopReason);
ledger.ErrorIdentifier(idx)=string(errorIdentifier);
ledger.ErrorMessage(idx)=string(errorMessage);
ledger.Artifact(idx)=string(artifact);
if isstruct(history)
    if isfield(history,'epoch'), ledger.EpochsCompleted(idx)=numel(history.epoch); end
    if isfield(history,'iteration'), ledger.IterationsCompleted(idx)=numel(history.iteration); end
end
writeMutableLedger(path,ledger);
end

function recoverLedgerSuccess(out,record,artifact)
path=fullfile(out,'attempt_ledger.csv');
if ~isfile(path), return; end
ledger=readAttemptLedger(path);
idx=find(ledger.RunID==record.runID,1);
if isempty(idx) || ledger.Status(idx)=="completed", return; end
finishAttempt(out,record.runID,"completed",record.trainingSeconds,record.history, ...
    "Recovered completed immutable run artifact after interrupted ledger update.", ...
    "","",artifact);
end

function recoverLedgerFailure(out,record,artifact)
path=fullfile(out,'attempt_ledger.csv');
if ~isfile(path), return; end
ledger=readAttemptLedger(path);
idx=find(ledger.RunID==record.runID,1);
if isempty(idx) || ledger.Status(idx)=="failed", return; end
finishAttempt(out,record.runID,"failed",record.trainingSeconds,struct, ...
    "Recovered failed immutable run artifact after interrupted ledger update.", ...
    record.errorIdentifier,record.errorMessage,artifact);
end

function upsertLedger(out,row)
path=fullfile(out,'attempt_ledger.csv');
if isfile(path)
    ledger=readAttemptLedger(path);
    assert(isequal(ledger.Properties.VariableNames,row.Properties.VariableNames), ...
        'femstudy:restfieldStudy:LedgerSchema','Attempt ledger schema changed.');
    idx=find(ledger.RunID==row.RunID,1);
    if isempty(idx)
        ledger=[ledger;row];
    else
        ledger(idx,:)=row;
    end
else
    ledger=row;
end
writeMutableLedger(path,ledger);
end

function writeMutableLedger(path,ledger)
tmp=[tempname(fileparts(path)),'.csv'];
writetable(ledger,tmp);
[ok,msg]=movefile(tmp,path,'f');
assert(ok,'femstudy:restfieldStudy:LedgerWrite','Cannot update attempt ledger: %s',msg);
end

function ledger=readAttemptLedger(path)
options=detectImportOptions(path,'TextType','string');
textVariables={'RunID','BaseRunID','Stage','Model','Architecture','Optimizer', ...
    'StartedAt','StopReason','Status','ErrorIdentifier','ErrorMessage','Artifact', ...
    'ConfigSHA256','DataSHA256','CodeSHA256'};
options=setvartype(options,textVariables,'string');
ledger=readtable(path,options);
end

function repairAttemptLedger(out)
path=fullfile(out,'attempt_ledger.csv');
ledger=readAttemptLedger(path);
runs=fullfile(out,'runs');
for i=1:height(ledger)
    if ~any(ledger.Status(i)==["completed","failed"]), continue; end
    artifact=fullfile(runs,ledger.RunID(i)+".mat");
    assert(isfile(artifact),'femstudy:restfieldStudy:LedgerArtifactMissing', ...
        'Terminal ledger row has no run artifact: %s.',ledger.RunID(i));
    loaded=load(artifact,'value'); record=loaded.value;
    assert(record.runID==ledger.RunID(i) && record.status==ledger.Status(i) && ...
        record.baseRunID==ledger.BaseRunID(i), ...
        'femstudy:restfieldStudy:LedgerArtifactMismatch', ...
        'Ledger and run artifact disagree for %s.',ledger.RunID(i));
    storedArtifact=ledger.Artifact(i);
    if ismissing(storedArtifact) || storedArtifact=="" || storedArtifact=="NaN"
        ledger.Artifact(i)=string(artifact);
    else
        assert(storedArtifact==string(artifact), ...
            'femstudy:restfieldStudy:LedgerArtifactConflict', ...
            'Ledger artifact path conflicts for %s.',ledger.RunID(i));
    end
    if record.status=="completed"
        if isfield(record,'history') && isstruct(record.history) && ...
                isfield(record.history,'stopReason')
            ledger.StopReason(i)=string(record.history.stopReason);
        elseif record.metadata.stage=="gpr" || record.metadata.stage=="pilot"
            ledger.StopReason(i)="GPR fit completed";
        end
        ledger.ErrorIdentifier(i)=""; ledger.ErrorMessage(i)="";
        if isfield(record,'history') && isstruct(record.history)
            if isfield(record.history,'epoch')
                ledger.EpochsCompleted(i)=numel(record.history.epoch);
            end
            if isfield(record.history,'iteration')
                ledger.IterationsCompleted(i)=numel(record.history.iteration);
            end
        end
    else
        ledger.StopReason(i)="exception";
        ledger.ErrorIdentifier(i)=string(record.errorIdentifier);
        ledger.ErrorMessage(i)=string(record.errorMessage);
    end
end
writeMutableLedger(path,ledger);
end

function select=loadSelection(out,name,prepared)
path=fullfile(out,name);
assert(isfile(path),'femstudy:restfieldStudy:SelectionMissing', ...
    'Run selection stage first: %s',name);
a=load(path,'value'); select=a.value;
assert(isKnownProvenance(out,select.provenance) && ...
    strcmp(select.provenance.configSHA256,prepared.provenance.configSHA256), ...
    'femstudy:restfieldStudy:SelectionProvenance', ...
    'Selection provenance is not in the immutable manifest history.');
end

function tf=isKnownProvenance(out,provenance)
files=[dir(fullfile(out,'prepared.mat'));dir(fullfile(out,'prepared_revision_*.mat'))];
tf=false;
for i=1:numel(files)
    a=load(fullfile(files(i).folder,files(i).name),'value');
    if isequaln(a.value.provenance,provenance)
        tf=true; return
    end
end
end

function runs=loadRuns(out,prefix)
files=dir(fullfile(out,'runs',[char(prefix),'*.mat']));
runs=struct([]);
for i=1:numel(files)
    a=load(fullfile(files(i).folder,files(i).name),'value');
    if isfield(a.value,'status') && a.value.status=="completed"
        if isempty(runs)
            runs=a.value;
        else
            runs(end+1)=a.value; %#ok<AGROW>
        end
    end
end
end

function run=latestSuccessfulRun(out,base)
files=dir(fullfile(out,'runs',[char(base),'*.mat']));
run=[];
for i=1:numel(files)
    a=load(fullfile(files(i).folder,files(i).name),'value');
    if a.value.status=="completed"
        assert(isempty(run),'femstudy:restfieldStudy:DuplicateSuccessfulRun', ...
            'Multiple successful artifacts exist for run %s.',base);
        run=a.value;
    end
end
end

function metrics=collectRunMetrics(runs,architectureIDValue)
parts=cell(0,1);
for i=1:numel(runs)
    if contains(string(runs(i).metadata.baseRunID), ...
            "A_"+architectureIDValue+"_") || ...
            contains(string(runs(i).metadata.baseRunID), ...
            "B_LBFGS_"+architectureIDValue+"_")
        parts{end+1}=runs(i).caseMetrics; %#ok<AGROW>
    end
end
assert(~isempty(parts),'femstudy:restfieldStudy:MetricsMissing','No run metrics found.');
metrics=vertcat(parts{:});
end

function summary=optimizerSummary(adamMetrics,lbfgsMetrics,adam,lbfgs)
optimizers=["adam";"lbfgs"];
metrics={adamMetrics;lbfgsMetrics};
runSets={adam;lbfgs}; rows=cell(2,8);
for i=1:2
    m=metrics{i};
    rows(i,:)={optimizers(i),mean(m.RelativeWeightedFieldError), ...
        median(m.RelativeWeightedFieldError),nearestRank(m.RelativeWeightedFieldError,.95), ...
        max(m.RelativeWeightedFieldError),mean(m.AbsoluteWeightedRMS_m), ...
        mean([runSets{i}.trainingSeconds]),numel(unique(m.CaseID))};
end
summary=cell2table(rows,'VariableNames',{'Optimizer','MeanRelativeError', ...
    'MedianRelativeError','P95RelativeError','MaximumRelativeError', ...
    'MeanAbsoluteRMS_m','MeanTrainingSeconds','PhysicalCaseCount'});
end

function assertSameInitialWeights(adam,lbfgs)
for i=1:numel(adam)
    match=find(arrayfun(@(x)x.metadata.fold==adam(i).metadata.fold && ...
        x.metadata.seed==adam(i).metadata.seed,lbfgs),1);
    assert(~isempty(match) && ...
        strcmp(adam(i).model.initialWeightsHash,lbfgs(match).model.initialWeightsHash), ...
        'femstudy:restfieldStudy:InitialWeightsMismatch', ...
        'Paired Adam/L-BFGS runs do not have identical initial parameters.');
end
end

function widths=findArchitecture(architectures,id)
for i=1:numel(architectures)
    if architectureID(architectures{i})==string(id)
        widths=architectures{i}; return
    end
end
error('femstudy:restfieldStudy:ArchitectureUnknown','Unknown architecture ID: %s',id);
end

function id=architectureID(widths)
id="h"+join(string(widths),"x");
end

function label=architectureText(widths)
label="["+join(string(widths),",")+"]";
end

function value=fieldSummaryTable(metrics,groupColumns)
groups=unique(metrics(:,groupColumns),'rows','stable');
rows=cell(height(groups),width(groups)+7);
for i=1:height(groups)
    mask=true(height(metrics),1);
    for j=1:numel(groupColumns)
        name=groupColumns{j};
        groupValue=groups.(name);
        mask=mask & metrics.(name)==groupValue(i);
    end
    r=metrics.RelativeWeightedFieldError(mask);
    a=metrics.AbsoluteWeightedRMS_m(mask);
    p=metrics.PODProjectionRelativeError(mask);
    rows(i,:)=[table2cell(groups(i,:)), ...
        {mean(r),median(r),nearestRank(r,.95),max(r),mean(a),mean(p), ...
        numel(unique(metrics.CaseID(mask)))}];
end
value=cell2table(rows,'VariableNames',[groupColumns, ...
    {'MeanRelativeError','MedianRelativeError','P95RelativeError', ...
    'MaximumRelativeError','MeanAbsoluteRMS_m','MeanPODProjectionError','PhysicalCaseCount'}]);
end

function analyzeStudy(~,out,cfg,prepared)
repairAttemptLedger(out);
architecture=loadRuns(out,"A_");
gpr=loadRuns(out,"GPR_");
optimizerSelection=loadSelection(out,'optimizer_selection.mat',prepared);
architectureSelection=loadSelection(out,'architecture_selection.mat',prepared);
chosenID=architectureSelection.chosenArchitectureID;
selectedWidth=findArchitecture(cfg.architectureStage.architectures,chosenID);
lbfgs=loadRuns(out,"B_LBFGS_"+chosenID+"_");
expectedA=numel(cfg.architectureStage.architectures)*cfg.validation.foldCount* ...
    numel(cfg.architectureStage.seeds);
expectedG=cfg.validation.foldCount;
expectedB=cfg.validation.foldCount*numel(cfg.optimizerStage.seeds);
assert(numel(architecture)==expectedA && numel(gpr)==expectedG && numel(lbfgs)==expectedB, ...
    'femstudy:restfieldStudy:CampaignIncomplete', ...
    'Architecture/GPR/L-BFGS run grid incomplete. Inspect attempt_ledger.csv.');
assert(all(string({architecture.status})=="completed") && ...
    all(string({gpr.status})=="completed") && all(string({lbfgs.status})=="completed"), ...
    'femstudy:restfieldStudy:CampaignFailed', ...
    'One or more planned candidate runs failed; they remain in attempt_ledger.csv.');
finalPrefix="FINAL_"+architectureID(selectedWidth)+"_"+upper(optimizerSelection.chosenOptimizer)+"_";
final=loadRuns(out,finalPrefix);
assert(numel(final)==numel(cfg.architectureStage.seeds), ...
    'femstudy:restfieldStudy:FinalFitsIncomplete', ...
    'The selected configuration must be fitted on all 384 cases for each seed.');

allCV=[architecture(:);lbfgs(:);gpr(:)];
allMetrics=vertcat(allCV.caseMetrics);
writeImmutableTable(fullfile(out,'cross_validation_case_metrics.csv'),allMetrics);
archSummary=architectureSummary(architecture,cfg.architectureStage.architectures);
selectedAdam=latestSelectedAdam(out,chosenID,cfg);
optimizerRuns=[selectedAdam(:);lbfgs(:)];
optMetrics=vertcat(optimizerRuns.caseMetrics);
adamRuns=optimizerRuns(arrayfun(@(x)x.metadata.optimizer=="adam",optimizerRuns));
lbfgsRuns=optimizerRuns(arrayfun(@(x)x.metadata.optimizer=="lbfgs",optimizerRuns));
optSummary=optimizerSummary( ...
    optMetrics(optMetrics.Optimizer=="adam",:), ...
    optMetrics(optMetrics.Optimizer=="lbfgs",:), ...
    adamRuns,lbfgsRuns);
gprMetrics=vertcat(gpr.caseMetrics);
gprSummary=fieldSummaryTable(gprMetrics,{'Model','Optimizer'});
paired=pairedComparisons(architecture,lbfgs,gpr,chosenID, ...
    optimizerSelection.chosenOptimizer);
history=collectHistories([architecture(:);lbfgs(:);final(:)]);
writeImmutableTable(fullfile(out,'architecture_results.csv'),archSummary);
writeImmutableTable(fullfile(out,'optimizer_results.csv'),optSummary);
writeImmutableTable(fullfile(out,'gpr_reference_results.csv'),gprSummary);
writeImmutableTable(fullfile(out,'architecture_fold_seed_summary.csv'), ...
    fieldSummaryTable(vertcat(architecture.caseMetrics),{'Architecture','Fold','Seed'}));
writeImmutableTable(fullfile(out,'architecture_seed_summary.csv'), ...
    fieldSummaryTable(vertcat(architecture.caseMetrics),{'Architecture','Seed'}));
writeImmutableTable(fullfile(out,'architecture_seed_spread.csv'), ...
    seedSpreadSummary(fieldSummaryTable(vertcat(architecture.caseMetrics),{'Architecture','Seed'})));
writeImmutableTable(fullfile(out,'optimizer_fold_seed_summary.csv'), ...
    fieldSummaryTable(optMetrics,{'Optimizer','Fold','Seed'}));
writeImmutableTable(fullfile(out,'gpr_fold_summary.csv'), ...
    fieldSummaryTable(gprMetrics,{'Fold'}));
writeImmutableTable(fullfile(out,'paired_case_differences.csv'),paired);
writeImmutableTable(fullfile(out,'paired_difference_summary.csv'),pairedSummary(paired));
writeImmutableTable(fullfile(out,'training_history.csv'),history);
writeImmutableTable(fullfile(out,'pod_projection_by_fold.csv'),podProjectionSummary(out,cfg));
makePlots(out,archSummary,optSummary,architecture,lbfgs);
ledger=readAttemptLedger(fullfile(out,'attempt_ledger.csv'));
finalLedger=fullfile(out,'attempt_ledger_final.csv');
if ~isfile(finalLedger)
    writeImmutableTable(finalLedger,ledger);
else
    verifyFinalLedger(finalLedger,ledger);
end
writeFinalReport(out,cfg,prepared,architectureSelection,optimizerSelection, ...
    archSummary,optSummary,gprSummary,final,ledger,selectedWidth, ...
    numel(unique(allMetrics.CaseID(allMetrics.ReferenceWeightedNorm_m< ...
        cfg.selection.referenceNormFloor_m))),cfg.selection.referenceNormFloor_m);
fprintf('Evaluation complete. CV physical cases: %d; seeds remain separate; no holdout labels used.\n', ...
    numel(unique(allMetrics.CaseID)));
end

function verifyFinalLedger(path,current)
stored=readAttemptLedger(path);
assert(isequal(stored.Properties.VariableNames,current.Properties.VariableNames) && ...
    height(stored)==height(current),'femstudy:restfieldStudy:FinalLedgerConflict', ...
    'Frozen final ledger schema or row count differs from the verified attempt ledger.');
keyColumns={'RunID','BaseRunID','Stage','Model','Architecture','Optimizer', ...
    'Fold','Seed','TrainingCases','ValidationCases','StartedAt','ElapsedSeconds', ...
    'EpochsCompleted','IterationsCompleted','Status','ConfigSHA256','DataSHA256','CodeSHA256'};
for i=1:numel(keyColumns)
    name=keyColumns{i};
    assert(isequaln(stored.(name),current.(name)), ...
        'femstudy:restfieldStudy:FinalLedgerConflict', ...
        'Frozen final ledger conflicts with current verified values in %s.',name);
end
for i=1:height(current)
    assert(isfile(current.Artifact(i)),'femstudy:restfieldStudy:LedgerArtifactMissing', ...
        'Verified terminal run artifact disappeared: %s.',current.RunID(i));
    loaded=load(current.Artifact(i),'value'); record=loaded.value;
    if current.Status(i)=="completed"
        assert(record.status=="completed", ...
            'femstudy:restfieldStudy:FinalLedgerConflict', ...
            'Completed run status differs in artifact %s.',current.RunID(i));
        if isfield(record,'history') && isstruct(record.history) && ...
                isfield(record.history,'stopReason')
            assert(current.StopReason(i)==string(record.history.stopReason), ...
                'femstudy:restfieldStudy:FinalLedgerConflict', ...
                'Stop reason differs in artifact %s.',current.RunID(i));
        end
    elseif current.Status(i)=="failed"
        assert(record.status=="failed" && ...
            current.ErrorIdentifier(i)==string(record.errorIdentifier) && ...
            current.ErrorMessage(i)==string(record.errorMessage), ...
            'femstudy:restfieldStudy:FinalLedgerConflict', ...
            'Failure details differ in artifact %s.',current.RunID(i));
    end
end
end

function summary=architectureSummary(runs,architectures)
rows=cell(numel(architectures),10);
for i=1:numel(architectures)
    id=architectureID(architectures{i});
    subset=runs(arrayfun(@(x)contains(x.metadata.baseRunID,"A_"+id+"_"),runs));
    metrics=vertcat(subset.caseMetrics);
    rows(i,:)={id,architectureText(architectures{i}), ...
        mean(metrics.RelativeWeightedFieldError),median(metrics.RelativeWeightedFieldError), ...
        nearestRank(metrics.RelativeWeightedFieldError,.95), ...
        max(metrics.RelativeWeightedFieldError),mean(metrics.AbsoluteWeightedRMS_m), ...
        mean(metrics.PODProjectionRelativeError),mean([subset.trainingSeconds]), ...
        numel(unique(metrics.CaseID))};
end
summary=cell2table(rows,'VariableNames',{'ArchitectureID','Architecture', ...
    'MeanRelativeError','MedianRelativeError','P95RelativeError','MaximumRelativeError', ...
    'MeanAbsoluteRMS_m','MeanPODProjectionError','MeanTrainingSeconds','PhysicalCaseCount'});
end

function summary=seedSpreadSummary(seedSummary)
architectures=unique(seedSummary.Architecture,'stable');
rows=cell(numel(architectures),6);
for i=1:numel(architectures)
    selected=seedSummary(seedSummary.Architecture==architectures(i),:);
    means=selected.MeanRelativeError;
    rows(i,:)={architectures(i),min(means),median(means),max(means),std(means), ...
        numel(unique(selected.Seed))};
end
summary=cell2table(rows,'VariableNames',{'Architecture','MinimumSeedMeanError', ...
    'MedianSeedMeanError','MaximumSeedMeanError','StandardDeviationAcrossSeedMeans','SeedCount'});
end

function summary=pairedSummary(paired)
groups=unique(paired(:,{'ComparisonType','Pair'}),'rows','stable');
rows=cell(height(groups),8);
for i=1:height(groups)
    mask=paired.ComparisonType==groups.ComparisonType(i) & paired.Pair==groups.Pair(i);
    d=paired.DifferenceAminusB(mask);
    rows(i,:)={groups.ComparisonType(i),groups.Pair(i),numel(d),mean(d),median(d), ...
        nearestRank(abs(d),.95),max(abs(d)),mean(d>0)};
end
summary=cell2table(rows,'VariableNames',{'ComparisonType','Pair','PairedCaseCount', ...
    'MeanDifferenceAminusB','MedianDifferenceAminusB','P95AbsoluteDifference', ...
    'MaximumAbsoluteDifference','FractionCasesAHasHigherError'});
end

function summary=podProjectionSummary(out,cfg)
rows=cell(cfg.validation.foldCount,6);
for f=1:cfg.validation.foldCount
    a=load(fullfile(out,'preprocessing',sprintf('fold_%02d.mat',f)),'value');
    p=a.value.projectionMetrics.RelativeWeightedFieldError;
    rows(f,:)={f,a.value.podRank,a.value.podEnergyRetained,mean(p), ...
        nearestRank(p,.95),max(p)};
end
summary=cell2table(rows,'VariableNames',{'Fold','PODRank','TrainingEnergyRetained', ...
    'ValidationProjectionMeanRelativeError','ValidationProjectionP95RelativeError', ...
    'ValidationProjectionMaximumRelativeError'});
end

function runs=latestSelectedAdam(out,id,cfg)
runs=struct([]);
for f=1:cfg.validation.foldCount
    for seed=cfg.architectureStage.seeds(:)'
        run=latestSuccessfulRun(out,sprintf('A_%s_fold%02d_seed%d',id,f,seed));
        assert(~isempty(run),'femstudy:restfieldStudy:SelectedAdamMissing', ...
            'Selected-architecture Adam run is missing.');
        if isempty(runs)
            runs=run;
        else
            runs(end+1)=run; %#ok<AGROW>
        end
    end
end
end

function paired=pairedComparisons(architecture,lbfgs,gpr,chosenID,selectedOptimizer)
rows=cell(0,8);
ids=strings(0,1);
for i=1:numel(architecture)
    id=architecture(i).metadata.baseRunID;
    token=regexp(char(id),'^A_(h[0-9x]+)_','tokens','once');
    if ~isempty(token), ids(end+1,1)=string(token{1}); end %#ok<AGROW>
end
ids=unique(ids,'stable');
archMetric=vertcat(architecture.caseMetrics);
for a=1:numel(ids)-1
    for b=a+1:numel(ids)
        A=caseMeanByFold(archMetric,ids(a));
        B=caseMeanByFold(archMetric,ids(b));
        [~,ia,ib]=intersect([A.Fold,A.CaseID],[B.Fold,B.CaseID],'rows','stable');
        delta=A.MeanError(ia)-B.MeanError(ib);
        for k=1:numel(delta)
            rows(end+1,:)={"architecture",ids(a)+"-"+ids(b),A.Fold(ia(k)), ...
                A.CaseID(ia(k)),A.MeanError(ia(k)),B.MeanError(ib(k)),delta(k), ...
                "seed-mean of errors; no prediction ensemble"}; %#ok<AGROW>
        end
    end
end
adam=latestSelectedAdamFromStruct(architecture,chosenID);
adamMetrics=vertcat(adam.caseMetrics); bMetrics=vertcat(lbfgs.caseMetrics);
A=caseMeanByFold(adamMetrics,"");
B=caseMeanByFold(bMetrics,"");
[~,ia,ib]=intersect([A.Fold,A.CaseID],[B.Fold,B.CaseID],'rows','stable');
for k=1:numel(ia)
    rows(end+1,:)={"optimizer","adam-lbfgs",A.Fold(ia(k)),A.CaseID(ia(k)), ...
        A.MeanError(ia(k)),B.MeanError(ib(k)),A.MeanError(ia(k))-B.MeanError(ib(k)), ...
        "seed-mean of errors; paired folds and cases"}; %#ok<AGROW>
end
gprMetrics=vertcat(gpr.caseMetrics);
gprMean=caseMeanByFold(gprMetrics,"");
M=adamMetrics;
if selectedOptimizer=="lbfgs", M=bMetrics; end
selectedMean=caseMeanByFold(M,"");
[~,ia,ib]=intersect([selectedMean.Fold,selectedMean.CaseID], ...
    [gprMean.Fold,gprMean.CaseID],'rows','stable');
for k=1:numel(ia)
    rows(end+1,:)={"gpr-reference",selectedOptimizer+"-GPR", ...
        selectedMean.Fold(ia(k)),selectedMean.CaseID(ia(k)), ...
        selectedMean.MeanError(ia(k)),gprMean.MeanError(ib(k)), ...
        selectedMean.MeanError(ia(k))-gprMean.MeanError(ib(k)), ...
        "selected MLP optimizer; seed-mean of errors"}; %#ok<AGROW>
end
paired=cell2table(rows,'VariableNames',{'ComparisonType','Pair','Fold','CaseID', ...
    'A_RelativeError','B_RelativeError','DifferenceAminusB','Interpretation'});
end

function runs=latestSelectedAdamFromStruct(architecture,id)
runs=architecture(arrayfun(@(x)contains(x.metadata.baseRunID,"A_"+id+"_"),architecture));
end

function grouped=caseMeanByFold(metrics,architectureIDValue)
if architectureIDValue~=""
    token=regexp(char(architectureIDValue),'^h[0-9x]+$','once');
    if ~isempty(token)
        mask=contains(metrics.RunID,"A_"+architectureIDValue+"_");
    else
        mask=true(height(metrics),1);
    end
    metrics=metrics(mask,:);
end
groups=unique(metrics(:,{'Fold','CaseID'}),'rows','stable');
meanError=zeros(height(groups),1);
for i=1:height(groups)
    mask=metrics.Fold==groups.Fold(i) & metrics.CaseID==groups.CaseID(i);
    meanError(i)=mean(metrics.RelativeWeightedFieldError(mask));
end
grouped=groups; grouped.MeanError=meanError;
end

function history=collectHistories(runs)
rows=cell(0,7);
for i=1:numel(runs)
    h=runs(i).history;
    loss=h.trainingLoss;
    if isempty(loss), continue; end
    for k=1:numel(loss)
        iteration=k;
        if numel(h.iteration)>=k, iteration=h.iteration(k); end
        epoch=NaN;
        if numel(h.epoch)>=k, epoch=h.epoch(k); end
        rows(end+1,:)={runs(i).runID,runs(i).metadata.stage, ...
            runs(i).metadata.architecture,runs(i).metadata.optimizer, ...
            iteration,loss(k),epoch}; %#ok<AGROW>
    end
end
if isempty(rows)
    history=table(strings(0,1),strings(0,1),strings(0,1),strings(0,1), ...
        zeros(0,1),zeros(0,1),zeros(0,1), ...
        'VariableNames',{'RunID','Stage','Architecture','Optimizer','Iteration','TrainingLoss','Epoch'});
else
    history=cell2table(rows,'VariableNames', ...
        {'RunID','Stage','Architecture','Optimizer','Iteration','TrainingLoss','Epoch'});
end
end

function makePlots(out,archSummary,optSummary,architecture,lbfgs)
path=fullfile(out,'architecture_comparison.png');
if ~isfile(path)
    fig=figure('Visible','off');
    bar(archSummary.MeanRelativeError);
    set(gca,'XTickLabel',cellstr(archSummary.Architecture));
    ylabel('Mean relative weighted field error'); title('Architecture CV comparison');
    exportgraphics(fig,path); close(fig);
end
path=fullfile(out,'optimizer_comparison.png');
if ~isfile(path)
    fig=figure('Visible','off');
    bar(optSummary.MeanRelativeError);
    set(gca,'XTickLabel',cellstr(optSummary.Optimizer));
    ylabel('Mean relative weighted field error'); title('Optimizer CV comparison');
    exportgraphics(fig,path); close(fig);
end
plotHistoryGroups(out,architecture(:),"architecture", ...
    fullfile(out,'architecture_training_curves.png'));
plotHistoryGroups(out,lbfgs(:),"optimizer", ...
    fullfile(out,'optimizer_training_curves.png'));
end

function plotHistoryGroups(out,runs,grouping,path)
if isfile(path), return; end
fig=figure('Visible','off'); hold on;
labels=strings(0,1);
if grouping=="architecture"
    for i=1:numel(runs)
        label=runs(i).metadata.architecture;
        if ~any(labels==label), labels(end+1)=label; end %#ok<AGROW>
    end
else
    labels=["adam","lbfgs"];
    selectedAdam=latestSelectedAdamForPlot(out,runs);
    runs=[runs(:);selectedAdam(:)];
end
for i=1:numel(labels)
    if grouping=="architecture"
        selected=runs(arrayfun(@(x)x.metadata.architecture==labels(i),runs));
    else
        selected=runs(arrayfun(@(x)x.metadata.optimizer==labels(i),runs));
    end
    curves=nan(numel(selected),100);
    for j=1:numel(selected)
        loss=selected(j).history.trainingLoss(:);
        if numel(loss)>=2
            x=linspace(0,1,numel(loss)); curves(j,:)=interp1(x,loss,linspace(0,1,100));
        end
    end
    if any(isfinite(curves),'all')
        plot(linspace(0,1,100),median(curves,1,'omitnan'),'LineWidth',1.5);
    end
end
xlabel('Normalized training progress'); ylabel('Training MSE (scaled coefficients)');
legend(cellstr(labels),'Location','best'); title(grouping+" training curves"); hold off;
exportgraphics(fig,path); close(fig);
end

function runs=latestSelectedAdamForPlot(out,lbfgs)
runs=struct([]);
for i=1:numel(lbfgs)
    if lbfgs(i).metadata.optimizer~="lbfgs", continue; end
    archToken=regexp(char(lbfgs(i).metadata.baseRunID),'B_LBFGS_(h[0-9x]+)_fold([0-9]+)_seed([0-9]+)','tokens','once');
    if isempty(archToken), continue; end
    adam=latestSuccessfulRun(out,sprintf('A_%s_fold%02d_seed%d', ...
        archToken{1},str2double(archToken{2}),str2double(archToken{3})));
    if ~isempty(adam)
        if isempty(runs)
            runs=adam;
        else
            runs(end+1)=adam; %#ok<AGROW>
        end
    end
end
end

function writeFinalReport(out,~,prepared,architectureSelection,optimizerSelection, ...
        archSummary,optSummary,gprSummary,final,ledger,selectedWidth, ...
        smallNormCases,referenceNormFloor)
report=fullfile(out,'FINAL_REPORT_v2.md');
if isfile(report), return; end
history=ledger;
failures=history(history.Status=="failed" | history.Status=="aborted",:);
finalRows=cell(numel(final),7);
for i=1:numel(final)
    finalRows(i,:)={final(i).metadata.seed,final(i).podRank, ...
        final(i).trainingSeconds,numel(final(i).history.epoch), ...
        numel(final(i).history.iteration),final(i).history.stopReason, ...
        numel(final(i).model.trainIDs)};
end
finalSummary=cell2table(finalRows,'VariableNames',{'Seed','PODRank', ...
    'TrainingSeconds','EpochsCompleted','IterationsCompleted','StopReason', ...
    'TrainingCases'});
writeImmutableTable(fullfile(out,'final_fit_seed_training.csv'),finalSummary);
seedLines=strings(height(finalSummary),1);
for i=1:height(finalSummary)
    seedLines(i)=sprintf('| %d | %d | %d | %d | %.2f | %s |', ...
        finalSummary.Seed(i),finalSummary.TrainingCases(i), ...
        finalSummary.PODRank(i),finalSummary.IterationsCompleted(i), ...
        finalSummary.TrainingSeconds(i),finalSummary.StopReason(i));
end
text=["# Architektur- und Trainingsvergleich des Balken-Restfeld-MLP"; ...
    ""; "Stand: "+string(datetime('now','Format','yyyy-MM-dd')); ...
    ""; "## Validierungsstrategie und Integritaet"; ...
    ""; "Dreifache gruppierte Kreuzvalidierung innerhalb der 384 bestehenden Trainingsfaelle. " + ...
    "Pro Fold wurden 256 Faelle trainiert und 128 Faelle ausschliesslich zur aeusseren " + ...
    "Kandidatenauswahl verwendet. Die CV ist kein unabhaengiger Abschlusstest. " + ...
    "POD, Rang, Mittelwerte und Skalierung stammen pro Fold nur aus den 256 Trainingsfaellen."; ...
    ""; "Die 64 Labels des abgeschlossenen statischen Holdouts, die frueheren Testkohorten " + ...
    "und neue FEM-Berechnungen wurden nicht verwendet. Deren Status als verbrauchte " + ...
    "Tests bleibt unveraendert."; ...
    ""; "## Auswahl"; ...
    ""; sprintf('Faelle mit Referenznorm unter dem vorab festgelegten Nennerboden %.1e m: %d.', ...
        referenceNormFloor,smallNormCases); ...
    ""; "Architektur: **"+architectureSelection.chosenArchitecture+"**. Optimierer: **"+ ...
    optimizerSelection.chosenOptimizer+"**. Auswahlmetriken und Tie-Break sind in der " + ...
    "versionierten Konfiguration festgelegt."; ...
    ""; "## Architekturvergleich"; "";
    "| Architektur | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean POD projection | Mean train s |"; ...
    "|---|---:|---:|---:|---:|---:|---:|---:|"];
for i=1:height(archSummary)
    text(end+1)=sprintf('| %s | %.8g | %.8g | %.8g | %.8g | %.8g | %.8g | %.4g |', ...
        archSummary.Architecture(i),archSummary.MeanRelativeError(i), ...
        archSummary.MedianRelativeError(i),archSummary.P95RelativeError(i), ...
        archSummary.MaximumRelativeError(i),archSummary.MeanAbsoluteRMS_m(i), ...
        archSummary.MeanPODProjectionError(i),archSummary.MeanTrainingSeconds(i)); %#ok<AGROW>
end
text=[text; ""; "## Optimierervergleich"; "";
    "| Optimierer | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean train s |";
    "|---|---:|---:|---:|---:|---:|---:|"];
for i=1:height(optSummary)
    text(end+1)=sprintf('| %s | %.8g | %.8g | %.8g | %.8g | %.8g | %.4g |', ...
        optSummary.Optimizer(i),optSummary.MeanRelativeError(i), ...
        optSummary.MedianRelativeError(i),optSummary.P95RelativeError(i), ...
        optSummary.MaximumRelativeError(i),optSummary.MeanAbsoluteRMS_m(i), ...
        optSummary.MeanTrainingSeconds(i)); %#ok<AGROW>
end
text=[text; ""; "## GPR-Referenz"; "";
    "| Modell | Kernel | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean POD projection |";
    "|---|---|---:|---:|---:|---:|---:|---:|"];
for i=1:height(gprSummary)
    text(end+1)=sprintf('| %s | %s | %.8g | %.8g | %.8g | %.8g | %.8g | %.8g |', ...
        gprSummary.Model(i),gprSummary.Optimizer(i),gprSummary.MeanRelativeError(i), ...
        gprSummary.MedianRelativeError(i),gprSummary.P95RelativeError(i), ...
        gprSummary.MaximumRelativeError(i),gprSummary.MeanAbsoluteRMS_m(i), ...
        gprSummary.MeanPODProjectionError(i)); %#ok<AGROW>
end
text=[text; ""; "GPR nutzt dieselbe Fold-POD-Darstellung und denselben Koeffizientenfit-Split. " + ...
    "Seine feste Sigma-Einstellung ist nicht dieselbe Regularisierungsdefinition wie " + ...
    "das MLP-Gewichts-L2."; ...
    ""; "## Finale Fits auf n=384 (keine Testauswertung)"; ...
    ""; "| Seed | Trainingsfaelle | POD-Rang | Iterationen | Fit s | Abbruchgrund |"; ...
    "|---:|---:|---:|---:|---:|---|"; seedLines;  ...
    ""; "## Kampagnenstatus"; "";
    sprintf('Finale MLP-Fits auf jeweils 384 Trainingsfaellen: %d.',numel(final)); ...
    sprintf('Fehlgeschlagene oder abgebrochene Versuche (einschliesslich erfolgreicher Retries davor): %d.',height(failures)); ...
    "";     "Laufstatus und Fehlergruende: `attempt_ledger.csv` und `attempt_ledger_final.csv`; " + ...
    "CV-Ergebnisse je Fall in `cross_validation_case_metrics.csv`; finale Fitzeiten " + ...
    "und Seed-/Rangzuordnung in `final_fit_seed_training.csv`; Trainingshistorien in `training_history.csv`. " +  ...
    "Architektur- und Optimiererdiagramme sowie Kurven liegen " + ...
    "als PNG im Studienordner."; ...
    ""; "Die finale 384-Fall-Fit-Konfiguration ist nur fuer einen spaeteren, neu " + ...
    "festgelegten unabhaengigen Test eingefroren. Dieser Auftrag erzeugt keinen neuen " + ...
    "Holdout und wertet keine bereits verbrauchten Testfaelle aus."; ...
    ""; "## Reproduktion"; ""; "```matlab"; ...
    "openProject('blank_project.prj')"; ...
    "run_restfield_architecture_training('prepare')"; ...
    "run_restfield_architecture_training('pilot')"; ...
    "run_restfield_architecture_training('architecture')"; ...
    "run_restfield_architecture_training('select_architecture')"; ...
    "run_restfield_architecture_training('optimizer')"; ...
    "run_restfield_architecture_training('select_optimizer')"; ...
    "run_restfield_architecture_training('gpr')"; ...
    "run_restfield_architecture_training('final_fit')"; ...
    "run_restfield_architecture_training('evaluate')"; "```"; ...
    ""; "## Provenienz"; "";
    "Config SHA-256: `"+prepared.provenance.configSHA256+"`"; ...
    "Training data SHA-256: `"+prepared.provenance.trainingDataSHA256+"`"; ...
    "Git revision at preparation: `"+prepared.provenance.gitRevision+"`"; ...
    "Selected architecture: `"+architectureText(selectedWidth)+"`"; ...
    "MATLAB: "+prepared.matlabVersion+"; cores reported: "+string(prepared.numCores)+". " + ...
    "Keine neue FEM-Referenzberechnung."];
fid=fopen(report,'w');
assert(fid>=0,'femstudy:restfieldStudy:ReportExists','Refusing to replace existing report: %s',report);
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',strjoin(text,newline));
clear cleanup
end

function writeImmutableTable(path,expected)
if isfile(path)
    actual=readtable(path,TextType="string");
    assert(isequal(actual.Properties.VariableNames,expected.Properties.VariableNames) && ...
        isequal(size(actual),size(expected)),'femstudy:restfieldStudy:TableConflict', ...
        'Existing table has incompatible schema or dimensions: %s',path);
    for i=1:width(expected)
        a=actual{:,i}; b=expected{:,i};
        if isnumeric(a) && isnumeric(b)
            sameNaN=isequal(isnan(a),isnan(b));
            finite=isfinite(a) & isfinite(b);
            assert(sameNaN && isequal(isinf(a),isinf(b)) && ...
                all(abs(a(finite)-b(finite))<=1e-12*max(1,max(abs(b(finite)))), 'all'), ...
                'femstudy:restfieldStudy:TableConflict','Existing table values differ: %s',path);
        elseif isdatetime(a) && isdatetime(b)
            assert(isequaln(posixtime(a),posixtime(b)), ...
                'femstudy:restfieldStudy:TableConflict','Existing datetime values differ: %s',path);
        elseif isstring(a) && isdatetime(b)
            parsed=datetime(a,'InputFormat','yyyy-MM-dd HH:mm:ss');
            assert(isequaln(posixtime(parsed),posixtime(b)), ...
                'femstudy:restfieldStudy:TableConflict','Existing timestamp values differ: %s',path);
        elseif isdatetime(a) && isstring(b)
            parsed=datetime(b,'InputFormat','yyyy-MM-dd HH:mm:ss');
            assert(isequaln(posixtime(a),posixtime(parsed)), ...
                'femstudy:restfieldStudy:TableConflict','Existing timestamp values differ: %s',path);
        elseif ~isequaln(a,b)
            error('femstudy:restfieldStudy:TableConflict', ...
                'Existing table values differ: %s',path);
        end
    end
    return
end
tmp=[tempname(fileparts(path)),'.csv'];
writetable(expected,tmp);
[ok,msg]=movefile(tmp,path);
assert(ok,'femstudy:restfieldStudy:TableWrite','Cannot write immutable table: %s',msg);
end

function writeImmutableJson(path,value)
if isfile(path)
    actual=jsondecode(fileread(path));
    assert(isequaln(actual,value),'femstudy:restfieldStudy:JsonConflict', ...
        'Existing provenance JSON differs: %s',path);
    return
end
fid=fopen(path,'w');
assert(fid>=0,'femstudy:restfieldStudy:JsonWrite','Cannot create provenance JSON.');
cleanup=onCleanup(@()fclose(fid));
fwrite(fid,jsonencode(value,'PrettyPrint',true),'char');
clear cleanup
end

function hash=sha256File(path)
fid=fopen(path,'rb');
assert(fid>=0,'femstudy:restfieldStudy:HashRead','Cannot open file for hashing: %s',path);
cleanup=onCleanup(@()fclose(fid));
bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
clear cleanup
end

function hash=combinedCodeHash(provenance)
digest=java.security.MessageDigest.getInstance('SHA-256');
bytes=uint8(char(join(provenance.codeSHA256,"")));
digest.update(typecast(bytes,'int8'));
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end

function path=relativePath(root,absolute)
path=string(erase(absolute,[root filesep]));
end

function value=nearestRank(values,p)
values=sort(values(isfinite(values)));
assert(~isempty(values),'femstudy:restfieldStudy:EmptyMetric','No finite values for summary.');
value=values(max(1,ceil(p*numel(values))));
end
