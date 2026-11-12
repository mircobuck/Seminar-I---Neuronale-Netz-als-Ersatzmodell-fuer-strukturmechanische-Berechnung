function [state,report] = fit(data,config)
%fit Create a synthetic constant-output adapter for contract tests.
if string(data.modality)=="static"
    state.constant=mean(data.displacementFields,2);
else
    state.constant=mean(data.naturalFrequenciesHz,1);
end
state.task=string(data.modality);
report=struct('method',"dummy",'note',"Contract example; not a scientific model", ...
    'trainingCount',size(data.inputParameters,1),'seed',config.seed);
end
