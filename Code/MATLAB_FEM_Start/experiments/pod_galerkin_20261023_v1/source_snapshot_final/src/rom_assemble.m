function [K,f,m,timing]=rom_assemble(mesh,x)
%rom_assemble - Assemble full structural matrices on the mapped common mesh
%   [K,F,M,TIMING] = rom_assemble(MESH,X) returns the free-DOF system.
%   Full unconstrained matrices are assembled and eliminated exactly once.
%   See also assembleFEMatrices, fegeometry
t=tic;
nodes=[x(1)*(mesh.nodes(1,:)-.5);x(2)*(mesh.nodes(2,:)-.5);x(3)*mesh.nodes(3,:)];
g=fegeometry(nodes',mesh.elements');
assert(isequal(g.Mesh.Elements,mesh.elements));
assert(isequal(g.Mesh.Nodes,nodes));
m=femodel(AnalysisType="structuralStatic",Geometry=g);
m.MaterialProperties=materialProperties(YoungsModulus=x(4),PoissonsRatio=x(5));
m.FaceBC(nearestFace(g,[-x(1)/2 0 x(3)/2]))=faceBC(Constraint="fixed");
m.FaceLoad(nearestFace(g,[x(1)/2 0 x(3)/2]))= ...
    faceLoad(SurfaceTraction=[0;0;x(6)/(x(2)*x(3))]);
timing.GeometrySeconds=toc(t); t=tic;
FEM=assembleFEMatrices(m,"none");
assert(size(FEM.K,1)==3*size(mesh.nodes,2),'Unexpected already-reduced matrices.');
fullK=FEM.K+FEM.A+FEM.Q; fullF=FEM.F+FEM.G;
resultant=sum(reshape(fullF,[],3),1);
assert(norm(resultant-[0 0 x(6)])/abs(x(6))<1e-10,'Incorrect load integration.');
assert(norm(FEM.H(:,mesh.free),'fro')==0,'Constraint/free-DOF mismatch.');
assert(all(FEM.R==0),'Nonhomogeneous lifting is not implemented.');
K=fullK(mesh.free,mesh.free); f=fullF(mesh.free);
timing.AssemblySeconds=toc(t);
end
