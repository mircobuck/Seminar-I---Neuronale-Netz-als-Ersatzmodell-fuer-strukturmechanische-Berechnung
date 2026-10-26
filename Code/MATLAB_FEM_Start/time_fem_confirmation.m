function time_fem_confirmation()
% Repeat one reference case; measure actual mesh, solve, and grid interpolation.
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','static_confirmation_v1');a=load(fullfile(out,'design.mat'));x=a.design.X(1,:);
L=x(1);b=x(2);h=x(3);E=x(4);nu=x(5);F=x(6); t=zeros(5,4);
for j=0:5
 alltime=tic; g=multicuboid(L,b,h);
 m=femodel(AnalysisType="structuralStatic",Geometry=g);
 m.MaterialProperties=materialProperties(YoungsModulus=E,PoissonsRatio=nu);
 m.FaceBC(nearestFace(g,[-L/2 0 h/2]))=faceBC(Constraint="fixed");
 m.FaceLoad(nearestFace(g,[L/2 0 h/2]))=faceLoad(SurfaceTraction=[0;0;F/(b*h)]);
 s=tic;m=generateMesh(m,Hmax=min(b,h)/3,GeometricOrder="quadratic"); mesh=toc(s);
 s=tic;R=solve(m);solution=toc(s);
 [xi,~]=reference_grid([21 5 5]);xyz=[L*(xi(1,:)-.5);b*(xi(2,:)-.5);h*xi(3,:)];
 s=tic;U=interpolateDisplacement(R,xyz);T=interpolateDisplacement(R,[L/2;0;h/2]);interpolation=toc(s); %#ok<NASGU>
 elapsed=toc(alltime);
 if j>0,t(j,:)=[mesh solution interpolation elapsed];end
end
metadata=struct('id',a.design.id(1),'repetitions',5,'warmup',1,'units','seconds','scope','setup+mesh+solve+grid and tip interpolation');
save(fullfile(out,'fem_timing.mat'),'t','metadata');writematrix(t,fullfile(out,'fem_timing.csv'));disp(mean(t,1));
end
