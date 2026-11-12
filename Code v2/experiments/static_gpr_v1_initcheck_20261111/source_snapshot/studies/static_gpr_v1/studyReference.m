function data=studyReference(out,phase,role)
% Only the final evaluation phase may request either test role.
phase=string(phase); role=string(role);
assert(any(phase==["tune","train","evaluate"]),'study:Phase','Unknown phase.');
assert(any(role==["val","interpolation","extrapolation"]),'study:Role','Unknown role.');
assert(role=="val" || phase=="evaluate",'study:TestLabelGate', ...
    'Training and tuning may not load test references.');
if phase=="evaluate", studyCheckFrozen(out); end
split="test"; if role=="val", split="val"; end
folder=fullfile(out,'references',role); filename=fullfile(folder,split+'.mat');
expected=strtrim(fileread(fullfile(folder,'data.sha256')));
assert(strcmp(studyHash(filename),expected),'study:DataChanged','Reference hash changed.');
data=surrogate.loadDataset(filename);
end
