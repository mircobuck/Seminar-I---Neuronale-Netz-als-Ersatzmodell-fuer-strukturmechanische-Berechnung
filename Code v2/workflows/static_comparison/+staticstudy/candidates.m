function candidates = candidates(method,cfg)
    %candidates Preserve the versioned candidate order and original model defaults.
    base = struct('seed',cfg.seed_tuning,'datasetId',"main_static",  'optimizer', string(cfg.training_optimizer),  'maxEpochs', ...
        cfg.max_epochs,  'miniBatchSize',  cfg.mini_batch_size,  'learningRate', cfg.learning_rate);
    specifications = cfg.search.(method);
    candidates = cell(numel(specifications),1);
    for k=1:numel(specifications)
        candidate = base;
        spec = specifications(k);
        fields = fieldnames(spec);
        for j=1:numel(fields)
            value = spec.(fields{j});
            if ischar(value)
                value = string(value);
            end
            candidate.(fields{j}) = value;
        end
        candidates{k} = candidate;
    end
end
