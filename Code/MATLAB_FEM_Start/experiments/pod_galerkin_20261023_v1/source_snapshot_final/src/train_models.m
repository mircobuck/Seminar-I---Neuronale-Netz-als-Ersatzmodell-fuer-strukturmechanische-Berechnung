function train_models(c)
assert(exist('fitrgp','file')~=0,'Statistics and Machine Learning Toolbox required.');
f=fullfile(c.out,'models.mat');
assert(~isfile(f),'Models already frozen. Use a new run folder to retrain.');
a=load(fullfile(c.out,'train.mat'),'D'); tr=a.D;
a=load(fullfile(c.out,'val.mat'),'D'); va=a.D;
assert(isempty(intersect(tr.id,va.id)));
models={}; selection=table(); rng(c.modelSeed);
t=tic; M=struct('name',"Scalar_GPR",'type',"scalar",'reg',fit_gps(tr.X,tr.Y));
M.seconds=toc(t); models{end+1}=M;
t=tic; M=struct('name',"Beam_plus_GPR",'type',"correction", ...
    'reg',fit_gps(tr.X,tr.Y(:,1)-beam_tip(tr.X)));
M.seconds=toc(t); models{end+1}=M;
methods=["gp","rbf"];
if c.useMLP && exist('trainnet','file')~=0
    methods(end+1)="mlp";
elseif c.useMLP
    warning('Deep Learning Toolbox missing: MLP skipped.');
end
for method=methods
    started=tic; best=Inf; chosen=[];
    switch method
        case "rbf", params=c.rbfLambda;
        case "mlp", params=c.mlpWidths;
        otherwise, params=0;
    end
    ranks=unique(min(c.ranks,size(tr.X,1)-1));
    for r=ranks
        P=pod_fit(tr.S,tr.w,r); A=pod_encode(P,tr.S); Av=pod_encode(P,va.S);
        for hp=params
            switch method
                case "gp", reg=fit_gps(tr.X,A);
                case "rbf", reg=fit_rbf(tr.X,A,hp);
                case "mlp", reg=fit_mlp(tr.X,A,va.X,Av,hp,c);
            end
            M=struct('name',"POD_"+upper(method),'type',"field",'reg',reg,'pod',P);
            H=predict_surrogate(M,va.X);
            score=mean(field_error(va.S,H,tr.w));
            row=table(method,P.r,hp,score,'VariableNames', ...
                {'Method','Rank','Hyperparameter','ValidationMeanRelativeL2'});
            if isempty(selection), selection=row; else, selection=[selection;row]; end %#ok<AGROW>
            if score<best, best=score; chosen=M; end
        end
    end
    chosen.seconds=toc(started); chosen.validationScore=best;
    models{end+1}=chosen; %#ok<AGROW>
end
meta=struct('config',c,'trainIDs',tr.id,'valIDs',va.id, ...
    'created',string(datetime('now')),'MATLAB',version, ...
    'physics',tr.physics,'xi',tr.xi,'w',tr.w);
save(f,'models','meta','selection','-v7.3');
writetable(selection,fullfile(c.out,'validation_selection.csv'));
fprintf('Frozen %d models. Test data not used.\n',numel(models));
end
