function extend_static_training_768
%extend_static_training_768 - Append 384 static FEM training cases in place
%   extend_static_training_768 preserves the original 384 training cases
%   and all validation, test, and modal data. Interrupted FEM work resumes
%   from individual case files. The original train and design are backed up.

root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'data_generation','data','static');
backup=fullfile(folder,'backup_384');
if ~isfolder(backup), mkdir(backup); end
for name=["train.mat","design.csv"]
    target=fullfile(backup,name);
    if ~isfile(target), copyfile(fullfile(folder,name),target); end
end
a=load(fullfile(backup,'train.mat'),'D'); original=a.D;
assert(numel(original.id)==384,'Expected the original 384 training cases.');
design=readtable(fullfile(backup,'design.csv'),'TextType','string');
assert(nnz(design.split=="train")==384 && numel(unique(design.id))==height(design));
cfg=readstruct(fullfile(root,'data_generation','configs','data_generation_v1.json'));
section=cfg.static;
names=cellstr(string(section.parameterNames));
lower=reshape(section.lower,1,[]); upper=reshape(section.upper,1,[]);
stream=RandStream('mt19937ar','Seed',20261105);
unit=zeros(384,numel(lower));
for j=1:numel(lower)
    unit(:,j)=(randperm(stream,384)'-rand(stream,384,1))/384;
end
X=lower+unit.*(upper-lower);
ids=max(design.id)+(1:384)';
added=array2table([ids X],'VariableNames',[{'id'},names]);
added.split=repmat("train",384,1);
expanded=[design;added];
assert(size(unique(expanded{:,names},'rows'),1)==height(expanded));
designTarget=fullfile(folder,'design_768.csv');
if isfile(designTarget)
    existing=readtable(designTarget,'TextType','string');
    assert(isequal(existing.id,expanded.id) && isequal(existing.split,expanded.split));
    assert(all(abs(existing{:,names}-expanded{:,names})<= ...
        1e-14*max(1,abs(expanded{:,names})),'all'));
else
    writetable(expanded,designTarget);
end
oldPath=path;
cleanup=onCleanup(@()path(oldPath));
addpath(fullfile(root,'fem_core'),fullfile(root,'fem_core','src'),'-begin');
femConfig=config("smoke");
femConfig.names=names; femConfig.lower=lower; femConfig.upper=upper;
femConfig.gridSize=reshape(section.fieldGrid,1,[]);
femConfig.meshDivisor=section.meshDivisor;
femConfig.geometricOrder=string(section.geometricOrder);
femConfig.saveRawMesh=section.saveRawMesh;
femConfig.maxDeflectionRatio=section.maxDeflectionRatio;
D=original;
for i=1:384
    casePath=fullfile(folder,'cases',sprintf('case_%06d.mat',ids(i)));
    if isfile(casePath)
        a=load(casePath,'value'); value=a.value;
        assert(value.id==ids(i) && value.split=="train" && value.modality=="static");
        assert(isequal(value.parameters,X(i,:)),'Existing extension case differs.');
    else
        result=solve_case(X(i,:),femConfig);
        payload=struct('displacementField',result.S,'scalarResponse',result.Y, ...
            'xi',result.xi,'weights',result.w,'nNodes',result.nNodes, ...
            'seconds',result.seconds);
        value=struct('schema',"fem-reference-data-v1",'id',ids(i), ...
            'split',"train",'modality',"static",'parameters',X(i,:), ...
            'parameterNames',string(names),'payload',payload, ...
            'createdAt',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
        temporary=[tempname(folder),'.mat'];
        save(temporary,'value','-v7.3'); movefile(temporary,casePath);
    end
    p=value.payload;
    assert(isequal(p.xi,D.xi) && isequal(p.weights,D.w));
    assert(all(isfinite(p.displacementField)));
    k=384+i;
    D.id(k,1)=ids(i); D.X(k,:)=X(i,:);
    D.S(:,k)=p.displacementField(:); D.Y(k,:)=p.scalarResponse(:)';
    D.seconds(k,1)=p.seconds; D.nodes(k,1)=p.nNodes;
    fprintf('Static extension %d/384, case %d: %.2fs\n',i,ids(i),p.seconds);
end
assert(isequal(D.id(1:384),original.id) && isequal(D.X(1:384,:),original.X));
assert(isequal(D.S(:,1:384),original.S) && numel(unique(D.id))==768);
temporary=fullfile(folder,'train_768_pending.mat');
save(temporary,'D','-v7.3');
% Install the extended design first; the old training split is still valid.
copyfile(designTarget,fullfile(folder,'design.csv'),'f');
movefile(temporary,fullfile(folder,'train.mat'),'f');
manifest=struct('originalTrainingCases',384,'trainingCases',768, ...
    'additionalDesignSeed',20261105,'sampling',"independent Latin hypercube", ...
    'originalConfig',"data_generation_v1.json (frozen original design)", ...
    'validationCases',12,'testCases',64,'modalModified',false);
writestruct(manifest,fullfile(folder,'training_extension_768.json'));
fprintf('Static train.mat updated: 768 cases; validation/test/modal unchanged.\n');
end
