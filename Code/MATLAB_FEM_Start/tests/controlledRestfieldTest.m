classdef controlledRestfieldTest < matlab.unittest.TestCase
    methods (Test)
        function columnHiddenLayerWidthsAreIterated(testCase)
            rng(6,'twister');
            X=randn(16,6);
            A=[X(:,1)+X(:,2),X(:,3)-X(:,4)];
            options=struct('HiddenLayers',[8;4],'Seed',43,'Budget',1, ...
                'Optimizer',"adam",'BatchSize',16,'InitialLearnRate',1e-3, ...
                'L2Regularization',1e-4,'HistorySize',10, ...
                'GradientTolerance',1e-6,'StepTolerance',1e-8);
            model=femstudy.models.fitControlledRestMLP(X,A,options);
            testCase.verifyEqual(model.hiddenLayers,[8 4]);
            testCase.verifySize(predict_reg(model,X),size(A));
        end

        function optimizersUseSameInitialWeightsAndPredictFiniteValues(testCase)
            rng(6,'twister');
            X=randn(24,6);
            A=[X(:,1)+X(:,2),X(:,3)-X(:,4)];
            common=struct('HiddenLayers',[8],'Seed',42,'Budget',2, ...
                'Optimizer',"adam",'BatchSize',24,'InitialLearnRate',1e-3, ...
                'L2Regularization',1e-4,'HistorySize',10, ...
                'GradientTolerance',1e-6,'StepTolerance',1e-8);
            adamOptions=common;
            lbfgsOptions=common; lbfgsOptions.Optimizer="lbfgs";
            [adam,adamHistory]=femstudy.models.fitControlledRestMLP(X,A,adamOptions);
            [lbfgs,lbfgsHistory]=femstudy.models.fitControlledRestMLP(X,A,lbfgsOptions);
            testCase.verifyEqual(adam.initialWeightsHash,lbfgs.initialWeightsHash);
            testCase.verifySize(predict_reg(adam,X),size(A));
            testCase.verifySize(predict_reg(lbfgs,X),size(A));
            testCase.verifyTrue(all(isfinite(predict_reg(adam,X)),'all'));
            testCase.verifyTrue(all(isfinite(predict_reg(lbfgs,X)),'all'));
            testCase.verifyEqual(adam.optimizer,"adam");
            testCase.verifyEqual(lbfgs.optimizer,"lbfgs");
            testCase.verifyGreaterThanOrEqual(adam.trainingSeconds,0);
            testCase.verifyGreaterThanOrEqual(lbfgs.trainingSeconds,0);
            testCase.verifyTrue(isfield(adamHistory,'trainingLoss'));
            testCase.verifyTrue(isfield(lbfgsHistory,'trainingLoss'));
            testCase.verifyNotEmpty(adamHistory.trainingLoss);
            testCase.verifyNotEmpty(lbfgsHistory.trainingLoss);
        end
    end
end
