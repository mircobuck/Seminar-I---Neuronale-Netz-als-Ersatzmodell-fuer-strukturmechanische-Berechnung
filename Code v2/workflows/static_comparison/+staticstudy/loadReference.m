function data = loadReference(out,role)
    %loadReference Internal read after a phase-level freeze check for test roles.
    locations = jsondecode(fileread(fullfile(out,'reference_locations.json')));
    folder = locations.(role);
    split = "test";
    if role=="val"
        split = "val";
    end
    file = fullfile(folder,split+'.mat');
    assert(strcmp(staticstudy.hash(file),strtrim(fileread(fullfile(folder,'data.sha256')))), ...
        'study:DataChanged',  'Reference dataset checksum changed: %s',  file);
    data = surrogate.loadDataset(file);
end
