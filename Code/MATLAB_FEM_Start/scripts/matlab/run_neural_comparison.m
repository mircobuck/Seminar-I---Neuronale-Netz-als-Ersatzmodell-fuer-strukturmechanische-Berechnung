function run_neural_comparison(stage,N,seed)
%RUN_NEURAL_COMPARISON Immutable, resumable study stages in the current project.
% prepare, prototype_checks, static, modal_check, modal_data, modal_train.
% N and seed are optional.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
cfg=jsondecode(fileread(fullfile(root,'configs','neural_comparison_v1.json')));
out=fullfile(root,'experiments','active',cfg.study);
source=fullfile(root,cfg.source); c=config('smoke');
if nargin<2, N=cfg.sizes(:)'; end
if nargin<3, seed=cfg.seeds(:)'; end
assert(all(ismember(N,cfg.sizes)) && all(ismember(seed,cfg.seeds)));
switch string(stage)
    case "prepare"
        file=fullfile(out,'prepared.mat');
        if isfile(file)
            a=load(file); assert(isequaln(a.value.config,cfg)); return
        end
        previous=[];
        for n=cfg.sizes(:)'
            a=load(fullfile(source,"n"+n,'train.mat')); D=a.D;
            v=load(fullfile(source,"n"+n,'val.mat')); t=load(fullfile(source,"n"+n,'test.mat'));
            assert(numel(D.id)==n && all(isfinite(D.S),'all'));
            assert(isequal(v.D.id(:),(13:18)') && isequal(t.D.id(:),(19:24)'));
            assert(isempty(intersect(D.id,[v.D.id;t.D.id])));
            assert(isempty(previous) || isequal(D.id(1:numel(previous)),previous));
            if n==12, refV=v.D; refT=t.D; end
            assert(isequaln(v.D,refV) && isequaln(t.D,refT));
            previous=D.id;
        end
        raw=dir(fullfile(source,'n384','cases','case_*.mat')); assert(numel(raw)==396);
        for k=1:numel(raw)
            a=load(fullfile(raw(k).folder,raw(k).name)); r=a.out;
            assert(size(r.nodes,1)==3 && size(r.elements,1)==10);
            assert(isequal(size(r.displacement),[size(r.nodes,2),3]));
            assert(all(isfinite(r.displacement),'all') && all(r.elements(:)>=1));
            assert(max(r.elements(:))<=size(r.nodes,2));
        end
        old=[D.X;refV.X;refT.X];
        confirmation=readtable(fullfile(root,'experiments','active','static_confirmation_v1','design.csv'));
        old=[old;confirmation{:,c.names}];
        rng(cfg.seed,'twister'); X=c.lower+rand(cfg.finalCount,6).*(c.upper-c.lower);
        cols=[1 2 3 5]; A=(X(:,cols)-c.lower(cols))./(c.upper(cols)-c.lower(cols));
        B=(old(:,cols)-c.lower(cols))./(c.upper(cols)-c.lower(cols));
        assert(min(pdist2(A,B,'chebychev'),[],'all')>1e-10);
        pair=pdist2(A,A,'chebychev'); pair(1:size(pair,1)+1:end)=Inf;
        assert(min(pair,[],'all')>1e-10);
        final=struct('X',X,'id',(200001:200000+cfg.finalCount)');
        rng(cfg.modalSeed,'twister'); count=384+cfg.modalValidationCount+cfg.modalTestCount;
        lo=[c.lower(1:5),cfg.densityRange(1)]; hi=[c.upper(1:5),cfg.densityRange(2)];
        modal=struct('X',lo+rand(count,6).*(hi-lo),'id',(300001:300000+count)');
        modal.split=[repmat("train",384,1);repmat("val",cfg.modalValidationCount,1);repmat("test",cfg.modalTestCount,1)];
        value=struct('config',cfg,'staticFinal',final,'modal',modal,'version',version, ...
            'toolboxes',ver,'computer',computer,'created',string(datetime('now')),'nativeCases',numel(raw));
        femstudy.data.saveNew(file,value);
        writetable(array2table([final.id final.X],VariableNames=[{'id'},c.names]),fullfile(out,'static_final_design.csv'));
        names={'id','L_m','b_m','h_m','E_Pa','nu','rho_kg_m3'};
        tab=array2table([modal.id modal.X],VariableNames=names); tab.split=modal.split;
        writetable(tab,fullfile(out,'modal_design.csv'));
        fprintf('Prepared: 396 native cases audited; 64 static and 64 modal final cases sealed.\n');
    case "static"
        verifyPrepared(out,cfg);
        for n=N
            a=load(fullfile(source,"n"+n,'train.mat')); D=a.D;
            a=load(fullfile(source,"n"+n,'val.mat')); V=a.D;
            for s=seed
                options=cfg; options.modelSeed=s;
                for kind=["pod","residual"]
                    file=fullfile(out,"n"+n,"seed"+s,kind+'.mat');
                    if isfile(file), continue; end
                    model=femstudy.models.fitNeural(D,V,kind,options);
                    femstudy.data.saveNew(file,model);
                    fprintf('Static %s n=%d seed=%d validation=%g time=%.1fs\n',kind,n,s,model.validationError,model.trainingSeconds);
                end
            end
        end
    case "prototype_checks"
        verifyPrepared(out,cfg); file=fullfile(out,'prototype_checks.mat');
        if isfile(file), return; end
        rng(61027,"twister"); xi=rand(3,24); X=[1 .1 .1 1e9 .3 -1;1.1 .09 .12 1.4e9 .31 -1.2];
        D=struct('X',X,'xi',xi,'S',rand(72,2)*1e-6,'w',ones(72,1)/24);
        fno=femstudy.models.fitFNO(D,modes=[2 1 1]); H=femstudy.models.predictFNO(fno,X);
        pinn=struct('parameters',[1 1e9 .1 .1],'width',2,'theta',zeros(7,1));
        [pw,pr]=femstudy.models.predictPINN(pinn,linspace(0,1,8));
        nodes=[0 1 0 0 .5 .5 0 0 .5 .5;0 0 1 0 0 .5 .5 0 .5 0;0 0 0 1 0 0 0 .5 .5 .5];
        C=struct('nodes',nodes,'elements',(1:10)','X',X(1,:), 'displacement',zeros(10,3));
        graph=femstudy.models.fitGraph({C}); U=femstudy.models.predictGraph(graph,C);
        value=struct('schema',"prototype-checks-v1",'fnoFieldSize',size(H), ...
            'pinnProfileSize',size(pw),'pinnResidualSize',size(pr), ...
            'graphFieldSize',size(U),'models',{{fno,pinn,graph}}, ...
            'created',string(datetime('now')));
        femstudy.data.saveNew(file,value);
        fprintf('Prototype checks passed: DeepONet adapter, PINN, FNO and graph interfaces.\n');
    case "modal_check"
        a=verifyPrepared(out,cfg); file=fullfile(out,'modal_check.mat');
        if isfile(file), return; end
        x=a.modal.X(1,:); coarse=femstudy.fem.modal(x,3); fine=femstudy.fem.modal(x,4);
        value.convergence=femstudy.fem.compareModes(coarse,fine,.01);
        x(6)=2*x(6); density=femstudy.fem.modal(x,3);
        value.densityRelativeError=max(abs(density.frequencyHz(1:6)./coarse.frequencyHz(1:6)*sqrt(2)-1));
        value.pass=value.convergence.pass && value.densityRelativeError<1e-6;
        femstudy.data.saveNew(file,value); assert(value.pass,'Modal qualification failed.');
    case "modal_data"
        a=verifyPrepared(out,cfg); check=load(fullfile(out,'modal_check.mat')); assert(check.value.pass);
        % Final-test reference generation is deliberately deferred until freeze.
        indices=find(a.modal.split~="test");
        for i=indices(:)'
            file=fullfile(out,'modal_cases',sprintf('case_%06d.mat',a.modal.id(i)));
            if isfile(file), old=load(file); assert(isequal(old.value.parameters,a.modal.X(i,:))); continue; end
            value=femstudy.fem.modal(a.modal.X(i,:),3);
            femstudy.data.saveNew(file,value);
            fprintf('Modal reference %d/%d: %.2fs\n',i,numel(indices),value.seconds);
        end
    case "modal_train"
        a=verifyPrepared(out,cfg);
        D=readModal(a.modal,out,"train"); V=readModal(a.modal,out,"val");
        for n=N
            T=femstudy.data.subset(D,1:n);
            file=fullfile(out,"n"+n,'frequency_gp.mat');
            if ~isfile(file)
                started=tic; model=femstudy.models.fitFrequency(T,V); model.trainingSeconds=toc(started);
                femstudy.data.saveNew(file,model);
            end
            for s=seed
                file=fullfile(out,"n"+n,"seed"+s,'frequency_mlp.mat');
                if isfile(file), continue; end
                options=cfg; options.modelSeed=s;
                model=femstudy.models.fitNeural(T,V,"frequency",options);
                femstudy.data.saveNew(file,model);
                fprintf('Frequency n=%d seed=%d validation=%g\n',n,s,model.validationError);
            end
        end
    otherwise
        error('femstudy:stage:Unknown','Unknown or not yet implemented stage: %s',stage);
end
end

function value=verifyPrepared(out,cfg)
a=load(fullfile(out,'prepared.mat')); value=a.value;
assert(isequaln(value.config,cfg),'Configuration changed after preparation.');
end

function D=readModal(design,out,label)
ids=find(design.split==label); D.X=design.X(ids,:); D.id=design.id(ids);
D.F=zeros(numel(ids),6); D.seconds=zeros(numel(ids),1);
for j=1:numel(ids)
    file=fullfile(out,'modal_cases',sprintf('case_%06d.mat',D.id(j)));
    a=load(file); assert(isequal(a.value.parameters,D.X(j,:)));
    D.F(j,:)=a.value.frequencyHz(1:6)'; D.seconds(j)=a.value.seconds;
end
assert(all(D.F>0,'all') && all(diff(D.F,1,2)>=0,'all'));
end
