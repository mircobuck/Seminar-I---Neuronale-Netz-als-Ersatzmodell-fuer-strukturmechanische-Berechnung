function studyDesign(root,out,cfg)
% Fixed candidate order and reserve rows, without loading any labels.
prior=rng; cleanup=onCleanup(@()rng(prior)); rng(cfg.seed_design,'twister'); %#ok<NASGU>
lo=reshape(cfg.lower,1,[]); hi=reshape(cfg.upper,1,[]); span=hi-lo;
role=strings(0,1); group=zeros(0,1); reserve=false(0,1); X=zeros(0,6);
for split=["val","interpolation"]
    n=cfg.counts.(split); nReserve=ceil(n/4); N=n+nReserve; U=zeros(N,6);
    for j=1:6
        U(1:n,j)=(randperm(n)'-rand(n,1))/n;
        U(n+1:end,j)=(randperm(nReserve)'-rand(nReserve,1))/nReserve;
    end
    X=[X;lo+U.*span]; role=[role;repmat(split,N,1)]; group=[group;zeros(N,1)]; %#ok<AGROW>
    reserve=[reserve;false(n,1);true(nReserve,1)]; %#ok<AGROW>
end
for g=1:12
    n=floor(cfg.counts.extrapolation/12)+(g<=mod(cfg.counts.extrapolation,12)); N=n+4;
    U=zeros(N,6); for j=1:6, U(:,j)=(randperm(N)'-rand(N,1))/N; end
    A=lo+U.*span; q=ceil(g/2); delta=(.05+.05*rand(N,1))*span(q);
    if mod(g,2)==1, A(:,q)=lo(q)-delta; else, A(:,q)=hi(q)+delta; end
    X=[X;A]; role=[role;repmat("extrapolation",N,1)]; group=[group;repmat(g,N,1)]; %#ok<AGROW>
    reserve=[reserve;false(n,1);true(4,1)]; %#ok<AGROW>
end
assert(all(X(:,1:4)>0,'all') && all(X(:,5)>-1 & X(:,5)<.5) && all(X(:,6)<0), ...
    'study:Physical','Candidate design outside physical range.');
names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
ids=(cfg.id_start:cfg.id_start+size(X,1)-1)';
manifest=readtable(fullfile(root,'experiments','static_pod_gpr_20261111','design_manifest.csv'),'TextType','string','Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
for j=1:height(manifest)
    T=readtable(fullfile(root,manifest.file(j)));
    assert(~any(ismember(ids,T.id)),'study:IdOverlap','Candidate IDs overlap a historical design.');
    surrogate.study.assertDisjointParameters(X,T{:,names},lo,hi,cfg.duplicate_tolerance);
end
for pilotName=["static_gpr_v1_generation_pilot_20261111","static_gpr_v1_generation_pilot_v2_20261111"]
    pilotPath=fullfile(root,'experiments',pilotName,'candidate_design.csv');
    if isfile(pilotPath)
        T=readtable(pilotPath); assert(~any(ismember(ids,T.id)),'study:IdOverlap','Candidate IDs overlap pilot design.');
        surrogate.study.assertDisjointParameters(X,T{:,names},lo,hi,cfg.duplicate_tolerance);
    end
end
T=readtable(fullfile(root,'experiments','static_pod_gpr_20261111','fem_pilot','pilot_design.csv'));
surrogate.study.assertDisjointParameters(X,T{:,names},lo,hi,cfg.duplicate_tolerance);
for j=1:size(X,1)-1
    surrogate.study.assertDisjointParameters(X(j,:),X(j+1:end,:),lo,hi,cfg.duplicate_tolerance);
end
design=array2table([ids X],'VariableNames',[{'id'},names]);
design.role=role; design.group=group; design.reserve=reserve;
save(fullfile(out,'candidate_design.mat'),'design');
writetable(design,fullfile(out,'candidate_design.csv'));
end
