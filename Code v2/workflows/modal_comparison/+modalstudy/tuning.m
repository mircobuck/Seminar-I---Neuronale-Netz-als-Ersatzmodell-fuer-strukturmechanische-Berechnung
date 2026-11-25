function tuning(out,cfg)
%tuning Prepare common modal training data, then use the shared search.
assert(isfile(fullfile(out,'generation.complete')),'modalstudy:GenerateRequired','Generate/register references first.');
modalstudy.manifest(modalstudy.artifact(fullfile(out,'references.mat')));
timer=tic; started=string(datetime('now','TimeZone','UTC'));
cleanup=onCleanup(@()surrogate.study.recordSearch(out,"all",started,timer)); %#ok<NASGU>
train=modalstudy.reference(out,"tune","train"); val=modalstudy.reference(out,"tune","val");
surrogate.validateTrainingSplits(train,val);
ids=modalstudy.subsets(train,cfg);
data=modalstudy.subset(train,ids{find(cfg.training_sizes==cfg.tuning_size,1),1});
surrogate.study.selectConfigurations(out,cfg,data,val);
end
