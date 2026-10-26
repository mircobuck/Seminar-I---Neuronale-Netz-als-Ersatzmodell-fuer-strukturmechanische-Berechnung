function plot_hybrid_diagnostics()
%PLOT_HYBRID_DIAGNOSTICS Plot saved diagnostics; never fits or runs FEM.
root=fileparts(mfilename('fullpath'));
folder=fullfile(root,'experiments','hybrid_static_audit_v1');
z=load(fullfile(folder,'diagnostics_v1.mat')); d=z.diagnostics.validation;
f=figure('Visible','off'); hold on;
for k=1:3, plot(d.ids,100*d.metrics(k).relative,'-o','DisplayName',d.metrics(k).name); end
xlabel('Validierungsfall-ID'); ylabel('Relativer Feldfehler (%)'); grid on; legend('Location','best');
exportgraphics(f,fullfile(folder,'validation_case_errors.pdf'),'ContentType','vector'); close(f);
f=figure('Visible','off'); tiledlayout(1,2);
for k=1:2
    nexttile; m=d.model(k); hold on;
    plot(d.ids,m.trueCoeff(:,1),'-o','DisplayName','FEM-Projektion');
    plot(d.ids,m.predictedCoeff(:,1),'-x','DisplayName','GPR');
    xlabel('Validierungsfall-ID'); ylabel('POD-Koeffizient (m)'); grid on; legend('Location','best');
    if k==1, title('Direktes POD-GPR'); else, title('Hybrid'); end
end
exportgraphics(f,fullfile(folder,'validation_coefficients.pdf'),'ContentType','vector'); close(f);
f=figure('Visible','off'); hold on;
for k=1:2
    plot(d.ids,100*d.model(k).projectionError,'--o','DisplayName',"Projektion "+k);
    plot(d.ids,100*d.metrics(k+1).relative,'-x','DisplayName',"Vorhersage "+k);
end
xlabel('Validierungsfall-ID'); ylabel('Relativer Gesamtfeldfehler (%)'); grid on; legend('Location','best');
exportgraphics(f,fullfile(folder,'projection_vs_prediction.pdf'),'ContentType','vector'); close(f);
end
