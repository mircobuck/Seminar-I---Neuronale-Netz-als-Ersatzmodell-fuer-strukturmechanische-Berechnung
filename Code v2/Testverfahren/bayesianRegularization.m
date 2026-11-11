function net = bayesianRegularization(XTrain, YTrain, layers, settings)
%bayesianRegularization Train an MLP with Bayesian regularization (trainbr).

rng(settings.randomSeed);
hasHiddenLayer = numel(layers) > 2;
inputCount = size(XTrain, 2);
outputCount = size(YTrain, 2);
if hasHiddenLayer
    hiddenWidth = layers(2).OutputSize;
    parameterCount = hiddenWidth * (inputCount + outputCount + 1) + outputCount;
else
    parameterCount = inputCount * outputCount + outputCount;
end
hessianBytes = 8 * parameterCount^2;
jacobianBytes = 8 * size(XTrain, 1) * outputCount * parameterCount;
estimatedMemoryBytes = hessianBytes + jacobianBytes;
availableMemory = memory;

if estimatedMemoryBytes > availableMemory.MemAvailableAllArrays / 2
    error('bayesianRegularization:MemoryLimit', ...
        ['Estimated Bayesian regularization workspace requires %.1f GB, ', ...
         'which is too large for the currently available memory. Use Adam ', ...
         'or reduce the output size.'], estimatedMemoryBytes / 1024^3);
end

if hasHiddenLayer
    net = feedforwardnet(hiddenWidth, "trainbr");
    net.layers{1}.transferFcn = "tansig";
    net.layers{2}.transferFcn = "purelin";
else
    net = feedforwardnet([], "trainbr");
    net.layers{1}.transferFcn = "purelin";
end
net = configure(net, XTrain', YTrain');
net.inputs{1}.processFcns = {};
net.outputs{net.numLayers}.processFcns = {};
net.divideFcn = "dividetrain";
net.trainParam.epochs = settings.maxEpochs;
net.trainParam.showWindow = false;

net = train(net, XTrain', YTrain');
end