function sampling48(root,stage)
cfgPath=fullfile(root,'configs','restfield_sampling48_20261028_v1.json');
cfg=jsondecode(fileread(cfgPath));
out=fullfile(root,'experiments','active',cfg.study);
assert(isfolder(out),'Protocol folder is missing.');
if stage=="prepare"
    prepare(root,out,cfg,cfgPath);
    return
end
manifest=readMat(fullfile(out,'manifest.mat'));
verifyFiles(root,manifest.sources);
assert(strcmp(manifest.matlabVersion,version),'MATLAB version changed.');
designs=readMat(fullfile(out,'designs.mat'));
validation=readMat(fullfile(out,'validation.mat'));
switch stage
    case "pilot"
        d=designs(1); D=ensureData(out,cfg,d,manifest);
        p=ensurePrep(out,cfg,d,D);
        a=fitRun(out,cfg,d,p,validation,manifest,"mlp",42,"pilot_a",10);
        b=fitRun(out,cfg,d,p,validation,manifest,"mlp",42,"pilot_b",10);
        g=fitRun(out,cfg,d,p,validation,manifest,"gpr",42,"pilot_gpr",250);
        assert(strcmp(a.model.initialWeightsHash,b.model.initialWeightsHash));
        ya=predict_reg(a.model,validation.X); yb=predict_reg(b.model,validation.X);
        assert(norm(ya-yb,'fro')<=1e-10*max(norm(ya,'fro'),realmin));
        checkRepresentation(p,D,validation,a,g,cfg);
        before=treeSignatures(fullfile(out,'attempts'));
        ensureData(out,cfg,d,manifest);
        fitRun(out,cfg,d,p,validation,manifest,"mlp",42,"pilot_a",10);
        assert(isequal(before,treeSignatures(fullfile(out,'attempts'))));
        checks=struct('designReproduction',true,'splitSeparation',true, ...
            'trainOnlyPreprocessing',true,'sharedScaling',true, ...
            'reconstructionAndMetrics',true,'initializationReproduction',true, ...
            'unchangedArtifactsOnResume',true,'excludedFromCampaign',true);
        putMat(fullfile(out,'pilot_passed.mat'),checks);
        disp('Pilot passed, including repeat initialization and artifact hashes.');
    case "data"
        readMat(fullfile(out,'pilot_passed.mat'));
        for k=1:numel(designs)
            D=ensureData(out,cfg,designs(k),manifest);
            ensurePrep(out,cfg,designs(k),D);
        end
    case "campaign"
        readMat(fullfile(out,'pilot_passed.mat'));
        for k=1:numel(designs)
            d=designs(k);
            D=readMat(fullfile(out,'training',d.name+'.mat'));
            p=ensurePrep(out,cfg,d,D);
            fitRun(out,cfg,d,p,validation,manifest,"gpr",cfg.gprSeed,"campaign",cfg.mlp.budget);
            for seed=reshape(cfg.seeds,1,[])
                fitRun(out,cfg,d,p,validation,manifest,"mlp",seed,"campaign",cfg.mlp.budget);
            end
        end
    case {"evaluate","audit"}
        evaluate(root,out,cfg,designs,validation,manifest);
    otherwise
        error('Unknown study stage: %s',stage);
end
end

function prepare(root,out,cfg,cfgPath)
manifestPath=fullfile(out,'manifest.mat');
if isfile(manifestPath)
    m=readMat(manifestPath); verifyFiles(root,m.sources);
    readMat(fullfile(out,'designs.mat')); readMat(fullfile(out,'validation.mat'));
    fprintf('Prepared design and provenance verified; no new artifacts.\n');
    return
end
oldRoot=fullfile(root,'experiments','active',cfg.sourceStudy);
oldCfgPath=fullfile(root,'configs',string(cfg.sourceStudy)+".json");
old=jsondecode(fileread(oldCfgPath));
for name=["parameterNames","lower","upper","seeds","pod","mlp","gprKernel","metricFloor"]
    assert(isequaln(cfg.(name),old.(name)),'Prior configuration mismatch: %s',name);
end
c=femConfig(cfg);
assert(isequal(c.gridSize,[21 5 5]) && c.meshDivisor==3 && c.geometricOrder=="quadratic");

% Only designs, never old holdout field labels, enter the exclusion inventory.
files=[dir(fullfile(root,'experiments','**','*design*.csv')); ...
    dir(fullfile(root,'runs','**','*design*.csv')); ...
    dir(fullfile(root,'configs','designs','*.csv'))];
known=table; knownIDs=[]; paths=strings(0,1);
names=cellstr(string(cfg.parameterNames(:)'));
for k=1:numel(files)
    path=string(fullfile(files(k).folder,files(k).name));
    if startsWith(path,string(out)), continue; end
    t=readtable(path,TextType="string"); vars=string(t.Properties.VariableNames);
    idcol=find(strcmpi(vars,'id'),1);
    if isempty(idcol), continue; end
    id=t{:,idcol}; assert(isnumeric(id)&&all(isfinite(id)));
    knownIDs=[knownIDs;id(:)]; %#ok<AGROW>
    paths(end+1,1)=path; %#ok<AGROW>
    if all(ismember(string(names),vars))
        q=array2table(t{:,names},VariableNames=names);
        q.ID=id(:); q.Source=repmat(path,height(t),1);
        known=[known;q]; %#ok<AGROW>
    end
end
assert(~isempty(known) && all(ismember((800001:800128)',knownIDs)), ...
    'Development validation design missing from exclusion inventory.');
assert(all(ismember((700001:700064)',knownIDs)) && ...
    all(ismember((200001:200064)',knownIDs)),'Known test cohort is missing.');
lo=cfg.lower(:)'; span=cfg.upper(:)'-lo;
K=(known{:,names}-lo)./span;
assert(all(isfinite(K),'all'));
designs=repmat(struct('name',"",'strategy',"",'seed',0,'id',[], ...
    'X',[],'U',[],'minimumKnownDistance',0,'minimumPairDistance',0),6,1);
allX=[]; allIDs=[];
for k=1:6
    d=designs(k); d.name=string(cfg.designNames{k});
    d.strategy=string(cfg.strategies{k}); d.seed=cfg.designSeeds(k);
    U=generateDesign(cfg,d.strategy,d.seed);
    assert(isequal(U,generateDesign(cfg,d.strategy,d.seed)),'Design is not reproducible.');
    if d.strategy=="lhs"
        for j=1:6, assert(isequal(sort(floor(48*U(:,j))),(0:47)')); end
    end
    d.id=(cfg.idStart+(k-1)*48:cfg.idStart+k*48-1)';
    d.U=U; d.X=lo+U.*span;
    distance=pdist2(U,K,'chebychev'); d.minimumKnownDistance=min(distance,[],'all');
    pair=pdist2(U,U,'chebychev'); pair(1:49:end)=Inf;
    d.minimumPairDistance=min(pair,[],'all');
    assert(d.minimumKnownDistance>cfg.duplicateToleranceNormalized && ...
        d.minimumPairDistance>cfg.duplicateToleranceNormalized);
    assert(isempty(intersect(d.id,knownIDs)));
    allX=[allX;U]; allIDs=[allIDs;d.id]; %#ok<AGROW>
    designs(k)=d;
end
cross=pdist2(allX,allX,'chebychev'); cross(1:289:end)=Inf;
assert(min(cross,[],'all')>cfg.duplicateToleranceNormalized && numel(unique(allIDs))==288);
putMat(fullfile(out,'designs.mat'),designs);
for k=1:6
    d=designs(k); t=array2table([d.id d.X],VariableNames=[{'ID'} names]);
    t.Design=repmat(d.name,48,1); t.Strategy=repmat(d.strategy,48,1);
    t.DesignSeed=repmat(d.seed,48,1); t.Split=repmat("training",48,1);
    putTable(fullfile(out,'designs',d.name+'.csv'),t);
end
putTable(fullfile(out,'known_static_design_inventory.csv'),known);
putMat(fullfile(out,'known_ids.mat'),unique(knownIDs));

% Verify the inherited development labels against the prior frozen checksums.
ledger=readtable(fullfile(oldRoot,'development_fem_ledger.csv'),TextType="string");
ledger=ledger(ledger.Status=="success",:); ledger=sortrows(ledger,'ID');
assert(isequal(ledger.ID,(800001:800128)'));
design=readtable(fullfile(oldRoot,'development_validation_design.csv'));
checksums=readtable(fullfile(oldRoot,'SHA256SUMS.csv'),TextType="string");
V=struct('id',ledger.ID,'X',design{:,names},'S',zeros(1575,128),'xi',[],'w',[]);
for k=1:128
    path=string(fullfile(oldRoot,'development_cases',ledger.Artifact(k)));
    suffix="/development_cases/"+ledger.Artifact(k);
    row=endsWith(replace(string(checksums.path),'\','/'),suffix);
    assert(nnz(row)==1 && strcmp(fileSHA(path),checksums.sha256(row)),'Validation hash mismatch.');
    a=load(path,'value'); v=a.value;
    assert(v.status=="success" && v.id==V.id(k) && isequal(v.x,V.X(k,:)));
    if k==1, V.xi=v.xi; V.w=v.w(:); else, assert(isequal(V.xi,v.xi)&&isequal(V.w,v.w(:))); end
    V.S(:,k)=v.S(:); paths(end+1,1)=path; %#ok<AGROW>
end
assert(all(isfinite(V.S),'all'));
putMat(fullfile(out,'validation.mat'),V);
plan=table;
for k=1:6
    for model=["gpr","mlp"]
        seeds=cfg.gprSeed; if model=="mlp", seeds=reshape(cfg.seeds,1,[]); end
        for seed=seeds
            row=table(designs(k).name,designs(k).strategy,designs(k).seed,model,seed,"planned", ...
                VariableNames={'Design','Strategy','DesignSeed','Model','Seed','Status'});
            plan=[plan;row]; %#ok<AGROW>
        end
    end
end
assert(height(plan)==24); putTable(fullfile(out,'planned_runs.csv'),plan);
sourceFiles=dir(fullfile(root,'src','**','*.m'));
for k=1:numel(sourceFiles), paths(end+1,1)=string(fullfile(sourceFiles(k).folder,sourceFiles(k).name)); end %#ok<AGROW>
paths=[paths;string(cfgPath);string(oldCfgPath);string(fullfile(root,'config.m')); ...
    string(fullfile(root,'scripts','matlab','run_restfield_sampling48.m')); ...
    string(fullfile(out,'PROTOCOL.md'));string(fullfile(out,'designs.mat')); ...
    string(fullfile(out,'validation.mat'));string(fullfile(out,'planned_runs.csv')); ...
    string(fullfile(oldRoot,'SHA256SUMS.csv'));string(fullfile(oldRoot,'summary.csv'))];
sources=fileSignatures(root,unique(paths));
[~,revision]=system('git rev-parse HEAD'); [~,status]=system('git status --short');
m=struct('sources',sources,'matlabVersion',version,'toolboxes',ver,'computer',computer, ...
    'processor',string(getenv('PROCESSOR_IDENTIFIER')),'gitRevision',string(strtrim(revision)), ...
    'gitStatus',string(status),'femConfig',c,'preparedAt',timestamp(), ...
    'minimumAllDesignDistance',min(cross,[],'all'),'configSHA256',fileSHA(cfgPath));
putMat(manifestPath,m); putTable(fullfile(out,'source_checksums.csv'),sources);
fprintf('Six designs frozen: 288 distinct training IDs; %d known static rows excluded.\n',height(known));
end

function U=generateDesign(cfg,strategy,seed)
rng(seed,cfg.rng);
if strategy=="uniform"
    U=rand(cfg.countPerDesign,6);
else
    U=lhsdesign(cfg.countPerDesign,6,'Criterion',cfg.lhs.criterion, ...
        'Iterations',cfg.lhs.iterations,'Smooth',cfg.lhs.smooth);
end
end

function c=femConfig(cfg)
c=config(cfg.fem.mode); c.meshDivisor=cfg.fem.meshDivisor;
c.geometricOrder=string(cfg.fem.geometricOrder); c.gridSize=cfg.fem.gridSize(:)';
c.saveRawMesh=cfg.fem.saveRawMesh; c.maxDeflectionRatio=cfg.fem.maxDeflectionRatio;
end

function D=ensureData(out,cfg,d,manifest)
path=fullfile(out,'training',d.name+'.mat');
if isfile(path)
    D=readMat(path); assert(isequal(D.id,d.id)&&isequal(D.X,d.X));
    verifyAbsoluteFiles(D.sources); return
end
c=femConfig(cfg); assert(isequaln(c,manifest.femConfig));
D=struct('id',d.id,'X',d.X,'S',zeros(1575,48),'xi',[],'w',[],'sources',table);
for k=1:48
    context=struct('design',d.name,'id',d.id(k),'x',d.X(k,:), ...
        'manifestSHA',fileSHA(fullfile(out,'manifest.mat')));
    base="fem_"+string(d.id(k));
    [result,resultPath,done]=beginAttempt(out,base,context);
    if ~done
        timer=tic;
        try
            v=solve_case(d.X(k,:),c); v.seconds=toc(timer);
            assert(numel(v.S)==1575 && all(isfinite(v.S)) && all(isfinite(v.Y)));
            result=struct('status',"completed",'context',context,'data',v, ...
                'seconds',toc(timer),'finishedAt',timestamp());
            putMat(resultPath,result);
        catch err
            saveFailure(resultPath,context,timer,err); rethrow(err);
        end
        fprintf('%s FEM %d/48 (ID %d): %.2f s\n',d.name,k,d.id(k),result.seconds);
    end
    v=result.data;
    assert(isequal(v.x,d.X(k,:)));
    if k==1, D.xi=v.xi; D.w=v.w(:); else, assert(isequal(D.xi,v.xi)&&isequal(D.w,v.w(:))); end
    D.S(:,k)=v.S(:);
    D.sources=[D.sources;table(string(resultPath),fileSHA(resultPath),VariableNames={'Path','SHA256'})]; %#ok<AGROW>
end
putMat(path,D);
end

function p=ensurePrep(out,cfg,d,D)
path=fullfile(out,'preprocessing',d.name+'.mat');
if isfile(path)
    p=readMat(path); assert(isequal(p.trainIDs,D.id)&&isequal(p.trainX,D.X));
    assert(strcmp(p.trainingSHA,fileSHA(fullfile(out,'training',d.name+'.mat'))));
    return
end
R=D.S-femstudy.fem.beamField(D.X,D.xi);
P=pod_fit(R,D.w,min(cfg.pod.maxRank,numel(D.id)-1));
r=find(P.energy>=cfg.pod.energy,1); if isempty(r)||r>P.r, r=P.r; end
P.V=P.V(:,1:r); P.r=r; P.selectedEnergy=P.energy(r);
p=struct('trainIDs',D.id,'trainX',D.X,'xi',D.xi,'weights',D.w,'pod',P, ...
    'coefficients',pod_encode(P,R),'trainingSHA',fileSHA(fullfile(out,'training',d.name+'.mat')));
assert(r<=47 && r<=32 && norm(P.V'*(D.w.*P.V)-eye(r),'fro')<1e-10);
putMat(path,p);
end

function record=fitRun(out,cfg,d,p,V,manifest,kind,seed,stage,budget)
context=struct('design',d.name,'strategy',d.strategy,'designSeed',d.seed, ...
    'kind',kind,'seed',seed,'stage',stage,'budget',budget, ...
    'configSHA',manifest.configSHA256,'manifestSHA',fileSHA(fullfile(out,'manifest.mat')), ...
    'preprocessingSHA',fileSHA(fullfile(out,'preprocessing',d.name+'.mat')), ...
    'validationSHA',fileSHA(fullfile(out,'validation.mat')));
base=stage+"_"+d.name+"_"+kind+"_"+string(seed);
[record,path,done]=beginAttempt(out,base,context); if done, return; end
timer=tic;
try
    history=struct; options=struct;
    if kind=="mlp"
        options=struct('HiddenLayers',cfg.mlp.layers(:)','Optimizer',"lbfgs",'Seed',seed, ...
            'Budget',budget,'BatchSize',cfg.mlp.batchSize,'InitialLearnRate',cfg.mlp.learningRate, ...
            'L2Regularization',cfg.mlp.l2,'HistorySize',cfg.mlp.historySize, ...
            'GradientTolerance',cfg.mlp.gradientTolerance,'StepTolerance',cfg.mlp.stepTolerance);
        [model,history]=femstudy.models.fitControlledRestMLP(p.trainX,p.coefficients,options);
        seconds=model.trainingSeconds; reason=string(history.stopReason);
    else
        rng(seed,cfg.rng); fitTimer=tic;
        model=fit_gps(p.trainX,p.coefficients,cfg.gprKernel);
        seconds=toc(fitTimer); reason="GPR fit returned; convergence not separately certified";
    end
    checkScaling(model,p);
    B=femstudy.fem.beamField(V.X,p.xi);
    prediction=B+p.pod.mean+p.pod.V*predict_reg(model,V.X)';
    M=metrics(V.S,prediction,V.w,cfg.metricFloor); M.CaseID=V.id;
    proj=B+p.pod.mean+p.pod.V*pod_encode(p.pod,V.S-B)';
    PM=metrics(V.S,proj,V.w,cfg.metricFloor);
    M.ProjectionRelative=PM.Relative; M.ProjectionAbsolute_m=PM.Absolute_m;
    assert(isequal(p.xi,V.xi)&&isequal(p.weights,V.w)&&isempty(intersect(p.trainIDs,V.id)));
    record=struct('status',"completed",'context',context,'model',model,'options',options, ...
        'history',history,'metrics',M,'trainingSeconds',seconds,'seconds',toc(timer), ...
        'stopReason',reason,'convergence',convergence(reason,kind),'podRank',p.pod.r, ...
        'podEnergy',p.pod.selectedEnergy,'trainIDs',p.trainIDs,'validationIDs',V.id, ...
        'finishedAt',timestamp());
    putMat(path,record);
    fprintf('%s %s %s seed %d: %.2f s; %s\n',stage,d.name,kind,seed,seconds,reason);
catch err
    saveFailure(path,context,timer,err); rethrow(err);
end
end

function checkScaling(model,p)
xm=mean(p.trainX,1); xs=std(p.trainX,0,1); xs(xs==0)=1;
ym=mean(p.coefficients,1); ys=std(p.coefficients,0,1);
ys(ys<=1e-12*max(max(abs(p.coefficients),[],1),realmin))=1;
assert(isequal(model.xm,xm)&&isequal(model.xs,xs)&&isequal(model.ym,ym)&&isequal(model.ys,ys), ...
    'Scaling is not exactly training-derived.');
end

function checkRepresentation(p,D,V,a,g,cfg)
assert(isempty(intersect(D.id,V.id)) && numel(unique(D.id))==48);
assert(isequal(a.trainIDs,g.trainIDs)&&isequal(a.validationIDs,g.validationIDs));
for f=["xm","xs","ym","ys"], assert(isequal(a.model.(f),g.model.(f))); end
assert(isequal(a.metrics.ProjectionRelative,g.metrics.ProjectionRelative));
R=D.S-femstudy.fem.beamField(D.X,D.xi);
assert(isequal(p.pod.mean,mean(R,2)) && isequal(p.coefficients,pod_encode(p.pod,R)));
assert(norm(p.pod.V'*(D.w.*p.pod.V)-eye(p.pod.r),'fro')<1e-10);
assert(norm(pod_encode(p.pod,p.pod.mean+p.pod.V*p.coefficients')-p.coefficients,'fro') ...
    <1e-10*max(norm(p.coefficients,'fro'),realmin));
z=metrics(V.S,V.S,V.w,cfg.metricFloor); assert(all(z.Relative==0));
z=metrics(V.S,2*V.S,V.w,cfg.metricFloor); assert(max(abs(z.Relative-1))<1e-12);
assert(all(abs(a.metrics.Relative-a.metrics.Absolute_m./max(a.metrics.ReferenceNorm_m,cfg.metricFloor))<1e-12));
end

function M=metrics(reference,prediction,w,floorValue)
assert(isequal(size(reference),size(prediction))&&all(isfinite(prediction),'all') ...
    &&all(isfinite(reference),'all')&&all(w>0));
absolute=sqrt(sum(w(:).*(prediction-reference).^2,1))';
referenceNorm=sqrt(sum(w(:).*reference.^2,1))';
M=table(absolute./max(referenceNorm,floorValue),absolute,referenceNorm, ...
    VariableNames={'Relative','Absolute_m','ReferenceNorm_m'});
end

function label=convergence(reason,kind)
if kind=="gpr", label="not_separately_certified";
elseif contains(reason,"Suitable learning rate not found",IgnoreCase=true), label="line_search_failed";
elseif contains(reason,"Max iterations",IgnoreCase=true), label="budget_limit";
elseif contains(reason,"tolerance",IgnoreCase=true), label="trainer_tolerance_stop";
else, label="not_confirmed";
end
end

function [result,path,done]=beginAttempt(out,base,context)
folder=fullfile(out,'attempts',base); if ~isfolder(folder), mkdir(folder); end
starts=dir(fullfile(folder,'attempt_*.start.mat')); result=struct; done=false; path="";
for k=1:numel(starts)
    startPath=fullfile(starts(k).folder,starts(k).name); s=readMat(startPath);
    assert(isequaln(s.context,context),'Attempt context changed: %s',startPath);
    rp=replace(string(startPath),'.start.mat','.result.mat');
    if ~isfile(rp), continue; end
    r=readMat(rp); assert(isequaln(r.context,context));
    if r.status=="completed"
        assert(~done,'Multiple successful attempts for %s',base);
        result=r; path=rp; done=true;
    else
        assert(r.status=="failed",'Unknown terminal status');
    end
end
if done, return; end
number=numel(starts)+1; stem=fullfile(folder,sprintf('attempt_%03d',number));
putMat(stem+".start.mat",struct('context',context,'startedAt',timestamp()));
path=stem+".result.mat";
end

function saveFailure(path,context,timer,err)
if isfile(path), rethrow(err); end
record=struct('status',"failed",'context',context,'seconds',toc(timer), ...
    'errorIdentifier',string(err.identifier),'error',string(getReport(err,'extended','hyperlinks','off')), ...
    'finishedAt',timestamp());
putMat(path,record);
end

function evaluate(root,out,cfg,designs,V,manifest)
summary=table; cases=table; historyTable=table;
for k=1:6
    d=designs(k); D=readMat(fullfile(out,'training',d.name+'.mat'));
    verifyAbsoluteFiles(D.sources);
    p=readMat(fullfile(out,'preprocessing',d.name+'.mat'));
    g=[];
    for kind=["gpr","mlp"]
        seeds=cfg.gprSeed; if kind=="mlp", seeds=reshape(cfg.seeds,1,[]); end
        for seed=seeds
            base="campaign_"+d.name+"_"+kind+"_"+string(seed);
            files=dir(fullfile(out,'attempts',base,'*.result.mat')); values=cell(numel(files),1);
            good=false(numel(files),1);
            for j=1:numel(files)
                values{j}=readMat(fullfile(files(j).folder,files(j).name));
                good(j)=values{j}.status=="completed";
            end
            assert(nnz(good)==1,'Missing or duplicate completed run: %s',base);
            r=values{find(good,1)};
            assert(strcmp(r.context.manifestSHA,fileSHA(fullfile(out,'manifest.mat'))));
            assert(strcmp(r.context.preprocessingSHA,fileSHA(fullfile(out,'preprocessing',d.name+'.mat'))));
            assert(strcmp(r.context.validationSHA,fileSHA(fullfile(out,'validation.mat'))));
            checkScaling(r.model,p);
            if kind=="gpr", g=r; else, checkRepresentation(p,D,V,r,g,cfg); end
            B=femstudy.fem.beamField(V.X,V.xi);
            Y=B+p.pod.mean+p.pod.V*predict_reg(r.model,V.X)';
            fresh=metrics(V.S,Y,V.w,cfg.metricFloor);
            assert(isequaln(fresh,r.metrics(:,fresh.Properties.VariableNames)), ...
                'Stored metrics differ from reconstructed field.');
            M=r.metrics;
            iterations=0; initialHash="";
            if kind=="mlp"
                h=r.history; iterations=numel(h.iteration); initialHash=string(r.model.initialWeightsHash);
                if iterations>0
                    epoch=nan(iterations,1); loss=nan(iterations,1);
                    if numel(h.epoch)==iterations, epoch=h.epoch(:); end
                    if numel(h.trainingLoss)==iterations, loss=h.trainingLoss(:); end
                    ht=table(repmat(base,iterations,1),h.iteration(:),epoch,loss, ...
                        VariableNames={'RunID','Iteration','Epoch','TrainingLoss'});
                    historyTable=[historyTable;ht]; %#ok<AGROW>
                end
            end
            v=struct('Design',d.name,'Strategy',d.strategy,'DesignSeed',d.seed,'Model',kind, ...
                'Seed',seed,'PODRank',r.podRank,'PODEnergy',r.podEnergy, ...
                'MeanRelative',mean(M.Relative),'MedianRelative',median(M.Relative), ...
                'P95Relative',nearest(M.Relative),'MaxRelative',max(M.Relative), ...
                'MeanAbsolute_m',mean(M.Absolute_m),'MedianAbsolute_m',median(M.Absolute_m), ...
                'P95Absolute_m',nearest(M.Absolute_m),'MaxAbsolute_m',max(M.Absolute_m), ...
                'MeanProjectionRelative',mean(M.ProjectionRelative),'MedianProjectionRelative',median(M.ProjectionRelative), ...
                'P95ProjectionRelative',nearest(M.ProjectionRelative),'MaxProjectionRelative',max(M.ProjectionRelative), ...
                'MeanProjectionAbsolute_m',mean(M.ProjectionAbsolute_m), ...
                'P95ProjectionAbsolute_m',nearest(M.ProjectionAbsolute_m), ...
                'TrainingSeconds',r.trainingSeconds,'Iterations',iterations, ...
                'StopReason',r.stopReason,'Convergence',r.convergence, ...
                'MeetsTarget',nearest(M.Relative)<=cfg.targetP95,'InitialWeightsSHA256',initialHash);
            summary=[summary;struct2table(v)]; %#ok<AGROW>
            M.Design=repmat(d.name,height(M),1); M.Strategy=repmat(d.strategy,height(M),1);
            M.Model=repmat(kind,height(M),1); M.Seed=repmat(seed,height(M),1);
            cases=[cases;M]; %#ok<AGROW>
        end
    end
end
assert(height(summary)==24 && height(cases)==3072);
assert(nnz(summary.Model=="mlp")==18 && nnz(summary.Model=="gpr")==6);
mlp=summary(summary.Model=="mlp",:);
designSummary=groupsummary(mlp,["Strategy","Design"],["mean","std","min","max"],"P95Relative");
designSummary.AllSeedsPass=designSummary.max_P95Relative<=cfg.targetP95;
strategySummary=groupsummary(designSummary,"Strategy",["mean","std","min","max"], ...
    ["mean_P95Relative","max_P95Relative"]);
passCounts=groupsummary(summary,["Strategy","Model"],"sum","MeetsTarget");
designPassCounts=groupsummary(designSummary,"Strategy","sum","AllSeedsPass");
[ledger,femLedger]=attemptTables(out);
assert(nnz(ledger.Stage=="campaign" & ledger.Status=="completed")==24);
assert(nnz(femLedger.Status=="completed")==288);
value=struct('summary',summary,'cases',cases,'history',historyTable, ...
    'designSummary',designSummary,'strategySummary',strategySummary, ...
    'passCounts',passCounts,'designPassCounts',designPassCounts, ...
    'attemptLedger',ledger,'femLedger',femLedger,'manifestSHA',fileSHA(fullfile(out,'manifest.mat')));
putMat(fullfile(out,'evaluation.mat'),value);
putTable(fullfile(out,'summary.csv'),summary); putTable(fullfile(out,'case_metrics.csv'),cases);
putTable(fullfile(out,'training_history.csv'),historyTable);
putTable(fullfile(out,'design_summary.csv'),designSummary); putTable(fullfile(out,'strategy_summary.csv'),strategySummary);
putTable(fullfile(out,'target_counts.csv'),passCounts); putTable(fullfile(out,'design_target_counts.csv'),designPassCounts);
putTable(fullfile(out,'attempt_ledger.csv'),ledger); putTable(fullfile(out,'fem_ledger.csv'),femLedger);
old=readtable(fullfile(root,'experiments','active',cfg.sourceStudy,'summary.csv'),TextType="string");
old=old(old.N==48,:); putTable(fullfile(out,'historical_n48_summary.csv'),old);
assert(strcmp(manifest.configSHA256,fileSHA(fullfile(root,'configs',string(cfg.study)+".json"))));
putMat(fullfile(out,'audit_passed.mat'),struct('runs',24,'developmentCaseRows',3072, ...
    'femCases',288,'reconstructionRechecked',true,'sharedScalingRechecked',true, ...
    'noIncompleteDesign',true,'manifestSHA',fileSHA(fullfile(out,'manifest.mat'))));
disp(passCounts); disp(designPassCounts);
end

function [ledger,femLedger]=attemptTables(out)
files=dir(fullfile(out,'attempts','**','*.start.mat')); ledger=table; femLedger=table;
for k=1:numel(files)
    startPath=fullfile(files(k).folder,files(k).name); s=readMat(startPath); c=s.context;
    path=replace(string(startPath),'.start.mat','.result.mat');
    status="interrupted_without_result"; elapsed=NaN; fit=NaN; stop=""; err=""; finished="";
    if isfile(path)
        r=readMat(path); status=r.status; elapsed=r.seconds; finished=r.finishedAt;
        if status=="failed", err=r.error;
        elseif isfield(r,'trainingSeconds'), fit=r.trainingSeconds; stop=r.stopReason;
        end
    end
    if isfield(c,'kind')
        row=table(c.design,c.strategy,c.designSeed,c.kind,c.seed,c.stage,status, ...
            elapsed,fit,stop,err,string(startPath),path,s.startedAt,finished, ...
            VariableNames={'Design','Strategy','DesignSeed','Model','Seed','Stage','Status', ...
            'ElapsedSeconds','TrainingSeconds','StopReason','Error','StartArtifact','ResultArtifact','StartedAt','FinishedAt'});
        ledger=[ledger;row]; %#ok<AGROW>
    else
        row=table(c.design,c.id,status,elapsed,err,string(startPath),path,s.startedAt,finished, ...
            VariableNames={'Design','ID','Status','Seconds','Error','StartArtifact','ResultArtifact','StartedAt','FinishedAt'});
        femLedger=[femLedger;row]; %#ok<AGROW>
    end
end
end

function q=nearest(x)
x=sort(x); q=x(ceil(.95*numel(x)));
end

function putMat(path,value)
if isfile(path)
    old=readMat(path); assert(isequaln(old,value),'Immutable artifact conflict: %s',path); return
end
femstudy.data.saveNew(char(path),value);
putText(string(path)+".sha256",fileSHA(path));
end

function value=readMat(path)
assert(isfile(path),'Required artifact missing: %s',path);
assert(isfile(string(path)+".sha256"),'Missing integrity seal: %s',path);
assert(strcmp(strtrim(fileread(string(path)+".sha256")),fileSHA(path)),'Artifact checksum mismatch: %s',path);
a=load(path,'value'); value=a.value;
end

function putTable(path,value)
folder=fileparts(path); if ~isfolder(folder), mkdir(folder); end
tmp=string(tempname(folder))+".csv"; writetable(value,tmp);
cleanup=onCleanup(@() removeTemp(tmp));
if isfile(path)
    assert(strcmp(fileSHA(path),fileSHA(tmp)),'Immutable table conflict: %s',path);
else
    [ok,msg]=movefile(tmp,path); assert(ok,msg);
end
end

function removeTemp(path)
if isfile(path), delete(path); end
end

function putText(path,text)
if isfile(path), assert(strcmp(fileread(path),char(text))); return; end
fid=fopen(path,'w','n','UTF-8'); assert(fid>=0); cleaner=onCleanup(@() fclose(fid));
fprintf(fid,'%s',text);
end

function verifyFiles(root,t)
for k=1:height(t)
    p=fullfile(root,t.Path(k)); assert(strcmp(fileSHA(p),t.SHA256(k)),'Provenance mismatch: %s',p);
end
end

function verifyAbsoluteFiles(t)
for k=1:height(t), assert(strcmp(fileSHA(t.Path(k)),t.SHA256(k))); end
end

function t=fileSignatures(root,paths)
hashes=strings(numel(paths),1); rel=strings(numel(paths),1);
for k=1:numel(paths)
    hashes(k)=fileSHA(paths(k)); rel(k)=extractAfter(string(paths(k)),strlength(string(root))+1);
end
t=table(rel,hashes,VariableNames={'Path','SHA256'});
end

function t=treeSignatures(folder)
files=dir(fullfile(folder,'**','*')); files=files(~[files.isdir]);
paths=strings(numel(files),1); hashes=paths;
for k=1:numel(files), paths(k)=string(fullfile(files(k).folder,files(k).name)); hashes(k)=fileSHA(paths(k)); end
t=sortrows(table(paths,hashes),'paths');
end

function hash=fileSHA(path)
fid=fopen(path,'r'); assert(fid>=0,'Cannot open %s',path); cleaner=onCleanup(@() fclose(fid));
md=java.security.MessageDigest.getInstance('SHA-256');
while true
    b=fread(fid,1048576,'*uint8'); if isempty(b), break; end
    md.update(b);
end
hash=string(lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[])));
end

function text=timestamp()
text=string(datetime('now',TimeZone='Europe/Berlin',Format='yyyy-MM-dd HH:mm:ss Z'));
end
