function plots(out,cfg,rows,modes,cases,analytic)
%plots Compact scientific figures from report tables, never from a new model fit.
folder=fullfile(out,'figures'); if ~isfolder(folder), mkdir(folder); end
methods=string(cfg.methods(:)'); colors=[0 .447 .741; .85 .325 .098; .466 .674 .188; .494 .184 .556];
fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]); theme(fig,'light'); cleanup=onCleanup(@()close(fig));
hold on;
for m=1:numel(methods)
    part=rows(rows.Method==methods(m) & rows.Role=="main" & rows.Status=="ok",:);
    sizes=unique(part.N); avg=zeros(size(sizes)); low=avg; high=avg;
    for j=1:numel(sizes)
        e=100*part.MeanError(part.N==sizes(j)); avg(j)=mean(e); low(j)=min(e); high(j)=max(e);
    end
    errorbar(sizes,avg,avg-low,high-avg,'-o','Color',colors(m,:),'DisplayName',methods(m));
end
xlabel('Training cases'); ylabel('Mean relative frequency error (%)'); grid on;
title('Known test cases: mean and range across runs'); legend('Location','best','Interpreter','none');
exportgraphics(fig,fullfile(folder,'learning_curve.png'),'Resolution',160); clear cleanup

fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]); theme(fig,'light'); cleanup=onCleanup(@()close(fig));
errors=nan(6,numel(methods)+1); errors(:,end)=100*mean(analytic,1)';
for m=1:numel(methods)
    part=rows(rows.Method==methods(m) & rows.Role=="main" & rows.N==max(cfg.training_sizes) & rows.Status=="ok",:);
    for j=1:6, errors(j,m)=100*mean(modes.MeanError(ismember(modes.RunId,part.RunId) & modes.Mode==j)); end
end
bar(1:6,errors); xlabel('Frequency rank'); ylabel('Mean relative error (%)'); grid on;
legend([methods,"Euler-Bernoulli bending"],'Interpreter','none','Location','best');
title('Frequency-rank errors (no mode-family identification)');
exportgraphics(fig,fullfile(folder,'errors_by_rank.png'),'Resolution',160); clear cleanup

fig=figure('Visible','off','Color','white','Position',[100 100 1000 720]); theme(fig,'light'); cleanup=onCleanup(@()close(fig));
for m=1:numel(methods)
    subplot(2,2,m);
    part=rows(rows.Method==methods(m) & rows.Role=="main" & rows.N==max(cfg.training_sizes) & rows.Seed==cfg.seed_tuning,:);
    points=cases(ismember(cases.RunId,part.RunId),:);
    scatter(points.ReferenceHz,points.PredictionHz,10,points.Mode,'filled'); hold on;
    if ~isempty(points), lim=[0 max(points.ReferenceHz)*1.05]; plot(lim,lim,'k--'); end
    xlabel('FEM (Hz)'); ylabel('Prediction (Hz)'); title(methods(m),'Interpreter','none'); grid on;
end
exportgraphics(fig,fullfile(folder,'parity.png'),'Resolution',160); clear cleanup

fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]); theme(fig,'light'); cleanup=onCleanup(@()close(fig)); hold on;
for method=["pod_mlp","pod_gpr"]
    part=sortrows(rows(rows.Method==method & rows.Role=="rank",:),'Rank');
    plot(part.Rank,100*part.MeanError,'-o','DisplayName',method);
end
xlabel('POD rank'); ylabel('Mean relative frequency error (%)'); grid on;
legend('Interpreter','none','Location','best'); title(sprintf('POD rank diagnostic: fixed settings, seed %d',cfg.seed_tuning));
exportgraphics(fig,fullfile(folder,'pod_rank.png'),'Resolution',160); clear cleanup

fig=figure('Visible','off','Color','white','Position',[100 100 1000 650]); theme(fig,'light'); cleanup=onCleanup(@()close(fig));
seconds=nan(numel(methods),1);
for m=1:numel(methods)
    seconds(m)=median(rows.FitSeconds(rows.Method==methods(m) & rows.Role=="main" & ...
        rows.N==max(cfg.training_sizes) & rows.Status=="ok"));
end
bar(categorical(methods),seconds); ylabel('Median full-pool fit time (s)'); grid on;
exportgraphics(fig,fullfile(folder,'fit_times.png'),'Resolution',160);
end
