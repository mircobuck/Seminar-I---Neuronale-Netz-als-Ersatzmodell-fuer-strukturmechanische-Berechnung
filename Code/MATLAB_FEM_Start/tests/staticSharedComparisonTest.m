classdef staticSharedComparisonTest < matlab.unittest.TestCase
    methods (Test)
        function fitBeamFieldRejectsSplitOverlap(testCase)
            train=struct('id',[1;2]);
            val=struct('id',[2;3]);
            testCase.verifyError(@()femstudy.models.fitBeamField(train,val), ...
                'femstudy:split:Leakage');
        end

        function fitBeamFieldRejectsInvalidConfiguredRanks(testCase)
            train=struct('id',1,'xi',zeros(3,1),'w',1);
            val=struct('id',2,'xi',zeros(3,1),'w',1);
            options=struct('ranks',0,'kernels',"ardmatern52");
            testCase.verifyError(@()femstudy.models.fitBeamField(train,val,options), ...
                'femstudy:beamField:Ranks');
        end

        function fitBeamFieldRejectsUnknownKernel(testCase)
            train=struct('id',1,'xi',zeros(3,1),'w',1);
            val=struct('id',2,'xi',zeros(3,1),'w',1);
            options=struct('ranks',1,'kernels',"unknown");
            testCase.verifyError(@()femstudy.models.fitBeamField(train,val,options), ...
                'femstudy:beamField:Kernels');
        end

        function pairwiseMetricUsesSameCaseIDs(testCase)
            ids=[19;20;21];
            reference=[1 2 3;1 1 1;2 2 2];
            prediction=reference.*[1.1 0.9 1.2];
            metric=femstudy.metrics.field(reference,prediction,ones(3,1), ...
                [1 1 1;1 1 1;1 1 1]);
            testCase.verifyEqual(numel(ids),numel(metric.relative));
            testCase.verifyTrue(all(isfinite(metric.relative)));
            testCase.verifyEqual(metric.summary(1),median(metric.relative),AbsTol=1e-14);
            sorted=sort(metric.relative);
            testCase.verifyEqual(metric.summary(2), ...
                sorted(ceil(.95*numel(ids))),AbsTol=1e-14);
        end

        function immutableSaveRefusesReplacement(testCase)
            folder=tempname; mkdir(folder);
            cleanup=onCleanup(@()rmdir(folder,'s'));
            path=fullfile(folder,'artifact.mat');
            femstudy.data.saveNew(path,struct('value',17));
            testCase.verifyError(@()femstudy.data.saveNew(path,struct('value',23)), ...
                'femstudy:artifact:Exists');
            loaded=load(path,'value');
            testCase.verifyEqual(loaded.value.value,17);
            clear cleanup
        end
    end
end
