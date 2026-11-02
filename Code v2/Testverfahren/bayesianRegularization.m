function net = bayesianRegularization(XTrain, YTrain, layers, settings)
%bayesianRegularization Train an MLP with Bayesian regularization (trainbr).

rng(settings.randomSeed);
hiddenWidth = layers(2).OutputSize;
inputCount = size(XTrain, 2);
outputCount = size(YTrain, 2);
parameterCount = hiddenWidth * (inputCount + outputCount + 1) + outputCount;
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

net = feedforwardnet(hiddenWidth, "trainbr");
net.layers{1}.transferFcn = "tansig";
net.layers{2}.transferFcn = "purelin";
net = configure(net, XTrain', YTrain');
net.inputs{1}.processFcns = {};
net.outputs{net.numLayers}.processFcns = {};
net.divideFcn = "dividetrain";
net.trainParam.epochs = settings.maxEpochs;
net.trainParam.showWindow = false;

net = train(net, XTrain', YTrain');
end