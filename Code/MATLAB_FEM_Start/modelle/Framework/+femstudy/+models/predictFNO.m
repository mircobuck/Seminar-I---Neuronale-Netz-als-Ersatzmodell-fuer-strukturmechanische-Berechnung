function field=predictFNO(model,X)
%PREDICTFNO Predict fields on the model's regular query grid.
q=size(model.xi,2); field=zeros(3*q,size(X,1));
for n=1:size(X,1)
    A=fourierFeaturesLocal(X(n,:),model.xi,model.modes,model.parameterMean,model.parameterStd);
    y=A*model.coef;
    field(:,n)=y(:);
end
end

function A=fourierFeaturesLocal(X,xi,modes,mu,sigma)
u=xi(1,:); v=xi(2,:); z=xi(3,:); Q=numel(u);
base=[ones(Q,1),[u;v;z]',repmat((X-mu)./sigma,Q,1),double(abs(u)<1e-12)']; terms=base;
for i=0:modes(1)-1
 for j=0:modes(2)-1
  for k=0:modes(3)-1
   if i+j+k>0
    phase=2*pi*(i*u+j*v+k*z)'; terms=[terms,cos(phase),sin(phase)]; %#ok<AGROW>
   end
  end
 end
end
A=terms;
end
