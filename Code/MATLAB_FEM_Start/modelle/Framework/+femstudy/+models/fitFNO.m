function model = fitFNO(train,options)
%FITFNO Fit a compact regular-grid Fourier-feature operator prototype.
arguments
    train (1,1) struct
    options.modes (1,3) double {mustBeInteger,mustBePositive} = [6 2 2]
    options.lambda (1,1) double {mustBeNonnegative} = 1e-8
end
assert(isfield(train,'S') && isfield(train,'xi') && isfield(train,'X'));
mu=mean(train.X,1); sigma=max(std(train.X,0,1),1);
q=size(train.xi,2); A=[]; Y=cell(1,3);
for k=1:size(train.X,1)
    F=fourierFeatures(train.X(k,:),train.xi,options.modes,mu,sigma);
    A=[A;F];
    for c=1:3, Y{c}=[Y{c};train.S((c-1)*q+(1:q),k)]; end
end
G=A'*A+options.lambda*eye(size(A,2)); coef=zeros(size(A,2),3);
for c=1:3, coef(:,c)=G\(A'*Y{c}); end
model=struct('schema',"fno-prototype-v1",'xi',train.xi,'modes',options.modes, ...
    'coef',coef,'lambda',options.lambda,'parameterMean',mu,'parameterStd',sigma);
end

function A=fourierFeatures(X,xi,modes,mu,sigma)
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
