classdef neuralPrototypeTest < matlab.unittest.TestCase
    methods (Test)
        function pinnEnforcesClamp(testCase)
            model=struct('parameters',[1 1e9 .1 .1],'width',2,'theta',zeros(7,1));
            [w,~]=femstudy.models.predictPINN(model,[0 .5 1]);
            testCase.verifyEqual(w(1),0,'AbsTol',1e-14);
        end

        function fnoPreservesFieldShape(testCase)
            xi=[0 1;0 1;0 1]; X=[1 .1 .1 1e9 .3 -1;1.1 .1 .1 1.1e9 .3 -1.2];
            D=struct('X',X,'xi',xi,'S',zeros(6,2));
            M=femstudy.models.fitFNO(D,modes=[2 1 1]); H=femstudy.models.predictFNO(M,X);
            testCase.verifySize(H,[6 2]);
            testCase.verifyTrue(all(isfinite(H),'all'));
        end

        function graphDeduplicatesEdgesAndClamps(testCase)
            nodes=[0 1 0 0 .5 .5 0 0 .5 .5;0 0 1 0 0 .5 .5 0 .5 0;0 0 0 1 0 0 0 .5 .5 .5];
            elements=(1:10)'; G=femstudy.models.buildGraph(nodes,elements,[1 .1 .1 1e9 .3 -1]);
            testCase.verifyEqual(size(unique(G.edges','rows'),1),size(G.edges,2));
            testCase.verifyTrue(all(G.nodeWeights>=0));
            C=struct('nodes',nodes,'elements',elements,'X',[1 .1 .1 1e9 .3 -1], ...
                'displacement',zeros(10,3));
            M=femstudy.models.fitGraph({C}); U=femstudy.models.predictGraph(M,C);
            testCase.verifySize(U,[10 3]);
            testCase.verifyEqual(U(G.clampedNodes,:),zeros(numel(G.clampedNodes),3),'AbsTol',1e-12);
        end
    end
end
