function localFile = prepareModalSmoke(destination)
%prepareModalSmoke Prepare fixed tiny inputs for a LATER explicitly requested FEM smoke.
% This function copies design/data subsets; it does not solve or train anything.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setupProject;
assert(~isfolder(destination),'modalstudy:Output','Use a new smoke input directory.');
mkdir(destination); design=table;
counts=[16 4 4]; roles=["train","val","test"];
for k=1:3
    a=load(fullfile(root,'data_generation','data','modal',roles(k)+'.mat'),'D'); D=a.D;
    idx=1:counts(k); D.id=D.id(idx); D.X=D.X(idx,:); D.frequencyHz=D.frequencyHz(idx,:); D.seconds=D.seconds(idx);
    save(fullfile(destination,roles(k)+'.mat'),'D');
    c=surrogate.contract("modal"); T=array2table(D.X,'VariableNames',cellstr(c.parameterNames));
    T=addvars(T,D.id,repmat(roles(k),numel(idx),1),'Before',1,'NewVariableNames',{'id','split'});
    design=[design;T]; %#ok<AGROW>
end
writetable(design,fullfile(destination,'design.csv'));
old=readtable(fullfile(root,'..','Praesentation','daten','modal_test_vorhersagen.csv'));
old=old(ismember(old.id,D.id),:); writetable(old,fullfile(destination,'history.csv'));
local=struct('training_file',fullfile(destination,'train.mat'),'validation_file',fullfile(destination,'val.mat'), ...
    'test_file',fullfile(destination,'test.mat'),'design_file',fullfile(destination,'design.csv'), ...
    'presentation_file',fullfile(destination,'history.csv'),'output_dir',fullfile(destination,'run'));
localFile=fullfile(destination,'smoke.local.json'); writelines(jsonencode(local,PrettyPrint=true),localFile);
end
