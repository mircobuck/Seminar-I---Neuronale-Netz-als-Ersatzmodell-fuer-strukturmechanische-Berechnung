function net = levenbergMarquardt(XTrain, YTrain, layers, XValidation, YValidation, settings)
%levenbergMarquardt Train the same one-hidden-layer MLP with trainlm.

rng(settings.randomSeed);
hiddenWidth = layers(2).OutputSize;
inputCount = size(XTrain, 2);
outputCount = size(YTrain, 2);
parameterCount = hiddenWidth * (inputCount + outputCount + 1) + outputCount;
estimatedHessianBytes = 8 * parameterCount^2;
availableMemory = memory;

if estimatedHessianBytes > availableMemory.MemAvailableAllArrays / 2
    error('levenbergMarquardt:MemoryLimit', ...
        ['Estimated LM Hessian requires %.1f GB, which is too large for the ', ...
         'currently available memory. Use Adam or reduce the output size.'], ...
        estimatedHessianBytes / 1024^3);
end

XAll = [XTrain; XValidation]';
YAll = [YTrain; YValidation]';
trainCount = size(XTrain, 1);

net = feedforwardnet(hiddenWidth, "trainlm");
net.layers{1}.transferFcn = "tansig";
net.layers{2}.transferFcn = "purelin";
net = configure(net, XAll, YAll);
net.inputs{1}.processFcns = {};
net.outputs{net.numLayers}.processFcns = {};
net.divideFcn = "divideind";
net.divideParam.trainInd = 1:trainCount;
net.divideParam.valInd = trainCount + (1:size(XValidation, 1));
net.divideParam.testInd = [];
net.trainParam.epochs = settings.maxEpochs;
net.trainParam.max_fail = 20;
net.trainParam.showWindow = false;

net = train(net, XAll, YAll);
end