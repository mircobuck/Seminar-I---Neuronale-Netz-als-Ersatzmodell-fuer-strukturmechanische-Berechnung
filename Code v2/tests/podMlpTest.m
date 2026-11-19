classdef podMlpTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            folder=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function weightedBasisAndReconstruction(testCase)
            data=makeContractData("train");
            data.displacementFields(1,:)=0;
            data.displacementComponentWeights=(1:1575)'/1575;
            model=surrogate.fitModel("pod_mlp",data,podMlpTest.config());
            state=model.state; w=data.displacementComponentWeights;
            testCase.verifyEqual(state.basis'*(w.*state.basis),1,AbsTol=1e-10);
            centered=data.displacementFields-state.fieldMean;
            reconstructed=state.fieldMean+state.basis*(state.basis'*(w.*centered));
            testCase.verifyEqual(reconstructed,data.displacementFields,AbsTol=1e-10);
            testCase.verifyEqual(state.basis(1),0,AbsTol=1e-12);
        end
        function predictionOrderAndPersistence(testCase)
            data=makeContractData("train");
            data.displacementFields(1,:)=0;
            model=surrogate.fitModel("pod_mlp",data,podMlpTest.config());
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits, ...
                'caseIds',data.caseIds);
            before=surrogate.predictModel(model,request);
            request.inputParameters=flipud(request.inputParameters);
            request.caseIds=flipud(request.caseIds);
            reversed=surrogate.predictModel(model,request);
            path=[tempname,'.mat']; testCase.addTeardown(@()delete(path));
            surrogate.saveModel(path,model);
            after=surrogate.predictModel(surrogate.loadModel(path),request);
            testCase.verifySize(before.displacementFields,[1575,2]);
            testCase.verifyEqual(reversed.displacementFields,fliplr(before.displacementFields),AbsTol=1e-10);
            testCase.verifyEqual(after.displacementFields,reversed.displacementFields,AbsTol=1e-10);
            testCase.verifyEqual(before.displacementFields(1,:),[0 0],AbsTol=1e-12);
        end
        function constantInputIsSafe(testCase)
            data=makeContractData("train");
            data.inputParameters(:,2)=3;
            model=surrogate.fitModel("pod_mlp",data,podMlpTest.config());
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits, ...
                'caseIds',data.caseIds);
            prediction=surrogate.predictModel(model,request);
            testCase.verifyTrue(all(isfinite(prediction.displacementFields),'all'));
        end
        function weightedFieldLossUsesSharedCoefficientScale(testCase)
            data=makeContractData("train");
            cfg=podMlpTest.config(); cfg.lossMode="weighted_field_mse";
            model=surrogate.fitModel("pod_mlp",data,cfg);
            testCase.verifyEqual(model.state.lossMode,"weighted_field_mse");
            testCase.verifyEqual(model.state.coefficientScale, ...
                repmat(model.state.coefficientScale(1),1,cfg.rank));
            testCase.verifyEqual(model.state.settings.lossMode,"weighted_field_mse");
        end
        function unsupportedLossModeRejected(testCase)
            data=makeContractData("train");
            cfg=podMlpTest.config(); cfg.lossMode="unweighted_field_mse";
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,cfg), ...
                'surrogate:pod_mlp:Config');
        end
        function optimizerSelectionAndValidation(testCase)
            data=makeContractData("train");
            cfg=podMlpTest.config(); cfg.optimizer="adam";
            [model,report]=surrogate.fitModel("pod_mlp",data,cfg);
            testCase.verifyEqual(report.optimizer,"adam");
            testCase.verifyEqual(model.state.settings.optimizer,"adam");
            cfg=podMlpTest.config(); cfg.optimizer="unsupported";
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,cfg), ...
                'surrogate:pod_mlp:Config');
        end
        function invalidRankRejected(testCase)
            data=makeContractData("train");
            cfg=podMlpTest.config(); cfg.rank=2;
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,cfg),'surrogate:pod_mlp:Rank');
            cfg.rank=0;
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,cfg),'surrogate:pod_mlp:Config');
        end
        function missingConfigFieldsReported(testCase)
            data=makeContractData("train");
            cfg=rmfield(podMlpTest.config(),{'hiddenWidth','hiddenLayers'});
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,cfg),'surrogate:pod_mlp:Config');
        end
        function modalTaskRejected(testCase)
            data=makeContractData("train");
            data.modality="modal";
            testCase.verifyError(@()surrogate.fitModel("pod_mlp",data,podMlpTest.config()), ...
                'surrogate:pod_mlp:Task');
        end
    end
    methods (Static, Access=private)
        function cfg=config()
            cfg=struct('seed',42,'datasetId',"synthetic",'rank',1, ...
                'hiddenWidth',4,'maxEpochs',2,'miniBatchSize',2,'learningRate',1e-3, ...
                'hiddenLayers',1);
        end
    end
end
