function comparePrevious(out,cfg)
    %comparePrevious Describe rerun differences without changing model selection.
    previous=fullfile(cfg.paths.reference_run,'run_results.csv');
    if cfg.reference_mode~="reuse" || ~isfile(previous)
        return;
    end
    old=readtable(previous,'TextType','string');
    current=readtable(fullfile(out,'run_results.csv'),'TextType','string');
    oldKey=replace(old.id,"\","/")+"|"+old.role;
    newKey=replace(current.id,"\","/")+"|"+current.role;
    [matched,location]=ismember(newKey,oldKey);
    assert(all(matched) && height(current)==height(old),'study:Comparison', ...
        'Run identities differ from the previous study.');
    old=old(location,:);
    assert(all(current.method==old.method & current.N==old.N),'study:Comparison','Method or training count changed.');
    comparison=table(current.id,current.role,current.avg,old.avg,current.avg-old.avg,  current.p95-old.p95, ...
        current.worst-old.worst,  current.fitSeconds,  old.fitSeconds,  'VariableNames',  {'RunId','Role', ...
        'NewMean','OldMean','MeanDifference',  'P95Difference',  'MaximumDifference',  'NewFitSeconds',  'HistoricalFitSeconds'});
    writetable(comparison,fullfile(out,'comparison_previous.csv'));
    oldSelection=load(fullfile(cfg.paths.reference_run,'selections.mat'),'selections');
    newSelection=load(fullfile(out,'selections.mat'),'selections');
    same=true;
    for method=string(cfg.methods(:)')
        same=same && isequaln(orderfields(oldSelection.selections.(method)), ...
            orderfields(newSelection.selections.(method)));
    end
    maximum=max(abs(comparison.MeanDifference));
    writelines(["# Vergleich mit der historischen Hauptstudie"; "";  "Gleiche gewaehlte Konfigurationen: "+string(same);  "Maximale absolute Differenz der mittleren relativen Fallfehler: "+string(maximum);  "Vollstaendige Zuordnung und neue/historische Fit-Zeiten: comparison_previous.csv.";  "Bekannte Referenzfaelle: diese Wiederholung ist kein neuer unabhaengiger Abschlusstest.";  "Numerische Abweichungen werden dokumentiert und nicht durch nachtraegliche Auswahl korrigiert."],  fullfile(out,'VERGLEICH.md'));
end
