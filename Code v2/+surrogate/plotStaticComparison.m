function [figures,results] = plotStaticComparison(models,reference,metricConfig)
%plotStaticComparison Plot static field errors for saved surrogate models.
%   MODELS is a struct array with fields label and model. All models are
%   evaluated on the same validated reference cases, in their given order.
surrogate.validateDataset(reference);
assert(string(reference.modality)=="static" && string(reference.split)=="val", ...
    'surrogate:plot:Reference','A static validation split is required.');
assert(isstruct(models) && ~isempty(models) && all(isfield(models,{'label','model'})), ...
    'surrogate:plot:Models','Provide at least one model with label and model fields.');
labels=string({models.label});
assert(all(strlength(labels)>0) && numel(unique(labels))==numel(labels), ...
    'surrogate:plot:Labels','Model labels must be nonempty and unique.');
request=struct('inputParameters',reference.inputParameters, ...
    'parameterNames',reference.parameterNames,'parameterUnits',reference.parameterUnits, ...
    'caseIds',reference.caseIds);
results=repmat(struct('label',"",'metrics',struct(), ...
    'medianRelativeError',NaN,'p95RelativeError',NaN,'undefinedCount',0),numel(models),1);
for k=1:numel(models)
    prediction=surrogate.predictModel(models(k).model,request);
    metrics=surrogate.evaluatePrediction(prediction,reference,metricConfig);
    valid=sort(metrics.relativeWeightedFieldError(metrics.relativeErrorDefined));
    results(k).label=labels(k);
    results(k).metrics=metrics;
    results(k).undefinedCount=nnz(~metrics.relativeErrorDefined);
    if ~isempty(valid)
        results(k).medianRelativeError=median(valid);
        results(k).p95RelativeError=valid(ceil(0.95*numel(valid)));
    end
end

% Per-case absolute errors and aggregate relative errors use different units.
figures(1)=figure('Name','Absoluter Feldfehler - Validierung','NumberTitle','off');
ax=axes(figures(1)); hold(ax,'on');
for k=1:numel(results)
    plot(ax,1:numel(reference.caseIds),results(k).metrics.absoluteWeightedFieldError, ...
        '-o','DisplayName',char(labels(k)));
end
hold(ax,'off'); grid(ax,'on');
xticks(ax,1:numel(reference.caseIds)); xticklabels(ax,string(reference.caseIds));
xtickangle(ax,45); xlabel(ax,'FEM-Fall-ID');
ylabel(ax,'Gewichteter absoluter Feldfehler [m]');
title(ax,'Absolutfehler je Validierungsfall'); legend(ax,'Location','best','Interpreter','none');

figures(2)=figure('Name','Median und P95 - Validierung','NumberTitle','off');
ax=axes(figures(2));
values=100*[[results.medianRelativeError]' [results.p95RelativeError]'];
positions=1:numel(labels);
hold(ax,'on');
medianBars=bar(ax,positions-0.2,values(:,1),0.4);
p95Bars=bar(ax,positions+0.2,values(:,2),0.4);
hold(ax,'off'); grid(ax,'on');
xticks(ax,1:numel(labels)); xticklabels(ax,labels); ax.TickLabelInterpreter='none';
ylabel(ax,'Gewichteter relativer Feldfehler [%]');
title(ax,sprintf('Median und P95 (Nearest Rank); undefiniert: %s', ...
    strjoin(string([results.undefinedCount]),', ')),'Interpreter','none');
legend(ax,[medianBars p95Bars],{'Median','P95'},'Location','best');
end
