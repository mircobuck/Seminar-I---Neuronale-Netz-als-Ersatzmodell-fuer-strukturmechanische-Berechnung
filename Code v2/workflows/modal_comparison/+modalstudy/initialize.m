function initialize(root,out,cfg)
%initialize Record provenance and split designs without reading test labels.
if isfolder(out), modalstudy.verify(root,out,cfg); return; end
assert(usejava('jvm') && ~isempty(which('trainnet')) && ~isempty(which('fitrgp')) && ~isempty(which('femodel')), ...
    'modalstudy:Products','MATLAB, Java, Deep Learning, Statistics and PDE Toolbox are required.');
surrogate.study.requireSpace(root);
sources=modalstudy.sources(root,cfg);
design=readtable(cfg.paths.design_file,'TextType','string'); c=surrogate.contract("modal");
assert(all(ismember(["id","split",c.parameterNames],string(design.Properties.VariableNames))), ...
    'modalstudy:Design','Missing design columns.');
X=design{:,cellstr(c.parameterNames)};
assert(all(isfinite(X),'all') && all(X(:,[1:4 6])>0,'all') && all(X(:,5)>-1 & X(:,5)<.5) && ...
    numel(unique(design.id))==height(design) && size(unique(X,'rows'),1)==height(design), ...
    'modalstudy:Design','Invalid or overlapping design cases.');
assert(all(ismember(design.split,["train","val","test"])),'modalstudy:Design','Unknown split.');
for split=["train","val","test"]
    assert(nnz(design.split==split)==cfg.counts.(split),'modalstudy:Count','Unexpected %s count.',split);
end
mkdir(out);
writetable(sources,fullfile(out,'source_manifest.csv'));
writelines(jsonencode(cfg,PrettyPrint=true),fullfile(out,'resolved_config.json'));
modalstudy.artifact(fullfile(out,'candidate_design.mat'),design);
locations=struct('train',cfg.paths.training_file,'val',cfg.paths.validation_file,'test',cfg.paths.test_file);
if cfg.reference_mode=="generate"
    for split=["train","val","test"]
        locations.(split)=fullfile(out,'references',split,split+'.mat');
    end
end
writelines(jsonencode(locations,PrettyPrint=true),fullfile(out,'reference_locations.json'));
[status,commit]=system(sprintf('git -C "%s" rev-parse HEAD',root));
assert(status==0,'modalstudy:Git','Cannot record revision.');
metadata=struct('startedAt',string(datetime('now','TimeZone','UTC')), ...
    'startedPosix',posixtime(datetime('now','TimeZone','UTC')), 'budgetSeconds',Inf, ...
    'pilotSpentSeconds',0,'gitCommit',strtrim(commit),'matlabVersion',version, ...
    'products',{ver},'knownReferenceRepeat',true);
save(fullfile(out,'environment.mat'),'metadata');
end
