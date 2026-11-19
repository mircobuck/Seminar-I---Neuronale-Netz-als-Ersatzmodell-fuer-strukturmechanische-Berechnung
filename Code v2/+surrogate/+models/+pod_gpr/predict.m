function Y = predict(state,X)
%predict Reconstruct displacement fields in metres in request order.
X=(double(X(:,state.activeInputs))-state.inputMean(state.activeInputs))./state.inputScale(state.activeInputs);
coeff=repmat(state.coefficientMean,size(X,1),1);
for j=1:numel(state.models)
    if ~state.constantCoefficients(j)
        coeff(:,j)=predict(state.models{j},X).*state.coefficientScale(j)+state.coefficientMean(j);
    end
end
Y=state.fieldMean+state.basis*coeff';
end
