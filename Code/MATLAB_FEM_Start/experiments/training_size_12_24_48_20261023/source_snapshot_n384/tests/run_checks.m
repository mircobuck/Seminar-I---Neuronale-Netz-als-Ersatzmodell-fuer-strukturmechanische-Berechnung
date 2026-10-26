function run_checks(withFEM)
if nargin==0, withFEM=false; end
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'src')); rng(17);
% Independent low-rank data: projection should recover snapshots.
B=randn(45,3); A=randn(3,20); S=B*A; w=0.1+rand(45,1);
P=pod_fit(S,w,3); H=P.mean+P.V*pod_encode(P,S)';
assert(norm(H-S,'fro')/norm(S,'fro')<1e-12);
assert(norm(P.V'*(w.*P.V)-eye(3),'fro')<1e-12);
% Polynomial tail must reproduce an affine mapping at UNSEEN points.
X=rand(24,3); Y=[ones(24,1),X]*[1 2;2 3;4 5;6 7];
R=fit_rbf(X,Y,0); Z=rand(8,3);
assert(norm(predict_reg(R,Z)-[ones(8,1),Z]*[1 2;2 3;4 5;6 7],'fro')<1e-9);
for mode=["smoke","pilot"]
    c=config(mode); T=readtable(c.design,TextType="string");
    assert(height(T)==sum(c.counts));
    assert(numel(unique(T.id))==height(T));
    for j=1:3
        labels=["train","val","test"];
        assert(nnz(T.split==labels(j))==c.counts(j));
    end
end
if withFEM
    c=config('smoke'); x=(c.lower+c.upper)/2;
    a=solve_case(x,c); x(6)=2*x(6); b=solve_case(x,c);
    assert(norm(b.S-2*a.S)/norm(b.S)<1e-7,'Force scaling failed.');
    x(6)=x(6)/2; x(4)=2*x(4); b=solve_case(x,c);
    assert(norm(b.S-a.S/2)/norm(b.S)<1e-7,'E scaling failed.');
end
fprintf('Requested checks passed.\n');
end
