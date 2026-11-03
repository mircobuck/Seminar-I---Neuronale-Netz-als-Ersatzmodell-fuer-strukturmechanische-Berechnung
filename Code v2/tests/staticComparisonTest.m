classdef staticComparisonTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            folder=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function knownErrorsAndMultipleModels(testCase)
            training=makeContractData("static","train");
            reference=makeContractData("static","val");
            model=surrogate.fitModel("dummy",training,struct('seed',1,'datasetId',"synthetic"));
            models=struct('label',{"first","second"},'model',{model,model});
            config=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
            [figures,results]=surrogate.plotStaticComparison(models,reference,config);
            testCase.addTeardown(@()close(figures));
            expected=[0.500001;0.249999];
            testCase.verifyEqual(results(1).metrics.relativeWeightedFieldError,expected,AbsTol=1e-10);
            testCase.verifyEqual(results(1).medianRelativeError,median(expected),AbsTol=1e-10);
            testCase.verifyEqual(results(1).p95RelativeError,max(expected),AbsTol=1e-10);
            testCase.verifyEqual(results(1).metrics.absoluteWeightedFieldError, ...
                sqrt(3)*[0.500001;0.499998],AbsTol=1e-10);
            testCase.verifyEqual(results(2).metrics,results(1).metrics);
            testCase.verifyEqual(numel(figures),2);
        end
        function undefinedRelativeErrorsRemainVisible(testCase)
            training=makeContractData("static","train");
            reference=makeContractData("static","val");
            reference.displacementFields(:,1)=0;
            model=surrogate.fitModel("dummy",training,struct('seed',1,'datasetId',"synthetic"));
            models=struct('label',"dummy",'model',model);
            config=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
            [figures,results]=surrogate.plotStaticComparison(models,reference,config);
            testCase.addTeardown(@()close(figures));
            testCase.verifyTrue(isnan(results.metrics.relativeWeightedFieldError(1)));
            testCase.verifyEqual(results.undefinedCount,1);
            testCase.verifyEqual(results.medianRelativeError,results.metrics.relativeWeightedFieldError(2));
        end
        function testSplitRejected(testCase)
            reference=makeContractData("static","test");
            models=struct('label',"dummy",'model',struct());
            config=struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0);
            testCase.verifyError(@()surrogate.plotStaticComparison(models,reference,config), ...
                'surrogate:plot:Reference');
        end
    end
end
