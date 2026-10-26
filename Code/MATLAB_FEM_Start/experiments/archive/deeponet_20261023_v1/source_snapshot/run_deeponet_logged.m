function run_deeponet_logged(stage,N,seed)
%run_deeponet_logged - Preserve execution logs and explicit failure records.
if nargin<2, N=12; end
if nargin<3, seed=42; end
out=fullfile(fileparts(mfilename('fullpath')),'experiments','deeponet_20261023_v1');
logs=fullfile(out,'logs'); if ~isfolder(logs), mkdir(logs); end
started=datetime('now',Format='yyyy-MM-dd HH:mm:ss'); tick=tic;
status="PASS"; diagnostic="";
try
    transcript=evalc('run_deeponet_study(stage,N,seed)');
catch exception
    status="FAIL"; diagnostic=string(getReport(exception,'extended',Hyperlinks='off'));
    transcript=char(diagnostic);
end
file=fullfile(logs,string(stage)+"_n"+N+"_seed"+seed+"_"+ ...
    string(datetime('now',Format='yyyyMMdd_HHmmss_SSS'))+".txt");
writelines(string(transcript),file);
event=table(string(started),string(stage),N,seed,status,toc(tick),diagnostic, ...
    'VariableNames',{'Started','Stage','TrainingCases','Seed','Status','Seconds','Diagnostic'});
events=fullfile(out,'events.csv');
if isfile(events), event=[readtable(events,TextType="string");event]; end
writetable(event,events); disp(transcript);
assert(status=="PASS",'%s',diagnostic);
end
