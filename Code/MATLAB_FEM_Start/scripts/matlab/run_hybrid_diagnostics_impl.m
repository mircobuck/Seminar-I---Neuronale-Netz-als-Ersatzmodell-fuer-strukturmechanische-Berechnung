function run_hybrid_diagnostics_impl()
%RUN_HYBRID_DIAGNOSTICS Read frozen models and record split diagnostics.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,genpath(fullfile(root,'modelle')));
folder=fullfile(root,'experiments','hybrid_static_audit_v1');
output=fullfile(folder,'diagnostics_v1.mat');
assert(~isfile(output),'Diagnostics already exist; preserve previous results.');
frozen=load(fullfile(folder,'selection.mat'));
base=fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384');
a=load(fullfile(base,'train.mat')); D=a.D;
b=load(fullfile(base,'test.mat')); T=b.D;
sets={subset(D,frozen.spec.trainIDs),subset(D,frozen.spec.valIDs),T};
names=["train","validation","historical_test"];
w=D.w(:); xi=D.xi; n=size(xi,2);
fixed=find(xi(1,:)==0); clamp=[fixed fixed+n fixed+2*n];
tip=find(all(xi==[1;.5;.5],1));
diagnostics=struct;
for s=1:3
    d=sets{s}; B=femstudy.fem.beamField(d.X,xi);
    ms={frozen.direct,frozen.hybrid};
    for k=1:2
        m=ms{k}; target=d.S; if k==2, target=target-B; end
        trueCoeff=pod_encode(m.pod,target);
        predictedCoeff=predict_reg(m.reg,d.X);
        proj=m.pod.mean+m.pod.V*trueCoeff';
        raw=m.pod.mean+m.pod.V*predictedCoeff';
        if k==2, proj=proj+B; raw=raw+B; end
        field=raw; field(clamp,:)=0;
        model(k).trueCoeff=trueCoeff; model(k).predictedCoeff=predictedCoeff;
        model(k).projectionError=field_error(d.S,proj,w);
        model(k).rawField=raw; model(k).field=field; model(k).projection=proj;
        model(k).orthogonalityError=norm(m.pod.V'*(w.*m.pod.V)-eye(m.pod.r),'fro');
        model(k).xMeanError=norm(m.reg.xm-mean(sets{1}.X,1));
        model(k).xScaleError=norm(m.reg.xs-std(sets{1}.X,0,1));
        model(k).kernel=cell(1,numel(m.reg.net));
        for j=1:numel(m.reg.net)
            if ~isempty(m.reg.net{j})
                gp=m.reg.net{j};
                model(k).kernel{j}=struct('parameters',gp.KernelInformation.KernelParameters, ...
                    'sigma',gp.Sigma,'logLikelihood',gp.LogLikelihood);
            end
        end
    end
    fields={B,model(1).field,model(2).field};
    labels=["beam","direct","hybrid"];
    for k=1:3
        H=fields{k}; err=H-d.S;
        metrics(k).name=labels(k); metrics(k).relative=field_error(d.S,H,w);
        metrics(k).rms=zeros(numel(d.id),3); metrics(k).relativeComponent=nan(numel(d.id),3);
        for c=1:3
            idx=(1:n)+(c-1)*n; wc=w(idx);
            metrics(k).rms(:,c)=sqrt(sum(wc.*err(idx,:).^2,1))';
            den=sqrt(sum(wc.*d.S(idx,:).^2,1))';
            valid=den>1e-14; metrics(k).relativeComponent(valid,c)=metrics(k).rms(valid,c)./den(valid);
        end
        metrics(k).predictedTip=H(2*n+tip,:)';
        metrics(k).tipAbsoluteError=abs(H(2*n+tip,:)'-d.S(2*n+tip,:)');
        metrics(k).clampAfter=max(abs(H(clamp,:)),[],1)';
        if k==1, metrics(k).clampBefore=metrics(k).clampAfter; metrics(k).clampCorrection=zeros(numel(d.id),1);
        else
            R=model(k-1).rawField;
            metrics(k).clampBefore=max(abs(R(clamp,:)),[],1)';
            metrics(k).clampCorrection=sqrt(sum(w.*(R-H).^2,1))';
        end
    end
    diagnostics.(names(s))=struct('ids',d.id,'metrics',metrics,'model',model,'beam',B);
end
metadata=struct('version',version,'weights','sum 1 per component; sum 3 overall', ...
    'relativeComponentThreshold_m',1e-14,'trainingIDs',frozen.spec.trainIDs, ...
    'validationIDs',frozen.spec.valIDs,'note','true coefficients only used for diagnostics');
save(output,'diagnostics','metadata','-v7.3');
fprintf('Saved %s\n',output);
end
function out=subset(D,ids)
idx=find(ismember(D.id,ids)); out=D; out.X=D.X(idx,:); out.S=D.S(:,idx); out.id=D.id(idx);
end
