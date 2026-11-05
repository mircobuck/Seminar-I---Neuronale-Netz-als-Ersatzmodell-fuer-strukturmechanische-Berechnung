function plotLayerComparison(oldDir,newDir,thirdDir)
if nargin<3, thirdDir=newDir; modelCount=2; else, modelCount=3; end
a=load(fullfile(oldDir,'learning_curve.mat')); b=load(fullfile(newDir,'learning_curve.mat')); c=load(fullfile(thirdDir,'learning_curve.mat'));
assert(isequal(a.counts,c.counts) && isequal(a.seeds,c.seeds));
assert(isequal(a.counts,b.counts) && isequal(a.seeds,b.seeds));
for k=1:numel(a.details)
    j=find([b.details.count]==a.details(k).count & [b.details.seed]==a.details(k).seed);
    assert(isscalar(j) && isequal(a.details(k).trainingIds,b.details(j).trainingIds));
    assert(isequal(a.details(k).metrics.caseIds,b.details(j).metrics.caseIds));
    j=find([c.details.count]==a.details(k).count & [c.details.seed]==a.details(k).seed);
    assert(isscalar(j) && isequal(a.details(k).trainingIds,c.details(j).trainingIds));
    assert(isequal(a.details(k).metrics.caseIds,c.details(j).metrics.caseIds));
end
names={'Mittlerer Absolutfehler','Median','P95'};
files={'vergleich_absolut.png','vergleich_median.png','vergleich_p95.png'};
colors=lines(numel(a.seeds));
for metric=1:3
    f=figure('Visible','off'); ax=axes(f); hold(ax,'on');
    for k=1:numel(a.seeds)
        for model=1:modelCount
            if model==1, d=a; style='-o'; elseif model==2, d=b; style='--s'; else, d=c; style=':d'; end
            values=zeros(size(d.counts));
            for n=1:numel(d.counts)
                ix=find([d.details.seed]==d.seeds(k) & [d.details.count]==d.counts(n));
                row=find(d.summary.Seed==d.seeds(k) & d.summary.TrainingCases==d.counts(n));
                if metric==1, values(n)=mean(d.details(ix).metrics.absoluteWeightedFieldError);
                elseif metric==2, values(n)=d.summary.MedianRelativePercent(row);
                else, values(n)=d.summary.P95RelativePercent(row); end
            end
            plot(ax,d.counts,values,style,'Color',colors(k,:),'LineWidth',1.3, ...
                'DisplayName',sprintf('%d Hidden Layer, Seed %d',model,d.seeds(k)));
        end
    end
    grid(ax,'on'); xticks(ax,a.counts); xlabel(ax,'Anzahl Trainingsfälle');
    if metric==1, ylabel(ax,'Mittlerer gewichteter absoluter Feldfehler [m]');
    else, ylabel(ax,'Gewichteter relativer Feldfehler [%]'); end
    title(ax,sprintf('%s: POD-MLP auf %d Validierungsfällen',names{metric},numel(a.details(1).metrics.caseIds)));
    legend(ax,'Location','best'); exportgraphics(f,fullfile(thirdDir,files{metric}),'Resolution',160); close(f);
end
end
