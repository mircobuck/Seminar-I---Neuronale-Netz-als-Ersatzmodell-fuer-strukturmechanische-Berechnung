function pod = fitPod(data,rank,method,prepared)
%fitPod Compute or verify the centered weighted training POD.
if nargin<4, prepared=[]; end
assert(isnumeric(rank) && isscalar(rank) && isfinite(rank) && rank>=1 && rank==fix(rank), ...
    'surrogate:pod:Config','POD rank must be a positive integer.');
fingerprint=surrogate.models.shared.podFingerprint(data);
if ~isempty(prepared)
    assert(isstruct(prepared) && isfield(prepared,'fingerprint') && ...
        strcmp(prepared.fingerprint,fingerprint) && prepared.rank==rank && ...
        isequal(prepared.weights,double(data.displacementComponentWeights(:))), ...
        'surrogate:pod:PreparedMismatch','Prepared POD does not match training data, weights, order or rank.');
    pod=prepared; return
end
w=double(data.displacementComponentWeights(:)); fields=double(data.displacementFields);
mu=mean(fields,2); centered=fields-mu;
[U,S,~]=svd(sqrt(w).*centered,'econ'); singular=diag(S);
if isempty(singular), numericalRank=0; else
    numericalRank=sum(singular>max(size(centered))*eps(max(singular)));
end
assert(rank<=numericalRank,char("surrogate:"+string(method)+":Rank"), ...
    'Requested POD rank %d exceeds numerical training rank %d.',rank,numericalRank);
basis=U(:,1:rank)./sqrt(w);
pod=struct('basis',basis,'fieldMean',mu,'weights',w,'rank',rank, ...
    'numericalRank',numericalRank,'fingerprint',fingerprint, ...
    'retainedEnergy',sum(singular(1:rank).^2)/sum(singular.^2));
end
