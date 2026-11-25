function completeModalFixture(out,cfg,withEvaluation)
%completeModalFixture Mock saved fits/results for state and report tests only.
if nargin<3, withEvaluation=true; end
train=modalstudy.reference(out,"train","train");
val=modalstudy.reference(out,"train","val");
selections=struct;
for method=cfg.methods
    c=surrogate.study.candidates(method,cfg); selections.(method)=c{1};
end
save(fullfile(out,'selections.mat'),'selections');
writelines(string(surrogate.study.hash(fullfile(out,'selections.mat'))),fullfile(out,'selections.sha256'));
runs=modalstudy.runPlan(train,cfg,selections); modalstudy.artifact(fullfile(out,'run_plan.mat'),runs);
for k=1:numel(runs)
    r=runs(k); folder=fullfile(out,r.id); mkdir(folder);
    model=struct('mockArtifact',true); surrogate.saveModel(fullfile(folder,'model.mat'),model);
    result=struct('method',r.method,'status',"ok",'message',"",'fitSeconds',1, ...
        'trainingIds',r.ids,'validationIds',val.caseIds,'config',r.config,'report',struct, ...
        'modelHash',surrogate.study.hash(fullfile(folder,'model.mat')));
    save(fullfile(folder,'result.mat'),'result');
    writelines(string(surrogate.study.hash(fullfile(folder,'result.mat'))),fullfile(folder,'result.sha256'));
end
for method=cfg.methods
    folder=fullfile(out,'tuning',method); mkdir(folder);
    info=struct('attempted',1,'candidates',1,'winner',1); save(fullfile(folder,'search_summary.mat'),'info');
    sessions=table(method,"fixture",1,'VariableNames',{'method','start_utc','elapsed_seconds'});
    writetable(sessions,fullfile(folder,'search_sessions.csv'));
end
writelines("Synthetic fixture only",fullfile(out,'training.complete'));
modalstudy.freeze(out,cfg);
if ~withEvaluation, return; end
data=modalstudy.reference(out,"evaluate","test");
[analytic,families]=modalstudy.analytical(data.inputParameters);
ref=struct('caseIds',data.caseIds,'inputParameters',data.inputParameters,'frequencyHz',data.frequencyHz, ...
    'analyticHz',analytic,'analyticFamilies',families,'historicalSeconds',data.computationTimeSeconds);
modalstudy.artifact(fullfile(out,'evaluation','test_reference.mat'),ref);
for k=1:numel(runs)
    r=runs(k); n=numel(data.caseIds);
    q=struct('id',r.id,'method',r.method,'role',r.role,'N',numel(r.ids),'config',r.config, ...
        'status',"ok",'message',"",'fitSeconds',1,'report',struct, ...
        'predictionHz',1.01*data.frequencyHz,'absoluteHz',.01*data.frequencyHz,'relative',.01*ones(n,6), ...
        'nonpositive',false(n,6),'orderViolation',false(n,1),'loadSeconds',.01, ...
        'predictionSeconds',.01,'modelBytes',100,'projectionSquared',zeros(n,1), ...
        'regressionSquared',zeros(n,1),'reconstructionSquared',zeros(n,1),'decompositionResidual',zeros(n,1));
    modalstudy.artifact(fullfile(out,'evaluation',r.id,'observed.mat'),q);
end
% Tiny timing fixture exercises report calculations; it performs no benchmark.
b=struct('ids',data.caseIds(1:2),'methods',cfg.methods,'femTimes',2*ones(2,2), ...
    'single',.01*ones(2,2,4),'batch',.015*ones(2,4),'loadSeconds',.1*ones(4,1), ...
    'fitSeconds',ones(4,1),'searchSeconds',ones(4,1));
modalstudy.artifact(fullfile(out,'benchmark','results.mat'),b);
writelines("Synthetic evaluations only",fullfile(out,'evaluation.complete'));
end
