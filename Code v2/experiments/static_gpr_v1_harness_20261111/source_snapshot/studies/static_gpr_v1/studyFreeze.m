function studyFreeze(root,studyRoot,out)
assert(isfile(fullfile(out,'training.complete')),'study:IncompleteTraining','Training phase not complete.');
assert(isfile(fullfile(out,'selections.mat')),'study:NoSelection','Missing selected configurations.');
manifest=fullfile(out,'freeze_manifest.csv'); seal=fullfile(out,'freeze_manifest.sha256');
if isfile(manifest) || isfile(seal), studyCheckFrozen(out); return; end
sources=studySources(root,studyRoot); paths=sources.Path;
paths=[paths;string(fullfile(out,'source_manifest.csv'));string(fullfile(out,'candidate_design.mat')); ...
    string(fullfile(out,'selections.mat'));string(fullfile(out,'selections.sha256')); ...
    string(fullfile(out,'training.complete'));string(fullfile(out,'distribution_ids.mat'))];
for role=["val","interpolation","extrapolation"]
    split="test"; if role=="val", split="val"; end
    folder=fullfile(out,'references',role);
    paths=[paths;string(fullfile(folder,split+'.mat'));string(fullfile(folder,'design.csv')); ...
        string(fullfile(folder,'data.sha256'));string(fullfile(folder,'ledger.csv'))]; %#ok<AGROW>
end
for branch=["runs","controlled","distribution","bases","tuning"]
    files=dir(fullfile(out,branch,'**','*.mat'));
    paths=[paths;string(fullfile({files.folder},{files.name}))']; %#ok<AGROW>
end
paths=sort(unique(paths)); sha=strings(numel(paths),1);
for k=1:numel(paths)
    assert(isfile(paths(k)),'study:FreezeMissing','Missing frozen artifact %s',paths(k));
    sha(k)=string(studyHash(paths(k)));
end
T=table(paths,sha,'VariableNames',{'Path','SHA256'});
writetable(T,manifest); writelines(string(studyHash(manifest)),seal);
studyCheckFrozen(out);
end
