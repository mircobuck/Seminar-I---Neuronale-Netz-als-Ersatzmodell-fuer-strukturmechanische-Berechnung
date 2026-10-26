function out=predict_surrogate(M,X)
% Input X columns L,b,h,E,nu,Fz. Output schema depends on M.type.
switch M.type
    case "scalar", out=predict_reg(M.reg,X);
    case "correction", out=beam_tip(X)+predict_reg(M.reg,X);
    case "field", out=M.pod.mean+M.pod.V*predict_reg(M.reg,X)';
    otherwise, error('Unknown surrogate type.');
end
end
