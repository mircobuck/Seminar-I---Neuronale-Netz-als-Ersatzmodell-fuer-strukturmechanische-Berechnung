classdef modalModelsTest < matlab.unittest.TestCase
    properties (TestParameter)
        Method = {"mlp","rbf","pod_mlp","pod_gpr"}
    end
    methods (TestClassSetup)
        function setup(t)
            root=fileparts(fileparts(mfilename('fullpath')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'tests')));
            t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'workflows','modal_comparison')));
        end
    end
    methods (Test)
        function allMethodsRoundTrip(t,Method)
            data=makeModalData("train"); cfg=modalModelsTest.settings;
            [model,report]=surrogate.fitModel(Method,data,cfg);
            request=modalModelsTest.request(data);
            before=surrogate.predictModel(model,request);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'model.mat'); surrogate.saveModel(file,model);
            after=surrogate.predictModel(surrogate.loadModel(file),request);
            t.verifySize(before.frequencyHz,[12 6]);
            t.verifyEqual(after,before,AbsTol=0);
            t.verifyEqual(report.trainingCount,12);
            t.verifyFalse(isfield(before,'displacementFields'));
            t.verifyEqual(model.outputUnit,"Hz");
        end
        function normalizationUsesTrainingOnly(t,Method)
            data=makeModalData("train"); model=surrogate.fitModel(Method,data,modalModelsTest.settings);
            t.verifyEqual(model.state.inputMean,mean(data.inputParameters,1),AbsTol=0);
        end
        function fullRankReconstructs(t)
            data=makeModalData("train");
            p=surrogate.models.shared.fitPod(data,6,"pod_mlp",[]);
            F=data.frequencyHz'; reconstructed=p.fieldMean+p.basis*(p.basis'*(F-p.fieldMean));
            t.verifyEqual(reconstructed,F,AbsTol=1e-10);
            t.verifyEqual(p.retainedEnergy,1,AbsTol=1e-12);
        end
        function badRankRejected(t)
            t.verifyError(@()surrogate.models.shared.fitPod(makeModalData("train"),7,"pod_mlp",[]),'surrogate:pod_mlp:Rank');
        end
        function constantInputsAndTargets(t,Method)
            data=makeModalData("train");
            data.inputParameters(:,5)=.3; data.frequencyHz(:,1)=100;
            model=surrogate.fitModel(Method,data,modalModelsTest.settings);
            prediction=surrogate.predictModel(model,modalModelsTest.request(data));
            t.verifyTrue(all(isfinite(prediction.frequencyHz),'all'));
            t.verifyEqual(model.state.inputScale(5),1,AbsTol=0);
        end
        function metricsDoNotSortOrClip(t)
            data=makeModalData("test"); c=surrogate.contract("modal");
            p=struct('contractVersion',c.version,'task',c.task,'outputUnit',c.outputUnit, ...
                'caseIds',data.caseIds,'modeIndices',c.modeIndices,'frequencyHz',1.1*data.frequencyHz);
            e=surrogate.evaluatePrediction(p,data,struct);
            t.verifyEqual(e.relativeFrequencyError,.1*ones(12,6),AbsTol=1e-12);
            p.frequencyHz(:,2)=-10;
            e=surrogate.evaluatePrediction(p,data,struct);
            t.verifyTrue(all(e.orderViolation));
            t.verifyTrue(all(e.nonpositiveFrequency(:,2)));
        end
        function rejectsForceInsteadOfDensity(t)
            data=makeModalData("train"); data.parameterNames(6)="Fz_N";
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Parameters');
        end
        function rejectsUnsortedReference(t)
            data=makeModalData("train"); data.frequencyHz(:,[1 2])=data.frequencyHz(:,[2 1]);
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Targets');
        end
        function rejectsNonpositiveReference(t)
            data=makeModalData("train"); data.frequencyHz(1,1)=0;
            t.verifyError(@()surrogate.validateDataset(data),'surrogate:data:Targets');
        end
        function disjointSplits(t)
            train=makeModalData("train"); val=makeModalData("val",4,100);
            t.verifyWarningFree(@()surrogate.validateTrainingSplits(train,val));
        end
        function rejectsParameterOverlap(t)
            train=makeModalData("train"); val=makeModalData("val",4,100);
            val.inputParameters(1,:)=train.inputParameters(1,:);
            t.verifyError(@()surrogate.validateTrainingSplits(train,val),'surrogate:splits:Overlap');
        end
        function checkpointResumeAndChangedData(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            metadata=struct('startedPosix',posixtime(datetime('now','TimeZone','UTC')), ...
                'budgetSeconds',Inf,'pilotSpentSeconds',0);
            save(fullfile(folder.Folder,'environment.mat'),'metadata');
            train=makeModalData("train"); val=makeModalData("val",4,100);
            file=fullfile(folder.Folder,'fit'); c=modalModelsTest.settings;
            first=surrogate.study.fitCheckpoint(file,"mlp",train,val,c);
            second=surrogate.study.fitCheckpoint(file,"mlp",train,val,c);
            t.verifyEqual(first.status,"ok"); t.verifyEqual(second,first,AbsTol=0);
            val.frequencyHz(1,1)=val.frequencyHz(1,1)+1;
            t.verifyError(@()surrogate.study.fitCheckpoint(file,"mlp",train,val,c),'study:CheckpointChanged');
        end
        function analyticalMaterialScaling(t)
            data=makeModalData("train"); X=data.inputParameters;
            original=modalstudy.analytical(X); X(:,4)=4*X(:,4);
            t.verifyEqual(modalstudy.analytical(X),2*original,RelTol=1e-12);
        end
        function modalPodUsesSharedScale(t)
            data=makeModalData("train"); cfg=modalModelsTest.settings;
            cfg.lossMode="shared_output_mse";
            model=surrogate.fitModel("pod_mlp",data,cfg);
            t.verifyEqual(model.state.coefficientScale(1),model.state.coefficientScale(2),AbsTol=0);
            t.verifyEqual(model.state.weights,ones(6,1),AbsTol=0);
        end
    end
    methods (Static)
        function c=settings
            c=struct('seed',42,'datasetId',"synthetic",'rank',2,'hiddenWidth',3, ...
                'hiddenLayers',1,'maxEpochs',1,'miniBatchSize',4,'learningRate',.001, ...
                'centerCount',3,'rbfWidth',1,'optimizer',"adam",'lossMode',"per_coefficient_mse");
            % Direct networks use their default; POD uses its common default.
            c=rmfield(c,'lossMode');
        end
        function r=request(data)
            r=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
        end
    end
end
