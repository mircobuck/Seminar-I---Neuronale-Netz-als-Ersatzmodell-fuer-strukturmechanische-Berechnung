function summary = summarizeErrors(errors)
%summarizeErrors Aggregate case errors with Nearest-Rank P95 and explicit NaNs.
arguments
    errors double
end
assert(isreal(errors) && all(isnan(errors) | (isfinite(errors) & errors>=0),'all'), ...
    'surrogate:study:InvalidErrors','Errors must be nonnegative finite values or undefined NaNs.');
defined = errors(isfinite(errors));
summary = struct('mean',NaN,'median',NaN,'p95',NaN,'maximum',NaN, ...
    'definedCount',numel(defined),'undefinedCount',nnz(isnan(errors)));
if isempty(defined)
    return
end
summary.mean = mean(defined);
summary.median = median(defined);
ordered = sort(defined);
summary.p95 = ordered(ceil(.95*numel(ordered)));
summary.maximum = max(defined);
end
