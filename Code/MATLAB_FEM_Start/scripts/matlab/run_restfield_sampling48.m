function run_restfield_sampling48(stage)
%RUN_RESTFIELD_SAMPLING48 Run a frozen 48-case sampling comparison stage.
if nargin==0
    disp('Stages: prepare, pilot, data, campaign, evaluate, audit');
    return
end
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
femstudy.studies.sampling48(root,string(stage));
end
