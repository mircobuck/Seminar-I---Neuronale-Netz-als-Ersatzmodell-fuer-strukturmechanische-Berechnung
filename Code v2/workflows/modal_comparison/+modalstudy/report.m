function report(out,cfg)
%report Tables and plots from sealed results only; no new fits or FEM solves.
assert(isfile(fullfile(out,'evaluation.complete')),'modalstudy:EvaluationRequired','Evaluate first.');
ref=modalstudy.artifact(fullfile(out,'evaluation','test_reference.mat'));
runs=modalstudy.artifact(fullfile(out,'run_plan.mat')); rows=table; cases=table; modes=table; diagnostics=table;
for k=1:numel(runs)
    r=runs(k); if r.role=="timing", continue; end
    q=modalstudy.artifact(fullfile(out,'evaluation',r.id,'observed.mat'));
    stats=surrogate.study.summarizeErrors(q.relative(:)); rank=NaN;
    if isfield(q.config,'rank'), rank=q.config.rank; end
    row=table(q.id,q.method,q.role,q.N,q.config.seed,rank,q.status,q.message, ...
        stats.mean,stats.median,stats.p95,stats.maximum,q.fitSeconds,q.loadSeconds,q.modelBytes, ...
        sum(q.nonpositive(:),'omitnan'),sum(q.orderViolation,'omitnan'), ...
        'VariableNames',{'RunId','Method','Role','N','Seed','Rank','Status','Message','MeanError', ...
        'MedianError','P95Error','MaxError','FitSeconds','LoadSeconds','ModelBytes','NonpositiveCount','OrderViolationCount'});
    rows=[rows;row]; %#ok<AGROW>
    [caseRow,mode]=ndgrid(1:numel(ref.caseIds),1:6); count=numel(mode);
    cases=[cases;table(repmat(q.id,count,1),ref.caseIds(caseRow(:)),mode(:), ...
        ref.frequencyHz(:),q.predictionHz(:),q.absoluteHz(:),q.relative(:), ...
        'VariableNames',{'RunId','CaseId','Mode','ReferenceHz','PredictionHz','AbsoluteErrorHz','RelativeError'})]; %#ok<AGROW>
    for j=1:6
        s=surrogate.study.summarizeErrors(q.relative(:,j));
        modes=[modes;table(q.id,j,s.mean,s.median,s.p95,s.maximum, ...
            'VariableNames',{'RunId','Mode','MeanError','MedianError','P95Error','MaxError'})]; %#ok<AGROW>
    end
    if startsWith(q.method,"pod_")
        diagnostics=[diagnostics;table(repmat(q.id,numel(ref.caseIds),1),ref.caseIds, ...
            q.projectionSquared,q.regressionSquared,q.reconstructionSquared,q.decompositionResidual, ...
            'VariableNames',{'RunId','CaseId','ProjectionSquaredHz','RegressionSquaredHz', ...
            'ReconstructionSquaredHz','DecompositionResidualHz'})]; %#ok<AGROW>
    end
end
writetable(rows,fullfile(out,'run_results.csv')); writetable(cases,fullfile(out,'case_results.csv'));
writetable(modes,fullfile(out,'mode_results.csv')); writetable(diagnostics,fullfile(out,'pod_diagnostics.csv'));
analytic=abs(ref.analyticHz-ref.frequencyHz)./ref.frequencyHz;
[caseRow,mode]=ndgrid(1:numel(ref.caseIds),1:6);
writetable(table(ref.caseIds(caseRow(:)),mode(:),ref.frequencyHz(:),ref.analyticHz(:), ...
    ref.analyticFamilies(:),analytic(:),'VariableNames',{'CaseId','Rank','FemHz','BendingTheoryHz','BendingFamily','RelativeError'}), ...
    fullfile(out,'analytical_comparison.csv'));
historicalComparison(out,cfg,ref);
search=table; attempts=table; timing=table;
for method=string(cfg.methods(:)')
    a=load(fullfile(out,'tuning',method,'search_summary.mat'),'info');
    sessions=readtable(fullfile(out,'tuning',method,'search_sessions.csv'));
    search=[search;table(method,a.info.attempted,a.info.candidates,sum(sessions.elapsed_seconds),a.info.winner, ...
        'VariableNames',{'Method','Attempted','Candidates','Seconds','Winner'})]; %#ok<AGROW>
end
files=dir(fullfile(out,'tuning','**','result.mat'));
for k=1:numel(files)
    a=load(fullfile(files(k).folder,files(k).name),'result'); r=a.result;
    attempts=[attempts;table(string(files(k).folder),r.method,r.status,r.fitSeconds,r.message, ...
        'VariableNames',{'Checkpoint','Method','Status','FitSeconds','Message'})]; %#ok<AGROW>
end
for k=find([runs.role]=="timing" | ([runs.method]=="pod_gpr" & [runs.role]=="main" & arrayfun(@(r)numel(r.ids)==max(cfg.training_sizes),runs)))
    a=load(fullfile(out,runs(k).id,'result.mat'),'result');
    timing=[timing;table(runs(k).id,a.result.status,a.result.fitSeconds, ...
        'VariableNames',{'RunId','Status','FitSeconds'})]; %#ok<AGROW>
end
writetable(search,fullfile(out,'search_costs.csv')); writetable(attempts,fullfile(out,'search_attempts.csv'));
writetable(timing,fullfile(out,'gpr_timing_repeats.csv'));
benchmarkFile=fullfile(out,'benchmark','results.mat');
hasBenchmark=isfile(benchmarkFile);
if hasBenchmark, benchmarkTables(out,modalstudy.artifact(benchmarkFile)); end
modalstudy.plots(out,cfg,rows,modes,cases,analytic);
text=["# Modalstudie: sechs Eigenfrequenzen"; ""; ...
    "MLP, RBF, POD-MLP und POD-GPR. Frequenzraenge 1 bis 6, keine Eigenformvorhersage."; ...
    "Bekannte Referenzfaelle: kein neuer unabhaengiger Abschlusstest und kein Extrapolationstest."; ...
    "Auswahl ausschliesslich auf Validierung; insbesondere bei 12 Validierungsfaellen sind Rangfolgen unsicher."; ...
    "POD-Basis und Normalisierung stammen ausschliesslich aus den Trainingsdaten."; ...
    "Fehler sind abs(Vorhersage-FEM)/FEM; alle sechs Frequenzraenge erhalten gleiches Gewicht."; ...
    "Wiederholungen sind keine zusaetzlichen unabhaengigen Testfaelle. Keine nachtraegliche Sortierung oder Begrenzung der Vorhersagen."; ...
    "Euler-Bernoulli beschreibt hier nur Biegung: Rangvergleich ist keine Modenidentifikation oder vollstaendige 3D-Referenz."; ...
    "Historische Praesentationsmodelle: Einzelmodell Seed 42 und Ensemble aus drei Netzen getrennt in historical_comparison.csv."; ...
    "POD-Fehlerzerlegung verwendet die quadrierte euklidische Hz-Norm, nicht den relativen Auswahlfehler."; ""; ...
    sprintf('Auswertungen: %d erfolgreich, %d fehlgeschlagen.',nnz(rows.Status=="ok"),nnz(rows.Status~="ok")); ...
    sprintf('Train/Val/Test: %d/%d/%d. Benchmark vorhanden: %d.',cfg.counts.train,cfg.counts.val,cfg.counts.test,hasBenchmark); ""; ...
    "Ergebnisse: run_results.csv, mode_results.csv, case_results.csv, pod_diagnostics.csv und figures/."; ...
    "Suchkosten und Fehlversuche: search_costs.csv, search_attempts.csv. GPR-Zeitwiederholungen: gpr_timing_repeats.csv."; ...
    "Benchmark: neue serielle FEM-Zeiten gegen predictModel inklusive Transformation und Rekonstruktion; getrennte Ladezeit."; ...
    "Break-even setzt vorhandene Trainingsdaten voraus; Offlinekosten = Hauptfit, optional Suche. Keine allgemeine Wirtschaftlichkeitsaussage."];
writelines(text,fullfile(out,'REPORT.md'));
writelines("Report completed from stored results only.",fullfile(out,'report.complete'));
end

function historicalComparison(out,cfg,ref)
old=readtable(cfg.paths.presentation_file,'TextType','string');
[found,idx]=ismember(old.id,ref.caseIds);
assert(all(found) && all(old.mode>=1 & old.mode<=6 & old.mode==fix(old.mode)) && ...
    height(old)==numel(ref.caseIds)*6 && size(unique([old.id old.mode],'rows'),1)==height(old), ...
    'modalstudy:History','Historical case/rank keys differ.');
expected=ref.frequencyHz(sub2ind(size(ref.frequencyHz),idx,old.mode));
tolerance=1e-10;
if cfg.reference_mode=="generate", tolerance=1e-5; end
assert(all(abs(expected-old.fem)<=tolerance*max(1,abs(expected))),'modalstudy:History','Historical FEM references differ.');
rows=table;
for column=["mlpSeed42","podMlpSeed42","mlpMean","podMlpMean"]
    kind="single_seed42"; if endsWith(column,"Mean"), kind="ensemble_seeds42_43_44"; end
    error=abs(old.(column)-expected)./expected;
    rows=[rows;table(repmat(column,height(old),1),repmat(kind,height(old),1),old.id,old.mode, ...
        expected,old.(column),error,'VariableNames', ...
        {'Model','Kind','CaseId','Mode','ReferenceHz','PredictionHz','RelativeError'})]; %#ok<AGROW>
end
writetable(rows,fullfile(out,'historical_comparison.csv'));
writetable(table(ref.caseIds,ref.historicalSeconds,'VariableNames',{'CaseId','HistoricalFemSeconds'}), ...
    fullfile(out,'historical_test_costs.csv'));
end

function benchmarkTables(out,b)
folder=fullfile(out,'benchmark'); count=numel(b.ids); summary=table; scenarios=table;
femCases=median(b.femTimes,2); femSingle=median(femCases); femBatch=sum(femCases);
for m=1:numel(b.methods)
    one=median(b.single(:,:,m),2); singleMedian=median(one); batchMedian=median(b.batch(:,m));
    summary=[summary;table(b.methods(m),femSingle,iqr(femCases),singleMedian,iqr(one), ...
        femBatch,batchMedian,iqr(b.batch(:,m)),b.loadSeconds(m),'VariableNames', ...
        {'Method','FemSingleSeconds','FemBetweenCaseIqr','SingleSeconds','SingleBetweenCaseIqr', ...
        'FemBatchSeconds','BatchSeconds','BatchIqr','LoadSeconds'})]; %#ok<AGROW>
    for includeSearch=[false,true]
        offline=b.fitSeconds(m)+includeSearch*b.searchSeconds(m);
        singleCases=NaN; batchCases=NaN;
        if femSingle>singleMedian, singleCases=ceil(offline/(femSingle-singleMedian)); end
        if femBatch>batchMedian, batchCases=count*ceil(offline/(femBatch-batchMedian)); end
        scenarios=[scenarios;table(b.methods(m),includeSearch,offline,singleCases,batchCases, ...
            'VariableNames',{'Method','IncludeSearch','OfflineSeconds','SingleCases','BatchCases'})]; %#ok<AGROW>
    end
end
writetable(summary,fullfile(folder,'summary.csv')); writetable(scenarios,fullfile(folder,'break_even.csv'));
[i,j]=ndgrid(1:count,1:size(b.femTimes,2));
writetable(table(b.ids(i(:)),j(:),b.femTimes(:),'VariableNames',{'CaseId','Repeat','Seconds'}),fullfile(folder,'fem_raw.csv'));
[i,j,m]=ndgrid(1:count,1:size(b.single,2),1:numel(b.methods)); method=b.methods(m(:));
writetable(table(method(:),b.ids(i(:)),j(:),b.single(:),'VariableNames',{'Method','CaseId','Repeat','Seconds'}),fullfile(folder,'surrogate_raw.csv'));
writetable(array2table(b.batch,'VariableNames',cellstr(b.methods)),fullfile(folder,'batch_raw.csv'));
end
