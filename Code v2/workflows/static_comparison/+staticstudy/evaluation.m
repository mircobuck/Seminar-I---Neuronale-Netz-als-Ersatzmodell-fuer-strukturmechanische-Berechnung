function evaluation(~,out,cfg)
    % Test references are inaccessible here until the complete freeze is checked.

    refs=struct('interpolation',staticstudy.loadReference(out,"interpolation"),  'extrapolation', ...
        staticstudy.loadReference(out,"extrapolation"));
    freezeManifest=readtable(fullfile(out,'freeze_manifest.csv'),'TextType','string',  'Delimiter',  ',', ...
        'ReadVariableNames',  true,  'VariableNamingRule',  'preserve');
    paths=strings(0,1);
    for j=1:height(freezeManifest)
        candidate=freezeManifest.Path(j);
        [folder,name,extension]=fileparts(candidate);
        if ~(name=="result" && extension==".mat")
            continue;
        end
        [parent,leaf]=fileparts(folder);
        [~,branch]=fileparts(parent);
        eligible=(any(string(branch)==["runs","controlled"]) && startsWith(string(leaf), ...
            "n")) ||  (string(branch)=="distribution" && any(startsWith(string(leaf),["space_","skew_"])));
        if eligible
            paths(end+1)=candidate; %#ok<AGROW>
        end
    end
    assert(~isempty(paths),'study:NoModels','No trained models found.');
    prior=rng;
    cleanup=onCleanup(@()rng(prior));
    rng(cfg.seed_evaluation,'twister');
    paths=paths(randperm(numel(paths)));
    for k=1:numel(paths)
        checkpoint=char(paths(k));
        a=load(checkpoint,'result');
        fit=a.result;
        modelFile=fullfile(fileparts(checkpoint),'model.mat');
        if fit.status=="ok"
            assert(any(freezeManifest.Path==string(modelFile)),'study:FreezeInvalid','Model absent from freeze.');
        end
        relative=extractAfter(string(fileparts(checkpoint)),strlength(string(out))+1);
        resultFolder=fullfile(out,'evaluation',relative);
        if ~isfolder(resultFolder)
            mkdir(resultFolder);
        end
        for role=["interpolation","extrapolation"]
            filename=fullfile(resultFolder,role+'.mat');
            hashFile=filename+'.sha256';
            if isfile(filename) && ~isfile(hashFile)
                movefile(filename,filename+'.incomplete');
            end
            if isfile(filename)
                assert(strcmp(staticstudy.hash(filename),strtrim(fileread(hashFile))), ...
                    'study:EvaluationChanged',  'Evaluation checkpoint changed.');
                continue
            end
            staticstudy.requireBudget(out,30);
            staticstudy.requireSpace(out);
            data=refs.(role);
            n=numel(data.caseIds);
            observed=struct('method',fit.method,'role',role,'status',fit.status,  'message',  fit.message, ...
                'fitSeconds',  fit.fitSeconds,  'report',  fit.report,  'trainingIds',  fit.trainingIds,  'config',  fit.config,  'caseIds',  data.caseIds,  'absolute',  nan(n,1),  'referenceNorm',  nan(n,1),  'relative',  nan(n,1),  'tipError',  nan(n,1),  'maxMagnitudeError',  nan(n,1),  'projectionSquared',  nan(n,1),  'regressionSquared',  nan(n,1),  'reconstructionSquared',  nan(n,1),  'decompositionResidual',  nan(n,1),  'decompositionValid',  nan(n,1),  'singleTimes',  [],  'batchTimes',  [],  'loadSeconds',  NaN,  'saveSeconds',  fit.saveSeconds,  'modelBytes',  NaN,  'femTip',  nan(n,1),  'eulerBernoulliTip',  nan(n,1),  'timoshenkoTip',  nan(n,1));
            if fit.status=="ok"
                try
                    started=tic;
                    model=surrogate.loadModel(modelFile);
                    observed.loadSeconds=toc(started);
                    fileInfo=dir(modelFile);
                    observed.modelBytes=fileInfo.bytes;
                    [observed,request]=staticstudy.observeModel(model,data,observed,fit.method,cfg);
                    if role=="interpolation"
                        [observed.singleTimes,observed.batchTimes]=staticstudy.timePrediction(model,request,cfg);
                    end
                catch err
                    observed.status="failed";
                    observed.message=string(err.identifier)+": "+string(err.message);
                end
            end
            temporary=[tempname(resultFolder),'.mat'];
            save(temporary,'observed','-v7.3');
            [ok,msg]=movefile(temporary,filename);
            assert(ok,'study:EvaluationWrite','%s',msg);
            writelines(string(staticstudy.hash(filename)),filename+'.sha256');
        end
    end
    writelines("test evaluation completed",fullfile(out,'evaluation.complete'));
end
