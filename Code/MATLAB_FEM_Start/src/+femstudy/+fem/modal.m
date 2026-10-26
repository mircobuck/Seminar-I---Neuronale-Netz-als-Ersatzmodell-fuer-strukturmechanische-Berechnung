function out = modal(x, divisor)
%MODAL Undamped, unprestressed cantilever modes; x=[L b h E nu rho].
assert(numel(x)==6 && all(isfinite(x)) && all(x([1:4 6])>0));
t=tic; L=x(1); b=x(2); h=x(3);
g=multicuboid(L,b,h);
m=femodel(AnalysisType="structuralModal",Geometry=g);
m.MaterialProperties=materialProperties(YoungsModulus=x(4),PoissonsRatio=x(5),MassDensity=x(6));
m.FaceBC(nearestFace(g,[-L/2 0 h/2]))=faceBC(Constraint="fixed");
m=generateMesh(m,Hmax=min(b,h)/divisor,GeometricOrder="quadratic");
upper=2000;
while true
    r=solve(m,FrequencyRange=[-1 2*pi*upper]);
    f=r.NaturalFrequencies(:)/(2*pi);
    if numel(f)>=8, break; end
    upper=2*upper;
    assert(upper<=128000,'femstudy:modal:InsufficientModes','Fewer than eight modes in search range.');
end
out.schema="modal-v1"; out.parameters=x; out.divisor=divisor;
out.frequencyHz=f; out.upperHz=upper; out.nodes=m.Geometry.Mesh.Nodes;
out.elements=m.Geometry.Mesh.Elements;
out.rawModes=cat(1,r.ModeShapes.ux,r.ModeShapes.uy,r.ModeShapes.uz);
[xi,w]=reference_grid([21 5 5]);
xyz=[L*(xi(1,:)-.5);b*(xi(2,:)-.5);h*xi(3,:)];
P=rom_observation(out.nodes,out.elements,xyz);
n=size(out.nodes,2); U=out.rawModes;
Q=[P*U(1:n,:);P*U(n+1:2*n,:);P*U(2*n+1:3*n,:)];
norms=sqrt(sum(w(:).*Q.^2,1));
assert(all(norms>0)); out.queryModes=Q./norms;
out.queryWeights=w(:); out.queryCoordinates=xi;
out.nativeSpace="case-specific quadratic mesh; component-block order";
out.querySpace="normalized grid 21x5x5; component-block order";
out.seconds=toc(t);
end
