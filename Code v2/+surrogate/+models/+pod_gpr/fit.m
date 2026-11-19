function [state,report] = fit(data,config)
%fit Fit one exact Gaussian process per weighted POD coefficient.
assert(string(data.modality)=="static",'surrogate:pod_gpr:Task','Static fields only.');
assert(isfield(config,'rank'),'surrogate:pod_gpr:Config','Missing rank.');
if ~isfield(config,'kernel'), config.kernel="ardsquaredexponential"; end
if ~isfield(config,'basisFunction'), config.basisFunction="constant"; end
if ~isfield(config,'sigma'), config.sigma=1e-4; end
assert(isscalar(string(config.kernel)) && any(string(config.kernel)==["ardsquaredexponential","ardmatern52"]), ...
    'surrogate:pod_gpr:Config','Unsupported kernel.');
assert(isscalar(string(config.basisFunction)) && any(string(config.basisFunction)==["constant","linear"]), ...
    'surrogate:pod_gpr:Config','Unsupported basis function.');
assert(isscalar(config.sigma) && isnumeric(config.sigma) && isfinite(config.sigma) && config.sigma>1e-8, ...
    'surrogate:pod_gpr:Config','Sigma must exceed the positive lower bound.');
t=tic; prepared=[];
if isfield(config,'preparedPod'), prepared=config.preparedPod; end
pod=surrogate.models.shared.fitPod(data,config.rank,"pod_gpr",prepared); podSeconds=toc(t);
t=tic; X=double(data.inputParameters); inputMean=mean(X,1); inputScale=std(X,0,1);
activeInputs=inputScale>0; inputScale(~activeInputs)=1;
X=(X(:,activeInputs)-inputMean(activeInputs))./inputScale(activeInputs);
coeff=(pod.basis'*(pod.weights.*(double(data.displacementFields)-pod.fieldMean)))';
coefficientMean=mean(coeff,1); coefficientScale=std(coeff,0,1);
constantCoefficients=coefficientScale==0; coefficientScale(constantCoefficients)=1;
Z=(coeff-coefficientMean)./coefficientScale; preprocessSeconds=toc(t);
models=cell(1,config.rank); starts=cell(1,config.rank); opt=statset('fitrgp');
opt.MaxIter=500; opt.TolFun=1e-6; opt.TolX=1e-8; opt.Display='off';
t=tic;
for j=1:config.rank
    if constantCoefficients(j), continue; end
    assert(any(activeInputs),'surrogate:pod_gpr:ConstantInputs', ...
        'Nonconstant target with all constant inputs cannot be fitted.');
    best=-inf; details=repmat(struct('likelihood',NaN,'warningId',"",'warningMessage',"", ...
        'convergenceStatus',"not_reported"),1,2);
    for k=1:2
        scales=[0.5,2]; initial=[repmat(scales(k),sum(activeInputs),1);1];
        lastwarn('');
        candidate=fitrgp(X,Z(:,j),'FitMethod','exact','PredictMethod','exact', ...
            'KernelFunction',char(config.kernel),'BasisFunction',char(config.basisFunction), ...
            'KernelParameters',initial,'Sigma',config.sigma,'SigmaLowerBound',1e-8, ...
            'ConstantSigma',true,'Standardize',false,'Optimizer','quasinewton','OptimizerOptions',opt);
        [warningMessage,warningId]=lastwarn;
        convergenceStatus="not_reported";
        if ~isempty(warningId), convergenceStatus="warning_recorded"; end
        details(k)=struct('likelihood',candidate.LogLikelihood,'warningId',string(warningId), ...
            'warningMessage',string(warningMessage),'convergenceStatus',convergenceStatus);
        if candidate.LogLikelihood>best, best=candidate.LogLikelihood; models{j}=candidate; end
    end
    assert(~isempty(models{j}),'surrogate:pod_gpr:Fit','No finite GPR likelihood.');
    starts{j}=details;
end
regressionSeconds=toc(t);
state=struct('basis',pod.basis,'fieldMean',pod.fieldMean,'weights',pod.weights, ...
    'numericalRank',pod.numericalRank,'podFingerprint',pod.fingerprint,'retainedEnergy',pod.retainedEnergy, ...
    'inputMean',inputMean,'inputScale',inputScale,'activeInputs',activeInputs, ...
    'coefficientMean',coefficientMean,'coefficientScale',coefficientScale, ...
    'constantCoefficients',constantCoefficients,'models',{models},'starts',{starts}, ...
    'optimizerOptions',opt,'initialLengthScales',[0.5 2], ...
    'sigmaLowerBound',1e-8,'fitMethod',"exact",'settings',config);
report=struct('method',"pod_gpr",'trainingCount',size(X,1),'numericalRank',pod.numericalRank, ...
    'podRank',config.rank,'retainedEnergy',pod.retainedEnergy,'settings',config, ...
    'timing',struct('podSeconds',podSeconds,'preprocessSeconds',preprocessSeconds,'regressionSeconds',regressionSeconds));
end
