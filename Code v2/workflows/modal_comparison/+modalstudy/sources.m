function manifest = sources(root,cfg)
%sources Bind executable source, configurations and immutable input artifacts.
paths=string({fullfile(root,'runModalStudy.m');fullfile(root,'setupProject.m'); ...
    fullfile(root,'loadFemDataset.m');cfg.config_file;cfg.local_file; ...
    cfg.paths.training_file;cfg.paths.validation_file;cfg.paths.test_file; ...
    cfg.paths.design_file;cfg.paths.presentation_file});
for key=["training_file","validation_file","test_file"]
    paths(end+1)=string(fullfile(fileparts(cfg.paths.(key)),'design.csv')); %#ok<AGROW>
end
for folder=["+surrogate","fem_core","workflows/modal_comparison"]
    files=dir(fullfile(root,folder,'**','*.m'));
    paths=[paths;string(fullfile({files.folder},{files.name}))']; %#ok<AGROW>
end
manifest=modalstudy.manifest(paths);
end
