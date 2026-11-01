function dataset = loadFemDataset(filePath)
%loadFemDataset - Load a FEM split with descriptive field names
%   DATASET = loadFemDataset(FILEPATH) loads a static or modal split
%   without changing the MAT-file or the original data values.

loaded = load(filePath, 'D');
assert(isfield(loaded, 'D'), 'femdata:load:MissingDataset', ...
    'The MAT-file does not contain the D structure.');
source = loaded.D;
dataset.schema = source.schema;
dataset.modality = source.modality;
dataset.split = source.split;
dataset.caseIds = source.id;
dataset.inputParameters = source.X;
% Die Spaltennamen stammen aus dem Design, das zu diesem Split geh?rt.
designPath = fullfile(fileparts(filePath), 'design.csv');
assert(isfile(designPath), 'femdata:load:MissingDesign', ...
    'Cannot find the design file: %s', designPath);
design = readtable(designPath, 'TextType', 'string');
parameterNames = string(design.Properties.VariableNames);
parameterNames = parameterNames(~ismember(parameterNames, ["id", "split"]));
assert(numel(parameterNames) == size(source.X,2), ...
    'femdata:load:ParameterCount', 'Design and dataset dimensions differ.');
dataset.parameterNames = parameterNames;
dataset.computationTimeSeconds = source.seconds;

switch string(source.schema)
    case "static-displacement-fields-v1"
        dataset.displacementFields = source.S;
        dataset.tipDisplacementZ = source.Y(:,1);
        dataset.maxDisplacementMagnitudeOnGrid = source.Y(:,2);
        dataset.normalizedGridCoordinates = source.xi;
        dataset.displacementComponentWeights = source.w;
        dataset.meshNodeCounts = source.nodes;
    case "modal-natural-frequencies-v1"
        dataset.naturalFrequenciesHz = source.frequencyHz;
        dataset.modeIndices = source.modeIndices;
        dataset.frequencyUnit = source.frequencyUnit;
    otherwise
        error('femdata:load:UnknownSchema', ...
            'Unsupported dataset schema: %s', string(source.schema));
end
end
