function [dataset, design] = loadFemDataset(filePath)
%loadFemDataset - Load a FEM split with descriptive field names
%   DATASET = loadFemDataset(FILEPATH) loads a static displacement split
%   without changing the MAT-file or the original data values.
%   [DATASET, DESIGN] also returns the associated design table.

loaded = load(filePath, 'D');
source = loaded.D;
dataset.schema = source.schema;
dataset.modality = source.modality;
dataset.split = source.split;
dataset.caseIds = source.id;
dataset.inputParameters = source.X;
% Parameter names come from the design belonging to this split.
designPath = fullfile(fileparts(filePath), 'design.csv');
design = readtable(designPath, 'TextType', 'string');
parameterNames = string(design.Properties.VariableNames);
parameterNames = parameterNames(~ismember(parameterNames, ["id", "split"]));
assert(numel(parameterNames) == size(source.X,2), ...
    'femdata:load:ParameterCount', 'Design and dataset dimensions differ.');
dataset.parameterNames = parameterNames;
dataset.computationTimeSeconds = source.seconds;

assert(string(source.schema)=="static-displacement-fields-v1", ...
    'femdata:load:UnknownSchema','Unsupported static dataset schema: %s.',string(source.schema));
dataset.displacementFields = source.S;
dataset.tipDisplacementZ = source.Y(:,1);
dataset.maxDisplacementMagnitudeOnGrid = source.Y(:,2);
dataset.normalizedGridCoordinates = source.xi;
dataset.displacementComponentWeights = source.w;
dataset.meshNodeCounts = source.nodes;
end
