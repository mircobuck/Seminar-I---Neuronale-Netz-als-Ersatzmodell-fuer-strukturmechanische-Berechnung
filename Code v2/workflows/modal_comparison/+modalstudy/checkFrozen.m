function manifest = checkFrozen(out)
%checkFrozen Verify the seal and required artifacts before access to test labels.
file=fullfile(out,'freeze_manifest.csv'); seal=fullfile(out,'freeze_manifest.sha256');
assert(isfile(file) && isfile(seal),'study:FreezeRequired','Freeze is required before test access.');
assert(strcmp(surrogate.study.hash(file),strtrim(fileread(seal))),'study:FreezeChanged','Freeze manifest changed.');
manifest=readtable(file,'TextType','string');
required=string(fullfile(out,{'source_manifest.csv','resolved_config.json','reference_locations.json', ...
    'candidate_design.mat','references.mat','selections.mat','selections.sha256','run_plan.mat','training.complete'}));
assert(all(ismember(required,manifest.Path)),'study:FreezeInvalid','Incomplete freeze manifest.');
modalstudy.manifest(manifest);
refs=modalstudy.artifact(fullfile(out,'references.mat'));
assert(all(ismember(refs.Path,manifest.Path)),'study:FreezeInvalid','References absent from freeze.');
end
