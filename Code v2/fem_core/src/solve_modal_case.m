function out = solve_modal_case(x,c)
%solve_modal_case Six lowest undamped, unprestressed 3D cantilever frequencies.
assert(isnumeric(x) && isvector(x) && numel(x)==6 && isreal(x) && all(isfinite(x)) && ...
    all(x([1:4 6])>0) && x(5)>-1 && x(5)<.5,'modalfem:Inputs','Invalid L,b,h,E,nu,rho.');
assert(c.meshDivisor>=1 && c.meshDivisor==fix(c.meshDivisor) && string(c.geometricOrder)=="quadratic", ...
    'modalfem:Mesh','Expected positive divisor and quadratic elements.');
timer=tic; L=x(1); b=x(2); h=x(3);
g=multicuboid(L,b,h);
m=femodel(AnalysisType="structuralModal",Geometry=g);
m.MaterialProperties=materialProperties(YoungsModulus=x(4),PoissonsRatio=x(5),MassDensity=x(6));
m.FaceBC(nearestFace(g,[-L/2 0 h/2]))=faceBC(Constraint="fixed");
m=generateMesh(m,Hmax=min(b,h)/c.meshDivisor,GeometricOrder=c.geometricOrder);
upper=2000;
while true
    r=solve(m,FrequencyRange=[-1,2*pi*upper]);
    f=sort(r.NaturalFrequencies(:)/(2*pi));
    assert(isreal(f) && all(isfinite(f)) && all(f>0),'modalfem:Frequencies','Nonpositive or invalid frequency.');
    if numel(f)>=6, break; end
    assert(upper<128000,'modalfem:InsufficientModes','Fewer than six modes up to 128000 Hz.');
    upper=2*upper;
end
out=struct('frequencyHz',f(1:6)','modeIndices',(1:6)','frequencyUnit',"Hz", ...
    'parameters',x(:)','upperHz',upper,'modeCountReturned',numel(f), ...
    'meshDivisor',c.meshDivisor,'nodes',size(m.Geometry.Mesh.Nodes,2),'seconds',toc(timer));
end
