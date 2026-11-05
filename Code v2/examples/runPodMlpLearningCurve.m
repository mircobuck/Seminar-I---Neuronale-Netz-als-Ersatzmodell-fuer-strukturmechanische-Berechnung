function [summary,outputDir] = runPodMlpLearningCurve(outputDir, hiddenLayers, hiddenWidth)
%runPodMlpLearningCurve Train nested static POD-MLP subsets and validate.
%   The output directory must not yet exist. No test data is loaded.
if nargin<2, hiddenLayers=1; end
if nargin<3, hiddenWidth=64; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
assert(~isfolder(outputDir) && ~isfile(outputDir), ...
    'surrogate:learningCurve:Exists','Output path already exists: %s',outputDir);
dataDir=fullfile(root,'data_generation','data','static');
training=surrogate.loadDataset(fullfile(dataDir,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataDir,'val.mat'));
surrogate.validateTrainingSplits(training,validation);
counts=[12 24 48 96 192 384]; seeds=[42 43 44];
request=struct('inputParameters',validation.inputParameters, ...
    'parameterNames',validation.parameterNames,'parameterUnits',validation.parameterUnits, ...
    'caseIds',validation.caseIds);
metricConfig=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
mkdir(outputDir);
details=struct('count',{},'seed',{},'trainingIds',{},'report',{},'metrics',{},'modelFile',{});
row=0;
for seed=seeds
    % The same permutation makes the subsets nested within each seed.
    stream=RandStream('mt19937ar','Seed',seed);
    order=randperm(stream,numel(training.caseIds));
    for count=counts
        row=row+1; indices=order(1:count);
        subset=training;
        subset.caseIds=training.caseIds(indices);
        subset.inputParameters=training.inputParameters(indices,:);
        subset.displacementFields=training.displacementFields(:,indices);
        % Other per-case loader fields are not part of the training contract.
        subset=rmfield(subset,{'computationTimeSeconds','tipDisplacementZ', ...
            'maxDisplacementMagnitudeOnGrid','meshNodeCounts'});
        config=struct('seed',seed,'datasetId',"static-data-generation-v1", ...
            'rank',10,'hiddenWidth',hiddenWidth,'maxEpochs',200, ...
            'miniBatchSize',min(32,count),'learningRate',1e-3,'hiddenLayers',hiddenLayers);
        fprintf('Training: %d cases, seed %d\n',count,seed);
        [model,report]=surrogate.fitModel("pod_mlp",subset,config);
        prediction=surrogate.predictModel(model,request);
        metrics=surrogate.evaluatePrediction(prediction,validation,metricConfig);
        file=sprintf('pod_mlp_adam_%d_n%d_seed%d.mat',hiddenWidth,count,seed);
        surrogate.saveModel(fullfile(outputDir,file),model);
        details(row)=struct('count',count,'seed',seed,'trainingIds',subset.caseIds, ...
            'report',report,'metrics',metrics,'modelFile',file);
    end
end
summary=table('Size',[numel(details) 5], ...
    'VariableTypes',{'double','double','double','double','double'}, ...
    'VariableNames',{'TrainingCases','Seed','MedianRelativePercent','P95RelativePercent','UndefinedCount'});
for k=1:numel(details)
    errors=sort(details(k).metrics.relativeWeightedFieldError(details(k).metrics.relativeErrorDefined));
    summary.TrainingCases(k)=details(k).count; summary.Seed(k)=details(k).seed;
    summary.UndefinedCount(k)=nnz(~details(k).metrics.relativeErrorDefined);
    if isempty(errors)
        summary.MedianRelativePercent(k)=NaN; summary.P95RelativePercent(k)=NaN;
    else
        summary.MedianRelativePercent(k)=100*median(errors);
        summary.P95RelativePercent(k)=100*errors(ceil(.95*numel(errors)));
    end
end
save(fullfile(outputDir,'learning_curve.mat'),'summary','details','counts','seeds', ...
    'metricConfig','-v7.3');
writetable(summary,fullfile(outputDir,'learning_curve.csv'));
plotPodMlpLearningCurve(outputDir);
end
