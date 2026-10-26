function export_controlled_metrics()
%EXPORT_CONTROLLED_METRICS Export saved training and validation predictions.
root=fileparts(mfilename('fullpath')); addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','hybrid_controlled_fits_v1');
a=load(fullfile(root,'experiments','training_size_12_24_48_20261023','n384','train.mat'),'D'); D=a.D;
a=load(fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat'),'spec'); spec=a.spec;
n=size(D.xi,2); tip=find(all(D.xi==[1;.5;.5],1)); clamp=find(D.xi(1,:)==0); clamp=[clamp clamp+n clamp+2*n];
cases=table; aggregates=table;
for k=1:2
 for c=1:8
  a=load(fullfile(out,sprintf('fit_%d_%d.mat',k,c)),'result'); r=a.result;
  if r.status~="success",continue;end
  for split=1:2
   if split==1, ids=r.trainIDs; pred=r.trainField; rel=r.trainError; proj=r.trainProjection; else,ids=r.valIDs;pred=r.valField;rel=r.valError;proj=r.valProjection;end
   ix=ismember(D.id,ids); E=pred-D.S(:,ix); rms=zeros(numel(ids),3);
   for j=1:3,ind=(1:n)+(j-1)*n;rms(:,j)=sqrt(sum(D.w(ind).*E(ind,:).^2,1))';end
   C=table(repmat(k,numel(ids),1),repmat(c,numel(ids),1),repmat(split,numel(ids),1),ids(:),100*rel(:),100*proj(:),rms(:,1),rms(:,2),rms(:,3),abs(E(2*n+tip,:))',max(abs(pred(clamp,:)),[],1)', ...
      'VariableNames',{'kind','candidate','split','id','relativePct','projectionPct','uxRmsM','uyRmsM','uzRmsM','tipAbsM','clampRawMaxM'});
   cases=[cases;C]; %#ok<AGROW>
   aggregates=[aggregates;table(k,c,split,100*mean(rel),100*median(rel),100*max(rel),100*mean(proj), ...
    'VariableNames',{'kind','candidate','split','meanPct','medianPct','maxPct','projectionMeanPct'})]; %#ok<AGROW>
  end
 end
end
writetable(cases,fullfile(out,'all_cases.csv')); writetable(aggregates,fullfile(out,'all_aggregates.csv'));
end
