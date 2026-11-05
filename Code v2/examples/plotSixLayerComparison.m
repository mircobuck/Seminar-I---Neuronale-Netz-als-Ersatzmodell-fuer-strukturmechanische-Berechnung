function plotSixLayerComparison(root)
dirs={'mein_lernkurven_lauf','lernkurven_2_hidden_layer','lernkurven_3_hidden_layer', ...
    'lernkurven_4_hidden_layer','lernkurven_5_hidden_layer','lernkurven_6_hidden_layer'};
data=cell(1,6);
for m=1:6, data{m}=load(fullfile(root,dirs{m},'learning_curve.mat')); end
base=data{1};
for m=2:6
    d=data{m}; assert(isequal(base.counts,d.counts) && isequal(base.seeds,d.seeds));
    for k=1:numel(base.details)
        ref=base.details(k); j=find([d.details.count]==ref.count & [d.details.seed]==ref.seed);
        assert(isscalar(j) && isequal(ref.trainingIds,d.details(j).trainingIds));
        assert(isequal(ref.metrics.caseIds,d.details(j).metrics.caseIds));
    end
end
names={'Mittlerer Absolutfehler','Median','P95'};
files={'vergleich_1_bis_6_absolut.png','vergleich_1_bis_6_median.png','vergleich_1_bis_6_p95.png'};
colors=lines(6); outputDir=fullfile(root,dirs{6});
for metric=1:3
    f=figure('Visible','off','Position',[100 100 1500 520]);
    t=tiledlayout(f,1,numel(base.seeds),'TileSpacing','compact');
    for k=1:numel(base.seeds)
        ax=nexttile(t); hold(ax,'on');
        for m=1:6
            d=data{m}; values=zeros(size(d.counts));
            for n=1:numel(d.counts)
                ix=find([d.details.seed]==base.seeds(k) & [d.details.count]==d.counts(n));
                row=find(d.summary.Seed==base.seeds(k) & d.summary.TrainingCases==d.counts(n));
                if metric==1, values(n)=mean(d.details(ix).metrics.absoluteWeightedFieldError);
                elseif metric==2, values(n)=d.summary.MedianRelativePercent(row);
                else, values(n)=d.summary.P95RelativePercent(row); end
            end
            plot(ax,d.counts,values,'-o','Color',colors(m,:),'LineWidth',1.3, ...
                'DisplayName',sprintf('%d Schicht(en)',m));
        end
        grid(ax,'on'); xticks(ax,base.counts); xlabel(ax,'Trainingsfälle');
        if metric==1, ylabel(ax,'Mittlerer gewichteter absoluter Feldfehler [m]');
        else, ylabel(ax,'Gewichteter relativer Feldfehler [%]'); end
        title(ax,sprintf('Seed %d',base.seeds(k)));
        if k==1, legend(ax,'Location','best'); end
    end
    title(t,sprintf('%s: POD-MLP, %d Validierungsfälle',names{metric},numel(base.details(1).metrics.caseIds)));
    exportgraphics(f,fullfile(outputDir,files{metric}),'Resolution',160); close(f);
end
end
