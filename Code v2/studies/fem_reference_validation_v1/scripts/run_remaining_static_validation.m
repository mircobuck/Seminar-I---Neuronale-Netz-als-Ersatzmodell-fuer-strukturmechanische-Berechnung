function run_remaining_static_validation(outputDir)
%RUN_REMAINING_STATIC_VALIDATION Compare remaining static FEM cases to beams.
%   Reads the 384 added training cases and all validation and test cases.
%   Does not run FEM, train a surrogate, or evaluate surrogate predictions.
studyRoot=fileparts(fileparts(mfilename('fullpath')));
projectRoot=fileparts(fileparts(studyRoot));
dataRoot=fullfile(projectRoot,'data_generation','data','static');
if nargin<1 || isempty(outputDir)
    outputDir=fullfile(studyRoot,'results','remaining_static_20261106');
end
if ~isfolder(outputDir), mkdir(outputDir); end

oldPath=path;
pathCleanup=onCleanup(@()path(oldPath));
addpath(projectRoot,'-begin');
train=surrogate.loadDataset(fullfile(dataRoot,'train.mat'));
validation=surrogate.loadDataset(fullfile(dataRoot,'val.mat'));
test=surrogate.loadDataset(fullfile(dataRoot,'test.mat'));
original=surrogate.loadDataset(fullfile(dataRoot,'backup_384','train.mat'));

assert(string(train.split)=="train" && numel(train.caseIds)==768, ...
    'femvalidation:RemainingStatic:Train','Expected 768 current training cases.');
assert(string(validation.split)=="val" && numel(validation.caseIds)==12, ...
    'femvalidation:RemainingStatic:Validation','Expected 12 validation cases.');
assert(string(test.split)=="test" && numel(test.caseIds)==64, ...
    'femvalidation:RemainingStatic:Test','Expected 64 test cases.');
assert(numel(original.caseIds)==384 && all(ismember(original.caseIds,train.caseIds)), ...
    'femvalidation:RemainingStatic:OriginalTrain','Original training IDs differ.');
assert(isempty(intersect(train.caseIds,validation.caseIds)) && ...
    isempty(intersect(train.caseIds,test.caseIds)) && ...
    isempty(intersect(validation.caseIds,test.caseIds)), ...
    'femvalidation:RemainingStatic:SplitOverlap','Static split IDs overlap.');

addedMask=~ismember(train.caseIds,original.caseIds);
assert(nnz(addedMask)==384, ...
    'femvalidation:RemainingStatic:AddedTrain','Expected 384 added training cases.');
sets={train,validation,test};
sets{1}.caseIds=train.caseIds(addedMask);
sets{1}.inputParameters=train.inputParameters(addedMask,:);
sets{1}.displacementFields=train.displacementFields(:,addedMask);
splitNames=["train_added";"validation";"test"];
caseTotal=sum(cellfun(@(d)numel(d.caseIds),sets));
nx=21; ny=5; nz=5;
profileRows=caseTotal*nx*2;
caseId=zeros(profileRows,1); station=zeros(profileRows,1);
distance=zeros(profileRows,1); split=strings(profileRows,1);
theory=strings(profileRows,1); femUz=zeros(profileRows,1);
analyticUz=zeros(profileRows,1); row=0;
gridLinear=(1:nx)+(3-1)*nx+(3-1)*nx*ny;

for splitIndex=1:numel(sets)
    data=sets{splitIndex};
    assert(isequal(size(data.normalizedGridCoordinates),[3,nx*ny*nz]), ...
        'femvalidation:RemainingStatic:Grid','Unexpected static reference grid.');
    for i=1:numel(data.caseIds)
        p=data.inputParameters(i,:);
        L=p(1); b=p(2); h=p(3); E=p(4); nu=p(5); F=p(6);
        A=b*h; Iy=b*h^3/12; G=E/(2*(1+nu));
        s=data.normalizedGridCoordinates(1,gridLinear)*L;
        eb=F*s.^2.*(3*L-s)/(6*E*Iy);
        timoshenko=eb+F*s/((5/6)*G*A);
        fieldRows=2*nx*ny*nz+gridLinear;
        femProfile=data.displacementFields(fieldRows,i);
        for theoryIndex=1:2
            rowIndex=row+(1:nx);
            row=row+nx;
            caseId(rowIndex)=data.caseIds(i);
            station(rowIndex)=(1:nx)';
            distance(rowIndex)=s(:);
            split(rowIndex)=splitNames(splitIndex);
            if theoryIndex==1
                theory(rowIndex)="Euler-Bernoulli";
                analyticUz(rowIndex)=eb(:);
            else
                theory(rowIndex)="Timoshenko";
                analyticUz(rowIndex)=timoshenko(:);
            end
            femUz(rowIndex)=femProfile(:);
        end
    end
end
profiles=table(caseId,split,station,distance,theory,femUz,analyticUz, ...
    'VariableNames',{'caseId','split','stationIndex','distanceFromClamp_m', ...
    'theory','femUz_m','analyticUz_m'});

uniqueCases=unique(caseId,'stable');
errorRows=numel(uniqueCases)*2;
caseErrorId=zeros(errorRows,1); errorSplit=strings(errorRows,1);
errorTheory=strings(errorRows,1); pointCount=zeros(errorRows,1);
axisAbs=zeros(errorRows,1); axisRel=nan(errorRows,1);
tipFem=zeros(errorRows,1); tipAnalytic=zeros(errorRows,1);
tipAbs=zeros(errorRows,1); tipRel=nan(errorRows,1);
defined=false(errorRows,1); row=0;
for i=1:numel(uniqueCases)
    for theoryIndex=1:2
        row=row+1;
        if theoryIndex==1, theoryName="Euler-Bernoulli";
        else, theoryName="Timoshenko"; end
        mask=caseId==uniqueCases(i) & theory==theoryName;
        e=femUz(mask)-analyticUz(mask);
        ref=analyticUz(mask);
        axisAbs(row)=sqrt(mean(e.^2));
        refRms=sqrt(mean(ref.^2));
        if refRms>1e-12
            axisRel(row)=axisAbs(row)/refRms;
            defined(row)=true;
        end
        tipFem(row)=femUz(find(mask,1,'last'));
        tipAnalytic(row)=analyticUz(find(mask,1,'last'));
        tipAbs(row)=abs(tipFem(row)-tipAnalytic(row));
        if abs(tipAnalytic(row))>1e-12
            tipRel(row)=tipAbs(row)/abs(tipAnalytic(row));
        end
        caseErrorId(row)=uniqueCases(i);
        errorSplit(row)=split(find(mask,1));
        errorTheory(row)=theoryName;
        pointCount(row)=nnz(mask);
    end
end
remainingErrors=table(caseErrorId,errorSplit,errorTheory,pointCount,axisAbs, ...
    axisRel,tipFem,tipAnalytic,tipAbs,tipRel,defined, ...
    'VariableNames',{'caseId','split','theory','axisPointCount', ...
    'axisRmsAbsolute_m','axisRmsRelative','tipFemUz_m','tipAnalyticUz_m', ...
    'tipAbsoluteError_m','tipRelativeError','relativeErrorDefined'});

baselinePath=fullfile(studyRoot,'results','static_axis_errors.csv');
baseline=readtable(baselinePath,'TextType','string');
assert(isequal(sort(unique(baseline.caseId)),sort(original.caseIds)), ...
    'femvalidation:RemainingStatic:Baseline', ...
    'Existing 384-case baseline IDs do not match the original training split.');
baseline.split=repmat("train_original",height(baseline),1);
baseline=baseline(:,remainingErrors.Properties.VariableNames);
allErrors=[baseline;remainingErrors];
summarySplits=["train_added";"validation";"test";"all_remaining"; ...
    "all_static";"train_original"];
summaryTheories=["Euler-Bernoulli";"Timoshenko"];
summaryRows=numel(summarySplits)*numel(summaryTheories);
summarySplit=strings(summaryRows,1); summaryTheory=strings(summaryRows,1);
summaryCount=zeros(summaryRows,1); axisMedian=nan(summaryRows,1);
axisP95=nan(summaryRows,1); axisMax=nan(summaryRows,1);
tipMedian=nan(summaryRows,1); tipP95=nan(summaryRows,1); tipMax=nan(summaryRows,1);
row=0;
for sIndex=1:numel(summarySplits)
    for tIndex=1:numel(summaryTheories)
        row=row+1;
        summarySplit(row)=summarySplits(sIndex);
        summaryTheory(row)=summaryTheories(tIndex);
        if summarySplits(sIndex)=="all_remaining"
            selected=allErrors.split~="train_original";
        elseif summarySplits(sIndex)=="all_static"
            selected=true(height(allErrors),1);
        else
            selected=allErrors.split==summarySplits(sIndex);
        end
        selected=selected & allErrors.theory==summaryTheories(tIndex);
        q=allErrors(selected,:);
        if isempty(q), continue, end
        summaryCount(row)=numel(unique(q.caseId));
        axisValues=sort(q.axisRmsRelative(logical(q.relativeErrorDefined)));
        tipValues=sort(q.tipRelativeError(isfinite(q.tipRelativeError)));
        if ~isempty(axisValues)
            axisMedian(row)=median(axisValues);
            axisP95(row)=axisValues(ceil(.95*numel(axisValues)));
            axisMax(row)=max(axisValues);
        end
        if ~isempty(tipValues)
            tipMedian(row)=median(tipValues);
            tipP95(row)=tipValues(ceil(.95*numel(tipValues)));
            tipMax(row)=max(tipValues);
        end
    end
end
summary=table(summarySplit,summaryTheory,summaryCount,axisMedian,axisP95, ...
    axisMax,tipMedian,tipP95,tipMax);
remainingSummary=summary(~ismember(summary.summarySplit, ...
    ["train_original","all_static"]),:);
allStaticSummary=summary(summary.summarySplit=="all_static",:);

filesToWrite={"static_train_added_axis_profiles.csv", ...
    "static_validation_axis_profiles.csv","static_test_axis_profiles.csv", ...
    "static_remaining_axis_profiles.csv","static_remaining_axis_errors.csv", ...
    "static_remaining_summary.csv","static_all_cases_summary.csv", ...
    "REPORT.md","manifest.txt"};
for k=1:numel(filesToWrite)
    assert(~isfile(fullfile(outputDir,filesToWrite{k})), ...
        'femvalidation:RemainingStatic:Exists', ...
        'Refusing to overwrite existing result: %s',filesToWrite{k});
end
writetable(profiles(profiles.split=="train_added",:), ...
    fullfile(outputDir,filesToWrite{1}));
writetable(profiles(profiles.split=="validation",:), ...
    fullfile(outputDir,filesToWrite{2}));
writetable(profiles(profiles.split=="test",:), ...
    fullfile(outputDir,filesToWrite{3}));
writetable(profiles,fullfile(outputDir,filesToWrite{4}));
writetable(remainingErrors,fullfile(outputDir,filesToWrite{5}));
writetable(remainingSummary,fullfile(outputDir,filesToWrite{6}));
writetable(allStaticSummary,fullfile(outputDir,filesToWrite{7}));

reportPath=fullfile(outputDir,'REPORT.md');
fid=fopen(reportPath,'w');
assert(fid>=0,'femvalidation:RemainingStatic:Write','Cannot write report.');
fprintf(fid,['# Additional analytical validation of static FEM cases\n\n' ...
    '**Run date:** 2026-11-06  \n' ...
    '**Scope:** 384 added training, 12 validation and 64 test cases (460 total).  \n' ...
    '**Status:** completed; existing FEM results were read only.\n\n' ...
    'The remaining cases were compared with Euler-Bernoulli and Timoshenko ' ...
    'beam curves along the 21-point beam center axis, including tip deflection. ' ...
    'No FEM runs, surrogate training or surrogate predictions were performed. ' ...
    'Validation and test FEM labels were read for this physics-reference check; ' ...
    'this is not an independent POD-MLP test and must not be used for model selection.\n\n' ...
    'The original 384 training cases and their stored results were not changed. ' ...
    'The all-static summary combines those 384 cases with the 460 remaining cases ' ...
    '(844 unique cases). Relative errors are ratios; multiply by 100 for percent. ' ...
    'P95 uses nearest rank.\n\n' ...
    '## Remaining cases by split and theory\n\n' ...
    '| Split | Theory | Cases | Axis RMS median | Axis RMS P95 | Axis RMS max | Tip median | Tip P95 | Tip max |\n' ...
    '|---|---|---:|---:|---:|---:|---:|---:|---:|\n']);
for i=1:height(remainingSummary)
    fprintf(fid,'| %s | %s | %d | %.8g | %.8g | %.8g | %.8g | %.8g | %.8g |\n', ...
        remainingSummary.summarySplit(i),remainingSummary.summaryTheory(i), ...
        remainingSummary.summaryCount(i),remainingSummary.axisMedian(i), ...
        remainingSummary.axisP95(i),remainingSummary.axisMax(i), ...
        remainingSummary.tipMedian(i),remainingSummary.tipP95(i),remainingSummary.tipMax(i));
end
fprintf(fid,['\n## All 844 static cases (original plus remaining)\n\n' ...
    '| Theory | Cases | Axis RMS median | Axis RMS P95 | Axis RMS max | Tip median | Tip P95 | Tip max |\n' ...
    '|---|---:|---:|---:|---:|---:|---:|---:|\n']);
for i=1:height(allStaticSummary)
    fprintf(fid,'| %s | %d | %.8g | %.8g | %.8g | %.8g | %.8g | %.8g |\n', ...
        allStaticSummary.summaryTheory(i),allStaticSummary.summaryCount(i), ...
        allStaticSummary.axisMedian(i),allStaticSummary.axisP95(i), ...
        allStaticSummary.axisMax(i),allStaticSummary.tipMedian(i), ...
        allStaticSummary.tipP95(i),allStaticSummary.tipMax(i));
end
fprintf(fid,['\n## Limitations\n\n' ...
    '- This is a one-dimensional center-axis/tip comparison, not a full 3D field validation.\n' ...
    '- Euler-Bernoulli and Timoshenko are approximations, not exact 3D solutions.\n' ...
    '- Reading validation/test FEM labels here does not assess or select a surrogate.\n']);
fclose(fid);

hashPaths={fullfile(studyRoot,'protocol.md'), ...
    fullfile(studyRoot,'scripts','run_remaining_static_validation.m'), ...
    fullfile(projectRoot,'loadFemDataset.m'), ...
    fullfile(projectRoot,'+surrogate','loadDataset.m'), ...
    fullfile(dataRoot,'design.csv'),fullfile(dataRoot,'train.mat'), ...
    fullfile(dataRoot,'val.mat'),fullfile(dataRoot,'test.mat'), ...
    fullfile(dataRoot,'backup_384','design.csv'), ...
    fullfile(dataRoot,'backup_384','train.mat'),baselinePath};
manifestPath=fullfile(outputDir,'manifest.txt');
fid=fopen(manifestPath,'w');
assert(fid>=0,'femvalidation:RemainingStatic:Write','Cannot write manifest.');
fprintf(fid,'studyId=fem_reference_validation_v1_remaining_static_20261106\n');
fprintf(fid,'MATLAB=%s\nplatform=%s\nscope=384_added_training+12_validation+64_test\n', ...
    version,computer);
for k=1:numel(hashPaths)
    fileId=fopen(hashPaths{k},'rb');
    assert(fileId>=0,'femvalidation:RemainingStatic:HashRead', ...
        'Cannot read provenance file: %s',hashPaths{k});
    bytes=fread(fileId,Inf,'*uint8');
    fclose(fileId);
    digest=java.security.MessageDigest.getInstance('SHA-256');
    digest.update(typecast(bytes,'int8'));
    fileHash=lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2).',1,[]));
    [~,name,ext]=fileparts(hashPaths{k});
    fprintf(fid,'file_%02d_%s%s=%s\n',k,name,ext,fileHash);
end
fclose(fid);
fprintf(['Remaining static analytical comparison completed: %d cases ' ...
    '(%d added train, %d validation, %d test).\nResults: %s\n'], ...
    numel(unique(remainingErrors.caseId)),nnz(addedMask), ...
    numel(validation.caseIds),numel(test.caseIds),outputDir);
clear pathCleanup
end
