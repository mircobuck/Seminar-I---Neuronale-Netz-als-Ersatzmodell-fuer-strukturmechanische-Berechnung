function freeze(root,out,cfg)
    %freeze Bind completed training, external references and active source in a new seal.
    assert(isfile(fullfile(out,'training.complete')),'study:IncompleteTraining','Train before freezing.');
    staticstudy.validateReferences(out,cfg);
    staticstudy.verify(root,out,cfg);
    file=fullfile(out,'freeze_manifest.csv');
    if isfile(file)
        staticstudy.checkFrozen(out);
        return
    end
    source=staticstudy.sources(root,cfg);
    paths=source.Path;
    files=dir(fullfile(out,'**','*'));
    for k=1:numel(files)
        if files(k).isdir
            continue;
        end
        [~,~,ext]=fileparts(files(k).name);
        if any(string(ext)==[".mat",".csv",".json",".sha256",".complete"])
            paths(end+1)=string(fullfile(files(k).folder,files(k).name)); %#ok<AGROW>
        end
    end
    records=dir(fullfile(out,'**','result.mat'));
    assert(~isempty(records),'study:NoModels','Cannot freeze an empty training run.');
    for k=1:numel(records)
        resultFile=fullfile(records(k).folder,records(k).name);
        assert(strcmp(staticstudy.hash(resultFile),strtrim(fileread(fullfile(records(k).folder, ...
            'result.sha256')))),  'study:CheckpointChanged',  'Fit checkpoint changed.');
        a=load(resultFile,'result');
        if a.result.status=="ok"
            assert(strcmp(staticstudy.hash(fullfile(records(k).folder,'model.mat')),a.result.modelHash), ...
                'study:CheckpointChanged',  'Model checkpoint changed.');
        end
    end
    paths=sort(unique(paths));
    hashes=strings(size(paths));
    for k=1:numel(paths)
        hashes(k)=string(staticstudy.hash(paths(k)));
    end
    manifest=table(paths,hashes,'VariableNames',{'Path','SHA256'});
    writetable(manifest,file);
    writelines(string(staticstudy.hash(file)),fullfile(out,'freeze_manifest.sha256'));
    staticstudy.checkFrozen(out);
end
