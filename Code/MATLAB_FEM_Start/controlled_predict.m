function [U,timing]=controlled_predict(r,X,xi)
%CONTROLLED_PREDICT Online-only adapter for the controlled static fits.
narginchk(3,3); total=tic;
if ~isstruct(r) || ~all(isfield(r,{'status','kind','pod','reg','normalized'})) || r.status~="success" || ~ismember(r.kind,[1 2])
    error('controlled:schema','Invalid saved model schema.');
end
if ~isnumeric(X) || size(X,2)~=6 || any(~isfinite(X),'all') || any(X(:,1:4)<=0,'all') || any(X(:,6)>=0)
    error('controlled:parameters','Expected finite SI parameters with positive dimensions and E, and negative nonzero F.');
end
[expected,~]=reference_grid([21 5 5]);
if ~isequal(size(xi),size(expected)) || any(abs(xi-expected)>1e-12,'all') || size(r.pod.V,1)~=3*size(expected,2)
    error('controlled:space','Unsupported reference space or coordinate ordering.');
end
t=tic; B=zeros(3*size(xi,2),size(X,1)); if r.kind==2,B=femstudy.fem.beamField(X,xi);end
timing.physics=toc(t); timing.transfer=0;
t=tic; coeff=predict_reg(r.reg,X); timing.regression=toc(t);
t=tic; U=r.pod.mean+r.pod.V*coeff'; timing.reconstruction=toc(t);
t=tic; if r.normalized,U=U.*((X(:,6)/(-500)).*(1e11./X(:,4)))';end
U=U+B; timing.postprocessing=toc(t); timing.total=toc(total);
end
