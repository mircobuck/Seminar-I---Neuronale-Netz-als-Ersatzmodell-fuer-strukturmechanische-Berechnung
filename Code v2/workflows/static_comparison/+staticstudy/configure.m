function cfg = configure(root, configFile, localFile)
    %configure Separate scientific settings from machine-specific paths.
    configFile = resolve(root,configFile);
    localFile = resolve(root,localFile);
    cfg = jsondecode(fileread(configFile));
    cfg.paths = jsondecode(fileread(localFile));
    cfg.config_file = configFile;
    cfg.local_file = localFile;
    for name = ["training_file","training_blocks","reference_run","output_dir"]
        cfg.paths.(name) = resolve(root,cfg.paths.(name));
    end
    cfg.paths.exclusion_designs = string(cfg.paths.exclusion_designs);
    for k=1:numel(cfg.paths.exclusion_designs)
        cfg.paths.exclusion_designs(k) = resolve(root,cfg.paths.exclusion_designs(k));
    end
    cfg.methods = string(cfg.methods);
    cfg.reference_mode = string(cfg.reference_mode);
    assert(isequal(cfg.methods(:),["mlp";"rbf";"pod_mlp";"pod_gpr"]),  'study:Methods', ...
        'The static comparison requires exactly its four documented methods.');
    assert(any(cfg.reference_mode==["reuse","generate"]),'study:ReferenceMode','Invalid reference mode.');
    assert(any(cfg.training_sizes==cfg.tuning_size),'study:TuningSize','Tuning size is missing from training sizes.');
    assert(mod(cfg.distribution_size,2)==0 && cfg.distribution_size<=cfg.tuning_size,  'study:DistributionSize', ...
        'Distribution size must be even and no larger than the tuning pool.');
    assert(cfg.prediction_batch_size<=cfg.counts.interpolation,'study:BatchSize', ...
        'Prediction batch exceeds reference count.');
    assert(all(cfg.benchmark_indices>=1 & cfg.benchmark_indices<=cfg.counts.interpolation), ...
        'study:BenchmarkCases',  'Benchmark indices exceed interpolation data.');
end

function result = resolve(root,value)
    value = char(value);
    if isempty(regexp(value,'^([A-Za-z]:[\\/]|[\\/])','once'))
        value = fullfile(root,value);
    end
    result = char(java.io.File(value).getCanonicalPath());
end
