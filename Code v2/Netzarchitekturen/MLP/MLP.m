%% Simple MLP for FEM data
% Choose the prediction task here, then run this script.
% The model is trained on the training split and checked on validation data.
% Test data is intentionally not loaded.

clear;
clc;

%% Settings to change

task = "static"; % Use "static" for displacement fields or "modal" for frequencies.
hiddenWidth = 64;
maxEpochs = 200;
miniBatchSize = 32;
learningRate = 1e-3;
momentum = 0.9;
randomSeed = 42;
testverfahren = "adam"; % "adam", "sgd-momentum", "levenberg-marquardt", or "bayesian-regularization".

%% Load the existing training and validation data

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
    % Each column in the saved file is one displacement field.
    YTrain = double(trainData.displacementFields');
    YValidation = double(validationData.displacementFields');
elseif task == "modal"
    % Each row contains the six natural frequencies for one case.
    YTrain = double(trainData.naturalFrequenciesHz);
    YValidation = double(validationData.naturalFrequenciesHz);
else
    error('Choose task as "static" or "modal".');
end

%% Normalize inputs and targets using training data only

inputMean = mean(XTrain, 1);
inputScale = std(XTrain, 0, 1);
inputScale(inputScale == 0) = 1;

outputMean = mean(YTrain, 1);
outputScale = std(YTrain, 0, 1);
outputScale(outputScale == 0) = 1;

XTrainNormalized = (XTrain - inputMean) ./ inputScale;
XValidationNormalized = (XValidation - inputMean) ./ inputScale;
YTrainNormalized = (YTrain - outputMean) ./ outputScale;
YValidationNormalized = (YValidation - outputMean) ./ outputScale;

%% Define the MLP architecture

rng(randomSeed);

layers = [
    featureInputLayer(size(XTrain, 2), Normalization="none")
    fullyConnectedLayer(hiddenWidth)
    tanhLayer
    fullyConnectedLayer(size(YTrain, 2))
];

trainingSettings = struct( ...
    "maxEpochs", maxEpochs, ...
    "miniBatchSize", miniBatchSize, ...
    "learningRate", learningRate, ...
    "momentum", momentum, ...
    "randomSeed", randomSeed);

%% Train the same MLP with the selected test procedure

switch testverfahren
    case "adam"
        net = adam(XTrainNormalized, YTrainNormalized, layers, ...
            XValidationNormalized, YValidationNormalized, trainingSettings);
        predictedNormalized = minibatchpredict(net, XValidationNormalized, ...
            ExecutionEnvironment="cpu");
    case "sgd-momentum"
        net = sgdMomentum(XTrainNormalized, YTrainNormalized, layers, ...
            XValidationNormalized, YValidationNormalized, trainingSettings);
        predictedNormalized = minibatchpredict(net, XValidationNormalized, ...
            ExecutionEnvironment="cpu");
    case "levenberg-marquardt"
        net = levenbergMarquardt(XTrainNormalized, YTrainNormalized, layers, ...
            XValidationNormalized, YValidationNormalized, trainingSettings);
        predictedNormalized = net(XValidationNormalized')';
    case "bayesian-regularization"
        net = bayesianRegularization(XTrainNormalized, YTrainNormalized, ...
            layers, trainingSettings);
        predictedNormalized = net(XValidationNormalized')';
    otherwise
        error('Unknown test procedure: %s', testverfahren);
end

%% Check the trained network on validation cases

predictedValues = double(predictedNormalized) .* outputScale + outputMean;

if task == "static"
    relativeError = vecnorm(predictedValues - YValidation, 2, 2) ./ ...
        max(vecnorm(YValidation, 2, 2), eps);
    fprintf("Task: static displacement fields\n");
    fprintf("Validation field error, median: %.2f %%\n", median(relativeError) * 100);
    fprintf("Validation field error, mean:   %.2f %%\n", mean(relativeError) * 100);
else
    relativeError = abs(predictedValues - YValidation) ./ max(abs(YValidation), eps);
    fprintf("Task: modal natural frequencies\n");
    fprintf("Validation frequency error, mean: %.2f %%\n", mean(relativeError, "all") * 100);
end

fprintf("Training cases: %d\n", size(XTrain, 1));
fprintf("Validation cases: %d\n", size(XValidation, 1));
fprintf("Hidden units: %d\n", hiddenWidth);
