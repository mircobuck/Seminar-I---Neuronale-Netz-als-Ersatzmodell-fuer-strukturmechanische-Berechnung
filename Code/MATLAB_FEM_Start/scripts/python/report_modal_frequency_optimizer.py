"""Report the frozen modal optimizer comparison from its MATLAB exports."""
from __future__ import annotations
import collections
import csv
import hashlib
import math
from pathlib import Path
import statistics
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'experiments/active/modal_frequency_optimizer_20261029_v1'

def read(name):
    with (OUT/name).open(encoding='utf-8-sig',newline='') as f:
        return list(csv.DictReader(f))

def put(path, text):
    data=text.encode('utf-8')
    if path.exists():
        if path.read_bytes()!=data: raise RuntimeError(f'Artifact conflict: {path}')
    else:
        with path.open('xb') as f: f.write(data)

def p95(values):
    a=sorted(values)
    return a[math.ceil(.95*len(a))-1]

def main():
    runs=read('cv_run_summary.csv'); cases=read('cv_case_frequency_metrics.csv'); modes=read('mode_summary.csv')
    ledger=read('attempt_ledger_final.csv'); sel=read('selection.csv')[0]
    assert len(runs)==21 and len(cases)==21*128*6
    assert sum(r['Stage']=='cv' and r['Status']=='completed' for r in ledger)==21
    assert sum(r['Stage']=='final' and r['Status']=='completed' for r in ledger)==3
    for model in ('adam','lbfgs'):
        score=statistics.mean(float(c['RelativeRaw']) for c in cases if c['Model']==model)
        assert abs(score-float(sel['adamMean' if model=='adam' else 'lbfgsMean']))<1e-12
    grouped=collections.defaultdict(list)
    for c in cases:
        grouped[(c['Model'],int(c['Fold']),int(c['Seed']),int(c['Mode']))].append(c)
    detailed=[]
    for key,items in sorted(grouped.items()):
        assert len(items)==128
        row=dict(zip(('Model','Fold','Seed','Mode'),key))
        for representation in ('Raw','Sorted'):
            rel=[float(x['Relative'+representation]) for x in items]
            ab=[float(x['Absolute'+representation+'Hz']) for x in items]
            for name,v in [('Mean',statistics.mean(rel)),('Median',statistics.median(rel)),('P95',p95(rel)),('Max',max(rel))]: row[name+'Relative'+representation]=v
            for name,v in [('Mean',statistics.mean(ab)),('Median',statistics.median(ab)),('P95',p95(ab)),('Max',max(ab))]: row[name+'Absolute'+representation+'Hz']=v
        detailed.append(row)
    path=OUT/'mode_fold_seed_summary.csv'
    import io
    sio=io.StringIO(newline=''); w=csv.DictWriter(sio,fieldnames=list(detailed[0]),lineterminator='\n'); w.writeheader(); w.writerows(detailed); put(path,sio.getvalue())
    spreads=[]
    for model in ('adam','lbfgs','gpr'):
        for mode in range(1,7):
            rr=[r for r in detailed if r['Model']==model and r['Mode']==mode]
            fold=[statistics.mean(r['MeanRelativeRaw'] for r in rr if r['Fold']==f) for f in (1,2,3)]
            seeds=[] if model=='gpr' else [statistics.mean(r['MeanRelativeRaw'] for r in rr if r['Seed']==s) for s in (42,43,44)]
            spreads.append({'Model':model,'Mode':mode,'FoldMin':min(fold),'FoldMax':max(fold),'FoldSD':statistics.stdev(fold),
                'SeedMin':min(seeds) if seeds else '', 'SeedMax':max(seeds) if seeds else '', 'SeedSD':statistics.stdev(seeds) if seeds else ''})
    sio=io.StringIO(newline=''); w=csv.DictWriter(sio,fieldnames=list(spreads[0]),lineterminator='\n'); w.writeheader(); w.writerows(spreads); put(OUT/'mode_spread.csv',sio.getvalue())
    violation=collections.Counter(); casecount=collections.Counter(); predictions=collections.defaultdict(dict)
    for c in cases: predictions[(c['Model'],c['Fold'],c['Seed'],c['CaseID'])][int(c['Mode'])]=float(c['RawHz'])
    for (model,fold,seed,case),d in predictions.items():
        assert len(d)==6; casecount[model]+=1
        for j in range(1,6): violation[(model,j)]+=d[j]>d[j+1]
    sio=io.StringIO(newline=''); w=csv.writer(sio,lineterminator='\n'); w.writerow(['Model','AdjacentPair','Violations','EvaluatedCasePredictions','Fraction'])
    for model in ('adam','lbfgs','gpr'):
        for j in range(1,6): w.writerow([model,f'{j}-{j+1}',violation[(model,j)],casecount[model],violation[(model,j)]/casecount[model]])
    put(OUT/'ordering_by_pair.csv',sio.getvalue())
    fig,axes=plt.subplots(1,2,figsize=(12,4.8),layout='constrained')
    for model in ('adam','lbfgs','gpr'):
        mr=sorted([r for r in modes if r['Model']==model and r['Representation']=='raw'],key=lambda x:int(x['Mode']))
        axes[0].plot([int(r['Mode']) for r in mr],[100*float(r['P95Relative']) for r in mr],marker='o',label=model.upper())
        rr=[r for r in runs if r['Model']==model]
        axes[1].scatter([float(r['TrainingSeconds']) for r in rr],[100*float(r['MeanRawRelative']) for r in rr],label=model.upper())
    axes[0].set(title='P95 by frequency index (raw)',xlabel='Frequency index',ylabel='Relative error (%)',xticks=range(1,7))
    axes[1].set(title='Fold / seed performance and fit cost',xlabel='Fit time (s)',ylabel='Mean relative frequency error (%)')
    for ax in axes: ax.legend(); ax.grid(alpha=.25)
    if not (OUT/'comparison.png').exists(): fig.savefig(OUT/'comparison.png',dpi=180)
    plt.close(fig)
    lines=['# Kontrollierter Optimierervergleich: Eigenfrequenzen','',
        'Stand: 29.10.2026. Dreifache Kreuzvalidierung innerhalb von 384 vorhandenen Modal-Trainingsfaellen; kein unabhaengiger Abschlusstest. Sechs aufsteigend sortierte Frequenzen sind keine Eigenformvorhersage und kein Modenfamilien-Tracking.',
        '',f"Auswahl nach vorab festgelegter mittlerer relativer Fehlerquote der rohen Hz-Ausgaben: **{sel['optimizer'].upper()}**. Adam: {100*float(sel['adamMean']):.5f} %, L-BFGS: {100*float(sel['lbfgsMean']):.5f} %. Gleichstand bis 1e-12 waere fuer Adam entschieden worden.",
        '',f"Die feste GPR-Referenz erreicht ueber dieselben 384 aeusseren Faelle und sechs Frequenzen {100*statistics.mean(float(c['RelativeRaw']) for c in cases if c['Model']=='gpr'):.5f} % mittleren relativen Fehler. Dieser Referenzvergleich verwendet trainierte GPR-Hyperparameter pro Fold und dient nicht zur Optimiererwahl.",
        '', '## Fold- und Seedlaeufe','', '| Modell | Fold | Seed | Mittel roh % | Fit s | Stopp | Faelle mit Ordnungsverletzung % | Verletzte Nachbarpaare |', '|---|---:|---:|---:|---:|---|---:|---:|']
    for r in runs:
        lines.append(f"| {r['Model']} | {r['Fold']} | {r['Seed']} | {100*float(r['MeanRawRelative']):.5f} | {float(r['TrainingSeconds']):.2f} | {r['StopReason']} | {100*float(r['OrderViolationCaseFraction']):.2f} | {r['ViolationPairs']} |")
    lines+=['','## Nach Frequenz und Darstellung','','Relative Fehler in Prozent, absolute in Hz. Die MLP-Quantile enthalten drei Seed-Wiederholungen pro Fall; Seeds sind keine unabhaengigen physikalischen Faelle. Separate Fold-/Seed-Quantile: `mode_fold_seed_summary.csv`.','', '| Modell | Frequenzindex | Darstellung | Mittel % | Median % | P95 % | Max % | Mittel Hz | Median Hz | P95 Hz | Max Hz |','|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|']
    for r in modes:
        lines.append(f"| {r['Model']} | {r['Mode']} | {r['Representation']} | {100*float(r['MeanRelative']):.4f} | {100*float(r['MedianRelative']):.4f} | {100*float(r['P95Relative']):.4f} | {100*float(r['MaxRelative']):.4f} | {float(r['MeanAbsoluteHz']):.3f} | {float(r['MedianAbsoluteHz']):.3f} | {float(r['P95AbsoluteHz']):.3f} | {float(r['MaxAbsoluteHz']):.3f} |")
    lines+=['','## Streuung und Ordnungsverletzungen','', 'Mittlere rohe Fehler der neun Fold-/Seed-Fits (GPR drei Folds); Spannweite und Stichprobenstandardabweichung sind deskriptiv:','', '| Modell | Min % | Max % | SD Prozentpunkte | Faelle mit Verletzung | verletzte Nachbarpaare |','|---|---:|---:|---:|---:|---:|']
    for model in ('adam','lbfgs','gpr'):
        rr=[r for r in runs if r['Model']==model]; vals=[100*float(r['MeanRawRelative']) for r in rr]
        affected=sum(round(128*float(r['OrderViolationCaseFraction'])) for r in rr); pairs=sum(int(float(r['ViolationPairs'])) for r in rr)
        lines.append(f"| {model} | {min(vals):.5f} | {max(vals):.5f} | {statistics.stdev(vals):.5f} | {affected}/{len(rr)*128} | {pairs} |")
    lines+=['', 'Seed- und Foldstreuung getrennt: je Mittelwert zuerst ueber die andere Achse gemittelt; Werte in Prozent und SD in Prozentpunkten.', '', '| Modell | Seed-Mittel: Bereich | Seed-SD | Fold-Mittel: Bereich | Fold-SD |', '|---|---:|---:|---:|---:|']
    for model in ('adam','lbfgs','gpr'):
        rr=[r for r in runs if r['Model']==model]
        fold_means=[statistics.mean(100*float(r['MeanRawRelative']) for r in rr if int(r['Fold'])==fold) for fold in (1,2,3)]
        if model=='gpr': seed_range='nicht anwendbar'; seed_sd='-'
        else:
            seed_means=[statistics.mean(100*float(r['MeanRawRelative']) for r in rr if int(r['Seed'])==seed) for seed in (42,43,44)]
            seed_range=f'{min(seed_means):.5f}–{max(seed_means):.5f}'; seed_sd=f'{statistics.stdev(seed_means):.5f}'
        lines.append(f'| {model} | {seed_range} | {seed_sd} | {min(fold_means):.5f}–{max(fold_means):.5f} | {statistics.stdev(fold_means):.5f} |')
    lines+=['','Streuung der mittleren relativen Rohfehler je Frequenz: Bereich in Prozent, Stichproben-SD in Prozentpunkten. Seed-Mittel sind jeweils ueber Folds, Fold-Mittel ueber Seeds gemittelt.', '', '| Modell | Frequenzindex | Fold-Bereich % | Fold-SD pp | Seed-Bereich % | Seed-SD pp |', '|---|---:|---:|---:|---:|---:|']
    for r in spreads:
        sr='-' if r['SeedSD']=='' else f"{100*r['SeedMin']:.4f}–{100*r['SeedMax']:.4f}"
        ss='-' if r['SeedSD']=='' else f"{100*r['SeedSD']:.4f}"
        lines.append(f"| {r['Model']} | {r['Mode']} | {100*r['FoldMin']:.4f}–{100*r['FoldMax']:.4f} | {100*r['FoldSD']:.4f} | {sr} | {ss} |")
    lines+=['','Separate Anzahl fuer jedes benachbarte Frequenzpaar: `ordering_by_pair.csv`. Rohe Vorhersagen und nachsortierte Ergebnisse sind getrennt gespeichert; Nachsortieren geht nicht in die Auswahl ein. Fold- und Seedwerte je Frequenz stehen in `mode_fold_seed_summary.csv`.','', '## Technische Integritaet und Aufwand','', 'Die 384 vorhandenen Trainingsfaelle wurden mit drei vorab gespeicherten Folds (256 Fit / 128 Validierung) verwendet. Log-Ziele und alle Skalierungen stammen ausschliesslich aus dem jeweiligen Fit-Fold. GPR und MLP nutzen dieselbe Transformation; GPR-Kernel ARD-Matern-5/2 und Sigma=1e-4 waren festgelegt. Pilot und Audit prueften Split, log/exp, Skalierung, initiale Gewichte, Aggregation und Wiederaufnahme. Keine frueheren Holdout-Labels, keine neuen FEM-Referenzen.','']
    for model in ('adam','lbfgs','gpr'):
        rr=[r for r in runs if r['Model']==model]
        lines.append(f"- {model}: {sum(float(r['TrainingSeconds']) for r in rr):.2f} s summierte CV-Fitzeit; {len(rr)} Fits.")
    bad=[r for r in ledger if r['Status']!='completed']
    lines+=['',f"Versuchsledger: {len(bad)} fehlgeschlagene oder unterbrochene Versuche. Ein auswertbarer Trainingsstand ist kein Konvergenznachweis; exakte Stopgruende stehen oben und im Ledger.",
        '', 'Drei finale Fits der ausgewaehlten Konfiguration auf allen 384 Trainingsfaellen sind gespeichert; sie sind nicht unabhaengig getestet. Die fruehere Frequenzstudie bleibt separate historische Evidenz.',
        '', '| Finaler Seed | Fit s | Stopp |', '|---:|---:|---|']
    for r in ledger:
        if r['Stage']=='final' and r['Status']=='completed':
            lines.append(f"| {r['Seed']} | {float(r['TrainingSeconds']):.2f} | {r['StopReason']} |")
    lines+=['',
        '## Artefakte und Wiederaufnahme','','`fold_assignments.csv`, `source_checksums.csv`, `prepared.mat`, `manifest.mat`, `pilot_passed.mat`, `cv_run_summary.csv`, `cv_case_frequency_metrics.csv`, `mode_summary.csv`, `mode_fold_seed_summary.csv`, `mode_spread.csv`, `ordering_by_pair.csv`, `training_history.csv`, `all_training_history.csv`, `selection.csv`, `attempt_ledger_cv.csv`, `attempt_ledger_final.csv` und die einzelnen versiegelten Modellartefakte.',
        '', 'Im Projektordner:', '', '```matlab', "openProject('blank_project.prj')", "run_modal_frequency_optimizer('prepare')", "run_modal_frequency_optimizer('pilot')", "run_modal_frequency_optimizer('campaign')", "run_modal_frequency_optimizer('evaluate')", "run_modal_frequency_optimizer('final')", "run_modal_frequency_optimizer('ledger')", "export_modal_training_history", '```', '', 'Bericht: `python scripts/python/report_modal_frequency_optimizer.py`. Bestehende erfolgreiche Modellartefakte werden geprueft und wiederverwendet; abweichende Daten oder Code stoppen den Lauf.', '']
    put(OUT/'FINAL_REPORT_v2.md','\n'.join(lines))
    print('Report:',sel['optimizer'],'CV rows',len(cases))

if __name__=='__main__': main()
