function finalize_restfield_learning_curve
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); out=fullfile(root,'experiments','active','restfield_learning_curve_20261028_v1');
run_restfield_learning_curve('evaluate');
files=dir(fullfile(out,'runs','*.mat')); ledger=table; history=table;
for k=1:numel(files)
 a=load(fullfile(files(k).folder,files(k).name),'value'); v=a.value;
 if v.status=="completed", err=""; stop=v.stopReason; seconds=v.trainingSeconds; else, err=v.error; stop="exception"; seconds=v.elapsedSeconds; end
 row=table(string(files(k).name),v.n,v.kind,v.seed,v.pilot,v.status,seconds,string(stop),string(err),'VariableNames',{'Artifact','N','Model','Seed','Pilot','Status','Seconds','StopReason','Error'}); ledger=[ledger;row]; %#ok<AGROW>
 if v.status=="completed" && isfield(v.history,'iteration')
  h=v.history; count=numel(h.iteration); if count>0
   epoch=nan(count,1); loss=nan(count,1); if numel(h.epoch)==count, epoch=h.epoch; end; if numel(h.trainingLoss)==count, loss=h.trainingLoss; end
   row=table(repmat(string(files(k).name),count,1),h.iteration(:),epoch(:),loss(:),'VariableNames',{'Artifact','Iteration','Epoch','Loss'}); history=[history;row]; %#ok<AGROW>
  end
 end
end
writetable(ledger,fullfile(out,'attempt_ledger.csv')); writetable(history,fullfile(out,'training_history.csv'));
files=dir(fullfile(out,'development_cases','*.mat')); refs=table;
for k=1:numel(files)
 a=load(fullfile(files(k).folder,files(k).name),'value'); v=a.value; err=""; if v.status=="failed", err=v.error; end
 row=table(string(files(k).name),v.id,v.status,v.seconds,err,'VariableNames',{'Artifact','ID','Status','Seconds','Error'}); refs=[refs;row]; %#ok<AGROW>
end
writetable(refs,fullfile(out,'development_fem_ledger.csv'));
fprintf('Models: %d attempts; FEM: %d attempts, %.2f seconds.\n',height(ledger),height(refs),sum(refs.Seconds));
end
