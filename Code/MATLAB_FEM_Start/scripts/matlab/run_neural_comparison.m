function run_neural_comparison(stage,N,seed)
%RUN_NEURAL_COMPARISON Immutable, resumable study stages in the current project.
% prepare, prototype_checks, static, static_final_data, static_evaluate,
% modal_check, modal_data, modal_train, modal_final_data, modal_evaluate.
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
    case "static_final_data"
        a=verifyPrepared(out,cfg); design=a.staticFinal;
        assertStaticModelsFrozen(out,cfg);
        c.meshDivisor=3; c.geometricOrder="quadratic"; c.saveRawMesh=false;
        c.maxDeflectionRatio=0.02;
        for i=1:numel(design.id)
            file=fullfile(out,'static_cases',sprintf('case_%06d.mat',design.id(i)));
            if isfile(file)
                old=load(file); assert(isequal(old.value.x,design.X(i,:)));
                assert(all(isfinite(old.value.S)) && all(isfinite(old.value.Y)));
                continue
            end
            started=tic; lastwarn('');
            try
                value=solve_case(design.X(i,:),c);
                value.seconds=toc(started);
                value.status="success";
                [value.femWarning,value.femWarningID]=lastwarn;
            catch err
                failure=struct('status',"failed",'id',design.id(i), ...
                    'x',design.X(i,:),'seconds',toc(started), ...
                    'error',getReport(err,'extended','hyperlinks','off'));
                [failure.femWarning,failure.femWarningID]=lastwarn;
                femstudy.data.saveNew(file,failure);
                rethrow(err);
            end
            value.id=design.id(i);
            femstudy.data.saveNew(file,value);
            fprintf('Static final FEM %d/%d: %.2fs\n',i,numel(design.id),value.seconds);
        end
    case "static_evaluate"
        a=verifyPrepared(out,cfg);
        resultFile=fullfile(out,'static_test_evaluation.mat');
        if isfile(resultFile)
            old=load(resultFile);
            assert(isfield(old,'value') && ...
                isequal(old.value.testIDs,a.staticFinal.id), ...
                'femstudy:study:StaticResultMismatch', ...
                'Stored static evaluation does not match the sealed test design.');
            return
        end
        test=readStaticFinal(a.staticFinal,out);
        train=load(fullfile(source,'n384','train.mat'));
        val=load(fullfile(source,'n384','val.mat'));
        assert(isempty(intersect(test.id,[train.D.id;val.D.id])));
        records=struct('id',{},'N',{},'seed',{},'kind',{},'trainingSeconds',{},'predict',{});
        records(end+1)=struct('id',"Beam_theory_field",'N',0,'seed',0, ...
            'kind',"physics",'trainingSeconds',0, ...
            'predict',@(X)femstudy.fem.beamField(X,test.xi));
        for n=cfg.sizes(:)'
            for s=cfg.seeds(:)'
                for kind=["pod","residual"]
                    file=fullfile(out,"n"+n,"seed"+s,kind+'.mat');
                    assert(isfile(file),'Missing frozen static model: %s',file);
                    q=load(file); m=q.value;
                    records(end+1)=struct('id',"Neural_"+kind,'N',n,'seed',s, ...
                        'kind',kind,'trainingSeconds',m.trainingSeconds, ...
                        'predict',@(X)femstudy.models.predictNeural(m,X)); %#ok<AGROW>
                end
            end
        end
        base=load(fullfile(source,'n384','models.mat'));
        for i=1:numel(base.models)
            m=base.models{i};
            if m.type~="field", continue; end
            records(end+1)=struct('id',"Legacy_"+m.name,'N',384,'seed',42, ...
                'kind',"legacy",'trainingSeconds',m.seconds, ...
                'predict',@(X)predict_surrogate(m,X)); %#ok<AGROW>
        end
        deepRoot=fullfile(root,'experiments','archive','deeponet_20261023_v1','n384');
        for s=42:46
            q=load(fullfile(deepRoot,"seed"+s,'model.mat')); m=q.model;
            records(end+1)=struct('id',"DeepONet",'N',384,'seed',s, ...
                'kind',"deeponet",'trainingSeconds',NaN, ...
                'predict',@(X)predict_deeponet(m,X,test.xi)); %#ok<AGROW>
        end
        perCase=cell(0,11); timing=cell(0,10); summary=cell(0,9);
        for k=1:numel(records)
            m=records(k); H=m.predict(test.X);
            assert(isequal(size(H),size(test.S)) && all(isfinite(H),'all'), ...
                'Invalid field prediction from %s.',m.id);
            metric=femstudy.metrics.field(test.S,H,test.w,test.X);
            qn=size(test.xi,2); tip=find(test.xi(1,:)==1 & test.xi(2,:)==.5 & test.xi(3,:)==.5,1);
            uz=H(2*qn+tip,:);
            gridMaximum=zeros(numel(test.id),1);
            for j=1:numel(test.id)
                field=reshape(H(:,j),qn,3);
                gridMaximum(j)=max(sqrt(sum(field.^2,2)));
            end
            perCase=[perCase;[repmat({m.id},numel(test.id),1), ...
                num2cell(repmat(m.N,numel(test.id),1)), ...
                num2cell(repmat(m.seed,numel(test.id),1)),num2cell(test.id), ...
                num2cell(metric.relative),num2cell(metric.absoluteRMS), ...
                num2cell(metric.componentRelative), ...
                num2cell(uz(:)-test.Y(:,1)), ...
                num2cell(gridMaximum-test.Y(:,2))]]; %#ok<AGROW>
            firstTiming=size(timing,1)+1;
            for j=1:numel(test.id)
                m.predict(test.X(j,:));
                repeats=zeros(cfg.timingRepeats,1);
                for rep=1:cfg.timingRepeats
                    t=tic; m.predict(test.X(j,:)); repeats(rep)=toc(t);
                end
                for rep=1:numel(repeats)
                    timing(end+1,:)={m.id,m.N,m.seed,test.id(j),rep,repeats(rep), ...
                        median(repeats),metric.relative(j),metric.absoluteRMS(j),m.trainingSeconds}; %#ok<AGROW>
                end
            end
            summary(end+1,:)={m.id,m.N,m.seed,median(metric.relative), ...
                metric.summary(2),max(metric.relative), ...
                mean(metric.relative),median(cell2mat(timing(firstTiming:end,7))), ...
                m.trainingSeconds}; %#ok<AGROW>
            fprintf('Static test %s n=%d seed=%d median=%.4g%%\n', ...
                m.id,m.N,m.seed,100*median(metric.relative));
        end
        result=struct('schema',"static-neural-final-evaluation-v1", ...
            'testIDs',test.id,'modelIDs',string({records.id}), ...
            'perCase',cell2table(perCase,'VariableNames', ...
            {'Model','N','Seed','TestID','RelativeFieldError','AbsoluteRMS_m', ...
             'RelativeUxError','RelativeUyError','RelativeUzError', ...
             'TipUzError_m','GridMaximumError_m'}), ...
            'timing',cell2table(timing,'VariableNames', ...
            {'Model','N','Seed','TestID','Repeat','PredictionSeconds', ...
             'CaseMedianSeconds','RelativeFieldError','AbsoluteRMS_m','TrainingSeconds'}), ...
            'summary',cell2table(summary,'VariableNames', ...
            {'Model','N','Seed','MedianRelativeError','P95RelativeError', ...
             'MaxRelativeError','MeanRelativeError','MedianPredictionSeconds', ...
             'TrainingSeconds'}), ...
            'MATLAB',version,'Toolboxes',ver,'Computer',computer);
        femstudy.data.saveNew(resultFile,result);
        writetable(result.summary,fullfile(out,'static_test_summary.csv'));
        writetable(result.perCase,fullfile(out,'static_test_per_case.csv'));
        writetable(result.timing,fullfile(out,'static_test_timing.csv'));
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
    case "modal_final_data"
        a=verifyPrepared(out,cfg);
        assertModalModelsFrozen(out,cfg);
        ids=find(a.modal.split=="test");
        for i=ids(:)'
            file=fullfile(out,'modal_test_cases',sprintf('case_%06d.mat',a.modal.id(i)));
            if isfile(file)
                old=load(file); assert(isequal(old.value.parameters,a.modal.X(i,:)));
                continue
            end
            lastwarn('');
            value=femstudy.fem.modal(a.modal.X(i,:),3);
            value.id=a.modal.id(i);
            [value.femWarning,value.femWarningID]=lastwarn;
            femstudy.data.saveNew(file,value);
            fprintf('Modal final FEM %d/%d: %.2fs\n',find(ids==i,1),numel(ids),value.seconds);
        end
    case "modal_evaluate"
        a=verifyPrepared(out,cfg); resultFile=fullfile(out,'modal_test_evaluation.mat');
        if isfile(resultFile)
            old=load(resultFile);
            assert(isfield(old,'value') && ...
                isequal(old.value.testIDs,a.modal.id(a.modal.split=="test")), ...
                'femstudy:study:ModalResultMismatch', ...
                'Stored modal evaluation does not match the sealed test design.');
            return
        end
        test=readModalTest(a.modal,out);
        records=struct('id',{},'N',{},'seed',{},'kind',{},'trainingSeconds',{},'predict',{});
        for n=cfg.sizes(:)'
            file=fullfile(out,"n"+n,'frequency_gp.mat');
            assert(isfile(file),'Missing frozen frequency GPR: %s',file);
            q=load(file); m=q.value;
            records(end+1)=struct('id',"Frequency_GPR",'N',n,'seed',42, ...
                'kind',"gpr",'trainingSeconds',m.trainingSeconds, ...
                'predict',@(X)femstudy.models.predictFrequency(m,X)); %#ok<AGROW>
            for s=cfg.seeds(:)'
                file=fullfile(out,"n"+n,"seed"+s,'frequency_mlp.mat');
                assert(isfile(file),'Missing frozen frequency MLP: %s',file);
                q=load(file); m=q.value;
                records(end+1)=struct('id',"Frequency_MLP",'N',n,'seed',s, ...
                    'kind',"mlp",'trainingSeconds',m.trainingSeconds, ...
                    'predict',@(X)femstudy.models.predictNeural(m,X)); %#ok<AGROW>
            end
        end
        perCase=cell(0,10); perMode=cell(0,12); timing=cell(0,10); summary=cell(0,9);
        for k=1:numel(records)
            m=records(k); [raw,sorted,violations]=predictFrequencies(m,test.X);
            metric=femstudy.metrics.frequency(struct('rawHz',raw, ...
                'sortedHz',sorted,'orderViolation',violations),test.F);
            caseRaw=mean(metric.relativeRaw,2,'omitnan');
            caseSorted=mean(metric.relativeSorted,2,'omitnan');
            perCase=[perCase;[repmat({m.id},numel(test.id),1), ...
                num2cell(repmat(m.N,numel(test.id),1)), ...
                num2cell(repmat(m.seed,numel(test.id),1)),num2cell(test.id), ...
                num2cell(caseRaw),num2cell(caseSorted),num2cell(violations), ...
                num2cell(mean(metric.absoluteRawHz,2)), ...
                num2cell(mean(metric.absoluteSortedHz,2)), ...
                num2cell(test.seconds)]]; %#ok<AGROW>
            for mode=1:size(test.F,2)
                rawModeErrors=sort(metric.relativeRaw(:,mode));
                sortedModeErrors=sort(metric.relativeSorted(:,mode));
                perMode(end+1,:)={m.id,m.N,m.seed,mode, ...
                    median(metric.relativeRaw(:,mode),'omitnan'), ...
                    median(metric.relativeSorted(:,mode),'omitnan'), ...
                    rawModeErrors(ceil(.95*numel(test.id))), ...
                    sortedModeErrors(ceil(.95*numel(test.id))),  ...
                    max(metric.relativeRaw(:,mode),[],'omitnan'), ...
                    max(metric.relativeSorted(:,mode),[],'omitnan'), ...
                    median(metric.absoluteRawHz(:,mode)), ...
                    median(metric.absoluteSortedHz(:,mode))}; %#ok<AGROW>
            end
            repeats=zeros(numel(test.id),cfg.timingRepeats);
            for j=1:numel(test.id)
                m.predict(test.X(j,:));
                for rep=1:cfg.timingRepeats
                    t=tic; m.predict(test.X(j,:)); repeats(j,rep)=toc(t);
                end
                for rep=1:cfg.timingRepeats
                    timing(end+1,:)={m.id,m.N,m.seed,test.id(j),rep,repeats(j,rep), ...
                        median(repeats(j,:)),m.trainingSeconds,test.seconds(j), ...
                        violations(j)}; %#ok<AGROW>
                end
            end
            modelPredictionMedian=median(median(repeats,2));
            summary(end+1,:)={m.id,m.N,m.seed,median(caseRaw,'omitnan'), ...
                median(caseSorted,'omitnan'),max(caseRaw,[],'omitnan'), ...
                max(caseSorted,[],'omitnan'),mean(violations),modelPredictionMedian}; %#ok<AGROW>
            fprintf('Modal test %s n=%d seed=%d raw=%.4g%% sorted=%.4g%%\n', ...
                m.id,m.N,m.seed,100*median(caseRaw,'omitnan'), ...
                100*median(caseSorted,'omitnan'));
        end
        result=struct('schema',"modal-frequency-final-evaluation-v1", ...
            'testIDs',test.id,'modelIDs',string({records.id}), ...
            'perCase',cell2table(perCase,'VariableNames', ...
            {'Model','N','Seed','TestID','MeanRelativeRaw','MeanRelativeSorted', ...
             'OrderViolation','MeanAbsoluteRaw_Hz','MeanAbsoluteSorted_Hz','FEMSeconds'}), ...
            'perMode',cell2table(perMode,'VariableNames', ...
            {'Model','N','Seed','Mode','MedianRelativeRaw','MedianRelativeSorted', ...
             'P95RelativeRaw','P95RelativeSorted','MaxRelativeRaw','MaxRelativeSorted', ...
             'MedianAbsoluteRaw_Hz', ...
             'MedianAbsoluteSorted_Hz'}), ...
            'timing',cell2table(timing,'VariableNames', ...
            {'Model','N','Seed','TestID','Repeat','PredictionSeconds', ...
             'CaseMedianSeconds','TrainingSeconds','FEMSeconds','OrderViolation'}), ...
            'summary',cell2table(summary,'VariableNames', ...
            {'Model','N','Seed','MedianRelativeRaw','MedianRelativeSorted', ...
             'MaxRelativeRaw','MaxRelativeSorted','OrderViolationFraction', ...
             'PredictionSecondsPerCase'}), ...
            'MATLAB',version,'Toolboxes',ver,'Computer',computer);
        femstudy.data.saveNew(resultFile,result);
        writetable(result.summary,fullfile(out,'modal_test_summary.csv'));
        writetable(result.perCase,fullfile(out,'modal_test_per_case.csv'));
        writetable(result.perMode,fullfile(out,'modal_test_per_mode.csv'));
        writetable(result.timing,fullfile(out,'modal_test_timing.csv'));
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

function assertStaticModelsFrozen(out,cfg)
for n=cfg.sizes(:)'
    for s=cfg.seeds(:)'
        for kind=["pod","residual"]
            file=fullfile(out,"n"+n,"seed"+s,kind+'.mat');
            assert(isfile(file),'Static model is not frozen: %s',file);
            q=load(file); assert(isfinite(q.value.validationError));
        end
    end
end
end

function assertModalModelsFrozen(out,cfg)
for n=cfg.sizes(:)'
    file=fullfile(out,"n"+n,'frequency_gp.mat');
    assert(isfile(file),'Modal model is not frozen: %s',file);
    q=load(file); assert(isfinite(q.value.validationScores(1)));
    for s=cfg.seeds(:)'
        file=fullfile(out,"n"+n,"seed"+s,'frequency_mlp.mat');
        assert(isfile(file),'Modal model is not frozen: %s',file);
        q=load(file); assert(isfinite(q.value.validationError));
    end
end
end

function D=readStaticFinal(design,out)
D.X=design.X; D.id=design.id;
for i=1:numel(D.id)
    file=fullfile(out,'static_cases',sprintf('case_%06d.mat',D.id(i)));
    assert(isfile(file),'Missing frozen static FEM reference: %s',file);
    a=load(file); v=a.value;
    assert(isfield(v,'status') && v.status=="success" && isequal(v.x,D.X(i,:)));
    if i==1
        D.xi=v.xi; D.w=v.w; D.S=zeros(numel(v.S),numel(D.id));
        D.Y=zeros(numel(D.id),numel(v.Y));
    else
        assert(isequal(v.xi,D.xi) && isequal(v.w,D.w));
    end
    D.S(:,i)=v.S; D.Y(i,:)=v.Y; D.seconds(i,1)=v.seconds;
end
assert(all(isfinite(D.S),'all') && all(isfinite(D.Y),'all'));
end

function D=readModalTest(design,out)
ids=find(design.split=="test"); D.X=design.X(ids,:); D.id=design.id(ids);
D.F=zeros(numel(ids),6); D.seconds=zeros(numel(ids),1);
for j=1:numel(ids)
    file=fullfile(out,'modal_test_cases',sprintf('case_%06d.mat',D.id(j)));
    assert(isfile(file),'Missing frozen modal FEM reference: %s',file);
    a=load(file); assert(isequal(a.value.parameters,D.X(j,:)));
    D.F(j,:)=a.value.frequencyHz(1:6)'; D.seconds(j)=a.value.seconds;
end
assert(all(D.F>0,'all') && all(diff(D.F,1,2)>=0,'all'));
end

function [raw,sorted,violations]=predictFrequencies(model,X)
output=model.predict(X);
if isstruct(output)
    raw=output.rawHz;
else
    raw=output;
end
assert(size(raw,1)==size(X,1) && size(raw,2)==6 && ...
    all(isfinite(raw),'all') && all(raw>0,'all'));
sorted=sort(raw,2); violations=any(diff(raw,1,2)<0,2);
end
