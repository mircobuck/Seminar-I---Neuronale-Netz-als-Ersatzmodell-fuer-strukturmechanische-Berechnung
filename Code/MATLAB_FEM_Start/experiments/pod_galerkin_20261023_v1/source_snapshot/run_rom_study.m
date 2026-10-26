function outDir=run_rom_study(stage,varargin)
%run_rom_study - Run the common-space POD-Galerkin comparison
%   OUTDIR = run_rom_study(STAGE) prepares, checks, fits or evaluates the
%   experiment. run_rom_study("snapshots",START,STOP) checkpoints training
%   snapshots; run_rom_study("fit",N) freezes one training-size ROM.
%   See also rom_assemble, rom_predict
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
outDir=fullfile(root,'experiments','pod_galerkin_20261023_v1');
if string(stage)=="prepare", prepare(root,outDir); return; end
p=load(fullfile(outDir,'protocol.mat')); mesh=p.mesh; cfg=p.cfg;
switch string(stage)
    case "checks", checks(mesh,cfg,outDir);
    case "validation", snapshots(mesh,cfg,outDir,"val",1,6);
    case "snapshots", snapshots(mesh,cfg,outDir,"train",varargin{1},varargin{2});
    case "fit", fitROM(mesh,cfg,outDir,varargin{1});
    case "testdata"
        for n=cfg.counts, assert(isfile(fullfile(outDir,"n"+n,'model.mat'))); end
        snapshots(mesh,cfg,outDir,"test",1,6);
    case "evaluate", evaluateROM(mesh,cfg,outDir,varargin{1});
    case "summarize", summarize(outDir,cfg);
    otherwise, error('Unknown ROM study stage.');
end
end

function prepare(root,outDir)
assert(~isfolder(outDir),'Study exists; resume stages instead.');
source=fullfile(root,'experiments','training_size_12_24_48_20261023');
C=readtable(fullfile(source,'comparison.csv'),TextType="string");
cfg.counts=unique(C.TrainingCases)'; assert(isequal(cfg.counts,[12 24 48 96 192 384]));
cfg.source=source; cfg.root=root; cfg.MATLAB=version; cfg.ranks=[1 2 4 8 11];
a=load(fullfile(source,'n384','models.mat'),'meta'); cfg.original=a.meta.config;
cfg.x0=(cfg.original.lower+cfg.original.upper)/2;
cfg.meshDivisor=3; cfg.basis="uncentered Euclidean nodal POD on free DOFs";
cfg.modelSeed=cfg.original.modelSeed;
m=femodel(AnalysisType="structuralStatic", ...
    Geometry=multicuboid(cfg.x0(1),cfg.x0(2),cfg.x0(3)));
m=generateMesh(m,Hmax=min(cfg.x0(2:3))/cfg.meshDivisor,GeometricOrder="quadratic");
mesh.nodes=m.Geometry.Mesh.Nodes./cfg.x0(1:3)'+[.5;.5;0];
mesh.nodes(abs(mesh.nodes)<1e-12)=0;
mesh.nodes(abs(mesh.nodes-1)<1e-12)=1;
mesh.elements=m.Geometry.Mesh.Elements;
mesh.nNodes=size(mesh.nodes,2); mesh.nDOF=3*mesh.nNodes;
mesh.clampedNodes=find(mesh.nodes(1,:)==0);
mesh.fixed=[mesh.clampedNodes,mesh.clampedNodes+mesh.nNodes,mesh.clampedNodes+2*mesh.nNodes];
mesh.free=setdiff((1:mesh.nDOF)',mesh.fixed(:));
[mesh.xi,mesh.w]=reference_grid(cfg.original.gridSize);
mesh.tipIndex=find(all(mesh.xi==[1;.5;.5],1)); assert(isscalar(mesh.tipIndex));
mesh.P=rom_observation(mesh.nodes,mesh.elements,mesh.xi);
mesh.O=blkdiag(mesh.P,mesh.P,mesh.P); mesh.O=mesh.O(:,mesh.free);
mkdir(outDir); mkdir(fullfile(outDir,'snapshots')); mkdir(fullfile(outDir,'logs'));
copyfile(fullfile(root,'src'),fullfile(outDir,'source_snapshot','src'));
copyfile(fullfile(root,'run_rom_study.m'),fullfile(outDir,'source_snapshot'));
save(fullfile(outDir,'protocol.mat'),'cfg','mesh','-v7.3');
plan=["# POD-Galerkin comparison protocol"; ...
    "Six existing sizes: 12,24,48,96,192,384; same training IDs, validation IDs 13-18 and test IDs 19-24."; ...
    "No new physical samples or model seeds; original model seed 42 retained as provenance."; ...
    "Mesh generated at domain midpoint with Hmax=min(b0,h0)/3, quadratic tetrahedra."; ...
    "Reference coordinates [0,1]^3 mapped by diag(L,b,h), offset (-L/2,-b/2,0)."; ...
    "Fixed connectivity, node order and block DOF order [ux;uy;uz]."; ...
    "Full unconstrained K+A+Q and F+G; eliminate known zero clamp DOFs ONCE."; ...
    "Uncentered nodal POD from each training subset ONLY. Ranks [1,2,4,8,11]."; ...
    "Choose minimum validation mean weighted relative L2 error against original FEM output fields."; ...
    "Test labels/snapshots loaded only after ALL six models are frozen."; ...
    "Different common mesh vs old per-case meshes: quantify discrepancy, never claim identical discretizations."; ...
    "Quadratic shape-function observation on original 525-point grid; midpoint tip is on this grid."; ...
    "Output projection floor is weighted least-squares projection onto O*V, NOT nodal POD coefficients."; ...
    "Residual and energy errors reference the common-space full FEM; field/scalar errors reference original FEM."; ...
    "Full fresh assembly is included in every ROM online timing; no affine optimization."; ...
    "Original model files are read only. Re-evaluate their missing scalar outputs without retraining."; ...
    "Timing repeats: three full online executions per test case; use median, store every sample."; ...
    "Test set already inspected in prior series; exploratory comparison, no new blind holdout." ];
writelines(plan,fullfile(outDir,'PLAN.md'));
fprintf('Prepared ROM: %d nodes, %d elements, %d free DOFs.\n', ...
    mesh.nNodes,size(mesh.elements,2),numel(mesh.free));
end

function checks(mesh,cfg,outDir)
x=cfg.x0; t=tic; [K,f,m]=rom_assemble(mesh,x);
assert(norm(K-K','fro')/norm(K,'fro')<1e-12); [~,flag]=chol(K); assert(flag==0);
u=K\f; full=zeros(mesh.nDOF,1); full(mesh.free)=u;
R=solve(m); direct=[R.Displacement.ux;R.Displacement.uy;R.Displacement.uz];
matrixError=norm(full-direct)/norm(direct); assert(matrixError<1e-8);
assert(all(full(mesh.fixed)==0));
xyz=[x(1)*(mesh.xi(1,:)-.5);x(2)*(mesh.xi(2,:)-.5);x(3)*mesh.xi(3,:)];
U=interpolateDisplacement(R,xyz); expected=[U.ux(:);U.uy(:);U.uz(:)];
interpolationError=norm(mesh.O*u-expected)/norm(expected); assert(interpolationError<1e-9);
nullFEM=assembleFEMatrices(m,"nullspace");
nullU=nullFEM.B*(nullFEM.Kc\nullFEM.Fc)+nullFEM.ud;
nullspaceError=norm(nullU-full)/norm(full); assert(nullspaceError<1e-8);
xx=x; xx(6)=2*x(6); [K2,f2]=rom_assemble(mesh,xx); u2=K2\f2;
forceError=norm(u2-2*u)/norm(u2); assert(forceError<1e-8);
xx=x; xx(4)=2*x(4); [K2,f2]=rom_assemble(mesh,xx); u2=K2\f2;
eError=norm(u2-u/2)/norm(u2); assert(eError<1e-8);
V=u/norm(u); [H,~,ur,~,d]=rom_predict(mesh,V,x);
inclusionError=norm(ur-u)/norm(u); assert(inclusionError<1e-8);
assert(d.CholeskyFlag==0 && d.Symmetry<1e-12 && d.ProjectedResidual<1e-8);
assert(d.Residual<1e-8 && norm(H-mesh.O*u)/norm(H)<1e-8);
seconds=toc(t);
save(fullfile(outDir,'checks.mat'),'matrixError','interpolationError', ...
    'nullspaceError','forceError','eError','inclusionError','seconds');
disp(table(matrixError,interpolationError,nullspaceError,forceError,eError,inclusionError));
fprintf('All ROM mechanics checks passed in %.3f s.\n',seconds);
end

function snapshots(mesh,cfg,outDir,label,first,last)
assert(isfile(fullfile(outDir,'checks.mat')),'Mechanics checks required.');
a=load(fullfile(cfg.source,'n384',label+'.mat'),'D'); D=a.D;
assert(first>=1 && last<=numel(D.id));
for i=first:last
    file=fullfile(outDir,'snapshots',sprintf('case_%04d.mat',D.id(i)));
    if isfile(file), old=load(file,'snapshot'); assert(isequal(old.snapshot.x,D.X(i,:))); continue; end
    total=tic; [K,f,~,timing]=rom_assemble(mesh,D.X(i,:));
    t=tic; u=K\f; timing.FullSolveSeconds=toc(t);
    t=tic; H=mesh.O*u; nq=size(mesh.xi,2);
    y=[H(2*nq+mesh.tipIndex),max(sqrt(sum(reshape(H,nq,3).^2,2)))];
    timing.ReconstructionSeconds=toc(t); timing.TotalSeconds=toc(total);
    gap=field_error(D.S(:,i),H,mesh.w);
    snapshot=struct('id',D.id(i),'x',D.X(i,:),'u',u,'H',H,'y',y, ...
        'timing',timing,'meshGap',gap,'residual',norm(K*u-f)/norm(f));
    assert(all(isfinite(u)) && snapshot.residual<1e-7);
    tmp=string(file)+".tmp.mat"; save(tmp,'snapshot','-v7.3'); movefile(tmp,file);
    fprintf('%s %d/%d: ID %d, mesh gap %.6g%%, %.3f s\n',label,i,numel(D.id),D.id(i),100*gap,timing.TotalSeconds);
end
end

function fitROM(mesh,cfg,outDir,n)
assert(ismember(n,cfg.counts)); folder=fullfile(outDir,"n"+n);
assert(~isfile(fullfile(folder,'model.mat')),'Frozen ROM must not be overwritten.');
a=load(fullfile(cfg.source,"n"+n,'train.mat'),'D'); trainIDs=a.D.id;
v=load(fullfile(cfg.source,"n"+n,'val.mat'),'D'); va=v.D;
assert(numel(trainIDs)==n && isempty(intersect(trainIDs,va.id)));
S=zeros(numel(mesh.free),n); snapshotSeconds=0;
for j=1:n
    a=load(fullfile(outDir,'snapshots',sprintf('case_%04d.mat',trainIDs(j))),'snapshot');
    assert(a.snapshot.id==trainIDs(j)); S(:,j)=a.snapshot.u;
    snapshotSeconds=snapshotSeconds+a.snapshot.timing.TotalSeconds;
end
started=tic; basisClock=tic; [V,SV,~]=svd(S,'econ');
s=diag(SV); numericalRank=nnz(s>max(size(S))*eps(max(s)));
ranks=cfg.ranks(cfg.ranks<=min(n,numericalRank)); V=V(:,1:max(ranks));
basisSeconds=toc(basisClock); selection=table(); best=Inf; chosenRank=NaN;
validationClock=tic;
for r=ranks
    scores=zeros(6,1);
    for j=1:6
        H=rom_predict(mesh,V(:,1:r),va.X(j,:));
        scores(j)=field_error(va.S(:,j),H,mesh.w);
    end
    score=mean(scores);
    selection=[selection;table(r,score,'VariableNames',{'Rank','ValidationMeanRelativeL2'})]; %#ok<AGROW>
    if score<best, best=score; chosenRank=r; end
end
validationSeconds=toc(validationClock); offlineSeconds=toc(started);
model=struct('name',"POD_Galerkin",'V',V(:,1:chosenRank), ...
    'rank',chosenRank,'trainIDs',trainIDs,'valIDs',va.id,'validationScore',best, ...
    'basisSeconds',basisSeconds,'selectionSeconds',validationSeconds, ...
    'offlineSeconds',offlineSeconds,'snapshotSeconds',snapshotSeconds, ...
    'ranks',ranks,'singularValues',s,'MATLAB',version,'config',cfg);
if ~isfolder(folder), mkdir(folder); end
save(fullfile(folder,'model.mat'),'model','selection','-v7.3');
writetable(selection,fullfile(folder,'validation_selection.csv'));
fprintf('Frozen ROM n=%d, rank=%d, validation %.6g%%, snapshots %.3f s, offline %.3f s.\n', ...
    n,chosenRank,100*best,snapshotSeconds,offlineSeconds);
end

function evaluateROM(mesh,cfg,outDir,n)
error('Evaluation stage not implemented yet.');
end

function summarize(outDir,cfg)
error('Summary stage not implemented yet.');
end
