function result=frequency(pred,truth,thresholdHz)
if nargin<3, thresholdHz=1e-8; end
assert(isequal(size(pred.rawHz),size(truth)));
valid=abs(truth)>thresholdHz;
raw=abs(pred.rawHz-truth); sorted=abs(pred.sortedHz-truth);
rr=nan(size(raw)); rs=rr; rr(valid)=raw(valid)./abs(truth(valid)); rs(valid)=sorted(valid)./abs(truth(valid));
result=struct('absoluteRawHz',raw,'absoluteSortedHz',sorted,'relativeRaw',rr, ...
    'relativeSorted',rs,'thresholdHz',thresholdHz,'orderViolationFraction',mean(pred.orderViolation));
end
