function create_project_status_report()
%CREATE_PROJECT_STATUS_REPORT Export current study results, MATLAB plots, and PDF.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
study=fullfile(root,'experiments','active','neural_comparison_20261027_v1');
plotDir=fullfile(study,'figures');
report=fullfile(root,'docs','project-status-20261028.pdf');
staticFile=fullfile(study,'static_test_summary.csv');
modalFile=fullfile(study,'modal_test_summary.csv');
assert(isfile(staticFile) && isfile(modalFile), ...
    'femstudy:report:MissingResults','Expected evaluation CSV files are missing.');
baseReport=report; basePlotDir=plotDir; versionNumber=2;
while isfile(report) || isfolder(plotDir)
    [reportDir,reportName,reportExt]=fileparts(baseReport);
    report=fullfile(reportDir,sprintf('%s-v%d%s',reportName,versionNumber,reportExt));
    plotDir=fullfile(fileparts(basePlotDir),sprintf('figures-v%d',versionNumber));
    versionNumber=versionNumber+1;
end
mkdir(plotDir);
S=readtable(staticFile); M=readtable(modalFile);
S.Model=string(S.Model); M.Model=string(M.Model);
assert(height(S)==45 && height(M)==24, ...
    'femstudy:report:UnexpectedRows','Evaluation summary row counts changed.');
assert(all(isfinite(S.MedianRelativeError)) && ...
    all(isfinite(M.MedianRelativeRaw)), ...
    'femstudy:report:NonfiniteResults','Summary contains nonfinite errors.');

staticLearning=makeStaticLearningPlot(S,plotDir);
staticComparison=makeStaticComparisonPlot(S,plotDir);
modalLearning=makeModalLearningPlot(M,plotDir);
modalComparison=makeModalComparisonPlot(M,plotDir);
pages={makeCoverPage(S,M),staticLearning,staticComparison, ...
    modalLearning,modalComparison,makeImplementationPage()};
for k=1:numel(pages)
    if k==1
        exportgraphics(pages{k},report,'ContentType','vector');
    else
        exportgraphics(pages{k},report,'Append',true,'ContentType','vector');
    end
end
close(pages{:});
fprintf('PDF report: %s\nMATLAB plots: %s\n',report,plotDir);
end

function fig=makeStaticLearningPlot(T,plotDir)
fig=newPage('Statische Felder: Lernkurve');
ax=axes(fig,'Position',[.12 .20 .80 .65]); hold(ax,'on');
colors=[.05 .35 .72;.85 .32 .12];
models=["Neural_pod","Neural_residual"];
labels=["POD-MLP","Neuronales Restfeld"];
sizes=unique(T.N(T.N>0));
for k=1:numel(models)
    center=nan(size(sizes)); low=center; high=center;
    for j=1:numel(sizes)
        rows=T.N==sizes(j) & T.Model==models(k);
        values=100*T.MedianRelativeError(rows);
        center(j)=median(values);
        low(j)=min(values); high(j)=max(values);
    end
    errorbar(ax,sizes,center,center-low,high-center,'-o', ...
        'Color',colors(k,:),'LineWidth',1.8,'MarkerFaceColor',colors(k,:), ...
        'DisplayName',labels(k));
end
yline(ax,100*T.MedianRelativeError(T.Model=="Beam_theory_field"), ...
    '--k','Balkentheorie-Feldbaseline','LabelHorizontalAlignment','left', ...
    'HandleVisibility','off');
set(ax,'XScale','log','YScale','log','XTick',sizes);
xlim(ax,[10 450]); grid(ax,'on'); box(ax,'on');
xlabel(ax,'Anzahl Trainingsfälle n');
ylabel(ax,'Median relativer Feldfehler (%)');
title(ax,'64 unabhaengige statische Testfaelle; Linie = Median der Seeds, Balken = Min-Max');
legend(ax,'Location','southwest');
exportPlot(fig,plotDir,'static-learning-curve');
end

function fig=makeStaticComparisonPlot(T,plotDir)
fig=newPage('Statische Felder: Modellvergleich bei n = 384');
names=["Neuronales Restfeld","POD-MLP","POD-GP (historisch)", ...
    "POD-RBF (historisch)","POD-MLP (historisch)","DeepONet (Archiv)", ...
    "Balkentheorie"];
ids=["Neural_residual","Neural_pod","Legacy_POD_GP","Legacy_POD_RBF", ...
    "Legacy_POD_MLP","DeepONet","Beam_theory_field"];
values=nan(size(ids));
for k=1:numel(ids)
    rows=T.Model==ids(k);
    if ids(k)~="Beam_theory_field", rows=rows & T.N==384; end
    values(k)=100*median(T.MedianRelativeError(rows));
end
ax=axes(fig,'Position',[.12 .24 .82 .58]);
b=bar(ax,values,'FaceColor','flat');
b.CData=repmat([.18 .48 .72],numel(values),1);
b.CData(1,:)=[.85 .32 .12];
set(ax,'YScale','log','XTick',1:numel(names),'XTickLabel',names);
ax.XTickLabelRotation=22; grid(ax,'on'); box(ax,'on');
ylabel(ax,'Median relativer Feldfehler (%)');
title(ax,'Vergleich auf denselben 64 unabhängigen Testfällen');
for k=1:numel(values)
    text(ax,k,values(k)*1.13,sprintf('%.3g%%',values(k)), ...
        'HorizontalAlignment','center','FontSize',9);
end
exportPlot(fig,plotDir,'static-model-comparison-n384');
end

function fig=makeModalLearningPlot(T,plotDir)
fig=newPage('Modal: Frequenz-Lernkurve');
ax=axes(fig,'Position',[.12 .20 .80 .65]); hold(ax,'on');
sizes=unique(T.N);
gp=nan(size(sizes)); mlp=gp; low=gp; high=gp;
for j=1:numel(sizes)
    rows=T.N==sizes(j) & T.Model=="Frequency_GPR";
    gp(j)=100*median(T.MedianRelativeRaw(rows));
    rows=T.N==sizes(j) & T.Model=="Frequency_MLP";
    values=100*T.MedianRelativeRaw(rows);
    mlp(j)=median(values); low(j)=min(values); high(j)=max(values);
end
semilogx(ax,sizes,gp,'-s','Color',[.05 .35 .72], ...
    'LineWidth',1.8,'MarkerFaceColor',[.05 .35 .72],'DisplayName','Frequency-GPR');
errorbar(ax,sizes,mlp,mlp-low,high-mlp,'-o','Color',[.85 .32 .12], ...
    'LineWidth',1.8,'MarkerFaceColor',[.85 .32 .12], ...
    'DisplayName','Frequency-MLP (Median und Min-Max der Seeds)');
set(ax,'YScale','log','XTick',sizes); xlim(ax,[10 450]);
grid(ax,'on'); box(ax,'on');
xlabel(ax,'Anzahl Modal-Trainingsfälle n');
ylabel(ax,'Median relativer Fehler der sechs Frequenzen (%)');
title(ax,'64 unabhängige Modal-Testfälle; Frequenzen nach Index verglichen');
legend(ax,'Location','southwest');
exportPlot(fig,plotDir,'modal-frequency-learning-curve');
end

function fig=makeModalComparisonPlot(T,plotDir)
fig=newPage('Modal: n = 384 und Ordnungsverletzungen');
ax=axes(fig,'Position',[.13 .22 .78 .62]);
rows=T.N==384;
gp=100*T.MedianRelativeRaw(rows & T.Model=="Frequency_GPR");
mlp=100*T.MedianRelativeRaw(rows & T.Model=="Frequency_MLP");
viol=T.OrderViolationFraction(rows & T.Model=="Frequency_MLP");
gp=median(gp); mlpMedian=median(mlp);
mlpMin=min(mlp); mlpMax=max(mlp); violationMedian=median(viol);
yyaxis(ax,'left');
bar(ax,[1 2],[gp mlpMedian],.55);
hold(ax,'on');
errorbar(ax,2,mlpMedian,mlpMedian-mlpMin,mlpMax-mlpMedian, ...
    'k.','LineWidth',1.5,'CapSize',10);
ylabel(ax,'Median relativer Frequenzfehler (%)');
set(ax,'YScale','log','XTick',[1 2],'XTickLabel', ...
    {'Frequency-GPR','Frequency-MLP'});
yyaxis(ax,'right');
plot(ax,2,100*violationMedian,'kd','MarkerFaceColor',[.95 .75 .15], ...
    'MarkerSize',8);
ylabel(ax,'Ordnungsverletzungen bei MLP-Testfällen (%)');
title(ax,sprintf(['n=384; GPR %.3g%%; MLP-Median %.3g%% ' ...
    '(Seed-Spanne %.3g bis %.3g%%); MLP-Ordnungsverletzung %.2g%%'], ...
    gp,mlpMedian,mlpMin,mlpMax,100*violationMedian));
grid(ax,'on'); box(ax,'on');
exportPlot(fig,plotDir,'modal-model-comparison-n384');
end

function fig=makeCoverPage(S,M)
fig=newPage('Projektstand | MATLAB FEM-Ersatzmodelle');
annotation(fig,'textbox',[.10 .75 .80 .12],'String', ...
    'Projektstand und Ergebnisse','FontSize',24,'FontWeight','bold', ...
    'EdgeColor','none','HorizontalAlignment','center');
annotation(fig,'textbox',[.15 .65 .70 .06],'String', ...
    'MATLAB FEM | Stand 28. Oktober 2026','FontSize',14, ...
    'EdgeColor','none','HorizontalAlignment','center');
bestStatic=100*min(S.MedianRelativeError(S.Model=="Neural_residual" & S.N==384));
bestGpr=100*median(M.MedianRelativeRaw(M.Model=="Frequency_GPR" & M.N==384));
textLines={ ...
    'Kurzfazit', ...
    sprintf('Statische Verschiebungsfelder: bestes neuronales Restfeldmodell n=384: %.3g%% Medianfehler.',bestStatic), ...
    sprintf('Eigenfrequenzen: Frequency-GPR bei n=384: %.3g%% Medianfehler.',bestGpr), ...
    'Die unabhängigen Tests umfassen je 64 statische beziehungsweise modale FEM-Fälle.', ...
    '', ...
    'Berichtsumfang', ...
    'Implementierte Modellfamilien, Studienablauf, Ergebnisse und Grenzen.', ...
    'Die folgenden Abbildungen wurden aus den gespeicherten MATLAB-Auswertungen erzeugt.', ...
    '', ...
    'Wichtig: Ein Frequenzmodell sagt keine Eigenformen voraus. Es gibt derzeit kein ausgewertetes Eigenform-Surrogat.'};
annotation(fig,'textbox',[.13 .27 .74 .34],'String',textLines, ...
    'FontSize',13,'EdgeColor','none','Interpreter','none', ...
    'VerticalAlignment','middle');
annotation(fig,'textbox',[.10 .08 .80 .08],'String', ...
    'Quelle: experiments/active/neural_comparison_20261027_v1 | MATLAB R2025b', ...
    'FontSize',9,'EdgeColor','none','HorizontalAlignment','center');
end

function fig=makeImplementationPage()
fig=newPage('Implementierte Modelle und Aussagegrenzen');
sections={ ...
    'Implementierte und untersuchte Modellfamilien', ...
    'Statik - Skalare: Scalar-GPR, analytische Balkentheorie und Beam-plus-GPR.', ...
    'Statik - Felder: POD-GP, POD-RBF, POD-MLP, POD-Galerkin, DeepONet, Beam-Field-POD-GPR sowie neuronales POD-MLP und neuronales Restfeldmodell.', ...
    'Modal: Frequency-GPR und Frequency-MLP sagen Eigenfrequenzen voraus; sie geben keine Eigenformen aus.', ...
    '', ...
    'Zusaetzliche Prototypen - Schnittstellen/Machbarkeit, kein gleichwertiger Modellvergleich', ...
    'PINN: 1-D Euler-Bernoulli-Balken; kein 3-D-FEM-Feld-PINN.', ...
    'Fourier-Gittermodell: Fourier-Feature-Readout; keine vollständige mehrschichtige FNO-Reproduktion.', ...
    'Graphnetz: statischer Message-Passing-Prototyp; kein vollständiger MeshGraphNet-Rollout.', ...
    'DeepONet-Adapter: bindet den vorhandenen Ansatz an die Paket-API an.', ...
    '', ...
    'Ergebnisgrenzen und offene Punkte', ...
    'Die Modalprojektion meldete wiederholt: Some input points are not referenced by the triangulation. Die Warnung ist nicht als behoben bewertet.', ...
    'MAC-basierte Modenfamilienzuordnung und kontrollierte Amortisationsanalyse fehlen.', ...
    'Die 64-Fall-Testsets sind verbraucht; keine Nachoptimierung anhand dieser Fehlerwerte.', ...
    'Die 384-Fall-Ergebnisse sind benchmarkbezogen und keine allgemeine Genauigkeitsgarantie.', ...
    '', ...
    'Verifikation', ...
    'run_checks(false): bestanden | neuralStudyTest: 5/5 | neuralPrototypeTest: 3/3 | Code Analyzer: 0 Befunde.'};
annotation(fig,'textbox',[.09 .10 .82 .82],'String',sections, ...
    'FontSize',11,'EdgeColor','none','Interpreter','none', ...
    'VerticalAlignment','top');
end

function fig=newPage(pageTitle)
fig=figure('Visible','off','Color','white','Units','inches', ...
    'Position',[0 0 8.27 11.69],'PaperPositionMode','auto');
if nargin>0
    annotation(fig,'textbox',[.08 .93 .84 .045],'String',pageTitle, ...
        'FontSize',17,'FontWeight','bold','EdgeColor','none', ...
        'HorizontalAlignment','center');
end
end

function exportPlot(fig,plotDir,stem)
exportgraphics(fig,fullfile(plotDir,[stem '.png']),'Resolution',180);
savefig(fig,fullfile(plotDir,[stem '.fig']));
end
