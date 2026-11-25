function value = artifact(file,value)
%artifact Read or atomically write one sealed MAT payload; never replace it.
seal=string(file)+".sha256";
if nargin==1 || isfile(file)
    assert(isfile(file) && isfile(seal) && strcmp(surrogate.study.hash(file),strtrim(fileread(seal))), ...
        'modalstudy:ArtifactChanged','Missing or changed artifact: %s',file);
    saved=load(file,'value');
    if nargin==2
        assert(isequaln(saved.value,value),'modalstudy:ArtifactChanged','Resume payload differs: %s',file);
    end
    value=saved.value; return
end
folder=fileparts(file); if ~isfolder(folder), mkdir(folder); end
temporary=[tempname(folder),'.mat'];
save(temporary,'value','-v7.3');
[ok,msg]=movefile(temporary,file); assert(ok,'modalstudy:Write','%s',msg);
writelines(string(surrogate.study.hash(file)),seal);
end
