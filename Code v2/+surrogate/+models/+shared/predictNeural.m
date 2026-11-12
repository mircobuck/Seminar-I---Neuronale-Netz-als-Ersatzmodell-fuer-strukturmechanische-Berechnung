function Y = predictNeural(state,X)
%predictNeural Apply training transforms and restore physical output units.
X=(double(X)-state.inputMean)./state.inputScale;
if state.method=="rbf"
    X=surrogate.models.shared.rbfFeatures(X,state.centers,state.settings.rbfWidth);
end
if state.backend=="trainnet"
    Y=double(minibatchpredict(state.network,X,ExecutionEnvironment="cpu"));
else
    Y=state.network(X')';
end
% Constant targets (including clamped displacement DOFs) stay exact.
Y(:,state.constantOutputs)=0;
Y=Y.*state.outputScale+state.outputMean;
if state.task=="static", Y=Y'; end
end
