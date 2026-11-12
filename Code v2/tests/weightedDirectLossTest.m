classdef weightedDirectLossTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            folder=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function weightedObjectiveIsProportional(testCase)
            data=makeContractData("train");
            data.displacementComponentWeights=(1:1575)'/1575;
            cfg=weightedDirectLossTest.config();
            [model,report]=surrogate.fitModel("mlp",data,cfg);
            residual=reshape(sin(1:3150),2,1575);
            normalized=residual./model.state.outputScale;
            physical=sum(residual.^2.*data.displacementComponentWeights',2);
            testCase.verifyEqual(mean(normalized.^2,2), ...
                physical./(1575*model.state.outputScale(1)^2*data.displacementComponentWeights(1)),RelTol=1e-12);
            testCase.verifyEqual(report.lossMode,"weighted_field_mse");
        end
        function constantFieldRestored(testCase)
            data=makeContractData("train");
            data.displacementFields(:,2)=data.displacementFields(:,1);
            model=surrogate.fitModel("mlp",data,weightedDirectLossTest.config());
            request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
            prediction=surrogate.predictModel(model,request);
            testCase.verifyEqual(prediction.displacementFields,data.displacementFields,AbsTol=1e-12);
        end
    end
    methods (Static,Access=private)
        function cfg=config()
            cfg=struct('seed',42,'datasetId',"synthetic",'hiddenWidth',4, ...
                'maxEpochs',2,'miniBatchSize',2,'lossMode',"weighted_field_mse");
        end
    end
end
