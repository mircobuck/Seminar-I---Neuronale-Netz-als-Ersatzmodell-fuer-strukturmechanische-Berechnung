function [state,report] = fitNeural(method,data,config)
%fitNeural Shared training for direct MLP and fixed-center RBF models.
%   Only the supplied training split is used, including normalization.
%   Adam uses trainnet without internal validation or alternative optimizers.
%   The default is standardized MSE; static fields can use weighted MSE.
preprocessTimer=tic;
cfg=defaults(config);
task=string(data.modality);
assert(task=="static",'surrogate:neural:Task', ...
    'Only static displacement fields are supported.');
X=double(data.inputParameters);
Y=double(data.displacementFields');
inputMean=mean(X,1); inputScale=std(X,0,1); inputScale(inputScale==0)=1;
outputMean=mean(Y,1); outputScale=std(Y,0,1);
constantOutputs=outputScale==0; outputScale(constantOutputs)=1;
if cfg.lossMode=="weighted_field_mse"
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
layers=featureInputLayer(size(X,2),Normalization="none");
for layer=1:numel(hidden)
    layers=[layers;fullyConnectedLayer(hidden(layer));tanhLayer]; %#ok<AGROW>
end
layers=[layers;fullyConnectedLayer(size(Y,2))];
options=trainingOptions(cfg.optimizer,'MaxEpochs',cfg.maxEpochs, ...
    'MiniBatchSize',cfg.miniBatchSize,'InitialLearnRate',cfg.learningRate, ...
    'Shuffle','every-epoch','OutputNetwork','last-iteration', ...
    'ExecutionEnvironment','cpu','Verbose',false);
networkSetupSeconds=toc(setupTimer);
optimizationTimer=tic;
network=trainnet(X,Y,layers,"mse",options);
trainingSeconds=toc(optimizationTimer);
backend="trainnet";
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
    'maxEpochs',200,'miniBatchSize',32,'learningRate',1e-3, ...
    'lossMode',"standardized_output_mse");
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
positives={'rbfWidth','learningRate'};
for k=1:numel(positives)
    v=cfg.(positives{k});
    assert(isnumeric(v) && isreal(v) && isscalar(v) && isfinite(v) && v>0, ...
        'surrogate:neural:Config','%s must be positive and finite.',positives{k});
end
cfg.lossMode=string(cfg.lossMode);
assert(isscalar(cfg.lossMode) && any(cfg.lossMode==["standardized_output_mse","weighted_field_mse"]), ...
    'surrogate:neural:Config','Unsupported loss mode.');
cfg.optimizer=string(cfg.optimizer);
assert(isscalar(cfg.optimizer) && cfg.optimizer=="adam", ...
    'surrogate:neural:Config','The current static study supports Adam only.');
end
