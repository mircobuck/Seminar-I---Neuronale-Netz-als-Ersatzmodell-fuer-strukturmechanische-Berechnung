function run_static_confirmation_impl(stage)
%RUN_STATIC_CONFIRMATION Frozen confirmation experiment; one checkpoint per FEM case.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','static_confirmation_v1');
c=config('smoke'); [xi,w]=reference_grid(c.gridSize);
switch string(stage)
 case "design"
  assert(~isfile(fullfile(out,'design.mat')),'Design already exists.');
  rng(20261026,'twister'); lo=c.lower; hi=c.upper;
  X=lo+lhsdesign(64,6,'criterion','none').*(hi-lo); id=(100001:100064)';
  paths=[dir(fullfile(root,'designs','*.csv'));dir(fullfile(root,'experiments','active','training_size_12_24_48_20261023','*design*.csv'))];
  old=[]; used={}; names=c.names;
  for i=1:numel(paths)
   p=fullfile(paths(i).folder,paths(i).name); T=readtable(p);
   if all(ismember(names,T.Properties.VariableNames)),old=[old;T{:,names}];used{end+1}=p;end %#ok<AGROW>
  end
  assert(~isempty(old),'No historical design data.');
  A=(X-lo)./(hi-lo); B=(old-lo)./(hi-lo);
  cols=[1 2 3 5]; mind=min(pdist2(A(:,cols),B(:,cols),'chebychev'),[],'all');
  D=pdist2(A(:,cols),A(:,cols),'chebychev'); D(1:65:end)=inf;
  assert(mind>1e-10 && min(D,[],'all')>1e-10,'Equivalent case detected.');
  design=struct('X',X,'id',id,'historicalFiles',{used},'historicalCount',size(old,1),'minimumGeometryNuDistance',mind,'seed',20261026);
  save(fullfile(out,'design.mat'),'design'); writetable(array2table([id X],'VariableNames',[{'id'} names]),fullfile(out,'design.csv'));
  fprintf('Design complete, %d historical rows, min normalized geometric distance %.9g\n',size(old,1),mind);
 case {"one","data"}
  a=load(fullfile(out,'design.mat')); design=a.design;
  if stage=="one",ids=1;else,ids=1:64;end
  for i=ids
   file=fullfile(out,sprintf('fem_%06d.mat',design.id(i))); if isfile(file),fprintf('reuse %d\n',i);continue;end
   t=tic; lastwarn('');
   try
    value=solve_case(design.X(i,:),c); [msg,wid]=lastwarn;
    result=struct('status',"success",'id',design.id(i),'X',design.X(i,:),'value',value,'warning',msg,'warningID',wid,'seconds',toc(t));
   catch err
    [msg,wid]=lastwarn; result=struct('status',"failed",'id',design.id(i),'X',design.X(i,:),'error',getReport(err),'warning',msg,'warningID',wid,'seconds',toc(t));
   end
   tmp=string(file)+".tmp.mat";save(tmp,'result','-v7.3');movefile(tmp,file);
   fprintf('FEM %d/64: %s %.2f sec\n',i,result.status,result.seconds);
   if result.status~="success",error('confirmation:FEMFailed','Case %d failed; checkpoint retained.',i);end
  end
 case "predict"
  a=load(fullfile(out,'design.mat')); X=a.design.X;
  r=cell(1,2);for k=1:2,a=load(fullfile(root,'experiments','hybrid_controlled_fits_v1',sprintf('fit_%d_8.mat',k)));r{k}=a.result;end
  raw=cell(1,3); raw{1}=femstudy.fem.beamField(X,xi);
  for k=1:2,raw{k+1}=controlled_predict(r{k},X,xi);end
  n=size(xi,2); clamp=find(xi(1,:)==0); clamp=[clamp clamp+n clamp+2*n];
  corrected=raw;for k=1:3,corrected{k}(clamp,:)=0;end
  save(fullfile(out,'predictions.mat'),'raw','corrected','X','xi','w','-v7.3');
  fprintf('Frozen predictions saved without FEM targets.\n');
 otherwise,error('Unknown stage.');
end
end
