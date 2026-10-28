function plot_test_case(mode,modelName,caseIndex)
% Compare held-out FEM and prediction on the common reference points.
if nargin<1, mode="pilot"; end
if nargin<2, modelName="POD_GP"; end
if nargin<3, caseIndex=1; end
c=config(mode); addpath(genpath(fullfile(c.root,'modelle')));
a=load(fullfile(c.out,'models.mat')); models=a.models;
a=load(fullfile(c.out,'test.mat'),'D'); D=a.D;
assert(caseIndex>=1 && caseIndex<=size(D.X,1));
k=find(cellfun(@(m)m.name==string(modelName),models),1);
assert(~isempty(k) && models{k}.type=="field",'Choose a field model.');
x=D.X(caseIndex,:); H=predict_surrogate(models{k},x);
Q=size(D.xi,2); z=2*Q+(1:Q);
xyz=[x(1)*(D.xi(1,:)-0.5);x(2)*(D.xi(2,:)-0.5);x(3)*D.xi(3,:)];
truth=D.S(z,caseIndex); pred=H(z);
cl=[min([truth;pred]) max([truth;pred])];
figure; tiledlayout(1,3);
nexttile; scatter3(xyz(1,:),xyz(2,:),xyz(3,:),14,truth,'filled');
axis equal; colorbar; clim(cl); title('FEM u_z [m]');
nexttile; scatter3(xyz(1,:),xyz(2,:),xyz(3,:),14,pred,'filled');
axis equal; colorbar; clim(cl); title(modelName+' u_z [m]');
nexttile; scatter3(xyz(1,:),xyz(2,:),xyz(3,:),14,abs(pred-truth),'filled');
axis equal; colorbar; title('Absolute error [m]');
end
