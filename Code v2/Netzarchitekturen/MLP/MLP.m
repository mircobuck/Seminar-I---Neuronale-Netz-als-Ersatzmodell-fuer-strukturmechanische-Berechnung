%% Direct MLP through the surrogate architecture
% Training uses train.mat only; validation is evaluated after training.
task = "static";
config = struct('seed',42,'hiddenWidth',64,'maxEpochs',200, ...
    'miniBatchSize',32,'learningRate',1e-3,'momentum',0.9, ...
    'optimizer',"adam");
projectFolder = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectFolder,fullfile(projectFolder,'examples'));
[model,report,metrics] = runDirectNeuralExample("mlp",task,config);
disp(report);
disp(metrics);
