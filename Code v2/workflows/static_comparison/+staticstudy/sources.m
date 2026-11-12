function manifest = sources(root,cfg)
    %sources Bind active code, scientific/local configuration, and input files.
    paths = string({fullfile(root,'runStaticStudy.m'); fullfile(root,'setupProject.m');  fullfile(root, ...
        'loadFemDataset.m');  cfg.config_file;  cfg.local_file;  cfg.paths.training_file;  fullfile(fileparts(cfg.paths.training_file),'design.csv');  cfg.paths.training_blocks});
    for folder=["+surrogate","fem_core","workflows/static_comparison"]
        files=dir(fullfile(root,folder,'**','*.m'));
        paths=[paths;string(fullfile({files.folder},{files.name}))']; %#ok<AGROW>
    end
    paths=[paths;string(fullfile(root,'workflows','static_comparison', ...
        'studyPlots.py'));  cfg.paths.exclusion_designs(:)];
    if cfg.reference_mode=="reuse"
        for name=["candidate_design.mat","candidate_design.csv","candidate_design.sha256"]
            paths(end+1)=string(fullfile(cfg.paths.reference_run,name)); %#ok<AGROW>
        end
        for role=["val","interpolation","extrapolation"]
            folder=fullfile(cfg.paths.reference_run,'references',role);
            split="test";
            if role=="val"
                split="val";
            end
            for name=[split+".mat","design.csv","data.sha256","ledger.csv","generation_sessions.csv"]
                paths(end+1)=string(fullfile(folder,name)); %#ok<AGROW>
            end
        end
    end
    paths=sort(unique(paths));
    hashes=strings(size(paths));
    for k=1:numel(paths)
        hashes(k)=string(staticstudy.hash(paths(k)));
    end
    manifest=table(paths,hashes,'VariableNames',{'Path','SHA256'});
end
