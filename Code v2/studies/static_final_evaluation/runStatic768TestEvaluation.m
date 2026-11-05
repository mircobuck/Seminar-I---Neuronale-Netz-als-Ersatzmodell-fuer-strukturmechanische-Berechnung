function result = runStatic768TestEvaluation(outputDir)
%runStatic768TestEvaluation Evaluate all 12 768-case POD-MLP architectures.
%   Each architecture's three saved seeds are evaluated on the fixed static
%   test split. No models are retrained and no plots are exported.
if nargin<2, trainingCases=768; end
result=runStaticTrainingTestEvaluation(outputDir,trainingCases);
end
