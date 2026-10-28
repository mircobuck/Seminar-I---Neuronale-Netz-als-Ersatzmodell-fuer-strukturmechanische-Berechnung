function graph=buildGraph(nodes,elements,X)
%BUILDGRAPH Build a directed quadratic-element graph and explicit features.
arguments
    nodes (3,:) double {mustBeFinite}
    elements (10,:) double {mustBeInteger,mustBePositive}
    X (1,6) double {mustBeFinite}
end
assert(max(elements,[],'all')<=size(nodes,2));
pairs=nchoosek(1:10,2); edges=zeros(2,0);
for e=1:size(elements,2)
    ids=elements(:,e);
    edges=[edges,[ids(pairs(:,1))';ids(pairs(:,2))']; ...
        [ids(pairs(:,2))';ids(pairs(:,1))']]; %#ok<AGROW>
end
edges=unique(edges','rows')';
clamped=abs(nodes(1,:)-min(nodes(1,:)))<1e-10;
nodeFeatures=[nodes',repmat(X,size(nodes,2),1),double(clamped)'];
rel=nodes(:,edges(2,:))-nodes(:,edges(1,:));
edgeFeatures=[rel',vecnorm(rel,2,1)'];
graph=struct('schema',"quadratic-tet-graph-v1",'nodes',nodes, ...
    'elements',elements,'edges',edges,'nodeFeatures',nodeFeatures, ...
    'edgeFeatures',edgeFeatures,'clampedNodes',find(clamped), ...
    'nodeWeights',positiveWeights(nodes,elements));
end

function weights=positiveWeights(nodes,elements)
weights=zeros(size(nodes,2),1);
for e=1:size(elements,2)
    ids=elements(1:4,e); a=nodes(:,ids(2))-nodes(:,ids(1));
    b=nodes(:,ids(3))-nodes(:,ids(1)); c=nodes(:,ids(4))-nodes(:,ids(1));
    volume=abs(dot(a,cross(b,c)))/6; weights(elements(:,e))=weights(elements(:,e))+volume/10;
end
assert(all(weights>=0) && any(weights>0));
end
