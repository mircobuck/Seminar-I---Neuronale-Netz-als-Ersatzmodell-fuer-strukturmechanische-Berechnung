function evaluation(~,out,cfg)
    % Test references are inaccessible here until the complete freeze is checked.
    % interpolation and extrapolation data are loaded and saved in struct
    refs=struct('interpolation',staticstudy.loadReference(out,"interpolation"),  'extrapolation', ...
        staticstudy.loadReference(out,"extrapolation"));

    freezeManifest=readtable(fullfile(out,'freeze_manifest.csv'),'TextType','string',  'Delimiter',  ',', ...
        'ReadVariableNames',  true,  'VariableNamingRule',  'preserve');
    % empty list   
    paths=strings(0,1);
    % go through freeze manifst
    for j=1:height(freezeManifest)
        % every row of manifest
        candidate=freezeManifest.Path(j);
        % extract folder, name and extension
        [folder,name,extension]=fileparts(candidate);
        if ~(name=="result" && extension==".mat")
            continue;
        end
        % extract some foldernames
        [parent,leaf]=fileparts(folder);
        [~,branch]=fileparts(parent);
        % if eligible, add to list of paths
        eligible=(any(string(branch)==["runs","controlled"]) && startsWith(string(leaf), ...
            "n")) ||  (string(branch)=="distribution" && any(startsWith(string(leaf),["space_","skew_"])));
        if eligible
            paths(end+1)=candidate; %#ok<AGROW>
        end
    end
    % paths is now a list of all result.mat files in the freeze manifest that are eligible for evaluation
    assert(~isempty(paths),'study:NoModels','No trained models found.');
    % randomize the order of evaluation to avoid bias from the order of the freeze manifest due to temperature of the processor
    prior=rng;
    cleanup=onCleanup(@()rng(prior));
    rng(cfg.seed_evaluation,'twister');
    paths=paths(randperm(numel(paths)));
    % iterate over all eliglible results
    for k=1:numel(paths)
        % take current path
        checkpoint=char(paths(k));
        % load varibal reuslt from this mat file
        a=load(checkpoint,'result');
        % saved in fit
        fit=a.result;
        % path to model file
        modelFile=fullfile(fileparts(checkpoint),'model.mat');
        % check if model file is in freezemode
        if fit.status=="ok"
            assert(any(freezeManifest.Path==string(modelFile)),'study:FreezeInvalid','Model absent from freeze.');
        end
        % relative path to result folder
        relative=extractAfter(string(fileparts(checkpoint)),strlength(string(out))+1);
        % folder for solutions
        resultFolder=fullfile(out,'evaluation',relative);
        % create folder if not existing
        if ~isfolder(resultFolder)
            mkdir(resultFolder);
        end
        % iterate over interpolation and extrapolation
        for role=["interpolation","extrapolation"]
            % name for the mat file and the hash file
            filename=fullfile(resultFolder,role+'.mat');
            hashFile=filename+'.sha256';
            % if the result file exists but the hash file does not, rename the result file to indicate it is incomplete
            if isfile(filename) && ~isfile(hashFile)
                movefile(filename,filename+'.incomplete');
            end
            % check  result file with hash file
            if isfile(filename)
                assert(strcmp(staticstudy.hash(filename),strtrim(fileread(hashFile))), ...
                    'study:EvaluationChanged',  'Evaluation checkpoint changed.');
                continue
            end

            staticstudy.requireBudget(out,30);
            staticstudy.requireSpace(out);
            % refs.interpolation and refs.extrapolation 
            data=refs.(role);
            % number of cases
            n=numel(data.caseIds);
            % struct for evaluation
            observed=struct('method',fit.method,'role',role,'status',fit.status,  'message',  fit.message, ...
                'fitSeconds',  fit.fitSeconds,  'report',  fit.report,  'trainingIds',  fit.trainingIds,  'config',  fit.config,  'caseIds',  data.caseIds,  'absolute',  nan(n,1),  'referenceNorm',  nan(n,1),  'relative',  nan(n,1),  'tipError',  nan(n,1),  'maxMagnitudeError',  nan(n,1),  'projectionSquared',  nan(n,1),  'regressionSquared',  nan(n,1),  'reconstructionSquared',  nan(n,1),  'decompositionResidual',  nan(n,1),  'decompositionValid',  nan(n,1),  'singleTimes',  [],  'batchTimes',  [],  'loadSeconds',  NaN,  'saveSeconds',  fit.saveSeconds,  'modelBytes',  NaN,  'femTip',  nan(n,1),  'eulerBernoulliTip',  nan(n,1),  'timoshenkoTip',  nan(n,1));
            % acutal evaluation starts here
            if fit.status=="ok"
                try     
                    % timer 
                    started=tic;
                    % load model
                    model=surrogate.loadModel(modelFile);
                    % loading time
                    observed.loadSeconds=toc(started);

                    fileInfo=dir(modelFile);
                    % model file size in bytes
                    observed.modelBytes=fileInfo.bytes;
                    % evaluate the model with the data and the observed struct
                    [observed,request]=staticstudy.observeModel(model,data,observed,fit.method,cfg);
                    if role=="interpolation"
                        [observed.singleTimes,observed.batchTimes]=staticstudy.timePrediction(model,request,cfg);
                    end
                catch err
                    observed.status="failed";
                    observed.message=string(err.identifier)+": "+string(err.message);
                end
            end
            % save everything to a temporary file and then move it to the final destination to avoid partial writes
            temporary=[tempname(resultFolder),'.mat'];
            save(temporary,'observed','-v7.3');
            [ok,msg]=movefile(temporary,filename);
            assert(ok,'study:EvaluationWrite','%s',msg);
            writelines(string(staticstudy.hash(filename)),filename+'.sha256');
        end
    end
    writelines("test evaluation completed",fullfile(out,'evaluation.complete'));
end
