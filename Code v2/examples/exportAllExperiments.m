function exportAllExperiments(root)
% Export per-run and per-validation-case results from saved learning curves.
runRows=cell(216,11); caseRows=cell(216*12,8); i=0; j=0;
for width=[64 128]
    maxLayers=6;
    for layers=1:maxLayers
        if width==64 && layers==1
            folder='mein_lernkurven_lauf';
        elseif width==64
            folder=sprintf('lernkurven_%d_hidden_layer',layers);
        else
            folder=sprintf('lernkurven_128_%d_layer',layers);
        end
        d=load(fullfile(root,folder,'learning_curve.mat'));
        assert(numel(d.details)==18);
        for k=1:numel(d.details)
            x=d.details(k); m=x.metrics; r=find(d.summary.Seed==x.seed & d.summary.TrainingCases==x.count);
            assert(isscalar(r)); i=i+1;
            relative=m.relativeWeightedFieldError(m.relativeErrorDefined);
            meanRelative=NaN; maximumRelative=NaN;
            if ~isempty(relative)
                meanRelative=100*mean(relative); maximumRelative=100*max(relative);
            end
            runRows(i,:)={width,layers,x.count,x.seed,mean(m.absoluteWeightedFieldError), ...
                d.summary.MedianRelativePercent(r),d.summary.P95RelativePercent(r), ...
                d.summary.UndefinedCount(r),fullfile(folder,x.modelFile),meanRelative,maximumRelative};
            for c=1:numel(m.caseIds)
                j=j+1; caseRows(j,:)={width,layers,x.count,x.seed,string(m.caseIds(c)), ...
                    m.absoluteWeightedFieldError(c),m.relativeWeightedFieldError(c),m.relativeErrorDefined(c)};
            end
        end
    end
end
out=fullfile(root,'POD_MLP_Versuchsprotokoll'); if ~isfolder(out), mkdir(out); end
runs=cell2table(runRows(1:i,:),'VariableNames',{'NeuronsPerLayer','HiddenLayers','TrainingCases','Seed', ...
    'MeanAbsoluteError_m','MedianRelativePercent','P95RelativePercent','UndefinedCount','ModelFile', ...
    'MeanRelativePercent','MaximumRelativePercent'});
cases=cell2table(caseRows(1:j,:),'VariableNames',{'NeuronsPerLayer','HiddenLayers','TrainingCases','Seed', ...
    'ValidationCaseId','AbsoluteError_m','RelativeError','RelativeErrorDefined'});
writetable(runs,fullfile(out,'alle_versuchslaeufe.csv'));
writetable(cases,fullfile(out,'alle_validierungsfaelle.csv'));
fprintf('Exported %d runs and %d validation observations.\n',i,j);
end
