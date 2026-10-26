function diagnostic_static_confirmation()
root=fileparts(mfilename('fullpath'));addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','static_confirmation_v1');
a=load(fullfile(out,'design.mat')); X=a.design.X; ids=a.design.id;
a=load(fullfile(root,'experiments','training_size_12_24_48_20261023','n384','train.mat'),'D');D=a.D;
train=ismember(D.id,[1:12 25:30]); meanX=mean(D.X(train,:),1); stdX=std(D.X(train,:),0,1);stdX(stdX==0)=1;
distance=min(pdist2((X-meanX)./stdX,(D.X(train,:)-meanX)./stdX),[],2);
T=table(ids,distance,'VariableNames',{'id','nearestTrainDistance'});writetable(T,fullfile(out,'distances.csv'));
p=load(fullfile(out,'predictions.mat'));a=load(fullfile(out,'evaluation.mat')); rows=a.rows;
hybrid=rows(rows.model==3,:);[~,worst]=max(hybrid.fieldPct);
f=figure('Visible','off','Position',[100 100 1000 350]); tiledlayout(1,2);
nexttile;scatter(distance,hybrid.fieldPct,25,'filled');xlabel('Trainingsabstand (standardisiert)');ylabel('Hybrid-Feldfehler (%)');grid on;
nexttile;scatter(X(:,4)/1e9,hybrid.fieldPct,25,X(:,1),'filled');xlabel('Elastizitätsmodul (GPa)');ylabel('Hybrid-Feldfehler (%)');colorbar;title('Farbe: Länge (m)');grid on;
exportgraphics(f,fullfile(out,'diagnostic.png'),'Resolution',150);close(f);
a=load(fullfile(out,sprintf('fem_%06d.mat',ids(worst)))); U=a.result.value.S;
N=size(p.xi,2);ix=find(abs(p.xi(2,:)-.5)<1e-12);f=figure('Visible','off','Position',[100 100 1100 350]);tiledlayout(1,3);
fields={U(2*N+ix),p.corrected{3}(2*N+ix,worst),p.corrected{3}(2*N+ix,worst)-U(2*N+ix)};
names={'FEM u_z','Hybrid u_z','Hybrid minus FEM'};
for j=1:3,nexttile;scatter(p.xi(1,ix),p.xi(3,ix),22,fields{j}*1e6,'filled');axis equal tight;colorbar;title(names{j});xlabel('normiertes x');ylabel('normiertes z');end
sgtitle(sprintf('Fall %d, Verschiebung in µm',ids(worst)));
exportgraphics(f,fullfile(out,'field_worst.png'),'Resolution',150);close(f);
end
