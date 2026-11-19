function summary = showStaticResultsExample(outputDirectory)
%showStaticResultsExample Display saved tables without loading models or training.
arguments
    outputDirectory (1,1) string
end
summary=readtable(fullfile(outputDirectory,'pipeline_summary.csv'),'TextType','string');
disp(summary);
figure;
hold on;
methods=unique(summary.method,'stable');
for method=methods(:)'
    rows=summary(summary.method==method & summary.role=="interpolation",:);
    plot(rows.n,100*rows.meanError,'-o','DisplayName',method);
end
xlabel('Training cases');
ylabel('Mean weighted relative field error [%]');
legend('Location','best');
grid on;
end
