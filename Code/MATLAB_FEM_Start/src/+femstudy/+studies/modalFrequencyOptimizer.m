function modalFrequencyOptimizer(root,stage)
cfgPath=fullfile(root,'configs','modal_frequency_optimizer_20261029_v1.json');
cfg=jsondecode(fileread(cfgPath)); out=fullfile(root,'experiments','active',cfg.study);
if stage=="prepare", prepare(root,out,cfg,cfgPath); return; end
m=readMat(fullfile(out,'manifest.mat')); verifySources(root,m.sources);
assert(strcmp(version,m.matlabVersion),'MATLAB version changed.');
D=readMat(fullfile(out,'prepared.mat'));
switch stage
    case "pilot"
        a=fit(out,cfg,D,m,"pilot","adam",1,42,10);
        b=fit(out,cfg,D,m,"pilot","lbfgs",1,42,10);
        g=fit(out,cfg,D,m,"pilot","gpr",1,42,10);
        assert(strcmp(a.model.initialWeightsHash,b.model.initialWeightsHash));
        assert(isequal(a.trainIDs,b.trainIDs)&&isequal(a.trainIDs,g.trainIDs));
        for f=["xm","xs","ym","ys"], assert(isequal(a.model.(f),b.model.(f))&&isequal(a.model.(f),g.model.(f))); end
        assert(max(abs(exp(log(D.F(:)))./D.F(:)-1))<1e-12);
        assert(all(isfinite(a.predRaw),'all')&&all(a.predRaw>0,'all'));
        assert(abs(a.meanRaw-mean(abs(a.predRaw-a.truth)./a.truth,'all'))<1e-14);
        before=fileSHA(fullfile(out,'runs','pilot_adam_f01_s42_attempt01.mat'));
        fit(out,cfg,D,m,"pilot","adam",1,42,10);
        assert(strcmp(before,fileSHA(fullfile(out,'runs','pilot_adam_f01_s42_attempt01.mat'))));
        putMat(fullfile(out,'pilot_passed.mat'),struct('split',true,'logRoundTrip',true, ...
            'identicalInitialization',true,'sharedScaling',true,'metrics',true,'resume',true));
        disp('Pilot passed.');
    case "campaign"
        readMat(fullfile(out,'pilot_passed.mat'));
        for fold=1:3
            fit(out,cfg,D,m,"cv","gpr",fold,42,0);
            for seed=reshape(cfg.seeds,1,[])
                fit(out,cfg,D,m,"cv","adam",fold,seed,cfg.adamEpochs);
                fit(out,cfg,D,m,"cv","lbfgs",fold,seed,cfg.lbfgsIterations);
            end
        end
    case "evaluate"
        evaluate(out,cfg,D,m);
    case "final"
        selection=readMat(fullfile(out,'selection.mat'));
        for seed=reshape(cfg.seeds,1,[])
            budget=cfg.adamEpochs; if selection.optimizer=="lbfgs", budget=cfg.lbfgsIterations; end
            fit(out,cfg,D,m,"final",selection.optimizer,0,seed,budget);
        end
    case "ledger"
        ledger(out,"final");
    otherwise
        error('Unknown stage %s',stage);
end
end

function prepare(root,out,cfg,cfgPath)
if isfile(fullfile(out,'manifest.mat'))
    m=readMat(fullfile(out,'manifest.mat')); verifySources(root,m.sources); readMat(fullfile(out,'prepared.mat')); return
end
source=fullfile(root,'experiments','active',cfg.sourceStudy);
a=load(fullfile(source,'prepared.mat'),'value'); q=a.value.modal;
isTrain=q.split=="train"; X=q.X(isTrain,:); ids=q.id(isTrain);
assert(isequal(ids(:),(cfg.trainIDs(1):cfg.trainIDs(2))')&&size(X,1)==384);
lo=cfg.lower(:)'; span=cfg.upper(:)'-lo; U=(X-lo)./span;
assert(all(U>=0,'all')&&all(U<=1,'all'));
dist=pdist2(U,U,'chebychev'); dist(1:385:end)=Inf;
assert(min(dist,[],'all')>cfg.normalizedDuplicateTolerance,'Duplicate training parameters');
F=zeros(384,6); paths=strings(0,1);
for k=1:384
    path=string(fullfile(source,'modal_cases',sprintf('case_%06d.mat',ids(k))));
    a=load(path,'value'); v=a.value;
    assert(isequal(v.parameters,X(k,:))&&v.divisor==3);
    F(k,:)=v.frequencyHz(1:6); paths(end+1,1)=path; %#ok<AGROW>
end
assert(all(isfinite(F),'all')&&all(F>0,'all')&&all(diff(F,1,2)>=0,'all'));
rng(cfg.foldSeed,'twister'); perm=randperm(384); fold=zeros(384,1);
for j=1:3, fold(perm((j-1)*128+(1:128)))=j; end
assert(all(arrayfun(@(j) nnz(fold==j)==128,1:3)));
D=struct('id',ids(:),'X',X,'F',F,'fold',fold,'designSeed',cfg.foldSeed);
putMat(fullfile(out,'prepared.mat'),D);
T=array2table([ids(:) fold X],VariableNames=[{'ID','Fold'} cellstr(string(cfg.parameterNames(:)'))]);
writeTable(fullfile(out,'fold_assignments.csv'),T);
paths=[paths;string(cfgPath);string(fullfile(out,'PROTOCOL.md')); ...
    string(fullfile(root,'scripts','matlab','run_modal_frequency_optimizer.m')); ...
    string(fullfile(root,'src','+femstudy','+studies','modalFrequencyOptimizer.m')); ...
    string(fullfile(root,'src','+femstudy','+models','fitControlledRestMLP.m')); ...
    string(fullfile(root,'src','fit_gps.m'));string(fullfile(root,'src','predict_reg.m')); ...
    string(fullfile(source,'prepared.mat'));string(fullfile(out,'prepared.mat')); ...
    string(fullfile(out,'fold_assignments.csv'))];
hashes=strings(numel(paths),1); relative=paths;
for k=1:numel(paths), hashes(k)=fileSHA(paths(k)); relative(k)=extractAfter(paths(k),strlength(string(root))+1); end
sources=table(relative,hashes,VariableNames={'Path','SHA256'});
[~,gitrev]=system('git rev-parse HEAD'); [~,status]=system('git status --short');
m=struct('sources',sources,'matlabVersion',version,'toolboxes',ver,'computer',computer, ...
    'gitRevision',string(strtrim(gitrev)),'gitStatus',string(status),'configSHA',fileSHA(cfgPath));
putMat(fullfile(out,'manifest.mat'),m); writeTable(fullfile(out,'source_checksums.csv'),sources);
fprintf('Saved 384 cases and three 128-case folds; no modal holdout labels loaded.\n');
end

function r=fit(out,cfg,D,m,stage,optimizer,fold,seed,budget)
base=sprintf('%s_%s_f%02d_s%d',stage,optimizer,fold,seed);
folder=fullfile(out,'runs'); if ~isfolder(folder), mkdir(folder); end
files=dir(fullfile(folder,base+"_attempt*.mat"));
starts=files(endsWith(string({files.name}),'.started.mat'));
files=files(~endsWith(string({files.name}),'.started.mat'));
for k=1:numel(files)
    old=readMat(fullfile(files(k).folder,files(k).name));
    assert(old.context.stage==stage&&old.context.optimizer==optimizer&&old.context.fold==fold ...
        &&old.context.seed==seed&&old.context.budget==budget ...
        &&strcmp(old.context.manifestSHA,fileSHA(fullfile(out,'manifest.mat'))));
    if old.status=="completed", r=old; return; end
end
attempt=numel(starts)+1; path=fullfile(folder,sprintf('%s_attempt%02d.mat',base,attempt));
context=struct('stage',stage,'optimizer',optimizer,'fold',fold,'seed',seed,'budget',budget, ...
    'manifestSHA',fileSHA(fullfile(out,'manifest.mat')),'configSHA',m.configSHA);
started=fullfile(folder,sprintf('%s_attempt%02d.started.mat',base,attempt));
putMat(started,context); timer=tic;
try
    tr=true(384,1); if fold>0, tr=D.fold~=fold; end
    va=false(384,1); if fold>0, va=D.fold==fold; end
    assert(nnz(tr)==256 || (fold==0 && nnz(tr)==384));
    assert(isempty(intersect(D.id(tr),D.id(va))));
    X=D.X(tr,:); Y=log(D.F(tr,:)); history=struct; opts=struct;
    if optimizer=="gpr"
        rng(seed,'twister'); model=fit_gps(X,Y,cfg.gprKernel); seconds=toc(timer);
        reason="GPR fit completed; convergence not separately certified";
    else
        opts=struct('HiddenLayers',cfg.architecture(:)','Optimizer',optimizer,'Seed',seed, ...
            'Budget',budget,'BatchSize',cfg.batchSize,'InitialLearnRate',cfg.learningRate, ...
            'L2Regularization',cfg.l2,'HistorySize',cfg.historySize, ...
            'GradientTolerance',cfg.gradientTolerance,'StepTolerance',cfg.stepTolerance);
        [model,history]=femstudy.models.fitControlledRestMLP(X,Y,opts);
        seconds=model.trainingSeconds; reason=string(history.stopReason);
    end
    xs=std(X,0,1); xs(xs==0)=1; ys=std(Y,0,1);
    ys(ys<=1e-12*max(max(abs(Y),[],1),realmin))=1;
    assert(isequal(model.xm,mean(X,1))&&isequal(model.xs,xs)&& ...
        isequal(model.ym,mean(Y,1))&&isequal(model.ys,ys),'Scaling leakage.');
    raw=[]; truth=[]; sorted=[]; score=NaN; violations=[];
    if fold>0
        truth=D.F(va,:); raw=exp(predict_reg(model,D.X(va,:))); sorted=sort(raw,2);
        assert(all(isfinite(raw),'all')&&all(raw>0,'all'));
        score=mean(abs(raw-truth)./truth,'all'); violations=sum(diff(raw,1,2)<0,2);
    end
    r=struct('status',"completed",'context',context,'trainIDs',D.id(tr),'validationIDs',D.id(va), ...
        'model',model,'options',opts,'history',history,'trainingSeconds',seconds,'elapsedSeconds',toc(timer), ...
        'stopReason',reason,'predRaw',raw,'predSorted',sorted,'truth',truth,'meanRaw',score,'violations',violations);
    putMat(path,r); fprintf('%s %s fold %d seed %d: %.2f s, %s\n',stage,optimizer,fold,seed,seconds,reason);
catch err
    r=struct('status',"failed",'context',context,'elapsedSeconds',toc(timer), ...
        'error',string(getReport(err,'extended','hyperlinks','off')));
    putMat(path,r); rethrow(err);
end
end

function evaluate(out,cfg,D,m)
rows=table; cases=table; histories=table; init=strings(3,3,2);
for fold=1:3
    for model=["gpr","adam","lbfgs"]
        seeds=42; if model~="gpr", seeds=reshape(cfg.seeds,1,[]); end
        for seed=seeds
            base=sprintf('cv_%s_f%02d_s%d',model,fold,seed); files=dir(fullfile(out,'runs',base+"_attempt*.mat"));
            files=files(~endsWith(string({files.name}),'.started.mat')); good={};
            for j=1:numel(files), r=readMat(fullfile(files(j).folder,files(j).name)); if r.status=="completed", good{end+1}=r; end, end %#ok<AGROW>
            assert(numel(good)==1,'Incomplete or duplicate %s',base); r=good{1};
            assert(strcmp(r.context.manifestSHA,fileSHA(fullfile(out,'manifest.mat'))));
            assert(isequal(r.validationIDs,D.id(D.fold==fold)) && isequal(r.trainIDs,D.id(D.fold~=fold)));
            raw=exp(predict_reg(r.model,D.X(D.fold==fold,:))); assert(isequal(raw,r.predRaw));
            if model~="gpr"
                idx=find(cfg.seeds==seed); z=1+(model=="lbfgs"); init(fold,idx,z)=r.model.initialWeightsHash;
                h=r.history; n=numel(h.iteration);
                if n>0
                    loss=nan(n,1); if numel(h.trainingLoss)==n, loss=h.trainingLoss(:); end
                    ht=table(repmat(string(base),n,1),h.iteration(:),loss,VariableNames={'RunID','Iteration','Loss'});
                    histories=[histories;ht]; %#ok<AGROW>
                end
            end
            h=table(string(base),model,fold,seed,r.meanRaw,r.trainingSeconds,r.stopReason, ...
                mean(r.violations>0),sum(r.violations),VariableNames={'RunID','Model','Fold','Seed','MeanRawRelative','TrainingSeconds','StopReason','OrderViolationCaseFraction','ViolationPairs'});
            rows=[rows;h]; %#ok<AGROW>
            for j=1:6
                ref=r.truth(:,j); ar=abs(r.predRaw(:,j)-ref); as=abs(r.predSorted(:,j)-ref);
                c=table(repmat(string(base),128,1),repmat(model,128,1),repmat(fold,128,1), ...
                    repmat(seed,128,1),r.validationIDs,repmat(j,128,1),ref,r.predRaw(:,j),r.predSorted(:,j), ...
                    ar,as,ar./ref,as./ref,r.violations,VariableNames={'RunID','Model','Fold','Seed','CaseID','Mode','TruthHz','RawHz','SortedHz','AbsoluteRawHz','AbsoluteSortedHz','RelativeRaw','RelativeSorted','OrderViolationPairs'});
                cases=[cases;c]; %#ok<AGROW>
            end
        end
    end
end
assert(all(init(:,:,1)==init(:,:,2),'all'),'Optimizers did not share initial weights');
assert(height(rows)==21&&height(cases)==21*128*6);
score=[mean(cases.RelativeRaw(cases.Model=="adam")),mean(cases.RelativeRaw(cases.Model=="lbfgs"))];
winner="adam"; if score(2)<score(1)-cfg.tieTolerance, winner="lbfgs"; end
selection=struct('optimizer',winner,'adamMean',score(1),'lbfgsMean',score(2), ...
    'metric',string(cfg.primaryMetric),'tieTolerance',cfg.tieTolerance,'manifestSHA',fileSHA(fullfile(out,'manifest.mat')));
putMat(fullfile(out,'selection.mat'),selection);
modeSummary=table;
for model=["adam","lbfgs","gpr"]
    for j=1:6
        c=cases(cases.Model==model & cases.Mode==j,:);
        for representation=["raw","sorted"]
            rel=c.RelativeRaw; absHz=c.AbsoluteRawHz;
            if representation=="sorted", rel=c.RelativeSorted; absHz=c.AbsoluteSortedHz; end
            row=table(model,j,representation,mean(rel),median(rel),nearest(rel),max(rel), ...
                mean(absHz),median(absHz),nearest(absHz),max(absHz), ...
                VariableNames={'Model','Mode','Representation','MeanRelative','MedianRelative','P95Relative','MaxRelative','MeanAbsoluteHz','MedianAbsoluteHz','P95AbsoluteHz','MaxAbsoluteHz'});
            modeSummary=[modeSummary;row]; %#ok<AGROW>
        end
    end
end
writeTable(fullfile(out,'cv_run_summary.csv'),rows); writeTable(fullfile(out,'cv_case_frequency_metrics.csv'),cases);
writeTable(fullfile(out,'mode_summary.csv'),modeSummary); writeTable(fullfile(out,'training_history.csv'),histories);
writeTable(fullfile(out,'selection.csv'),struct2table(selection)); ledger(out,"cv");
assert(strcmp(m.configSHA,fileSHA(fullfile(fileparts(fileparts(fileparts(out))),'configs',string(cfg.study)+".json"))));
fprintf('Adam mean %.6g, L-BFGS mean %.6g; selected %s.\n',score(1),score(2),winner);
end

function ledger(out,phase)
files=dir(fullfile(out,'runs','*_attempt*.started.mat')); T=table;
for k=1:numel(files)
    startPath=string(fullfile(files(k).folder,files(k).name)); c=readMat(startPath);
    resultPath=replace(startPath,'.started.mat','.mat'); sec=NaN; stop=""; err="";
    if phase=="cv" && c.stage=="final", continue; end
    status="interrupted";
    if isfile(resultPath)
        r=readMat(resultPath); assert(isequaln(r.context,c)); status=r.status;
        if status=="completed", sec=r.trainingSeconds; stop=r.stopReason; else, err=r.error; end
    end
    row=table(resultPath,c.stage,c.optimizer,c.fold,c.seed,c.budget,status,sec,stop,err, ...
        VariableNames={'Artifact','Stage','Optimizer','Fold','Seed','Budget','Status','TrainingSeconds','StopReason','Error'});
    T=[T;row]; %#ok<AGROW>
end
path=fullfile(out,'attempt_ledger_'+phase+'.csv');
writeTable(path,T);
end

function q=nearest(x), x=sort(x); q=x(ceil(.95*numel(x))); end

function putMat(path,value)
if isfile(path), old=readMat(path); assert(isequaln(old,value),'Artifact conflict: %s',path); return; end
femstudy.data.saveNew(char(path),value); fid=fopen(string(path)+".sha256",'w'); assert(fid>0);
cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s',fileSHA(path));
end

function value=readMat(path)
assert(isfile(path)&&isfile(string(path)+".sha256"),'Artifact or seal missing: %s',path);
assert(strcmp(strtrim(fileread(string(path)+".sha256")),fileSHA(path)),'Checksum mismatch: %s',path);
a=load(path,'value'); value=a.value;
end

function writeTable(path,T)
parent=fileparts(path); if ~isfolder(parent), mkdir(parent); end
tmp=string(tempname(parent))+".csv"; writetable(T,tmp); cleanup=onCleanup(@() deleteIfExists(tmp));
if isfile(path), assert(strcmp(fileSHA(path),fileSHA(tmp)),'Table conflict: %s',path);
else, [ok,msg]=movefile(tmp,path); assert(ok,msg); end
end

function deleteIfExists(path), if isfile(path), delete(path); end, end
function verifySources(root,t)
for k=1:height(t), assert(strcmp(fileSHA(fullfile(root,t.Path(k))),t.SHA256(k)),'Source changed: %s',t.Path(k)); end
end
function h=fileSHA(path)
fid=fopen(path,'r'); assert(fid>=0,'Cannot open %s',path); cleanup=onCleanup(@() fclose(fid));
md=java.security.MessageDigest.getInstance('SHA-256');
while true, b=fread(fid,1048576,'*uint8'); if isempty(b), break; end; md.update(b); end
h=string(lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[])));
end
