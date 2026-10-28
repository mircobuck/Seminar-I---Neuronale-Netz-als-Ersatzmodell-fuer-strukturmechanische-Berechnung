function summarize_controlled_gpr()
%SUMMARIZE_CONTROLLED_GPR Summarize saved fits without training or FEM.
root=fileparts(mfilename('fullpath')); addpath(root,genpath(fullfile(root,'modelle')));
folder=fullfile(root,'experiments','hybrid_controlled_fits_v1');
source=fullfile(root,'experiments','training_size_12_24_48_20261023','n384','train.mat');
a=load(source); D=a.D; old=load(fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat'));
it=ismember(D.id,old.spec.trainIDs); iv=ismember(D.id,old.spec.valIDs); w=D.w(:); n=size(D.xi,2);
ids=D.id(iv); tip=find(all(D.xi==[1;.5;.5],1)); clamp=find(D.xi(1,:)==0); clamp=[clamp clamp+n clamp+2*n];
rows=table; timing=zeros(2,8,5); cases=table;
for kind=1:2
    for c=1:8
        a=load(fullfile(folder,sprintf('fit_%d_%d.mat',kind,c))); r=a.result;
        if r.status~="success",continue;end
        ll=0; for j=1:numel(r.fitInfo), if ~isempty(r.fitInfo{j}),ll=ll+r.fitInfo{j}.logLikelihood;end,end
        T=table(kind,c,mean(r.trainError)*100,mean(r.valError)*100,median(r.valError)*100,max(r.valError)*100, ...
            mean(r.valProjection)*100,ll,r.seconds,'VariableNames',{'kind','candidate','trainMeanPct','valMeanPct','valMedianPct','valMaxPct','valProjectionPct','trainLogLikelihood','fitSeconds'});
        rows=[rows;T]; %#ok<AGROW>
        E=r.valField-D.S(:,iv); rms=zeros(numel(ids),3);
        for j=1:3, ix=(1:n)+(j-1)*n; rms(:,j)=sqrt(sum(w(ix).*E(ix,:).^2,1))'; end
        V=table(repmat(kind,numel(ids),1),repmat(c,numel(ids),1),ids(:),100*r.valError(:),rms(:,1),rms(:,2),rms(:,3), ...
            abs(E(2*n+tip,:))',max(abs(r.valField(clamp,:)),[],1)', ...
            'VariableNames',{'kind','candidate','id','relativePct','uxRmsM','uyRmsM','uzRmsM','tipAbsM','clampRawMaxM'});
        cases=[cases;V]; %#ok<AGROW>
        X=D.X(iv,:); predict_reg(r.reg,X);
        for rep=1:5
            t=tic; predict_reg(r.reg,X); timing(kind,c,rep)=toc(t);
        end
    end
end
writetable(rows,fullfile(folder,'fit_summary.csv')); writetable(cases,fullfile(folder,'validation_cases.csv'));
metadata=struct('MATLAB',version,'batchSize',numel(ids),'warmup',1,'repetitions',5, ...
    'timingScope',"GPR regression only; batch of six",'host',getenv('COMPUTERNAME'));
save(fullfile(folder,'summary.mat'),'rows','cases','timing','metadata');
f=figure('Visible','off'); tiledlayout(1,2);
for kind=1:2
    nexttile; v=rows(rows.kind==kind,:); bar(v.candidate,v.valMeanPct);
    xlabel('Kandidat'); ylabel('Mittlerer Validierungsfehler (%)'); grid on;
    if kind==1,title('Direktes POD-GPR');else,title('Hybrid');end
end
exportgraphics(f,fullfile(folder,'validation_candidates.pdf'),'ContentType','vector'); close(f);
end
