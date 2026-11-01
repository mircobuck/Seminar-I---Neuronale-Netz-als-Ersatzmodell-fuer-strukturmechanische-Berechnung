function run_validation(mode)
%RUN_VALIDATION Check FEM beam references against analytics and refined meshes.
if nargin==0
    fprintf('Modes: analysis, mesh, all\n');
    return
end
mode=validatestring(char(mode),{'analysis','mesh','all'});
studyRoot=fileparts(fileparts(mfilename('fullpath')));
projectRoot=fileparts(fileparts(studyRoot));
cfg=jsondecode(fileread(fullfile(studyRoot,'config.json')));
dataRoot=fullfile(studyRoot,cfg.dataRoot);
resultsRoot=fullfile(studyRoot,'results');
if ~isfolder(resultsRoot), mkdir(resultsRoot); end
coreRoot=fullfile(projectRoot,'fem_core');
oldPath=path;
pathCleanup=onCleanup(@()path(oldPath));
addpath(projectRoot,coreRoot,fullfile(coreRoot,'src'),'-begin');
assert(usejava('jvm'),'femvalidation:JavaRequired', ...
    'Java is required for study provenance hashes.');
writeManifest(studyRoot,projectRoot,dataRoot,cfg);
if mode=="analysis" || mode=="all"
    runAnalyticalAnalysis(dataRoot,resultsRoot,cfg);
end
if mode=="mesh" || mode=="all"
    runMeshStudy(projectRoot,dataRoot,resultsRoot,studyRoot,cfg);
end
fprintf('FEM reference validation completed in %s\n',resultsRoot);
end

function runAnalyticalAnalysis(dataRoot,resultsRoot,cfg)
static=surrogate.loadDataset(fullfile(dataRoot,'static','train.mat'));
modal=surrogate.loadDataset(fullfile(dataRoot,'modal','train.mat'));
assert(string(static.split)=="train" && ...
    numel(static.caseIds)==cfg.staticCaseCount, ...
    'femvalidation:StaticSplit','Static training split differs from protocol.');
assert(string(modal.split)=="train" && ...
    numel(modal.caseIds)==cfg.modalCaseCount, ...
    'femvalidation:ModalSplit','Modal training split differs from protocol.');

staticAxis=buildStaticAxisProfiles(static,cfg.static);
staticErrors=buildStaticAxisErrors(staticAxis,cfg.static.relativeNormFloor);
modalScreen=buildModalFrequencyScreen(modal,cfg.modal.betaRoots);
saveImmutableTable(fullfile(resultsRoot,'static_axis_profiles.csv'),staticAxis);
saveImmutableTable(fullfile(resultsRoot,'static_axis_errors.csv'),staticErrors);
saveImmutableTable(fullfile(resultsRoot,'modal_frequency_screen.csv'),modalScreen);
saveImmutableMat(fullfile(resultsRoot,'analytical_comparison.mat'), ...
    struct('staticAxisProfiles',staticAxis,'staticAxisErrors',staticErrors, ...
    'modalFrequencyScreen',modalScreen));
fprintf('Analytical comparison: %d static and %d modal training cases.\n', ...
    numel(static.caseIds),numel(modal.caseIds));
end

function profiles=buildStaticAxisProfiles(data,staticConfig)
n=numel(data.caseIds);
xi=data.normalizedGridCoordinates;
nx=21; ny=5; nz=5;
assert(isequal(size(xi),[3,nx*ny*nz]), ...
    'femvalidation:StaticGrid','Unexpected static reference grid.');
iy=(ny+1)/2; iz=(nz+1)/2;
linearIndex=(1:nx)+(iy-1)*nx+(iz-1)*nx*ny;
s=xi(1,linearIndex).*data.inputParameters(:,1);
rowCount=n*nx*2;
caseId=zeros(rowCount,1); station=zeros(rowCount,1);
xMeters=zeros(rowCount,1); theory=strings(rowCount,1);
femUz=zeros(rowCount,1); analyticUz=zeros(rowCount,1);
row=0;
for i=1:n
    p=data.inputParameters(i,:);
    L=p(1); b=p(2); h=p(3); E=p(4); nu=p(5); F=p(6);
    area=b*h; Iy=b*h^3/12; G=E/(2*(1+nu));
    sCase=s(i,:);
    eb=F*sCase.^2.*(3*L-sCase)/(6*E*Iy);
    timoshenko=eb+F*sCase/(staticConfig.shearCorrectionFactor*G*area);
    fieldStart=2*nx*ny*nz+(1:nx*ny*nz);
    femField=data.displacementFields(fieldStart(linearIndex),i);
    for modelIndex=1:2
        if modelIndex==1
            modelName="Euler-Bernoulli";
            analytic=eb;
        else
            modelName="Timoshenko";
            analytic=timoshenko;
        end
        rows=row+(1:nx);
        caseId(rows)=data.caseIds(i);
        station(rows)=(1:nx)';
        xMeters(rows)=sCase(:);
        theory(rows)=modelName;
        femUz(rows)=femField(:);
        analyticUz(rows)=analytic(:);
        row=row+nx;
    end
end
profiles=table(caseId,station,xMeters,theory,femUz,analyticUz, ...
    'VariableNames',{'caseId','stationIndex','distanceFromClamp_m', ...
    'theory','femUz_m','analyticUz_m'});
end

function errors=buildStaticAxisErrors(profiles,relativeNormFloor)
caseIds=unique(profiles.caseId,'stable');
rows=numel(caseIds)*2;
caseId=zeros(rows,1); theory=strings(rows,1); pointCount=zeros(rows,1);
axisRmsAbsolute=zeros(rows,1); axisRmsRelative=nan(rows,1);
tipFem=zeros(rows,1); tipAnalytic=zeros(rows,1);
tipAbsolute=zeros(rows,1); tipRelative=nan(rows,1);
defined=false(rows,1); outRow=0;
for i=1:numel(caseIds)
    for modelIndex=1:2
        modelName=["Euler-Bernoulli","Timoshenko"];
        selected=profiles.caseId==caseIds(i) & profiles.theory==modelName(modelIndex);
        p=profiles(selected,:);
        errorField=p.femUz_m-p.analyticUz_m;
        rmsError=sqrt(mean(errorField.^2));
        rmsReference=sqrt(mean(p.analyticUz_m.^2));
        outRow=outRow+1;
        caseId(outRow)=caseIds(i);
        theory(outRow)=modelName(modelIndex);
        pointCount(outRow)=height(p);
        axisRmsAbsolute(outRow)=rmsError;
        if rmsReference>relativeNormFloor
            axisRmsRelative(outRow)=rmsError/rmsReference;
            defined(outRow)=true;
        end
        tipFem(outRow)=p.femUz_m(end);
        tipAnalytic(outRow)=p.analyticUz_m(end);
        tipAbsolute(outRow)=abs(tipFem(outRow)-tipAnalytic(outRow));
        if abs(tipAnalytic(outRow))>relativeNormFloor
            tipRelative(outRow)=tipAbsolute(outRow)/abs(tipAnalytic(outRow));
        end
    end
end
errors=table(caseId,theory,pointCount,axisRmsAbsolute,axisRmsRelative, ...
    tipFem,tipAnalytic,tipAbsolute,tipRelative,defined, ...
    'VariableNames',{'caseId','theory','axisPointCount','axisRmsAbsolute_m', ...
    'axisRmsRelative','tipFemUz_m','tipAnalyticUz_m','tipAbsoluteError_m', ...
    'tipRelativeError','relativeErrorDefined'});
end

function screen=buildModalFrequencyScreen(data,beta)
n=numel(data.caseIds);
femFrequencies=data.naturalFrequenciesHz;
assert(size(femFrequencies,2)>=6, ...
    'femvalidation:ModalFrequencyCount','Six FEM frequencies are required.');
femFrequencies=femFrequencies(:,1:6);
L=data.inputParameters(:,1);
b=data.inputParameters(:,2);
h=data.inputParameters(:,3);
E=data.inputParameters(:,4);
rho=data.inputParameters(:,6);
area=b.*h;
frequencyBendZ=beta(1)^2./(2*pi*L.^2).*sqrt(E.*(b.*h.^3/12)./(rho.*area));
frequencyBendY=beta(1)^2./(2*pi*L.^2).*sqrt(E.*(h.*b.^3/12)./(rho.*area));
nearestIndexZ=zeros(n,1); nearestIndexY=zeros(n,1);
nearestRelZ=zeros(n,1); nearestRelY=zeros(n,1);
for i=1:n
    [nearestRelZ(i),nearestIndexZ(i)]=min(abs(femFrequencies(i,:)-frequencyBendZ(i)) ...
        ./frequencyBendZ(i));
    [nearestRelY(i),nearestIndexY(i)]=min(abs(femFrequencies(i,:)-frequencyBendY(i)) ...
        ./frequencyBendY(i));
end
screen=table(data.caseIds(:),frequencyBendZ,frequencyBendY, ...
    femFrequencies(:,1),femFrequencies(:,2),femFrequencies(:,3), ...
    femFrequencies(:,4),femFrequencies(:,5),femFrequencies(:,6), ...
    nearestIndexZ,nearestRelZ,nearestIndexY,nearestRelY, ...
    'VariableNames',{'caseId','analyticFundamentalBendZ_Hz', ...
    'analyticFundamentalBendY_Hz','femFrequency1_Hz','femFrequency2_Hz', ...
    'femFrequency3_Hz','femFrequency4_Hz','femFrequency5_Hz', ...
    'femFrequency6_Hz','nearestFemIndexForBendZ','nearestRelDifferenceBendZ', ...
    'nearestFemIndexForBendY','nearestRelDifferenceBendY'});
end

function runMeshStudy(projectRoot,dataRoot,resultsRoot,studyRoot,cfg)
static=surrogate.loadDataset(fullfile(dataRoot,'static','train.mat'));
modal=surrogate.loadDataset(fullfile(dataRoot,'modal','train.mat'));
assert(string(static.split)=="train" && string(modal.split)=="train", ...
    'femvalidation:MeshSplit','Mesh study accepts training data only.');
runRecords=struct('modality',{},'caseId',{},'meshDivisor',{}, ...
    'attempt',{},'status',{},'startedAt',{},'seconds',{}, ...
    'errorIdentifier',{},'errorMessage',{});
failures=strings(0,1);
markInterruptedAttemptsAsAborted(resultsRoot);
for modality=["static","modal"]
    if modality=="static"
        data=static; representativeIds=cfg.staticRepresentativeCaseIds;
    else
        data=modal; representativeIds=cfg.modalRepresentativeCaseIds;
    end
    for caseId=representativeIds(:)'
        index=find(data.caseIds==caseId,1);
        assert(~isempty(index),'femvalidation:RepresentativeCase', ...
            'Representative case %d is not in the training split.',caseId);
        parameters=data.inputParameters(index,:);
        for meshDivisor=cfg.meshDivisors(:)'
            existing=findCompletedAttempt(resultsRoot,modality,caseId,meshDivisor,cfg);
            if existing
                continue
            end
            attempt=nextAttempt(resultsRoot,modality,caseId,meshDivisor);
            path=attemptPath(resultsRoot,modality,caseId,meshDivisor,attempt);
            record=struct('schema',cfg.schema,'studyId',cfg.studyId, ...
                'configHash',sha256File(fullfile(studyRoot,'config.json')), ...
                'modality',modality,'caseId',caseId, ...
                'meshDivisor',meshDivisor,'parameters',parameters, ...
                'attempt',attempt,'status',"running", ...
                'startedAt',string(datetime('now','TimeZone','UTC', ...
                'Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX')), ...
                'matlabVersion',string(version),'gitCommit',gitCommit(projectRoot));
            record.seconds=0;
            record.errorIdentifier=""; record.errorMessage="";
            saveImmutableMat(path,struct('record',record));
            started=tic;
            try
                if modality=="static"
                    output=solveStatic(projectRoot,parameters,meshDivisor);
                else
                    output=femstudy.fem.modal(parameters,meshDivisor);
                end
                record.status="completed";
                record.seconds=toc(started);
                record.completedAt=string(datetime('now','TimeZone','UTC', ...
                    'Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
                if modality=="static"
                    record.result=struct('field',output.S(:), ...
                        'tipUz_m',output.Y(1),'grid',output.xi, ...
                        'weights',output.w,'nodeCount',output.nNodes);
                else
                    record.result=struct('frequencyHz',output.frequencyHz(:), ...
                        'queryModes',output.queryModes, ...
                        'queryWeights',output.queryWeights(:), ...
                        'queryCoordinates',output.queryCoordinates, ...
                        'nodeCount',size(output.nodes,2));
                end
                record.errorIdentifier=""; record.errorMessage="";
            catch exception
                record.status="failed";
                record.seconds=toc(started);
                record.completedAt=string(datetime('now','TimeZone','UTC', ...
                    'Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
                record.errorIdentifier=string(exception.identifier);
                record.errorMessage=string(exception.message);
                failures(end+1,1)=sprintf('%s case %d mesh %d: %s (%s)', ...
                    modality,caseId,meshDivisor,exception.identifier,exception.message);
            end
            writeReplaceableMat(path,struct('record',record));
            runRecords(end+1)=struct('modality',modality,'caseId',caseId, ...
                'meshDivisor',meshDivisor,'attempt',attempt, ...
                'status',record.status,'startedAt',record.startedAt, ...
                'seconds',record.seconds,'errorIdentifier',record.errorIdentifier, ...
                'errorMessage',record.errorMessage);
            fprintf('%s case %d mesh %d: %s (%.2fs)\n', ...
                modality,caseId,meshDivisor,record.status,record.seconds);
        end
    end
end
runRecords=collectRunRecords(resultsRoot);
saveRunTable(fullfile(resultsRoot,'mesh_run_attempts.csv'),runRecords);
staticConvergence=buildStaticConvergence(resultsRoot,static,cfg);
modalConvergence=buildModalConvergence(resultsRoot,modal,cfg);
modalAnalytic=buildModalAnalyticMatches(resultsRoot,modal,cfg);
modalBase=buildModalBaseComparison(resultsRoot,modal,cfg);
saveImmutableTable(fullfile(resultsRoot,'static_mesh_convergence.csv'),staticConvergence);
saveImmutableTable(fullfile(resultsRoot,'modal_mesh_convergence.csv'),modalConvergence);
saveImmutableTable(fullfile(resultsRoot,'modal_analytical_mode_matches.csv'),modalAnalytic);
saveImmutableTable(fullfile(resultsRoot,'modal_mesh3_vs_stored.csv'),modalBase);
writeReplaceableMat(fullfile(resultsRoot,'mesh_study_summary.mat'), ...
    struct('runAttempts',runRecords,'failures',failures, ...
    'staticConvergence',staticConvergence, ...
    'modalConvergence',modalConvergence,'modalAnalyticalMatches',modalAnalytic, ...
    'modalMesh3VsStored',modalBase));
if ~isempty(failures)
    fprintf(2,'FEM failures were recorded:\n%s\n',strjoin(failures,newline));
    error('femvalidation:FEMFailures', ...
        '%d FEM run(s) failed; see results/mesh_run_attempts.csv and per-attempt MAT files.', ...
        numel(failures));
end
end

function output=solveStatic(projectRoot,parameters,meshDivisor)
coreConfig=config("smoke");
cfg=jsondecode(fileread(fullfile(projectRoot,'data_generation', ...
    'configs','data_generation_v1.json')));
coreConfig.names=cellstr(string(cfg.static.parameterNames));
coreConfig.lower=reshape(cfg.static.lower,1,[]);
coreConfig.upper=reshape(cfg.static.upper,1,[]);
coreConfig.gridSize=reshape(cfg.static.fieldGrid,1,[]);
coreConfig.meshDivisor=meshDivisor;
coreConfig.geometricOrder=string(cfg.static.geometricOrder);
coreConfig.saveRawMesh=false;
coreConfig.maxDeflectionRatio=cfg.static.maxDeflectionRatio;
output=solve_case(parameters,coreConfig);
end

function convergence=buildStaticConvergence(resultsRoot,data,cfg)
records=cell(numel(cfg.staticRepresentativeCaseIds),numel(cfg.meshDivisors));
for i=1:numel(cfg.staticRepresentativeCaseIds)
    for j=1:numel(cfg.meshDivisors)
        records{i,j}=loadCompletedRecord(resultsRoot,"static", ...
            cfg.staticRepresentativeCaseIds(i),cfg.meshDivisors(j),cfg);
    end
end
n=numel(cfg.staticRepresentativeCaseIds)*(numel(cfg.meshDivisors)-1);
caseId=zeros(n,1); coarseMesh=zeros(n,1); fineMesh=zeros(n,1);
relativeFieldChange=zeros(n,1); relativeTipChange=zeros(n,1);
productionFieldDifference=nan(n,1); productionTipDifference=nan(n,1);
row=0;
for i=1:numel(cfg.staticRepresentativeCaseIds)
    dataIndex=find(data.caseIds==cfg.staticRepresentativeCaseIds(i),1);
    reference=data.displacementFields(:,dataIndex);
    referenceTip=referenceTipUz(data,dataIndex);
    for j=1:numel(cfg.meshDivisors)-1
        coarse=records{i,j}.result; fine=records{i,j+1}.result;
        denominator=sqrt(sum(coarse.weights(:).*coarse.field(:).^2));
        fieldError=sqrt(sum(coarse.weights(:).*(fine.field(:)-coarse.field(:)).^2));
        row=row+1; caseId(row)=cfg.staticRepresentativeCaseIds(i);
        coarseMesh(row)=cfg.meshDivisors(j); fineMesh(row)=cfg.meshDivisors(j+1);
        relativeFieldChange(row)=fieldError/max(denominator,realmin);
        relativeTipChange(row)=abs(fine.tipUz_m-coarse.tipUz_m) ...
            /max(abs(coarse.tipUz_m),realmin);
        if cfg.meshDivisors(j)==3
            baseDenominator=sqrt(sum(data.displacementComponentWeights(:).*reference(:).^2));
            productionFieldDifference(row)=sqrt(sum(data.displacementComponentWeights(:) ...
                .*(coarse.field(:)-reference(:)).^2))/max(baseDenominator,realmin);
            productionTipDifference(row)=abs(coarse.tipUz_m-referenceTip) ...
                /max(abs(referenceTip),realmin);
        end
    end
end
convergence=table(caseId,coarseMesh,fineMesh,relativeFieldChange, ...
    relativeTipChange,productionFieldDifference,productionTipDifference, ...
    'VariableNames',{'caseId','coarseMeshDivisor','fineMeshDivisor', ...
    'relativeWeightedFieldChange','relativeTipChange', ...
    'mesh3VsStoredFieldRelativeDifference','mesh3VsStoredTipRelativeDifference'});
end

function value=referenceTipUz(data,index)
fieldIndex=1050+273;
value=data.displacementFields(fieldIndex,index);
end

function convergence=buildModalConvergence(resultsRoot,data,cfg)
n=numel(cfg.modalRepresentativeCaseIds)*(numel(cfg.meshDivisors)-1)*6;
caseId=zeros(n,1); coarseMesh=zeros(n,1); fineMesh=zeros(n,1);
coarseMode=zeros(n,1); fineMode=zeros(n,1); macValue=zeros(n,1);
coarseFrequency=zeros(n,1); fineFrequency=zeros(n,1);
relativeFrequencyChange=zeros(n,1); status=strings(n,1); row=0;
for i=1:numel(cfg.modalRepresentativeCaseIds)
    meshRecords=cell(1,numel(cfg.meshDivisors));
    for j=1:numel(cfg.meshDivisors)
        meshRecords{j}=loadCompletedRecord(resultsRoot,"modal", ...
            cfg.modalRepresentativeCaseIds(i),cfg.meshDivisors(j),cfg);
    end
    for j=1:numel(cfg.meshDivisors)-1
        a=meshRecords{j}.result; b=meshRecords{j+1}.result;
        [pairs,mac]=matchModes(a.queryModes,b.queryModes,a.queryWeights,6);
        for m=1:size(pairs,1)
            row=row+1; cm=pairs(m,1); fm=pairs(m,2);
            caseId(row)=cfg.modalRepresentativeCaseIds(i);
            coarseMesh(row)=cfg.meshDivisors(j);
            fineMesh(row)=cfg.meshDivisors(j+1);
            coarseMode(row)=cm; fineMode(row)=fm; macValue(row)=mac(cm,fm);
            coarseFrequency(row)=a.frequencyHz(cm);
            fineFrequency(row)=b.frequencyHz(fm);
            relativeFrequencyChange(row)=abs(a.frequencyHz(cm)-b.frequencyHz(fm)) ...
                /max(abs(a.frequencyHz(cm)),realmin);
            if macValue(row)>=cfg.modal.macAcceptanceThreshold
                status(row)="matched";
            else
                status(row)="low_MAC_ambiguous";
            end
        end
    end
end
convergence=table(caseId,coarseMesh,fineMesh,coarseMode,fineMode,macValue, ...
    coarseFrequency,fineFrequency,relativeFrequencyChange,status, ...
    'VariableNames',{'caseId','coarseMeshDivisor','fineMeshDivisor', ...
    'coarseModeIndex','fineModeIndex','MAC','coarseFrequency_Hz', ...
    'fineFrequency_Hz','relativeFrequencyChange','status'});
end

function comparison=buildModalBaseComparison(resultsRoot,data,cfg)
n=numel(cfg.modalRepresentativeCaseIds)*6;
caseId=zeros(n,1); modeIndex=zeros(n,1); storedFrequency=zeros(n,1);
recomputedFrequency=zeros(n,1); absoluteDifference=zeros(n,1);
relativeDifference=zeros(n,1); row=0;
for i=1:numel(cfg.modalRepresentativeCaseIds)
    index=find(data.caseIds==cfg.modalRepresentativeCaseIds(i),1);
    record=loadCompletedRecord(resultsRoot,"modal", ...
        cfg.modalRepresentativeCaseIds(i),3,cfg);
    for mode=1:6
        row=row+1; caseId(row)=cfg.modalRepresentativeCaseIds(i);
        modeIndex(row)=mode;
        storedFrequency(row)=data.naturalFrequenciesHz(index,mode);
        recomputedFrequency(row)=record.result.frequencyHz(mode);
        absoluteDifference(row)=abs(recomputedFrequency(row)-storedFrequency(row));
        relativeDifference(row)=absoluteDifference(row)/abs(storedFrequency(row));
    end
end
comparison=table(caseId,modeIndex,storedFrequency,recomputedFrequency, ...
    absoluteDifference,relativeDifference, ...
    'VariableNames',{'caseId','frequencyIndex','storedMesh3_Hz', ...
    'recomputedMesh3_Hz','absoluteDifference_Hz','relativeDifference'});
end

function matches=buildModalAnalyticMatches(resultsRoot,data,cfg)
candidateCount=2*numel(cfg.modal.betaRoots);
n=numel(cfg.modalRepresentativeCaseIds)*numel(cfg.meshDivisors)*candidateCount;
caseId=zeros(n,1); meshDivisor=zeros(n,1); axisLabel=strings(n,1);
analyticOrder=zeros(n,1); analyticFrequency=zeros(n,1);
assignedMode=zeros(n,1); modalMAC=zeros(n,1); femFrequency=nan(n,1);
relativeFrequencyError=nan(n,1); status=strings(n,1); row=0;
for i=1:numel(cfg.modalRepresentativeCaseIds)
    dataIndex=find(data.caseIds==cfg.modalRepresentativeCaseIds(i),1);
    p=data.inputParameters(dataIndex,:);
    candidates=makeAnalyticModeCandidates(p,cfg.modal.betaRoots);
    for divisor=cfg.meshDivisors(:)'
        record=loadCompletedRecord(resultsRoot,"modal", ...
            cfg.modalRepresentativeCaseIds(i),divisor,cfg);
        q=record.result.queryModes;
        weights=record.result.queryWeights;
        scores=analyticModeMac(candidates,q,weights,record.result.queryCoordinates);
        [pairs,~]=matchModesFromScore(scores);
        assignment=nan(size(candidates,1),2);
        for k=1:size(pairs,1)
            assignment(pairs(k,1),:)=[pairs(k,2),scores(pairs(k,1),pairs(k,2))];
        end
        for k=1:size(candidates,1)
            row=row+1; caseId(row)=cfg.modalRepresentativeCaseIds(i);
            meshDivisor(row)=divisor; axisLabel(row)=candidates(k).axis;
            analyticOrder(row)=candidates(k).order;
            analyticFrequency(row)=candidates(k).frequencyHz;
            if isfinite(assignment(k,1))
                assignedMode(row)=assignment(k,1);
                modalMAC(row)=assignment(k,2);
                if modalMAC(row)>=cfg.modal.macAcceptanceThreshold
                    femFrequency(row)=record.result.frequencyHz(assignedMode(row));
                    relativeFrequencyError(row)=abs(femFrequency(row)-analyticFrequency(row)) ...
                        /analyticFrequency(row);
                    status(row)="matched";
                else
                    status(row)="low_MAC_unassigned";
                end
            else
                status(row)="unassigned";
            end
        end
    end
end
matches=table(caseId,meshDivisor,axisLabel,analyticOrder,analyticFrequency, ...
    assignedMode,modalMAC,femFrequency,relativeFrequencyError,status, ...
    'VariableNames',{'caseId','meshDivisor','bendingDirection', ...
    'analyticModeOrder','analyticFrequency_Hz','femModeIndex','MAC', ...
    'femFrequency_Hz','relativeFrequencyError','status'});
end

function candidates=makeAnalyticModeCandidates(p,betaRoots)
L=p(1); b=p(2); h=p(3); E=p(4); rho=p(6); area=b*h;
candidates=repmat(struct('axis',"",'order',0,'frequencyHz',0,'shape',[]), ...
    2*numel(betaRoots),1);
index=0;
for axisName=["z","y"]
    if axisName=="z", inertia=b*h^3/12; component=3;
    else, inertia=h*b^3/12; component=2;
    end
    for order=1:numel(betaRoots)
        index=index+1; beta=betaRoots(order);
        candidates(index)=struct('axis',axisName,'order',order, ...
            'frequencyHz',beta^2/(2*pi*L^2)*sqrt(E*inertia/(rho*area)), ...
            'shape',analyticBeamMode(beta,component));
    end
end
end

function shape=analyticBeamMode(beta,component)
[x,y,z]=ndgrid(linspace(0,1,21),linspace(0,1,5),linspace(0,1,5));
sigma=(cosh(beta)+cos(beta))/(sinh(beta)+sin(beta));
phi=cosh(beta*x)-cos(beta*x)-sigma*(sinh(beta*x)-sin(beta*x));
phiVector=phi(:);
shape=zeros(1575,1);
shape((component-1)*525+(1:525))=phiVector;
end

function scores=analyticModeMac(candidates,queryModes,weights,coordinates)
scores=zeros(numel(candidates),min(6,size(queryModes,2)));
for i=1:numel(candidates)
    shape=candidates(i).shape;
    assert(numel(coordinates)==3*525, ...
        'femvalidation:ModalGrid','Unexpected modal observation grid.');
    q=shape;
    qNorm=sum(weights(:).*q.^2);
    for j=1:size(scores,2)
        mode=queryModes(:,j);
        denominator=qNorm*sum(weights(:).*mode.^2);
        if denominator>0
            scores(i,j)=abs(sum(weights(:).*q.*mode))^2/denominator;
        end
    end
end
end

function [pairs,scores]=matchModes(a,b,weights,count)
count=min([count,size(a,2),size(b,2)]);
scores=zeros(count,count);
for i=1:count
    for j=1:count
        denominator=sum(weights(:).*a(:,i).^2)*sum(weights(:).*b(:,j).^2);
        if denominator>0
            scores(i,j)=abs(sum(weights(:).*a(:,i).*b(:,j)))^2/denominator;
        end
    end
end
[pairs,~]=matchModesFromScore(scores);
end

function [pairs,assignedScore]=matchModesFromScore(scores)
[candidateIndex,modeIndex]=ndgrid(1:size(scores,1),1:size(scores,2));
values=scores(:);
[~,order]=sort(values,'descend');
usedCandidates=false(size(scores,1),1);
usedModes=false(size(scores,2),1);
pairs=zeros(0,2); assignedScore=zeros(0,1);
for k=1:numel(order)
    candidate=candidateIndex(order(k)); mode=modeIndex(order(k));
    if ~usedCandidates(candidate) && ~usedModes(mode)
        pairs(end+1,:)=[candidate,mode];
        assignedScore(end+1,1)=scores(candidate,mode);
        usedCandidates(candidate)=true; usedModes(mode)=true;
        if size(pairs,1)==min(size(scores)), break; end
    end
end
end

function found=findCompletedAttempt(resultsRoot,modality,caseId,divisor,cfg)
files=dir(fullfile(resultsRoot,sprintf('%s_case_%06d_mesh_%02d_attempt_*.mat', ...
    modality,caseId,divisor)));
found=false;
for i=1:numel(files)
    item=load(fullfile(files(i).folder,files(i).name),'record');
    record=item.record;
    configPath=fullfile(fileparts(fileparts(mfilename('fullpath'))),'config.json');
    assert(record.caseId==caseId && record.meshDivisor==divisor && ...
        string(record.modality)==modality && ...
        string(record.configHash)==sha256File(configPath), ...
        'femvalidation:ResumeConflict','Existing FEM attempt conflicts with the study configuration.');
    if string(record.status)=="completed"
        found=true;
        return
    end
end
end

function record=loadCompletedRecord(resultsRoot,modality,caseId,divisor,cfg)
files=dir(fullfile(resultsRoot,sprintf('%s_case_%06d_mesh_%02d_attempt_*.mat', ...
    modality,caseId,divisor)));
if ~isempty(files)
    [~,order]=sort({files.name});
    files=files(order);
end
for i=numel(files):-1:1
    item=load(fullfile(files(i).folder,files(i).name),'record');
    record=item.record;
    assert(string(record.configHash)==sha256File(fullfile( ...
        fileparts(fileparts(mfilename('fullpath'))),'config.json')), ...
        'femvalidation:ResumeConflict','Existing FEM attempt has a different config hash.');
    if string(record.status)=="completed"
        return
    end
end
error('femvalidation:MissingAttempt', ...
    'No successful result for %s case %d mesh %d.',modality,caseId,divisor);
end

function attempt=nextAttempt(resultsRoot,modality,caseId,divisor)
files=dir(fullfile(resultsRoot,sprintf('%s_case_%06d_mesh_%02d_attempt_*.mat', ...
    modality,caseId,divisor)));
attempt=numel(files)+1;
end

function path=attemptPath(resultsRoot,modality,caseId,divisor,attempt)
path=fullfile(resultsRoot,sprintf('%s_case_%06d_mesh_%02d_attempt_%03d.mat', ...
    modality,caseId,divisor,attempt));
end

function writeManifest(studyRoot,projectRoot,dataRoot,cfg)
files={fullfile(studyRoot,'config.json'), ...
    fullfile(studyRoot,'protocol.md'),fullfile(studyRoot,'scripts','run_validation.m'), ...
    fullfile(projectRoot,'data_generation','configs','data_generation_v1.json'), ...
    fullfile(projectRoot,'fem_core','config.m'), ...
    fullfile(projectRoot,'fem_core','src','solve_case.m'), ...
    fullfile(projectRoot,'fem_core','src','reference_grid.m'), ...
    fullfile(projectRoot,'fem_core','src','rom_observation.m'), ...
    fullfile(projectRoot,'fem_core','src','+femstudy','+fem','modal.m'), ...
    fullfile(projectRoot,'loadFemDataset.m'), ...
    fullfile(dataRoot,'static','design.csv'), ...
    fullfile(dataRoot,'static','train.mat'), ...
    fullfile(dataRoot,'modal','design.csv'), ...
    fullfile(dataRoot,'modal','train.mat')};
lines=["studyId="+string(cfg.studyId); ...
    "MATLAB="+string(version); ...
    "PDE="+string(ver('pde').Version); ...
    "platform="+string(computer); ...
    "cpu="+string(getenv('PROCESSOR_IDENTIFIER'))];
for i=1:numel(files)
    assert(isfile(files{i}),'femvalidation:MissingProvenanceSource', ...
        'Missing provenance input: %s',files{i});
    [~,name,ext]=fileparts(files{i});
    lines(end+1,1)="file_"+string(i)+"_"+string([name ext])+"="+sha256File(files{i});
end
text=strjoin(lines,newline)+newline;
writeImmutableText(fullfile(studyRoot,'results','study_manifest.txt'),text);
end

function hash=sha256File(path)
fid=fopen(path,'rb');
assert(fid>=0,'femvalidation:HashRead','Cannot open file for hashing: %s',path);
cleanup=onCleanup(@()fclose(fid));
bytes=fread(fid,Inf,'*uint8');
digest=java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytes,'int8'));
hash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
clear cleanup
end

function writeImmutableText(path,text)
if isfile(path)
    assert(string(fileread(path))==string(text), ...
        'femvalidation:ManifestConflict','Existing manifest differs: %s',path);
    return
end
fid=fopen(path,'w');
assert(fid>=0,'femvalidation:Write','Cannot write file: %s',path);
cleanup=onCleanup(@()fclose(fid));
fwrite(fid,text,'char');
clear cleanup
end

function saveImmutableMat(path,variables)
if isfile(path)
    old=load(path);
    names=fieldnames(variables);
    assert(all(isfield(old,names)),'femvalidation:ArtifactConflict', ...
        'Existing artifact has a different structure: %s',path);
    for i=1:numel(names)
        assert(isequaln(old.(names{i}),variables.(names{i})), ...
            'femvalidation:ArtifactConflict','Refusing to overwrite: %s',path);
    end
    return
end
folder=fileparts(path);
if ~isfolder(folder), mkdir(folder); end
temporary=[tempname(folder),'.mat'];
save(temporary,'-struct','variables','-v7.3');
[ok,message]=movefile(temporary,path);
assert(ok,'femvalidation:Write','Could not save %s: %s',path,message);
end

function saveImmutableTable(path,value)
if isfile(path)
    temporary=[tempname(fileparts(path)),'.csv'];
    writetable(value,temporary);
    cleanup=onCleanup(@()delete(temporary));
    assert(string(fileread(path))==string(fileread(temporary)), ...
        'femvalidation:ArtifactConflict','Refusing to overwrite: %s',path);
    clear cleanup
    return
end
folder=fileparts(path);
if ~isfolder(folder), mkdir(folder); end
temporary=[tempname(folder),'.csv'];
writetable(value,temporary);
[ok,message]=movefile(temporary,path);
assert(ok,'femvalidation:Write','Could not save %s: %s',path,message);
end

function saveRunTable(path,records)
T=struct2table(records);
if ~isfolder(fileparts(path)), mkdir(fileparts(path)); end
writetable(T,path);
end

function records=collectRunRecords(resultsRoot)
records=struct('modality',{},'caseId',{},'meshDivisor',{}, ...
    'attempt',{},'status',{},'startedAt',{},'seconds',{}, ...
    'errorIdentifier',{},'errorMessage',{});
for modality=["static","modal"]
    files=dir(fullfile(resultsRoot,sprintf('%s_case_*_mesh_*_attempt_*.mat',modality)));
    for i=1:numel(files)
        item=load(fullfile(files(i).folder,files(i).name),'record');
        record=item.record;
        records(end+1)=struct('modality',record.modality,'caseId',record.caseId, ...
            'meshDivisor',record.meshDivisor,'attempt',record.attempt, ...
            'status',record.status,'startedAt',record.startedAt, ...
            'seconds',record.seconds,'errorIdentifier',record.errorIdentifier, ...
            'errorMessage',record.errorMessage);
    end
end
end

function writeReplaceableMat(path,variables)
folder=fileparts(path);
if ~isfolder(folder), mkdir(folder); end
temporary=[tempname(folder),'.mat'];
save(temporary,'-struct','variables','-v7.3');
[ok,message]=movefile(temporary,path,'f');
assert(ok,'femvalidation:Write','Could not update %s: %s',path,message);
end

function markInterruptedAttemptsAsAborted(resultsRoot)
files=[dir(fullfile(resultsRoot,'static_case_*_mesh_*_attempt_*.mat')); ...
    dir(fullfile(resultsRoot,'modal_case_*_mesh_*_attempt_*.mat'))];
for i=1:numel(files)
    path=fullfile(files(i).folder,files(i).name);
    item=load(path,'record');
    record=item.record;
    if string(record.status)=="running"
        record.status="aborted";
        record.completedAt=string(datetime('now','TimeZone','UTC', ...
            'Format','yyyy-MM-dd''T''HH:mm:ss.SSSXXX'));
        record.errorIdentifier="femvalidation:Interrupted";
        record.errorMessage="Previous process ended before this attempt completed.";
        writeReplaceableMat(path,struct('record',record));
    end
end
end

function commit=gitCommit(projectRoot)
[status,output]=system(sprintf('git -C "%s" rev-parse HEAD',projectRoot));
if status==0
    commit=strtrim(string(output));
else
    commit="unavailable";
end
end
