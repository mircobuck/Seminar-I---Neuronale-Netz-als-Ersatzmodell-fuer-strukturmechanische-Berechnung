function generate(out,cfg)
%generate Register existing references, or explicitly recompute fixed designs.
design=modalstudy.artifact(fullfile(out,'candidate_design.mat'));
if cfg.reference_mode=="generate"
    c=surrogate.contract("modal"); fem=struct('meshDivisor',cfg.mesh_divisor,'geometricOrder',cfg.geometric_order);
    for split=["train","val","test"]
        rows=design(design.split==split,:); folder=fullfile(out,'references',split);
        if ~isfolder(folder), mkdir(folder); end
        n=height(rows); frequencyHz=zeros(n,6); seconds=zeros(n,1);
        for k=1:n
            file=fullfile(folder,'cases',sprintf('case_%d.mat',rows.id(k)));
            x=rows{k,cellstr(c.parameterNames)};
            if isfile(file)
                value=modalstudy.artifact(file);
                assert(isequal(value.parameters,x) && value.meshDivisor==cfg.mesh_divisor, ...
                    'modalstudy:ArtifactChanged','FEM checkpoint differs.');
            else
                surrogate.study.requireSpace(out);
                value=solve_modal_case(x,fem);
                modalstudy.artifact(file,value);
            end
            frequencyHz(k,:)=value.frequencyHz; seconds(k)=value.seconds;
        end
        D=struct('schema',"modal-natural-frequencies-v1",'modality',"modal",'split',split, ...
            'id',rows.id,'X',rows{:,cellstr(c.parameterNames)},'frequencyHz',frequencyHz, ...
            'modeIndices',(1:6)','frequencyUnit',"Hz",'seconds',seconds);
        file=fullfile(folder,split+'.mat');
        if ~isfile(file)
            temporary=[tempname(folder),'.mat']; save(temporary,'D','-v7.3');
            [ok,msg]=movefile(temporary,file); assert(ok,'modalstudy:Write','%s',msg);
            writelines(string(surrogate.study.hash(file)),file+'.sha256');
        else
            assert(strcmp(surrogate.study.hash(file),strtrim(fileread(file+'.sha256'))), ...
                'modalstudy:ArtifactChanged','Generated split changed.');
        end
        writetable(rows,fullfile(folder,'design.csv'));
    end
end
train=modalstudy.reference(out,"generate","train"); val=modalstudy.reference(out,"generate","val");
surrogate.validateTrainingSplits(train,val);
locations=jsondecode(fileread(fullfile(out,'reference_locations.json')));
paths=string(struct2cell(locations));
for split=["train","val","test"]
    paths(end+1)=string(fullfile(fileparts(locations.(split)),'design.csv')); %#ok<AGROW>
end
modalstudy.artifact(fullfile(out,'references.mat'),modalstudy.manifest(paths));
writelines("References registered; no test labels used for model selection.",fullfile(out,'generation.complete'));
end
