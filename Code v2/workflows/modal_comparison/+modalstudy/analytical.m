function [F,families] = analytical(X)
%analytical Six lowest Euler-Bernoulli bending frequencies, not full 3D modes.
beta=[1.875104068711961,4.694091132974175,7.854757438237613, ...
    10.99554073487547,14.13716839104647,17.27875953208824];
L=X(:,1); b=X(:,2); h=X(:,3); E=X(:,4); rho=X(:,6); A=b.*h;
fy=(beta.^2./(2*pi*L.^2)).*sqrt(E.*(h.*b.^3/12)./(rho.*A));
fz=(beta.^2./(2*pi*L.^2)).*sqrt(E.*(b.*h.^3/12)./(rho.*A));
[allF,order]=sort([fy,fz],2);
names=["y"+string(1:6),"z"+string(1:6)];
F=allF(:,1:6); families=names(order(:,1:6));
end
