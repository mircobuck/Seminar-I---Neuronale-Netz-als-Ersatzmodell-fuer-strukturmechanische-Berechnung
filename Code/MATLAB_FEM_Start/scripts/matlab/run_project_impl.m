function run_project_impl(mode,stage)
% run_project("smoke","generate") then train then evaluate.
if nargin<1, mode="smoke"; end
if nargin<2, stage="generate"; end
c=config(mode); addpath(genpath(fullfile(c.root,'modelle')));
if ~isfolder(c.out), mkdir(c.out); end
switch string(stage)
    case "generate", generate_dataset(c);
    case "train", train_models(c);
    case "evaluate", evaluate_models(c);
    otherwise, error('stage: generate, train, evaluate');
end
end
