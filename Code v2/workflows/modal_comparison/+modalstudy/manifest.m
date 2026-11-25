function result = manifest(paths)
%manifest Deterministic file hashes, or verify a previously recorded manifest.
if istable(paths)
    for k=1:height(paths)
        assert(isfile(paths.Path(k)) && strcmp(surrogate.study.hash(paths.Path(k)),paths.SHA256(k)), ...
            'study:FreezeChanged','Artifact changed: %s',paths.Path(k));
    end
    result=paths; return
end
paths=sort(unique(string(paths(:)))); hashes=strings(size(paths));
for k=1:numel(paths), hashes(k)=string(surrogate.study.hash(paths(k))); end
result=table(paths,hashes,'VariableNames',{'Path','SHA256'});
end
