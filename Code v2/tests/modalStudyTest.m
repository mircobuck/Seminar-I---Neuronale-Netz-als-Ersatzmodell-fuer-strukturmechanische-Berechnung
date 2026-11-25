classdef modalStudyTest < matlab.unittest.TestCase
    properties
        Root
        Config
        Out
        LocalFile
    end
    methods (TestClassSetup)
        function setupPaths(t)
            t.Root=fileparts(fileparts(mfilename('fullpath')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(t.Root));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(t.Root,'tests')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(t.Root,'workflows','modal_comparison')));
        end
    end
    methods (TestMethodSetup)
        function fixture(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [t.Config,t.Out,t.LocalFile]=makeModalStudyFixture(folder.Folder,t.Root);
        end
    end
    methods (Test)
        function helpDoesNotChangePath(t)
            before=path; runModalStudy;
            t.verifyEqual(path,before);
        end
        function syntheticDatasetRoundTrip(t)
            actual=modalstudy.reference(t.Out,"train","train"); expected=makeModalData("train",16);
            t.verifyEqual(actual.frequencyHz,expected.frequencyHz,AbsTol=0);
            t.verifyEqual(actual.inputParameters,expected.inputParameters,AbsTol=0);
            t.verifyFalse(isfield(actual,'displacementFields'));
        end
        function designMismatchRejected(t)
            a=load(t.Config.paths.training_file,'D'); D=a.D; D.X(1,1)=D.X(1,1)+.01;
            save(t.Config.paths.training_file,'D');
            t.verifyError(@()surrogate.loadDataset(t.Config.paths.training_file),'surrogate:data:Design');
        end
        function nestedSelectionIsReproducible(t)
            data=makeModalData("train",16); first=modalstudy.subsets(data,t.Config);
            second=modalstudy.subsets(data,t.Config);
            t.verifyEqual(first,second);
            t.verifyTrue(all(ismember(first{1,1},first{2,1})));
            t.verifyEqual(first{2,1},data.caseIds);
        end
        function testLabelsBlockedUntilFreeze(t)
            t.verifyError(@()modalstudy.reference(t.Out,"tune","test"),'study:TestLabelGate');
            t.verifyError(@()modalstudy.reference(t.Out,"evaluate","test"),'study:FreezeRequired');
        end
        function initAndGenerateResume(t)
            before=modalstudy.artifact(fullfile(t.Out,'references.mat'));
            runModalStudy("init",t.Config.config_file,t.LocalFile);
            runModalStudy("generate",t.Config.config_file,t.LocalFile);
            t.verifyEqual(modalstudy.artifact(fullfile(t.Out,'references.mat')),before);
        end
        function sourceChangesRejected(t)
            writelines("changed",t.Config.paths.presentation_file);
            t.verifyError(@()modalstudy.verify(t.Root,t.Out,t.Config),'modalstudy:SourceChanged');
        end
        function sealedArtifactCannotBeReplaced(t)
            f=fullfile(t.Out,'small.mat'); modalstudy.artifact(f,1);
            t.verifyError(@()modalstudy.artifact(f,2),'modalstudy:ArtifactChanged');
        end
        function frozenTrainingAndTamperingBlocked(t)
            completeModalFixture(t.Out,t.Config);
            t.verifyError(@()runModalStudy("train",t.Config.config_file,t.LocalFile),'study:AlreadyFrozen');
            writelines("changed",fullfile(t.Out,'training.complete'));
            t.verifyError(@()modalstudy.reference(t.Out,"evaluate","test"),'study:FreezeChanged');
        end
        function reportFromMockResultsCanRepeat(t)
            completeModalFixture(t.Out,t.Config);
            before=modalstudy.checkFrozen(t.Out);
            runModalStudy("report",t.Config.config_file,t.LocalFile);
            runModalStudy("report",t.Config.config_file,t.LocalFile);
            t.verifyEqual(modalstudy.checkFrozen(t.Out),before);
            rows=readtable(fullfile(t.Out,'run_results.csv'),'TextType','string');
            t.verifyTrue(all(rows.Status=="ok"));
            t.verifyEqual(sort(unique(rows.Method)),sort(t.Config.methods(:)));
            t.verifyEqual(height(readtable(fullfile(t.Out,'historical_comparison.csv'))),96);
            info=imfinfo(fullfile(t.Out,'figures','learning_curve.png'));
            t.verifyGreaterThan(info.Width,100);
        end
        function evaluationRecordsFailuresWithoutRefitting(t)
            completeModalFixture(t.Out,t.Config,false);
            runModalStudy("evaluate",t.Config.config_file,t.LocalFile);
            runs=modalstudy.artifact(fullfile(t.Out,'run_plan.mat'));
            q=modalstudy.artifact(fullfile(t.Out,'evaluation',runs(1).id,'observed.mat'));
            t.verifyEqual(q.status,"failed");
            t.verifyTrue(all(isnan(q.relative),'all'));
            before=modalstudy.manifest(string(fullfile(t.Out,'evaluation',runs(1).id,'observed.mat')));
            runModalStudy("evaluate",t.Config.config_file,t.LocalFile);
            t.verifyEqual(modalstudy.manifest(before.Path),before);
        end
        function plannedCountsMatch(t)
            cfg=modalstudy.configure(t.Root,"workflows/modal_comparison/configs/study.json", ...
                "workflows/modal_comparison/configs/local.example.json");
            selections=modalStudyTest.firstCandidates(cfg);
            runs=modalstudy.runPlan(makeModalData("train",384),cfg,selections);
            t.verifyEqual(numel(runs),72);
            t.verifyEqual(nnz([runs.role]=="main"),58);
            t.verifyEqual(nnz([runs.role]=="rank"),12);
            t.verifyEqual(nnz([runs.role]=="timing"),2);
        end
        function searchAndTrainingUseOnlyProvidedSplits(t)
            train=modalstudy.reference(t.Out,"tune","train"); val=modalstudy.reference(t.Out,"tune","val");
            cfg=t.Config; cfg.search.mlp=struct('hiddenWidth',{3,4},'hiddenLayers',{1,1});
            surrogate.study.selectConfigurations(t.Out,cfg,train,val,@modalStudyTest.mockFit);
            saved=load(fullfile(t.Out,'selections.mat'),'selections');
            t.verifyEqual(saved.selections.mlp.hiddenWidth,3);
            modalstudy.training(t.Out,cfg,@modalStudyTest.mockFit);
            t.verifyTrue(isfile(fullfile(t.Out,'training.complete')));
            files=dir(fullfile(t.Out,'**','mock_call.mat'));
            t.verifyGreaterThanOrEqual(numel(files),10);
        end
    end
    methods (Static)
        function selections=firstCandidates(cfg)
            selections=struct;
            for method=cfg.methods
                candidates=surrogate.study.candidates(method,cfg); selections.(method)=candidates{1};
            end
        end
        function result=mockFit(folder,method,train,val,c)
            assert(train.split=="train" && val.split=="val",'test:Split','No test data may enter a fit.');
            if ~isfolder(folder), mkdir(folder); end
            value=struct('method',method,'trainingIds',train.caseIds,'validationIds',val.caseIds,'config',c);
            save(fullfile(folder,'mock_call.mat'),'value');
            score=1;
            if method=="mlp", score=c.hiddenWidth; end
            result=struct('status',"ok",'meanError',score,'p95Error',score);
        end
    end
end
