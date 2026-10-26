function run_controlled_gpr_fits(out,limit,stopAfter)
%RUN_CONTROLLED_GPR_FITS Resume immutable, predefined train/validation fits.
root=fileparts(mfilename('fullpath')); addpath(root,fullfile(root,'src'));
if nargin<1 || isempty(out),out=fullfile(root,'experiments','hybrid_controlled_fits_v1');end
if nargin<2,limit=8;end
if nargin<3,stopAfter=inf;end
if ~isfolder(out),mkdir(out);end
completed=0;
old=load(fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat'));
a=load(fullfile(root,'experiments','training_size_12_24_48_20261023','n384','train.mat')); D=a.D;
it=ismember(D.id,old.spec.trainIDs); iv=ismember(D.id,old.spec.valIDs);
X=D.X(it,:); Xv=D.X(iv,:); S=D.S(:,it); Sv=D.S(:,iv); w=D.w(:); xi=D.xi;
assert(numel(unique([D.id(it);D.id(iv)]))==24 && size(unique([X;Xv],'rows'),1)==24);
assert(all(X(:,6)~=0) && all(Xv(:,6)~=0) && all(X(:,4)>0) && all(Xv(:,4)>0));
beam=femstudy.fem.beamField(X,xi); beamV=femstudy.fem.beamField(Xv,xi);
scale=(X(:,6)/(-500)).*(1e11./X(:,4)); scaleV=(Xv(:,6)/(-500)).*(1e11./Xv(:,4));
assert(all(scale>0) && all(scaleV>0));
opts=statset('MaxIter',200,'Display','off');
for kind=1:2
    for candidate=1:limit
        file=fullfile(out,sprintf('fit_%d_%d.mat',kind,candidate));
        if isfile(file), fprintf('Reuse %s\n',file); continue; end
        start=tic; rng(42); lastwarn('');
        try
            target=S; if kind==2,target=S-beam;end
            normalized=candidate==8;
            if normalized, target=target./scale'; end
            rank=[2 4]; P=pod_fit(target,w,rank(kind)); Y=pod_encode(P,target);
            M.kind="gp"; M.xm=mean(X,1); M.xs=std(X,0,1); M.xs(M.xs==0)=1;
            M.ym=mean(Y,1); M.ys=std(Y,0,1); M.fixed=M.ys<=1e-12*max(max(abs(Y),[],1),realmin); M.ys(M.fixed)=1;
            Z=(X-M.xm)./M.xs; M.net=cell(1,size(Y,2)); fitInfo=cell(1,size(Y,2));
            if candidate==1, initial=[]; else, values=[.5 1 2 .5 1 2 1]; initial=values(candidate-1); end
            learnSigma=candidate>=5 && candidate<=7;
            for j=1:size(Y,2)
                if M.fixed(j),continue;end
                t=(Y(:,j)-M.ym(j))/M.ys(j);
                args={'KernelFunction','ardsquaredexponential','Standardize',false, ...
                    'Sigma',1e-4,'SigmaLowerBound',1e-8,'ConstantSigma',~learnSigma, ...
                    'Optimizer','quasinewton','OptimizerOptions',opts,'BasisFunction','constant'};
                if ~isempty(initial), args=[args {'KernelParameters',[repmat(initial,1,size(X,2)) 1]}]; end %#ok<AGROW>
                lastwarn(''); gt=tic; M.net{j}=fitrgp(Z,t,args{:}); [msg,warnId]=lastwarn;
                g=M.net{j}; fitInfo{j}=struct('seconds',toc(gt),'warning',msg,'warningID',warnId, ...
                    'kernelParameters',g.KernelInformation.KernelParameters,'sigma',g.Sigma, ...
                    'logLikelihood',g.LogLikelihood,'optimizerInfo',"not exposed by this interface");
            end
            H=P.mean+P.V*predict_reg(M,X)'; Hv=P.mean+P.V*predict_reg(M,Xv)';
            Atrue=pod_encode(P,target); Apred=predict_reg(M,X);
            targetV=Sv; if kind==2,targetV=Sv-beamV;end
            if normalized,targetV=targetV./scaleV';end
            AtrueV=pod_encode(P,targetV); ApredV=predict_reg(M,Xv);
            proj=P.mean+P.V*Atrue'; projV=P.mean+P.V*AtrueV';
            if normalized, H=H.*scale'; Hv=Hv.*scaleV'; proj=proj.*scale'; projV=projV.*scaleV'; end
            if kind==2, H=H+beam; Hv=Hv+beamV; proj=proj+beam; projV=projV+beamV; end
            result=struct('status',"success",'kind',kind,'candidate',candidate,'seed',42, ...
                'initial',initial,'normalized',normalized,'learnSigma',learnSigma,'trainIDs',D.id(it), ...
                'valIDs',D.id(iv),'pod',P,'reg',M,'fitInfo',{fitInfo}, ...
                'trainError',field_error(S,H,w),'valError',field_error(Sv,Hv,w), ...
                'trainProjection',field_error(S,proj,w),'valProjection',field_error(Sv,projV,w), ...
                'trainActualCoeff',Atrue,'trainPredCoeff',Apred,'valActualCoeff',AtrueV,'valPredCoeff',ApredV, ...
                'trainField',H,'valField',Hv,'seconds',toc(start));
        catch err
            result=struct('status',"failed",'kind',kind,'candidate',candidate,'message',getReport(err),'seconds',toc(start));
        end
        tmp=string(file)+".tmp.mat"; save(tmp,'result','-v7.3'); movefile(tmp,file);
        fprintf('kind %d candidate %d: %s\n',kind,candidate,result.status);
        completed=completed+1;
        if completed>=stopAfter,error('controlled:interrupted','Deliberate interruption after checkpoint.');end
    end
end
end
