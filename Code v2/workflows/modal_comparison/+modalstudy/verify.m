function verify(root,out,cfg)
%verify Source or input changes require a new run directory.
assert(isfile(fullfile(out,'environment.mat')),'modalstudy:InitRequired','Initialize a new run first.');
saved=readtable(fullfile(out,'source_manifest.csv'),'TextType','string');
assert(isequal(saved,modalstudy.sources(root,cfg)),'modalstudy:SourceChanged','Source or input changed; use a new run.');
resolved=jsondecode(fileread(fullfile(out,'resolved_config.json')));
assert(isequaln(resolved,jsondecode(jsonencode(cfg))),'modalstudy:ConfigChanged','Resolved configuration changed.');
modalstudy.artifact(fullfile(out,'candidate_design.mat'));
end
