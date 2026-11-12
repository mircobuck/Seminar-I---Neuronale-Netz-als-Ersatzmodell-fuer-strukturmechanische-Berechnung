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
    modelBytes=q.modelBytes; loadSeconds=q.loadSeconds;
    row=table(id,method,role,status,message,N,fitSeconds,prep,pod,center,regression,sharedPod, ...
        standaloneFitSeconds,modelBytes,loadSeconds,single,singleIqr,batch,batchIqr, ...
        avg,med,p95,worst,absolute,undefined);
    rows=[rows;row]; %#ok<AGROW>
    count=numel(q.caseIds);
    c=table(repmat(id,count,1),repmat(method,count,1),repmat(role,count,1),q.caseIds(:), ...
        q.relative(:),q.absolute(:),q.referenceNorm(:),q.tipError(:),q.maxMagnitudeError(:), ...
        q.projectionSquared(:),q.regressionSquared(:),q.reconstructionSquared(:),q.decompositionResidual(:), ...
        'VariableNames',{'RunId','Method','Role','CaseId','Relative','Absolute','ReferenceNorm','TipError', ...
        'MaxMagnitudeError','ProjectionSquared','RegressionSquared','ReconstructionSquared','DecompositionResidual'});
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
plotDir=fullfile(out,'plots'); if ~isfolder(plotDir), mkdir(plotDir); end
for role=["interpolation","extrapolation"]
    subset=rows(rows.role==role & rows.status=="ok" & startsWith(rows.id,"runs"),:);
    if isempty(subset), continue; end
    plotScatter(subset.N,subset.avg,subset.method,'Trainingsf?lle','Mittlerer relativer Feldfehler',fullfile(plotDir,role+'_error_vs_data.png'));
    plotScatter(subset.N,subset.fitSeconds,subset.method,'Trainingsf?lle','Fit-Zeit [s]',fullfile(plotDir,role+'_train_vs_data.png'));
    plotScatter(subset.fitSeconds,subset.avg,subset.method,'Fit-Zeit [s]','Mittlerer relativer Feldfehler',fullfile(plotDir,role+'_error_vs_train.png'));
    plotScatter(subset.single,subset.avg,subset.method,'Vollst?ndige Einzelfall-Vorhersage [s]','Mittlerer relativer Feldfehler',fullfile(plotDir,role+'_error_vs_prediction.png'));
    d=rows(rows.role==role & rows.status=="ok" & startsWith(rows.id,"distribution"),:);
    if ~isempty(d), plotScatter(double(contains(d.id,'skew')),d.avg,d.method,'Verteilung (0 raumf?llend, 1 ungleichm??ig)','Mittlerer relativer Feldfehler',fullfile(plotDir,role+'_distribution.png')); end
end
summary=fullfile(out,'REPORT.md'); fid=fopen(summary,'w'); cleaner=onCleanup(@()fclose(fid));
fprintf(fid,'# Statischer Vier-Methoden-Vergleich\n\nTest-Freeze vor Auswertung gepr?ft. Details: run_results.csv und case_results.csv.\n\n');
fprintf(fid,'Erfolgreiche Lauf/Split-Auswertungen: %d; fehlgeschlagene: %d.\n\n',nnz(rows.status=="ok"),nnz(rows.status~="ok"));
fprintf(fid,'Gewichtete relative Fehler sind Fallgr??en; Wiederholungen sind keine zus?tzlichen unabh?ngigen F?lle. Interpolation und Extrapolation bleiben getrennt.\n\n');
final=summaries(summaries.role=="interpolation" & summaries.n==768 & summaries.failed==0,:);
if ~isempty(final)
    [~,i]=min(final.meanError); chosen=final(i,:);
    fprintf(fid,'Genauigkeitsorientierter Ausgangspunkt (Interpolation, N=768): %s; mittlerer relativer Fehler %.6g, mediane Fit-Zeit %.4g s und mediane Einzelfall-Vorhersage %.4g s. Diese Auswahl ist eine Beschreibung dieses begrenzten Vergleichs; Extrapolation, Streuung und Datenkosten in pipeline_summary.csv mitbeurteilen.\n\n', ...
        chosen.method,chosen.meanError,chosen.fitMedian,chosen.predictMedian);
end
fprintf(fid,'Die vollst?ndigen Modell- und Datenkosten, Suchhistorie und Fehlversuche sind in den zugeh?rigen Checkpoints und Tabellen dokumentiert. Analytische Balkenl?sungen sind keine exakte 3D-Feldreferenz.\n');
end
function plotScatter(x,y,method,xlabelText,ylabelText,filename)
f=figure('Visible','off'); hold on; kinds=unique(method);
for j=1:numel(kinds), mask=method==kinds(j); scatter(x(mask),y(mask),25,'filled','DisplayName',kinds(j)); end
xlabel(xlabelText); ylabel(ylabelText); legend('Location','best'); grid on; exportgraphics(f,filename); close(f);
end
