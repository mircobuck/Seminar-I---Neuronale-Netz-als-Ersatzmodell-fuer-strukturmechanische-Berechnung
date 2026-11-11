function result = runL2Reevaluation(outputDir)
%runL2Reevaluation - Reevaluate saved POD-MLP studies with four L2 statistics.
%   RESULT = runL2Reevaluation(OUTPUTDIR) computes new predictions on the
%   existing validation sets. OUTPUTDIR must not exist. No training, FEM,
%   or production test-label access is performed.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','l2_reevaluation_20261111');
end
assert(~isfolder(outputDir) && ~isfile(outputDir), ...
    'surrogate:reevaluation:Exists','Output already exists: %s',outputDir);
experimentRoot=fullfile(root,'experiments');
architectureRoot=fullfile(experimentRoot,'pod_mlp_fresh_validation_128_20261108');
frozen=readtable(fullfile(architectureRoot,'model_freeze.csv'),'TextType','string','Delimiter',',','VariableNamingRule','preserve');
frozen=frozen(ismember(frozen.Width,[64 128]) & ismember(frozen.HiddenLayers,1:5),:);
assert(height(frozen)==420,'surrogate:reevaluation:ArchitectureCount', ...
    'Expected 420 frozen architecture/loss models.');
plan=table(repmat("architecture_loss",height(frozen),1),frozen.File,frozen.SHA256, ...
    'VariableNames',{'Study','File','ExpectedSHA256'});
studyNames=["optimizer","learning_rate","width","pod_rank"];
studyFolders=["pod_mlp_optimizer_pilot_20261108_v2", ...
    "pod_mlp_learning_rate_study_20261108", ...
    "pod_mlp_width_study_20261109_with128","pod_mlp_rank_study_20261110"];
for k=1:numel(studyNames)
    manifest=readtable(fullfile(experimentRoot,studyFolders(k),'model_manifest.csv'), ...
        'TextType','string','Delimiter',',','VariableNamingRule','preserve');
    plan=[plan; table(repmat(studyNames(k),height(manifest),1), ...
        manifest.File,manifest.SHA256,'VariableNames',plan.Properties.VariableNames)]; %#ok<AGROW>
end
for k=1:height(plan)
    if ~isfile(plan.File(k))
        plan.File(k)=string(fullfile(root,plan.File(k)));
    end
    assert(isfile(plan.File(k)),'surrogate:reevaluation:MissingModel', ...
        'Missing model: %s',plan.File(k));
    assert(sha256File(plan.File(k))==plan.ExpectedSHA256(k), ...
        'surrogate:reevaluation:Hash','Model hash mismatch: %s',plan.File(k));
end
referenceFiles=[string(fullfile(root,'data_generation','data','static','val.mat')); ...
    string(fullfile(architectureRoot,'reference_data','static','val.mat'))];
referenceNames=["original_validation_12";"existing_validation_128"];
referenceHashes=arrayfun(@sha256File,referenceFiles);
sourceFile=string(mfilename('fullpath'))+".m";
metadata=struct('createdAt',string(datetime('now','TimeZone','Europe/Berlin')), ...
    'matlabVersion',string(version),'metric',"relative_weighted_L2_per_case", ...
    'statistics',["median","mean","nearest_rank_p95","maximum"], ...
    'primaryMetric',"mean_relative_weighted_L2",'staticReferenceFloor',0, ...
    'seedAggregation',"arithmetic mean of per-seed statistics; not pooled cases", ...
    'undefinedPolicy',"NaN; excluded from relative summaries; counts retained", ...
    'testDataLoaded',false,'modelsRetrained',false,'femExecuted',false, ...
    'sourceFile',sourceFile,'sourceSHA256',sha256File(sourceFile));
mkdir(outputDir);
writetable(plan,fullfile(outputDir,'model_plan.csv'));
writetable(table(referenceNames,referenceFiles,referenceHashes, ...
    'VariableNames',{'Dataset','File','SHA256'}),fullfile(outputDir,'reference_manifest.csv'));
codeFiles=[sourceFile;string(fullfile(root,'+surrogate','evaluatePrediction.m')); ...
    string(fullfile(root,'+surrogate','predictModel.m')); ...
    string(fullfile(root,'+surrogate','+models','+pod_mlp','predict.m'))];
codeHashes=arrayfun(@sha256File,codeFiles);
writetable(table(codeFiles,codeHashes,'VariableNames',{'File','SHA256'}), ...
    fullfile(outputDir,'code_manifest.csv'));
save(fullfile(outputDir,'evaluation_plan.mat'),'plan','metadata');
references=cell(2,1); requests=cell(2,1);
for k=1:2
    references{k}=surrogate.loadDataset(referenceFiles(k));
    assert(string(references{k}.split)=="val", ...
        'surrogate:reevaluation:Split','Only validation data are allowed.');
    requests{k}=struct('inputParameters',references{k}.inputParameters, ...
        'parameterNames',references{k}.parameterNames, ...
        'parameterUnits',references{k}.parameterUnits,'caseIds',references{k}.caseIds);
end
assert(numel(references{1}.caseIds)==12 && numel(references{2}.caseIds)==128, ...
    'surrogate:reevaluation:ReferenceCount','Expected 12 and 128 validation cases.');
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
runBlocks=cell(height(plan)*2,1); caseBlocks=cell(height(plan)*2,1);
runIndex=0;
for k=1:height(plan)
    model=surrogate.loadModel(plan.File(k));
    config=model.config;
    layerTypes=string(arrayfun(@class,model.state.network.Layers,'UniformOutput',false));
    hiddenLayers=nnz(layerTypes=="nnet.cnn.layer.FullyConnectedLayer")-1;
    assert(hiddenLayers>=1,'surrogate:reevaluation:Layers','No hidden MLP layers found.');
    if isfield(config,'hiddenLayers')
        assert(config.hiddenLayers==hiddenLayers, ...
            'surrogate:reevaluation:Layers','Stored depth differs from network.');
    end
    lossMode="per_coefficient_mse";
    if isfield(model.state,'lossMode')
        lossMode=string(model.state.lossMode);
    elseif isfield(config,'lossMode')
        lossMode=string(config.lossMode);
    end
    optimizer="adam";
    if isfield(config,'optimizer'), optimizer=string(config.optimizer); end
    referenceIndices=2;
    if plan.Study(k)=="architecture_loss", referenceIndices=1:2; end
    for referenceIndex=referenceIndices
        reference=references{referenceIndex};
        assert(isempty(intersect(model.trainingCaseIds,reference.caseIds)), ...
            'surrogate:reevaluation:Overlap','Training and validation IDs overlap.');
        started=tic;
        prediction=surrogate.predictModel(model,requests{referenceIndex});
        predictionSeconds=toc(started);
        metrics=surrogate.evaluatePrediction(prediction,reference,metricConfig);
        % Independent formula guards against aggregation before normalization.
        delta=prediction.displacementFields-reference.displacementFields;
        weights=reference.displacementComponentWeights;
        absolute=sqrt(sum(weights.*delta.^2,1))';
        denominator=sqrt(sum(weights.*reference.displacementFields.^2,1))';
        defined=denominator>0;
        independent=absolute(defined)./denominator(defined);
        assert(isequaln(independent,metrics.relativeWeightedFieldError(defined)), ...
            'surrogate:reevaluation:Formula','Relative L2 formula mismatch.');
        values=sort(metrics.relativeWeightedFieldError(metrics.relativeErrorDefined));
        stats=nan(1,4);
        if ~isempty(values)
            stats=100*[median(values),mean(values),values(ceil(.95*numel(values))),max(values)];
        end
        runIndex=runIndex+1;
        runBlocks{runIndex}=table(runIndex,plan.Study(k),referenceNames(referenceIndex), ...
            lossMode,config.hiddenWidth,hiddenLayers, ...
            numel(model.trainingCaseIds),config.seed,optimizer,config.learningRate,config.rank, ...
            stats(1),stats(2),stats(3),stats(4),numel(values),nnz(~defined), ...
            mean(absolute),predictionSeconds,plan.File(k),plan.ExpectedSHA256(k), ...
            'VariableNames',{'RunId','Study','Dataset','LossMode','Width','HiddenLayers', ...
            'TrainingCases','Seed','Optimizer','LearningRate','Rank','MedianPercent', ...
            'MeanPercent','P95Percent','MaximumPercent','DefinedCount','UndefinedCount', ...
            'MeanAbsoluteErrorM','PredictionSeconds','ModelFile','ModelSHA256'});
        caseBlocks{runIndex}=table(repmat(runIndex,numel(reference.caseIds),1), ...
            reference.caseIds,metrics.absoluteWeightedFieldError, ...
            metrics.referenceWeightedFieldNorm,metrics.relativeWeightedFieldError, ...
            metrics.relativeErrorDefined,'VariableNames',{'RunId','CaseId','AbsoluteErrorM', ...
            'ReferenceNormM','RelativeError','RelativeErrorDefined'});
    end
    if mod(k,20)==0 || k==height(plan)
        fprintf('Reevaluated %d/%d model records; %d validation runs.\n',k,height(plan),runIndex);
        runs=vertcat(runBlocks{1:runIndex});
        writetable(runs,fullfile(outputDir,'run_metrics.csv'));
    end
end
runs=vertcat(runBlocks{1:runIndex});
cases=vertcat(caseBlocks{1:runIndex});
summary=aggregateSeeds(runs);
verification=verifyHistoricalCases(runs,cases,architectureRoot,experimentRoot,studyNames,studyFolders);
writetable(verification,fullfile(outputDir,'historical_case_verification.csv'));
writetable(summary,fullfile(outputDir,'configuration_summary.csv'));
writetable(cases,fullfile(outputDir,'case_errors.csv'));
% Every architecture/loss pair must use identical training IDs.
for k=1:2:height(frozen)
    first=surrogate.loadModel(frozen.File(k));
    second=surrogate.loadModel(frozen.File(k+1));
    assert(isequal(first.trainingCaseIds,second.trainingCaseIds), ...
        'surrogate:reevaluation:TrainingPairs','Loss pair has different training IDs.');
end
result=struct('metadata',metadata,'runs',runs,'summary',summary,'cases',cases, ...
    'historicalVerification',verification);
save(fullfile(outputDir,'reevaluation.mat'),'result','-v7.3');
plotComparisons(summary,outputDir);
writeReport(result,outputDir);
fprintf('Completed %d runs, %d case predictions, %d configurations.\n', ...
    height(runs),height(cases),height(summary));
end

function verification=verifyHistoricalCases(runs,cases,architectureRoot,experimentRoot,studyNames,studyFolders)
folders=[string(architectureRoot),string(fullfile(experimentRoot,studyFolders))];
names=["architecture_loss",studyNames];
verification=table();
for k=1:numel(names)
    historical=readtable(fullfile(folders(k),'validation_case_errors.csv'),'TextType','string','Delimiter',',','VariableNamingRule','preserve');
    selected=runs(runs.Study==names(k) & runs.Dataset=="existing_validation_128",:);
    maxDifference=0; verifiedRuns=0;
    for j=1:height(selected)
        row=selected(j,:);
        mask=historical.Seed==row.Seed;
        fields={'LossMode','Width','HiddenLayers','TrainingCases','Optimizer','LearningRate','Rank'};
        for field=fields
            if ismember(field{1},historical.Properties.VariableNames)
                mask=mask & historical.(field{1})==row.(field{1});
            end
        end
        old=sortrows(historical(mask,:),'CaseId');
        current=sortrows(cases(cases.RunId==row.RunId,:),'CaseId');
        assert(isequal(old.CaseId,current.CaseId), ...
            'surrogate:reevaluation:HistoricalIds','Historical case IDs differ.');
        assert(isequal(isnan(old.RelativeError),isnan(current.RelativeError)), ...
            'surrogate:reevaluation:HistoricalUndefined','Historical undefined flags differ.');
        valid=current.RelativeErrorDefined;
        difference=abs(old.RelativeError(valid)-current.RelativeError(valid));
        assert(all(difference<=1e-9*max(1,abs(current.RelativeError(valid)))), ...
            'surrogate:reevaluation:HistoricalValues','Historical predictions changed.');
        if ~isempty(difference), maxDifference=max(maxDifference,max(difference)); end
        verifiedRuns=verifiedRuns+1;
    end
    verification=[verification;table(names(k),verifiedRuns,maxDifference, ...
        'VariableNames',{'Study','VerifiedRuns','MaximumAbsoluteRelativeErrorDifference'})]; %#ok<AGROW>
end
end

function summary=aggregateSeeds(runs)
keys={'Study','Dataset','LossMode','Width','HiddenLayers','TrainingCases', ...
    'Optimizer','LearningRate','Rank'};
[groups,summary]=findgroups(runs(:,keys));
names={'MedianPercent','MeanPercent','P95Percent','MaximumPercent'};
for k=1:numel(names)
    summary.(names{k})=splitapply(@mean,runs.(names{k}),groups);
end
summary.SeedCount=splitapply(@numel,runs.Seed,groups);
summary.MinimumSeedMeanPercent=splitapply(@min,runs.MeanPercent,groups);
summary.MaximumSeedMeanPercent=splitapply(@max,runs.MeanPercent,groups);
summary.WorstObservedMaximumPercent=splitapply(@max,runs.MaximumPercent,groups);
summary.UndefinedCount=splitapply(@sum,runs.UndefinedCount,groups);
summary=sortrows(summary,{'Study','Dataset','TrainingCases','MeanPercent'});
assert(all(summary.SeedCount==3),'surrogate:reevaluation:Seeds', ...
    'Every configuration must have three seed runs.');
end

function plotComparisons(summary,outputDir)
fields={'MedianPercent','MeanPercent','P95Percent','MaximumPercent'};
metricNames={'Median','Mittelwert','P95 (Nearest Rank)','Maximum'};
studies=unique(summary.Study);
for study=studies'
    data=summary(summary.Study==study & summary.Dataset=="existing_validation_128" ...
        & summary.TrainingCases==768,:);
    data=sortrows(data,'MeanPercent');
    labels="w"+data.Width+" / L"+data.HiddenLayers+" / "+data.Optimizer+ ...
        " / lr="+data.LearningRate+" / r="+data.Rank;
    if study=="architecture_loss"
        labels=labels+" / "+data.LossMode;
    end
    fig=figure('Visible','off','Position',[50 50 1600 1000]);
    layout=tiledlayout(fig,2,2,'TileSpacing','compact');
    for k=1:4
        ax=nexttile(layout);
        bar(ax,data.(fields{k})); grid(ax,'on');
        xticks(ax,1:height(data)); xticklabels(ax,labels);
        ax.TickLabelInterpreter='none'; xtickangle(ax,70);
        ylabel(ax,'Relativer gewichteter L2-Fehler [%]');
        title(ax,metricNames{k});
    end
    title(layout,study+": 128 Validierungsfaelle; Mittel der Kennzahlen aus drei Seeds", ...
        'Interpreter','none');
    exportgraphics(fig,fullfile(outputDir,study+"_four_metrics.png"),'Resolution',150);
    close(fig);
end
for width=[64 128]
    data=summary(summary.Study=="architecture_loss" & summary.Width==width & ...
        summary.Dataset=="existing_validation_128" & summary.LossMode=="weighted_field_mse",:);
    fig=figure('Visible','off','Position',[50 50 1200 800]);
    layout=tiledlayout(fig,2,2);
    for k=1:4
        ax=nexttile(layout); hold(ax,'on');
        for depth=1:5
            subset=sortrows(data(data.HiddenLayers==depth,:),'TrainingCases');
            plot(ax,subset.TrainingCases,subset.(fields{k}),'-o', ...
                'DisplayName',sprintf('%d Schichten',depth));
        end
        grid(ax,'on'); xlabel(ax,'Trainingsfaelle');
        ylabel(ax,'Relativer gewichteter L2-Fehler [%]');
        title(ax,metricNames{k}); legend(ax,'Location','best');
    end
    title(layout,sprintf('Breite %d, weighted field MSE, 128 Validierungsfaelle',width));
    exportgraphics(fig,fullfile(outputDir,sprintf('learning_curves_width_%d.png',width)), ...
        'Resolution',150);
    close(fig);
end
end

function writeReport(result,outputDir)
file=fopen(fullfile(outputDir,'ERGEBNISSE.md'),'w','n','UTF-8');
assert(file>=0,'surrogate:reevaluation:Report','Cannot create report.');
cleanup=onCleanup(@()fclose(file));
fprintf(file,'# L2-Neuauswertung der POD-MLP-Studien\n\nStand: %s.\n\n',result.metadata.createdAt);
fprintf(file,['Gespeicherte Modelle wurden geladen und ihre Vorhersagen neu berechnet. ' ...
    'Kein neues Training, keine FEM und kein Zugriff auf produktive Testlabels.\n\n' ...
    'Je Balkenfall: e = sqrt(sum(w .* (u_pred-u_ref).^2)) / sqrt(sum(w .* u_ref.^2)). ' ...
    'Danach Median, arithmetischer Mittelwert, Nearest-Rank-P95 und Maximum ueber die Faelle. ' ...
    'Alle relativen Kennzahlen in Prozent. Null-Referenzen bleiben NaN; Anzahl wird ausgewiesen.\n\n' ...
    'Hauptvergleich: 128 bereits verwendete Validierungsfaelle. Architektur/Loss zusaetzlich ' ...
    'auf den urspruenglichen 12 Faellen. Bei 12 Faellen ist Nearest-Rank-P95 das Maximum.\n\n' ...
    'Konfigurationstabellen zeigen das arithmetische Mittel jeder Kennzahl ueber drei Seeds. ' ...
    'MaximumPercent ist daher der Mittelwert der drei Fallmaxima; WorstObservedMaximumPercent ' ...
    'ist das groesste beobachtete Maximum. Seeds sind keine neuen Balkenfaelle.\n\n' ...
    'Rangfolge: aufsteigender mittlerer relativer L2-Fehler. Die Kennzahlen koennen unterschiedliche ' ...
    'Rangfolgen ergeben. Diese erneute Validierung ist explorativ, kein neuer unabhaengiger Test.\n\n']);
summary=result.summary;
studies=unique(summary.Study);
for study=studies'
    fprintf(file,'## %s: 768 Trainingsfaelle, 128 Validierungsfaelle\n\n',study);
    data=summary(summary.Study==study & summary.Dataset=="existing_validation_128" ...
        & summary.TrainingCases==768,:);
    data=sortrows(data,'MeanPercent');
    fprintf(file,'| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median %% | Mittelwert %% | P95 %% | Maximum %% | Groesstes Maximum %% |\n');
    fprintf(file,'|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|\n');
    for k=1:height(data)
        row=data(k,:);
        fprintf(file,'| %s | %d | %d | %s | %.4g | %d | %.4f | %.4f | %.4f | %.4f | %.4f |\n', ...
            row.LossMode,row.Width,row.HiddenLayers,row.Optimizer,row.LearningRate,row.Rank, ...
            row.MedianPercent,row.MeanPercent,row.P95Percent,row.MaximumPercent, ...
            row.WorstObservedMaximumPercent);
    end
    fprintf(file,'\n');
end
fprintf(file,['## Umfang und Grenzen\n\n' ...
    '%d Auswertelaeufe, %d Fallvorhersagen, %d Konfiguration/Datensatz-Gruppen.\n\n' ...
    'Die Architektur/Loss-Studie umfasst Breiten 64/128, Schichten 1 bis 5, ' ...
    'Trainingsgroessen 12/24/48/96/192/384/768, zwei Losses und Seeds 42/43/44. ' ...
    'Optimierer und Lernrate wurden bei Breite 128 und 1/2 Schichten untersucht; ' ...
    'die Breitenstudie bei zwei Schichten, die Rangstudie bei Breite 64 und zwei Schichten. ' ...
    'Es handelt sich nicht um ein vollstaendiges gemeinsames Hyperparametergitter.\n\n' ...
    'PredictionSeconds ist eine einfache Diagnosemessung einschliesslich Wrapper und Rekonstruktion, ' ...
    'kein auf Wiederholungen beruhender Laufzeitbenchmark.\n\n' ...
    'Vollstaendige Ergebnisse: run_metrics.csv (je Seed), configuration_summary.csv ' ...
    '(je Konfiguration), case_errors.csv (je Fall), model_plan.csv und reference_manifest.csv ' ...
    '(Dateien und SHA-256). Originalergebnisse bleiben erhalten.\n'], ...
    height(result.runs),height(result.cases),height(result.summary));
fprintf(file,'\nDie neu berechneten Fallfehler wurden gegen die archivierten Fallfehler geprueft:\n\n');
for k=1:height(result.historicalVerification)
    row=result.historicalVerification(k,:);
    fprintf(file,'- %s: %d Laeufe, groesste absolute Differenz %.3g.\n', ...
        row.Study,row.VerifiedRuns,row.MaximumAbsoluteRelativeErrorDifference);
end
end

function hash=sha256File(file)
stream=java.security.MessageDigest.getInstance('SHA-256');
handle=fopen(file,'rb');
assert(handle>=0,'surrogate:reevaluation:Read','Cannot read %s',file);
cleanup=onCleanup(@()fclose(handle));
while ~feof(handle)
    bytes=fread(handle,1024*1024,'*uint8');
    stream.update(bytes);
end
hash=lower(string(reshape(dec2hex(typecast(stream.digest(),'uint8'),2).',1,[])));
end
