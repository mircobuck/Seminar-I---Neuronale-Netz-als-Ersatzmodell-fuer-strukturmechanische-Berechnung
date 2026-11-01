function run_restfield_learning_curve(stage)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
out=fullfile(root,'experiments','active','restfield_learning_curve_20261028_v1');
cp=fullfile(root,'configs','restfield_learning_curve_20261028_v1.json'); cfg=jsondecode(fileread(cp));
switch string(stage)
 case "prepare", prepare(root,out,cfg,cp);
 case "fem", fem(root,out,cfg,cp);
 case "pilot", campaign(root,out,cfg,cp,true);
 case "campaign", campaign(root,out,cfg,cp,false);
 case "evaluate", evaluate(out,cfg);
 otherwise, error('Unknown stage');
end
end
function prepare(root,out,cfg,cp)
p=fullfile(out,'prepared.mat'); if isfile(p), verify(root,out,cp); return; end
source=fullfile(root,'experiments','active','training_size_12_24_48_20261023');
a=load(fullfile(source,'n384','train.mat'),'D'); D=a.D; ids=[]; X=[];
for n=reshape(cfg.sizes,1,[])
 b=load(fullfile(source,sprintf('n%d',n),'train.mat'),'D'); d=b.D;
 expected=[(1:12)';(25:n+12)']; assert(isequal(d.id(:),expected));
 [found,ix]=ismember(d.id,D.id); assert(all(found)&&isequal(d.X,D.X(ix,:))&&isequal(d.S,D.S(:,ix))); 
end
for f={'train.mat','val.mat','test.mat'}
 b=load(fullfile(source,'n384',f{1}),'D'); ids=[ids;b.D.id(:)]; X=[X;b.D.X]; %#ok<AGROW>
end
files=dir(fullfile(root,'experiments','active','**','*design.csv'));
for k=1:numel(files)
 t=readtable(fullfile(files(k).folder,files(k).name));
 if all(ismember([{'id'};cellstr(cfg.parameterNames(:))],t.Properties.VariableNames'))
  ids=[ids;t.id]; X=[X;t{:,cellstr(cfg.parameterNames)}]; %#ok<AGROW>
 end
end
lo=cfg.lower(:)'; hi=cfg.upper(:)'; rng(cfg.validation.seed,'twister');
U=lhsdesign(cfg.validation.count,6,'Criterion','maximin','Iterations',cfg.validation.iterations);
V=lo+U.*(hi-lo); vi=(cfg.validation.idStart:cfg.validation.idStart+cfg.validation.count-1)';
assert(isempty(intersect(ids,vi))); dist=pdist2((V-lo)./(hi-lo),(X-lo)./(hi-lo),'chebychev');
assert(min(dist,[],'all')>cfg.validation.minNormalizedChebyshev);
w=pdist2(U,U,'chebychev'); w(1:size(w,1)+1:end)=Inf; assert(min(w,[],'all')>cfg.validation.minNormalizedChebyshev);
t=array2table([vi V],'VariableNames',[{'id'} cellstr(cfg.parameterNames(:)')]); t.split=repmat("development_validation",height(t),1);
design=fullfile(out,'development_validation_design.csv'); assert(~isfile(design)); writetable(t,design);
paths=[string(cp);string(fullfile(out,'PROTOCOL.md'));string(mfilename('fullpath')+".m");string(fullfile(source,'n384','train.mat'))];
for n=reshape(cfg.sizes,1,[]), paths(end+1)=string(fullfile(source,sprintf('n%d',n),'train.mat')); end
for k=1:numel(files), paths(end+1)=string(fullfile(files(k).folder,files(k).name)); end
paths(end+1)=string(design); hashes=strings(size(paths)); for k=1:numel(paths), hashes(k)=sha(paths(k)); end
value=struct('paths',paths,'hashes',hashes,'knownCount',numel(ids),'minimumDistance',min(dist,[],'all'),'matlabVersion',version,'toolboxes',ver,'created',datetime('now'));
femstudy.data.saveNew(p,value); fprintf('Design saved; %d known rows, minimum normalized distance %.6g.\n',numel(ids),value.minimumDistance);
end
function verify(~,out,~)
a=load(fullfile(out,'prepared.mat'),'value'); v=a.value;
am=fullfile(out,'provenance_amendment_01.json'); if isfile(am), amendment=jsondecode(fileread(am)); else, amendment=[]; end
for k=1:numel(v.paths)
 actual=sha(v.paths(k)); expected=v.hashes(k);
 if ~isempty(amendment) && endsWith(v.paths(k),'run_restfield_learning_curve.m'), assert(strcmp(expected,amendment.oldRunnerHash)); expected=amendment.newRunnerHash; amendment2=jsondecode(fileread(fullfile(out,'provenance_amendment_02.json'))); assert(strcmp(expected,amendment2.oldRunnerHash)); expected=amendment2.newRunnerHash; end
 assert(isfile(v.paths(k)) && strcmp(actual,expected),'Provenance mismatch: %s',v.paths(k));
end
if ~isempty(amendment), for k=1:numel(amendment.paths), assert(strcmp(sha(amendment.paths{k}),amendment.hashes{k}),'Source mismatch: %s',amendment.paths{k}); end, end
end
function fem(root,out,cfg,cp)
verify(root,out,cp); t=readtable(fullfile(out,'development_validation_design.csv'));
c=config('smoke'); c.meshDivisor=3; c.geometricOrder="quadratic"; c.saveRawMesh=false; c.maxDeflectionRatio=0.02;
dirpath=fullfile(out,'development_cases'); if ~isfolder(dirpath), mkdir(dirpath); end
for i=1:height(t)
 id=t.id(i); x=t{i,cellstr(cfg.parameterNames)}; base=fullfile(dirpath,sprintf('case_%06d',id));
 files=dir(base+"*.mat"); done=false;
 for k=1:numel(files), a=load(fullfile(files(k).folder,files(k).name),'value'); v=a.value; assert(v.id==id && isequal(v.x,x)); if v.status=="success", done=true; end, end
 if done, continue; end
 path=base+".mat"; if isfile(path), path=base+sprintf('_attempt_%03d.mat',numel(files)+1); end
 started=tic;
 try
  v=solve_case(x,c); v.seconds=toc(started); v.status="success"; v.id=id; v.x=x;
  assert(numel(v.S)==1575 && all(isfinite(v.S)) && all(isfinite(v.Y))); femstudy.data.saveNew(path,v);
 catch err
  v=struct('status',"failed",'id',id,'x',x,'seconds',toc(started),'error',string(getReport(err,'extended','hyperlinks','off'))); femstudy.data.saveNew(path,v); rethrow(err);
 end
 fprintf('Development FEM %d/%d %.1f s\n',i,height(t),v.seconds);
end
end
function s=sha(path)
fid=fopen(path,'r'); assert(fid>=0); cleanup=onCleanup(@() fclose(fid)); md=java.security.MessageDigest.getInstance('SHA-256');
while true, b=fread(fid,1048576,'*uint8'); if isempty(b), break; end; md.update(b); end
s=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
function [V,S,w,xi,ids]=references(out,cfg)
t=readtable(fullfile(out,'development_validation_design.csv')); V=t{:,cellstr(cfg.parameterNames)}; ids=t.id;
for i=1:height(t)
 files=dir(fullfile(out,'development_cases',sprintf('case_%06d*.mat',ids(i)))); found=false;
 for k=1:numel(files)
  a=load(fullfile(files(k).folder,files(k).name),'value'); v=a.value; assert(v.id==ids(i)&&isequal(v.x,V(i,:)));
  if v.status=="success", assert(~found); found=true; end
 end
 assert(found,'Missing successful reference %d',ids(i));
 if i==1, xi=v.xi; w=v.w(:); S=zeros(numel(w),height(t)); else, assert(isequal(xi,v.xi)&&isequal(w,v.w(:))); end
 S(:,i)=v.S(:);
end
end
function campaign(root,out,cfg,cp,pilot)
verify(root,out,cp); [V,S,w,xi,ids]=references(out,cfg);
if ~pilot, assert(isfile(fullfile(out,'pilot_passed.mat')),'Pilot required'); end
source=fullfile(root,'experiments','active','training_size_12_24_48_20261023');
if pilot, sizes=12; else, sizes=reshape(cfg.sizes,1,[]); end
for n=sizes
 a=load(fullfile(source,sprintf('n%d',n),'train.mat'),'D'); D=a.D;
 assert(isequal(D.xi,xi)&&isequal(D.w(:),w)&&isempty(intersect(D.id,ids)));
 beam=femstudy.fem.beamField(D.X,xi); R=D.S-beam; P=pod_fit(R,w,min(cfg.pod.maxRank,n-1));
 r=find(P.energy>=cfg.pod.energy,1); if isempty(r)||r>P.r, r=P.r; end
 P.V=P.V(:,1:r); P.r=r; P.selectedEnergy=P.energy(r); A=pod_encode(P,R); BV=femstudy.fem.beamField(V,xi);
 projection=metric(S,BV+P.mean+P.V*pod_encode(P,S-BV)',w,cfg.metricFloor);
 prep=struct('pod',P,'trainIDs',D.id,'trainX',D.X,'A',A,'rank',r,'energy',P.energy(r),'projection',projection,'validationIDs',ids);
 prepath=fullfile(out,'preprocessing',sprintf('n%d.mat',n));
 if isfile(prepath), old=load(prepath,'value'); assert(isequaln(old.value,prep)); else, femstudy.data.saveNew(prepath,prep); end
 kinds=["beam","gpr","mlp","mlp","mlp"]; seeds=[0,42,42,43,44]; if pilot, kinds=["beam","gpr","mlp"]; seeds=[0,42,42]; end
 for j=1:numel(kinds)
  kind=kinds(j); seed=seeds(j); prefix="run"; if pilot, prefix="pilot"; end
  base=fullfile(out,'runs',sprintf('%s_n%d_%s_seed%d',prefix,n,kind,seed));
  list=dir(base+"*.mat"); completed=false;
  for k=1:numel(list), b=load(fullfile(list(k).folder,list(k).name),'value'); if b.value.status=="completed", completed=true; end, end
  if completed, continue; end
  path=base+".mat"; if isfile(path), path=base+sprintf('_attempt_%03d.mat',numel(list)+1); end
  started=tic;
  try
   reg=[]; history=struct; reused=false; reason="";
   if kind=="mlp"
    o=struct('HiddenLayers',[32 32],'Optimizer',"lbfgs",'Seed',seed,'Budget',cfg.mlp.budget,'BatchSize',cfg.mlp.batchSize,'InitialLearnRate',cfg.mlp.learningRate,'L2Regularization',cfg.mlp.l2,'HistorySize',cfg.mlp.historySize,'GradientTolerance',cfg.mlp.gradientTolerance,'StepTolerance',cfg.mlp.stepTolerance);
    if pilot, o.Budget=10; end
    if n==384 && ~pilot
     oldpath=fullfile(root,'experiments','active','restfield_mlp_architecture_training_20261028_v1','final_preprocessing.mat'); old=load(oldpath,'value'); q=old.value;
     oldrun=fullfile(fileparts(oldpath),'runs',sprintf('FINAL_h32x32_LBFGS_seed%d.mat',seed)); z=load(oldrun,'value'); z=z.value; g=z.model.reg;
     reused=isequal(q.trainIDs,D.id(:)) && isequal(q.trainX,D.X) && isequal(q.xi,xi) && isequal(q.weights,w) && isequaln(q.pod,P) && isequaln(q.trainCoefficients,A) && strcmp(q.provenance.trainingDataSHA256,sha(fullfile(source,'n384','train.mat'))) && z.status=="completed" && isequal(g.hiddenLayers,[32 32]) && g.optimizer=="lbfgs" && g.seed==seed && g.budget==250 && g.l2Regularization==cfg.mlp.l2 && strcmp(z.metadata.configSHA256,sha(fullfile(root,'configs','restfield_mlp_architecture_training_20261028_v1.json')));
     if reused, reg=g; history=z.history; reason="reused exact preprocessing, data and recorded configuration"; else, reason="preprocessing or recorded configuration mismatch; refit"; end
    end
    if ~reused, [reg,history]=femstudy.models.fitControlledRestMLP(D.X,A,o); end
    pred=BV+P.mean+P.V*predict_reg(reg,V)'; seconds=reg.trainingSeconds; stop=string(history.stopReason);
   elseif kind=="gpr"
    reg=fit_gps(D.X,A,cfg.gprKernel); seconds=toc(started); pred=BV+P.mean+P.V*predict_reg(reg,V)'; stop="GPR fit completed";
   else
    pred=BV; seconds=0; stop="analytical";
   end
   M=metric(S,pred,w,cfg.metricFloor); M.CaseID=ids; M.ProjectionRelative=projection.Relative; M.ProjectionAbsolute=projection.Absolute;
   v=struct('status',"completed",'kind',kind,'seed',seed,'n',n,'pilot',pilot,'podRank',r,'energy',P.energy(r),'metrics',M,'history',history,'reg',reg,'trainingSeconds',seconds,'stopReason',stop,'reused',reused,'reuseReason',reason,'trainIDs',D.id,'validationIDs',ids,'elapsedSeconds',toc(started));
   femstudy.data.saveNew(path,v); fprintf('%s n=%d %s seed=%d finished %.2f s\n',prefix,n,kind,seed,seconds);
  catch err
   v=struct('status',"failed",'kind',kind,'seed',seed,'n',n,'pilot',pilot,'error',string(getReport(err,'extended','hyperlinks','off')),'elapsedSeconds',toc(started)); femstudy.data.saveNew(path,v); rethrow(err);
  end
 end
end
if pilot
 assert(numel(unique(ids))==128 && all(isfinite(projection.Relative)) && all(projection.Relative>=0));
 v=struct('status',"passed",'checked',datetime('now'),'note',"split, shared train-only POD, reconstruction, metrics; rerun checks immutable outputs");
 p=fullfile(out,'pilot_passed.mat'); if ~isfile(p), femstudy.data.saveNew(p,v); end
end
end
function t=metric(S,Y,w,floorValue)
assert(isequal(size(S),size(Y))&&all(isfinite(Y),'all')); a=sqrt(sum(w.*(Y-S).^2,1))'; ref=sqrt(sum(w.*S.^2,1))'; t=table(a./max(ref,floorValue),a,ref,'VariableNames',{'Relative','Absolute','Reference'});
end
function evaluate(out,cfg)
outputs=[string(fullfile(out,'summary.csv'));string(fullfile(out,'case_metrics.csv'));string(fullfile(out,'learning_curves.png'))];
exists=arrayfun(@(p) isfile(p),outputs); if any(exists), assert(all(exists),'Partial evaluation output; refusing overwrite'); fprintf('Evaluation outputs exist; preserving them.\n'); return; end
files=dir(fullfile(out,'runs','run_*.mat')); rows=table; cases=table;
for k=1:numel(files)
 a=load(fullfile(files(k).folder,files(k).name),'value'); v=a.value;
 if v.status~="completed", continue; end
 m=v.metrics; x=sort(m.Relative); p=x(ceil(.95*numel(x)));
 row=table(v.n,v.kind,v.seed,v.podRank,v.energy,mean(x),median(x),p,max(x),mean(m.Absolute),max(m.Absolute),mean(m.ProjectionRelative),v.trainingSeconds,string(v.stopReason),v.reused,string(v.reuseReason),'VariableNames',{'N','Model','Seed','PODRank','Energy','MeanRelative','Median','P95','Maximum','MeanAbsolute_m','MaxAbsolute_m','MeanProjection','TrainingSeconds','StopReason','Reused','ReuseReason'});
 rows=[rows;row]; m.N=repmat(v.n,height(m),1); m.Model=repmat(v.kind,height(m),1); m.Seed=repmat(v.seed,height(m),1); cases=[cases;m]; %#ok<AGROW>
end
assert(height(rows)==numel(cfg.sizes)*5 && height(cases)==height(rows)*128,'Incomplete campaign');
writetable(sortrows(rows,{'N','Model','Seed'}),fullfile(out,'summary.csv')); writetable(cases,fullfile(out,'case_metrics.csv'));
f=figure('Visible','off'); tiledlayout(1,3); nexttile; hold on;
for seed=reshape(cfg.seeds,1,[]), a=rows(rows.Model=="mlp" & rows.Seed==seed,:); a=sortrows(a,'N'); semilogx(a.N,a.P95,'-o','DisplayName',sprintf('MLP %d',seed)); end
for model=["gpr","beam"], a=sortrows(rows(rows.Model==model,:),'N'); semilogx(a.N,a.P95,'-o','DisplayName',model); end
yline(.01,'--'); title('P95'); legend; grid on; nexttile; hold on;
for model=["mlp","gpr","beam"], a=sortrows(rows(rows.Model==model & (rows.Seed==42 | rows.Seed==0),:),'N'); loglog(a.N,a.MeanRelative,'-o','DisplayName',model); end
title('Mean relative error'); grid on; legend; nexttile; hold on;
for model=["mlp","gpr"], a=sortrows(rows(rows.Model==model & rows.Seed==42,:),'N'); loglog(a.N,a.TrainingSeconds,'-o','DisplayName',model); end
title('Training seconds'); grid on; legend; exportgraphics(f,fullfile(out,'learning_curves.png')); close(f);
end
