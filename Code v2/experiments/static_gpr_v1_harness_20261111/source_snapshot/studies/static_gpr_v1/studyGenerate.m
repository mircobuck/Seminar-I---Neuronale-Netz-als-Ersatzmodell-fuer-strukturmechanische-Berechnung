function studyGenerate(root,out,cfg,roles)
% Generate split-isolated 3-D FEM references with immutable case checkpoints.
addpath(fullfile(root,'fem_core'),fullfile(root,'fem_core','src'));
a=load(fullfile(out,'candidate_design.mat'),'design'); Dsg=a.design;
expectedHash=strtrim(fileread(fullfile(out,'candidate_design.sha256')));
assert(strcmp(studyHash(fullfile(out,'candidate_design.mat')),expectedHash), ...
    'study:DesignChanged','Candidate design was changed.');
names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
femConfig=config('smoke'); femConfig.meshDivisor=cfg.mesh_divisor;
femConfig.geometricOrder=string(cfg.geometric_order); femConfig.saveRawMesh=false;
femConfig.maxDeflectionRatio=cfg.max_deflection_ratio;
for role=string(roles(:)')
    assert(any(role==["val","interpolation","extrapolation"]),'study:Role','Invalid reference role.');
    folder=fullfile(out,'references',role); cases=fullfile(folder,'cases');
    if ~isfolder(cases), mkdir(cases); end
    if role=="extrapolation", groups=1:12; else, groups=0; end
    selected=[]; phaseStart=tic;
    for g=groups
        rows=find(Dsg.role==role & Dsg.group==g);
        if g==0, target=cfg.counts.(role); else
            target=floor(cfg.counts.extrapolation/12)+(g<=mod(cfg.counts.extrapolation,12));
        end
        successes=0;
        for j=rows(:)'
            if successes==target, break; end
            id=Dsg.id(j); parameters=Dsg{j,names};
            path=fullfile(cases,sprintf('case_%06d.mat',id));
            seal=string(path)+'.sha256';
            if isfile(path) && ~isfile(seal)
                quarantine=string(path)+'.incomplete_'+string(posixtime(datetime('now','TimeZone','UTC')));
                [ok,msg]=movefile(path,quarantine); assert(ok,'study:Quarantine','%s',msg);
            end
            if isfile(path)
                assert(strcmp(studyHash(path),strtrim(fileread(seal))),'study:CheckpointChanged','FEM checkpoint changed.');
                saved=load(path,'record'); record=saved.record;
                assert(record.id==id && isequal(record.parameters,parameters) && record.role==role, ...
                    'study:CheckpointChanged','Case checkpoint does not match design.');
            else
                studyRequireBudget(out,20);
                started=tic; status="ok"; message=""; value=[];
                try
                    value=solve_case(parameters,femConfig);
                catch err
                    status="failed"; message=string(err.identifier)+": "+string(err.message);
                end
                record=struct('id',id,'role',role,'group',g,'parameters',parameters, ...
                    'status',status,'message',message,'wallSeconds',toc(started),'value',value);
                temporary=[tempname(cases),'.mat']; save(temporary,'record','-v7.3');
                [ok,msg]=movefile(temporary,path); assert(ok,'study:Save','%s',msg);
                writelines(string(studyHash(path)),seal);
            end
            if record.status=="ok", selected(end+1)=j; successes=successes+1; end %#ok<AGROW>
        end
        assert(successes==target,'study:ReservesExhausted','Not enough successful cases for %s group %d.',role,g);
    end
    selected=selected(:); n=numel(selected); ids=Dsg.id(selected); X=Dsg{selected,names};
    S=zeros(1575,n); Y=zeros(n,2); seconds=zeros(n,1); nodes=zeros(n,1);
    statuses=table;
    for j=1:n
        a=load(fullfile(cases,sprintf('case_%06d.mat',ids(j))),'record'); v=a.record.value;
        if j==1, xi=v.xi; w=v.w; else
            assert(isequal(v.xi,xi)&&isequal(v.w,w),'study:Grid','Inconsistent FEM grid.');
        end
        S(:,j)=v.S; Y(j,:)=v.Y; seconds(j)=v.seconds; nodes(j)=v.nNodes;
    end
    allRows=find(Dsg.role==role); ledger=table;
    for j=allRows(:)'
        path=fullfile(cases,sprintf('case_%06d.mat',Dsg.id(j)));
        if ~isfile(path), continue; end
        a=load(path,'record'); r=a.record; solverSeconds=NaN;
        if r.status=="ok", solverSeconds=r.value.seconds; end
        ledger=[ledger;table(r.id,r.group,r.status,r.message,r.wallSeconds,solverSeconds, ...
            'VariableNames',{'id','group','status','message','wall_seconds','solver_seconds'})]; %#ok<AGROW>
    end
    split="test"; if role=="val", split="val"; end
    D=struct('schema',"static-displacement-fields-v1",'modality',"static",'split',split, ...
        'id',ids,'X',X,'S',S,'Y',Y,'xi',xi,'w',w,'seconds',seconds,'nodes',nodes);
    design=Dsg(selected,{'id',names{:}}); design.split=repmat(split,n,1);
    dataFile=fullfile(folder,split+'.mat'); designFile=fullfile(folder,'design.csv');
    if ~isfile(dataFile), save(dataFile,'D','-v7.3'); else
        old=load(dataFile,'D'); assert(isequaln(old.D,D),'study:DatasetChanged','Dataset differs from checkpoints.');
    end
    if ~isfile(designFile), writetable(design,designFile); end
    studyData=surrogate.loadDataset(dataFile); assert(isequal(studyData.caseIds,ids)); %#ok<NASGU>
    if ~isfile(fullfile(folder,'ledger.csv')), writetable(ledger,fullfile(folder,'ledger.csv')); end
    if ~isfile(fullfile(folder,'data.sha256')), writelines(string(studyHash(dataFile)),fullfile(folder,'data.sha256')); end
    if ~isfile(fullfile(folder,'generation_final_invocation_wall.txt')), writelines(string(toc(phaseStart)),fullfile(folder,'generation_final_invocation_wall.txt')); end
end
end
