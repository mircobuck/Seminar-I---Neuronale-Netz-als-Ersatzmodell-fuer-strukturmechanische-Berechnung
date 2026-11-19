function validateReferences(out,cfg)
    %validateReferences Check split metadata without reading test displacement labels.
    train = surrogate.loadDataset(cfg.paths.training_file);
    val = staticstudy.reference(out,"train","val");
    surrogate.validateTrainingSplits(train,val);
    assert(numel(val.caseIds)==cfg.counts.val,'study:Counts','Validation count differs from configuration.');
    locations = jsondecode(fileread(fullfile(out,'reference_locations.json')));
    parameters = train.inputParameters;
    allIds = train.caseIds;
    names = cellstr(train.parameterNames);
    for role=["val","interpolation","extrapolation"]
        folder = locations.(role);
        design = readtable(fullfile(folder,'design.csv'),'TextType','string');
        expectedSplit = "test";
        if role=="val"
            expectedSplit="val";
        end
        assert(height(design)==cfg.counts.(role) && all(design.split==expectedSplit),  'study:Counts', ...
            'Incorrect count or split role for %s.',  role);
        assert(~any(ismember(design.id,allIds)),'study:IdOverlap','Split case IDs overlap.');
        X = design{:,names};
        surrogate.study.assertDisjointParameters(parameters,X,cfg.lower,cfg.upper,cfg.duplicate_tolerance);
        for j=1:size(X,1)-1
            surrogate.study.assertDisjointParameters(X(j,:),X(j+1:end,:),cfg.lower,cfg.upper,cfg.duplicate_tolerance);
        end
        parameters=[parameters;X]; %#ok<AGROW>
        allIds=[allIds;design.id]; %#ok<AGROW>
    end
end
