function generate_modal_data_v2(stage)
%GENERATE_MODAL_DATA_V2 Generate and split modal frequency references.
if nargin==0
    fprintf('Stages: design, train_val, test\n');
    return
end
stage=validatestring(char(stage),{'design','train_val','test'});
if stage=="design"
    run_data_generation_v2("design");
elseif stage=="train_val"
    run_data_generation_v2("modal_train_val");
else
    run_data_generation_v2("modal_test");
end
end
