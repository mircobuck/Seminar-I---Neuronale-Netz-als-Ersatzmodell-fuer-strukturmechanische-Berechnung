function runRepairedEvaluation()
% Resume the frozen test study with separately documented evaluation repair.
repair=fileparts(mfilename('fullpath')); out=fileparts(repair); root=fileparts(fileparts(out));
studyRoot=fullfile(root,'studies','static_gpr_v1'); addpath(root,studyRoot,repair);
studyVerify(root,studyRoot,out); studyCheckFrozen(out); studyVerifyRepair(out);
cfg=jsondecode(fileread(fullfile(studyRoot,'study_config.json')));
fprintf('START repaired evaluation %s\n',string(datetime('now')));
studyEvaluationRepaired(root,out,cfg);
studyVerify(root,studyRoot,out); studyCheckFrozen(out); studyVerifyRepair(out);
fprintf('FINISHED repaired evaluation; START report %s\n',string(datetime('now')));
studyReportRepaired(out,cfg);
python=fullfile(getenv('LOCALAPPDATA'),'Programs','Python','Python312','python.exe');
command=sprintf('"%s" "%s" "%s"',python,fullfile(studyRoot,'studyPlots.py'),out);
[status,message]=system(command); assert(status==0,'study:PlotFailed','%s',message);
analysis=fullfile(out,'source_snapshot','post_analysis','analysis_static_gpr.py');
command=sprintf('"%s" "%s" "%s"',python,analysis,out);
[status,message]=system(command); assert(status==0,'study:AnalysisFailed','%s',message);
studyVerify(root,studyRoot,out); studyCheckFrozen(out); studyVerifyRepair(out);
writelines("repaired evaluation and report completed",fullfile(repair,'repair.complete'));
fprintf('FINISHED repaired evaluation and report %s\n',string(datetime('now')));
end
