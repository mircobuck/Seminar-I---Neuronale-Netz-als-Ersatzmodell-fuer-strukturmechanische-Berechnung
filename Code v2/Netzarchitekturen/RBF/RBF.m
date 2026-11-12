%% Fixed-center Gaussian RBF through the surrogate architecture
% Training uses train.mat only; validation is evaluated after training.
task = "static";
config = struct('seed',42,'centerCount',64,'rbfWidth',1,'maxEpochs',200, ...
    'miniBatchSize',32,'learningRate',1e-3,'momentum',0.9, ...
    'optimizer',"adam");
projectFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectFolder,fullfile(projectFolder,'examples'));
[model,report,metrics] = runDirectNeuralExample("rbf",task,config);
disp(report);
disp(metrics);
