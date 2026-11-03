function [state,report] = fit(data,config)
%fit Train a weighted POD-MLP on static displacement fields.
assert(string(data.modality)=="static",'surrogate:pod_mlp:Task', ...
    'POD-MLP supports static displacement fields only.');
defaults=struct('rank',10,'hiddenWidth',64,'maxEpochs',200, ...
    'miniBatchSize',32,'learningRate',1e-3);
names=fieldnames(defaults);
for k=1:numel(names)
    if ~isfield(config,names{k}), config.(names{k})=defaults.(names{k}); end
end
integers={'rank','hiddenWidth','maxEpochs','miniBatchSize'};
for k=1:numel(integers)
    value=config.(integers{k});
    assert(isnumeric(value) && isreal(value) && isscalar(value) && ...
        isfinite(value) && value>=1 && value==fix(value), ...
        'surrogate:pod_mlp:Config','%s must be a positive integer.',integers{k});
end
assert(isnumeric(config.learningRate) && isreal(config.learningRate) && ...
    isscalar(config.learningRate) && isfinite(config.learningRate) && config.learningRate>0, ...
    'surrogate:pod_mlp:Config','learningRate must be positive and finite.');

% Weighted SVD yields a basis orthonormal in the FEM field metric.
fields=double(data.displacementFields);
weights=double(data.displacementComponentWeights(:));
fieldMean=mean(fields,2);
weightedFields=sqrt(weights).*(fields-fieldMean);
[U,S,~]=svd(weightedFields,'econ');
singularValues=diag(S);
numericalRank=sum(singularValues>max(size(weightedFields))*eps(max(singularValues)));
assert(config.rank<=numericalRank,'surrogate:pod_mlp:Rank', ...
    'Requested POD rank %d exceeds numerical training rank %d.',config.rank,numericalRank);
basis=U(:,1:config.rank)./sqrt(weights);
coefficients=(basis'*(weights.*(fields-fieldMean)))';

% All learned transforms come from training data and travel with the model.
X=double(data.inputParameters);
inputMean=mean(X,1); inputScale=std(X,0,1); inputScale(inputScale==0)=1;
coefficientMean=mean(coefficients,1);
coefficientScale=std(coefficients,0,1);
constantCoefficients=coefficientScale==0;
coefficientScale(constantCoefficients)=1;
X=(X-inputMean)./inputScale;
Y=(coefficients-coefficientMean)./coefficientScale;
layers=[featureInputLayer(size(X,2),Normalization="none")
    fullyConnectedLayer(config.hiddenWidth)
    tanhLayer
    fullyConnectedLayer(config.rank)];
options=trainingOptions("adam",MaxEpochs=config.maxEpochs, ...
    MiniBatchSize=config.miniBatchSize,InitialLearnRate=config.learningRate, ...
    Shuffle="every-epoch",OutputNetwork="last-iteration", ...
    ExecutionEnvironment="cpu",Verbose=false);
net=trainnet(X,Y,layers,"mse",options);
state=struct('network',net,'basis',basis,'fieldMean',fieldMean, ...
    'inputMean',inputMean,'inputScale',inputScale, ...
    'coefficientMean',coefficientMean,'coefficientScale',coefficientScale, ...
    'constantCoefficients',constantCoefficients,'settings',config);
report=struct('method',"pod_mlp",'trainingCount',size(X,1), ...
    'numericalRank',numericalRank,'podRank',config.rank, ...
    'retainedEnergy',sum(singularValues(1:config.rank).^2)/sum(singularValues.^2), ...
    'optimizer',"adam",'settings',config);
end
