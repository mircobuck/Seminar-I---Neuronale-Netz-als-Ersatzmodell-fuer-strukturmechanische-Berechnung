function benchmark(root,out,cfg)
    %benchmark Repeat the predeclared serial FEM/public-prediction timing experiment.
    folder=fullfile(out,'benchmark');
    if ~isfolder(folder)
        mkdir(folder);
    end
    complete=fullfile(folder,'benchmark_results.mat');
    if isfile(complete)
        assert(strcmp(staticstudy.hash(complete),strtrim(fileread(complete+".sha256"))), ...
            'study:BenchmarkChanged',  'Benchmark result changed.');
        return
    end
    priorPath=path;
    cleanup=onCleanup(@()path(priorPath));
    addpath(fullfile(root,'fem_core'),fullfile(root,'fem_core','src'));
    data=staticstudy.loadReference(out,"interpolation");
    indices=cfg.benchmark_indices;
    X=data.inputParameters(indices,:);
    ids=data.caseIds(indices);
    count=numel(ids);
    methods=string(cfg.methods(:)');
    caseTable=array2table([double(ids(:)),X],  'VariableNames',  [{'id'},cellstr(data.parameterNames)]);
    writetable(caseTable,fullfile(folder,'benchmark_cases.csv'));
    femConfig=config('smoke');
    femConfig.meshDivisor=cfg.mesh_divisor;
    femConfig.geometricOrder=string(cfg.geometric_order);
    femConfig.saveRawMesh=false;
    femConfig.maxDeflectionRatio=cfg.max_deflection_ratio;
    meta=struct('matlab',version,'startedUTC',string(datetime('now','TimeZone','UTC')),  'indices',  indices, ...
        'ids',  ids,  'femConfig',  femConfig,  'warmup',  1,  'femRepeats',  cfg.benchmark_fem_repetitions,  'surrogateRepeats',  cfg.benchmark_surrogate_repetitions);
    save(fullfile(folder,'benchmark_meta.mat'),'meta');
    warm=solve_case(X(1,:),femConfig);
    assert(numel(warm.S)==1575,'study:FieldSize','FEM did not return a complete displacement field.');
    femTimes=nan(count,cfg.benchmark_fem_repetitions);
    femInternal=femTimes;
    partial=fullfile(folder,'fem_partial.mat');
    if isfile(partial)
        previous=load(partial);
        assert(isequal(previous.ids,ids),'study:CheckpointChanged','Benchmark cases changed.');
        femTimes=previous.femTimes;
        femInternal=previous.femInternal;
    end
    for repeat=1:cfg.benchmark_fem_repetitions
        order=1:count;
        if mod(repeat,2)==0
            order=fliplr(order);
        end
        for j=order
            if isfinite(femTimes(j,repeat))
                continue;
            end
            timer=tic;
            value=solve_case(X(j,:),femConfig);
            femTimes(j,repeat)=toc(timer);
            femInternal(j,repeat)=value.seconds;
            save(partial,'femTimes','femInternal','ids');
            fprintf('Benchmark FEM %d repeat %d: %.3f s\n',ids(j),repeat,femTimes(j,repeat));
        end
    end
    repetitions=cfg.benchmark_surrogate_repetitions;
    single=nan(count,repetitions,numel(methods));
    batch=nan(repetitions,numel(methods));
    loadTimes=nan(numel(methods),1);
    for m=1:numel(methods)
        file=fullfile(out,'runs',sprintf('n%03d_rep1_%s_seed%d',max(cfg.training_sizes),methods(m), ...
            cfg.seed_tuning),'model.mat');
        timer=tic;
        model=surrogate.loadModel(file);
        loadTimes(m)=toc(timer);
        request=struct('inputParameters',X,'parameterNames',data.parameterNames,  'parameterUnits', ...
            data.parameterUnits,  'caseIds',  ids);
        one=request;
        one.inputParameters=X(1,:);
        one.caseIds=ids(1);
        surrogate.predictModel(model,one);
        surrogate.predictModel(model,request);
        for repeat=1:repetitions
            for j=1:count
                one.inputParameters=X(j,:);
                one.caseIds=ids(j);
                timer=tic;
                surrogate.predictModel(model,one);
                single(j,repeat,m)=toc(timer);
            end
            timer=tic;
            surrogate.predictModel(model,request);
            batch(repeat,m)=toc(timer);
        end
        save(fullfile(folder,'surrogate_partial.mat'),'single','batch','loadTimes','methods','ids');
    end
    save(complete,'meta','femTimes','femInternal','single','batch','loadTimes','methods','ids');
    writelines(string(staticstudy.hash(complete)),complete+".sha256");
    writeTables(folder,out,cfg,femTimes,femInternal,single,batch,loadTimes,ids,methods);
    writelines("complete",fullfile(folder,'benchmark.complete'));
end

function writeTables(folder,out,cfg,femTimes,femInternal,single,batch,loadTimes,ids,methods)
    % Keep within-case timing repetitions separate from between-case variation.
    count=numel(ids);
    [caseRow,repeat]=ndgrid(1:count,1:size(femTimes,2));
    raw=table(ids(caseRow(:)),repeat(:),femTimes(:),femInternal(:),  'VariableNames',  {'CaseId','Repeat', ...
        'PublicSeconds','InternalSolverSeconds'});
    writetable(raw,fullfile(folder,'fem_raw.csv'));
    summary=table;
    surrogateRaw=table;
    scenarios=table;
    femCaseMedian=median(femTimes,2);
    femSingle=median(femCaseMedian);
    femBatch=sum(femCaseMedian);
    for m=1:numel(methods)
        method=methods(m);
        caseMedians=median(single(:,:,m),2);
        singleMedian=median(caseMedians);
        singleBetweenCaseIqr=iqr(caseMedians);
        batchMedian=median(batch(:,m));
        batchIqr=iqr(batch(:,m));
        loadSeconds=loadTimes(m);
        femBetweenCaseIqr=iqr(femCaseMedian);
        summary=[summary;table(method,femSingle,femBetweenCaseIqr,femBatch,singleMedian,  singleBetweenCaseIqr, ... %#ok<AGROW>
            batchMedian,  batchIqr,  loadSeconds)];
        [caseRow,repeat]=ndgrid(1:count,1:size(single,2));
        times=single(:,:,m);
        surrogateRaw=[surrogateRaw;table(repmat(method,numel(times),1),ids(caseRow(:)),repeat(:),times(:), ... %#ok<AGROW>
            'VariableNames',  {'Method','CaseId','Repeat','Seconds'})];
        fitFile=fullfile(out,'runs',sprintf('n%03d_rep1_%s_seed%d',max(cfg.training_sizes),method, ...
            cfg.seed_tuning),'result.mat');
        a=load(fitFile,'result');
        fitSeconds=a.result.fitSeconds;
        sessions=readtable(fullfile(out,'tuning',method,'search_sessions.csv'));
        searchSeconds=sum(sessions.elapsed_seconds);
        for includeSearch=[false,true]
            offlineSeconds=fitSeconds+includeSearch*searchSeconds;
            singleCases=breakEven(offlineSeconds,femSingle-singleMedian);
            batchCases=count*breakEven(offlineSeconds,femBatch-batchMedian);
            scenarios=[scenarios;table(method,includeSearch,offlineSeconds,singleCases,batchCases)]; %#ok<AGROW>
        end
    end
    writetable(summary,fullfile(folder,'summary.csv'));
    writetable(surrogateRaw,fullfile(folder,'surrogate_raw.csv'));
    writetable(array2table(batch,'VariableNames',cellstr(methods)),fullfile(folder,'batch_raw.csv'));
    writetable(scenarios,fullfile(folder,'break_even.csv'));
    writelines(["# Bedingter FEM-/Surrogatbenchmark"; "";  "Neue serielle Messungen, ein Warm-up, vorab konfigurierte Fallpositionen und Wiederholungen.";  "FEM: vollstaendiger solve_case inklusive Netz, Loesung, Interpolation und Spitzenpruefung.";  "Surrogat: oeffentliches predictModel inklusive Transformation und POD-Rekonstruktion.";  "Einzelfall: Median der fallweisen Mediane. Batch-FEM: Summe der fallweisen Mediane.";  "Break-even: ceil(Offlinekosten/(FEMzeit-Surrogatzeit)); nur positiver Nenner.";  "Offlinekosten sind neue Fit-Zeit des Hauptmodells, optional neue aeussere Familiensuche.";  "Vorhandene Referenzdaten werden als verfuegbar angenommen; historische Erzeugungskosten sind separat.";  "Laden/Speichern, Qualitaetssicherung, Wiederholungsstudien und kuenftige Updates sind nicht in diesen Szenarien enthalten.";  "Keine allgemeine Wirtschaftlichkeit oder Genauigkeitsgarantie; keine neue Modellauswahl."],  fullfile(folder,'BENCHMARK.md'));
end

function count=breakEven(cost,saving)
    count=NaN;
    if saving>0
        count=ceil(cost/saving);
    end
end
