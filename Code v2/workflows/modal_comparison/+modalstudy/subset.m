function data = subset(data,ids)
%subset Keep requested case order and only slice case-dependent arrays.
[found,rows]=ismember(ids,data.caseIds);
assert(all(found),'modalstudy:Ids','Unknown training IDs.');
data.caseIds=data.caseIds(rows); data.inputParameters=data.inputParameters(rows,:);
data.frequencyHz=data.frequencyHz(rows,:);
if isfield(data,'computationTimeSeconds'), data.computationTimeSeconds=data.computationTimeSeconds(rows); end
end
