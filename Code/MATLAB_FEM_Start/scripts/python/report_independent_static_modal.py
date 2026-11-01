"""Report two independent holdouts, without making new model selections."""
from __future__ import annotations
import collections
import csv
import hashlib
import math
from pathlib import Path
import statistics
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'experiments/active/independent_static_modal_20261029_v1'

def read(name):
    with (OUT/name).open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))

def put(path,text):
    b=text.encode('utf8')
    if path.exists():
        if path.read_bytes()!=b: raise RuntimeError(f'Immutable report conflict: {path}')
    else:
        with path.open('xb') as f: f.write(b)

def q95(x):
    y=sorted(x); return y[math.ceil(.95*len(y))-1]

def summarize(vals): return statistics.mean(vals),statistics.median(vals),q95(vals),max(vals)

def main():
    assert (OUT/'evaluation_complete.mat').exists()
    sc=read('static_case_metrics.csv'); mc=read('modal_case_metrics.csv'); times=read('prediction_times.csv'); ledger=read('fem_attempt_ledger.csv'); costs=read('training_costs.csv')
    assert len(sc)==640 and len(mc)==3072 and len(times)==1152
    assert len({r['CaseID'] for r in sc})==128 and len({r['CaseID'] for r in mc})==128
    assert sum(r['Status']=='completed' for r in ledger)==256
    sgroups=collections.defaultdict(list); mgroups=collections.defaultdict(list); tgroups=collections.defaultdict(list)
    for r in sc: sgroups[(r['Model'],r['Seed'])].append(r)
    for r in mc: mgroups[(r['Model'],r['Seed'],int(r['Frequency']))].append(r)
    for r in times: tgroups[(r['Task'],r['Model'],r['Seed'])].append(float(r['MedianSeconds']))
    assert len(sgroups)==5 and len(mgroups)==24 and len(tgroups)==9
    for g in list(sgroups.values())+list(mgroups.values()): assert len(g)==128
    assert all(len(v)==128 and all(math.isfinite(x) and x>0 for x in v) for v in tgroups.values())
    result=['# Unabhaengige Abschlusspruefung: Statik und Eigenfrequenzen', '',
            'Stand: 29.10.2026. Beide Holdouts wurden vor den neuen FEM-Labels festgelegt. Es gab keine Nachwahl von Seeds oder Hyperparametern. Die Zielgroessen und Fehler der beiden Aufgaben bleiben getrennt.', '',
            '## Statische Feldauswertung', '', 'Alle relativen Werte in Prozent, absolute gewichtete Vektorfeld-RMS-Werte in Metern; P95 nearest-rank (122. von 128). Zeiten: Median ueber 128 fallweise Mediane aus sieben Einzelvorhersagen.', '',
            '| Modell | Seed | Mittel % | Median % | P95 % | Max % | Mittel abs. m | Median abs. m | P95 abs. m | Max abs. m | P95 <= 1 % | Vorhersage s/Fall |', '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|']
    srows=[]
    for (model,seed),rs in sorted(sgroups.items()):
        rel=summarize([float(r['Relative']) for r in rs]); ab=summarize([float(r['Absolute_m']) for r in rs]); seconds=statistics.median(tgroups[('static',model,seed)])
        srows.append((model,seed,*rel,*ab,seconds));
        result.append(f"| {model} | {seed} | {100*rel[0]:.5f} | {100*rel[1]:.5f} | {100*rel[2]:.5f} | {100*rel[3]:.5f} | {ab[0]:.4g} | {ab[1]:.4g} | {ab[2]:.4g} | {ab[3]:.4g} | {'ja' if rel[2]<=.01 else 'nein'} | {seconds:.6g} |")
    result += ['', '## Modale Frequenzauswertung', '', 'Je Frequenz und Seed: rohe Ausgaben in Hz. Prozent ist der absolute relative Fehler, P95 ist nearest-rank. Das interne P95-Ziel wird je Frequenz und Seed ausgewiesen; ein mittlerer Fehler unter 1 % ist nicht hinreichend.', '',
               '| Modell | Seed | Frequenz | Mittel % | Median % | P95 % | Max % | Mittel Hz | Median Hz | P95 Hz | Max Hz | P95 <= 1 % |', '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|']
    mrows=[]
    for (model,seed,frequency),rs in sorted(mgroups.items()):
        rel=summarize([float(r['RelativeRaw']) for r in rs]); ab=summarize([float(r['AbsoluteRawHz']) for r in rs]); mrows.append((model,seed,frequency,*rel,*ab))
        result.append(f"| {model} | {seed} | {frequency} | {100*rel[0]:.5f} | {100*rel[1]:.5f} | {100*rel[2]:.5f} | {100*rel[3]:.5f} | {ab[0]:.4g} | {ab[1]:.4g} | {ab[2]:.4g} | {ab[3]:.4g} | {'ja' if rel[2]<=.01 else 'nein'} |")
    import io
    for filename,header,rows in [
        ('static_summary.csv',['Model','Seed','MeanRelative','MedianRelative','P95Relative','MaxRelative','MeanAbsolute_m','MedianAbsolute_m','P95Absolute_m','MaxAbsolute_m','MedianPredictionSeconds'],srows),
        ('modal_raw_summary.csv',['Model','Seed','Frequency','MeanRelative','MedianRelative','P95Relative','MaxRelative','MeanAbsoluteHz','MedianAbsoluteHz','P95AbsoluteHz','MaxAbsoluteHz'],mrows)]:
        buf=io.StringIO(newline=''); writer=csv.writer(buf,lineterminator='\n'); writer.writerow(header); writer.writerows(rows); put(OUT/filename,buf.getvalue())
    static_mlp=[r for r in srows if r[0]=='mlp']; static_gp=next(r for r in srows if r[0]=='gpr')
    modal_gp=[r for r in mrows if r[0]=='gpr']; modal_mlp=[r for r in mrows if r[0]=='mlp']
    result += ['', '## Einsatzempfehlung innerhalb des getesteten Parameterraums', '',
        f"Statisch erfuellen {sum(r[4]<=.01 for r in static_mlp)}/3 MLP-Seeds und die GPR-Referenz ({'ja' if static_gp[4]<=.01 else 'nein'}) das P95-Arbeitsziel. Unter den hier untersuchten Modellen ist die GPR-Referenz eine praktische Vergleichs- und Einsatzoption, soweit diese Feldmetrik und der Parameterbereich die Anwendung abdecken; auch einzelne Maximalfehler sind zu beachten. Das ist kein Nachweis fuer andere Geometrien, Lasten oder eine kleinere Trainingsmenge.",
        f"Modal erfuellen {sum(r[5]<=.01 for r in modal_mlp)}/18 MLP-Seed-/Frequenzkombinationen und {sum(r[5]<=.01 for r in modal_gp)}/6 GPR-Frequenzen das P95-Arbeitsziel. Fuer eine Anwendung, die dieses Ziel fuer jede Frequenz verlangt, ist keines der hier geprueften Modalmodelle anhand dieses Tests ausreichend belegt. Die GPR-Referenz ist ein nuetzlicher Vergleich, aber nicht durch einen Mittelwert unter 1 % fuer das P95-Ziel freigegeben. Keine Eigenform- oder Modenfamilienvalidierung."]
    result += ['', '## Auffaellige Faelle, Seedstreuung und Frequenzordnung', '', 'Die schlechtesten drei statischen Faelle je Modell/Seed (relativer Feldfehler):', '', '| Modell | Seed | IDs und Fehler % |', '|---|---:|---|']
    for (model,seed),rs in sorted(sgroups.items()):
        worst=sorted(rs,key=lambda r:float(r['Relative']),reverse=True)[:3]
        result.append(f"| {model} | {seed} | "+'; '.join(f"{r['CaseID']}: {100*float(r['Relative']):.4f}" for r in worst)+' |')
    result += ['', 'Modal: schwerster roher Einzelfehler je Modell/Seed (Frequenzindex in Klammern):', '', '| Modell | Seed | Fall (Frequenz) | relativer Fehler % | absolut Hz |', '|---|---:|---|---:|---:|']
    for model,seed in sorted({(k[0],k[1]) for k in mgroups}):
        rs=[r for r in mc if r['Model']==model and r['Seed']==seed]; worst=max(rs,key=lambda r:float(r['RelativeRaw']))
        result.append(f"| {model} | {seed} | {worst['CaseID']} ({worst['Frequency']}) | {100*float(worst['RelativeRaw']):.4f} | {float(worst['AbsoluteRawHz']):.4g} |")
    result += ['', 'Ordnungsverletzungen der rohen modalen Ausgaben, gezählt pro Fall und Nachbarpaar:', '', '| Modell | Seed | Faelle | Paare 1-2 / 2-3 / 3-4 / 4-5 / 5-6 |', '|---|---:|---:|---|']
    for model,seed in sorted({(k[0],k[1]) for k in mgroups}):
        rs=[r for r in mc if r['Model']==model and r['Seed']==seed and int(r['Frequency'])==1]
        masks=[r['PairMask'].zfill(5) for r in rs]; counts=[sum(mask[i]=='1' for mask in masks) for i in range(5)]
        result.append(f"| {model} | {seed} | {sum(int(r['ViolationPairs'])>0 for r in rs)}/128 | "+' / '.join(map(str,counts))+' |')
    spread=[]
    for case in sorted({r['CaseID'] for r in sc if r['Model']=='mlp'}):
        rs=[r for r in sc if r['Model']=='mlp' and r['CaseID']==case]; assert len(rs)==3
        v=[float(r['Relative']) for r in rs]; spread.append(max(v)-min(v))
    result += ['', f"Statische MLP-Seedstreuung je gleichem Fall: mediane Spannweite {100*statistics.median(spread):.5f} Prozentpunkte; P95 {100*q95(spread):.5f} Prozentpunkte. Seeds sind keine zusaetzlichen physikalischen Faelle.",
        '', 'Modal: Spannweite der drei seedweisen P95-Werte je Frequenz:', '', '| Frequenz | Min P95 % | Max P95 % | Spannweite Prozentpunkte |', '|---:|---:|---:|---:|']
    for freq in range(1,7):
        vals=[r[5] for r in mrows if r[0]=='mlp' and r[2]==freq]; assert len(vals)==3
        result.append(f'| {freq} | {100*min(vals):.5f} | {100*max(vals):.5f} | {100*(max(vals)-min(vals)):.5f} |')
    result += ['', 'Nachsortierte diagnostische Werte und saemtliche rohen Fallwerte stehen in `modal_case_metrics.csv`; eine Sortierung ist keine Modenfamilienzuordnung und verdeckt die obigen Verletzungen nicht.', '', '## Aufwand und Grenzen', '', 'Der Vorabpilot pruefte die Vorhersage- und Metrikschnittstellen, nicht jedoch eine explizite siebenfache Vorhersagezeitmessung. Die Timing-Schleife war vor Labelerzeugung eingefroren; ihre Messwerte wurden nachtraeglich auf Vollstaendigkeit und Endlichkeit geprueft. Dieser begrenzte Pilotmangel ist in `ADDENDUM_04.md` dokumentiert.']
    for task in ('static','modal'):
        successful=[float(r['Seconds']) for r in ledger if r['Task']==task and r['Status']=='completed']; failures=[r for r in ledger if r['Task']==task and r['Status']!='completed']
        result.append(f"- {task}: {len(successful)}/128 erfolgreiche FEM-Referenzen, Summe {sum(successful):.2f} s, Median {statistics.median(successful):.2f} s; {len(failures)} fehlgeschlagene/unterbrochene Versuche im Ledger.")
        longest=max((r for r in ledger if r['Task']==task and r['Status']=='completed'),key=lambda r:float(r['Seconds']))
        if float(longest['Seconds'])>300:
            result.append(f"  Die Wandzeit des Falls {longest['ID']} betraegt {float(longest['Seconds']):.2f} s und ist auffaellig hoch; insbesondere bei einer Sitzungsunterbrechung kann sie Warte-/Stillstandszeit enthalten. Sie bleibt in der Summe; weder diese Summe noch der Einzelwert ist als reine Rechenzeit belastbar. Der Median bleibt als robuste Beschreibung zusaetzlich angegeben.")
    result += ['', 'Vorhersagezeiten pro Modell:','', '| Aufgabe | Modell | Seed | Median s/Fall | P95 s/Fall |', '|---|---|---:|---:|---:|']
    for (task,model,seed),vals in sorted(tgroups.items()): result.append(f"| {task} | {model} | {seed} | {statistics.median(vals):.6g} | {q95(vals):.6g} |")
    result += ['', 'Finale Fitzeiten:','', '| Modell | Seed | Fit s | Herkunft |','|---|---:|---:|---|']
    for c in costs: result.append(f"| {c['Model']} | {c['Seed']} | {float(c['Seconds']):.2f} | {c['Source']} |")
    archpath=ROOT/'experiments/active/restfield_mlp_architecture_training_20261028_v1/attempt_ledger.csv'
    modalpath=ROOT/'experiments/active/modal_frequency_optimizer_20261029_v1/attempt_ledger_final.csv'
    with archpath.open(encoding='utf-8-sig',newline='') as f: arch=list(csv.DictReader(f))
    with modalpath.open(encoding='utf-8-sig',newline='') as f: modaldev=list(csv.DictReader(f))
    result += ['', 'Historischer Entwicklungs-/Suchaufwand (verschiedene Studien und Budgets; nicht als direkter Zeitvergleich zu interpretieren):', '', '| Vorarbeit | Fitversuche | Summe Sekunden | Messumfang |', '|---|---:|---:|---|']
    for stage in ('architecture','optimizer','gpr'):
        rr=[r for r in arch if r['Stage']==stage]
        result.append(f"| Statische CV {stage} | {len(rr)} | {sum(float(r['ElapsedSeconds']) for r in rr):.2f} | Erfolgs- und Fehlversuche; Ledger-Wandzeiten |")
    for optimizer in ('adam','lbfgs','gpr'):
        rr=[r for r in modaldev if r['Stage']=='cv' and r['Optimizer']==optimizer and r['Status']=='completed']
        result.append(f"| Modale CV {optimizer} | {len(rr)} | {sum(float(r['TrainingSeconds']) for r in rr):.2f} | Fitzeit erfolgreicher CV-Laeufe |")
    result.append('| Statische Lernkurven und Sampling | siehe Berichte | siehe Berichte | getrennte Datendesigns, Pilot- und FEM-Aufwand; keine Doppelzaehlung in den obigen Summen |')
    result += ['', 'Die historischen Fitzeiten stammen aus frueheren Sitzungen; sie sind keine synchron gemessenen Gesamtentwicklungsaufwaende. Modell- und Architektursuche, Pilotstudien sowie die frueheren Trainings-FEM-Kosten sind getrennte, unterschiedlich umfangreiche Vorarbeiten. Eine Amortisationszahl wird nicht angegeben, weil vergleichbare vollstaendige Entwicklungskosten und ein einheitlich kontrollierter Referenz-Zeitversuch fuer alle Komponenten fehlen. Wiederholte Vorhersagemessungen messen einzelne Faelle mit geladenen Modellen, keine Systemintegration.',
        '', 'Vorhandene Nachweise: [FEM-Skalierungs- und Smoke-Pruefung](../../../verification/smoke_20261023_105533/REPORT.md), [POD-Galerkin-Netzvergleich](../pod_galerkin_20261023_v1/REPORT.md), [modale Qualifikation und Triangulationswarnungen](../neural_comparison_20261027_v1/PROGRESS_20261027.md). Diese Pruefungen sind keine lueckenlose Fehlergarantie fuer alle neuen Parameter; Referenzen bleiben numerische FEM-Ergebnisse mit begrenzter Netzaufloesung. Modal werden weder Eigenformen noch Familienzuordnung validiert.',
        '', '## Seminarweite Ergebnismatrix', '', '| Thema | Einordnung | Quelle |', '|---|---|---|',
        '| Modellierungsansatz | Balkenfeld plus gelerntes Restfeld liefert auf dem frueheren gemeinsamen Test einen starken Feldvergleich; direkte POD-Modelle unterscheiden sich in Darstellung und Fitverfahren. | [Gemeinsamer statischer Vergleich](../static_shared_comparison_20261028_v1/FINAL_REPORT.md) |',
        '| Architektur und Training | [32,32]-tanh und L-BFGS wurden mit CV unter endlichem Budget ausgewaehlt; keine allgemeine Architekturoptimalitaet. | [Architektur-/Trainingsstudie](../restfield_mlp_architecture_training_20261028_v1/FINAL_REPORT_v2.md) |',
        '| Datenmenge | 48 Faelle genuegten im urspruenglichen Design; eine designuebergreifend robuste Mindestmenge ist unbekannt. | [Lernkurve](../restfield_learning_curve_20261028_v1/FINAL_REPORT.md) und [Samplingvergleich](../restfield_sampling48_20261028_v1/FINAL_REPORT_v2.md) |',
        '| Datenverteilung | Nur 1/6 neuer 48er-Designs erfuellte das Ziel fuer alle drei Seeds; kein konsistenter LHS-Vorteil. | [Samplingvergleich](../restfield_sampling48_20261028_v1/FINAL_REPORT_v2.md) |',
        '| Statische Genauigkeit | Die neue Tabelle oben bewertet die mit 384 Faellen trainierten Modelle auf 128 neuen Faellen; kein Mindestdatenbeweis. | Dieser Bericht, statische Fallmetriken |',
        '| Eigenfrequenzen | L-BFGS schlug Adam in der Modellauswahl-CV; GPR war dort im Mittel genauer. Neue rohe Testergebnisse oben; keine Eigenformvalidierung. | [Modal-CV](../modal_frequency_optimizer_20261029_v1/FINAL_REPORT_v2.md) und dieser Bericht |',
        '| Rechenaufwand | Vergleiche nur je Modell und Messumfang; FEM-Erzeugung, Entwicklungssuche, finale Fits und Inferenz getrennt. | Dieser Bericht und Quellenstudien |',
        '| DeepONet und RBF | Historische kleine Testsaetze und unterschiedliche Trainingsverfahren begrenzen die Aussage; DeepONet-Negativbefund erhalten. | [Historischer DeepONet-Bericht](../../archive/deeponet_20261023_v1/REPORT.md), [wissenschaftliche Synthese](../scientific_synthesis_20261026_v1/ausarbeitung.md) |',
        '| POD-Galerkin | Auf bekanntem kleinem Testsatz sehr genau, aber Online-Assemblierung weiterhin erforderlich; kein neuer blinder Nachweis. | [POD-Galerkin](../pod_galerkin_20261023_v1/REPORT.md) |',
        '| PINN / Fourier / Graph | Begrenzte Prototypen, keine vollstaendigen leistungsvalidierten Ersatzmodelle. | [Prototypengrenzen](../neural_comparison_20261027_v1/PROTOTYPES.md) |',
        '', '## Reproduktion und ausstehende Seminararbeiten', '',
        'Im Projektordner in MATLAB:', '', '```matlab', "openProject('blank_project.prj')", "run_independent_static_modal('prepare')", "run_independent_static_modal('pilot')", "run_independent_static_modal('freeze')", "run_independent_static_modal('static_data')", "run_independent_static_modal('modal_data')", "run_independent_static_modal('evaluate')", '```', '', 'Bericht: `python scripts/python/report_independent_static_modal.py`. Erfolgreiche Faelle und versiegelte Artefakte werden wiederverwendet; Integritaetskonflikte stoppen den Lauf.',
        '', 'Fuer die Seminarabgabe noch erforderlich: Erkenntnisse und Grenzen in die Ausarbeitung und Praesentation uebertragen; Abbildungen, Quellen und Einheiten im Abgabedokument gegenpruefen; verbleibende FEM-Netz- und Modalzuordnungsgrenzen transparent benennen. Diese Punkte sind Dokumentationsarbeiten, keine weitere Modelloptimierung.', '']
    put(OUT/'FINAL_REPORT_v2.md','\n'.join(result))
    # Separate visual panels avoid mixing field and frequency outcomes.
    fig,axes=plt.subplots(1,2,figsize=(12,4.5),layout='constrained')
    for model,seed,mean,med,p95,mx,*_ in srows: axes[0].scatter(f'{model} {seed}',100*p95)
    axes[0].axhline(1,color='black',linestyle='--'); axes[0].set(title='Static P95 by model and seed',ylabel='Weighted field error (%)'); axes[0].tick_params(axis='x',rotation=35)
    for model,seed in sorted({(x[0],x[1]) for x in mrows}):
        rs=sorted([r for r in mrows if r[0]==model and r[1]==seed],key=lambda r:r[2]); axes[1].plot([r[2] for r in rs],[100*r[5] for r in rs],marker='o',label=f'{model} {seed}')
    axes[1].axhline(1,color='black',linestyle='--'); axes[1].set(title='Modal raw P95 by frequency',xlabel='Frequency index',ylabel='Relative error (%)',xticks=range(1,7)); axes[1].legend(fontsize=8)
    for ax in axes: ax.grid(alpha=.25)
    if not (OUT/'holdout_results.png').exists(): fig.savefig(OUT/'holdout_results.png',dpi=180)
    plt.close(fig)
    print('Independent report: 128 static + 128 modal references')

if __name__=='__main__': main()
