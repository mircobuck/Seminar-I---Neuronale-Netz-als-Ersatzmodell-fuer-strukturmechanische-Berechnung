function [loss,gB,gT] = deeponet_gradients(branch,trunk,Z,xi,p,Y,w)
%deeponet_gradients - Differentiate the equally case-weighted relative loss.
H = deeponet_forward(branch,trunk,Z,xi,p);
loss = mean(sum(single(w).*(H-single(Y)).^2,1) ./ ...
    sum(single(w).*single(Y).^2,1));
[gB,gT] = dlgradient(loss,branch.Learnables,trunk.Learnables);
end
