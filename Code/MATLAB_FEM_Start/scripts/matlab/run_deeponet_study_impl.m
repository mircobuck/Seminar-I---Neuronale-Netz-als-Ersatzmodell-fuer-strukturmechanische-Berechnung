function run_deeponet_study_impl(stage,N,seed)
%run_deeponet_study - Run the isolated, resumable DeepONet comparison.
%   run_deeponet_study("prepare") audits existing complete-case splits.
%   Stages smoke, search, train, evaluate and summarize follow in order.
%   Search/train/evaluate accept N; train/evaluate also accept seed.
%   See also fit_deeponet, predict_deeponet
if nargin<2, N=12; end
if nargin<3, seed=42; end
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(fullfile(root,'src'));
out=fullfile(root,'experiments','archive','deeponet_20261023_v1');
old=fullfile(root,'experiments','active','training_size_12_24_48_20261023');
if ~isfolder(out), mkdir(out); end
if stage=="prepare"
    cfg=struct('counts',[12 24 48 96 192 384],'seeds',42:46, ...
        'widths',[32 64],'latents',[16 32],'epochs',1500, ...
        'learnRates',[1e-3 1e-3],'patience',30,'validateEvery',10, ...
        'matlabVersion',version,'execution',"CPU single precision");
    ids=[]; previous=[]; rows=table;
    for count=cfg.counts
        d=load(fullfile(old,"n"+count,'train.mat')); D=d.D;
        v=load(fullfile(old,"n"+count,'val.mat')); V=v.D;
        t=load(fullfile(old,"n"+count,'test.mat')); T=t.D;
        assert(isempty(intersect(D.id,[V.id;T.id])));
        assert(isempty(intersect(V.id,T.id)));
        assert(isequal(V.id(:),(13:18)') && isequal(T.id(:),(19:24)'));
        assert(isempty(previous) || isequal(D.id(1:numel(previous)),previous)); previous=D.id;
        assert(size(D.S,1)==3*size(D.xi,2));
        [xi,w]=reference_grid([21 5 5]);
        assert(isequal(D.xi,xi) && isequal(D.w,w));
        assert(abs(sum(w)-3)<1e-12);
        clamp=repmat(xi(1,:)'==0,3,1);
        assert(all(D.S(clamp,:)==0,'all'));
        assert(all(isfinite(D.S),'all') && size(unique(D.X,'rows'),1)==count);
        assert(isequal(V.xi,xi) && isequal(T.xi,xi));
        if count==12, refV=V; refT=T; end
        assert(isequaln(V,refV) && isequaln(T,refT));
        rows=[rows;table(repmat(count,numel(D.id),1),D.id(:), ...
            'VariableNames',{'TrainingCases','CaseID'})]; %#ok<AGROW>
        ids=D.id;
    end
    assert(numel(unique([ids;refV.id;refT.id]))==396);
    [~,tip]=min(sum((xi-[1;.5;.5]).^2,1));
    assert(max(abs(T.S(2*size(xi,2)+tip,:)'-T.Y(:,1)))<1e-12);
    if ~isfile(fullfile(out,'protocol.mat'))
        save(fullfile(out,'protocol.mat'),'cfg','-v7.3');
        writelines(jsonencode(cfg,PrettyPrint=true),fullfile(out,'protocol.json'));
        writetable(rows,fullfile(out,'training_ids.csv'));
        writetable(table(refV.id,'VariableNames',{'ValidationID'}),fullfile(out,'validation_ids.csv'));
        writetable(table(refT.id,'VariableNames',{'TestID'}),fullfile(out,'test_ids.csv'));
    end
    disp('PASS: all six nested complete-case splits, fixed holdouts, grid, weights, clamp, tip.');
    return
end
a=load(fullfile(out,'protocol.mat')); cfg=a.cfg;
d=load(fullfile(old,"n"+N,'train.mat')); D=d.D;
v=load(fullfile(old,"n"+N,'val.mat')); V=v.D;
switch stage
    case "smoke"
        tiny=subset(D,1:2); options=opts(cfg,1,42);
        options.epochs=3000; options.patience=300;
        [model,info]=fit_deeponet(tiny,tiny,options,fullfile(out,'tiny_overfit'));
        errors=field_error(tiny.S,predict_deeponet(model,tiny.X,tiny.xi),tiny.w);
        assert(max(errors)<.03,'DeepONet:TinyOverfit','Tiny-set error exceeds 3 percent');
        save(fullfile(out,'tiny_check.mat'),'errors','info');
        P=subset(D,1:4); Q=subset(D,5:6); R=subset(D,7:8);
        options.epochs=100; options.patience=30;
        [model,info]=fit_deeponet(P,Q,options,fullfile(out,'workflow_smoke'));
        H=predict_deeponet(model,R.X,R.xi);
        E=field_error(R.S,H,R.w);
        save(fullfile(out,'workflow_smoke','predictions.mat'),'H','E','info');
        fprintf('Complete internal smoke: two separate test cases, median error %.5g\n',median(E));
    case {"candidate1","candidate2"}
        candidate=str2double(extractAfter(string(stage),"candidate"));
        fit_deeponet(D,V,opts(cfg,candidate,42), ...
            fullfile(out,"n"+N,"candidate"+candidate));
    case "search"
        selection=table;
        for candidate=1:2
            options=opts(cfg,candidate,42);
            folder=fullfile(out,"n"+N,"candidate"+candidate);
            [~,info]=fit_deeponet(D,V,options,folder);
            selection=[selection;table(candidate,options.width,options.latent, ...
                info.validationScore,info.trainingSeconds, ...
                'VariableNames',{'Candidate','Width','Latent','ValidationScore','Seconds'})]; %#ok<AGROW>
        end
        [~,best]=min(selection.ValidationScore);
        file=fullfile(out,"n"+N,'selection.mat');
        if ~isfile(file), save(file,'best','selection'); end
        writetable(selection,fullfile(out,"n"+N,'validation_selection.csv'));
    case "train"
        a=load(fullfile(out,"n"+N,'selection.mat')); best=a.best;
        folder=fullfile(out,"n"+N,"seed"+seed);
        if seed==42
            if ~isfolder(folder), mkdir(folder); end
            if ~isfile(fullfile(folder,'model.mat'))
                copyfile(fullfile(out,"n"+N,"candidate"+best,'model.mat'),folder);
                copyfile(fullfile(out,"n"+N,"candidate"+best,'history.csv'),folder);
            end
        else
            fit_deeponet(D,V,opts(cfg,best,seed),folder);
        end
    case "evaluate"
        for count=cfg.counts
            for s=cfg.seeds
                assert(isfile(fullfile(out,"n"+count,"seed"+s,'model.mat')), ...
                    'All 30 final models must be frozen before test evaluation.');
            end
        end
        folder=fullfile(out,"n"+N,"seed"+seed);
        if isfile(fullfile(folder,'test_predictions.mat')), return; end
        a=load(fullfile(folder,'model.mat')); model=a.model; info=a.info;
        t=load(fullfile(old,"n"+N,'test.mat')); T=t.D;
        H=predict_deeponet(model,T.X,T.xi);
        E=field_error(T.S,H,T.w); Q=size(T.xi,2);
        [~,tip]=min(sum((T.xi-[1;.5;.5]).^2,1));
        Y=[H(2*Q+tip,:)' max(sqrt(H(1:Q,:).^2+ ...
            H(Q+(1:Q),:).^2+H(2*Q+(1:Q),:).^2),[],1)'];
        clamp=repmat(T.xi(1,:)'==0,3,1);
        C=max(abs(H(clamp,:)),[],1)'; times=zeros(6,5);
        for j=1:6
            predict_deeponet(model,T.X(j,:),T.xi);
            for repeat=1:5
                tick=tic; predict_deeponet(model,T.X(j,:),T.xi);
                times(j,repeat)=toc(tick);
            end
        end
        caseTable=table(repmat(N,6,1),repmat(seed,6,1),T.id(:),E(:), ...
            abs(Y(:,1)-T.Y(:,1)),abs(Y(:,2)-T.Y(:,2)),C,median(times,2), ...
            'VariableNames',{'TrainingCases','Seed','CaseID','FieldRelativeL2', ...
            'TipAbsError_m','MaxGridAbsError_m','ClampMax_m','OnlineSeconds'});
        summary=table(N,seed,median(E),prctile(E,95),max(E), ...
            mean(abs(Y(:,1)-T.Y(:,1))),mean(abs(Y(:,2)-T.Y(:,2))), ...
            max(C),median(times,'all'),info.trainingSeconds, ...
            info.preparationSeconds,info.parameterCount,info.bestEpoch, ...
            'VariableNames',{'TrainingCases','Seed','FieldMedianRelL2','FieldP95RelL2', ...
            'FieldWorstRelL2','TipMAE_m','MaxGridMAE_m','ClampMax_m','OnlineSeconds', ...
            'TrainingSeconds','PreparationSeconds','Parameters','BestEpoch'});
        writetable(caseTable,fullfile(folder,'per_case.csv'));
        writetable(summary,fullfile(folder,'summary.csv'));
        writematrix(times,fullfile(folder,'timing_samples.csv'));
        save(fullfile(folder,'test_predictions.mat'),'H','Y','E','times','summary','caseTable');
        disp(summary);
    case "summarize"
        summary=table; cases=table;
        for count=cfg.counts
            for s=cfg.seeds
                folder=fullfile(out,"n"+count,"seed"+s);
                summary=[summary;readtable(fullfile(folder,'summary.csv'))]; %#ok<AGROW>
                cases=[cases;readtable(fullfile(folder,'per_case.csv'))]; %#ok<AGROW>
            end
        end
        writetable(summary,fullfile(out,'deeponet_summary.csv'));
        writetable(cases,fullfile(out,'deeponet_per_case.csv'));
end
end

function options=opts(cfg,candidate,seed)
options=struct('width',cfg.widths(candidate),'latent',cfg.latents(candidate), ...
    'seed',seed,'epochs',cfg.epochs,'learnRate',cfg.learnRates(candidate), ...
    'patience',cfg.patience,'validateEvery',cfg.validateEvery);
end

function B=subset(A,idx)
B=A; B.X=A.X(idx,:); B.S=A.S(:,idx); B.Y=A.Y(idx,:); B.id=A.id(idx);
end
