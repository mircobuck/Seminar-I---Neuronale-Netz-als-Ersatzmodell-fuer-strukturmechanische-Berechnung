classdef staticFinalEvaluationTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            testDir=fileparts(mfilename('fullpath')); root=fileparts(testDir);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(testDir));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(root,'studies','static_final_evaluation')));
        end
    end
    methods (Test)
        function syntheticModelsAndFailure(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,out]=staticFinalEvaluationTest.setupStudy(fixture.Folder,false);
            config.models(2)=config.models(1); config.models(2).label="DUMMY_SEED_2";
            config.models(3)=struct('label',"MISSING",'file',fullfile(fixture.Folder,'missing.mat'));
            invalidPath=fullfile(fixture.Folder,'invalid.mat');
            model=struct('notModel',true); save(invalidPath,'model');
            config.models(4)=struct('label',"INVALID",'file',invalidPath);
            result=runStaticFinalEvaluation(config,out);
            testCase.verifyEqual(result.summary.Status, ...
                ["complete";"complete";"failed";"failed"]);
            expectedAbsolute=sqrt(3)*[.500001;.499998;2.499997];
            testCase.verifyEqual(result.summary.AbsoluteMeanM(1),mean(expectedAbsolute),AbsTol=1e-10);
            testCase.verifyEqual(result.summary.AbsoluteMedianM(1),expectedAbsolute(1),AbsTol=1e-10);
            testCase.verifyEqual(result.summary.AbsoluteP95M(1),expectedAbsolute(3),AbsTol=1e-10);
            testCase.verifyEqual(result.summary.AbsoluteMaxM(1),expectedAbsolute(3),AbsTol=1e-10);
            testCase.verifyEqual(result.summary.RelativeMedian(1),.500001,AbsTol=1e-10);
            testCase.verifyEqual(result.summary.RelativeP95(1),.62499925,AbsTol=1e-10);
            testCase.verifyEqual(result.cases.AbsoluteErrorM(1:3),expectedAbsolute,AbsTol=1e-10);
            testCase.verifyEqual(result.cases.ReferenceNormM(1:3),sqrt(3)*[1;2;4],AbsTol=1e-10);
            testCase.verifyEqual(result.cases.CaseId,[201;202;203;201;202;203]);
            testCase.verifyEqual(result.cases.RelativeError(1:3), ...
                [.500001;.249999;.62499925],AbsTol=1e-10);
            testCase.verifyEqual(result.cases.CaseId(1:3),result.cases.CaseId(4:6));
            testCase.verifyNotEmpty(result.details(3).errorMessage);
            testCase.verifyNotEmpty(result.details(4).errorMessage);
            for name={'study_config.mat','results.mat','case_errors.csv', ...
                    'summary.csv','run_status.csv'}
                testCase.verifyTrue(isfile(fullfile(out,name{1})));
            end
            status=readtable(fullfile(out,'run_status.csv'),'TextType','string', ...
                'VariableNamingRule','preserve','Delimiter',',');
            testCase.verifyEqual(status.Properties.VariableNames, ...
                {'Model','Status','ErrorId','ErrorMessage'});
            testCase.verifyEqual(status.Status,["complete";"complete";"failed";"failed"]);
            testCase.verifyTrue(all(strlength(status.ErrorMessage(3:4))>0));
            saved=load(fullfile(out,'results.mat'),'result');
            testCase.verifyEqual(saved.result.cases.CaseId,result.cases.CaseId);
            testCase.verifyTrue(isfile(fullfile(out,'p95.png')));
            testCase.verifyTrue(isfile(fullfile(out,'absolute_mean.png')));
            testCase.verifyTrue(isfile(fullfile(out,'median.png')));
            testCase.verifyEqual(result.metadata.datasetId,"synthetic");
            testCase.verifyEqual(result.metadata.task,"static_displacement_field");
        end
        function undefinedErrorIsRetained(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,out]=staticFinalEvaluationTest.setupStudy(fixture.Folder,true);
            result=runStaticFinalEvaluation(config,out);
            testCase.verifyTrue(isnan(result.cases.RelativeError(1)));
            testCase.verifyEqual(result.cases.UndefinedReason(1),"reference_norm_at_or_below_threshold");
            testCase.verifyEqual(result.summary.UndefinedCount,1);
            testCase.verifyEqual(result.summary.RelativeP95,result.cases.RelativeError(3));
            testCase.verifyEqual(result.summary.DefinedCount,2);
            testCase.verifyEqual(result.summary.AbsoluteP95M, ...
                max(result.cases.AbsoluteErrorM));
        end
        function testSplitIsRequired(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,out]=staticFinalEvaluationTest.setupStudy(fixture.Folder,false);
            config.split="val";
            testCase.verifyError(@()runStaticFinalEvaluation(config,out),'surrogate:final:Split');
        end
        function overlappingTrainingIdsAreRejectedPerModel(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,out]=staticFinalEvaluationTest.setupStudy(fixture.Folder,false);
            model=surrogate.loadModel(config.models.file);
            model.trainingCaseIds(1)=201;
            overlapPath=fullfile(fixture.Folder,'overlap.mat'); save(overlapPath,'model');
            config.models(2)=struct('label',"OVERLAP",'file',overlapPath);
            result=runStaticFinalEvaluation(config,out);
            testCase.verifyEqual(result.summary.Status,["complete";"failed"]);
            testCase.verifyEqual(result.details(2).errorId,"surrogate:final:Overlap");
            testCase.verifyEqual(height(result.cases),3);
        end
        function inconsistentIdsAreRejected(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,out]=staticFinalEvaluationTest.setupStudy(fixture.Folder,false);
            design=readtable(fullfile(fixture.Folder,'design.csv'));
            design.id(1)=999; writetable(design,fullfile(fixture.Folder,'design.csv'));
            testCase.verifyError(@()runStaticFinalEvaluation(config,out),'surrogate:data:Design');
        end
        function noOverwrite(testCase)
            fixture=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            [config,~]=staticFinalEvaluationTest.setupStudy(fixture.Folder,false);
            testCase.verifyError(@()runStaticFinalEvaluation(config,fixture.Folder),'surrogate:final:Exists');
        end
    end
    methods (Static, Access=private)
        function [config,out]=setupStudy(folder,zeroReference)
            train=makeContractData("static","train");
            model=surrogate.fitModel("dummy",train,struct('seed',1,'datasetId',"synthetic"));
            modelPath=fullfile(folder,'model.mat'); surrogate.saveModel(modelPath,model);
            reference=makeContractData("static","test");
            reference.caseIds=[201;202;203];
            reference.inputParameters=[reference.inputParameters; ...
                3 4 5 6 7 8];
            reference.displacementFields=[ones(1575,1),2*ones(1575,1),4*ones(1575,1)];
            if zeroReference, reference.displacementFields(:,1)=0; end
            D=struct('schema',"static-displacement-fields-v1",'modality',"static", ...
                'split',"test",'id',reference.caseIds,'X',reference.inputParameters, ...
                'seconds',zeros(3,1),'S',reference.displacementFields,'Y',zeros(3,2), ...
                'xi',reference.normalizedGridCoordinates,'w',reference.displacementComponentWeights, ...
                'nodes',zeros(3,1));
            dataPath=fullfile(folder,'synthetic.mat'); save(dataPath,'D');
            design=array2table([reference.caseIds reference.inputParameters], ...
                'VariableNames',[{'id'},cellstr(reference.parameterNames)]);
            design.split=repmat("test",3,1); writetable(design,fullfile(folder,'design.csv'));
            config=studyConfigTemplate(); config.datasetFile=dataPath; config.datasetId="synthetic";
            config.selectionRule="synthetic fixture"; config.freezeDescription="synthetic fixture";
            config.testLabelHistory="synthetic fixture";
            config.models=struct('label',"DUMMY_SEED_1",'file',modelPath);
            out=fullfile(folder,'output');
        end
    end
end
