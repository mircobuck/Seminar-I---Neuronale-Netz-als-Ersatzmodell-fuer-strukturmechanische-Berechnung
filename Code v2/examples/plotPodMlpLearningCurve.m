function figures = plotPodMlpLearningCurve(outputDir)
%plotPodMlpLearningCurve Plot validation errors from a learning-curve run.
%   Uses saved case metrics; no model training or test data is required.
data=load(fullfile(outputDir,'learning_curve.mat'),'summary','details','counts','seeds');
summary=data.summary; details=data.details; counts=data.counts; seeds=data.seeds;
ids=details(1).metrics.caseIds;
assert(all(arrayfun(@(x)isequal(x.metrics.caseIds,ids),details)), ...
    'surrogate:learningCurve:Cases','Validation case IDs or order differ.');

% The absolute curve is the mean of all validation-case absolute errors.
names={'Absolutfehler','Median','P95'};
files={'absolut_lernkurve.png','median_lernkurve.png','p95_lernkurve.png'};
figures=gobjects(1,3);
for metric=1:3
    figures(metric)=figure('Name',names{metric},'NumberTitle','off');
    ax=axes(figures(metric)); hold(ax,'on');
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
            else
                values(j)=summary.P95RelativePercent(row);
            end
        end
        plot(ax,counts,values,'-o','DisplayName',sprintf('Seed %d',seed));
    end
    hold(ax,'off'); grid(ax,'on'); xticks(ax,counts);
    xlabel(ax,'Anzahl Trainingsfälle');
    if metric==1
        ylabel(ax,'Mittlerer gewichteter absoluter Feldfehler [m]');
    else
        ylabel(ax,'Gewichteter relativer Feldfehler [%]');
    end
    title(ax,sprintf('POD_MLP_ADAM_64: %s, Validierung (%d Fälle)',names{metric},numel(ids)), ...
        'Interpreter','none');
    legend(ax,'Location','best');
    exportgraphics(figures(metric),fullfile(outputDir,files{metric}),'Resolution',160);
end
end
