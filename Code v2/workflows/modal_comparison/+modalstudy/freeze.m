function freeze(out,cfg)
%freeze Bind all completed attempts and the full test references, without reading labels.
if isfile(fullfile(out,'freeze_manifest.csv')), modalstudy.checkFrozen(out); return; end
assert(isfile(fullfile(out,'training.complete')),'study:IncompleteTraining','Train before freeze.');
refs=modalstudy.artifact(fullfile(out,'references.mat')); modalstudy.manifest(refs);
runs=modalstudy.artifact(fullfile(out,'run_plan.mat'));
for k=1:numel(runs)
    folder=fullfile(out,runs(k).id); file=fullfile(folder,'result.mat');
    assert(isfile(file) && strcmp(surrogate.study.hash(file),strtrim(fileread(fullfile(folder,'result.sha256')))), ...
        'study:CheckpointChanged','Missing or changed fit: %s',folder);
    a=load(file,'result'); r=a.result;
    assert(r.method==runs(k).method && isequaln(r.config,runs(k).config) && isequal(r.trainingIds,runs(k).ids), ...
        'study:CheckpointChanged','Fit does not match the registered plan.');
    if r.status=="ok"
        assert(strcmp(surrogate.study.hash(fullfile(folder,'model.mat')),r.modelHash), ...
            'study:CheckpointChanged','Model changed.');
    end
    if runs(k).role=="main" && numel(runs(k).ids)==max(cfg.training_sizes) && runs(k).config.seed==cfg.seed_tuning
        assert(r.status=="ok",'modalstudy:MainFailed','Main %s model failed: %s',runs(k).method,r.message);
    end
end
source=readtable(fullfile(out,'source_manifest.csv'),'TextType','string');
paths=[source.Path;refs.Path]; files=dir(fullfile(out,'**','*'));
for k=1:numel(files)
    if ~files(k).isdir, paths(end+1)=string(fullfile(files(k).folder,files(k).name)); end %#ok<AGROW>
end
manifest=modalstudy.manifest(paths); file=fullfile(out,'freeze_manifest.csv');
writetable(manifest,file);
writelines(string(surrogate.study.hash(file)),fullfile(out,'freeze_manifest.sha256'));
modalstudy.checkFrozen(out);
end
