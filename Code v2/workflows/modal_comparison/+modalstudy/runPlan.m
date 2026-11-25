function runs = runPlan(train,cfg,selections)
%runPlan Declarative list of fits, shared by execution, freeze and cost estimates.
subsets=modalstudy.subsets(train,cfg);
runs=struct('id',{},'method',{},'ids',{},'config',{},'role',{});
for k=1:numel(cfg.training_sizes)
    full=cfg.training_sizes(k)==max(cfg.training_sizes);
    repetitions=numel(cfg.seeds_selection); if full, repetitions=1; end
    for rep=1:repetitions
        for method=string(cfg.methods(:)')
            seeds=cfg.seed_tuning;
            if full && method~="pod_gpr", seeds=cfg.seeds_network(:)'; end
            for seed=seeds
                c=selections.(method); c.seed=seed;
                id=fullfile('runs',sprintf('n%03d_rep%d_%s_seed%d',cfg.training_sizes(k),rep,method,seed));
                runs(end+1)=entry(id,method,subsets{k,rep},c,"main"); %#ok<AGROW>
            end
        end
    end
end
ids=subsets{end,1};
for rank=cfg.controlled_ranks(:)'
    for method=["pod_mlp","pod_gpr"]
        c=selections.(method); c.rank=rank; c.seed=cfg.seed_tuning;
        id=fullfile('controlled',sprintf('rank%d_%s',rank,method));
        runs(end+1)=entry(id,method,ids,c,"rank"); %#ok<AGROW>
    end
end
for repeat=2:cfg.gpr_timing_repetitions
    c=selections.pod_gpr; c.seed=cfg.seed_tuning;
    id=fullfile('timing_repeats',sprintf('pod_gpr_repeat%d',repeat));
    runs(end+1)=entry(id,"pod_gpr",ids,c,"timing"); %#ok<AGROW>
end
end

function r=entry(id,method,ids,c,role)
r=struct('id',string(id),'method',method,'ids',ids,'config',c,'role',role);
end
