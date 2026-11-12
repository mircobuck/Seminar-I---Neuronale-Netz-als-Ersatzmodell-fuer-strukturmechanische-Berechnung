function initialize(root,out,cfg)
    %initialize Create a new run's provenance without mutating previous studies.
    if isfolder(out)
        staticstudy.verify(root,out,cfg);
        assert(isfile(fullfile(out,'environment.mat')),'study:IncompleteInit', ...
            'Incomplete initialization; use a new run directory.');
        return
    end
    assert(~strcmp(out,cfg.paths.reference_run),'study:Output','Output must differ from the historical reference run.');
    staticstudy.requireSpace(root);
    manifest=staticstudy.sources(root,cfg);
    train=surrogate.loadDataset(cfg.paths.training_file);
    assert(train.modality=="static",'study:StaticOnly','Only static displacement fields are supported.');
    blocks=staticstudy.trainingBlocks(train,cfg);
    assert(nnz(blocks)==nnz(~blocks),'study:Blocks','Training blocks must be balanced.');
    mkdir(out);
    writetable(manifest,fullfile(out,'source_manifest.csv'));
    writelines(jsonencode(cfg,PrettyPrint=true),fullfile(out,'resolved_config.json'));
    locations=struct;
    historicalReferenceCosts=table;
    if cfg.reference_mode=="reuse"
        source=cfg.paths.reference_run;
        for name=["candidate_design.mat","candidate_design.csv","candidate_design.sha256"]
            copyfile(fullfile(source,name),fullfile(out,name));
        end
        assert(strcmp(staticstudy.hash(fullfile(out,'candidate_design.mat')),  strtrim(fileread(fullfile(out, ...
            'candidate_design.sha256')))),'study:DesignChanged','Historical design checksum mismatch.');
        historicalReferenceCosts=readtable(fullfile(source,'reference_costs.csv'),'TextType','string');
        for role=["val","interpolation","extrapolation"]
            locations.(role)=fullfile(source,'references',role);
        end
    else
        staticstudy.createDesign(out,cfg);
        for role=["val","interpolation","extrapolation"]
            locations.(role)=fullfile(out,'references',role);
        end
    end
    writelines(jsonencode(locations,PrettyPrint=true),fullfile(out,'reference_locations.json'));
    [status,commit]=system(sprintf('git -C "%s" rev-parse HEAD',root));
    assert(status==0,'study:Git','Cannot record local Git revision.');
    budget=Inf;
    if ~isempty(cfg.total_budget_seconds)
        budget=cfg.total_budget_seconds;
    end
    metadata=struct('startedAt',string(datetime('now','TimeZone','UTC')),  'startedPosix', ...
        posixtime(datetime('now','TimeZone', ...
        'UTC')),  'budgetSeconds',  budget,  'pilotSpentSeconds',  0,  'gitCommit',  string(strtrim(commit)),  'matlabVersion',  string(version),  'products',  {ver},  'computer',  string(computer),  'cpu',  string(getenv('PROCESSOR_IDENTIFIER')),  'knownReferenceRepeat',  cfg.known_reference_repeat,  'historicalReferenceCosts',  historicalReferenceCosts);
    save(fullfile(out,'environment.mat'),'metadata');
end
