function result = runPodMlpLossStudy(outputDir)
%runPodMlpLossStudy Compare both POD-MLP losses across the full width/depth study.
%   Trains widths 64/128, depths 1:5, training sizes 12:768, and seeds 42:44.
%   Uses only the static validation split; test data is never loaded.
%   An interrupted run can be resumed with the same OUTPUTDIR.
%
%   The historical per_coefficient_mse results are read only from their
%   existing aggregate CSV. This runner trains only weighted_field_mse models.
%   Each new model is trained on the same seeded training IDs as its historical
%   counterpart, and all predictions are scored against the same validation IDs.

% Resolve project paths relative to this file so MATLAB's current folder does
% not affect which source code or datasets are used.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','pod_mlp_loss_study_20261107');
end

% Load only train and validation files. Keeping this list explicit ensures
% this experiment never opens or reads the already-used test split.
dataDir=fullfile(root,'data_generation','data','static');
training=surrogate.loadDataset(fullfile(dataDir,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataDir,'val.mat'));
surrogate.validateTrainingSplits(training,validation);
assert(numel(training.caseIds)>=768, ...
    'surrogate:lossStudy:TrainingCount','The full study requires 768 training cases.');

widths=[64 128]; depths=1:5; counts=[12 24 48 96 192 384 768];
seeds=[42 43 44]; lossMode="weighted_field_mse";
% Persist all choices that define the experiment, including the exact split
% IDs. On resume, an exact match is required before any saved model is reused.
config=struct('datasetId',"static-data-generation-v1", ...
    'trainingCaseIds',training.caseIds,'validationCaseIds',validation.caseIds, ...
    'widths',widths,'depths',depths,'trainingCounts',counts,'seeds',seeds, ...
    'lossMode',lossMode,'rank',10,'maxEpochs',200,'miniBatchSize',32, ...
    'learningRate',1e-3,'optimizer',"adam",'activation',"tanh", ...
    'outputNetwork',"last-iteration",'matlabVersion',string(version));
if isfolder(outputDir) || isfile(outputDir)
    assert(isfolder(outputDir) && isfile(fullfile(outputDir,'study_config.mat')), ...
        'surrogate:lossStudy:ExistingOutput', ...
        'Existing output is not a resumable loss study: %s',outputDir);
    saved=load(fullfile(outputDir,'study_config.mat'),'config');
    assert(isequaln(saved.config,config), ...
        'surrogate:lossStudy:ConfigMismatch', ...
        'Output folder belongs to a different study configuration.');
else
    [created,message]=mkdir(outputDir);
    assert(created,'surrogate:lossStudy:Directory','Cannot create output: %s',message);
    save(fullfile(outputDir,'study_config.mat'),'config');
end

% Each completed fit is checkpointed as a model plus one summary row and its
% validation-case rows. These tables make long runs inspectable and resumable.
runSummaryPath=fullfile(outputDir,'summary_runs.csv');
caseErrorsPath=fullfile(outputDir,'validation_case_errors.csv');
if isfile(runSummaryPath)
    summaryRuns=readtable(runSummaryPath,'TextType','string');
else
    summaryRuns=emptyRunSummary();
end
if isfile(caseErrorsPath)
    caseErrors=readtable(caseErrorsPath,'TextType','string');
else
    caseErrors=emptyCaseErrors();
end

% Prediction requests and metric thresholds are made once because every model
% uses the identical ordered validation cases and the same field-error metric.
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
modelDir=fullfile(outputDir,'models');
if ~isfolder(modelDir), mkdir(modelDir); end
for width=widths
    for depth=depths
        for seed=seeds
            % Match runPodMlpLearningCurve exactly: each seed gives a nested
            % permutation of the original 384 training cases, followed by a
            % seeded permutation of the 384 appended training cases.
            stream=RandStream('mt19937ar','Seed',seed);
            originalCount=min(384,numel(training.caseIds));
            order=[randperm(stream,originalCount), ...
                originalCount+randperm(stream,numel(training.caseIds)-originalCount)];
            for count=counts
                alreadyDone=summaryRuns.Width==width & ...
                    summaryRuns.HiddenLayers==depth & ...
                    summaryRuns.TrainingCases==count & summaryRuns.Seed==seed;
                if any(alreadyDone)
                    % A checkpoint is complete only when it has exactly one
                    % run row, a saved model, and one error row per val case.
                    assert(nnz(alreadyDone)==1 && isfile(modelPath(modelDir,width,depth,count,seed)) && ...
                        nnz(caseErrors.Width==width & caseErrors.HiddenLayers==depth & ...
                        caseErrors.TrainingCases==count & caseErrors.Seed==seed)==numel(validation.caseIds), ...
                        'surrogate:lossStudy:Checkpoint','Incomplete checkpoint for width %d, depth %d, count %d, seed %d.', ...
                        width,depth,count,seed);
                    continue
                end

                indices=order(1:count);
                subset=training;
                subset.caseIds=training.caseIds(indices);
                subset.inputParameters=training.inputParameters(indices,:);
                subset.displacementFields=training.displacementFields(:,indices);
                subset=rmfield(subset,{'computationTimeSeconds','tipDisplacementZ', ...
                    'maxDisplacementMagnitudeOnGrid','meshNodeCounts'});
                file=modelPath(modelDir,width,depth,count,seed);
                modelConfig=struct('seed',seed,'datasetId',config.datasetId, ...
                    'rank',config.rank,'hiddenWidth',width,'maxEpochs',config.maxEpochs, ...
                    'miniBatchSize',min(config.miniBatchSize,count), ...
                    'learningRate',config.learningRate,'hiddenLayers',depth, ...
                    'lossMode',lossMode);
                if isfile(file)
                    % A model may have been written just before an interrupted
                    % run. Reuse it only if both its exact training IDs and all
                    % fitting settings agree with the requested run.
                    savedModel=surrogate.loadModel(file);
                    assert(isequal(savedModel.trainingCaseIds,subset.caseIds) && ...
                        isequaln(savedModel.config,modelConfig), ...
                        'surrogate:lossStudy:ModelConflict', ...
                        'Existing checkpoint model does not match the study: %s',file);
                    model=savedModel;
                    report=struct('retainedEnergy',model.state.retainedEnergy);
                    trainingTime=NaN;
                else
                    fprintf('Loss %s, width %d, layers %d, cases %d, seed %d\n', ...
                        lossMode,width,depth,count,seed);
                    started=tic;
                    [model,report]=surrogate.fitModel("pod_mlp",subset,modelConfig);
                    trainingTime=toc(started);
                    surrogate.saveModel(file,model);
                end

                % Evaluate the reconstructed physical fields, not just the
                % normalized coefficient targets used by the training loss.
                prediction=surrogate.predictModel(model,request);
                metrics=surrogate.evaluatePrediction(prediction,validation,metricConfig);
                relative=sort(metrics.relativeWeightedFieldError(metrics.relativeErrorDefined));
                run=table(lossMode,width,depth,count,seed, ...
                    mean(metrics.absoluteWeightedFieldError), ...
                    100*median(relative),100*relative(ceil(.95*numel(relative))), ...
                    trainingTime,100*report.retainedEnergy, ...
                    'VariableNames',summaryRuns.Properties.VariableNames);
                summaryRuns=[summaryRuns;run]; %#ok<AGROW>
                block=table(repmat(width,numel(validation.caseIds),1), ...
                    repmat(depth,numel(validation.caseIds),1), ...
                    repmat(count,numel(validation.caseIds),1), ...
                    repmat(seed,numel(validation.caseIds),1),validation.caseIds, ...
                    metrics.absoluteWeightedFieldError,metrics.referenceWeightedFieldNorm, ...
                    metrics.relativeWeightedFieldError, ...
                    'VariableNames',caseErrors.Properties.VariableNames);
                caseErrors=[caseErrors;block]; %#ok<AGROW>
                % Write after each model, so completed work survives MATLAB
                % interruption and can be verified before a resume.
                writetable(summaryRuns,runSummaryPath);
                writetable(caseErrors,caseErrorsPath);
            end
        end
    end
end

% Reduce three seed runs to one architecture/training-size row, then pair it
% with the old-loss aggregate on identical width/depth/count keys.
summaryByArchitecture=aggregateRuns(summaryRuns,widths,depths,counts,seeds);
writetable(summaryByArchitecture,fullfile(outputDir,'summary_by_architecture.csv'));
oldSummary=readtable(fullfile(root,'experiments', ...
    'learning_curve_metrics_12_to_768_widths_1to5.csv'));
comparison=joinOldAndNew(summaryByArchitecture,oldSummary);
writetable(comparison,fullfile(outputDir,'comparison_old_vs_weighted_loss.csv'));
metadata=struct('config',config,'testDataLoaded',false, ...
    'completedRuns',height(summaryRuns),'validationCaseCount',numel(validation.caseIds), ...
    'createdAt',string(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX')));
save(fullfile(outputDir,'loss_study_results.mat'), ...
    'summaryRuns','caseErrors','summaryByArchitecture','comparison','metadata','-v7.3');
result=struct('summaryRuns',summaryRuns,'caseErrors',caseErrors, ...
    'summaryByArchitecture',summaryByArchitecture,'comparison',comparison, ...
    'metadata',metadata);
end

function path=modelPath(modelDir,width,depth,count,seed)
% Keep each combination in its own file so partial studies are auditable.
path=fullfile(modelDir,sprintf('pod_mlp_weighted_%d_width_%d_layers_n%d_seed%d.mat', ...
    width,depth,count,seed));
end

function tableOut=emptyRunSummary()
% Define fixed column types so fresh runs and CSV-based resumes concatenate
% without implicit numeric/string conversions.
tableOut=table('Size',[0 10], ...
    'VariableTypes',{'string','double','double','double','double','double', ...
        'double','double','double','double'}, ...
    'VariableNames',{'LossMode','Width','HiddenLayers','TrainingCases','Seed', ...
        'MeanAbsoluteErrorM','MedianRelativePercent','P95RelativePercent', ...
        'MeanTrainingTimeSeconds','RetainedPODPercent'});
end

function tableOut=emptyCaseErrors()
% Store one row per model and validation case, with physical units in names.
tableOut=table('Size',[0 8], ...
    'VariableTypes',{'double','double','double','double','double','double','double','double'}, ...
    'VariableNames',{'Width','HiddenLayers','TrainingCases','Seed','CaseId', ...
        'AbsoluteErrorM','ReferenceNormM','RelativeError'});
end

function output=aggregateRuns(runs,widths,depths,counts,seeds)
% Report seed ranges and medians without counting seeds as test cases.
output=table();
for width=widths
    for depth=depths
        for count=counts
            rows=runs(runs.Width==width & runs.HiddenLayers==depth & ...
                runs.TrainingCases==count,:);
            assert(height(rows)==numel(seeds),'surrogate:lossStudy:RunCount', ...
                'Expected one run per seed for width %d, depth %d, count %d.',width,depth,count);
            % Seed min/max and median summarize stochastic training runs;
            % the 12 validation cases remain the only evaluation cases.
            output=[output;table(width,depth,count,height(rows), ...
                min(rows.MeanAbsoluteErrorM),max(rows.MeanAbsoluteErrorM), ...
                median(rows.MeanAbsoluteErrorM), ...
                min(rows.MedianRelativePercent),max(rows.MedianRelativePercent), ...
                median(rows.MedianRelativePercent), ...
                min(rows.P95RelativePercent),max(rows.P95RelativePercent), ...
                median(rows.P95RelativePercent), ...
                'VariableNames',{'NeuronsPerLayer','HiddenLayers','TrainingCases','SeedCount', ...
                    'MeanAbsoluteError_m_minSeed','MeanAbsoluteError_m_maxSeed', ...
                    'MeanAbsoluteError_m_medianOfSeeds','MedianRelativePercent_minSeed', ...
                    'MedianRelativePercent_maxSeed','MedianRelativePercent_medianOfSeeds', ...
                    'P95RelativePercent_minSeed','P95RelativePercent_maxSeed', ...
                    'P95RelativePercent_medianOfSeeds'})]; %#ok<AGROW>
        end
    end
end
end

function output=joinOldAndNew(new,old)
% The historical CSV is already aggregated over seeds; rename its metrics
% before joining so the old and new values remain unambiguous.
old=old(:,{'NeuronsPerLayer','HiddenLayers','TrainingCases', ...
    'MeanAbsoluteError_m_medianOfSeeds','MedianRelativePercent_medianOfSeeds', ...
    'P95RelativePercent_medianOfSeeds'});
old.Properties.VariableNames(4:6)= ...
    {'OldLossMeanAbsoluteError_m','OldLossMedianRelativePercent','OldLossP95RelativePercent'};
output=outerjoin(new,old,'Keys',{'NeuronsPerLayer','HiddenLayers','TrainingCases'}, ...
    'MergeKeys',true,'Type','left');
output.MedianRelativePercentImprovement= ...
    output.OldLossMedianRelativePercent-output.MedianRelativePercent_medianOfSeeds;
output.P95RelativePercentImprovement= ...
    output.OldLossP95RelativePercent-output.P95RelativePercent_medianOfSeeds;
output.MeanAbsoluteErrorImprovement_m= ...
    output.OldLossMeanAbsoluteError_m-output.MeanAbsoluteError_m_medianOfSeeds;
end
