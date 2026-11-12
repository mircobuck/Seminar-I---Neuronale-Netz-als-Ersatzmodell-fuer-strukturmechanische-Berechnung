function [spaceIds,skewIds]=distribution(train,eligibleIds,cfg)
    % Hold common parameter extrema and block quotas fixed across both designs.
    data=staticstudy.subset(train,eligibleIds);
    X=(data.inputParameters-reshape(cfg.lower,1,[]))./(reshape(cfg.upper,1,[])-reshape(cfg.lower,1,[]));
    [~,imin]=min(X,[],1);
    [~,imax]=max(X,[],1);
    anchors=unique([imin imax]);
    block=staticstudy.trainingBlocks(data,cfg);
    target=cfg.distribution_size;
    quota=target/2;
    assert(numel(anchors)<target && sum(block(anchors))<=quota &&  sum(~block(anchors))<=quota, ...
        'study:DistributionAnchors',  'Invalid anchor quotas.');
    space=anchors(:);
    skew=anchors(:);
    while numel(space)<target
        dist=inf(size(X,1),1);
        for k=space(:)'
            dist=min(dist,sum((X-X(k,:)).^2,2));
        end
        dist(space)=-inf;
        if sum(block(space))>=quota
            dist(block)=-inf;
        end
        if sum(~block(space))>=quota
            dist(~block)=-inf;
        end
        [v,i]=max(dist);
        assert(isfinite(v),'study:Distribution','Unable to fill space design.');
        space(end+1)=i; %#ok<AGROW>
    end
    [~,ordering]=sortrows([X(:,1),(1:size(X,1))'],[1 2]);
    for i=ordering(:)'
        if numel(skew)==target
            break;
        end
        if ismember(i,skew)
            continue;
        end
        if (block(i) && sum(block(skew))<quota) || (~block(i) && sum(~block(skew))<quota)
            skew(end+1)=i; %#ok<AGROW>
        end
    end
    assert(numel(skew)==target && sum(block(skew))==quota,'study:Distribution','Unable to fill skew design.');
    spaceIds=data.caseIds(space);
    skewIds=data.caseIds(skew);
end
