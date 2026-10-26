function U=beamField(X,xi)
%BEAMFIELD Euler-Bernoulli cantilever field, SI units and component blocks.
% Neutral axis is y=0, z=h/2. Transverse shear and Poisson contraction
% are omitted; uy=0 is a model assumption, not an exact prediction.
assert(size(X,2)==6 && size(xi,1)==3);
n=size(xi,2); U=zeros(3*n,size(X,1));
for i=1:size(X,1)
    L=X(i,1); b=X(i,2); h=X(i,3); E=X(i,4); F=X(i,6);
    assert(L>0 && b>0 && h>0 && E>0);
    x=L*xi(1,:)'; z=h*(xi(3,:)'-0.5); I=b*h^3/12;
    w=F*x.^2.*(3*L-x)/(6*E*I);
    slope=F*x.*(2*L-x)/(2*E*I);
    U(:,i)=[-z.*slope;zeros(n,1);w];
end
end
