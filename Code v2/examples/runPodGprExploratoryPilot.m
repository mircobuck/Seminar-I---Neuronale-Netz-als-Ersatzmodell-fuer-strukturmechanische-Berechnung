function runPodGprExploratoryPilot(outputDir)
%runPodGprExploratoryPilot Compare rank-2 methods on historical validation.
% Historical validation is exploratory and is not an independent test.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
assert(~isfolder(outputDir),'surrogate:pilot:OutputExists','Use a new directory.');
mkdir(outputDir);
train=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
val=surrogate.loadDataset(fullfile(root,'data_generation','data','static','val.mat'));
surrogate.validateTrainingSplits(train,val);
% Fixed equally sized subsamples from both data-generation blocks.
ids=readtable(fullfile(root,'data_generation','data','static','design.csv'));
original=intersect(train.caseIds,ids.id(ids.split=="train" & ids.id<=810460),'stable');
extended=setdiff(train.caseIds,original,'stable');
assert(numel(original)==384 && numel(extended)==384,'surrogate:pilot:Blocks','Unexpected training blocks.');
prior=rng; cleanup=onCleanup(@()rng(prior)); rng(20261112,'twister');
selected=[original(randperm(numel(original),24));extended(randperm(numel(extended),24))];
[ok,idx]=ismember(selected,train.caseIds); assert(all(ok));
train.caseIds=train.caseIds(idx); train.inputParameters=train.inputParameters(idx,:);
train.displacementFields=train.displacementFields(:,idx);
t=tic; pod=surrogate.models.shared.fitPod(train,2,"pod_gpr",[]); podSeconds=toc(t);
common=struct('seed',42,'datasetId',"exploratory_48",'rank',2,'preparedPod',pod);
mlp=common; mlp.hiddenWidth=64; mlp.hiddenLayers=2; mlp.maxEpochs=200;
mlp.miniBatchSize=32; mlp.learningRate=1e-3; mlp.lossMode="weighted_field_mse";
gpr=common; gpr.kernel="ardsquaredexponential"; gpr.basisFunction="constant"; gpr.sigma=1e-4;
methods=["pod_mlp","pod_gpr"]; configs={mlp,gpr};
request=struct('inputParameters',val.inputParameters,'parameterNames',val.parameterNames, ...
    'parameterUnits',val.parameterUnits,'caseIds',val.caseIds);
rows=table; metrics=struct; reports=struct;
for i=1:numel(methods)
    t=tic; [model,report]=surrogate.fitModel(methods(i),train,configs{i}); fitSeconds=toc(t);
    t=tic; prediction=surrogate.predictModel(model,request); predictSeconds=toc(t);
    result=surrogate.evaluatePrediction(prediction,val,struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
    e=result.relativeWeightedFieldError; sorted=sort(e(isfinite(e)));
    rows=[rows; table(methods(i),fitSeconds,podSeconds,predictSeconds,mean(e,'omitnan'), ...
        median(e,'omitnan'),sorted(ceil(.95*numel(sorted))),max(e),sum(~isfinite(e)), ...
        'VariableNames',{'Method','FitSeconds','SharedPodSeconds','PredictionSeconds','MeanRelative', ...
        'MedianRelative','P95Relative','MaximumRelative','UndefinedCount'})]; %#ok<AGROW>
    surrogate.saveModel(fullfile(outputDir,char(methods(i)+".mat")),model);
    metrics.(methods(i))=result; reports.(methods(i))=report;
end
writetable(rows,fullfile(outputDir,'pilot_summary.csv'));
save(fullfile(outputDir,'pilot_data.mat'),'selected','metrics','reports','podSeconds');
writelines(["EXPLORATORY ONLY: historical 12-case validation, not an independent test."; ...
    "Fit times exclude separate shared POD construction; see SharedPodSeconds."], ...
    fullfile(outputDir,'STATUS.txt'));
end
