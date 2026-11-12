function [state,report] = fit(data,config)
%fit Trainiere ein gewichtetes POD-MLP fuer statische Verschiebungsfelder.
%   data enthaelt N Trainingsfaelle, Eingabeparameter und Verschiebungsfelder.
%   config benoetigt rank, hiddenWidth, maxEpochs, miniBatchSize,
%   learningRate und hiddenLayers. Optional ist lossMode:
%   "per_coefficient_mse" (Standard, rueckwaertskompatibel) oder
%   "weighted_field_mse". Die zweite Variante normiert alle POD-Zielkoeffizienten
%   mit derselben Trainings-RMS-Skala; dadurch entspricht die trainnet-MSE bis
%   auf einen konstanten Faktor dem mittleren gewichteten Feldfehler.
%   Optional ist optimizer: "adam" (Standard), "rmsprop" oder "sgdm".
%   state enthaelt Netz und Transformationen fuer Vorhersagen.
%   report enthaelt Trainingsumfang, POD-Rang und erhaltene Energie.
%   Fehler-IDs: surrogate:pod_mlp:Task, surrogate:pod_mlp:Config,
%   surrogate:pod_mlp:Rank.

% Validierung: Nur statische Daten und gueltige Netzparameter trainieren.
assert(string(data.modality)=="static",'surrogate:pod_mlp:Task', ...
    'POD-MLP supports static displacement fields only.');
required={'rank','hiddenWidth','maxEpochs','miniBatchSize', ...
    'learningRate','hiddenLayers'};
assert(isstruct(config) && isscalar(config), ...
    'surrogate:pod_mlp:Config','config must be a scalar struct.');
missing=required(~isfield(config,required));
assert(isempty(missing),'surrogate:pod_mlp:Config', ...
    'Missing required config fields: %s.',strjoin(missing,', '));
integerParameters={'rank','hiddenWidth','maxEpochs','miniBatchSize','hiddenLayers'};
for k=1:numel(integerParameters)
    parameterValue=config.(integerParameters{k});
    parameterName=integerParameters{k};
    assert(isnumeric(parameterValue) && isreal(parameterValue) && ...
        isscalar(parameterValue) && isfinite(parameterValue) && ...
        parameterValue>=1 && parameterValue==fix(parameterValue), ...
        'surrogate:pod_mlp:Config', ...
        '%s must be a positive integer.',parameterName);
end
assert(isnumeric(config.learningRate) && isreal(config.learningRate) && ...
    isscalar(config.learningRate) && isfinite(config.learningRate) && ...
    config.learningRate>0, 'surrogate:pod_mlp:Config', ...
    'learningRate must be positive and finite.');
% Keep the historical behavior as the default so existing configurations and
% saved-model workflows do not change unless a new loss is requested.
lossMode="per_coefficient_mse";
if isfield(config,'lossMode')
    lossMode=string(config.lossMode);
end
assert(isscalar(lossMode) && any(lossMode==["per_coefficient_mse","weighted_field_mse"]), ...
    'surrogate:pod_mlp:Config','Unsupported lossMode: %s.',lossMode);
optimizer="adam";
if isfield(config,'optimizer')
    optimizer=string(config.optimizer);
end
assert(isscalar(optimizer) && any(optimizer==["adam","rmsprop","sgdm"]), ...
    'surrogate:pod_mlp:Config','Unsupported optimizer: %s.',optimizer);

% Shared training-only POD; optionally use the identical checked basis.
podTimer=tic; prepared=[];
if isfield(config,'preparedPod'), prepared=config.preparedPod; end
pod=surrogate.models.shared.fitPod(data,config.rank,"pod_mlp",prepared);
podSeconds=toc(podTimer);
displacementFields=double(data.displacementFields);
componentWeights=pod.weights; fieldMean=pod.fieldMean; podBasis=pod.basis;
numericalRank=pod.numericalRank;
centeredFields=displacementFields-fieldMean;
targetCoefficients=(podBasis'*(componentWeights.*centeredFields))';
preprocessTimer=tic;

% Normierung: Eingaben [nCases x nParameter], Ziele [nCases x rank].
% Statistiken stammen nur aus dem Trainingssatz, damit Vorhersagen dieselbe
% Transformation nutzen und keine Information aus Validierungsdaten einfliesst.
inputParameters=double(data.inputParameters);
inputMean=mean(inputParameters,1);
inputScale=std(inputParameters,0,1);
% Konstante Groessen bleiben nach Zentrierung null; Skala 1 verhindert 0/0.
inputScale(inputScale==0)=1;
coefficientMean=mean(targetCoefficients,1);
coefficientScale=std(targetCoefficients,0,1);
constantCoefficients=coefficientScale==0;
coefficientScale(constantCoefficients)=1;
if lossMode=="weighted_field_mse"
    % A weighted-orthonormal POD basis preserves the weighted field norm:
    % ||u_hat-u||_W^2 = sum_j (c_hat_j-c_j)^2.
    % A single RMS scale therefore changes the MSE only by one common
    % positive factor; unlike per-coefficient scaling, it does not reweight
    % modes according to their individual standard deviations.
    % RMS is computed from training targets only. It fixes the overall loss
    % scale without using validation/test statistics or changing relative
    % importance between POD modes.
    sharedScale=sqrt(mean((targetCoefficients-coefficientMean).^2,'all'));
    assert(isfinite(sharedScale) && sharedScale>0, ...
        'surrogate:pod_mlp:TargetScale','Shared POD coefficient scale must be positive.');
    coefficientScale=repmat(sharedScale,1,config.rank);
end
normalizedInputs=(inputParameters-inputMean)./inputScale;
normalizedTargets=(targetCoefficients-coefficientMean)./coefficientScale;

preprocessSeconds=toc(preprocessTimer);
% Netz: Konfigurierte tanh-Schichten und lineare Ausgabe fuer POD-Koeffizienten.
setupTimer=tic;
layers=featureInputLayer(size(normalizedInputs,2),Normalization="none");
for k=1:config.hiddenLayers
    layers=[layers; fullyConnectedLayer(config.hiddenWidth); tanhLayer]; %#ok<AGROW>
end
layers=[layers; fullyConnectedLayer(config.rank)];
% Training uses the same MSE implementation for both modes. The target
% normalization above selects the objective; optimizer and training settings
% are otherwise identical, preserving the historical default behavior.
options=trainingOptions(optimizer,MaxEpochs=config.maxEpochs, ...
    MiniBatchSize=config.miniBatchSize,InitialLearnRate=config.learningRate, ...
    Shuffle="every-epoch",OutputNetwork="last-iteration", ...
    ExecutionEnvironment="cpu",Verbose=false);
networkSetupSeconds=toc(setupTimer);
trainTimer=tic;
network=trainnet(normalizedInputs,normalizedTargets,layers,"mse",options);
trainSeconds=toc(trainTimer);

% Rueckgabe: State enthaelt alle Transformationen, die predict.m benoetigt.
% Store the retained POD energy and loss name alongside the transforms so
% saved artifacts fully describe which training objective produced them.
state=struct('network',network,'basis',podBasis,'fieldMean',fieldMean, ...
    'inputMean',inputMean,'inputScale',inputScale, ...
    'coefficientMean',coefficientMean,'coefficientScale',coefficientScale, ...
    'constantCoefficients',constantCoefficients,'lossMode',lossMode, ...
    'retainedEnergy',pod.retainedEnergy,'weights',pod.weights, ...
    'numericalRank',pod.numericalRank,'podFingerprint',pod.fingerprint, ...
    'settings',config);
% Report dokumentiert Trainingsumfang, Rang, Energieanteil und Einstellungen.
report=struct('method',"pod_mlp",'trainingCount',size(inputParameters,1), ...
    'numericalRank',numericalRank,'podRank',config.rank, ...
    'retainedEnergy',state.retainedEnergy, ...
    'optimizer',optimizer,'lossMode',lossMode,'settings',config, ...
    'timing',struct('podSeconds',podSeconds,'preprocessSeconds',preprocessSeconds, ...
    'networkSetupSeconds',networkSetupSeconds,'trainingSeconds',trainSeconds,'regressionSeconds',trainSeconds));
end
