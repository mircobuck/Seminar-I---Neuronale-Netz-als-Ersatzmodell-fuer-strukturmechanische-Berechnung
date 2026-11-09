function result = runPodMlpLossPilot(outputDir)
%runPodMlpLossPilot Compare POD coefficient MSE with weighted field MSE.
%   Trains width-64 models with 1:3 hidden layers and seeds 42:44 on all
%   static training cases. Evaluation uses only the existing validation
%   split; no test data is loaded. OUTPUTDIR must not already exist.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','pod_mlp_loss_pilot_20261107');
end
assert(~isfolder(outputDir) && ~isfile(outputDir), ...
    'surrogate:lossPilot:Exists','Output path already exists: %s',outputDir);

dataDir=fullfile(root,'data_generation','data','static');
training=surrogate.loadDataset(fullfile(dataDir,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataDir,'val.mat'));
surrogate.validateTrainingSplits(training,validation);
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
lossModes=["per_coefficient_mse","weighted_field_mse"];
seeds=[42 43 44]; layersToTest=1:3; width=64;
n=numel(lossModes)*numel(seeds)*numel(layersToTest);
summary=table('Size',[n 10], ...
    'VariableTypes',{'string','double','double','double','double','double', ...
        'double','double','double','double'}, ...
    'VariableNames',{'LossMode','Width','HiddenLayers','TrainingCases','Seed', ...
        'MeanAbsoluteErrorM','MedianRelativePercent','P95RelativePercent', ...
        'MeanTrainingTimeSeconds','RetainedPODPercent'});
caseErrors=table(); modelFiles=strings(n,1);
row=0;
for lossMode=lossModes
    for hiddenLayers=layersToTest
        for seed=seeds
            row=row+1;
            config=struct('seed',seed,'datasetId',"static-data-generation-v1", ...
                'rank',10,'hiddenWidth',width,'maxEpochs',200, ...
                'miniBatchSize',32,'learningRate',1e-3, ...
                'hiddenLayers',hiddenLayers,'lossMode',lossMode);
            fprintf('Loss %s, width %d, layers %d, seed %d\n', ...
                lossMode,width,hiddenLayers,seed);
            started=tic;
            [model,report]=surrogate.fitModel("pod_mlp",training,config);
            trainingTime=toc(started);
            prediction=surrogate.predictModel(model,request);
            metrics=surrogate.evaluatePrediction(prediction,validation,metricConfig);
            relative=metrics.relativeWeightedFieldError(metrics.relativeErrorDefined);
            summary.LossMode(row)=lossMode;
            summary.Width(row)=width;
            summary.HiddenLayers(row)=hiddenLayers;
            summary.TrainingCases(row)=numel(training.caseIds);
            summary.Seed(row)=seed;
            summary.MeanAbsoluteErrorM(row)=mean(metrics.absoluteWeightedFieldError);
            summary.MedianRelativePercent(row)=100*median(relative);
            sortedRelative=sort(relative);
            summary.P95RelativePercent(row)=100*sortedRelative(ceil(.95*numel(sortedRelative)));
            summary.MeanTrainingTimeSeconds(row)=trainingTime;
            summary.RetainedPODPercent(row)=100*report.retainedEnergy;
            modelDir=fullfile(outputDir,char(lossMode));
            if ~isfolder(modelDir), mkdir(modelDir); end
            modelFile=sprintf('pod_mlp_%s_64_layers%d_seed%d.mat', ...
                lossMode,hiddenLayers,seed);
            modelFiles(row)=fullfile(modelDir,modelFile);
            surrogate.saveModel(modelFiles(row),model);
            block=table(repmat(lossMode,numel(validation.caseIds),1), ...
                repmat(hiddenLayers,numel(validation.caseIds),1), ...
                repmat(seed,numel(validation.caseIds),1),metrics.caseIds, ...
                metrics.absoluteWeightedFieldError,metrics.referenceWeightedFieldNorm, ...
                metrics.relativeWeightedFieldError, ...
                'VariableNames',{'LossMode','HiddenLayers','Seed','CaseId', ...
                    'AbsoluteErrorM','ReferenceNormM','RelativeError'});
            caseErrors=[caseErrors;block]; %#ok<AGROW>
        end
    end
end
metadata=struct('task',"static POD-MLP loss pilot", ...
    'datasetId',"static-data-generation-v1",'trainingCases',training.caseIds, ...
    'validationCases',validation.caseIds,'testDataLoaded',false, ...
    'width',width,'hiddenLayers',layersToTest,'seeds',seeds, ...
    'rank',10,'maxEpochs',200,'miniBatchSize',32,'learningRate',1e-3, ...
    'lossModes',lossModes,'metricConfig',metricConfig, ...
    'matlabVersion',string(version), ...
    'createdAt',string(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX')));
result=struct('summary',summary,'caseErrors',caseErrors, ...
    'metadata',metadata,'modelFiles',modelFiles);
save(fullfile(outputDir,'loss_pilot.mat'),'result','-v7.3');
writetable(summary,fullfile(outputDir,'summary.csv'));
writetable(caseErrors,fullfile(outputDir,'validation_case_errors.csv'));
end
