function model=fitNeural(train,val,kind,options)
%FITNEURAL Validation-selected POD, residual-POD or log-frequency MLP.
assert(isempty(intersect(train.id,val.id)), 'femstudy:split:Leakage','Split overlap.');
assert(size(train.X,2)==6 && all(isfinite(train.X),'all'));
started=tic; scores=[]; choices=[]; best=Inf; model=[];
frequency=strcmp(kind,'frequency'); residual=strcmp(kind,'residual');
if frequency
    assert(all(train.F>0,'all') && all(val.F>0,'all'));
    assert(std(train.X(:,6))>0,'femstudy:density:Constant','Density must vary.');
    ranks=0; S=log(train.F); V=log(val.F);
else
    assert(isequal(train.xi,val.xi) && isequal(train.w,val.w));
    ranks=unique(min(options.ranks(:)',size(train.X,1)-1));
    S=train.S; V=val.S;
    if residual
        S=S-femstudy.fem.beamField(train.X,train.xi);
        V=V-femstudy.fem.beamField(val.X,val.xi);
    end
end
for rank=ranks
    if frequency
        P=[]; A=S; Av=V;
    else
        P=pod_fit(S,train.w,rank); A=pod_encode(P,S); Av=pod_encode(P,V);
    end
    for width=options.widths(:)'
        reg=fit_mlp(train.X,A,val.X,Av,width,options);
        candidate=struct('schema',"neural-v1",'kind',string(kind),'reg',reg, ...
            'pod',P,'seed',options.modelSeed,'trainIDs',train.id,'validationIDs',val.id);
        if ~frequency, candidate.xi=train.xi; end
        H=femstudy.models.predictNeural(candidate,val.X);
        if frequency
            score=mean(abs(H-val.F)./val.F,'all');
        else
            score=mean(field_error(val.S,H,train.w));
        end
        scores(end+1,1)=score; choices(end+1,:)=[rank width]; %#ok<AGROW>
        if score<best, model=candidate; best=score; end
    end
end
assert(~isempty(model) && isfinite(best));
model.selection=array2table([choices scores],VariableNames={'Rank','Width','ValidationError'});
model.validationError=best; model.trainingSeconds=toc(started);
end
