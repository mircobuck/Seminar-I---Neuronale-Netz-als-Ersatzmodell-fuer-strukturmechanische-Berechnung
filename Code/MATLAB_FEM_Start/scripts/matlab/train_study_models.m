function train_study_models()
%TRAIN_STUDY_MODELS Fit static-field and modal-frequency models.
run_neural_comparison("static");
run_neural_comparison("modal_train");
end
