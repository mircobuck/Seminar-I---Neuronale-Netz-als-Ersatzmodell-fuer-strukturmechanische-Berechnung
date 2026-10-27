function model = fitDeepONet(train,val,options,folder)
%FITDEEPONET Package adapter for the existing resumable DeepONet trainer.
% The historical implementation remains the numerical implementation; this
% adapter gives the current study an explicit package entry point.
arguments
    train (1,1) struct
    val (1,1) struct
    options (1,1) struct
    folder (1,1) string
end
assert(isempty(intersect(train.id,val.id)), ...
    'femstudy:split:Leakage','Training and validation overlap.');
required = {'width','latent','epochs','learnRate','validateEvery','patience','seed'};
for k = 1:numel(required)
    assert(isfield(options,required{k}), ...
        'femstudy:deeponet:Option','Missing option: %s',required{k});
end
[model,info] = fit_deeponet(train,val,options,folder);
model.schema = "deeponet-v2-study-adapter";
model.trainingInfo = info;
end
