function createDesign(out,cfg)
    % Fixed candidate order and reserve rows, without loading any labels.
    prior=rng;
    cleanup=onCleanup(@()rng(prior));
    rng(cfg.seed_design,'twister');
    lo=reshape(cfg.lower,1,[]);
    hi=reshape(cfg.upper,1,[]);
    span=hi-lo;
    role=strings(0,1);
    group=zeros(0,1);
    reserve=false(0,1);
    X=zeros(0,6);
    for split=["val","interpolation"]
        n=cfg.counts.(split);
        nReserve=ceil(n/4);
        N=n+nReserve;
        U=zeros(N,6);
        for j=1:6
            U(1:n,j)=(randperm(n)'-rand(n,1))/n;
            U(n+1:end,j)=(randperm(nReserve)'-rand(nReserve,1))/nReserve;
        end
        X=[X;lo+U.*span]; %#ok<AGROW>
        role=[role;repmat(split,N,1)]; %#ok<AGROW>
        group=[group;zeros(N,1)]; %#ok<AGROW>
        reserve=[reserve;false(n,1);true(nReserve,1)]; %#ok<AGROW>
    end
    for g=1:12
        n=floor(cfg.counts.extrapolation/12)+(g<=mod(cfg.counts.extrapolation,12));
        N=n+4;
        U=zeros(N,6);
        for j=1:6
            U(:,j)=(randperm(N)'-rand(N,1))/N;
        end
        A=lo+U.*span;
        q=ceil(g/2);
        delta=(cfg.extrapolation_fraction(1)+diff(cfg.extrapolation_fraction)*rand(N,1))*span(q);
        if mod(g,2)==1
            A(:,q)=lo(q)-delta;
        else
            A(:,q)=hi(q)+delta;
        end
        X=[X;A]; %#ok<AGROW>
        role=[role;repmat("extrapolation",N,1)]; %#ok<AGROW>
        group=[group;repmat(g,N,1)]; %#ok<AGROW>
        reserve=[reserve;false(n,1);true(4,1)]; %#ok<AGROW>
    end
    assert(all(X(:,1:4)>0,'all') && all(X(:,5)>-1 & X(:,5)<.5) && all(X(:,6)<0),  'study:Physical', ...
        'Candidate design outside physical range.');
    names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
    ids=(cfg.id_start:cfg.id_start+size(X,1)-1)';
    for file=cfg.paths.exclusion_designs(:)'
        known=readtable(file);
        assert(~any(ismember(ids,known.id)),'study:IdOverlap','Generated case IDs overlap a known design.');
        surrogate.study.assertDisjointParameters(X,known{:,names},lo,hi,cfg.duplicate_tolerance);
    end
    for j=1:size(X,1)-1
        surrogate.study.assertDisjointParameters(X(j,:),X(j+1:end,:),lo,hi,cfg.duplicate_tolerance);
    end
    design=array2table([ids X],'VariableNames',[{'id'},names]);
    design.role=role;
    design.group=group;
    design.reserve=reserve;
    save(fullfile(out,'candidate_design.mat'),'design');
    writetable(design,fullfile(out,'candidate_design.csv'));
    writelines(string(staticstudy.hash(fullfile(out,'candidate_design.mat'))),fullfile(out,'candidate_design.sha256'));
end
