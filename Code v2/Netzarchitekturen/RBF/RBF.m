%% Simple RBF network for FEM data
% Choose the prediction task and training procedure, then run this script.
% The centers and widths of the radial basis functions stay fixed.

clear;
clc;

%% Settings to change

task = "static"; % Use "static" for displacement fields or "modal" for frequencies.
centerCount = 64;
rbfWidth = 1.0;
maxEpochs = 200;
miniBatchSize = 32;
learningRate = 1e-3;
momentum = 0.9;
randomSeed = 42;
testverfahren = "adam"; % "adam", "sgd-momentum", "levenberg-marquardt", or "bayesian-regularization".

%% Load training and validation data

scriptFolder = fileparts(mfilename('fullpath'));
projectFolder = fileparts(fileparts(scriptFolder));
addpath(projectFolder);
addpath(fullfile(projectFolder, "Testverfahren"));

dataFolder = fullfile(projectFolder, "data_generation", "data", task);
trainData = loadFemDataset(fullfile(dataFolder, "train.mat"));
validationData = loadFemDataset(fullfile(dataFolder, "val.mat"));

XTrain = double(trainData.inputParameters);
XValidation = double(validationData.inputParameters);

if task == "static"
    YTrain = double(trainData.displacementFields');
    YValidation = double(validationData.displacementFields');
elseif task == "modal"
    YTrain = double(trainData.naturalFrequenciesHz);
    YValidation = double(validationData.naturalFrequenciesHz);
else
    error('Choose task as "static" or "modal".');
end

%% Normalize using training data only

inputMean = mean(XTrain, 1);
inputScale = std(XTrain, 0, 1);
inputScale(inputScale == 0) = 1;
XTrainNormalized = (XTrain - inputMean) ./ inputScale;
XValidationNormalized = (XValidation - inputMean) ./ inputScale;

outputMean = mean(YTrain, 1);
outputScale = std(YTrain, 0, 1);
outputScale(outputScale == 0) = 1;
YTrainNormalized = (YTrain - outputMean) ./ outputScale;
YValidationNormalized = (YValidation - outputMean) ./ outputScale;

%% Build the RBF hidden layer from evenly spaced training cases

if rbfWidth <= 0
    error('RBF width must be greater than zero.');
end

centerCount = min(centerCount, size(XTrainNormalized, 1));
centerIndices = round(linspace(1, size(XTrainNormalized, 1), centerCount));
centers = XTrainNormalized(centerIndices, :);

RBFTrain = makeRBFfeatures(XTrainNormalized, centers, rbfWidth);
RBFValidation = makeRBFfeatures(XValidationNormalized, centers, rbfWidth);

%% Train only the linear output layer

layers = [
    featureInputLayer(centerCount, Normalization="none")
    fullyConnectedLayer(size(YTrainNormalized, 2))
];

settings = struct( ...
    "maxEpochs", maxEpochs, ...
    "miniBatchSize", miniBatchSize, ...
    "learningRate", learningRate, ...
    "momentum", momentum, ...
    "randomSeed", randomSeed);

switch testverfahren
    case "adam"
        net = adam(RBFTrain, YTrainNormalized, layers, ...
            RBFValidation, YValidationNormalized, settings);
        predictedNormalized = minibatchpredict(net, RBFValidation, ...
            ExecutionEnvironment="cpu");
    case "sgd-momentum"
        net = sgdMomentum(RBFTrain, YTrainNormalized, layers, ...
            RBFValidation, YValidationNormalized, settings);
        predictedNormalized = minibatchpredict(net, RBFValidation, ...
            ExecutionEnvironment="cpu");
    case "levenberg-marquardt"
        net = levenbergMarquardt(RBFTrain, YTrainNormalized, layers, ...
            RBFValidation, YValidationNormalized, settings);
        predictedNormalized = net(RBFValidation')';
    case "bayesian-regularization"
        net = bayesianRegularization(RBFTrain, YTrainNormalized, layers, settings);
        predictedNormalized = net(RBFValidation')';
    otherwise
        error('Unknown test procedure: %s', testverfahren);
end

predictedValues = double(predictedNormalized) .* outputScale + outputMean;

if task == "static"
    relativeError = vecnorm(predictedValues - YValidation, 2, 2) ./ ...
        max(vecnorm(YValidation, 2, 2), eps);
    fprintf("Task: static RBF displacement fields\n");
    fprintf("Validation field error, median: %.2f %%\n", median(relativeError) * 100);
    fprintf("Validation field error, mean:   %.2f %%\n", mean(relativeError) * 100);
else
    relativeError = abs(predictedValues - YValidation) ./ max(abs(YValidation), eps);
    fprintf("Task: modal RBF natural frequencies\n");
    fprintf("Validation frequency error, mean: %.2f %%\n", mean(relativeError, "all") * 100);
end

fprintf("RBF centers: %d\n", centerCount);
fprintf("RBF width: %.2f\n", rbfWidth);
fprintf("Training cases: %d\n", size(XTrain, 1));
fprintf("Validation cases: %d\n", size(XValidation, 1));

function features = makeRBFfeatures(inputs, centers, width)
features = zeros(size(inputs, 1), size(centers, 1));
for centerIndex = 1:size(centers, 1)
    difference = inputs - centers(centerIndex, :);
    squaredDistance = sum(difference.^2, 2);
    features(:, centerIndex) = exp(-squaredDistance / (2 * width^2));
end
end