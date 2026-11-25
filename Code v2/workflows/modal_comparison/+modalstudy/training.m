function training(out,cfg,fitFcn)
%training Execute the explicit run plan through immutable common checkpoints.
if nargin<3, fitFcn=@surrogate.study.fitCheckpoint; end
modalstudy.manifest(modalstudy.artifact(fullfile(out,'references.mat')));
file=fullfile(out,'selections.mat');
assert(isfile(file) && strcmp(surrogate.study.hash(file),strtrim(fileread(fullfile(out,'selections.sha256')))), ...
    'study:SelectionChanged','Tune first; selected settings must be unchanged.');
a=load(file,'selections');
train=modalstudy.reference(out,"train","train"); val=modalstudy.reference(out,"train","val");
surrogate.validateTrainingSplits(train,val);
runs=modalstudy.runPlan(train,cfg,a.selections);
modalstudy.artifact(fullfile(out,'run_plan.mat'),runs);
for k=1:numel(runs)
    r=runs(k); data=modalstudy.subset(train,r.ids);
    fitFcn(fullfile(out,r.id),r.method,data,val,r.config);
end
writelines("All planned fits attempted; statuses are recorded in checkpoints.",fullfile(out,'training.complete'));
end
