function saveNew(path,value)
%SAVENEW Write an immutable artifact; refuse replacement.
assert(~isfile(path),'femstudy:artifact:Exists','Artifact exists: %s',path);
parent=fileparts(path); if ~isfolder(parent), mkdir(parent); end
tmp=[tempname(parent) '.mat']; save(tmp,'value','-v7.3');
[ok,msg]=movefile(tmp,path); assert(ok,msg);
end
