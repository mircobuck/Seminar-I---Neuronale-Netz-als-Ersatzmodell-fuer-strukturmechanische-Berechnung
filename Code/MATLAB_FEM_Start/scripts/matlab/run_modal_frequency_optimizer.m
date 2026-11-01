function run_modal_frequency_optimizer(stage)
%RUN_MODAL_FREQUENCY_OPTIMIZER Execute the fixed frequency comparison.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
femstudy.studies.modalFrequencyOptimizer(root,string(stage));
end
