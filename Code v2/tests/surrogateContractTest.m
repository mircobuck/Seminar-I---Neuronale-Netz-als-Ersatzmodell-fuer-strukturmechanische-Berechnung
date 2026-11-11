classdef surrogateContractTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            testDir=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(testDir)));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(testDir));
        end
    end
    methods (Test)
        function modalRoundTripAndOrder(testCase)
            data=makeContractData("modal","train");
            [model,report]=surrogate.fitModel("dummy",data,struct('seed',42,'datasetId',"synthetic"));
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
            before=surrogate.predictModel(model,request);
            path=[tempname,'.mat']; testCase.addTeardown(@()delete(path));
            surrogate.saveModel(path,model);
            loaded=surrogate.loadModel(path);
            after=surrogate.predictModel(loaded,request);
            testCase.verifyEqual(after.naturalFrequenciesHz,before.naturalFrequenciesHz,AbsTol=1e-12);
            testCase.verifyEqual(after.naturalFrequenciesHz(2,:)-after.naturalFrequenciesHz(1,:), ...
                ones(1,6),AbsTol=1e-12);
            testCase.verifyEqual(report.trainingCount,2);
            testCase.verifyError(@()surrogate.saveModel(path,model),'surrogate:save:Exists');
        end
        function staticPredictionAndMetrics(testCase)
            data=makeContractData("static","train");
            model=surrogate.fitModel("dummy",data,struct('seed',1,'datasetId',"synthetic"));
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
            prediction=surrogate.predictModel(model,request);
            metrics=surrogate.evaluatePrediction(prediction,data, ...
                struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
            testCase.verifySize(prediction.displacementFields,[1575,2]);
            testCase.verifyEqual(prediction.displacementFields(1,2)-prediction.displacementFields(1,1), ...
                1e-6,AbsTol=1e-12);
            testCase.verifyEqual(metrics.relativeWeightedFieldError(1),0.500001,AbsTol=1e-10);
        end
        function zeroReferencesAreMarked(testCase)
            data=makeContractData("modal","val"); data.naturalFrequenciesHz(1,1)=0;
            prediction=struct('contractVersion',"surrogate-v1",'task',"modal", ...
                'outputUnit',"Hz",'modeIndices',(1:6)','caseIds',data.caseIds, ...
                'naturalFrequenciesHz',data.naturalFrequenciesHz);
            result=surrogate.evaluatePrediction(prediction,data, ...
                struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0));
            testCase.verifyTrue(isnan(result.relativeFrequencyError(1,1)));
            testCase.verifyFalse(result.relativeErrorDefined(1,1));
            testCase.verifyEqual(result.absoluteFrequencyErrorHz,zeros(2,6),AbsTol=1e-12);
        end
        function wrongParameterOrderRejected(testCase)
            data=makeContractData("static","train"); data.parameterNames([1,2])=data.parameterNames([2,1]);
            testCase.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Parameters');
        end
        function wrongGridRejected(testCase)
            data=makeContractData("static","train"); data.normalizedGridCoordinates(:,[1,2])=data.normalizedGridCoordinates(:,[2,1]);
            testCase.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Grid');
        end
        function duplicateIdsRejected(testCase)
            data=makeContractData("modal","train"); data.caseIds(2)=data.caseIds(1);
            testCase.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Ids');
        end
        function fieldOrientationRejected(testCase)
            data=makeContractData("static","train"); data.displacementFields=data.displacementFields';
            testCase.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Targets');
        end
        function validationCannotTrain(testCase)
            data=makeContractData("modal","val");
            testCase.verifyError(@()surrogate.fitModel("dummy",data, ...
                struct('seed',1,'datasetId',"synthetic")),'surrogate:fit:Split');
        end
        function overlappingSplitsRejected(testCase)
            training=makeContractData("modal","train");
            validation=makeContractData("modal","val");
            testCase.verifyError(@()surrogate.validateTrainingSplits(training,validation), ...
                'surrogate:splits:Overlap');
        end
        function disjointSplitsAccepted(testCase)
            training=makeContractData("modal","train");
            validation=makeContractData("modal","val");
            validation.caseIds=validation.caseIds+100;
            validation.inputParameters=validation.inputParameters+100;
            testCase.verifyWarningFree(@()surrogate.validateTrainingSplits(training,validation));
        end
        function badUnitsRejectedForPrediction(testCase)
            data=makeContractData("modal","train");
            model=surrogate.fitModel("dummy",data,struct('seed',1,'datasetId',"synthetic"));
            request=struct('inputParameters',data.inputParameters, ...
                'parameterNames',data.parameterNames,'parameterUnits',["mm",data.parameterUnits(2:end)],'caseIds',data.caseIds);
            testCase.verifyError(@()surrogate.predictModel(model,request),'surrogate:predict:Parameters');
        end
        function nonfinitePredictionsRejected(testCase)
            data=makeContractData("modal","val");
            values=data.naturalFrequenciesHz; values(1)=NaN;
            pred=struct('contractVersion',"surrogate-v1",'task',"modal",'outputUnit',"Hz", ...
                'modeIndices',(1:6)','naturalFrequenciesHz',values,'caseIds',data.caseIds);
            testCase.verifyError(@()surrogate.evaluatePrediction(pred,data, ...
                struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0)), ...
                'surrogate:evaluate:Output');
        end
        function unknownMethodRejected(testCase)
            data=makeContractData("modal","train");
            testCase.verifyError(@()surrogate.fitModel("missing",data, ...
                struct('seed',1,'datasetId',"synthetic")),'surrogate:fit:Method');
        end
        function reorderedCaseIdsRejected(testCase)
            data=makeContractData("modal","val");
            pred=struct('contractVersion',"surrogate-v1",'task',"modal",'outputUnit',"Hz", ...
                'modeIndices',(1:6)','naturalFrequenciesHz',data.naturalFrequenciesHz, ...
                'caseIds',flipud(data.caseIds));
            testCase.verifyError(@()surrogate.evaluatePrediction(pred,data, ...
                struct('staticReferenceFloor',0,'frequencyReferenceFloorHz',0)), ...
                'surrogate:evaluate:CaseIds');
        end
        function productionTrainCanBeLoaded(testCase)
            projectRoot=fileparts(fileparts(mfilename('fullpath')));
            filePath=fullfile(projectRoot,'data_generation','data','static','train.mat');
            testCase.assumeTrue(isfile(filePath),'Optional real training dataset not present.');
            data=surrogate.loadDataset(filePath);
            % Static training was extended to 768 cases on 2026-11-05.
            testCase.verifySize(data.inputParameters,[768,6]);
            testCase.verifyEqual(string(data.split),"train");
        end
        function productionModalSplitsCanBeLoaded(testCase)
            projectRoot=fileparts(fileparts(mfilename('fullpath')));
            folder=fullfile(projectRoot,'data_generation','data','modal');
            trainPath=fullfile(folder,'train.mat'); valPath=fullfile(folder,'val.mat');
            testCase.assumeTrue(isfile(trainPath) && isfile(valPath),'Optional real modal splits not present.');
            training=surrogate.loadDataset(trainPath);
            validation=surrogate.loadDataset(valPath);
            testCase.verifyWarningFree(@()surrogate.validateTrainingSplits(training,validation));
            testCase.verifySize(training.naturalFrequenciesHz,[384,6]);
            testCase.verifySize(validation.naturalFrequenciesHz,[12,6]);
        end
    end
end
