function studyVerifyRepair(out)
folder=fullfile(out,'evaluation_repair_v1'); manifest=fullfile(folder,'repair_manifest.json');
seal=fullfile(folder,'repair_manifest.sha256');
assert(isfile(manifest) && isfile(seal) && strcmp(studyHash(manifest),strtrim(fileread(seal))), ...
    'study:RepairChanged','Repair manifest missing or changed.');
m=jsondecode(fileread(manifest));
assert(strcmp(studyHash(fullfile(out,'freeze_manifest.csv')),m.freezeSha256), ...
    'study:FreezeChanged','Original freeze changed.');
for k=1:numel(m.files)
    assert(isfile(m.files(k).path) && strcmp(studyHash(m.files(k).path),m.files(k).sha256), ...
        'study:RepairChanged','Repair or test source changed: %s',m.files(k).path);
end
end
