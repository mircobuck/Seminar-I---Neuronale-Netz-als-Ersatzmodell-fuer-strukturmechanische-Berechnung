function H=predictNeural(model,X)
%PREDICTNEURAL Return metres in component blocks, or unsorted Hz by row.
A=predict_reg(model.reg,X);
if model.kind=="frequency"
    H=exp(A); assert(all(isfinite(H) & H>0,'all')); return
end
H=model.pod.mean+model.pod.V*A';
if model.kind=="residual", H=H+femstudy.fem.beamField(X,model.xi); end
end
