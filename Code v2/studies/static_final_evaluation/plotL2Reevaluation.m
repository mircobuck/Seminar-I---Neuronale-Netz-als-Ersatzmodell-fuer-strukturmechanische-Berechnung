function plotL2Reevaluation(outputDir)
%plotL2Reevaluation - Export readable plots from saved L2 study summaries.
%   plotL2Reevaluation(OUTPUTDIR) reads configuration_summary.csv and exports
%   comparisons and learning curves without predictions or training.
summary=readtable(fullfile(outputDir,'configuration_summary.csv'), ...
    'TextType','string','Delimiter',',','VariableNamingRule','preserve');
fields={'MedianPercent','MeanPercent','P95Percent','MaximumPercent'};
metricNames={'Median','Mittelwert','P95 (Nearest Rank)','Maximum je Seed, gemittelt'};
studies=unique(summary.Study);
for study=studies'
    data=summary(summary.Study==study & summary.Dataset=="existing_validation_128" ...
        & summary.TrainingCases==768,:);
    data=sortrows(data,'MeanPercent');
    switch study
        case "architecture_loss"
            lossLabel=repmat("Koeff.",height(data),1);
            lossLabel(data.LossMode=="weighted_field_mse")="Feld";
            labels=data.Width+" / L"+data.HiddenLayers+" / "+lossLabel;
            studyTitle="Architektur und Loss: Breite / Schichten / Loss";
        case "optimizer"
            labels=data.Optimizer+" / L"+data.HiddenLayers;
            studyTitle="Optimierer: Breite 128, POD-Rang 10, Lernrate 0,001";
        case "learning_rate"
            labels=string(data.LearningRate)+" / L"+data.HiddenLayers;
            studyTitle="Lernrate / Schichten: Adam, Breite 128, POD-Rang 10";
        case "width"
            labels=string(data.Width);
            studyTitle="Netzbreite: 2 Schichten, Adam, POD-Rang 10";
        case "pod_rank"
            labels=string(data.Rank);
            studyTitle="POD-Rang: Breite 64, 2 Schichten, Adam";
    end
    fig=figure('Visible','off','Color','white','Position',[50 50 1500 950]);
    layout=tiledlayout(fig,2,2,'TileSpacing','loose','Padding','loose');
    for k=1:4
        ax=nexttile(layout);
        values=data.(fields{k});
        if k==4
            bar(ax,[values,data.WorstObservedMaximumPercent]);
            legend(ax,{'Mittel der Seed-Maxima','Groesstes beobachtetes Maximum'}, ...
                'Location','northwest','FontSize',9);
            upper=max(data.WorstObservedMaximumPercent);
        else
            bar(ax,values);
            upper=max(values);
        end
        grid(ax,'on'); ylim(ax,[0 max(upper*1.15,eps)]);
        xticks(ax,1:height(data)); xticklabels(ax,labels);
        ax.TickLabelInterpreter='none'; ax.FontSize=10;
        xtickangle(ax,45); ylabel(ax,'Relativer L2-Fehler [%]');
        title(ax,metricNames{k},'FontSize',12);
        xlabel(ax,'Konfiguration, nach mittlerem Fehler sortiert');
    end
    title(layout,[studyTitle; ...
        "768 Trainingsfaelle; 128 Validierungsfaelle; drei Seeds"], ...
        'Interpreter','none','FontSize',14);
    exportgraphics(fig,fullfile(outputDir,study+"_four_metrics.png"),'Resolution',150);
    close(fig);
end
for width=[64 128]
    data=summary(summary.Study=="architecture_loss" & summary.Width==width & ...
        summary.Dataset=="existing_validation_128" & summary.LossMode=="weighted_field_mse",:);
    fig=figure('Visible','off','Color','white','Position',[50 50 1300 850]);
    layout=tiledlayout(fig,2,2,'TileSpacing','loose','Padding','loose');
    for k=1:4
        ax=nexttile(layout); hold(ax,'on');
        for depth=1:5
            subset=sortrows(data(data.HiddenLayers==depth,:),'TrainingCases');
            plot(ax,subset.TrainingCases,subset.(fields{k}),'-o','LineWidth',1.3, ...
                'DisplayName',sprintf('%d Schichten',depth));
        end
        if all(data.(fields{k})>0), ax.YScale='log'; end
        ax.XScale='log'; xticks(ax,unique(data.TrainingCases)); grid(ax,'on');
        xlabel(ax,'Trainingsfaelle'); ylabel(ax,'Relativer L2-Fehler [%], logarithmisch');
        title(ax,metricNames{k}); legend(ax,'Location','best','FontSize',9);
    end
    title(layout,sprintf('Breite %d; gewichtete Feld-MSE; 128 Validierungsfaelle; drei Seeds',width));
    exportgraphics(fig,fullfile(outputDir,sprintf('learning_curves_width_%d.png',width)), ...
        'Resolution',150);
    close(fig);
end
end
