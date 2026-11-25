% Two-study run. Stop on the first failed preflight or phase.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
cd(root); addpath(root); setupProject; addpath(fullfile(root,'tests'));
control=fullfile(root,'experiments','comparison_dual_20261124');
status=fullfile(control,'status.txt');
try
    writelines("modal_fem_preflight",status);
    fprintf('BEGIN modal FEM preflight %s\n',string(datetime('now')));
    checkModalFem(fullfile(control,'modal_preflight'));
    writelines("modal_smoke",status);
    fprintf('BEGIN modal smoke %s\n',string(datetime('now')));
    local=prepareModalSmoke(fullfile(control,'modal_smoke'));
    runModalWorkflowSmoke("workflows/modal_comparison/configs/smoke.json",local);
    studies={"static","modal"};
    for i=1:numel(studies)
        study=studies{i}; local=string(fullfile(control,study+".local.json"));
        if study=="static"
            runner=@runStaticStudy; cfg="workflows/static_comparison/configs/study.json";
        else
            runner=@runModalStudy; cfg="workflows/modal_comparison/configs/study.json";
        end
        for phase=["init","generate","tune","train","freeze","evaluate","benchmark","report"]
            writelines(study+"_"+phase,status);
            fprintf('BEGIN %s %s %s\n',study,phase,string(datetime('now')));
            timer=tic; runner(phase,cfg,local);
            fprintf('END %s %s %.3f s %s\n',study,phase,toc(timer),string(datetime('now')));
        end
    end
    writelines("complete",status); fprintf('BOTH STUDIES COMPLETED\n');
catch err
    message=string(getReport(err,'extended','hyperlinks','off'));
    writelines(message,fullfile(control,'failure.txt'));
    previous=strtrim(fileread(status)); writelines("failed: "+string(previous),status);
    fprintf(2,'%s\n',message); rethrow(err);
end
