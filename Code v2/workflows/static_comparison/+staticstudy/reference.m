function data = reference(out,phase,role)
    %reference Public guarded access to validation and frozen test references.
    phase = string(phase);
    role = string(role);
    assert(any(phase==["tune","train","evaluate"]),'study:Phase','Unknown reference phase.');
    assert(any(role==["val","interpolation","extrapolation"]),'study:Role','Unknown reference role.');
    assert(role=="val" || phase=="evaluate",'study:TestLabelGate','Tuning and training cannot load test labels.');
    if phase=="evaluate"
        staticstudy.checkFrozen(out);
    end
    data = staticstudy.loadReference(out,role);
end
