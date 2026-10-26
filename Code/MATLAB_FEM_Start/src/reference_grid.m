function [xi,w]=reference_grid(sz)
[a,b,c]=ndgrid(linspace(0,1,sz(1)),linspace(0,1,sz(2)), ...
    linspace(0,1,sz(3)));
xi=[a(:)';b(:)';c(:)'];
wa=ones(sz(1),1); wa([1 end])=0.5;
wb=ones(sz(2),1); wb([1 end])=0.5;
wc=ones(sz(3),1); wc([1 end])=0.5;
[A,B,C]=ndgrid(wa,wb,wc);
v=A(:).*B(:).*C(:); v=v/sum(v);
w=repmat(v,3,1); % reference-volume quadrature, ux;uy;uz
end
