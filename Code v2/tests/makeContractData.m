function data = makeContractData(task,split)
%makeContractData Create synthetic data for contract tests.
c=surrogate.contract(task);
data=struct('contractVersion',c.version,'modality',c.task,'split',string(split), ...
    'caseIds',[101;102],'inputParameters',[1 2 3 4 5 6;2 3 4 5 6 7], ...
    'parameterNames',c.parameterNames,'parameterUnits',c.parameterUnits);
if c.task=="static"
    data.displacementFields=[ones(1575,1),2*ones(1575,1)];
    data.normalizedGridCoordinates=c.grid;
    data.displacementComponentWeights=ones(1575,1)/525;
else
    data.naturalFrequenciesHz=[10 20 30 40 50 60;20 30 40 50 60 70];
    data.modeIndices=(1:6)'; data.frequencyUnit="Hz";
end
end
