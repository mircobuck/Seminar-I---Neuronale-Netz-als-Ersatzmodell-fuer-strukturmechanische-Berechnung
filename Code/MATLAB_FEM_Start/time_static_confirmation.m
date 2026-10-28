function time_static_confirmation()
root=fileparts(mfilename('fullpath'));addpath(root,genpath(fullfile(root,'modelle')));
out=fullfile(root,'experiments','static_confirmation_v1');a=load(fullfile(out,'design.mat')); X=a.design.X;
[xi,~]=reference_grid([21 5 5]); r=cell(1,2);
for k=1:2,a=load(fullfile(root,'experiments','hybrid_controlled_fits_v1',sprintf('fit_%d_8.mat',k)));r{k}=a.result;end
times=zeros(3,2,5,6);
for k=1:3
 for batch=1:2
  if batch==1,Q=X(1,:);else,Q=X;end
  for rep=0:5
   t0=tic;
   if k==1,t=tic;H=femstudy.fem.beamField(Q,xi);v=[toc(t) 0 0 0 0];else,[H,z]=controlled_predict(r{k-1},Q,xi);v=[z.physics z.transfer z.regression z.reconstruction z.postprocessing];end
   t=tic;n=size(xi,2);cl=find(xi(1,:)==0);H([cl cl+n cl+2*n],:)=0;v(5)=v(5)+toc(t);
   v(6)=toc(t0);
   if rep>0,times(k,batch,rep,:)=v;end
  end
 end
end
metadata=struct('version',version,'computer',computer,'warmup',1,'repetitions',5,'batchSizes',[1 64],'units','seconds');
save(fullfile(out,'timing.mat'),'times','metadata'); average=squeeze(mean(times,3));
for k=1:3,for batch=1:2,values(k+(batch-1)*3,:)=[k batch reshape(average(k,batch,:),1,6)];end,end %#ok<AGROW>
writematrix(values,fullfile(out,'timing.csv'));disp(average);
end
