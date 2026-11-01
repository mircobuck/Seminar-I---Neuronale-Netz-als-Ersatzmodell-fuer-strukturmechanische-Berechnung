function evaluate_study_models()
%EVALUATE_STUDY_MODELS Evaluate frozen models on the independent test designs.
% Each stage checks for its prerequisite frozen models before doing FEM work.
run_neural_comparison("static_final_data");
run_neural_comparison("static_evaluate");
run_neural_comparison("modal_final_data");
run_neural_comparison("modal_evaluate");
end
