function Y = predictNeural(state,X)
%predictNeural Apply training transforms and restore physical output units.
X=(double(X)-state.inputMean)./state.inputScale;
if state.method=="rbf"
    X=surrogate.models.shared.rbfFeatures(X,state.centers,state.settings.rbfWidth);
end
assert(state.task=="static" && state.backend=="trainnet", ...
    'surrogate:neural:Backend','This static workflow requires a trainnet model.');
Y=double(minibatchpredict(state.network,X,ExecutionEnvironment="cpu"));
% Constant targets (including clamped displacement DOFs) stay exact.
Y(:,state.constantOutputs)=0;
Y=Y.*state.outputScale+state.outputMean;
Y=Y';
end
