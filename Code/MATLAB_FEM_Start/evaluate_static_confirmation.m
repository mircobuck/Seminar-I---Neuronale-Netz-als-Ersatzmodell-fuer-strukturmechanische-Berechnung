function evaluate_static_confirmation()
%EVALUATE_STATIC_CONFIRMATION Evaluate previously frozen predictions.
root=fileparts(mfilename('fullpath')); addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','static_confirmation_v1');
a=load(fullfile(out,'design.mat')); design=a.design; p=load(fullfile(out,'predictions.mat'));
N=numel(design.id); n=size(p.xi,2); tip=find(all(p.xi==[1;.5;.5],1));
cl=find(p.xi(1,:)==0); cl=[cl cl+n cl+2*n]; S=zeros(3*n,N); tipref=zeros(N,1); femtime=zeros(N,1);
for i=1:N
 a=load(fullfile(out,sprintf('fem_%06d.mat',design.id(i))));
 assert(a.result.status=="success",'Incomplete FEM case %d',i);
 S(:,i)=a.result.value.S;tipref(i)=a.result.value.Y(1);femtime(i)=a.result.seconds;
end
rows=table; summary=table; projection=zeros(N,2);
for k=1:3
 H=p.corrected{k}; E=H-S; rel=field_error(S,H,p.w); rms=zeros(N,3); rcomp=nan(N,3);
 for j=1:3
  ix=(1:n)+(j-1)*n; rms(:,j)=sqrt(sum(p.w(ix).*E(ix,:).^2,1))';
  den=sqrt(sum(p.w(ix).*S(ix,:).^2,1))'; good=den>1e-14;rcomp(good,j)=rms(good,j)./den(good);
 end
 tiperr=abs(H(2*n+tip,:)'-tipref); tiprel=nan(N,1);good=abs(tipref)>1e-14;tiprel(good)=tiperr(good)./abs(tipref(good));
 clampRaw=max(abs(p.raw{k}(cl,:)),[],1)';clampPost=max(abs(H(cl,:)),[],1)';
 correction=max(abs(p.raw{k}(cl,:)-H(cl,:)),[],1)';
 T=table(repmat(k,N,1),design.id,rel*100,rms(:,1),rms(:,2),rms(:,3),rcomp(:,1)*100,rcomp(:,2)*100,rcomp(:,3)*100,tiperr,tiprel*100,clampRaw,clampPost,correction, ...
 'VariableNames',{'model','id','fieldPct','uxAbsM','uyAbsM','uzAbsM','uxPct','uyPct','uzPct','tipAbsM','tipPct','clampRawM','clampPostM','clampCorrectionM'});
 rows=[rows;T]; %#ok<AGROW>
 summary=[summary;table(k,N,mean(rel)*100,median(rel)*100,prctile(rel,95)*100,max(rel)*100, ...
 'VariableNames',{'model','N','meanPct','medianPct','p95Pct','maxPct'})]; %#ok<AGROW>
end
for k=1:2
 a=load(fullfile(root,'experiments','hybrid_controlled_fits_v1',sprintf('fit_%d_8.mat',k))); r=a.result;
 scale=(design.X(:,6)/-500).*(1e11./design.X(:,4));
 target=S; if k==2,target=S-femstudy.fem.beamField(design.X,p.xi);end
 target=target./scale'; coeff=pod_encode(r.pod,target);
 H=(r.pod.mean+r.pod.V*coeff').*scale';
 if k==2,H=H+femstudy.fem.beamField(design.X,p.xi);end
 projection(:,k)=field_error(S,H,p.w)*100;
end
paired=table(design.id,rows.fieldPct(2*N+1:3*N)-rows.fieldPct(1:N),rows.fieldPct(2*N+1:3*N)-rows.fieldPct(N+1:2*N),projection(:,1),projection(:,2), ...
 'VariableNames',{'id','hybridMinusBeamPctPoints','hybridMinusDirectPctPoints','directProjectionPct','hybridProjectionPct'});
writetable(rows,fullfile(out,'case_metrics.csv'));writetable(summary,fullfile(out,'summary.csv'));writetable(paired,fullfile(out,'paired.csv'));
save(fullfile(out,'evaluation.mat'),'rows','summary','paired','femtime');
disp(summary);fprintf('Hybrid vs beam improved %d, worse %d, equal %d\n',sum(paired.hybridMinusBeamPctPoints< -1e-10),sum(paired.hybridMinusBeamPctPoints>1e-10),sum(abs(paired.hybridMinusBeamPctPoints)<=1e-10));
end
