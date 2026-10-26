function tests=test_beam_field_hybrid
tests=functiontests(localfunctions);
end
function testBeamKinematics(t)
[xi,~]=reference_grid([21 5 5]);
x=[1 .08 .1 1e11 .3 -500]; n=size(xi,2);
u=femstudy.fem.beamField(x,xi);
tip=find(all(xi==[1;.5;.5],1));
verifyEqual(t,u(2*n+tip),beam_tip(x),'AbsTol',1e-15);
fixed=find(xi(1,:)==0);
verifyEqual(t,u([fixed fixed+n fixed+2*n]),zeros(3*numel(fixed),1));
scaled=femstudy.fem.beamField([x;x.*[1 1 1 2 1 2]],xi);
verifyEqual(t,scaled(:,1),scaled(:,2),'AbsTol',1e-15);
end
function testDisjointSplits(t)
d=struct('id',[1;2],'X',zeros(2,6),'S',zeros(3,2),'xi',zeros(3,1),'w',ones(3,1));
verifyError(t,@()femstudy.models.fitBeamField(d,d),'femstudy:split:Leakage');
end
