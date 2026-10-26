function model=fitBeamField(train,val)
%FITBEAMFIELD Train only on correction fields; validation selects POD rank.
assert(isempty(intersect(train.id,val.id)),'femstudy:split:Leakage','Split overlap.');
assert(isequal(train.xi,val.xi) && isequal(train.w,val.w));
B=femstudy.fem.beamField(train.X,train.xi); D=train.S-B;
BV=femstudy.fem.beamField(val.X,val.xi);
ranks=unique(min([1 2 4 8 12],size(train.X,1)-1));
scores=inf(size(ranks)); candidates=cell(size(ranks)); started=tic;
for k=1:numel(ranks)
    P=pod_fit(D,train.w,ranks(k)); A=pod_encode(P,D);
    reg=fit_gps(train.X,A);
    H=BV+P.mean+P.V*predict_reg(reg,val.X)';
    scores(k)=mean(field_error(val.S,H,train.w));
    candidates{k}=struct('pod',P,'reg',reg);
end
[~,ix]=min(scores); chosen=candidates{ix};
model=struct('schema',"beam-field-pod-gpr-v1",'physics',"euler-bernoulli-v1", ...
    'pod',chosen.pod,'reg',chosen.reg,'xi',train.xi,'weights',train.w, ...
    'trainIDs',train.id,'validationIDs',val.id,'ranks',ranks, ...
    'validationScores',scores,'selectedRank',chosen.pod.r,'kernel',"ardmatern52", ...
    'seed',42,'trainingSeconds',toc(started));
end
