function U=predictGraph(model,caseData)
%PREDICTGRAPH Predict native nodal displacements for one graph case.
G=femstudy.models.buildGraph(caseData.nodes,caseData.elements,caseData.X);
H=G.nodeFeatures; W=model.W;
for s=1:model.steps
    agg=zeros(size(H));
    for e=1:size(G.edges,2), agg(G.edges(2,e),:)=agg(G.edges(2,e),:)+H(G.edges(1,e),:); end
    H=tanh([H,agg]*W(1:size(H,2)*2,1:size(H,2)));
end
U=H*model.decoder; U(G.clampedNodes,:)=0;
end
