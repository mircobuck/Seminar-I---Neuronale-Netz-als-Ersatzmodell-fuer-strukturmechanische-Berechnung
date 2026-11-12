function Y = predict(state,X)
%predict Add a deterministic input-dependent term to test case ordering.
if state.task=="static"
    Y=repmat(state.constant,1,size(X,1))+repmat(X(:,1)'*1e-6,1575,1);
else
    Y=repmat(state.constant,size(X,1),1)+repmat(X(:,1),1,6);
end
end
