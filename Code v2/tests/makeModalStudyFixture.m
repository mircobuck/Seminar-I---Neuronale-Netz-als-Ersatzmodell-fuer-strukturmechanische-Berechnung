function [cfg,out,localFile] = makeModalStudyFixture(folder,root)
%makeModalStudyFixture Synthetic artifacts only; no real solver or study training.
source=fullfile(folder,'source'); mkdir(source);
train=makeModalData("train",16); val=makeModalData("val",4,100); test=makeModalData("test",4,200);
design=table;
for data={train,val,test}
    d=data{1}; D=struct('schema',d.schema,'modality',d.modality,'split',d.split, ...
        'id',d.caseIds,'X',d.inputParameters,'frequencyHz',d.frequencyHz, ...
        'frequencyUnit',"Hz",'modeIndices',d.modeIndices,'seconds',d.computationTimeSeconds);
    save(fullfile(source,d.split+'.mat'),'D');
    tab=array2table(d.inputParameters,'VariableNames',cellstr(d.parameterNames));
    tab=addvars(tab,d.caseIds,repmat(d.split,numel(d.caseIds),1),'Before',1,'NewVariableNames',{'id','split'});
    design=[design;tab]; %#ok<AGROW>
end
writetable(design,fullfile(source,'design.csv'));
[i,j]=ndgrid(1:4,1:6); F=test.frequencyHz(:);
old=table(test.caseIds(i(:)),j(:),F,F,strings(24,1),F,F,F,F,'VariableNames', ...
    {'id','mode','fem','analytic','analyticFamily','mlpMean','podMlpMean','mlpSeed42','podMlpSeed42'});
writetable(old,fullfile(source,'history.csv'));
science=jsondecode(fileread(fullfile(root,'workflows','modal_comparison','configs','smoke.json')));
science.reference_mode="reuse";
configFile=fullfile(folder,'science.json'); writelines(jsonencode(science),configFile);
local=struct('training_file',fullfile(source,'train.mat'),'validation_file',fullfile(source,'val.mat'), ...
    'test_file',fullfile(source,'test.mat'),'design_file',fullfile(source,'design.csv'), ...
    'presentation_file',fullfile(source,'history.csv'),'output_dir',fullfile(folder,'run'));
localFile=fullfile(folder,'local.json'); writelines(jsonencode(local),localFile);
cfg=modalstudy.configure(root,configFile,localFile);
out=runModalStudy("init",configFile,localFile);
runModalStudy("generate",configFile,localFile);
end
