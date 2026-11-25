function Y = predictNeural(state,X)
%predictNeural Apply training transforms and restore physical output units.
% normalize the input parameters and apply RBF features if needed
X=(double(X)-state.inputMean)./state.inputScale;
if state.method=="rbf"
    X=surrogate.models.shared.rbfFeatures(X,state.centers,state.settings.rbfWidth);
end
% some checks for the static trainnet workflow
assert(any(state.task==["static","modal"]) && state.backend=="trainnet", ...
    'surrogate:neural:Backend','This workflow requires a trainnet model.');
% netwrok pred    
Y=double(minibatchpredict(state.network,X,ExecutionEnvironment="cpu"));
% Constant targets (including clamped displacement DOFs) stay exact.
Y(:,state.constantOutputs)=0;
Y=Y.*state.outputScale+state.outputMean;
Y=Y';
end
