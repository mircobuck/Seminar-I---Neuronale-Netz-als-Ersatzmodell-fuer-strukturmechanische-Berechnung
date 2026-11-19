function data = makeContractData(split)
%makeContractData Create a small static fixture with explicit field ordering.
c=surrogate.contract("static");
data=struct('contractVersion',c.version,'modality',c.task,'split',string(split), ...
    'caseIds',[101;102],'inputParameters',[1 2 3 4 5 6;2 3 4 5 6 7], ...
    'parameterNames',c.parameterNames,'parameterUnits',c.parameterUnits);
data.displacementFields=[ones(1575,1),2*ones(1575,1)];
data.normalizedGridCoordinates=c.grid;
data.displacementComponentWeights=ones(1575,1)/525;
end
