function plot_controlled_fields()
%PLOT_CONTROLLED_FIELDS Uses saved models and FEM fields; never trains.
root=fileparts(mfilename('fullpath')); addpath(root,fullfile(root,'src'));
out=fullfile(root,'experiments','hybrid_controlled_fits_v1');
base=fullfile(root,'experiments','training_size_12_24_48_20261023','n384');
a=load(fullfile(base,'train.mat')); D=a.D;
f=load(fullfile(root,'experiments','hybrid_static_audit_v1','selection.mat'));
it=ismember(D.id,f.spec.trainIDs); iv=ismember(D.id,f.spec.valIDs);
X=D.X(it,:); S=D.S(:,it); Sv=D.S(:,iv); w=D.w(:); xi=D.xi;
beam=femstudy.fem.beamField(X,xi); beamV=femstudy.fem.beamField(D.X(iv,:),xi);
ranks=1:12; errors=zeros(numel(ranks),2);
for j=ranks
    P=pod_fit(S,w,j); H=P.mean+P.V*pod_encode(P,Sv)';
    errors(j,1)=mean(sqrt(sum(w.*(H-Sv).^2,1)));
    P=pod_fit(S-beam,w,j); H=beamV+P.mean+P.V*pod_encode(P,Sv-beamV)';
    errors(j,2)=mean(sqrt(sum(w.*(H-Sv).^2,1)));
end
fig=figure('Visible','off'); semilogy(ranks,errors,'-o'); grid on;
xlabel('POD-Rang'); ylabel('Mittlerer gewichteter Projektionsfehler (m)');
legend('Vollfeld','Differenzfeld','Location','best');
exportgraphics(fig,fullfile(out,'pod_compression.pdf'),'ContentType','vector'); close(fig);
c=load(fullfile(out,'fit_2_8.mat')); H=c.result.valField; ids=D.id(iv); V=Sv;
[~,order]=sort(field_error(V,H,w)); chosen=order([1 3 end]); Q=size(xi,2);
fig=figure('Visible','off','Position',[50 50 1100 700]); tiledlayout(3,3);
for j=1:3
    q=chosen(j); mid=abs(xi(2,:)-.5)<1e-12;
    fields={V(2*Q+1:3*Q,q),H(2*Q+1:3*Q,q),H(2*Q+1:3*Q,q)-V(2*Q+1:3*Q,q)};
    labels=["FEM","Hybrid","Fehler"];
    for k=1:3
        nexttile; scatter(xi(1,mid),xi(3,mid),18,fields{k}(mid)*1e6,'filled');
        axis tight; colorbar; xlabel('\xi_x'); ylabel('\xi_z');
        title(sprintf('Fall %d: %s (µm)',ids(q),labels(k)));
    end
end
exportgraphics(fig,fullfile(out,'field_cases.pdf'),'ContentType','vector'); close(fig);
end
