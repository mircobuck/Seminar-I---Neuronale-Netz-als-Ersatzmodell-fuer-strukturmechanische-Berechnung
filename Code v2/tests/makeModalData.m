function data = makeModalData(split,n,offset)
%makeModalData Small deterministic, full-rank synthetic frequency fixture.
if nargin<2, n=12; end
if nargin<3, offset=0; end
prior=rng; cleanup=onCleanup(@()rng(prior)); %#ok<NASGU>
rng(123+offset,'twister'); U=rand(n,6);
c=surrogate.contract("modal");
X=[.6+.6*U(:,1),.06+.04*U(:,2),.08+.06*U(:,3), ...
    70e9+140e9*U(:,4),.25+.1*U(:,5),2700+6200*U(:,6)];
F=100*(1:6)+10*U;
data=struct('schema',"modal-natural-frequencies-v1",'contractVersion',c.version, ...
    'modality',"modal",'split',string(split),'caseIds',(1:n)'+offset, ...
    'inputParameters',X,'parameterNames',c.parameterNames,'parameterUnits',c.parameterUnits, ...
    'frequencyHz',F,'modeIndices',c.modeIndices,'computationTimeSeconds',ones(n,1));
end
