function model=fitBeamField(train,val,options)
%FITBEAMFIELD Train on correction fields; validation selects rank and kernel.
assert(isempty(intersect(train.id,val.id)),'femstudy:split:Leakage','Split overlap.');
assert(isequal(train.xi,val.xi) && isequal(train.w,val.w));
if nargin<3
    options=struct('ranks',[1 2 4 8 12],'kernels',"ardmatern52");
end
assert(isfield(options,'ranks') && isfield(options,'kernels'), ...
    'femstudy:beamField:Options','Options must define ranks and kernels.');
ranks=unique(options.ranks(:)');
kernels=string(options.kernels(:)');
assert(~isempty(ranks) && all(isfinite(ranks)) && all(ranks>=1) && ...
    all(ranks==floor(ranks)),'femstudy:beamField:Ranks','Invalid POD ranks.');
assert(~isempty(kernels) && all(ismember(kernels, ...
    ["ardmatern52","ardsquaredexponential"])), ...
    'femstudy:beamField:Kernels','Unsupported GPR kernel candidate.');
ranks=min(ranks,size(train.X,1)-1);
B=femstudy.fem.beamField(train.X,train.xi); D=train.S-B;
BV=femstudy.fem.beamField(val.X,val.xi);
ranks=unique(ranks);
scores=inf(numel(ranks),numel(kernels));
candidates=cell(size(scores)); started=tic; best=Inf; winner=[];
for k=1:numel(ranks)
    P=pod_fit(D,train.w,ranks(k)); A=pod_encode(P,D);
    for j=1:numel(kernels)
        reg=fit_gps(train.X,A,kernels(j));
        H=BV+P.mean+P.V*predict_reg(reg,val.X)';
        score=mean(field_error(val.S,H,train.w));
        scores(k,j)=score;
        candidates{k,j}=struct('pod',P,'reg',reg);
        if score<best
            best=score; winner=[k j];
        end
    end
end
[rankIndex,kernelIndex]=deal(winner(1),winner(2));
chosen=candidates{rankIndex,kernelIndex};
model=struct('schema',"beam-field-pod-gpr-v1",'physics',"euler-bernoulli-v1", ...
    'pod',chosen.pod,'reg',chosen.reg,'xi',train.xi,'weights',train.w, ...
    'trainIDs',train.id,'validationIDs',val.id,'ranks',ranks, ...
    'kernels',kernels,'validationScores',scores, ...
    'selectedRank',chosen.pod.r,'kernel',kernels(kernelIndex), ...
    'validationError',best, ...
    'seed',42,'trainingSeconds',toc(started));
end
