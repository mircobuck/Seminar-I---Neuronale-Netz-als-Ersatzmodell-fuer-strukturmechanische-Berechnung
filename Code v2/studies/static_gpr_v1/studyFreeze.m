function studyFreeze(root,studyRoot,out)
assert(isfile(fullfile(out,'training.complete')),'study:IncompleteTraining','Training phase not complete.');
assert(isfile(fullfile(out,'selections.mat')),'study:NoSelection','Missing selected configurations.');
assert(strcmp(studyHash(fullfile(out,'selections.mat')),strtrim(fileread(fullfile(out,'selections.sha256')))), ...
    'study:SelectionChanged','Selected configurations changed.');
assert(strcmp(studyHash(fullfile(out,'candidate_design.mat')),strtrim(fileread(fullfile(out,'candidate_design.sha256')))), ...
    'study:DesignChanged','Candidate design changed.');
for branch=["runs","controlled","distribution","tuning","timing_repeats"]
    records=dir(fullfile(out,branch,'**','result.mat'));
    for k=1:numel(records)
        [~,leaf]=fileparts(records(k).folder); if startsWith(string(leaf),"tp"), continue; end
        file=fullfile(records(k).folder,records(k).name); sealFile=fullfile(records(k).folder,'result.sha256');
        assert(isfile(sealFile) && strcmp(studyHash(file),strtrim(fileread(sealFile))), ...
            'study:CheckpointChanged','Fit checkpoint changed: %s',file);
        a=load(file,'result'); result=a.result;
        if result.status=="ok"
            modelFile=fullfile(records(k).folder,'model.mat');
            assert(isfile(modelFile) && strcmp(studyHash(modelFile),result.modelHash), ...
                'study:CheckpointChanged','Model checkpoint changed: %s',modelFile);
        end
    end
end
manifest=fullfile(out,'freeze_manifest.csv'); seal=fullfile(out,'freeze_manifest.sha256');
if isfile(manifest) && isfile(seal), studyCheckFrozen(out); return; end
assert(~isfile(seal),'study:FreezeInvalid','Freeze seal exists without manifest.');
if isfile(manifest), movefile(manifest,fullfile(out,'freeze_manifest_incomplete.csv')); end
sources=studySources(root,studyRoot); paths=sources.Path;
paths=[paths;string(fullfile(out,'source_manifest.csv'));string(fullfile(out,'candidate_design.mat')); ...
    string(fullfile(out,'candidate_design.csv'));string(fullfile(out,'candidate_design.sha256')); ...
    string(fullfile(out,'environment.mat')); ...
    string(fullfile(out,'selections.mat'));string(fullfile(out,'selections.sha256')); ...
    string(fullfile(out,'training.complete'));string(fullfile(out,'distribution_ids.mat')); ...
    string(fullfile(out,'search_sessions.csv'))];
for role=["val","interpolation","extrapolation"]
    split="test"; if role=="val", split="val"; end
    folder=fullfile(out,'references',role);
    dataFile=fullfile(folder,split+'.mat');
    assert(isfile(dataFile) && strcmp(studyHash(dataFile),strtrim(fileread(fullfile(folder,'data.sha256')))), ...
        'study:DataChanged','Reference dataset changed: %s',role);
    paths=[paths;string(fullfile(folder,split+'.mat'));string(fullfile(folder,'design.csv')); ...
        string(fullfile(folder,'data.sha256'));string(fullfile(folder,'ledger.csv')); ...
        string(fullfile(folder,'generation_sessions.csv'))]; %#ok<AGROW>
end
for method=["mlp","rbf","pod_mlp","pod_gpr"]
    paths(end+1)=string(fullfile(out,'tuning',method,'search_sessions.csv')); %#ok<AGROW>
end
for branch=["runs","controlled","distribution","bases","tuning","timing_repeats"]
    files=dir(fullfile(out,branch,'**','*.mat'));
    for k=1:numel(files)
        [~,leaf]=fileparts(files(k).folder);
        if startsWith(string(leaf),"tp") || contains(files(k).name,'incomplete'), continue; end
        paths(end+1)=string(fullfile(files(k).folder,files(k).name)); %#ok<AGROW>
    end
end
for ext=["*.m","*.json","*.md","*.py"]
    files=dir(fullfile(out,'source_snapshot','**',ext));
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
