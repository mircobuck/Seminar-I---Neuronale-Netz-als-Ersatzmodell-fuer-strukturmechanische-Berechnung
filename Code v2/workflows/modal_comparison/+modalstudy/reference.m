function data = reference(out,phase,split)
%reference Guard test labels; hashes alone do not expose test frequencies.
assert(any(string(phase)==["generate","tune","train","evaluate","benchmark"]), ...
    'modalstudy:Phase','Unknown reference phase.');
assert(any(string(split)==["train","val","test"]),'modalstudy:Split','Unknown split.');
if string(split)=="test"
    assert(any(string(phase)==["evaluate","benchmark"]),'study:TestLabelGate','Test labels are frozen-phase only.');
    modalstudy.checkFrozen(out);
end
locations=jsondecode(fileread(fullfile(out,'reference_locations.json')));
data=surrogate.loadDataset(locations.(split));
assert(string(data.modality)=="modal" && string(data.split)==string(split),'modalstudy:Split','Wrong modal reference role.');
design=modalstudy.artifact(fullfile(out,'candidate_design.mat'));
expected=design(design.split==string(split),:);
X=expected{:,cellstr(data.parameterNames)};
assert(isequal(data.caseIds,expected.id) && isequal(size(X),size(data.inputParameters)) && ...
    all(abs(X-data.inputParameters)<=1e-14*max(1,abs(data.inputParameters)),'all'), ...
    'modalstudy:Design','Reference does not match the registered design.');
end
