function field = predictDeepONet(model,X,xi)
%PREDICTDEEPONET Predict three displacement components on the query grid.
arguments
    model (1,1) struct
    X double
    xi double {mustBeReal,mustBeFinite}
end
field = predict_deeponet(model,X,xi);
assert(size(field,1)==3*size(xi,2));
end
