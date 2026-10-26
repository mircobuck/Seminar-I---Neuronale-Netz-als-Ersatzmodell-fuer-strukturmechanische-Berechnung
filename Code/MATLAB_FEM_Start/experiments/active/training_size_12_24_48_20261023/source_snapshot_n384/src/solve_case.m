function out=solve_case(x,c)
% Full 3D linear elasticity, uniform end traction, clamp at x=-L/2.
L=x(1); b=x(2); h=x(3); E=x(4); nu=x(5); F=x(6);
ticID=tic;
g=multicuboid(L,b,h);
left=nearestFace(g,[-L/2 0 h/2]);
right=nearestFace(g,[L/2 0 h/2]);
m=femodel(AnalysisType="structuralStatic",Geometry=g);
m.MaterialProperties=materialProperties(YoungsModulus=E,PoissonsRatio=nu);
m.FaceBC(left)=faceBC(Constraint="fixed");
m.FaceLoad(right)=faceLoad(SurfaceTraction=[0;0;F/(b*h)]);
m=generateMesh(m,Hmax=min(b,h)/c.meshDivisor, ...
    GeometricOrder=c.geometricOrder);
R=solve(m);
[xi,w]=reference_grid(c.gridSize);
xyz=[L*(xi(1,:)-0.5);b*(xi(2,:)-0.5);h*xi(3,:)];
U=interpolateDisplacement(R,xyz);
out.S=[U.ux(:);U.uy(:);U.uz(:)];
assert(all(isfinite(out.S)),'Nonfinite displacement interpolation.');
% Enforce known homogeneous clamp in the common representation.
fixed=find(xi(1,:)==0); nq=size(xi,2);
out.S([fixed fixed+nq fixed+2*nq])=0;
T=interpolateDisplacement(R,[L/2;0;h/2]);
V=reshape(out.S,nq,3);
out.Y=[T.uz,max(sqrt(sum(V.^2,2)))]; % tip uz, grid max |u|
assert(all(isfinite(out.Y)));
assert(out.Y(1)<0,'Check traction and clamp orientation.');
assert(out.Y(2)/L<c.maxDeflectionRatio, ...
    'Small-deformation guard exceeded; review parameter domain.');
out.x=x; out.xi=xi; out.w=w;
out.nNodes=size(m.Geometry.Mesh.Nodes,2);
out.meshDivisor=c.meshDivisor;
if c.saveRawMesh
    out.nodes=m.Geometry.Mesh.Nodes;
    out.elements=m.Geometry.Mesh.Elements;
    out.displacement=[R.Displacement.ux(:), ...
        R.Displacement.uy(:),R.Displacement.uz(:)];
end
out.seconds=toc(ticID);
end
