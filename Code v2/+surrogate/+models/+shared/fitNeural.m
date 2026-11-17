% method either contains mlp or rbf
% data has the dataset for training
% config has obvious some config for training 
function [state,report] = fitNeural(method,data,config)
%fitNeural Shared training for direct MLP and fixed-center RBF models.
%   Only the supplied training split is used, including normalization.
%   Adam uses trainnet without internal validation or alternative optimizers.
%   The default is standardized MSE; static fields can use weighted MSE.
% lets measure some preprocessing time 
preprocessTimer=tic;
% write config in the even short name cfg with some added default values
cfg=defaults(config);
% which data is data. In our case: static
task=string(data.modality);
% check if static
assert(task=="static",'surrogate:neural:Task', ...
    'Only static displacement fields are supported.');
% INput and transposed outputparamters for the neural network    
X=double(data.inputParameters);
Y=double(data.displacementFields');
% normalize such that the input and output parameters have zero mean and unit variance
inputMean=mean(X,1); inputScale=std(X,0,1); inputScale(inputScale==0)=1;
outputMean=mean(Y,1); outputScale=std(Y,0,1);
constantOutputs=outputScale==0; outputScale(constantOutputs)=1;
% If loss function gets optimized with weighted mean squared error
if cfg.lossMode=="weighted_field_mse"
    weights=double(data.displacementComponentWeights(:))';
    sharedScale=sqrt(mean((Y-outputMean).^2.*weights,'all'));
    assert(isfinite(sharedScale),'surrogate:neural:TargetScale','Weighted target scale must be finite.');
    if sharedScale==0, sharedScale=1; end
    outputScale=sharedScale./sqrt(weights);
end
% normalize the input and output parameters for the neural network
X=(X-inputMean)./inputScale; Y=(Y-outputMean)./outputScale;
% end of time measurement
preprocessSeconds=toc(preprocessTimer);
% time measurement for center selection and RBF feature generation
centerTimer=tic;
% centers are only used for RBF, not for MLP. architecture is defined by hiddenWidth and hiddenLayers
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
% some time measurement for the setup of the neural network and training
trainTimer=tic;
setupTimer=tic;
% size of the input and data isnt normalized again
layers=featureInputLayer(size(X,2),Normalization="none");
% add hidden layers with tanh activation
for layer=1:numel(hidden)
    layers=[layers;fullyConnectedLayer(hidden(layer));tanhLayer]; %#ok<AGROW>
end
% output layer with linear activation for regression
layers=[layers;fullyConnectedLayer(size(Y,2))];
% trainingsoptions
options=trainingOptions(cfg.optimizer,'MaxEpochs',cfg.maxEpochs, ...
    'MiniBatchSize',cfg.miniBatchSize,'InitialLearnRate',cfg.learningRate, ...
    'Shuffle','every-epoch','OutputNetwork','last-iteration', ...
    'ExecutionEnvironment','cpu','Verbose',false);
% network setup
networkSetupSeconds=toc(setupTimer);
% timer for training
optimizationTimer=tic;
% training
network=trainnet(X,Y,layers,"mse",options);
% trianingsstime done
trainingSeconds=toc(optimizationTimer);

backend="trainnet";
% timemeasurement for training and build up of the net
trainSeconds=toc(trainTimer);
% safe the trained net
state=struct('method',method,'task',task,'network',network,'backend',backend, ...
    'inputMean',inputMean,'inputScale',inputScale,'outputMean',outputMean, ...
    'outputScale',outputScale,'constantOutputs',constantOutputs, ...
    'centers',centers,'settings',cfg);
% trianingsreport    
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
