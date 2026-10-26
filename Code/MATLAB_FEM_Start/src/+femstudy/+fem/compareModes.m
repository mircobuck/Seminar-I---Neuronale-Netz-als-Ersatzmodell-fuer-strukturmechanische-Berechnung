function result=compareModes(a,b,gap)
%COMPAREMODES Compare transferred eigenmodes, with cluster subspaces.
if nargin<3, gap=.01; end
assert(isequal(a.queryCoordinates,b.queryCoordinates) && isequal(a.queryWeights,b.queryWeights));
W=a.queryWeights; A=a.queryModes; B=b.queryModes;
mac=abs(A'*(W.*B)).^2; n=min([size(mac,1),size(mac,2),8]);
pairs=matchpairs(1-mac(1:n,1:n),2); pairs=sortrows(pairs,1);
result.pairs=pairs; result.mac=mac; result.gapHeuristic=gap;
result.relativeFrequency=abs(b.frequencyHz(pairs(:,2))-a.frequencyHz(pairs(:,1)))./a.frequencyHz(pairs(:,1));
result.clusterStatus="ok"; result.minimumSubspaceCosine=1;
if (numel(a.frequencyHz)>n && (a.frequencyHz(n+1)-a.frequencyHz(n))/a.frequencyHz(n)<gap) || ...
   (numel(b.frequencyHz)>n && (b.frequencyHz(n+1)-b.frequencyHz(n))/b.frequencyHz(n)<gap)
    result.clusterStatus="cluster extends beyond buffer";
end
f=a.frequencyHz(1:n); breaks=[0; find(diff(f)./f(1:end-1)>=gap); n];
for k=1:numel(breaks)-1
    ids=(breaks(k)+1):breaks(k+1);
    if numel(ids)<2
        if mac(ids,pairs(ids,2))<.7, result.clusterStatus="ambiguous singleton matching"; end
        continue
    end
    mapped=pairs(ids,2); aa=sqrt(W).*A(:,ids); bb=sqrt(W).*B(:,mapped);
    mapped=sort(mapped);
    if any(diff(mapped)~=1) || ...
       (mapped(1)>1 && (b.frequencyHz(mapped(1))-b.frequencyHz(mapped(1)-1))/b.frequencyHz(mapped(1)-1)<gap) || ...
       (mapped(end)<numel(b.frequencyHz) && (b.frequencyHz(mapped(end)+1)-b.frequencyHz(mapped(end)))/b.frequencyHz(mapped(end))<gap)
        result.clusterStatus="ambiguous cluster boundary"; continue
    end
    if rank(aa)<numel(ids) || rank(bb)<numel(ids) || (ids(end)==n && n==8)
        result.clusterStatus="ambiguous rank or buffer boundary"; continue
    end
    [qa,~]=qr(aa,0); [qb,~]=qr(bb,0);
    result.minimumSubspaceCosine=min(result.minimumSubspaceCosine,min(svd(qa'*qb)));
end
result.pass=all(pairs(1:6,1)==(1:6)') && all(result.relativeFrequency(1:6)<=.02) ...
    && result.clusterStatus=="ok" && result.minimumSubspaceCosine>=.8;
end
