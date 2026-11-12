function summary = summarizeDirectNeuralDeflection(outputDir)
%summarizeDirectNeuralDeflection Compare maximum displacement magnitudes.
%   Norm sqrt(ux^2+uy^2+uz^2) at each of the 525 grid points, in metres.
%   Uses only the same validation cases as the depth study, never test data.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root);
if nargin<1
    outputDir=fullfile(root,'experiments','direct_neural_depth_adam_20261111');
end
data=surrogate.loadDataset(fullfile(root,'experiments', ...
    'pod_mlp_fresh_validation_128_20261108','reference_data','static','val.mat'));
request=struct('inputParameters',data.inputParameters,'caseIds',data.caseIds, ...
    'parameterNames',data.parameterNames,'parameterUnits',data.parameterUnits);
reference=maximumMagnitude(data.displacementFields);
rows=table();
for method=["mlp","rbf"]
    for depth=1:3
        for seed=42:44
            file=fullfile(outputDir,'models',sprintf('%s_depth%d_seed%d.mat',method,depth,seed));
            model=surrogate.loadModel(file);
            prediction=surrogate.predictModel(model,request);
            predicted=maximumMagnitude(prediction.displacementFields);
            n=numel(data.caseIds);
            rows=[rows;table(repmat(method,n,1),repmat(depth,n,1),repmat(seed,n,1), ...
                data.caseIds,predicted,reference, ...
                'VariableNames',{'Method','Depth','Seed','CaseId', ...
                'PredictedMaxMagnitudeM','ReferenceMaxMagnitudeM'})]; %#ok<AGROW>
        end
    end
end
writetable(rows,fullfile(outputDir,'deflection_by_case.csv'));
summary=groupsummary(rows,["Method","Depth"],"max", ...
    ["PredictedMaxMagnitudeM","ReferenceMaxMagnitudeM"]);
writetable(summary,fullfile(outputDir,'maximum_deflection.csv'));
disp(summary);
end

function values = maximumMagnitude(fields)
vectors=reshape(fields,525,3,[]);
values=reshape(max(sqrt(sum(vectors.^2,2)),[],1),[],1);
end
