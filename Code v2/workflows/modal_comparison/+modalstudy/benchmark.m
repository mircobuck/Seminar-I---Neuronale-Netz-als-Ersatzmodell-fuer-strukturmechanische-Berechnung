function benchmark(out,cfg)
%benchmark New serial FEM timings versus public predictModel, after warm-up.
data=modalstudy.reference(out,"benchmark","test"); idx=cfg.benchmark_indices(:);
folder=fullfile(out,'benchmark'); file=fullfile(folder,'results.mat');
if isfile(file), modalstudy.artifact(file); return; end
if ~isfolder(folder), mkdir(folder); end
X=data.inputParameters(idx,:); ids=data.caseIds(idx); count=numel(ids);
fem=struct('meshDivisor',cfg.mesh_divisor,'geometricOrder',cfg.geometric_order);
solve_modal_case(X(1,:),fem);
femTimes=zeros(count,cfg.benchmark_fem_repetitions);
for repeat=1:cfg.benchmark_fem_repetitions
    order=1:count; if mod(repeat,2)==0, order=fliplr(order); end
    for j=order
        checkpoint=fullfile(folder,'fem',sprintf('case_%d_repeat%d.mat',ids(j),repeat));
        if isfile(checkpoint)
            value=modalstudy.artifact(checkpoint);
        else
            timer=tic; solved=solve_modal_case(X(j,:),fem);
            value=struct('seconds',toc(timer),'internalSeconds',solved.seconds, ...
                'frequencyHz',solved.frequencyHz,'id',ids(j),'parameters',X(j,:));
            modalstudy.artifact(checkpoint,value);
        end
        assert(value.id==ids(j) && isequal(value.parameters,X(j,:)),'modalstudy:Benchmark','Case changed.');
        assert(all(abs(value.frequencyHz-data.frequencyHz(idx(j),:))./data.frequencyHz(idx(j),:)<=1e-5), ...
            'modalstudy:FemMismatch','New FEM frequencies disagree with stored reference.');
        femTimes(j,repeat)=value.seconds;
    end
end
runs=modalstudy.artifact(fullfile(out,'run_plan.mat')); methods=string(cfg.methods(:)');
single=zeros(count,cfg.benchmark_surrogate_repetitions,numel(methods));
batch=zeros(cfg.benchmark_surrogate_repetitions,numel(methods)); loadSeconds=zeros(numel(methods),1);
fitSeconds=loadSeconds; searchSeconds=loadSeconds;
for m=1:numel(methods)
    checkpoint=fullfile(folder,methods(m)+".mat");
    if isfile(checkpoint)
        value=modalstudy.artifact(checkpoint);
    else
        r=runs(find([runs.role]=="main" & [runs.method]==methods(m) & ...
            arrayfun(@(x)numel(x.ids)==max(cfg.training_sizes) && x.config.seed==cfg.seed_tuning,runs),1));
        modelFile=fullfile(out,r.id,'model.mat'); timer=tic;
        model=surrogate.loadModel(modelFile); elapsed=toc(timer);
        request=struct('inputParameters',X,'parameterNames',data.parameterNames, ...
            'parameterUnits',data.parameterUnits,'caseIds',ids);
        one=request; one.inputParameters=X(1,:); one.caseIds=ids(1);
        surrogate.predictModel(model,one); surrogate.predictModel(model,request);
        singles=zeros(count,cfg.benchmark_surrogate_repetitions); batches=zeros(cfg.benchmark_surrogate_repetitions,1);
        for repeat=1:cfg.benchmark_surrogate_repetitions
            for j=1:count
                one.inputParameters=X(j,:); one.caseIds=ids(j); timer=tic;
                surrogate.predictModel(model,one); singles(j,repeat)=toc(timer);
            end
            timer=tic; surrogate.predictModel(model,request); batches(repeat)=toc(timer);
        end
        a=load(fullfile(out,r.id,'result.mat'),'result');
        sessions=readtable(fullfile(out,'tuning',methods(m),'search_sessions.csv'));
        value=struct('single',singles,'batch',batches,'loadSeconds',elapsed, ...
            'fitSeconds',a.result.fitSeconds,'searchSeconds',sum(sessions.elapsed_seconds));
        modalstudy.artifact(checkpoint,value);
    end
    single(:,:,m)=value.single; batch(:,m)=value.batch; loadSeconds(m)=value.loadSeconds;
    fitSeconds(m)=value.fitSeconds; searchSeconds(m)=value.searchSeconds;
end
value=struct('ids',ids,'methods',methods,'femTimes',femTimes,'single',single,'batch',batch, ...
    'loadSeconds',loadSeconds,'fitSeconds',fitSeconds,'searchSeconds',searchSeconds, ...
    'femConfig',fem,'warmup',1,'matlabVersion',string(version));
modalstudy.artifact(file,value);
end
