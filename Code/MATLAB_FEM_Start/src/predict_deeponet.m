function H = predict_deeponet(model,X,xi)
%predict_deeponet - Predict displacement in metres at reference coordinates.
%   H = predict_deeponet(model,X,xi) returns 3Q-by-N fields, component
%   blocks ux, uy, uz. X columns are L, b, h, E, nu, Fz in SI units.
%   See also deeponet_forward, fit_deeponet
Z = ((X-model.meanX)./model.stdX)';
H = double(extractdata(deeponet_forward(model.branch,model.trunk, ...
    Z,xi,model.options.latent))) * model.scaleU;
end
