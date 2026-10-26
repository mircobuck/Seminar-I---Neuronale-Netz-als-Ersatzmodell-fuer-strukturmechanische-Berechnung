function H = deeponet_forward(branch,trunk,Z,xi,p)
%deeponet_forward - Combine shared trunk features and three branch blocks.
%   H = deeponet_forward(branch,trunk,Z,xi,p) returns [ux;uy;uz]
%   in normalized displacement units, with one column per physical case.
%   Z is 6-by-N, xi is 3-by-Q. Each network runs once per batch.
%   See also predict_deeponet, fit_deeponet
B = stripdims(forward(branch,dlarray(single(Z),'CB')));
T = stripdims(forward(trunk,dlarray(single(2*xi-1),'CB')));
parts = cell(3,1);
for c = 1:3
    parts{c} = T' * B((c-1)*p+(1:p),:);
end
H = cat(1,parts{:}) .* single(repmat(xi(1,:)',3,1));
end
