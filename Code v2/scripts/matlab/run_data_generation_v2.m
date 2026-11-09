function run_data_generation_v2(stage, configFile, out)
%RUN_DATA_GENERATION_V2 Create and assign static/modal FEM reference data.
% Stages: design, static_train_val, static_val, modal_train_val, static_test,
% modal_test. STATIC_VAL generates only the assigned static validation cases.
if nargin==0
    fprintf(['Stages:\n' ...
        '  run_data_generation_v2("design")\n' ...
        '  run_data_generation_v2("static_train_val")\n' ...
        '  run_data_generation_v2("modal_train_val")\n' ...
        '  run_data_generation_v2("static_test")\n' ...
        '  run_data_generation_v2("modal_test")\n']);
    return
end
stage=validatestring(char(stage), ...
    {'design','static_train_val','static_val','modal_train_val','static_test','modal_test'});
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
sourceRoot=fullfile(root,'fem_core');
assert(isfolder(sourceRoot),'femdata:v2:SourceMissing', ...
    'Cannot find the local FEM core: %s',sourceRoot);
% Pfade nur für die Dauer dieses Aufrufs hinzufügen und danach wiederherstellen.
oldPath=path;
pathCleanup=onCleanup(@()path(oldPath));
addpath(sourceRoot,fullfile(sourceRoot,'src'),'-begin');

if nargin<2 || isempty(configFile)
    configFile=fullfile(root,'data_generation','configs','data_generation_v1.json');
end
if nargin<3 || isempty(out)
    out=fullfile(root,'data_generation','data');
end
cfg=jsondecode(fileread(configFile));
% JSON-Vektoren als Zeilen ausrichten, damit die Parameterrechnung passt.
for name=["static","modal"]
    cfg.(name).parameterNames=reshape(cfg.(name).parameterNames,1,[]);
    cfg.(name).lower=reshape(cfg.(name).lower,1,[]);
    cfg.(name).upper=reshape(cfg.(name).upper,1,[]);
end
assert(usejava('jvm'),'femdata:v2:JavaRequired','A MATLAB session with Java is required for SHA-256 provenance.');
if ~isfolder(out), mkdir(out); end
% Bei einer Wiederaufnahme m?ssen Konfiguration und relevante Quellen passen.
provenance=buildProvenance(configFile,sourceRoot);
writeImmutableText(fullfile(out,'provenance.txt'),provenance);
% Separate Provenienz für den neuen Runner; die alte Datei bleibt erhalten.
standalone="runner_sha256="+string(sha256File(mfilename('fullpath')+".m"))+newline;
writeImmutableText(fullfile(out,'standalone_provenance.txt'),standalone);

if stage=="design"
    createDesigns(configFile,out,cfg);
    return
end
switch stage
    case "static_train_val"
        generatePartition(out,cfg,"static",["train","val"]);
    case "static_val"
        generatePartition(out,cfg,"static","val");
    case "modal_train_val"
        generatePartition(out,cfg,"modal",["train","val"]);
    case "static_test"
        generatePartition(out,cfg,"static","test");
    case "modal_test"
        generatePartition(out,cfg,"modal","test");
end
end

function createDesigns(configFile,out,cfg)
if ~isfolder(out), mkdir(out); end
for modality=["static","modal"]
    section=cfg.(modality);
    counts=section.counts;
    total=counts.train+counts.val+counts.test;
    rng(cfg.seed+double(modality=="modal"),'twister');
    % Latin Hypercube verteilt jeden Parameter ?ber seinen gesamten Bereich.
    unit=latinHypercube(total,numel(section.lower));
    X=section.lower+unit.*(section.upper-section.lower);
    split=[repmat("train",counts.train,1); ...
        repmat("val",counts.val,1);repmat("test",counts.test,1)];
    order=randperm(total);
    split=split(order);
    X=X(order,:);
    ids=(section.idStart:section.idStart+total-1)';
    design=array2table([ids X], ...
        'VariableNames',[{'id'},cellstr(string(section.parameterNames))]);
    design.split=split;
    validateDesign(design,section);
    path=fullfile(out,modality,'design.csv');
    writeImmutableTable(path,design);
    fprintf('%s design assigned: train=%d, val=%d, test=%d (%d total).\n', ...
        modality,nnz(split=="train"),nnz(split=="val"),nnz(split=="test"),total);
end
writeImmutableText(fullfile(out,'design_config_sha256.txt'),string(sha256File( ...
    configFile))+newline);
end

function U=latinHypercube(n,p)
U=zeros(n,p);
for j=1:p
    U(:,j)=(randperm(n)'-rand(n,1))/n;
end
end

function validateDesign(T,section)
names=string(section.parameterNames);
assert(height(T)==sum([section.counts.train,section.counts.val,section.counts.test]) && ...
    numel(unique(T.id))==height(T) && ...
    size(unique(T{:,cellstr(names)},'rows'),1)==height(T), ...
    'femdata:v2:DesignIdentity','Design has duplicate IDs or parameter rows.');
assert(all(ismember(T.split,["train","val","test"])) && ...
    nnz(T.split=="train")==section.counts.train && ...
    nnz(T.split=="val")==section.counts.val && ...
    nnz(T.split=="test")==section.counts.test, ...
    'femdata:v2:SplitCounts','Design split assignment does not match configured counts.');
X=T{:,cellstr(names)};
assert(all(isfinite(X),'all') && ...
    all(X>=section.lower & X<=section.upper,'all'), ...
    'femdata:v2:ParameterBounds','Design parameters are nonfinite or outside configured bounds.');
end

function generatePartition(out,cfg,modality,partitions)
section=cfg.(modality);
designPath=fullfile(out,modality,'design.csv');
assert(isfile(designPath),'femdata:v2:DesignMissing', ...
    'Create and review designs first: %s',designPath);
T=readtable(designPath,'TextType','string');
validateDesign(T,section);
partitionNames=string(partitions);
if any(partitionNames=="test")
    fprintf(['TEST LABEL PHASE: calculating %d %s FEM references. ' ...
        'Run only after candidate models are frozen.\n'], ...
        nnz(T.split=="test"),modality);
end
caseDir=fullfile(out,modality,'cases');
if ~isfolder(caseDir), mkdir(caseDir); end
rows=find(ismember(T.split,partitionNames));
for i=rows(:)'
    id=T.id(i);
    x=T{i,cellstr(string(section.parameterNames))};
    path=fullfile(caseDir,sprintf('case_%06d.mat',id));
    % Bereits berechnete, passende F?lle ?berspringen; Konflikte abbrechen.
    if isfile(path)
        a=load(path,'value'); value=a.value;
        assert(value.id==id && value.split==T.split(i) && ...
            isequal(value.parameters,x), ...
            'femdata:v2:CaseArtifactConflict', ...
            'Existing case artifact conflicts with design row ID %d.',id);
        continue
    end
    started=tic;
    switch modality
        case "static"
            % Basisstruktur laden; die FEM-Einstellungen stammen aus der JSON-Datei.
            femConfig=config("smoke");
            femConfig.names=cellstr(string(section.parameterNames));
            femConfig.lower=section.lower;
            femConfig.upper=section.upper;
            femConfig.gridSize=section.fieldGrid;
            femConfig.meshDivisor=section.meshDivisor;
            femConfig.geometricOrder=string(section.geometricOrder);
            femConfig.saveRawMesh=section.saveRawMesh;
            femConfig.maxDeflectionRatio=section.maxDeflectionRatio;
            result=solve_case(x,femConfig);
            payload=struct('displacementField',result.S,'scalarResponse',result.Y, ...
                'xi',result.xi,'weights',result.w,'nNodes',result.nNodes, ...
                'seconds',toc(started));
        case "modal"
            result=femstudy.fem.modal(x,section.meshDivisor);
            % Nur die ersten sechs Eigenfrequenzen werden als Zielgr??en abgelegt.
            payload=struct('frequencyHz',result.frequencyHz(1:6), ...
                'seconds',result.seconds,'meshDivisor',result.divisor, ...
                'modeCountReturned',numel(result.frequencyHz));
        otherwise
            error('femdata:v2:UnknownModality','Unknown modality %s.',modality);
    end
    value=struct('schema',"fem-reference-data-v1",'id',id, ...
        'split',T.split(i),'modality',modality,'parameters',x, ...
        'parameterNames',string(section.parameterNames),'payload',payload, ...
        'createdAt',string(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
    saveImmutableMat(path,value);
    fprintf('%s %s FEM %d: %.2fs\n',modality,T.split(i),id,payload.seconds);
end
% Erst wenn alle F?lle eines Splits vorliegen, die gemeinsame MAT-Datei erzeugen.
for splitName=partitionNames
    selected=T(T.split==splitName,:);
    data=assemblePartition(caseDir,selected,section,modality,splitName);
    writePartition(fullfile(out,modality,splitName+'.mat'),data);
end
end

function data=assemblePartition(caseDir,T,section,modality,splitName)
ids=T.id(:); X=T{:,cellstr(string(section.parameterNames))};
records=cell(numel(ids),1);
for i=1:numel(ids)
    path=fullfile(caseDir,sprintf('case_%06d.mat',ids(i)));
    assert(isfile(path),'femdata:v2:CaseMissing','Missing FEM case artifact %s.',path);
    a=load(path,'value'); records{i}=a.value;
    assert(records{i}.id==ids(i) && records{i}.split==splitName && ...
        isequal(records{i}.parameters,X(i,:)), ...
        'femdata:v2:CaseAssignment','Case artifact does not match its split assignment.');
end
if modality=="static"
    first=records{1}.payload;
    % S: eine Feldspalte pro Fall; X und Y: je eine Zeile pro Fall.
    S=zeros(numel(first.displacementField),numel(ids));
    Y=zeros(numel(ids),numel(first.scalarResponse));
    seconds=zeros(numel(ids),1); nodes=zeros(numel(ids),1);
    for i=1:numel(ids)
        p=records{i}.payload;
        assert(isequal(p.xi,first.xi) && isequal(p.weights,first.weights), ...
            'femdata:v2:StaticGridMismatch','Static FEM reference grids differ.');
        S(:,i)=p.displacementField(:); Y(i,:)=p.scalarResponse(:)';
        seconds(i)=p.seconds; nodes(i)=p.nNodes;
    end
    data=struct('schema',"static-displacement-fields-v1",'modality',modality, ...
        'split',splitName,'id',ids,'X',X,'S',S,'Y',Y, ...
        'xi',first.xi,'w',first.weights,'seconds',seconds,'nodes',nodes);
else
    % Jede Zeile enth?lt die sechs Frequenzen eines Falls in Hz.
    F=zeros(numel(ids),6); seconds=zeros(numel(ids),1);
    for i=1:numel(ids)
        F(i,:)=records{i}.payload.frequencyHz(:)';
        seconds(i)=records{i}.payload.seconds;
    end
    data=struct('schema',"modal-natural-frequencies-v1",'modality',modality, ...
        'split',splitName,'id',ids,'X',X,'frequencyHz',F, ...
        'modeIndices',(1:6)','frequencyUnit',"Hz",'seconds',seconds);
end
end

function writePartition(path,data)
if isfile(path)
    old=load(path,'D'); saved=old.D;
    assert(isequaln(saved,data),'femdata:v2:PartitionConflict', ...
        'Existing split file conflicts with current case artifacts: %s',path);
    return
end
parent=fileparts(path); if ~isfolder(parent), mkdir(parent); end
tmp=[tempname(parent),'.mat']; D=data; save(tmp,'D','-v7.3');
[ok,msg]=movefile(tmp,path);
assert(ok,'femdata:v2:PartitionWrite','Could not save split file: %s',msg);
end

function saveImmutableMat(path,value)
if isfile(path)
    old=load(path,'value');
    assert(isequaln(old.value,value),'femdata:v2:CaseArtifactConflict', ...
        'Refusing to overwrite conflicting case artifact: %s',path);
    return
end
parent=fileparts(path); if ~isfolder(parent), mkdir(parent); end
tmp=[tempname(parent),'.mat']; save(tmp,'value','-v7.3');
[ok,msg]=movefile(tmp,path);
assert(ok,'femdata:v2:CaseArtifactWrite','Could not save case artifact: %s',msg);
end

function writeImmutableTable(path,T)
if isfile(path)
    existing=readtable(path,'TextType','string');
    sameNames=isequal(existing.Properties.VariableNames,T.Properties.VariableNames);
    numericNames=T.Properties.VariableNames(~strcmp(T.Properties.VariableNames,'split'));
    a=existing{:,numericNames}; b=T{:,numericNames};
    % CSV-Einlesen kann kleine Rundungsabweichungen verursachen.
    sameValues=isequal(size(a),size(b)) && ...
        all(abs(a-b)<=1e-14*max(1,abs(b)),'all');
    assert(sameNames && sameValues && isequal(existing.split,T.split), ...
        'femdata:v2:DesignConflict', ...
        'Existing design differs; refusing replacement: %s',path);
    return
end
parent=fileparts(path); if ~isfolder(parent), mkdir(parent); end
writetable(T,path);
end

function writeImmutableText(path,text)
if isfile(path)
    assert(string(fileread(path))==string(text),'femdata:v2:ProvenanceConflict', ...
        'Existing design provenance differs: %s',path);
    return
end
fid=fopen(path,'w');
assert(fid>=0,'femdata:v2:ProvenanceWrite','Could not write design provenance.');
cleanup=onCleanup(@()fclose(fid)); fwrite(fid,text,'char'); clear cleanup
end

function hash=sha256File(path)
fid=fopen(path,'rb');
assert(fid>=0,'femdata:v2:HashRead','Cannot open file for hashing: %s',path);
cleanup=onCleanup(@()fclose(fid)); bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
clear cleanup
end

function text=buildProvenance(configFile,sourceRoot)
files={configFile, fullfile(sourceRoot,'provenance','run_data_generation_v2_original.txt'), ...
    fullfile(sourceRoot,'config.m'), fullfile(sourceRoot,'src','solve_case.m'), ...
    fullfile(sourceRoot,'src','reference_grid.m'), ...
    fullfile(sourceRoot,'src','rom_observation.m'), ...
    fullfile(sourceRoot,'src','+femstudy','+fem','modal.m')};
text="MATLAB="+string(version)+newline;
pde=ver('pde');
assert(~isempty(pde) && license('test','PDE_Toolbox'), ...
    'femdata:v2:MissingPDE','Partial Differential Equation Toolbox is required.');
text=text+"PDE="+string(pde.Version)+newline;
for k=1:numel(files)
    assert(isfile(files{k}),'femdata:v2:MissingSource','Missing source: %s',files{k});
    text=text+"file"+k+"="+string(sha256File(files{k}))+newline;
end
end
