function M=fit_gps(X,Y,kernel)
if nargin<3, kernel="ardmatern52"; end
M.kind="gp"; M.xm=mean(X,1); M.xs=std(X,0,1); M.xs(M.xs==0)=1;
Z=(X-M.xm)./M.xs;
M.ym=mean(Y,1); M.ys=std(Y,0,1);
M.fixed=M.ys<=1e-12*max(max(abs(Y),[],1),realmin);
M.ys(M.fixed)=1; M.net=cell(1,size(Y,2));
for j=1:size(Y,2)
    if M.fixed(j), continue; end
    t=(Y(:,j)-M.ym(j))/M.ys(j);
    M.net{j}=fitrgp(Z,t,KernelFunction=kernel, ...
        Standardize=false,Sigma=1e-4,SigmaLowerBound=1e-8,ConstantSigma=true);
end
end
