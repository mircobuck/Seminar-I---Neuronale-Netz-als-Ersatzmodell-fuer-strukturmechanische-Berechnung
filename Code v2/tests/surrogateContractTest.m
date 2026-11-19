classdef surrogateContractTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(t)
            folder=fileparts(mfilename('fullpath'));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function staticRoundTripAndOverwriteGuard(t)
            data=makeContractData("train");
            cfg=struct('seed',42,'datasetId',"synthetic",'hiddenWidth',2,'maxEpochs',1,'miniBatchSize',2);
            [model,report]=surrogate.fitModel("mlp",data,cfg);
            request=surrogateContractTest.request(data);
            before=surrogate.predictModel(model,request);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'model.mat');
            surrogate.saveModel(file,model);
            after=surrogate.predictModel(surrogate.loadModel(file),request);
            t.verifyEqual(after,before,AbsTol=0);
            t.verifyEqual(report.trainingCount,2);
            t.verifyError(@()surrogate.saveModel(file,model),'surrogate:save:Exists');
        end
        function staticMetricsMatchWeightedFormula(t)
            data=makeContractData("val");
            prediction=surrogateContractTest.prediction(data);
            prediction.displacementFields=1.5*data.displacementFields;
            metrics=surrogate.evaluatePrediction(prediction,data,struct('staticReferenceFloor',0));
            t.verifyEqual(metrics.relativeWeightedFieldError,[.5;.5],AbsTol=1e-12);
            t.verifyEqual(metrics.absoluteWeightedFieldError,sqrt(3)*[.5;1],AbsTol=1e-12);
        end
        function zeroReferencesAreMarked(t)
            data=makeContractData("val");
            data.displacementFields(:,1)=0;
            metrics=surrogate.evaluatePrediction(surrogateContractTest.prediction(data),data,struct('staticReferenceFloor',0));
            t.verifyTrue(isnan(metrics.relativeWeightedFieldError(1)));
            t.verifyFalse(metrics.relativeErrorDefined(1));
            t.verifyEqual(metrics.absoluteWeightedFieldError,[0;0],AbsTol=0);
        end
        function wrongParameterOrderRejected(t)
            data=makeContractData("train");
            data.parameterNames([1,2])=data.parameterNames([2,1]);
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Parameters');
        end
        function wrongGridRejected(t)
            data=makeContractData("train");
            data.normalizedGridCoordinates(:,[1,2])=data.normalizedGridCoordinates(:,[2,1]);
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Grid');
        end
        function duplicateIdsRejected(t)
            data=makeContractData("train");
            data.caseIds(2)=data.caseIds(1);
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Ids');
        end
        function fieldOrientationRejected(t)
            data=makeContractData("train");
            data.displacementFields=data.displacementFields';
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Targets');
        end
        function validationCannotTrain(t)
            data=makeContractData("val");
            t.verifyError(@()surrogate.fitModel("mlp",data,struct('seed',1)), ...
                'surrogate:fit:Split');
        end
        function overlappingSplitsRejected(t)
            training=makeContractData("train");
            validation=makeContractData("val");
            t.verifyError(@()surrogate.validateTrainingSplits(training,validation),'surrogate:splits:Overlap');
        end
        function disjointSplitsAccepted(t)
            training=makeContractData("train");
            validation=makeContractData("val");
            validation.caseIds=validation.caseIds+100;
            validation.inputParameters=validation.inputParameters+100;
            t.verifyWarningFree(@()surrogate.validateTrainingSplits(training,validation));
        end
        function badUnitsRejectedForPrediction(t)
            data=makeContractData("train");
            model=struct('task',"static",'normalizedGridCoordinates',data.normalizedGridCoordinates);
            request=surrogateContractTest.request(data);
            request.parameterUnits(1)="mm";
            t.verifyError(@()surrogate.predictModel(model,request),'surrogate:predict:Parameters');
        end
        function nonfinitePredictionsRejected(t)
            data=makeContractData("val");
            prediction=surrogateContractTest.prediction(data);
            prediction.displacementFields(1)=NaN;
            t.verifyError(@()surrogate.evaluatePrediction(prediction,data,struct('staticReferenceFloor',0)), ...
                'surrogate:evaluate:Output');
        end
        function unknownMethodRejected(t)
            data=makeContractData("train");
            t.verifyError(@()surrogate.fitModel("missing",data,struct('seed',1)),'surrogate:fit:Method');
        end
        function unsupportedTaskRejected(t)
            t.verifyError(@()surrogate.contract("modal"),'surrogate:contract:Task');
        end
        function reorderedCaseIdsRejected(t)
            data=makeContractData("val");
            prediction=surrogateContractTest.prediction(data);
            prediction.caseIds=flipud(data.caseIds);
            t.verifyError(@()surrogate.evaluatePrediction(prediction,data,struct('staticReferenceFloor',0)), ...
                'surrogate:evaluate:CaseIds');
        end
        function productionTrainCanBeLoaded(t)
            root=fileparts(fileparts(mfilename('fullpath')));
            data=surrogate.loadDataset(fullfile(root,'data_generation','data','static','train.mat'));
            t.verifySize(data.inputParameters,[768,6]);
            t.verifyEqual(string(data.split),"train");
        end
    end
    methods (Static,Access=private)
        function request=request(data)
            request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
        end
        function prediction=prediction(data)
            prediction=struct('contractVersion',data.contractVersion,'task',"static", ...
                'outputUnit',"m",'caseIds',data.caseIds,'displacementFields',data.displacementFields, ...
                'normalizedGridCoordinates',data.normalizedGridCoordinates);
        end
    end
end
