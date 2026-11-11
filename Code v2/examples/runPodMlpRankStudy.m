function result = runPodMlpRankStudy(outputDir)
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','pod_mlp_rank_study_20261110');
end
ranks=[1 2 4 6 8 10 15 20];
seeds=[42 43 44];
training=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
validation=surrogate.loadDataset(fullfile(root,'experiments', ...
    'pod_mlp_fresh_validation_128_20261108','reference_data','static','val.mat'));
surrogate.validateTrainingSplits(training,validation);
assert(numel(training.caseIds)==768 && numel(validation.caseIds)==128, ...
    'surrogate:rankStudy:DataCount','Expected 768 training and 128 validation cases.');
controlDir=fullfile(root,'experiments','pod_mlp_width_study_20261109_with128');
config=struct('ranks',ranks,'seeds',seeds,'hiddenWidth',64,'hiddenLayers',2, ...
    'trainingCases',768,'rank10ControlDir',string(controlDir), ...
    'trainingCaseIds',training.caseIds,'validationCaseIds',validation.caseIds, ...
    'validationDatasetId',"static-fresh-validation-v1-seed20261109-n128", ...
    'lossMode',"weighted_field_mse",'optimizer',"adam",'activation',"tanh", ...
    'maxEpochs',200,'miniBatchSize',32,'learningRate',1e-3, ...
    'outputNetwork',"last-iteration",'testDataLoaded',false, ...
    'validationPreviouslyUsedForModelComparison',true, ...
    'matlabVersion',string(version));
if isfolder(outputDir)
    saved=load(fullfile(outputDir,'study_config.mat'),'config');
    assert(isequaln(saved.config,config),'surrogate:rankStudy:ConfigMismatch', ...
        'Existing output belongs to a different configuration.');
else
    assert(~isfile(outputDir),'surrogate:rankStudy:Output','Output is a file.');
    mkdir(outputDir);
    save(fullfile(outputDir,'study_config.mat'),'config');
end
modelDir=fullfile(outputDir,'models');
if ~isfolder(modelDir), mkdir(modelDir); end
plan=table(repelem(ranks(:),numel(seeds)),repmat(seeds(:),numel(ranks),1), ...
    'VariableNames',{'Rank','Seed'});
writetable(plan,fullfile(outputDir,'study_plan.csv'));
writelines(["Exploratory POD-rank study on the previously used 128 validation cases; no test data loaded.";
    "Fixed: width 64, two tanh hidden layers, weighted_field_mse, Adam, learning rate 0.001, 200 epochs, batch size 32, 768 training cases.";
    "Ranks: "+join(string(ranks),", ")+". Seeds: 42, 43, 44. Rank 10 reuses the frozen width-study controls.";
    "POD energy uses centered, weighted training fields. Projection errors use exact validation coefficients in the training-only POD basis; they are diagnostics, not deployable predictions.";
    "Summary: median over the three seed-level metrics. P95: nearest rank across the 128 validation cases.";
    "Changing rank also changes output dimension, initialization and the shared coefficient RMS normalization under the existing training implementation."], ...
    fullfile(outputDir,'STUDY_SCOPE.txt'));
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
controls=readtable(fullfile(controlDir,'model_metrics.csv'), ...
    'TextType','string','Delimiter',',');
modelMetrics=table(); caseErrors=table(); manifest=table();
for podRank=ranks
    for seed=seeds
        subset=trainingSubset(training,seed);
        modelSettings=struct('seed',seed,'datasetId',"static-data-generation-v1", ...
            'rank',podRank,'hiddenWidth',64,'maxEpochs',200,'miniBatchSize',32, ...
            'learningRate',1e-3,'hiddenLayers',2,'lossMode',"weighted_field_mse");
        if podRank==10
            modelFile=fullfile(controlDir,'models',sprintf( ...
                'pod_mlp_weighted_width_64_layers_2_n768_seed%d.mat',seed));
        else
            modelFile=fullfile(modelDir,sprintf( ...
                'pod_mlp_rank_%d_width_64_layers_2_n768_seed%d.mat',podRank,seed));
        end
        if isfile(modelFile)
            model=surrogate.loadModel(modelFile);
        else
            assert(podRank~=10,'surrogate:rankStudy:Control','Missing rank-10 control.');
            fprintf('Training POD rank %d, width 64, two layers, seed %d.\n',podRank,seed);
            [model,~]=surrogate.fitModel("pod_mlp",subset,modelSettings);
            surrogate.saveModel(modelFile,model);
        end
        assert(isequaln(model.config,modelSettings) && ...
            isequal(model.trainingCaseIds,subset.caseIds), ...
            'surrogate:rankStudy:ModelConflict','Model settings or training IDs differ.');
        prediction=surrogate.predictModel(model,request);
        metrics=surrogate.evaluatePrediction(prediction,validation,metricConfig);
        assert(all(metrics.relativeErrorDefined),'surrogate:rankStudy:Relative','Undefined relative errors.');
        basis=model.state.basis;
        weights=double(validation.displacementComponentWeights(:));
        reference=double(validation.displacementFields);
        projected=model.state.fieldMean+basis*(basis'*(weights.*(reference-model.state.fieldMean)));
        projectionPrediction=prediction;
        projectionPrediction.displacementFields=projected;
        projectionMetrics=surrogate.evaluatePrediction(projectionPrediction,validation,metricConfig);
        neuralError=sqrt(sum(weights.*(double(prediction.displacementFields)-projected).^2,1))';
        totalSquared=metrics.absoluteWeightedFieldError.^2;
        decomposedSquared=projectionMetrics.absoluteWeightedFieldError.^2+neuralError.^2;
        assert(max(abs(totalSquared-decomposedSquared))<=1e-7*max(totalSquared)+eps^2, ...
            'surrogate:rankStudy:Projection','Weighted error decomposition failed.');
        run=table(podRank,seed,mean(metrics.absoluteWeightedFieldError), ...
            100*median(metrics.relativeWeightedFieldError), ...
            100*nearestP95(metrics.relativeWeightedFieldError), ...
            100*model.state.retainedEnergy, ...
            mean(projectionMetrics.absoluteWeightedFieldError), ...
            100*median(projectionMetrics.relativeWeightedFieldError), ...
            100*nearestP95(projectionMetrics.relativeWeightedFieldError),mean(neuralError), ...
            'VariableNames',{'Rank','Seed','MeanAbsoluteErrorM','MedianRelativePercent', ...
            'P95RelativePercent','RetainedTrainingEnergyPercent','ProjectionMeanAbsoluteErrorM', ...
            'ProjectionMedianRelativePercent','ProjectionP95RelativePercent','NeuralMeanAbsoluteErrorM'});
        if podRank==10
            control=controls(controls.Width==64 & controls.Seed==seed,:);
            assert(height(control)==1 && ...
                abs(control.MedianRelativePercent-run.MedianRelativePercent)<1e-10 && ...
                abs(control.P95RelativePercent-run.P95RelativePercent)<1e-10 && ...
                abs(control.MeanAbsoluteErrorM-run.MeanAbsoluteErrorM)<1e-16, ...
                'surrogate:rankStudy:ControlMismatch','Rank-10 metrics differ from the control.');
        end
        modelMetrics=[modelMetrics;run]; %#ok<AGROW>
        n=numel(validation.caseIds);
        block=table(repmat(podRank,n,1),repmat(seed,n,1),validation.caseIds, ...
            metrics.absoluteWeightedFieldError,metrics.referenceWeightedFieldNorm, ...
            metrics.relativeWeightedFieldError,projectionMetrics.absoluteWeightedFieldError, ...
            projectionMetrics.relativeWeightedFieldError,neuralError, ...
            'VariableNames',{'Rank','Seed','CaseId','AbsoluteErrorM','ReferenceNormM', ...
            'RelativeError','ProjectionAbsoluteErrorM','ProjectionRelativeError','NeuralErrorM'});
        caseErrors=[caseErrors;block]; %#ok<AGROW>
        manifest=[manifest;table(podRank,seed,string(modelFile),sha256File(modelFile), ...
            podRank==10,'VariableNames',{'Rank','Seed','File','SHA256','ReusedControl'})]; %#ok<AGROW>
        writetable(modelMetrics,fullfile(outputDir,'model_metrics.csv'));
        writetable(caseErrors,fullfile(outputDir,'validation_case_errors.csv'));
        writetable(manifest,fullfile(outputDir,'model_manifest.csv'));
        fprintf('Completed rank %d, seed %d: median %.3f%%, P95 %.3f%%.\n', ...
            podRank,seed,run.MedianRelativePercent,run.P95RelativePercent);
    end
end
summaryByRank=groupsummary(modelMetrics,"Rank","median", ...
    string(modelMetrics.Properties.VariableNames(3:end)));
assert(height(modelMetrics)==numel(ranks)*numel(seeds) && ...
    all(summaryByRank.GroupCount==numel(seeds)), ...
    'surrogate:rankStudy:RunCount','Incomplete rank study.');
writetable(summaryByRank,fullfile(outputDir,'summary_by_rank.csv'));
save(fullfile(outputDir,'rank_study_results.mat'),'config','modelMetrics', ...
    'caseErrors','summaryByRank','manifest','metricConfig','-v7.3');
plotRankStudy(modelMetrics,summaryByRank,ranks,seeds,outputDir);
result=struct('modelMetrics',modelMetrics,'caseErrors',caseErrors, ...
    'summaryByRank',summaryByRank,'manifest',manifest,'outputDir',string(outputDir));
end

function subset=trainingSubset(training,seed)
stream=RandStream('mt19937ar','Seed',seed);
order=[randperm(stream,384),384+randperm(stream,numel(training.caseIds)-384)];
subset=training;
subset.caseIds=training.caseIds(order);
subset.inputParameters=training.inputParameters(order,:);
subset.displacementFields=training.displacementFields(:,order);
subset=rmfield(subset,{'computationTimeSeconds','tipDisplacementZ', ...
    'maxDisplacementMagnitudeOnGrid','meshNodeCounts'});
end

function value=nearestP95(values)
values=sort(values);
value=values(ceil(.95*numel(values)));
end

function plotRankStudy(runs,summary,ranks,seeds,outputDir)
fig=figure('Visible','off','Position',[80 80 1500 530]);
tiled=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
colors=lines(numel(seeds));
metrics=["MeanAbsoluteErrorM","MedianRelativePercent","P95RelativePercent"];
labels=["Mittlerer absoluter Feldfehler [m]","Median relativer Feldfehler [%]", ...
    "P95 relativer Feldfehler [%]"];
for j=1:numel(metrics)
    ax=nexttile(tiled); hold(ax,'on');
    for k=1:numel(seeds)
        rows=runs(runs.Seed==seeds(k),:);
        plot(ax,rows.Rank,rows.(metrics(j)),'-o','Color',colors(k,:), ...
            'LineWidth',1.1,'DisplayName',sprintf('Seed %d',seeds(k)));
    end
    plot(ax,summary.Rank,summary.("median_"+metrics(j)),'-ks', ...
        'LineWidth',2,'MarkerFaceColor','k','DisplayName','Median ueber Seeds');
    ax.YScale='log'; grid(ax,'on'); xticks(ax,ranks); xtickangle(ax,45);
    xlabel(ax,'POD-Rang'); ylabel(ax,labels(j));
    if j==1, legend(ax,'Location','best'); end
end
title(tiled,'POD-MLP: Rangvergleich (64 Neuronen, 2 versteckte Schichten)');
savefig(fig,fullfile(outputDir,'error_by_rank.fig'));
exportgraphics(fig,fullfile(outputDir,'error_by_rank.png'),'Resolution',180);
close(fig);
fig=figure('Visible','off','Position',[80 80 1200 550]);
tiled=tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
ax=nexttile(tiled);
plot(ax,summary.Rank,100-summary.median_RetainedTrainingEnergyPercent,'-o','LineWidth',1.5);
ax.YScale='log'; grid(ax,'on'); xticks(ax,ranks); xtickangle(ax,45);
xlabel(ax,'POD-Rang'); ylabel(ax,'Verworfene gewichtete Trainingsenergie [%]');
ax=nexttile(tiled); hold(ax,'on');
plot(ax,summary.Rank,summary.median_MedianRelativePercent,'-o', ...
    'LineWidth',1.5,'DisplayName','POD-MLP gesamt');
plot(ax,summary.Rank,summary.median_ProjectionMedianRelativePercent,'-s', ...
    'LineWidth',1.5,'DisplayName','Reine POD-Projektion (exakte Koeffizienten)');
ax.YScale='log'; grid(ax,'on'); xticks(ax,ranks); xtickangle(ax,45);
xlabel(ax,'POD-Rang'); ylabel(ax,'Median relativer Feldfehler [%]');
legend(ax,'Location','best');
title(tiled,'POD-Diagnose: Trainingsenergie und Projektionsfehler auf Validierungsdaten');
savefig(fig,fullfile(outputDir,'pod_projection_diagnostics.fig'));
exportgraphics(fig,fullfile(outputDir,'pod_projection_diagnostics.png'),'Resolution',180);
close(fig);
end

function hash=sha256File(file)
fid=fopen(file,'rb');
assert(fid>=0,'surrogate:rankStudy:Read','Cannot read model file.');
cleanup=onCleanup(@()fclose(fid));
bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(string(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[])));
clear cleanup
end
