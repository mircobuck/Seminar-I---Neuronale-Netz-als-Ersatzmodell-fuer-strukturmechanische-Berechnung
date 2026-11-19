function verify(root,out,cfg)
    %verify Verify source and input identity once at each phase boundary.
    file=fullfile(out,'source_manifest.csv');
    assert(isfile(file),'study:NotInitialized','Initialize this run before executing phases.');
    saved=readtable(file,'TextType','string','Delimiter',',','VariableNamingRule','preserve');
    current=staticstudy.sources(root,cfg);
    assert(isequal(saved,current),'study:SourceChanged', ...
        'Code, configuration or input data changed. Start a new run; do not rewrite the manifest.');
end
