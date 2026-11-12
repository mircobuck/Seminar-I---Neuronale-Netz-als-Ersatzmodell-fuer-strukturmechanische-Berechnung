function [state,report] = fit(data,config)
%fit Train a tanh MLP through the common contract.
%   hiddenLayers defaults to 1; each tanh layer has hiddenWidth neurons.
%   Requires seed; optional hiddenWidth (64), optimizer ("adam"),
%   maxEpochs (200), miniBatchSize (32), learningRate (1e-3), momentum (0.9).
[state,report]=surrogate.models.shared.fitNeural("mlp",data,config);
end
