function model = fitPINN(parameters,options)
%FITPINN Fit a small 1-D Euler--Bernoulli PINN prototype.
% The hard factor x^2 enforces w(0)=w'(0)=0. This is intentionally a
% one-dimensional physics demonstration, not a 3-D FEM field surrogate.
arguments
    parameters (1,4) double {mustBeFinite,mustBePositive}
    options.width (1,1) double {mustBeInteger,mustBePositive} = 4
    options.collocationCount (1,1) double {mustBeInteger,mustBePositive} = 24
    options.maxIterations (1,1) double {mustBeInteger,mustBePositive} = 100
    options.seed (1,1) double {mustBeInteger} = 42
end
L=parameters(1); E=parameters(2); b=parameters(3); h=parameters(4);
EI=E*b*h^3/12; F=1;
rng(options.seed,"twister"); width=options.width;
x=linspace(0,L,options.collocationCount)';
theta0=0.1*randn(3*width+1,1);
objective=@(theta)pinnLoss(theta,x,L,EI,F,width);
settings=optimset('Display','off','MaxIter',options.maxIterations, ...
    'MaxFunEvals',20*options.maxIterations);
theta=fminsearch(objective,theta0,settings);
model=struct('schema',"pinn-1d-v1",'parameters',parameters, ...
    'width',width,'theta',theta,'collocationX',x, ...
    'loss',objective(theta),'boundary',"hard clamped at x=0", ...
    'equation',"EI*w''''=0",'loadBoundary',"EI*w'''(L)=-F");
end

function loss=pinnLoss(theta,x,L,EI,F,width)
epsx=max(L*1e-3,1e-6);
f=@(z)pinnValue(theta,z,L,width);
w0=f(x); w1=f(x+epsx); w2=f(x+2*epsx); w3=f(x+3*epsx); w4=f(x+4*epsx);
fourth=(w4-4*w3+6*w2-4*w1+w0)/epsx^4;
wm=f(L); wp=f(L-epsx); wpp=f(L-2*epsx); wppp=f(L-3*epsx);
second=(wm-2*wp+wpp)/epsx^2;
third=(wm-3*wp+3*wpp-wppp)/epsx^3;
loss=mean((EI*fourth).^2)+10*(EI*second).^2+10*(EI*third+F).^2;
end

function w=pinnValue(theta,x,L,width)
W=reshape(theta(1:2*width),width,2); b=theta(2*width+1:3*width); c=theta(end);
z=tanh(W(:,1)*(x(:)'/L)+W(:,2));
y=(c+ b'*z)';
w=(x(:).^2).*y;
end
