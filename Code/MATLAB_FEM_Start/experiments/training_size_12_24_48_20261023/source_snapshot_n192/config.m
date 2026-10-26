function c=config(mode)
% SI units. Conservative initial domain, not a material calibration.
if nargin==0, mode="pilot"; end
c.mode=string(mode); c.schema=1;
c.root=fileparts(mfilename('fullpath'));
c.names={'L_m','b_m','h_m','E_Pa','nu','Fz_N'};
c.lower=[0.6,0.06,0.08,70e9,0.25,-1000];
c.upper=[1.2,0.10,0.14,210e9,0.35,-100];
switch c.mode
    case "smoke", c.counts=[12 6 6]; c.seed=1001;
    case "pilot", c.counts=[64 32 64]; c.seed=1002;
    otherwise, error('Use smoke or pilot.');
end
c.gridSize=[21 5 5]; c.meshDivisor=3;
c.geometricOrder="quadratic"; c.saveRawMesh=true;
c.maxDeflectionRatio=0.02;
c.ranks=[2 4 8 12 20]; c.rbfLambda=[0 1e-8 1e-6 1e-4];
c.useMLP=true; c.mlpWidths=[32 64]; c.epochs=300;
c.modelSeed=42;
c.design=fullfile(c.root,'designs',c.mode+'.csv');
c.out=fullfile(c.root,'runs',c.mode);
end
