function studyReport(out,cfg)
studyCheckFrozen(out); assert(isfile(fullfile(out,'evaluation.complete')),'study:EvaluationIncomplete','Evaluate first.');
files=dir(fullfile(out,'evaluation','**','*.mat')); rows=table; cases=table;
for k=1:numel(files)
    filename=fullfile(files(k).folder,files(k).name); expected=strtrim(fileread(string(filename)+'.sha256'));
    assert(strcmp(studyHash(filename),expected),'study:EvaluationChanged','Evaluation result changed.');
    a=load(filename,'observed'); q=a.observed; folder=string(files(k).folder);
    runId=extractAfter(folder,strlength(string(fullfile(out,'evaluation')))+1);
    e=q.relative; good=e(isfinite(e)); avg=NaN; med=NaN; p95=NaN; worst=NaN;
    if ~isempty(good), good=sort(good); avg=mean(good); med=median(good); p95=good(ceil(.95*numel(good))); worst=max(good); end
    absolute=mean(q.absolute,'omitnan'); single=NaN; batch=NaN; singleIqr=NaN; batchIqr=NaN;
    timeFile=fullfile(files(k).folder,'interpolation.mat');
    if isfile(timeFile)
        assert(isfile(string(timeFile)+'.sha256') && strcmp(studyHash(timeFile), ...
            strtrim(fileread(string(timeFile)+'.sha256'))),'study:EvaluationChanged','Timing checkpoint changed.');
        t=load(timeFile,'observed'); single=median(t.observed.singleTimes); batch=median(t.observed.batchTimes);
        if ~isempty(t.observed.singleTimes), singleIqr=iqr(t.observed.singleTimes); batchIqr=iqr(t.observed.batchTimes); end
    end
    prep=NaN; pod=NaN; regression=NaN; center=NaN;
    if isfield(q.report,'timing')
        t=q.report.timing;
        if isfield(t,'preprocessSeconds'), prep=t.preprocessSeconds; end
        if isfield(t,'podSeconds'), pod=t.podSeconds; end
        if isfield(t,'centerSeconds'), center=t.centerSeconds; end
        if isfield(t,'regressionSeconds'), regression=t.regressionSeconds; end
    end
    sharedPod=0;
    if startsWith(runId,"controlled")
        token=regexp(char(runId),'n(\d+)_rep(\d+)_rank(\d+)','tokens','once');
        if ~isempty(token)
            path=fullfile(out,'bases',sprintf('n%s_rep%s_rank%s',token{1},token{2},token{3}),'pod.mat');
            if isfile(path), b=load(path,'podSeconds'); sharedPod=b.podSeconds; end
        end
    end
    id=runId; method=q.method; role=q.role; status=q.status; message=q.message; N=numel(q.trainingIds);
    fitSeconds=q.fitSeconds; standaloneFitSeconds=fitSeconds+sharedPod; undefined=sum(~isfinite(e));
    modelBytes=q.modelBytes; loadSeconds=q.loadSeconds; saveSeconds=q.saveSeconds;
    row=table(id,method,role,status,message,N,fitSeconds,prep,pod,center,regression,sharedPod, ...
        standaloneFitSeconds,modelBytes,loadSeconds,saveSeconds,single,singleIqr,batch,batchIqr, ...
        avg,med,p95,worst,absolute,undefined);
    rows=[rows;row]; %#ok<AGROW>
    count=numel(q.caseIds);
    c=table(repmat(id,count,1),repmat(method,count,1),repmat(role,count,1), ...
        repmat(status,count,1),repmat(message,count,1),q.caseIds(:), ...
        q.relative(:),q.absolute(:),q.referenceNorm(:),q.tipError(:),q.maxMagnitudeError(:), ...
        q.femTip(:),q.eulerBernoulliTip(:),q.timoshenkoTip(:), ...
        q.projectionSquared(:),q.regressionSquared(:),q.reconstructionSquared(:),q.decompositionResidual(:), ...
        q.decompositionValid(:),abs(q.tipError(:)),abs(q.maxMagnitudeError(:)), ...
        'VariableNames',{'RunId','Method','Role','Status','Message','CaseId','Relative','Absolute','ReferenceNorm','TipError', ...
        'MaxMagnitudeError','FemTip','EulerBernoulliTip','TimoshenkoTip','ProjectionSquared','RegressionSquared','ReconstructionSquared','DecompositionResidual','DecompositionValid','AbsoluteTipError','AbsoluteMaxMagnitudeError'});
    cases=[cases;c]; %#ok<AGROW>
end
writetable(rows,fullfile(out,'run_results.csv')); writetable(cases,fullfile(out,'case_results.csv'));
pipeline=rows(startsWith(rows.id,"runs"),:); summaries=table;
for role=["interpolation","extrapolation"]
    for method=["mlp","rbf","pod_mlp","pod_gpr"]
        for n=cfg.training_sizes(:)'
            part=pipeline(pipeline.role==role & pipeline.method==method & pipeline.N==n,:);
            if isempty(part), continue; end
            ok=part(part.status=="ok",:); count=height(ok); failed=height(part)-count;
            meanError=mean(ok.avg,'omitnan'); runStd=std(ok.avg,'omitnan');
            medianError=mean(ok.med,'omitnan'); p95Error=mean(ok.p95,'omitnan');
            if isempty(ok), maxObserved=NaN; else, maxObserved=max(ok.worst,[],'omitnan'); end
            fitMedian=median(ok.fitSeconds,'omitnan'); predictMedian=median(ok.single,'omitnan');
            variation="training selection"; if n==768 && method~="pod_gpr", variation="network initialization"; end
            if n==768 && method=="pod_gpr", variation="none"; end
            summaries=[summaries;table(role,method,n,count,failed,variation,meanError,runStd, ...
                medianError,p95Error,maxObserved,fitMedian,predictMedian)]; %#ok<AGROW>
        end
    end
end
writetable(summaries,fullfile(out,'pipeline_summary.csv'));
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
train=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
referenceRole="historical_training_pool"; solverSeconds=sum(train.computationTimeSeconds); activeWallSeconds=NaN;
failedCases=NaN; costs=table(referenceRole,solverSeconds,activeWallSeconds,failedCases);
for referenceRole=["val","interpolation","extrapolation"]
    folder=fullfile(out,'references',referenceRole); ledger=readtable(fullfile(folder,'ledger.csv'),'TextType','string');
    sessions=readtable(fullfile(folder,'generation_sessions.csv'),'TextType','string');
    solverSeconds=sum(ledger.solver_seconds,'omitnan'); activeWallSeconds=sum(sessions.elapsed_seconds);
    failedCases=nnz(ledger.status~="ok"); costs=[costs;table(referenceRole,solverSeconds,activeWallSeconds,failedCases)]; %#ok<AGROW>
end
writetable(costs,fullfile(out,'reference_costs.csv'));
search=table;
for method=["mlp","rbf","pod_mlp","pod_gpr"]
    a=load(fullfile(out,'tuning',method,'search_summary.mat'),'info'); info=a.info;
    sessions=readtable(fullfile(out,'tuning',method,'search_sessions.csv'),'TextType','string');
    searchSeconds=sum(sessions.elapsed_seconds);
    search=[search;table(method,info.attempted,info.candidates,searchSeconds,info.winner, ...
        'VariableNames',{'Method','Attempted','Candidates','SearchSeconds','Winner'})]; %#ok<AGROW>
end
allSessions=readtable(fullfile(out,'search_sessions.csv'),'TextType','string');
method="all"; attempted=sum(search.Attempted); candidates=sum(search.Candidates);
searchSeconds=sum(allSessions.elapsed_seconds); winner=NaN;
search=[search;table(method,attempted,candidates,searchSeconds,winner, ...
    'VariableNames',{'Method','Attempted','Candidates','SearchSeconds','Winner'})];
writetable(search,fullfile(out,'search_costs.csv'));
files=dir(fullfile(out,'tuning','**','result.mat'));
attempts=table('Size',[0 6],'VariableTypes',{'string','string','string','double','double','string'}, ...
    'VariableNames',{'Checkpoint','Method','Status','FitSeconds','WallSeconds','Message'});
for j=1:numel(files)
    path=fullfile(files(j).folder,files(j).name); a=load(path,'result'); r=a.result;
    attempts=[attempts;table(string(files(j).folder),r.method,r.status,r.fitSeconds,r.wallSeconds,r.message, ...
        'VariableNames',attempts.Properties.VariableNames)]; %#ok<AGROW>
end
writetable(attempts,fullfile(out,'search_attempts.csv'));
times=dir(fullfile(out,'timing_repeats','**','result.mat'));
repeatTimes=table('Size',[0 4],'VariableTypes',{'string','string','double','string'}, ...
    'VariableNames',{'Run','Status','FitSeconds','Message'});
for j=1:numel(times)
    a=load(fullfile(times(j).folder,times(j).name),'result'); r=a.result;
    repeatTimes=[repeatTimes;table(string(times(j).folder),r.status,r.fitSeconds,r.message, ...
        'VariableNames',{'Run','Status','FitSeconds','Message'})]; %#ok<AGROW>
end
writetable(repeatTimes,fullfile(out,'gpr_fit_timing_repeats.csv'));
summary=fullfile(out,'REPORT.md'); fid=fopen(summary,'w'); cleaner=onCleanup(@()fclose(fid));
fprintf(fid,'# Statischer Vier-Methoden-Vergleich\n\nTest-Freeze vor Auswertung geprueft. Details: run_results.csv und case_results.csv.\n\n');
fprintf(fid,'Erfolgreiche Lauf/Split-Auswertungen: %d; fehlgeschlagene: %d.\n\n',nnz(rows.status=="ok"),nnz(rows.status~="ok"));
fprintf(fid,'Gewichtete relative Fehler sind Fallgroessen; Wiederholungen sind keine zusaetzlichen unabhaengigen Faelle. Interpolation und Extrapolation bleiben getrennt.\n\n');
final=summaries(summaries.role=="interpolation" & summaries.n==768 & summaries.failed==0 & isfinite(summaries.meanError),:);
if ~isempty(final)
    [~,i]=min(final.meanError); chosen=final(i,:);
    fprintf(fid,'Genauigkeitsorientierter Ausgangspunkt (Interpolation, N=768): %s; mittlerer relativer Fehler %.6g, mediane Fit-Zeit %.4g s und mediane Einzelfall-Vorhersage %.4g s. Diese Auswahl ist eine Beschreibung dieses begrenzten Vergleichs; Extrapolation, Streuung und Datenkosten in pipeline_summary.csv mitbeurteilen.\n\n', ...
        chosen.method,chosen.meanError,chosen.fitMedian,chosen.predictMedian);
end
fprintf(fid,'Kein Break-even wurde angegeben, da kein zeitgleich kontrollierter FEM-Vergleich vorliegt.\n\n');
fprintf(fid,'TipError ist die vorzeichenbehaftete Abweichung von uz am Punkt (1,0.5,0.5); MaxMagnitudeError ist die vorzeichenbehaftete Differenz der Maximalbetraege. Absolute Varianten stehen zusaetzlich in case_results.csv.\n\n');
fprintf(fid,'Die vollstaendigen Modell- und Datenkosten, Suchhistorie und Fehlversuche sind in den zugehoerigen Checkpoints und Tabellen dokumentiert. Analytische Balkenloesungen sind keine exakte 3D-Feldreferenz.\n');
end
