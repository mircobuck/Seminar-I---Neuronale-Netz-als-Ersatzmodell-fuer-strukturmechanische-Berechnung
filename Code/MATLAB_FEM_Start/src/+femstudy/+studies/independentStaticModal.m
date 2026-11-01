function independentStaticModal(root,stage)
cfgPath=fullfile(root,'configs','independent_static_modal_20261029_v1.json');
cfg=jsondecode(fileread(cfgPath)); out=fullfile(root,'experiments','active',cfg.study);
switch stage
    case "prepare", prepare(root,out,cfg,cfgPath);
    case "pilot", pilot(root,out,cfg);
    case "freeze", freeze(root,out,cfg,cfgPath);
    case "static_data", data(root,out,cfg,"static");
    case "modal_data", data(root,out,cfg,"modal");
    case "evaluate", evaluate(root,out,cfg);
    otherwise, error('Unknown stage: %s',stage);
end
end

function prepare(root,out,cfg,cfgPath)
if isfile(fullfile(out,'prepared.mat'))
    p=readMat(fullfile(out,'prepared.mat')); verify(root,p.sources); return
end
lc=fullfile(root,'experiments','active','restfield_learning_curve_20261028_v1');
mo=fullfile(root,'experiments','active','modal_frequency_optimizer_20261029_v1');
staticTrain=fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384','train.mat');
sp=fullfile(lc,'preprocessing','n384.mat'); verifyPrior(root,lc,sp);
q=load(sp,'value'); P=q.value; a=load(staticTrain,'D'); S=a.D;
assert(isequal(P.trainIDs,S.id) && isequal(P.trainX,S.X) && isequal(P.pod.w,S.w(:)));
R=S.S-femstudy.fem.beamField(S.X,S.xi);
assert(isequal(P.pod.mean,mean(R,2))&&isequal(P.A,pod_encode(P.pod,R)));
pod=pod_fit(R,S.w,32); rank=find(pod.energy>=.9999,1); pod.V=pod.V(:,1:rank); pod.r=rank;
assert(rank==P.pod.r&&isequal(pod.V,P.pod.V)&&isequal(pod.mean,P.pod.mean));
models=struct('staticPod',P.pod,'xi',S.xi,'w',S.w(:),'staticMLP',{{}}, ...
    'staticGPR',[],'modalMLP',{{}},'modalGPR',[],'trainingCosts',table);
sourcePaths=[string(cfgPath);string(fullfile(out,'PROTOCOL.md'));string(staticTrain);string(sp)];
for seed=reshape(cfg.seeds,1,[])
    path=fullfile(lc,'runs',sprintf('run_n384_mlp_seed%d.mat',seed)); verifyPrior(root,lc,path);
    a=load(path,'value'); r=a.value;
    assert(r.status=="completed"&&r.reused&&isequal(r.trainIDs,S.id)&&r.seed==seed && ...
        isequal(r.reg.hiddenLayers,[32 32])&&r.reg.optimizer=="lbfgs"&&r.reg.budget==250);
    checkScaling(r.reg,S.X,P.A); models.staticMLP{seed-41}=r.reg;
    models.trainingCosts=[models.trainingCosts;table("static_mlp",seed,r.trainingSeconds,"historical",VariableNames={'Model','Seed','Seconds','Source'})]; %#ok<AGROW>
    sourcePaths(end+1,1)=string(path); %#ok<AGROW>
end
path=fullfile(lc,'runs','run_n384_gpr_seed42.mat'); verifyPrior(root,lc,path);
a=load(path,'value'); r=a.value; assert(r.status=="completed"&&isequal(r.trainIDs,S.id));
checkScaling(r.reg,S.X,P.A); models.staticGPR=r.reg;
models.trainingCosts=[models.trainingCosts;table("static_gpr",42,r.trainingSeconds,"historical",VariableNames=models.trainingCosts.Properties.VariableNames)];
sourcePaths(end+1,1)=string(path);
mp=fullfile(mo,'prepared.mat'); verifyPrior(root,mo,mp); a=load(mp,'value'); M=a.value;
assert(isequal(M.id,(300001:300384)')&&all(M.F>0,'all'));
sourcePaths(end+1,1)=string(mp);
for seed=reshape(cfg.seeds,1,[])
    path=fullfile(mo,'runs',sprintf('final_lbfgs_f00_s%d_attempt01.mat',seed)); verifyPrior(root,mo,path);
    a=load(path,'value'); r=a.value;
    assert(r.status=="completed" && r.context.stage=="final"&&r.context.optimizer=="lbfgs" && ...
        r.context.seed==seed && r.context.budget==250 && isequal(r.trainIDs,M.id));
    checkScaling(r.model,M.X,log(M.F)); models.modalMLP{seed-41}=r.model;
    models.trainingCosts=[models.trainingCosts;table("modal_mlp",seed,r.trainingSeconds,"historical",VariableNames=models.trainingCosts.Properties.VariableNames)]; %#ok<AGROW>
    sourcePaths(end+1,1)=string(path); %#ok<AGROW>
end
modelPath=fullfile(out,'models.mat');
if isfile(modelPath)
    saved=readMat(modelPath); checkScaling(saved.modalGPR,M.X,log(M.F));
    assert(isequaln(saved.staticPod,models.staticPod)&&isequaln(saved.staticMLP,models.staticMLP) ...
        &&isequaln(saved.staticGPR,models.staticGPR)&&isequaln(saved.modalMLP,models.modalMLP));
    models=saved;
else
    rng(cfg.modalGprSeed,'twister'); timer=tic; models.modalGPR=fit_gps(M.X,log(M.F),cfg.modalGprKernel);
    sec=toc(timer); checkScaling(models.modalGPR,M.X,log(M.F));
    models.trainingCosts=[models.trainingCosts;table("modal_gpr",42,sec,"new_fit",VariableNames=models.trainingCosts.Properties.VariableNames)];
    putMat(modelPath,models);
end

files=[dir(fullfile(root,'experiments','**','*design*.csv')); ...
    dir(fullfile(root,'configs','designs','*.csv')); ...
    dir(fullfile(root,'experiments','active','restfield_sampling48_20261028_v1','designs','*.csv'))];
knownIDs=[]; stat=[]; modal=[];
for k=1:numel(files)
    path=string(fullfile(files(k).folder,files(k).name)); if startsWith(path,string(out)), continue; end
    t=readtable(path,TextType="string"); vars=string(t.Properties.VariableNames); id=find(strcmpi(vars,'id'),1);
    if isempty(id), continue; end
    knownIDs=[knownIDs;t{:,id}]; %#ok<AGROW>
    if all(ismember(string(cfg.static.parameters),vars)), stat=[stat;t{:,cellstr(string(cfg.static.parameters))}]; end %#ok<AGROW>
    if all(ismember(string(cfg.modal.parameters),vars)), modal=[modal;t{:,cellstr(string(cfg.modal.parameters))}]; end %#ok<AGROW>
    sourcePaths(end+1,1)=path; %#ok<AGROW>
end
assert(~isempty(stat)&&~isempty(modal)&&all(ismember((800001:800128)',knownIDs))&& ...
    all(ismember((700001:700064)',knownIDs))&&all(ismember((300397:300460)',knownIDs)));
designs=struct;
for kind=["static","modal"]
    c=cfg.(kind); lo=c.lower(:)'; span=c.upper(:)'-lo; rng(c.seed,'twister');
    if kind=="static", U=lhsdesign(cfg.count,6,'Criterion','maximin','Iterations',c.iterations);
    else, U=rand(cfg.count,6); end
    X=lo+U.*span; ids=(c.idStart:c.idStart+cfg.count-1)';
    old=stat; if kind=="modal", old=modal; end
    dist=pdist2(U,(old-lo)./span,'chebychev'); internal=pdist2(U,U,'chebychev'); internal(1:129:end)=Inf;
    assert(isempty(intersect(ids,knownIDs))&&min(dist,[],'all')>cfg.duplicateToleranceNormalized && ...
        min(internal,[],'all')>cfg.duplicateToleranceNormalized);
    designs.(kind)=struct('X',X,'id',ids,'minimumKnownDistance',min(dist,[],'all'),'seed',c.seed);
    t=array2table([ids X],VariableNames=[{'ID'} cellstr(string(c.parameters(:)'))]);
    t.Split=repmat("independent_holdout",cfg.count,1); writeTable(fullfile(out,kind+"_holdout_design.csv"),t);
end
assert(isempty(intersect(designs.static.id,designs.modal.id)));
putMat(fullfile(out,'designs.mat'),designs);
sourcePaths=[sourcePaths;string(fullfile(out,'models.mat'));string(fullfile(out,'designs.mat')); ...
    string(fullfile(out,'static_holdout_design.csv'));string(fullfile(out,'modal_holdout_design.csv')); ...
    string(fullfile(root,'scripts','matlab','run_independent_static_modal.m')); ...
    string(fullfile(root,'config.m'));string(fullfile(root,'src','solve_case.m')); ...
    string(fullfile(root,'src','reference_grid.m'));string(fullfile(root,'src','rom_observation.m')); ...
    string(fullfile(root,'src','predict_reg.m'));string(fullfile(root,'src','fit_gps.m')); ...
    string(fullfile(root,'src','pod_fit.m'));string(fullfile(root,'src','pod_encode.m')); ...
    string(fullfile(root,'src','+femstudy','+fem','beamField.m')); ...
    string(fullfile(root,'src','+femstudy','+fem','modal.m')); ...
    string(fullfile(root,'src','+femstudy','+studies','independentStaticModal.m'))];
sources=signatures(root,unique(sourcePaths)); [~,rev]=system('git rev-parse HEAD'); [~,gitstatus]=system('git status --short');
p=struct('sources',sources,'matlabVersion',version,'toolboxes',ver,'gitRevision',string(strtrim(rev)), ...
    'gitStatus',string(gitstatus),'staticTrainIDs',S.id,'modalTrainIDs',M.id, ...
    'staticKnownRows',size(stat,1),'modalKnownRows',size(modal,1));
putMat(fullfile(out,'prepared.mat'),p); writeTable(fullfile(out,'source_checksums.csv'),sources);
writeTable(fullfile(out,'training_costs.csv'),models.trainingCosts);
fprintf('Prepared static and modal 128-case designs and frozen-candidate models; no holdout labels.\n');
end

function pilot(root,out,cfg)
p=readMat(fullfile(out,'prepared.mat')); verify(root,p.sources); models=readMat(fullfile(out,'models.mat'));
a=load(fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384','train.mat'),'D'); S=a.D;
a=load(fullfile(root,'experiments','active','modal_frequency_optimizer_20261029_v1','prepared.mat'),'value'); M=a.value;
assert(isempty(intersect(p.staticTrainIDs,p.modalTrainIDs)));
for kind=["static","modal"]
    for seed=[0 42 43 44]
        if kind=="modal"&&seed==0, continue; end
        if kind=="static", x=S.X(1:3,:); else, x=M.X(1:3,:); end
        raw=predict(models,kind,"mlp",seed,x);
        assert(all(isfinite(raw),'all'));
        if kind=="modal", assert(all(raw>0,'all')&&isequal(size(raw),[3 6])); end
    end
    if kind=="static", x=S.X(1:3,:); else, x=M.X(1:3,:); end
    y=predict(models,kind,"gpr",42,x); assert(all(isfinite(y),'all'));
end
ref=S.S(:,1:3); assert(all(fieldmetric(ref,ref,S.w,cfg.staticReferenceNormFloor)==0));
ref=M.F(1:3,:); assert(max(abs(exp(log(ref))./ref-1),[],'all')<1e-12);
before=fileSHA(fullfile(out,'models.mat')); readMat(fullfile(out,'models.mat'));
assert(strcmp(before,fileSHA(fullfile(out,'models.mat'))));
putMat(fullfile(out,'pilot_passed.mat'),struct('sharedPOD',true,'trainScaling',true, ...
    'staticFieldReconstruction',true,'frequencyTransform',true,'metrics',true,'resume',true));
disp('Known-training-case pilot passed; no holdout labels used.');
end

function freeze(root,out,cfg,cfgPath)
p=readMat(fullfile(out,'prepared.mat')); verify(root,p.sources); readMat(fullfile(out,'pilot_passed.mat'));
assert(strcmp(version,p.matlabVersion));
files=[string(fullfile(out,'prepared.mat'));string(fullfile(out,'pilot_passed.mat')); ...
    string(fullfile(out,'models.mat'));string(fullfile(out,'designs.mat'));string(cfgPath);string(fullfile(out,'PROTOCOL.md'))];
f=struct('files',signatures(root,files),'sourceManifestSHA',fileSHA(fullfile(out,'prepared.mat')), ...
    'matlabVersion',version,'frozenAt',string(datetime('now',TimeZone='Europe/Berlin')));
path=fullfile(out,'freeze.mat');
if isfile(path)
    prior=readMat(path); verify(root,prior.files); assert(strcmp(prior.sourceManifestSHA,f.sourceManifestSHA));
else, putMat(path,f); end
disp('Model, design, source and evaluation freeze verified.');
end

function data(root,out,cfg,kind)
f=readMat(fullfile(out,'freeze.mat')); verify(root,f.files);
p=readMat(fullfile(out,'prepared.mat')); verify(root,p.sources);
ds=readMat(fullfile(out,'designs.mat')); d=ds.(kind); folder=fullfile(out,'cases',kind); if ~isfolder(folder), mkdir(folder); end
if kind=="static"
    c=config('smoke'); c.meshDivisor=3; c.gridSize=[21 5 5]; c.geometricOrder="quadratic"; c.maxDeflectionRatio=.02; c.saveRawMesh=false;
end
for i=1:cfg.count
    base=sprintf('case_%07d',d.id(i)); files=dir(fullfile(folder,base+"_attempt*.mat"));
    starts=files(endsWith(string({files.name}),'.started.mat'));
    files=files(~endsWith(string({files.name}),'.started.mat')); done=false;
    for k=1:numel(files)
        a=readMat(fullfile(files(k).folder,files(k).name));
        assert(a.id==d.id(i)&&isequal(a.x,d.X(i,:))&&strcmp(a.freezeSHA,fileSHA(fullfile(out,'freeze.mat'))));
        if a.status=="completed", assert(~done); done=true; end
    end
    if done, continue; end
    attempt=numel(starts)+1;
    path=fullfile(folder,sprintf('%s_attempt%02d.mat',base,attempt));
    startPath=fullfile(folder,sprintf('%s_attempt%02d.started.mat',base,attempt));
    putMat(startPath,struct('id',d.id(i),'x',d.X(i,:),'freezeSHA',fileSHA(fullfile(out,'freeze.mat'))));
    timer=tic;
    try
        if kind=="static", v=solve_case(d.X(i,:),c); assert(numel(v.S)==1575 && all(isfinite(v.S)));
        else, v=femstudy.fem.modal(d.X(i,:),cfg.femModalDivisor); assert(numel(v.frequencyHz)>=6 && all(v.frequencyHz(1:6)>0) && all(diff(v.frequencyHz(1:6))>=0)); end
        a=struct('status',"completed",'id',d.id(i),'x',d.X(i,:),'data',v,'seconds',toc(timer), ...
            'freezeSHA',fileSHA(fullfile(out,'freeze.mat'))); putMat(path,a);
    catch err
        a=struct('status',"failed",'id',d.id(i),'x',d.X(i,:),'seconds',toc(timer), ...
            'error',string(getReport(err,'extended','hyperlinks','off')),'freezeSHA',fileSHA(fullfile(out,'freeze.mat')));
        putMat(path,a); rethrow(err);
    end
    fprintf('%s holdout %d/128: %.2f seconds\n',kind,i,a.seconds);
end
end

function Y=predict(m,kind,model,seed,X)
if kind=="static"
    B=femstudy.fem.beamField(X,m.xi);
    if seed==0, Y=B; return; end
    if model=="gpr", reg=m.staticGPR; else, reg=m.staticMLP{seed-41}; end
    Y=B+m.staticPod.mean+m.staticPod.V*predict_reg(reg,X)';
else
    if model=="gpr", reg=m.modalGPR; else, reg=m.modalMLP{seed-41}; end
    Y=exp(predict_reg(reg,X));
end
end

function evaluate(root,out,cfg)
f=readMat(fullfile(out,'freeze.mat')); verify(root,f.files); p=readMat(fullfile(out,'prepared.mat')); verify(root,p.sources);
d=readMat(fullfile(out,'designs.mat')); m=readMat(fullfile(out,'models.mat'));
cache=fullfile(out,'evaluation_data.mat');
if isfile(cache), result=readMat(cache); exportEvaluation(out,result); return; end
staticCases=table; modalCases=table; times=table; femLedger=table;
for kind=["static","modal"]
    X=d.(kind).X; ids=d.(kind).id; folder=fullfile(out,'cases',kind);
    for i=1:128
        starts=dir(fullfile(folder,sprintf('case_%07d_attempt*.started.mat',ids(i)))); good=[];
        for k=1:numel(starts)
            startPath=string(fullfile(starts(k).folder,starts(k).name)); st=readMat(startPath);
            assert(st.id==ids(i)&&isequal(st.x,X(i,:))&&strcmp(st.freezeSHA,fileSHA(fullfile(out,'freeze.mat'))));
            resultPath=replace(startPath,'.started.mat','.mat'); status="interrupted"; seconds=NaN; err="";
            if isfile(resultPath)
                a=readMat(resultPath); assert(a.id==ids(i)&&isequal(a.x,X(i,:))&&strcmp(a.freezeSHA,st.freezeSHA));
                status=a.status; seconds=a.seconds;
                if status=="completed", assert(isempty(good)); good=a; else, err=a.error; end
            end
            femLedger=[femLedger;table(kind,st.id,string(starts(k).name),status,seconds,err, ...
                VariableNames={'Task','ID','Artifact','Status','Seconds','Error'})]; %#ok<AGROW>
        end
        assert(~isempty(good),'Missing holdout ID %d',ids(i));
        if kind=="static"
            assert(isequal(good.data.xi,m.xi)&&isequal(good.data.w(:),m.w));
            if i==1, reference=zeros(1575,128); end
            reference(:,i)=good.data.S(:);
        else
            if i==1, reference=zeros(128,6); end
            reference(i,:)=good.data.frequencyHz(1:6);
        end
    end
    if kind=="static", kinds=["beam","gpr","mlp","mlp","mlp"]; seeds=[0 42 42 43 44];
    else, kinds=["gpr","mlp","mlp","mlp"]; seeds=[42 42 43 44]; end
    for j=1:numel(kinds)
        model=kinds(j); seed=seeds(j); predict(m,kind,model,seed,X(1,:));
        for i=1:128
            durations=zeros(cfg.predictionRepeats,1);
            for rep=1:cfg.predictionRepeats
                started=tic; y=predict(m,kind,model,seed,X(i,:)); durations(rep)=toc(started);
            end
            times=[times;table(kind,model,seed,ids(i),median(durations),min(durations),max(durations), ...
                VariableNames={'Task','Model','Seed','CaseID','MedianSeconds','MinSeconds','MaxSeconds'})]; %#ok<AGROW>
            if kind=="static"
                ref=reference(:,i); absErr=sqrt(sum(m.w.*(y-ref).^2)); normRef=sqrt(sum(m.w.*ref.^2));
                staticCases=[staticCases;table(model,seed,ids(i),absErr/max(normRef,cfg.staticReferenceNormFloor),absErr,normRef, ...
                    VariableNames={'Model','Seed','CaseID','Relative','Absolute_m','ReferenceNorm_m'})]; %#ok<AGROW>
            else
                truth=reference(i,:); sorted=sort(y,2); pair=diff(y,1,2)<0;
                for z=1:6
                    modalCases=[modalCases;table(model,seed,ids(i),z,truth(z),y(z),sorted(z), ...
                        abs(y(z)-truth(z)),abs(y(z)-truth(z))/truth(z), ...
                        abs(sorted(z)-truth(z)),abs(sorted(z)-truth(z))/truth(z),sum(pair), ...
                        string(sprintf('%d%d%d%d%d',pair)),VariableNames={'Model','Seed','CaseID','Frequency','TruthHz','RawHz','SortedHz', ...
                        'AbsoluteRawHz','RelativeRaw','AbsoluteSortedHz','RelativeSorted','ViolationPairs','PairMask'})]; %#ok<AGROW>
                end
            end
        end
    end
end
assert(height(staticCases)==640&&height(modalCases)==3072&&height(times)==1152);
result=struct('staticCases',staticCases,'modalCases',modalCases,'times',times,'femLedger',femLedger);
putMat(cache,result); exportEvaluation(out,result);
disp('Both independent holdouts evaluated.');
end
function exportEvaluation(out,result)
writeTable(fullfile(out,'static_case_metrics.csv'),result.staticCases); writeTable(fullfile(out,'modal_case_metrics.csv'),result.modalCases);
writeTable(fullfile(out,'prediction_times.csv'),result.times); writeTable(fullfile(out,'fem_attempt_ledger.csv'),result.femLedger);
putMat(fullfile(out,'evaluation_complete.mat'),struct('staticCases',128,'modalCases',128, ...
    'staticRows',height(result.staticCases),'modalRows',height(result.modalCases),'freezeSHA',fileSHA(fullfile(out,'freeze.mat'))));
end

function e=fieldmetric(ref,pred,w,floorValue)
e=sqrt(sum(w(:).*(ref-pred).^2,1))./max(sqrt(sum(w(:).*ref.^2,1)),floorValue);
end
function checkScaling(m,X,Y)
xs=std(X,0,1); xs(xs==0)=1; ys=std(Y,0,1); ys(ys<=1e-12*max(max(abs(Y),[],1),realmin))=1;
assert(isequal(m.xm,mean(X,1))&&isequal(m.xs,xs)&&isequal(m.ym,mean(Y,1))&&isequal(m.ys,ys));
end
function verifyPrior(root,folder,path)
list=readtable(fullfile(folder,'SHA256SUMS.csv'),TextType="string"); rel=replace(extractAfter(string(path),strlength(string(root))+1),'\','/');
names=replace(list.path,'\','/'); hit=names==rel; assert(nnz(hit)==1&&strcmp(fileSHA(path),list.sha256(hit)),'Prior source hash mismatch: %s',path);
end
function t=signatures(root,paths)
hash=strings(numel(paths),1); rel=paths;
for k=1:numel(paths), hash(k)=fileSHA(paths(k)); rel(k)=extractAfter(paths(k),strlength(string(root))+1); end
t=table(rel,hash,VariableNames={'Path','SHA256'});
end
function verify(root,t)
for k=1:height(t), assert(strcmp(fileSHA(fullfile(root,t.Path(k))),t.SHA256(k)),'Frozen source changed: %s',t.Path(k)); end
end
function putMat(path,value)
if isfile(path), old=readMat(path); assert(isequaln(old,value),'Immutable conflict: %s',path); return; end
femstudy.data.saveNew(char(path),value); fid=fopen(string(path)+".sha256",'w'); assert(fid>0); cleaner=onCleanup(@() fclose(fid)); fprintf(fid,'%s',fileSHA(path));
end
function v=readMat(path)
assert(isfile(path)&&isfile(string(path)+".sha256")&&strcmp(strtrim(fileread(string(path)+".sha256")),fileSHA(path)),'Missing or changed artifact: %s',path);
a=load(path,'value'); v=a.value;
end
function writeTable(path,T)
tmp=string(tempname(fileparts(path)))+".csv"; writetable(T,tmp); cleaner=onCleanup(@() deleteTmp(tmp));
if isfile(path), assert(strcmp(fileSHA(path),fileSHA(tmp)),'Existing output conflict: %s',path); else, [ok,msg]=movefile(tmp,path); assert(ok,msg); end
end
function deleteTmp(path), if isfile(path), delete(path); end, end
function h=fileSHA(path)
fid=fopen(path,'r'); assert(fid>=0,'Missing file: %s',path); cleaner=onCleanup(@() fclose(fid)); md=java.security.MessageDigest.getInstance('SHA-256');
while true, b=fread(fid,1048576,'*uint8'); if isempty(b), break; end; md.update(b); end
h=string(lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[])));
end
