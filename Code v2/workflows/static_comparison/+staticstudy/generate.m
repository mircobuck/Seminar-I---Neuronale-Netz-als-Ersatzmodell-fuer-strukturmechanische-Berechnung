function generate(~,out,cfg,roles)
    % Load the planned FEM cases and verify that the design file has not changed.
    a=load(fullfile(out,'candidate_design.mat'),'design');
    Dsg=a.design;
    expectedHash=strtrim(fileread(fullfile(out,'candidate_design.sha256')));
    assert(strcmp(staticstudy.hash(fullfile(out,'candidate_design.mat')),expectedHash),  'study:DesignChanged', ...
        'Candidate design was changed.');
    % Name the FEM parameters in the order of the design table.    
    names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
    % Load the FEM configuration for the static study. mesh, boundary conditions, and solver settings are all in this struct.
    femConfig=staticFemConfig(cfg);
    % iterate over the requested roles: val, interpolation, extrapolation
    for role=string(roles(:)')
        %checks if the role is valid
        assert(any(role==["val","interpolation","extrapolation"]),'study:Role','Invalid reference role.');
        % Create the folder for the role and its cases. The cases are stored in a subfolder named "cases".
        folder=fullfile(out,'references',role);
        cases=fullfile(folder,'cases');
        % if the folder for the role does not exist, create it. If the cases subfolder does not exist, create it as well.
        if ~isfolder(cases)
            mkdir(cases);
        end
        % 12 groups for extrapolation, 0 for val and interpolation
        if role=="extrapolation"
            groups=1:12;
        else
            groups=0;
        end
        
        selected=[];
        % starts the timer for the phase and records the start time in UTC format. The onCleanup function ensures that the generation process is recorded when the function exits, even if an error occurs.
        phaseStart=tic;
        startUtc=string(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
        generationCleanup=onCleanup(@()staticstudy.recordGeneration(folder,role,startUtc,phaseStart));
        % iterate over the groups for the current role
        for g=groups
            % gets rows from the design table that match the current role and group.
            rows=find(Dsg.role==role & Dsg.group==g);

            if g==0
                % validation and interpolation have a fixed number of cases, while extrapolation is divided into 12 groups. The target number of successful cases is determined based on the role and group.
                target=cfg.counts.(role);
            else
                target=floor(cfg.counts.extrapolation/12)+(g<=mod(cfg.counts.extrapolation,12));
            end
            % count the number of successful cases for the current role and group.
            successes=0;
            % iterate over the rows in the design table for the current role and group.
            for j=rows(:)'
                % if the number of successful cases has reached the target, break out of the loop.
                if successes==target
                    break;
                end
                % get the case ID and parameters
                id=Dsg.id(j);
                % takes the paramteres like height, width, length, force, youngs modulus and poisson ratio from the design table for the current row.
                parameters=Dsg{j,names}; 
                % Preserve a case file without a checksum as incomplete so it can be recomputed.
                caseFile=fullfile(cases,sprintf('case_%06d.mat',id));
                seal=string(caseFile)+'.sha256';
                if isfile(caseFile) && ~isfile(seal)
                    quarantine=string(caseFile)+'.incomplete_'+string(posixtime(datetime('now','TimeZone','UTC')));
                    [ok,msg]=movefile(caseFile,quarantine);
                    assert(ok,'study:Quarantine','%s',msg);
                end

                if isfile(caseFile)
                    % if file exists, check that the checksum matches the seal file and that the record matches the design table.
                    assert(strcmp(staticstudy.hash(caseFile),strtrim(fileread(seal))),'study:CheckpointChanged', ...
                        'FEM checkpoint changed.');
                    saved=load(caseFile,'record');
                    record=saved.record;
                    assert(record.id==id && isequal(record.parameters,parameters) && record.role==role, ...
                        'study:CheckpointChanged',  'Case checkpoint does not match design.');
                else
                    % checks time and space capacity
                    staticstudy.requireBudget(out,20);
                    staticstudy.requireSpace(out);
                    % tiem meausrement
                    started=tic;
                    status="ok";
                    message="";
                    value=[];
                    % actual FEM solving
                    try
                        value=solve_case(parameters,femConfig);
                    catch err
                        status="failed";
                        message=string(err.identifier)+": "+string(err.message);
                    end
                    % informations about the case are saved in  struct
                    record=struct('id',id,'role',role,'group',g,'parameters',parameters,  'status',  status, ...
                        'message',  message,  'wallSeconds',  toc(started),  'value',  value);
                    % dataset is saved in a temporary file
                    temporary=[tempname(cases),'.mat'];
                    save(temporary,'record','-v7.3');
                    [ok,msg]=movefile(temporary,caseFile);
                    assert(ok,'study:Save','%s',msg);
                    writelines(string(staticstudy.hash(caseFile)),seal);
                end
                if record.status=="ok"
                    selected(end+1)=j; %#ok<AGROW>
                    successes=successes+1;
                end
            end
            assert(successes==target,'study:ReservesExhausted','Not enough successful cases for %s group %d.',role,g);
        end
        % save design and data for the current role.
        selected=selected(:);
        n=numel(selected);
        ids=Dsg.id(selected);
        X=Dsg{selected,names};
        S=zeros(1575,n);
        Y=zeros(n,2);
        seconds=zeros(n,1);
        nodes=zeros(n,1);
        %iterae over the cases
        for j=1:n
            
            a=load(fullfile(cases,sprintf('case_%06d.mat',ids(j))),'record');
            v=a.record.value;
            % if this is the first case, store the grid points and weights. For subsequent cases, verify that the grid points and weights are consistent
            if j==1
                xi=v.xi;
                w=v.w;
            else
                assert(isequal(v.xi,xi)&&isequal(v.w,w),'study:Grid','Inconsistent FEM grid.');
            end
            % saves the FEM results for each case in the S and Y matrices, and records the computation time and number of nodes
            % S is "Verschiebungsfeld"
            S(:,j)=v.S;
            % Y is displacement at the tip and maximum displacement in the structure
            Y(j,:)=v.Y;
            seconds(j)=v.seconds;
            % number of nodes in the FEM mesh
            nodes(j)=v.nNodes;
        end
        % protokol the ledger for the specific role. The ledger contains the case ID, group, status, message, wall time, and solver time for each case.
        allRows=find(Dsg.role==role);
        ledger=table;
        % Load the selected FEM cases and combine their results into dataset arrays.
        for j=allRows(:)'
            caseFile=fullfile(cases,sprintf('case_%06d.mat',Dsg.id(j)));
            if ~isfile(caseFile)
                continue;
            end
            a=load(caseFile,'record');
            r=a.record;
            solverSeconds=NaN;
            if r.status=="ok"
                solverSeconds=r.value.seconds;
            end
            ledger=[ledger;table(r.id,r.group,r.status,r.message,r.wallSeconds,solverSeconds,  'VariableNames', ... %#ok<AGROW>
                {'id','group','status','message','wall_seconds','solver_seconds'})];
        end

        split="test";
        if role=="val"
            split="val";
        end
        % build dataset
        D=struct('schema',"static-displacement-fields-v1",'modality',"static",'split',split,  'id',  ids,  'X', ...
            X,  'S',  S,  'Y',  Y,  'xi',  xi,  'w',  w,  'seconds',  seconds,  'nodes',  nodes);
        % table with the design parameters and the role and group for each case
        design=Dsg(selected,[{'id'},names]);
        % add the role and group columns to the design table and save it as a CSV file.
        design.split=repmat(split,n,1);
        dataFile=fullfile(folder,split+'.mat');
        designFile=fullfile(folder,'design.csv');
        if ~isfile(dataFile)
            save(dataFile,'D','-v7.3');
        else
            old=load(dataFile,'D');
            assert(isequaln(old.D,D),'study:DatasetChanged','Dataset differs from checkpoints.');
        end
        if ~isfile(designFile)
            writetable(design,designFile);
        end
        studyData=surrogate.loadDataset(dataFile);
        assert(isequal(studyData.caseIds,ids));
        if ~isfile(fullfile(folder,'ledger.csv'))
            writetable(ledger,fullfile(folder,'ledger.csv'));
        end
        if ~isfile(fullfile(folder,'data.sha256'))
            writelines(string(staticstudy.hash(dataFile)),fullfile(folder,'data.sha256'));
        end
        clear generationCleanup
    end
end
