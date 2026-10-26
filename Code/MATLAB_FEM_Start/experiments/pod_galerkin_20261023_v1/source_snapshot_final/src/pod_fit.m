function P=pod_fit(S,w,r)
P.mean=mean(S,2); P.w=w(:); Z=S-P.mean;
[Q,D,~]=svd(sqrt(P.w).*Z,'econ');
s=diag(D); tol=max(size(Z))*eps(max(s));
r=min(r,nnz(s>tol)); assert(r>=1,'Snapshots have no varying component.');
P.V=Q(:,1:r)./sqrt(P.w); P.r=r;
P.energy=cumsum(s.^2)/sum(s.^2);
end
