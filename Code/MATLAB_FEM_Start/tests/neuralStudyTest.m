classdef neuralStudyTest < matlab.unittest.TestCase
    methods(Test)
        function leakageRejected(t)
            D=struct('id',[1;2]);
            t.verifyError(@()femstudy.models.fitNeural(D,D,'pod',struct), ...
                'femstudy:split:Leakage');
        end
        function fieldUnits(t)
            S=ones(6,2); H=2*S; w=ones(6,1)/2;
            r=femstudy.metrics.field(S,H,w,[1 2 3;2 3 4]);
            t.verifyEqual(r.relative,ones(2,1),AbsTol=1e-12);
            t.verifyEqual(r.absoluteRMS,sqrt(3)*ones(2,1),AbsTol=1e-12);
            t.verifyEqual(r.physicalL2,sqrt([18;72]),AbsTol=1e-12);
        end
        function zeroComponent(t)
            S=[zeros(2,1);ones(4,1)];
            r=femstudy.metrics.field(S,S,ones(6,1)/2,[1 1 1]);
            t.verifyTrue(isnan(r.componentRelative(1)));
            t.verifyEqual(r.componentAbsolute,zeros(1,3),AbsTol=0);
        end
        function densityMustVary(t)
            D=struct('id',[1;2],'X',ones(2,6),'F',ones(2,6));
            V=D; V.id=[3;4];
            t.verifyError(@()femstudy.models.fitNeural(D,V,'frequency',struct), ...
                'femstudy:density:Constant');
        end
        function weightedProjection(t)
            S=[1 2 3;2 4 6;3 6 9]; w=[.2;.3;.5];
            P=pod_fit(S,w,1); reconstructed=P.mean+P.V*pod_encode(P,S)';
            t.verifyEqual(reconstructed,S,AbsTol=1e-12);
            t.verifyEqual(P.V'*(w.*P.V),1,AbsTol=1e-12);
        end
    end
end
