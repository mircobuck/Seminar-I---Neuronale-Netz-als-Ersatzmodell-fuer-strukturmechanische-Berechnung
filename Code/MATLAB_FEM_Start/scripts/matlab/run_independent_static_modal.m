function run_independent_static_modal(stage)
%RUN_INDEPENDENT_STATIC_MODAL Run a preregistered independent evaluation.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
femstudy.studies.independentStaticModal(root,string(stage));
end
