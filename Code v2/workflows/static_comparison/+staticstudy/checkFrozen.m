function checkFrozen(out)
    %checkFrozen Validate the new freeze and every bound artifact before test access.
    file=fullfile(out,'freeze_manifest.csv');
    seal=fullfile(out,'freeze_manifest.sha256');
    assert(isfile(file) && isfile(seal),'study:FreezeRequired','Verified freeze is required before test access.');
    assert(strcmp(staticstudy.hash(file),strtrim(fileread(seal))),'study:FreezeChanged','Freeze manifest changed.');
    manifest=readtable(file,'TextType','string','Delimiter',',','VariableNamingRule','preserve');
    required=string({fullfile(out,'source_manifest.csv');fullfile(out,'resolved_config.json');  fullfile(out, ...
        'reference_locations.json');  fullfile(out,'candidate_design.mat');  fullfile(out,'selections.mat');  fullfile(out,'training.complete')});
    assert(all(ismember(required,manifest.Path)) && any(contains(manifest.Path,filesep+"runs"+filesep)), ...
        'study:FreezeInvalid',  'Freeze is missing required artifacts.');
    locations=jsondecode(fileread(fullfile(out,'reference_locations.json')));
    for role=["val","interpolation","extrapolation"]
        split="test";
        if role=="val"
            split="val";
        end
        assert(ismember(string(fullfile(locations.(role),split+'.mat')),manifest.Path),  'study:FreezeInvalid', ...
            'Reference is absent from freeze.');
    end
    for k=1:height(manifest)
        assert(isfile(manifest.Path(k)) && strcmp(staticstudy.hash(manifest.Path(k)),manifest.SHA256(k)), ...
            'study:FreezeChanged',  'Frozen artifact changed: %s',  manifest.Path(k));
    end
end
