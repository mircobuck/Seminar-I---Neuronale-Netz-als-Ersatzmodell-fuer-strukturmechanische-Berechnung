function export_modal_training_history
%EXPORT_MODAL_TRAINING_HISTORY Export pilot, CV, and final MLP histories.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
out=fullfile(root,'experiments','active','modal_frequency_optimizer_20261029_v1');
files=dir(fullfile(out,'runs','*_attempt*.mat'));
files=files(~endsWith(string({files.name}),'.started.mat')); T=table;
for k=1:numel(files)
    a=load(fullfile(files(k).folder,files(k).name),'value'); r=a.value;
    if r.status~="completed" || r.context.optimizer=="gpr", continue; end
    h=r.history; n=numel(h.iteration); if n==0, continue; end
    epoch=nan(n,1); loss=nan(n,1);
    if numel(h.epoch)==n, epoch=h.epoch(:); end
    if numel(h.trainingLoss)==n, loss=h.trainingLoss(:); end
    C=table(repmat(string(files(k).name),n,1),repmat(r.context.stage,n,1), ...
        repmat(r.context.optimizer,n,1),repmat(r.context.fold,n,1), ...
        repmat(r.context.seed,n,1),h.iteration(:),epoch,loss, ...
        VariableNames={'Artifact','Stage','Optimizer','Fold','Seed','Iteration','Epoch','Loss'});
    T=[T;C]; %#ok<AGROW>
end
path=fullfile(out,'all_training_history.csv'); tmp=string(tempname(out))+".csv";
writetable(T,tmp);
if isfile(path)
    assert(isequal(fileread(path),fileread(tmp)),'History export conflict');
    delete(tmp);
else
    [ok,msg]=movefile(tmp,path); assert(ok,msg);
end
end
