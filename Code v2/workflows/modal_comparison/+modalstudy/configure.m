function cfg = configure(root,configFile,localFile)
%configure Scientific settings and local paths; all paths relative to Code v2.
cfg=jsondecode(fileread(resolve(root,configFile)));
cfg.paths=jsondecode(fileread(resolve(root,localFile)));
cfg.config_file=resolve(root,configFile); cfg.local_file=resolve(root,localFile);
for key=["training_file","validation_file","test_file","design_file","output_dir","presentation_file"]
    cfg.paths.(key)=resolve(root,cfg.paths.(key));
end
cfg.methods=string(cfg.methods(:)'); cfg.reference_mode=string(cfg.reference_mode);
assert(isequal(cfg.methods,["mlp","rbf","pod_mlp","pod_gpr"]),'modalstudy:Methods','Expected the four study methods.');
assert(any(cfg.reference_mode==["reuse","generate"]),'modalstudy:ReferenceMode','Use reuse or generate.');
sizes=cfg.training_sizes(:);
assert(all(sizes>=2 & sizes==fix(sizes)) && issorted(sizes) && numel(unique(sizes))==numel(sizes) && ...
    any(sizes==cfg.tuning_size) && max(sizes)==cfg.counts.train, ...
    'modalstudy:Sizes','Invalid training or tuning sizes.');
assert(all(cfg.controlled_ranks>=1 & cfg.controlled_ranks<=6 & cfg.controlled_ranks==fix(cfg.controlled_ranks)), ...
    'modalstudy:Ranks','Ranks must be integers 1 through 6.');
assert(cfg.seed_tuning==cfg.seeds_network(1) && numel(unique(cfg.seeds_network))==numel(cfg.seeds_network), ...
    'modalstudy:Seeds','The first network seed must equal the tuning seed.');
for key=["seeds_network","seeds_selection"]
    v=cfg.(key); assert(~isempty(v) && all(isfinite(v) & v>=0 & v==fix(v)), ...
        'modalstudy:Seeds','Invalid random seeds.');
end
for key=["max_epochs","mini_batch_size","benchmark_fem_repetitions","benchmark_surrogate_repetitions","gpr_timing_repetitions"]
    v=cfg.(key); assert(isscalar(v) && isfinite(v) && v>=1 && v==fix(v),'modalstudy:Config','Invalid %s.',key);
end
assert(cfg.search_budget_seconds_per_family>0 && isfinite(cfg.search_budget_seconds_per_family), ...
    'modalstudy:Config','Search budget must be positive.');
assert(string(cfg.training_optimizer)=="adam" && cfg.learning_rate>0,'modalstudy:Config','Invalid training settings.');
assert(all(cfg.benchmark_indices>=1 & cfg.benchmark_indices<=cfg.counts.test & ...
    cfg.benchmark_indices==fix(cfg.benchmark_indices)) && numel(unique(cfg.benchmark_indices))==numel(cfg.benchmark_indices), ...
    'modalstudy:Benchmark','Invalid benchmark case indices.');
assert(cfg.mesh_divisor>=1 && cfg.mesh_divisor==fix(cfg.mesh_divisor) && string(cfg.geometric_order)=="quadratic", ...
    'modalstudy:Mesh','Expected a positive mesh divisor and quadratic elements.');
end

function p=resolve(root,p)
p=char(p);
if isempty(regexp(p,'^([A-Za-z]:[\\/]|[\\/])','once')), p=fullfile(root,p); end
p=char(java.io.File(p).getCanonicalPath());
end
