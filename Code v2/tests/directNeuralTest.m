classdef directNeuralTest < matlab.unittest.TestCase
    properties (TestParameter)
        method = struct('mlp',"mlp",'rbf',"rbf")
        depth = struct('one',1,'two',2,'three',3)
    end
    methods (TestClassSetup)
        function addProject(t)
            folder=fileparts(mfilename('fullpath'));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function depthArchitectureAndPrediction(t,method,depth)
            data=makeContractData("train");
            cfg=directNeuralTest.config(); cfg.hiddenLayers=depth;
            model=surrogate.fitModel(method,data,cfg);
            prediction=surrogate.predictModel(model,directNeuralTest.request(data));
            expectedTanhLayers=depth-double(method=="rbf");
            layerClasses=string(arrayfun(@class,model.state.network.Layers,'UniformOutput',false));
            t.verifyEqual(sum(contains(layerClasses,'TanhLayer')),expectedTanhLayers);
            t.verifyEqual(model.state.settings.hiddenLayers,depth);
            t.verifySize(prediction.displacementFields,[1575,2]);
            t.verifyTrue(all(isfinite(prediction.displacementFields),'all'));
        end
        function invalidDepthRejected(t,method)
            cfg=directNeuralTest.config(); cfg.hiddenLayers=0;
            data=makeContractData("train");
            t.verifyError(@()surrogate.fitModel(method,data,cfg),'surrogate:neural:Config');
        end
        function staticPersistence(t,method)
            data=makeContractData("train");
            cfg=directNeuralTest.config(); cfg.optimizer="adam";
            [model,report]=surrogate.fitModel(method,data,cfg);
            request=directNeuralTest.request(data);
            before=surrogate.predictModel(model,request);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'model.mat');
            surrogate.saveModel(file,model);
            after=surrogate.predictModel(surrogate.loadModel(file),request);
            t.verifySize(before.displacementFields,[1575,2]);
            t.verifyTrue(all(isfinite(before.displacementFields),'all'));
            t.verifyEqual(after.displacementFields,before.displacementFields,AbsTol=1e-8);
            t.verifyEqual(report.optimizer,"adam");
            t.verifyEqual(model.trainingCaseIds,data.caseIds);
        end
        function staticOrderingConstantsAndEvaluation(t,method)
            data=makeContractData("train");
            data.displacementFields(1,:)=0;
            data.inputParameters(:,2)=3;
            model=surrogate.fitModel(method,data,directNeuralTest.config());
            request=directNeuralTest.request(data);
            prediction=surrogate.predictModel(model,request);
            request.inputParameters=flipud(request.inputParameters);
            request.caseIds=flipud(request.caseIds);
            reversed=surrogate.predictModel(model,request);
            metrics=surrogate.evaluatePrediction(prediction,data, ...
                struct('staticReferenceFloor',0));
            t.verifySize(prediction.displacementFields,[1575,2]);
            t.verifyEqual(prediction.displacementFields(1,:),[0,0],AbsTol=1e-12);
            t.verifyEqual(reversed.displacementFields,fliplr(prediction.displacementFields),AbsTol=1e-6);
            t.verifyTrue(all(isfinite(metrics.relativeWeightedFieldError)));
        end
        function reproducibleAndRngRestored(t,method)
            data=makeContractData("train"); cfg=directNeuralTest.config();
            before=rng;
            first=surrogate.fitModel(method,data,cfg);
            after=rng;
            second=surrogate.fitModel(method,data,cfg);
            p=surrogate.predictModel(first,directNeuralTest.request(data));
            q=surrogate.predictModel(second,directNeuralTest.request(data));
            t.verifyEqual(before,after);
            t.verifyEqual(p.displacementFields,q.displacementFields,AbsTol=1e-8);
        end
        function invalidOptimizerRejected(t,method)
            cfg=directNeuralTest.config(); cfg.optimizer="invalid";
            data=makeContractData("train");
            t.verifyError(@()surrogate.fitModel(method,data,cfg),'surrogate:neural:Config');
        end
        function invalidWidthRejected(t)
            cfg=directNeuralTest.config(); cfg.rbfWidth=0;
            data=makeContractData("train");
            t.verifyError(@()surrogate.fitModel("rbf",data,cfg),'surrogate:neural:Config');
        end
        function validationSplitRejected(t,method)
            data=makeContractData("val");
            t.verifyError(@()surrogate.fitModel(method,data,directNeuralTest.config()), ...
                'surrogate:fit:Split');
        end
    end
    methods (Static, Access=private)
        function cfg=config()
            cfg=struct('seed',42,'hiddenWidth',3,'centerCount',2, ...
                'maxEpochs',2,'miniBatchSize',2,'learningRate',1e-3);
        end
        function request=request(data)
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits, ...
                'caseIds',data.caseIds);
        end
    end
end
