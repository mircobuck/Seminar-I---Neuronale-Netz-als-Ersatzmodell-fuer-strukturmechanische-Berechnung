function result=predictBeamField(model,X)
%PREDICTBEAMFIELD Return raw and clamp-enforced displacement fields.
total=tic; t=tic; B=femstudy.fem.beamField(X,model.xi); physics=toc(t);
t=tic; A=predict_reg(model.reg,X); regression=toc(t);
t=tic; raw=B+model.pod.mean+model.pod.V*A';
field=raw; n=size(model.xi,2); fixed=find(model.xi(1,:)==0);
field([fixed fixed+n fixed+2*n],:)=0; reconstruction=toc(t);
result=struct('rawField',raw,'field',field,'beamField',B, ...
    'timing',struct('physics',physics,'transfer',0,'regression',regression, ...
    'reconstruction',reconstruction,'online',toc(total)));
end
