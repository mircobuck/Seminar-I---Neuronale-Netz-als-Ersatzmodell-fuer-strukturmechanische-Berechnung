function [spaceIds,skewIds]=studyDistribution(train,eligibleIds,lower,upper)
% Hold common parameter extrema and block quotas fixed across both designs.
data=studySubset(train,eligibleIds); X=(data.inputParameters-reshape(lower,1,[]))./(reshape(upper,1,[])-reshape(lower,1,[]));
[~,imin]=min(X,[],1); [~,imax]=max(X,[],1); anchors=unique([imin imax]);
block=data.caseIds<=810460; assert(numel(anchors)<192 && sum(block(anchors))<=96 && ...
    sum(~block(anchors))<=96,'study:DistributionAnchors','Invalid anchor quotas.');
space=anchors(:); skew=anchors(:);
while numel(space)<192
    dist=inf(size(X,1),1);
    for k=space(:)', dist=min(dist,sum((X-X(k,:)).^2,2)); end
    dist(space)=-inf;
    if sum(block(space))>=96, dist(block)=-inf; end
    if sum(~block(space))>=96, dist(~block)=-inf; end
    [v,i]=max(dist); assert(isfinite(v),'study:Distribution','Unable to fill space design.');
    space(end+1)=i; %#ok<AGROW>
end
[~,ordering]=sortrows([X(:,1),(1:size(X,1))'],[1 2]);
for i=ordering(:)'
    if numel(skew)==192, break; end
    if ismember(i,skew), continue; end
    if (block(i) && sum(block(skew))<96) || (~block(i) && sum(~block(skew))<96)
        skew(end+1)=i; %#ok<AGROW>
    end
end
assert(numel(skew)==192 && sum(block(skew))==96,'study:Distribution','Unable to fill skew design.');
spaceIds=data.caseIds(space); skewIds=data.caseIds(skew);
end
