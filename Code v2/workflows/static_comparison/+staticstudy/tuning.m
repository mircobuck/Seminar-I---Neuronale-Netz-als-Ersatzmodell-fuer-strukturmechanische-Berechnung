function tuning(~,out,cfg)
    % Tune against validation only. Each attempt is an immutable checkpoint.
    assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen', ...
        'Tuning is forbidden after the freeze.');
    globalTimer=tic;
    globalStart=string(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
    globalCleanup=onCleanup(@()staticstudy.recordSearch(out,"all",globalStart,globalTimer));
    train=surrogate.loadDataset(cfg.paths.training_file);
    val=staticstudy.reference(out,"tune","val");
    surrogate.validateTrainingSplits(train,val);
    subsets=surrogate.study.nestedTrainingSubsets(train.caseIds,staticstudy.trainingBlocks(train,cfg), ...
        cfg.training_sizes,  cfg.seeds_selection);
    data=staticstudy.subset(train,  subsets{find(cfg.training_sizes==cfg.tuning_size,1),1});
    surrogate.study.selectConfigurations(out,cfg,data,val);
    clear globalCleanup
end
