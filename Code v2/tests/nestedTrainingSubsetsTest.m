classdef nestedTrainingSubsetsTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            folder=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
        end
    end
    methods (Test)
        function nestedBalancedAndRngPreserved(testCase)
            ids=(1:16)'; block=ids<=8; prior=rng;
            sets=surrogate.study.nestedTrainingSubsets(ids,block,[4 8 16],[1 2 3]);
            testCase.verifyEqual(rng,prior);
            testCase.verifyEqual(sum(sets{1,1}<=8),2);
            testCase.verifyTrue(all(ismember(sets{1,1},sets{2,1})));
            testCase.verifyTrue(all(ismember(sets{2,1},sets{3,1})));
            testCase.verifyEqual(sets{3,1},sets{3,2});
            testCase.verifyEqual(sets{3,2},sets{3,3});
            testCase.verifyEqual(sets,surrogate.study.nestedTrainingSubsets(ids,block,[4 8 16],[1 2 3]));
        end
        function normalizedParameterOverlap(testCase)
            first=[1 1e11]; second=[1+1e-11 1e11+1];
            testCase.verifyError(@()surrogate.study.assertDisjointParameters(first,second, ...
                [0 0],[2 2e11],1e-10),'surrogate:study:ParameterOverlap');
            testCase.verifyWarningFree(@()surrogate.study.assertDisjointParameters(first, ...
                [1.1 1e11],[0 0],[2 2e11],1e-10));
        end
        function unbalancedBlocksRejected(testCase)
            testCase.verifyError(@()surrogate.study.nestedTrainingSubsets((1:8)', ...
                [true(3,1);false(5,1)],[4 8],1),'surrogate:study:Sizes');
        end
    end
end
