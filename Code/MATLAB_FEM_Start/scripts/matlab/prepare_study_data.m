function prepare_study_data()
%PREPARE_STUDY_DATA Seal designs and make reusable training/validation FEM data.
% The final test design is sealed during prepare; test labels are deferred until
% after model fitting and are created by evaluate_study_models.
run_neural_comparison("prepare");
run_neural_comparison("modal_check");
run_neural_comparison("modal_data");
end
