function [model,history]=fitControlledRestMLP(X,A,options)
%FITCONTROLLEDRESTMLP Fit a fixed-budget MLP without validation-driven stopping.
required={'HiddenLayers','Optimizer','Seed','Budget','BatchSize', ...
    'InitialLearnRate','L2Regularization','HistorySize', ...
    'GradientTolerance','StepTolerance'};
assert(isstruct(options) && all(isfield(options,required)), ...
    'femstudy:controlledMLP:Options','Options struct is missing required fields.');
assert(ismatrix(X) && ismatrix(A) && isnumeric(X) && isnumeric(A) && ...
    all(isfinite(X),'all') && all(isfinite(A),'all') && ...
    size(X,1)==size(A,1) && size(X,1)>=2, ...
    'femstudy:controlledMLP:Data','Inputs and coefficient targets must be finite aligned rows.');
assert(isvector(options.HiddenLayers) && ~isempty(options.HiddenLayers) && ...
    all(options.HiddenLayers>0) && ...
    all(options.HiddenLayers==floor(options.HiddenLayers)) && ...
    ismember(string(options.Optimizer),["adam","lbfgs"]) && ...
    options.Seed>=0 && options.Seed==floor(options.Seed) && ...
    options.Budget>=1 && options.Budget==floor(options.Budget) && ...
    options.BatchSize>=1 && options.BatchSize==floor(options.BatchSize) && ...
    options.InitialLearnRate>0 && options.L2Regularization>=0 && ...
    options.HistorySize>=1 && options.GradientTolerance>0 && options.StepTolerance>0, ...
    'femstudy:controlledMLP:Options','One or more training options are invalid.');
assert(size(X,1)==size(A,1) && size(X,1)>=2 && ...
    all(isfinite(X),'all') && all(isfinite(A),'all'), ...
    'femstudy:controlledMLP:Data','Inputs and coefficient targets must be finite aligned rows.');

model=struct;
model.kind="mlp";
model.xm=mean(X,1);
model.xs=std(X,0,1);
model.xs(model.xs==0)=1;
model.ym=mean(A,1);
model.ys=std(A,0,1);
model.ys(model.ys<=1e-12*max(max(abs(A),[],1),realmin))=1;
Xt=single((X-model.xm)./model.xs);
At=single((A-model.ym)./model.ys);

rng(options.Seed,'twister');
layers=featureInputLayer(size(X,2),Normalization="none");
hiddenLayers=options.HiddenLayers(:)';
for width=hiddenLayers
    layers=[layers;fullyConnectedLayer(width);tanhLayer]; %#ok<AGROW>
end
layers=[layers;fullyConnectedLayer(size(A,2))];
net=dlnetwork(layers);
net=initialize(net,dlarray(single(zeros(size(X,2),1)),"CB"));
initialWeightsHash=hashLearnables(net);

switch options.Optimizer
    case "adam"
        trainOptions=trainingOptions("adam", ...
            MaxEpochs=options.Budget, ...
            MiniBatchSize=options.BatchSize, ...
            InitialLearnRate=options.InitialLearnRate, ...
            Shuffle="every-epoch", ...
            L2Regularization=options.L2Regularization, ...
            ExecutionEnvironment="cpu", ...
            OutputNetwork="last-iteration", ...
            Verbose=false);
    case "lbfgs"
        trainOptions=trainingOptions("lbfgs", ...
            MaxIterations=options.Budget, ...
            HistorySize=options.HistorySize, ...
            GradientTolerance=options.GradientTolerance, ...
            StepTolerance=options.StepTolerance, ...
            L2Regularization=options.L2Regularization, ...
            ExecutionEnvironment="cpu", ...
            Verbose=false);
end
started=tic;
[net,info]=trainnet(Xt,At,net,"mse",trainOptions);
trainingSeconds=toc(started);
history=extractHistory(info,options.Optimizer,options.Budget);
model.net=net;
model.hiddenLayers=hiddenLayers;
model.optimizer=options.Optimizer;
model.seed=options.Seed;
model.budget=options.Budget;
model.batchSize=options.BatchSize;
model.initialLearnRate=options.InitialLearnRate;
model.l2Regularization=options.L2Regularization;
model.initialWeightsHash=initialWeightsHash;
model.trainingSeconds=trainingSeconds;
model.history=history;
end

function history=extractHistory(info,optimizer,budget)
history=struct('infoClass',string(class(info)), ...
    'optimizer',optimizer,'budget',budget, ...
    'iteration',zeros(0,1),'epoch',zeros(0,1), ...
    'trainingLoss',zeros(0,1),'validationLoss',zeros(0,1), ...
    'stopReason',"not-reported");
if isprop(info,'TrainingHistory')
    trainTable=info.TrainingHistory;
    if istable(trainTable)
        variables=trainTable.Properties.VariableNames;
        if ismember('Iteration',variables), history.iteration=trainTable.Iteration(:); end
        if ismember('Epoch',variables), history.epoch=trainTable.Epoch(:); end
        if ismember('Loss',variables), history.trainingLoss=trainTable.Loss(:); end
    end
end
if isprop(info,'ValidationHistory')
    validationTable=info.ValidationHistory;
    if istable(validationTable) && ismember('Loss',validationTable.Properties.VariableNames)
        history.validationLoss=validationTable.Loss(:);
    end
end
if isprop(info,'StopReason')
    history.stopReason=string(info.StopReason);
elseif strcmp(optimizer,"adam")
    history.stopReason="maximum-epochs-or-trainer-stop";
elseif ~isempty(history.iteration)
    history.stopReason="lbfgs-terminated-before-or-at-budget";
end
end

function hash=hashLearnables(net)
values=net.Learnables.Value;
bytes=zeros(0,1,'uint8');
for i=1:numel(values)
    value=single(extractdata(values{i}));
    item=typecast(value(:),'uint8');
    bytes=[bytes;item(:)]; %#ok<AGROW>
end
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
end
