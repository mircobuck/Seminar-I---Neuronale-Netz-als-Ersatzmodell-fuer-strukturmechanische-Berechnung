function [state,report] = fitNeural(method,data,config)
%fitNeural Shared training for direct MLP and fixed-center RBF models.
%   Only the supplied training split is used, including normalization.
%   Adam/SGDM use trainnet; LM/BR use feedforwardnet without internal splits.
%   The default is standardized MSE; static fields can use weighted MSE.
preprocessTimer=tic;
cfg=defaults(config);
task=string(data.modality);
assert(any(task==["static","modal"]),'surrogate:neural:Task', ...
    'Only static and modal tasks are supported.');
X=double(data.inputParameters);
if task=="static", Y=double(data.displacementFields');
else, Y=double(data.naturalFrequenciesHz); end
inputMean=mean(X,1); inputScale=std(X,0,1); inputScale(inputScale==0)=1;
outputMean=mean(Y,1); outputScale=std(Y,0,1);
constantOutputs=outputScale==0; outputScale(constantOutputs)=1;
if cfg.lossMode=="weighted_field_mse"
    assert(task=="static",'surrogate:neural:LossTask','Weighted field loss is static only.');
    weights=double(data.displacementComponentWeights(:))';
    sharedScale=sqrt(mean((Y-outputMean).^2.*weights,'all'));
    assert(isfinite(sharedScale),'surrogate:neural:TargetScale','Weighted target scale must be finite.');
    if sharedScale==0, sharedScale=1; end
    outputScale=sharedScale./sqrt(weights);
end
X=(X-inputMean)./inputScale; Y=(Y-outputMean)./outputScale;
preprocessSeconds=toc(preprocessTimer);
centerTimer=tic;
centers=[];
if method=="rbf"
    count=min(cfg.centerCount,size(X,1));
    centers=X(round(linspace(1,size(X,1),count)),:);
    X=surrogate.models.shared.rbfFeatures(X,centers,cfg.rbfWidth);
    hidden=repmat(cfg.hiddenWidth,1,cfg.hiddenLayers-1);
else
    hidden=repmat(cfg.hiddenWidth,1,cfg.hiddenLayers);
end
centerSeconds=toc(centerTimer);
trainTimer=tic;
setupTimer=tic;
if any(cfg.optimizer==["adam","sgdm"])
    layers=featureInputLayer(size(X,2),Normalization="none");
    for layer=1:numel(hidden)
        layers=[layers;fullyConnectedLayer(hidden(layer));tanhLayer]; %#ok<AGROW>
    end
    layers=[layers;fullyConnectedLayer(size(Y,2))];
    args={};
    if cfg.optimizer=="sgdm", args={'Momentum',cfg.momentum}; end
    options=trainingOptions(cfg.optimizer,'MaxEpochs',cfg.maxEpochs, ...
        'MiniBatchSize',cfg.miniBatchSize,'InitialLearnRate',cfg.learningRate, ...
        'Shuffle','every-epoch','OutputNetwork','last-iteration', ...
        'ExecutionEnvironment','cpu','Verbose',false,args{:});
    networkSetupSeconds=toc(setupTimer);
    optimizationTimer=tic;
    network=trainnet(X,Y,layers,"mse",options);
    trainingSeconds=toc(optimizationTimer);
    backend="trainnet";
else
    widths=[size(X,2),hidden,size(Y,2)];
    nParameters=sum((widths(1:end-1)+1).*widths(2:end));
    estimatedBytes=8*(nParameters^2+numel(Y)*nParameters);
    assert(isfinite(estimatedBytes) && estimatedBytes<=cfg.maxWorkspaceBytes, ...
        'surrogate:neural:MemoryLimit', ...
        'Estimated LM/BR workspace %.2f GiB exceeds limit %.2f GiB. Use Adam/SGDM or reduce the model.', ...
        estimatedBytes/1024^3,cfg.maxWorkspaceBytes/1024^3);
    trainFcn='trainlm';
    if cfg.optimizer=="bayesian-regularization", trainFcn='trainbr'; end
    network=feedforwardnet(hidden,trainFcn);
    % Disable implicit preprocessing before configuration to avoid fitting
    % a second normalization or removing constant output rows.
    network.inputs{1}.processFcns={};
    network.outputs{network.numLayers}.processFcns={};
    for layer=1:numel(hidden), network.layers{layer}.transferFcn='tansig'; end
    network.layers{network.numLayers}.transferFcn='purelin';
    network.divideFcn='dividetrain';
    network.trainParam.epochs=cfg.maxEpochs;
    network.trainParam.showWindow=false;
    network.trainParam.showCommandLine=false;
    network=configure(network,X',Y');
    networkSetupSeconds=toc(setupTimer);
    optimizationTimer=tic;
    network=train(network,X',Y');
    trainingSeconds=toc(optimizationTimer);
    backend="legacy";
end
trainSeconds=toc(trainTimer);
state=struct('method',method,'task',task,'network',network,'backend',backend, ...
    'inputMean',inputMean,'inputScale',inputScale,'outputMean',outputMean, ...
    'outputScale',outputScale,'constantOutputs',constantOutputs, ...
    'centers',centers,'settings',cfg);
report=struct('method',method,'trainingCount',size(X,1), ...
    'optimizer',cfg.optimizer,'lossMode',cfg.lossMode,'settings',cfg, ...
    'timing',struct('preprocessSeconds',preprocessSeconds,'centerSeconds',centerSeconds, ...
    'networkSetupSeconds',networkSetupSeconds,'trainingSeconds',trainingSeconds,'regressionSeconds',trainSeconds));
if method=="rbf", report.centerCount=size(centers,1); end
end

function cfg = defaults(cfg)
assert(isstruct(cfg) && isscalar(cfg),'surrogate:neural:Config','Expected scalar config struct.');
d=struct('hiddenWidth',64,'hiddenLayers',1,'centerCount',64,'rbfWidth',1,'optimizer',"adam", ...
    'maxEpochs',200,'miniBatchSize',32,'learningRate',1e-3,'momentum',0.9, ...
    'maxWorkspaceBytes',1024^3,'lossMode',"standardized_output_mse");
names=fieldnames(d);
for k=1:numel(names)
    if ~isfield(cfg,names{k}), cfg.(names{k})=d.(names{k}); end
end
integers={'hiddenWidth','hiddenLayers','centerCount','maxEpochs','miniBatchSize'};
for k=1:numel(integers)
    v=cfg.(integers{k});
    assert(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>=1 && v==fix(v), ...
        'surrogate:neural:Config','%s must be a positive integer.',integers{k});
end
positives={'rbfWidth','learningRate','maxWorkspaceBytes'};
for k=1:numel(positives)
    v=cfg.(positives{k});
    assert(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>0, ...
        'surrogate:neural:Config','%s must be positive and finite.',positives{k});
end
assert(isnumeric(cfg.momentum) && isreal(cfg.momentum) && isscalar(cfg.momentum) && ...
    isfinite(cfg.momentum) && cfg.momentum>=0 && cfg.momentum<1, ...
    'surrogate:neural:Config','momentum must be in [0,1).');
cfg.lossMode=string(cfg.lossMode);
assert(isscalar(cfg.lossMode) && any(cfg.lossMode==["standardized_output_mse","weighted_field_mse"]), ...
    'surrogate:neural:Config','Unsupported loss mode.');
cfg.optimizer=string(cfg.optimizer);
if isscalar(cfg.optimizer) && cfg.optimizer=="sgd-momentum", cfg.optimizer="sgdm"; end
assert(isscalar(cfg.optimizer) && any(cfg.optimizer== ...
    ["adam","sgdm","levenberg-marquardt","bayesian-regularization"]), ...
    'surrogate:neural:Config','Unsupported optimizer.');
end
