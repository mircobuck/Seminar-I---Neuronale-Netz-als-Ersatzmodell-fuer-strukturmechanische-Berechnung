function T=studySources(root,studyRoot)
% Hash source and fixed data, including untracked MATLAB files.
folders={fullfile(root,'+surrogate'),fullfile(root,'fem_core'),studyRoot};
paths=strings(0,1);
for k=1:numel(folders)
    files=dir(fullfile(folders{k},'**','*.m'));
    paths=[paths;string(fullfile({files.folder},{files.name}))']; %#ok<AGROW>
end
paths=[paths;string(fullfile(studyRoot,'studyPlots.py'));string(fullfile(studyRoot,'study_config.json'));string(fullfile(studyRoot,'PROTOKOLL_v1.md')); ...
    string(fullfile(root,'loadFemDataset.m')); ...
    string(fullfile(root,'data_generation','data','static','train.mat')); ...
    string(fullfile(root,'data_generation','data','static','design.csv')); ...
    string(fullfile(root,'experiments','static_pod_gpr_20261111','design_manifest.csv')); ...
    string(fullfile(root,'experiments','static_pod_gpr_20261111','fem_pilot','pilot_design.csv'))];
manifest=readtable(fullfile(root,'experiments','static_pod_gpr_20261111','design_manifest.csv'),'TextType','string','Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
for k=1:height(manifest), paths(end+1)=string(fullfile(root,manifest.file(k))); end %#ok<AGROW>
for pilotName=["static_gpr_v1_generation_pilot_20261111","static_gpr_v1_generation_pilot_v2_20261111"]
    pilotPath=fullfile(root,'experiments',pilotName,'candidate_design.csv');
    if isfile(pilotPath), paths(end+1)=string(pilotPath); end %#ok<AGROW>
end
paths=sort(unique(paths)); hashes=strings(numel(paths),1);
for k=1:numel(paths), hashes(k)=string(studyHash(paths(k))); end
T=table(paths,hashes,'VariableNames',{'Path','SHA256'});
end
