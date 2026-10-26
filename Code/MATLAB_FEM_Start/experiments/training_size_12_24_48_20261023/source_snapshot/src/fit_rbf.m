function M=fit_rbf(X,A,lambda)
M.kind="rbf"; M.xm=mean(X,1); M.xs=std(X,0,1); M.xs(M.xs==0)=1;
M.X=(X-M.xm)./M.xs; n=size(X,1); P=[ones(n,1),M.X];
assert(rank(P)==size(P,2),'RBF input parameters must be independent.');
D=sqrt(max(0,sum(M.X.^2,2)+sum(M.X.^2,2)'-2*M.X*M.X'));
C=[D.^3+lambda*eye(n),P;P',zeros(size(P,2))];
assert(rcond(C)>1e-14,'Ill-conditioned RBF system; increase lambda.');
M.coef=C\[A;zeros(size(P,2),size(A,2))]; M.lambda=lambda;
end
