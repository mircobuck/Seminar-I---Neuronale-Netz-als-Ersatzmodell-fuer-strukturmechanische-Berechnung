classdef staticWorkflowTest < matlab.unittest.TestCase
    properties
        Root
        Config
    end
    properties (TestParameter)
        Method = {"mlp","rbf","pod_mlp","pod_gpr"}
    end
    methods (TestClassSetup)
        function configurePaths(t)
            t.Root=fileparts(fileparts(mfilename('fullpath')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(t.Root));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(t.Root,'workflows','static_comparison')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(t.Root,'tests')));
            t.Config=staticstudy.configure(t.Root,"workflows/static_comparison/configs/study.json", ...
                "workflows/static_comparison/configs/local.example.json");
        end
    end
    methods (Test)
        function harmlessEntryPreservesPath(t)
            before=path;
            runStaticStudy;
            t.verifyEqual(path,before);
        end
        function nearestRankAndUndefined(t)
            actual=surrogate.study.summarizeErrors([1:20 NaN]);
            t.verifyEqual([actual.mean actual.median actual.p95 actual.maximum],[10.5 10.5 19 20]);
            t.verifyEqual(actual.undefinedCount,1);
        end
        function allUndefined(t)
            actual=surrogate.study.summarizeErrors([NaN NaN]);
            t.verifyTrue(all(isnan([actual.mean actual.median actual.p95 actual.maximum])));
            t.verifyEqual(actual.undefinedCount,2);
        end
        function rejectsInvalidMetric(t)
            t.verifyError(@()surrogate.study.summarizeErrors([1 Inf]),'surrogate:study:InvalidErrors');
        end
        function tuningCannotReadTest(t)
            t.verifyError(@()staticstudy.reference(tempname,"tune","interpolation"),'study:TestLabelGate');
        end
        function evaluationNeedsFreeze(t)
            t.verifyError(@()staticstudy.reference(tempname,"evaluate","interpolation"),'study:FreezeRequired');
        end
        function candidateOrderUnchanged(t,Method)
            saved=load(fullfile(t.Root,'tests','fixtures','study_baseline.mat'),'baseline');
            expected=cellfun(@orderfields,saved.baseline.candidates.(Method),'UniformOutput',false);
            actual=cellfun(@orderfields,staticstudy.candidates(Method,t.Config),'UniformOutput',false);
            t.verifyEqual(actual(:),expected(:));
        end
        function storedPredictionsAndErrorsUnchanged(t,Method)
            paths=jsondecode(fileread(fullfile(t.Root,'tests','fixtures','regression.json')));
            saved=load(fullfile(t.Root,paths.predictions_file),'baseline');
            data=surrogate.loadDataset(fullfile(t.Config.paths.reference_run,'references','val','val.mat'));
            model=surrogate.loadModel(fullfile(t.Config.paths.reference_run,'runs',sprintf('n768_rep1_%s_seed42',Method),'model.mat'));
            request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
            prediction=surrogate.predictModel(model,request);
            metrics=surrogate.evaluatePrediction(prediction,data,struct('staticReferenceFloor',0));
            t.verifyEqual(prediction,saved.baseline.(Method).prediction);
            t.verifyEqual(rmfield(metrics,'metricConfig'),rmfield(saved.baseline.(Method).metrics,'metricConfig'),AbsTol=0);
            errors=metrics.relativeWeightedFieldError;
            sorted=sort(errors);
            actual=surrogate.study.summarizeErrors(errors);
            t.verifyEqual([actual.mean actual.median actual.p95 actual.maximum], ...
                [mean(errors) median(errors) sorted(ceil(.95*numel(errors))) max(errors)]);
        end
        function blockSelectionsUnchanged(t)
            data=surrogate.loadDataset(t.Config.paths.training_file);
            block=staticstudy.trainingBlocks(data,t.Config);
            saved=load(fullfile(t.Root,'tests','fixtures','study_baseline.mat'),'baseline');
            current=surrogate.study.nestedTrainingSubsets(data.caseIds,block, ...
                t.Config.training_sizes,t.Config.seeds_selection);
            t.verifyEqual(current,saved.baseline.subsets);
        end
        function resumeChecksConfigAndFingerprint(t)
            folder=tempname;
            mkdir(folder);
            t.addTeardown(@()rmdir(folder,'s'));
            metadata=struct('startedPosix',posixtime(datetime('now','TimeZone','UTC')), ...
                'budgetSeconds',Inf,'pilotSpentSeconds',0);
            save(fullfile(folder,'environment.mat'),'metadata');
            train=makeContractData("train");
            val=makeContractData("val");
            config=struct('seed',42,'datasetId',"test",'hiddenWidth',2,'maxEpochs',1,'miniBatchSize',2);
            target=fullfile(folder,'fit');
            first=staticstudy.fitCheckpoint(target,"mlp",train,val,config);
            second=staticstudy.fitCheckpoint(target,"mlp",train,val,config);
            t.verifyEqual(first,second);
            changed=config;
            changed.seed=43;
            t.verifyError(@()staticstudy.fitCheckpoint(target,"mlp",train,val,changed),'study:CheckpointChanged');
            train.displacementFields(1,1)=train.displacementFields(1,1)+1;
            t.verifyError(@()staticstudy.fitCheckpoint(target,"mlp",train,val,config),'study:CheckpointChanged');
        end
    end
end
