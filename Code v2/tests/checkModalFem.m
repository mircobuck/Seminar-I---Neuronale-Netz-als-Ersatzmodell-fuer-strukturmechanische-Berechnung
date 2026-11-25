function checkModalFem(outputDirectory)
%checkModalFem EXPLICIT costly preflight; never invoked by the normal unit suite.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(root); setupProject;
assert(~isfolder(outputDirectory),'modalstudy:Output','Use a new preflight directory.');
data=surrogate.loadDataset(fullfile(root,'data_generation','data','modal','train.mat'));
ids=[910349;910037;910159]; [found,idx]=ismember(ids,data.caseIds);
assert(all(found),'modalstudy:Ids','Representative training cases are missing.');
errors=zeros(3,6); seconds=zeros(3,1);
fem=struct('meshDivisor',3,'geometricOrder',"quadratic");
for k=1:3
    value=solve_modal_case(data.inputParameters(idx(k),:),fem);
    errors(k,:)=abs(value.frequencyHz-data.frequencyHz(idx(k),:))./data.frequencyHz(idx(k),:);
    seconds(k)=value.seconds;
end
mkdir(outputDirectory);
modalstudy.artifact(fullfile(outputDirectory,'fem_preflight.mat'),struct('ids',ids,'relativeErrors',errors,'seconds',seconds));
assert(all(errors<=1e-5,'all'),'modalstudy:FemMismatch','Resolve reference discrepancies before study execution.');
writelines("All six frequencies agree within 1e-5 for each of three training cases.",fullfile(outputDirectory,'preflight.complete'));
end
