function Y = predict(state,X)
%predict Reconstruct static displacement fields in metres.
X=(double(X)-state.inputMean)./state.inputScale;
coefficients=double(minibatchpredict(state.network,X,ExecutionEnvironment="cpu"));
coefficients=coefficients.*state.coefficientScale+state.coefficientMean;
coefficients(:,state.constantCoefficients)=state.coefficientMean(state.constantCoefficients);
Y=state.fieldMean+state.basis*coefficients';
end
