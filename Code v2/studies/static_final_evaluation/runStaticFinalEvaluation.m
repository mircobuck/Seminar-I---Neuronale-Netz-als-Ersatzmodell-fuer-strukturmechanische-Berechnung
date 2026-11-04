function result = runStaticFinalEvaluation(config,outputDir)
%runStaticFinalEvaluation Evaluate frozen static models on a specified split.
%   CONFIG records decisions before reference labels are loaded; see README.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(root);
required={'datasetFile','datasetId','split','selectionRule','freezeDescription', ...
    'testLabelHistory','metricConfig','models'};
assert(isstruct(config) && isscalar(config) && all(isfield(config,required)), ...
    'surrogate:final:Config','Missing study configuration fields.');
for name={'datasetFile','datasetId','split','selectionRule','freezeDescription','testLabelHistory'}
    value=string(config.(name{1}));
    assert(isscalar(value) && ~ismissing(value) && strlength(strtrim(value))>0, ...
        'surrogate:final:Config','%s must be documented.',name{1});
end
assert(string(config.split)=="test",'surrogate:final:Split','The final study requires the test split.');
assert(isstruct(config.metricConfig) && isscalar(config.metricConfig) && ...
    all(isfield(config.metricConfig,{'staticReferenceFloor','metrics','summaryStatistics'})), ...
    'surrogate:final:Config','Static metrics and their threshold must be specified.');
threshold=config.metricConfig.staticReferenceFloor;
assert(isnumeric(threshold) && isreal(threshold) && isscalar(threshold) && ...
    isfinite(threshold) && threshold>=0, ...
    'surrogate:final:Config','The static reference threshold must be finite and nonnegative.');
expectedMetrics=["weighted_absolute_field_error_m", ...
    "reference_weighted_field_norm_m","relative_weighted_field_error"];
expectedStatistics=["mean","median","nearest_rank_p95","maximum"];
assert(isequal(reshape(string(config.metricConfig.metrics),1,[]),expectedMetrics) && ...
    isequal(reshape(string(config.metricConfig.summaryStatistics),1,[]),expectedStatistics), ...
    'surrogate:final:Config','Metric names or summary statistics differ from the static study.');
assert(isstruct(config.models) && ~isempty(config.models) && ...
    all(isfield(config.models,{'label','file'})), ...
    'surrogate:final:Config','Specify model labels and files.');
labels=string({config.models.label}); files=string({config.models.file});
assert(all(~ismissing(labels)) && all(strlength(strtrim(labels))>0) && ...
    numel(unique(labels))==numel(labels) && all(~ismissing(files)) && ...
    all(strlength(strtrim(files))>0), ...
    'surrogate:final:Config','Model labels must be unique and model paths nonempty.');
assert((ischar(outputDir) || (isstring(outputDir) && isscalar(outputDir))) && ...
    strlength(string(outputDir))>0 && ~isfolder(outputDir) && ~isfile(outputDir), ...
    'surrogate:final:Exists','Output path already exists: %s',outputDir);
[created,message]=mkdir(outputDir);
assert(created,'surrogate:final:Directory','Cannot create output directory: %s',message);
% Persist the declared selection and metric choices before opening labels.
save(fullfile(outputDir,'study_config.mat'),'config');
reference=surrogate.loadDataset(config.datasetFile);
assert(string(reference.modality)=="static" && string(reference.split)==string(config.split), ...
    'surrogate:final:Reference','Expected a static reference of the configured split.');
request=struct('inputParameters',reference.inputParameters,'parameterNames',reference.parameterNames, ...
    'parameterUnits',reference.parameterUnits,'caseIds',reference.caseIds);
metricConfig=struct('staticReferenceFloor',threshold,'frequencyReferenceFloorHz',0);
n=numel(config.models);
details=repmat(struct('label',"",'file',"",'status',"failed",'errorId',"", ...
    'errorMessage',"",'modelMetadata',struct(),'metrics',struct()),n,1);
cases=table();
summary=table(labels(:),strings(n,1),nan(n,1),nan(n,1),nan(n,1),nan(n,1), ...
    nan(n,1),nan(n,1),nan(n,1),nan(n,1),zeros(n,1),zeros(n,1), ...
    'VariableNames',{'Model','Status','AbsoluteMeanM','AbsoluteMedianM','AbsoluteP95M', ...
    'AbsoluteMaxM','RelativeMean','RelativeMedian','RelativeP95','RelativeMax', ...
    'DefinedCount','UndefinedCount'});
for k=1:n
    details(k).label=labels(k); details(k).file=files(k);
    try
        model=surrogate.loadModel(files(k));
        assert(isempty(intersect(model.trainingCaseIds,reference.caseIds)), ...
            'surrogate:final:Overlap','Training and evaluation case IDs overlap.');
        details(k).modelMetadata=rmfield(model,'state');
        prediction=surrogate.predictModel(model,request);
        metrics=surrogate.evaluatePrediction(prediction,reference,metricConfig);
        details(k).metrics=metrics; details(k).status="complete";
        absolute=metrics.absoluteWeightedFieldError;
        relative=metrics.relativeWeightedFieldError(metrics.relativeErrorDefined);
        astats=statistics(absolute); rstats=statistics(relative);
        summary{k,3:10}=[astats rstats];
        summary.DefinedCount(k)=numel(relative);
        summary.UndefinedCount(k)=nnz(~metrics.relativeErrorDefined);
        reason=repmat("",numel(absolute),1);
        reason(~metrics.relativeErrorDefined)="reference_norm_at_or_below_threshold";
        block=table(repmat(labels(k),numel(absolute),1),metrics.caseIds,absolute, ...
            metrics.referenceWeightedFieldNorm,metrics.relativeWeightedFieldError, ...
            metrics.relativeErrorDefined,reason, ...
            'VariableNames',{'Model','CaseId','AbsoluteErrorM','ReferenceNormM', ...
            'RelativeError','RelativeDefined','UndefinedReason'});
        cases=[cases;block]; %#ok<AGROW>
    catch ME
        details(k).errorId=string(ME.identifier);
        details(k).errorMessage=string(ME.message);
    end
    summary.Status(k)=details(k).status;
end
metadata=struct('task',"static_displacement_field",'datasetId',string(config.datasetId), ...
    'datasetFile',string(config.datasetFile),'split',string(config.split), ...
    'caseIds',reference.caseIds,'matlabVersion',string(version), ...
    'createdAt',string(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXX')));
result=struct('summary',summary,'cases',cases,'details',details,'metadata',metadata);
save(fullfile(outputDir,'results.mat'),'result','-v7.3');
writetable(summary,fullfile(outputDir,'summary.csv'));
if ~isempty(cases), writetable(cases,fullfile(outputDir,'case_errors.csv')); end
failures=table(labels(:),string({details.status})',string({details.errorId})', ...
    string({details.errorMessage})','VariableNames',{'Model','Status','ErrorId','ErrorMessage'});
writetable(failures,fullfile(outputDir,'run_status.csv'));
plotResults(summary,outputDir);
end

function values=statistics(x)
x=sort(x(:));
if isempty(x), values=nan(1,4); return; end
values=[mean(x),median(x),x(ceil(.95*numel(x))),max(x)];
end

function plotResults(summary,outputDir)
names={'Mittlerer Absolutfehler','Median','P95'};
fields={'AbsoluteMeanM','AbsoluteMedianM','AbsoluteP95M'};
files={'absolute_mean.png','median.png','p95.png'};
for i=1:3
    fig=figure('Visible','off','Name',names{i});
    cleanup=onCleanup(@()close(fig));
    ax=axes(fig); values=summary.(fields{i});
    bar(ax,values); xticks(ax,1:height(summary)); xticklabels(ax,summary.Model);
    ax.TickLabelInterpreter='none'; xtickangle(ax,30); grid(ax,'on');
    ylabel(ax,'Gewichteter absoluter Feldfehler [m]');
    title(ax,[names{i} ' – Testsplit']);
    exportgraphics(fig,fullfile(outputDir,files{i}),'Resolution',150);
    clear cleanup
end
end
