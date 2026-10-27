function [w,residual] = predictPINN(model,x)
%PREDICTPINN Evaluate the hard-boundary 1-D PINN and its ODE residual.
arguments
    model (1,1) struct
    x double {mustBeReal,mustBeFinite}
end
L=model.parameters(1); E=model.parameters(2); b=model.parameters(3); h=model.parameters(4);
EI=E*b*h^3/12; F=1; width=model.width;
w=pinnValueLocal(model.theta,x,L,width);
dx=max(L*1e-3,1e-6); f=@(z)pinnValueLocal(model.theta,z,L,width);
residual=(f(x+4*dx)-4*f(x+3*dx)+6*f(x+2*dx)-4*f(x+dx)+f(x))/dx^4*EI;
residual=residual(:);
if any(abs(x-L)<10*eps(L)), residual(abs(x-L)<10*eps(L))=residual(abs(x-L)<10*eps(L))+F; end
end

function w=pinnValueLocal(theta,x,L,width)
W=reshape(theta(1:2*width),width,2); b=theta(2*width+1:3*width); c=theta(end);
z=tanh(W(:,1)*(x(:)'/L)+W(:,2)); y=(c+b'*z)'; w=x(:).^2.*y;
end
