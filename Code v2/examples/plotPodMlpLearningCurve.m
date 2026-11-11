function figures = plotPodMlpLearningCurve(outputDir)
%plotPodMlpLearningCurve Plot validation errors from a learning-curve run.
%   Uses saved case metrics; no model training or test data is required.
data=load(fullfile(outputDir,'learning_curve.mat'),'summary','details','counts','seeds');
summary=data.summary; details=data.details; counts=data.counts; seeds=data.seeds;
ids=details(1).metrics.caseIds;
assert(all(arrayfun(@(x)isequal(x.metrics.caseIds,ids),details)), ...
    'surrogate:learningCurve:Cases','Validation case IDs or order differ.');

% The absolute curve is the mean of all validation-case absolute errors.
names={'Absolutfehler','Median','P95','Mittelwert relativer L2-Fehler (Hauptmetrik)','Maximum relativer L2-Fehler'};
files={'absolut_lernkurve.png','median_lernkurve.png','p95_lernkurve.png','relative_l2_mean_lernkurve.png','relative_l2_maximum_lernkurve.png'};
figures=gobjects(1,5);
for metric=1:5
    figures(metric)=figure('Name',names{metric},'NumberTitle','off');
    ax=axes('Parent',figures(metric)); hold(ax,'on');
    for seed=seeds
        values=nan(size(counts));
        for j=1:numel(counts)
            index=find([details.seed]==seed & [details.count]==counts(j));
            row=find(summary.Seed==seed & summary.TrainingCases==counts(j));
            assert(isscalar(index) && isscalar(row), ...
                'surrogate:learningCurve:Runs','Missing or duplicate run.');
            if metric==1
                values(j)=mean(details(index).metrics.absoluteWeightedFieldError);
            elseif metric==2
                values(j)=summary.MedianRelativePercent(row);
            elseif metric==3
                values(j)=summary.P95RelativePercent(row);
            else
                metrics=details(index).metrics;
                relative=metrics.relativeWeightedFieldError(metrics.relativeErrorDefined);
                if isempty(relative)
                    values(j)=NaN;
                elseif metric==4
                    values(j)=100*mean(relative);
                else
                    values(j)=100*max(relative);
                end
            end
        end
        plot(ax,counts,values,'-o','DisplayName',sprintf('Seed %d',seed));
    end
    hold(ax,'off'); grid(ax,'on'); xticks(ax,counts);
    xlabel(ax,'Anzahl Trainingsfälle');
    if metric==1
        ylabel(ax,'Mittlerer gewichteter absoluter Feldfehler [m]');
    else
        ylabel(ax,'Relativer gewichteter L2-Fehler [%]');
    end
    title(ax,sprintf('POD-MLP: %s, Validierung (%d Fälle)',names{metric},numel(ids)), ...
        'Interpreter','none');
    legend(ax,'Location','best');
    exportgraphics(figures(metric),fullfile(outputDir,files{metric}),'Resolution',160);
end
end
