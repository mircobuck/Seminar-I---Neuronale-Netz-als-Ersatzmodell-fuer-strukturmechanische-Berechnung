function run_gpr_cause_analysis_impl()
%RUN_GPR_CAUSE_ANALYSIS Inspect frozen models without retraining or test data.
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(root,fullfile(root,'src'));
source=fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat');
out=fullfile(root,'experiments','hybrid_gpr_diagnosis_v1','analysis_v2.mat');
assert(~isfile(out),'Previous analysis is immutable.');
f=load(source); a=load(fullfile(root,'experiments','active','training_size_12_24_48_20261023','n384','train.mat')); D=a.D;
it=ismember(D.id,f.spec.trainIDs); iv=ismember(D.id,f.spec.valIDs);
X=D.X(it,:); Xv=D.X(iv,:); S=D.S(:,it); Sv=D.S(:,iv); xi=D.xi;
B=femstudy.fem.beamField(X,xi); Bv=femstudy.fem.beamField(Xv,xi);
items={f.direct,f.hybrid}; targets={S,S-B}; validation={Sv,Sv-Bv};
for k=1:2
    m=items{k}; actual=pod_encode(m.pod,targets{k});
    actualVal=pod_encode(m.pod,validation{k});
    z=(X-m.reg.xm)./m.reg.xs; zv=(Xv-m.reg.xm)./m.reg.xs;
    means=mean(actual,1); scales=std(actual,0,1); scales(m.reg.fixed)=1;
    manual=zeros(size(Xv,1),size(actual,2)); standardized=manual; uncertainty=manual;
    kernel=cell(1,size(actual,2));
    for j=1:size(actual,2)
        if m.reg.fixed(j), manual(:,j)=m.reg.ym(j); continue; end
        gp=m.reg.net{j}; [standardized(:,j),sd]=predict(gp,zv);
        uncertainty(:,j)=sd*m.reg.ys(j);
        manual(:,j)=standardized(:,j)*m.reg.ys(j)+m.reg.ym(j);
        pars=gp.KernelInformation.KernelParameters(:);
        ell=pars(1:size(z,2)); distance=zeros(size(zv,1),size(z,1));
        for q=1:size(zv,1), distance(q,:)=sum(((z-zv(q,:))./ell').^2,2)'; end
        if strcmpi(string(gp.KernelInformation.Name),"ardsquaredexponential")
            corr=exp(-distance/2);
        else
            rr=sqrt(distance); corr=(1+sqrt(5)*rr+5*distance/3).*exp(-sqrt(5)*rr);
        end
        kernel{j}=struct('name',string(gp.KernelInformation.Name),'parameters',pars, ...
            'sigma',gp.Sigma,'basisFunction',string(gp.BasisFunction), ...
            'maxCorrelation',max(corr,[],2),'correlation',corr,'beta',gp.Beta, ...
            'alpha',gp.Alpha,'logLikelihood',gp.LogLikelihood, ...
            'optimizationStatus',"not captured during original fit");
    end
    registered=predict_reg(m.reg,Xv);
    H=m.pod.mean+m.pod.V*manual'; Hregistered=m.pod.mean+m.pod.V*registered';
    nearest=zeros(size(Xv,1),1);
    for q=1:size(Xv,1), nearest(q)=min(vecnorm(z-zv(q,:),2,2)); end
    result(k)=struct('name',["direct","hybrid"],'trainIDs',D.id(it),'valIDs',D.id(iv), ...
        'trueTrain',actual,'trueValidation',actualVal,'standardizedPrediction',standardized, ...
        'manualPrediction',manual,'registeredPrediction',registered,'uncertainty',uncertainty, ...
        'meanError',norm(means-m.reg.ym),'scaleError',norm(scales-m.reg.ys), ...
        'coefficientAgreement',max(abs(manual-registered),[],'all'), ...
        'fieldAgreement',max(abs(H-Hregistered),[],'all'), ...
        'nearestStandardizedDistance',nearest,'outsideMarginal',Xv<min(X,[],1)|Xv>max(X,[],1), ...
        'parameterValues',Xv,'forceOverE',Xv(:,6)./Xv(:,4),'beamTip',beam_tip(Xv), ...
        'kernel',{kernel}); %#ok<AGROW>
    result(k).name=["direct","hybrid"]; result(k).name=result(k).name(k);
end
known=[2 -3;4 5]; mu=[10 20]; scale=[2 4]; basis=[1 0;0 1;1 -1];
decoded=mu+(known.*scale); reconstructed=basis*decoded';
assert(isequal(reconstructed,basis*[14 18;8 40]));
save(out,'result','known','mu','scale','basis','reconstructed','-v7.3');
fprintf('Manual versus registered max coefficient errors %.3g / %.3g\n',result(1).coefficientAgreement,result(2).coefficientAgreement);
end
