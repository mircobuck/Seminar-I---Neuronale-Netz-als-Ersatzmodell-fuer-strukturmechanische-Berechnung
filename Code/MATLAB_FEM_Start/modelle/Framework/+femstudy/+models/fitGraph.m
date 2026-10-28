function model=fitGraph(cases,options)
%FITGRAPH Fit a small static message-passing graph prototype.
arguments
    cases (1,:) cell
    options.steps (1,1) double {mustBeInteger,mustBePositive}=6
    options.seed (1,1) double {mustBeInteger}=42
    options.lambda (1,1) double {mustBeNonnegative}=1e-8
end
rng(options.seed,"twister"); W=randn(20,10)/sqrt(10); A=[]; Y=[];
for k=1:numel(cases)
    C=cases{k}; G=femstudy.models.buildGraph(C.nodes,C.elements,C.X); H=messageFeatures(G,W,options.steps);
    A=[A;H]; Y=[Y;C.displacement]; %#ok<AGROW>
end
model=struct('schema',"graph-message-passing-v1",'W',W,'steps',options.steps, ...
    'seed',options.seed,'lambda',options.lambda,'decoder', ...
    ((A'*A+options.lambda*eye(size(A,2)))\(A'*Y)));
end

function H=messageFeatures(G,W,steps)
H=G.nodeFeatures;
for s=1:steps
    agg=zeros(size(H));
    for e=1:size(G.edges,2)
        agg(G.edges(2,e),:)=agg(G.edges(2,e),:)+H(G.edges(1,e),:);
    end
    H=tanh([H,agg]*W(1:size(H,2)*2,1:size(H,2)));
end
end
