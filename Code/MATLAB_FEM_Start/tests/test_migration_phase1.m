function tests=test_migration_phase1
tests=functiontests(localfunctions);
end
function testSpatialIdentity(t)
a=struct('schema',1,'spaceID','native-a','units','m','ordering','xyz-block','constraints','clamped');
b=a; femstudy.data.assertCompatible(a,b); b.spaceID='native-b';
verifyError(t,@()femstudy.data.assertCompatible(a,b),'femstudy:space:Incompatible');
end
function testFrequencySorting(t)
p=struct('rawHz',[3 1 2],'sortedHz',[1 2 3],'orderViolation',true);
r=femstudy.metrics.frequency(p,[1 2 3],1e-8);
verifyEqual(t,r.relativeSorted,[0 0 0]); verifyGreaterThan(t,mean(r.relativeRaw),0);
verifyEqual(t,r.orderViolationFraction,1);
end
function testLeakage(t)
tr=struct('id',[1;2],'X',ones(2,6),'F',ones(2,6)); va=tr;
verifyError(t,@()femstudy.models.fitFrequency(tr,va),'femstudy:split:Leakage');
end
function testClusterRotationAndSign(t)
a.queryCoordinates=[0 1]; a.queryWeights=ones(3,1); a.queryModes=eye(3);
a.frequencyHz=[100;100.2;200]; b=a; theta=.4;
b.queryModes(:,1:2)=a.queryModes(:,1:2)*[cos(theta) -sin(theta);sin(theta) cos(theta)];
b.queryModes(:,3)=-b.queryModes(:,3);
% The actual convergence routine requires six target modes, so use an 8-mode fixture.
a.queryCoordinates=1:8; a.queryWeights=ones(8,1); a.queryModes=eye(8);
a.frequencyHz=[100;100.2;200;300;400;500;700;900]; b=a;
b.queryModes(:,1:2)=a.queryModes(:,1:2)*[cos(theta) -sin(theta);sin(theta) cos(theta)];
b.queryModes(:,3)=-b.queryModes(:,3);
r=femstudy.fem.compareModes(a,b,.01); verifyTrue(t,r.pass);
verifyEqual(t,r.minimumSubspaceCosine,1,'AbsTol',1e-12);
end
