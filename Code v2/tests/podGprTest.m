classdef podGprTest < matlab.unittest.TestCase
    methods (TestClassSetup)
        function addProject(testCase)
            folder=fileparts(mfilename('fullpath'));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(folder)));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
        end
    end
    methods (Test)
        function sharedPodAndMismatch(testCase)
            data=makeContractData("train");
            pod=surrogate.models.shared.fitPod(data,1,"pod_gpr",[]);
            testCase.verifyEqual(pod.basis'*(pod.weights.*pod.basis),1,AbsTol=1e-10);
            centered=data.displacementFields-pod.fieldMean;
            testCase.verifyEqual(pod.fieldMean+pod.basis*(pod.basis'*(pod.weights.*centered)), ...
                data.displacementFields,AbsTol=1e-10);
            altered=data; altered.caseIds=flipud(data.caseIds);
            testCase.verifyError(@()surrogate.models.shared.fitPod(altered,1,"pod_gpr",pod), ...
                'surrogate:pod:PreparedMismatch');
        end
        function decomposition(testCase)
            data=makeContractData("train");
            pod=surrogate.models.shared.fitPod(data,1,"pod_gpr",[]);
            modelState=struct('basis',pod.basis,'weights',pod.weights,'fieldMean',pod.fieldMean);
            prediction=pod.fieldMean+pod.basis*[0.1,0.2];
            result=surrogate.models.shared.podDiagnostics(modelState,data.displacementFields,prediction);
            testCase.verifyEqual(result.decompositionResidual,[0;0],AbsTol=1e-10);
            testCase.verifyEqual(result.predictionOffBasisSquared,[0;0],AbsTol=1e-10);
        end
        function badRankAndSplit(testCase)
            data=makeContractData("train"); cfg=podGprTest.config();
            cfg.rank=2;
            testCase.verifyError(@()surrogate.fitModel("pod_gpr",data,cfg),'surrogate:pod_gpr:Rank');
            data.split="val";
            testCase.verifyError(@()surrogate.fitModel("pod_gpr",data,cfg),'surrogate:fit:Split');
        end
        function constantFieldsHaveNoRank(testCase)
            data=makeContractData("train");
            data.displacementFields(:,2)=data.displacementFields(:,1);
            testCase.verifyError(@()surrogate.fitModel("pod_gpr",data,podGprTest.config()), ...
                'surrogate:pod_gpr:Rank');
        end
        function maternLinearUsesExactGpr(testCase)
            data=podGprTest.data(); cfg=podGprTest.config();
            cfg.kernel="ardmatern52"; cfg.basisFunction="linear"; cfg.sigma=1e-3;
            model=surrogate.fitModel("pod_gpr",data,cfg);
            testCase.verifyEqual(lower(string(model.state.models{1}.FitMethod)),"exact");
            testCase.verifyEqual(lower(string(model.state.models{1}.PredictMethod)),"exact");
            testCase.verifyEqual(lower(string(model.state.models{1}.KernelFunction)),"ardmatern52");
            testCase.verifyEqual(model.state.models{1}.Sigma,cfg.sigma,AbsTol=1e-12);
        end
        function fitPredictAndPersist(testCase)
            data=podGprTest.data(); data.inputParameters(:,2)=3;
            beforeRng=rng;
            model=surrogate.fitModel("pod_gpr",data,podGprTest.config());
            testCase.verifyEqual(rng,beforeRng);
            request=struct('inputParameters',data.inputParameters,'parameterNames',data.parameterNames, ...
                'parameterUnits',data.parameterUnits,'caseIds',data.caseIds);
            before=surrogate.predictModel(model,request);
            request.inputParameters=flipud(request.inputParameters); request.caseIds=flipud(request.caseIds);
            reversed=surrogate.predictModel(model,request);
            filename=[tempname,'.mat']; testCase.addTeardown(@()delete(filename));
            surrogate.saveModel(filename,model);
            after=surrogate.predictModel(surrogate.loadModel(filename),request);
            testCase.verifySize(before.displacementFields,[1575,numel(data.caseIds)]);
            testCase.verifyEqual(before.outputUnit,"m");
            testCase.verifyEqual(reversed.displacementFields,fliplr(before.displacementFields),AbsTol=1e-10);
            testCase.verifyEqual(after.displacementFields,reversed.displacementFields,AbsTol=1e-10);
            testCase.verifyFalse(model.state.activeInputs(2));
        end
    end
    methods (Static,Access=private)
        function cfg=config()
            cfg=struct('seed',42,'datasetId',"synthetic",'rank',1,'kernel',"ardsquaredexponential", ...
                'basisFunction',"constant",'sigma',1e-3);
        end
        function data=data()
            data=makeContractData("train");
            z=linspace(-1,1,10)'; data.caseIds=(101:110)';
            data.inputParameters=[z z.^2 z.^3 z.^4 z.^5 sin(z)];
            data.displacementFields=(1:1575)'*1e-7*(1+z');
        end
    end
end
