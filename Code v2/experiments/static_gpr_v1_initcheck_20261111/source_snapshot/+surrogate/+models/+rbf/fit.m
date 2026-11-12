function [state,report] = fit(data,config)
%fit Train an output network on fixed Gaussian RBF features.
%   hiddenLayers counts the fixed Gaussian layer plus hiddenLayers-1 tanh
%   layers of hiddenWidth neurons. Default 1 is the original linear RBF.
%   Requires seed; optional centerCount (64), rbfWidth (1), optimizer
%   ("adam"), maxEpochs (200), miniBatchSize (32), learningRate (1e-3).
%   Centers are evenly spaced training rows, as in Mirco's original RBF.
[state,report]=surrogate.models.shared.fitNeural("rbf",data,config);
end
