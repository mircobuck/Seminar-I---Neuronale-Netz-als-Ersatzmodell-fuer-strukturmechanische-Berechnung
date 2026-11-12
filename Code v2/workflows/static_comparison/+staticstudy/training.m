function training(~,out,cfg)
    assert(~isfile(fullfile(out,'freeze_manifest.csv')),'study:AlreadyFrozen', ...
        'Training is forbidden after the freeze.');
    train=surrogate.loadDataset(cfg.paths.training_file);
    val=staticstudy.reference(out,"train","val");
    surrogate.validateTrainingSplits(train,val);
    selectionFile=fullfile(out,'selections.mat');
    assert(isfile(selectionFile) && strcmp(staticstudy.hash(selectionFile),strtrim(fileread(fullfile(out, ...
        'selections.sha256')))),  'study:SelectionChanged',  'Selection missing or changed.');
    a=load(selectionFile,'selections');
    selections=a.selections;
    subsets=surrogate.study.nestedTrainingSubsets(train.caseIds,staticstudy.trainingBlocks(train,cfg), ...
        cfg.training_sizes,  cfg.seeds_selection);
    methods=string(cfg.methods(:)');
    for n=1:numel(cfg.training_sizes)
        repeats=numel(cfg.seeds_selection);
        if cfg.training_sizes(n)==max(cfg.training_sizes)
            repeats=1;
        end
        for rep=1:repeats
            data=staticstudy.subset(train,subsets{n,rep});
            order=circshift(methods,[0,mod(n+rep,4)]);
            for method=order
                c=selections.(method);
                c.seed=cfg.seed_tuning;
                folder=fullfile(out,'runs',sprintf('n%03d_rep%d_%s_seed%d',numel(data.caseIds),rep,method,c.seed));
                staticstudy.fitCheckpoint(folder,method,data,val,c);
            end
            for rank=cfg.controlled_ranks(:)'
                podFolder=fullfile(out,'bases',sprintf('n%03d_rep%d_rank%d',numel(data.caseIds),rep,rank));
                if ~isfolder(podFolder)
                    mkdir(podFolder);
                end
                podFile=fullfile(podFolder,'pod.mat');
                pod=[];
                if isfile(podFile) && ~isfile(fullfile(podFolder,'pod.sha256'))
                    movefile(podFile,fullfile(podFolder,'pod_incomplete.mat'));
                end
                if isfile(podFile)
                    assert(strcmp(staticstudy.hash(podFile),strtrim(fileread(fullfile(podFolder, ...
                        'pod.sha256')))),  'study:PodChanged',  'Saved basis changed.');
                    a=load(podFile,  'pod',  'podSeconds');
                    pod=a.pod;
                else
                    try
                        staticstudy.requireBudget(out,60);
                        staticstudy.requireSpace(out);
                        t=tic;
                        pod=surrogate.models.shared.fitPod(data,rank,"pod_gpr",[]);
                        podSeconds=toc(t);
                        save(podFile,'pod','podSeconds','-v7.3');
                        writelines(string(staticstudy.hash(podFile)),fullfile(podFolder,'pod.sha256'));
                    catch err
                        if ~strcmp(err.identifier,'surrogate:pod_gpr:Rank')
                            rethrow(err);
                        end
                        writelines(string(err.identifier)+": "+string(err.message),fullfile(podFolder, ...
                            'invalid_rank.txt'));
                    end
                end
                for method=["pod_mlp","pod_gpr"]
                    c=selections.(method);
                    c.rank=rank;
                    c.seed=cfg.seed_tuning;
                    if ~isempty(pod)
                        c.preparedPod=pod;
                    end
                    folder=fullfile(out,'controlled',sprintf('n%03d_rep%d_rank%d_%s',numel(data.caseIds),rep, ...
                        rank,method));
                    staticstudy.fitCheckpoint(folder,method,data,val,c);
                end
            end
        end
    end
    fullData=staticstudy.subset(train,subsets{end,1});
    for method=["mlp","rbf","pod_mlp"]
        for seed=reshape(cfg.seeds_network(2:end),1,[])
            c=selections.(method);
            c.seed=seed;
            folder=fullfile(out,'runs',sprintf('n%03d_rep1_%s_seed%d',numel(fullData.caseIds),method,seed));
            staticstudy.fitCheckpoint(folder,method,fullData,val,c);
        end
    end
    for repeat=2:cfg.gpr_timing_repetitions
        c=selections.pod_gpr;
        c.seed=cfg.seed_tuning;
        folder=fullfile(out,'timing_repeats',sprintf('n%03d_pod_gpr_repeat%d',numel(fullData.caseIds),repeat));
        staticstudy.fitCheckpoint(folder,"pod_gpr",fullData,val,c);
    end
    [spaceIds,skewIds]=staticstudy.distribution(train,subsets{find(cfg.training_sizes==cfg.tuning_size,1),1},cfg);
    save(fullfile(out,'distribution_ids.mat'),'spaceIds','skewIds');
    for method=methods
        for kind=["space","skew"]
            ids=spaceIds;
            if kind=="skew"
                ids=skewIds;
            end
            c=selections.(method);
            c.seed=cfg.seed_tuning;
            folder=fullfile(out,'distribution',sprintf('%s_%s',kind,method));
            staticstudy.fitCheckpoint(folder,method,staticstudy.subset(train,ids),val,c);
        end
    end
    writelines("training phases completed",fullfile(out,'training.complete'));
end
