function saveModel(filePath,model)
%saveModel Save an artifact without intentionally replacing an existing file.
assert(~isfile(filePath),'surrogate:save:Exists','File already exists: %s',filePath);
save(filePath,'model','-v7.3');
end
