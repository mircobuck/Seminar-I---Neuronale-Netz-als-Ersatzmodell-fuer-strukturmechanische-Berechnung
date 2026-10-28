function output=predict_new(mode,name,x)
% Example: predict_new("pilot","POD_GP",[1 .08 .12 140e9 .30 -500])
c=config(mode); addpath(genpath(fullfile(c.root,'modelle')));
a=load(fullfile(c.out,'models.mat')); trained=a.meta.config;
assert(size(x,2)==6,'Expected 6 parameter columns.');
assert(all(isfinite(x),'all'));
if any(x<trained.lower | x>trained.upper,'all')
    warning('Outside training box: this is extrapolation, accuracy unknown.');
end
idx=find(cellfun(@(m)m.name==string(name),a.models),1);
assert(~isempty(idx),'Model name not found.');
output=predict_surrogate(a.models{idx},x);
end
