"""Generate seminar report from preserved study and supplemental tables."""
import csv, hashlib, json, math, statistics
from pathlib import Path
H=Path(__file__).resolve().parent; M=H.parent/'static_gpr_main_v1_20261111_run2'
def read(p):
    with p.open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def f(x): return float(x)
methods=['mlp','rbf','pod_mlp','pod_gpr']
labels={'mlp':'MLP','rbf':'RBF','pod_mlp':'POD–MLP','pod_gpr':'POD–GPR'}
runs=read(M/'run_results.csv'); summary=read(M/'supplementary_analysis/pipeline_summary_corrected.csv')
search={r['Method']:f(r['SearchSeconds']) for r in read(M/'search_costs.csv')}; bench={r['method']:r for r in read(H/'benchmark_summary.csv')}
rank=read(H/'controlled_rank_n768.csv'); grp=read(H/'extrapolation_group_summary.csv'); paired=read(H/'extrapolation_outliers_paired.csv')
peak=read(H/'extrapolation_global_peaks.csv'); stats=read(H/'extrapolation_diagnostic_summary.csv'); meta=json.loads((H/'metadata.json').read_text(encoding='utf-8'))
main={}; times={}
for m in methods:
    subset=[r for r in runs if r['method']==m and r['role']=='interpolation' and r['id'].replace('/','\\').startswith(f'runs\\n768_rep1_{m}_seed')]
    subset.sort(key=lambda r:int(r['id'].split('seed')[-1]))
    main[m]=next(r for r in subset if r['id'].endswith('seed42')); times[m]=[f(r['fitSeconds']) for r in subset]
assert abs(f(main['pod_gpr']['fitSeconds'])-353.5687942)<1e-6
rep=[f(main['pod_gpr']['fitSeconds'])]+meta['gprRepeats']; assert abs(statistics.median(rep)-337.1902846)<1e-6
R=[]; add=R.append
add('# Ergänzung v1: wissenschaftliche Darstellung des statischen Vier-Methoden-Vergleichs')
add('\nStand 12.11.2026. Kennzeichnungen: **[H]** ursprüngliche Hauptstudie, **[D]** nachträgliche beschreibende Auswertung, **[B]** zusätzlicher Zeitbenchmark, **[Hyp]** Folgehypothese. Die Hauptstudie und ihre Modelle bleiben unverändert.\n')
add('## 1. Fragestellung und Aufbau [H]\n')
add('Aus sechs Eingabeparametern sollen die vollständigen statischen FEM-Verschiebungsfelder an 525 Punkten mit drei Komponenten (1575 Werte) vorhergesagt werden. Verglichen wurden direktes MLP, die vorhandene RBF-Variante, POD–MLP und POD–GPR. Eigenfrequenzen sind ausgeschlossen. Der Trainingspool umfasst 768 Fälle aus zwei Blöcken; für Lernkurven wurden N=48, 96, 192, 384 und 768 betrachtet. Die neuen Referenzen umfassen 128 Validierungs-, 256 Interpolations- und 128 Extrapolationsfälle. Extrapolation betrifft genau einen Parameter, 5–10 % der Trainingsintervallbreite außerhalb einer Grenze.\n')
add('Die Auswahl erfolgte bei N=384 auf einer blockausgeglichenen Trainingsauswahl anhand des mittleren gewichteten relativen Validierungsfeldfehlers; Gleichstände wurden über P95 und Konfigurations-ID behandelt. Neuronale Topkandidaten wurden mit Seeds 42/43/44 bestätigt; die GPR-Auswahl folgt dem deterministischen Protokoll. Die gewählte Familienkonfiguration wurde für alle Lernkurvengrößen festgehalten: Es fand keine separate Optimierung für jedes N statt. Modell- und Auswahlfreeze erfolgte vor Testlabelzugriff.\n')
add('## 2. Ausgewählte Konfigurationen [H]\n')
add('| Methode | Ausgewählte Konfiguration | Loss / Anpassung | Rang |')
add('|---|---|---|---:|')
add('| MLP | 3 verborgene Schichten × 128 | gewichtete Feld-MSE; Adam | – |')
add('| RBF | feste Gaußschicht mit 64 Zentren und Breitenparameter 2; danach 2 Tanh-Schichten × 64 (hiddenLayers=3) | gewichtete Feld-MSE; Adam | – |')
add('| POD–MLP | 3 verborgene Schichten × 80 | gewichtete Feld-MSE; Adam | 2 |')
add('| POD–GPR | ARD-Matérn-5/2, linearer Mittelwert, konstantes numerisches Sigma 0,001 | exakte GPR, zwei Starts | 15 |')
add('\nNeuronale Grundwerte: CPU, maximal 200 Epochen, Batch 32, Lernrate 0,001. GPR-Parameter für Adam in der gemeinsamen gespeicherten Konfigurationsstruktur sind für GPR nicht wirksam. GPR verwendet zwei Startlängenskalen und Quasi-Newton mit maximal 500 Iterationen; Sigma ist keine physikalische Rauschschätzung. Der tatsächlich untersuchte direkte MLP-Suchraum umfasste Breiten 64/128, Tiefen 2/3, Lernraten 0,0005/0,001 und beide Losses. Die ursprünglich vorgesehenen Breiten 32/80 fehlen: Einschränkung des Suchraums, kein Beleg der Ungültigkeit des durchgeführten Vergleichs.\n')
add('## 3. Vollpool: Genauigkeit und ursprüngliche Fit-Zeiten [H/D]\n')
add('| Methode | Interpolation Mittel / P95 / Maximum | Extrapolation Mittel / P95 / Maximum | Fit-Hauptmodell Seed 42 | Neuronale Fit-Zeiten Seeds 42/43/44 |')
add('|---|---:|---:|---:|---|')
for m in methods:
    a=next(x for x in summary if x['method']==m and x['role']=='interpolation' and x['n']=='768')
    b=next(x for x in summary if x['method']==m and x['role']=='extrapolation' and x['n']=='768')
    es=lambda x:' / '.join(f'{100*f(x[k]):.2f} %' for k in ['meanError','p95Error','maxObserved'])
    t=', '.join(f'{v:.2f}' for v in times[m])+' s' if m!='pod_gpr' else 'nicht zutreffend'
    add(f'| {labels[m]} | {es(a)} | {es(b)} | {f(main[m]["fitSeconds"]):.2f} s | {t} |')
add('\nMittelwert und P95 sind je Lauf über Fälle berechnet und für neuronale Modelle über drei Initialisierungen gemittelt; Maximum ist das größte beobachtete Fallmaximum. GPR hat im Vollpool eine Datenwahl und einen ausgewerteten Hauptlauf. Die Fit-Zeit dieses Hauptmodells beträgt **353,5687942 s**, nicht den Median der Zeitwiederholungen.\n')
add(f'Drei GPR-Fit-Zeitmessungen derselben Konfiguration: {rep[0]:.7f}, {rep[1]:.7f}, {rep[2]:.7f} s; Median **{statistics.median(rep):.7f} s**, Minimum {min(rep):.7f} s, Maximum {max(rep):.7f} s. Die Checkpoints bestätigen identische Konfiguration, Trainings-IDs und Trainings-/Validierungsfingerprints. Alle drei Zeiten messen den öffentlichen `fitModel`-Aufruf ohne Speichern und Validierungsvorhersage. Sie sind Wiederholungen der Zeitmessung, keine unabhängigen Modelle oder Datenziehungen; die drei neuronalen Seeds messen dagegen unterschiedliche Initialisierungen. Zeitbedingungen waren seriell geplant, verbleibende Systemeffekte sind nicht auszuschließen.\n')
add('## 4. Lernkurven und Verteilung [H]\n')
add('| Methode | N=48 | N=96 | N=192 | N=384 | N=768 |')
add('|---|---:|---:|---:|---:|---:|')
for m in methods:
    vals=[next(x for x in summary if x['method']==m and x['role']=='interpolation' and x['n']==str(n)) for n in [48,96,192,384,768]]
    add('| '+labels[m]+' | '+' | '.join(f'{100*f(x["meanError"]):.2f} %' for x in vals)+' |')
add('\nBei N=192 verringerte das raumfüllende gegenüber dem auf kleine Längen konzentrierten Design den mittleren Interpolationsfehler in dieser separaten Studie: MLP 5,45 statt 14,28 %, RBF 7,65 statt 23,35 %, POD–MLP 6,97 statt 15,27 %, POD–GPR 2,90 statt 5,08 %. Fallzahl, Randpunkte und Testfälle waren gleich. Dies ist ein deskriptiver Vergleich der konkreten Designs.\n')
add('## 5. Kontrollierter POD-Rang und Kosten bei N=768 [D]\n')
add('Ein gemeinsamer POD-Zustand wurde pro Rang und Auswahl bereitgestellt. Eigenständige Fit-Zeit = gemessener öffentlicher Fit mit vorberechneter Basis plus separat gemessene gemeinsame POD-Zeit; dies ist eine additive Schätzung der eigenständigen Pipeline. Einzelfall- und Batch-128-Zeiten sind Mediane der vollständigen Vorhersageaufrufe; sie stammen aus der ursprünglichen Messung. Pro Zeile liegt ein kontrollierter Lauf mit Seed 42 vor, kein Mittel über drei neuronale Initialisierungen.\n')
add('| Split | Methode | Rang | Läufe | Projektion | Feldfehler | Fit inkl. POD | Einzel / Batch 128 | Modellgröße |')
add('|---|---|---:|---:|---:|---:|---:|---:|---:|')
for x in rank:
    add(f'| {x["split"]} | {labels[x["method"]]} | {x["rank"]} | {x["runs"]} | {f(x["projection_percent"]):.4f} % | {f(x["field_percent"]):.3f} % | {f(x["fit_standalone_s"]):.2f} s | {f(x["prediction_single_ms"]):.2f} / {f(x["prediction_batch128_ms"]):.2f} ms | {int(x["model_bytes"])/1e6:.2f} MB |')
add('\nDie Projektion ist ein mittlerer relativer Anteil; 0,00 % nach Rundung bedeutet nicht exakt null. Rang 2 versus 15 bei POD–GPR: Interpolation 0,560 % versus 0,549 %, Extrapolation 3,861 % versus 3,854 %, bei etwa 70,53 versus 348,22 s eigenständigem Fit. **[Hyp]** Ein kleiner Rang könnte bei diesem Problem ein günstiges Genauigkeits-/Aufwandsverhältnis bieten. Diese nach Testeinsicht formulierte Hypothese erfordert eine neue vorab definierte Prüfung; der Validierungssieger Rang 15 wird in dieser Studie nicht ersetzt.\n')
add('## 6. Extrapolationsdiagnose [D]\n')
add('Für die Diagnose wurden die maximalen relativen Fehler je Familie über alle Vollpoolläufe bestimmt. Alle vier Maxima betreffen Fall **830644**. Die Parameter sind L=0,692972916 m, b=0,088804909 m, h=0,129583372 m, E=203010440886,835 Pa, ν=0,281823598 und Fz=−29,9501651 N. Fz liegt oberhalb der oberen Trainingsgrenze −100 N, um 70,049835 N bzw. 7,7833 % der Intervallbreite von 900 N. Die gewichtete FEM-Referenznorm beträgt 5,07563×10⁻⁷ m.\n')
add('| Methode / Seed des globalen Maximums | Absoluter Feldfehler | Relativer Feldfehler | Spitzenfehler | Maximumfehler |')
add('|---|---:|---:|---:|---:|')
for x in peak:
    add(f'| {labels[x["method"]]} / {x["run_id"].split("seed")[-1]} | {f(x["absolute_field_m"])*1e3:.6f} mm | {100*f(x["relative"]):.2f} % | {f(x["tip_error_m"])*1e3:.6f} mm | {f(x["maximum_error_m"])*1e3:.6f} mm |')
add('\nFür denselben Fall nachfolgend alle vier vorab festgelegten Seed-42-Modelle: Die angegebenen Spitzen- und Maximalwerte sind FEM-Wert plus gespeicherte vorzeichenbehaftete Abweichung. Sie sind keine Mittelwerte über Seeds.\n')
add('| Methode, Seed 42 | relativer Fehler | FEM-Spitze / Vorhersage | FEM-Maximum / Vorhersage |')
add('|---|---:|---:|---:|')
for x in paired:
    add(f'| {labels[x["method"]]} | {100*f(x["relative"]):.2f} % | {f(x["fem_tip_m"])*1e3:.6f} / {f(x["predicted_tip_m"])*1e3:.6f} mm | {f(x["fem_maximum_m"])*1e3:.6f} / {f(x["predicted_maximum_m"])*1e3:.6f} mm |')
add('\nDie folgenden Gruppenwerte verwenden nur die vier Seed-42-Hauptmodelle, je 10 oder 11 Fälle pro Gruppe. Sie sind explorativ; einzelne Fallkombinationen unterscheiden sich und Gruppenunterschiede belegen keine Kausalität.\n')
add('| Parameter / Seite | Fälle | MLP | RBF | POD–MLP | POD–GPR |')
add('|---|---:|---:|---:|---:|---:|')
for g in range(1,13):
    a=[next(x for x in grp if x['method']==m and int(x['group'])==g) for m in methods]
    add(f'| {a[0]["parameter"]} / {a[0]["side"]} | {a[0]["cases"]} | '+' | '.join(f'{100*f(x["mean_relative"]):.2f} %' for x in a)+' |')
add('\nDie 13 größten relativen Fehler je Methode hatten bei MLP/RBF/POD–MLP eine mediane Referenznorm von 2,54×10⁻⁶ m, bei GPR 4,94×10⁻⁶ m; der Median aller 128 Referenznormen war 5,04×10⁻⁵ m. Unter diesen jeweils 13 Fällen lagen 7/9/6/8 in der Fz-oberhalb-Gruppe (MLP/RBF/POD–MLP/GPR); diese Gruppe enthält insgesamt zehn Fälle. Kleine Referenznormen und die Lastgruppe gehen hier häufig mit großen relativen Fehlern einher. Der absolute Feldfehler von Fall 830644 ist nicht null; zudem sind die mittleren absoluten Fehler in der Fz-unterhalb-Gruppe bei allen Methoden größer als in der Fz-oberhalb-Gruppe. Kleine Normen erklären folglich einen Teil der relativen Zuspitzung, aber nicht sämtliche absoluten Abweichungen. Korrelationen und Gruppenwerte sind beschreibend, keine kausale Analyse. Details und alle 512 Seed-42-Fallzeilen stehen in den CSV-Dateien.\n')
add('## 7. Zusätzlicher FEM-/Surrogatbenchmark [B]\n')
add('Vorab festgelegte 12 Positionen im Interpolationsdatensatz, unabhängig vom Surrogatfehler; gleiche Eingaben, eingefrorene Vollpoolmodelle Seed 42, MATLAB R2025b, AMD Ryzen 5 4500U (6 Kerne). Serielle Messung, kein zusätzlich gestarteter Studienjob. Ein FEM-Warm-up; anschließend zwei vollständige solve_case-Aufrufe je Fall in umgekehrter Reihenfolge. Die FEM-Zeit umfasst Geometrie, Netz, Lösung, Interpolation aller 525 Punkte sowie Spitzenabfrage und Prüfungen. Pro Surrogat Warm-up und 30 Einzelaufrufe je Fall sowie 30 gemeinsame 12er-Batches; öffentliche Vorhersage mit Rücktransformation und Prüfung. Modelle werden vorab geladen, Ladezeiten separat; Dateizugriffe ausgeschlossen. Die Fälle stammen aus der Interpolation und sind nicht repräsentativ für beliebige zukünftige Verteilungen.\n')
add('| Methode | FEM Einzelfall: Median (IQR zwischen Fällen) | Surrogat Einzel: Median (IQR zwischen Fällen) | FEM seriell 12 Fälle | Surrogat Batch 12 | Modell laden |')
add('|---|---:|---:|---:|---:|---:|')
for m in methods:
    x=bench[m]; add(f'| {labels[m]} | {f(x["femSingleMedian"]):.3f} ({f(x["femBetweenCaseIQR"]):.3f}) s | {1000*f(x["surrogateSingleMedian"]):.3f} ({1000*f(x["surrogateBetweenCaseIQR"]):.3f}) ms | {f(x["femSerial12Sum"]):.3f} s | {1000*f(x["surrogateBatch12Median"]):.3f} ms | {f(x["modelLoad"]):.3f} s |')
add('\nDie FEM-Einzelfallwerte sind zunächst Mediane aus zwei Wiederholungen je Fall; anschließend werden Median und IQR über die zwölf Fälle gebildet. Der FEM-12er-Wert ist die Summe dieser fallweisen Mediane, keine Messung eines optimierten FEM-Batchsolvers. Batch-Zeiten sind Mediane aus 30 Aufrufen; ihre IQR und alle Rohzeiten stehen in den Benchmark-CSVs. Der erste gemessene Ladevorgang kann Start-/Cacheeffekte enthalten. FEM umfasst zusätzliche Spitzenabfrage und Prüfungen; die Zeitumfänge sind deshalb dokumentiert vergleichbar, aber nicht exakt identisch.\n')
add('### Bedingte Break-even-Rechnung [B/D]\n')
add('Für ein Einzelfall-Szenario: Q_BE = ceil(C_offline / (t_FEM − t_Surrogat)), nur für positiven Nenner. C_offline enthält den gemessenen Fit des Seed-42-Hauptmodells, optional die äußere Familiensuche. Fit und Suche stammen aus der früheren Hauptstudie, die Vorhersage- und FEM-Zeiten aus dem neuen Benchmark auf derselben Maschine; sie wurden nicht in derselben Sitzung gemessen. Für den 12er-Fall wird die gleiche Formel auf die Kosten pro Batch angewandt und anschließend mit 12 multipliziert. Es handelt sich um grobe Szenarien auf Basis von Medianen, ohne Unsicherheitsintervall und ohne Einbezug von Lade-/Speicherkosten, wiederholten Modellaktualisierungen oder Qualitätssicherung.\n')
add('| Methode | Einzelfälle: vorhandene Daten, Fit | Einzelfälle: Fit + Suche | 12er-Fälle: vorhandene Daten, Fit | 12er-Fälle: Fit + Suche |')
add('|---|---:|---:|---:|---:|')
scenarios=[]
for m in methods:
    b=bench[m]; fit=f(main[m]['fitSeconds']); denom=f(b['femSingleMedian'])-f(b['surrogateSingleMedian']); bd=f(b['femSerial12Sum'])-f(b['surrogateBatch12Median']); assert denom>0 and bd>0
    q0=math.ceil(fit/denom); q1=math.ceil((fit+search[m])/denom); qb0=12*math.ceil(fit/bd); qb1=12*math.ceil((fit+search[m])/bd)
    # Historical solver and validation wall are proxies, not newly measured full data-generation costs.
    proxy=1632.9175524+566.1100838
    qp=math.ceil((fit+proxy)/denom); qps=math.ceil((fit+proxy+search[m])/denom)
    scenarios.append(dict(method=m,fit_s=fit,search_s=search[m],single_denominator_s=denom,batch12_denominator_s=bd,
        existing_fit_cases=q0,existing_fit_search_cases=q1,batch_existing_fit_cases=qb0,batch_existing_fit_search_cases=qb1,
        historical_data_proxy_s=proxy,proxy_fit_cases=qp,proxy_fit_search_cases=qps))
    add(f'| {labels[m]} | {q0} | {q1} | {qb0} | {qb1} |')
with (H/'break_even_scenarios.csv').open('w',encoding='utf-8',newline='') as out:
    w=csv.DictWriter(out,fieldnames=list(scenarios[0]));w.writeheader();w.writerows(scenarios)
add('\nBei vorhandenen Trainings- und Validierungsdaten werden diese als versunkene beziehungsweise verfügbare Ressource behandelt. Für eine hypothetische Neuerzeugung ist nur eine unvollständige historische Kostenannahme verfügbar: 1632,92 s summierte historische Trainings-Solverzeit plus 566,11 s aktive Validierungserzeugung, zusammen 2199,03 s. Die historische Trainings-Gesamtzeit fehlt; diese gemischte Annahme ist weder eine kontrolliert neu gemessene Vollerzeugung noch eine belastbare untere Schranke. Als reine Rechenillustration ergibt sie folgende zusätzliche Szenarien:')
for s in scenarios: add(f'- {labels[s["method"]]}: {s["proxy_fit_cases"]} Einzelfälle mit Fit; {s["proxy_fit_search_cases"]} mit Fit und Suche.')
add('\nDie historischen Zahlen sind Annahmen, nicht durch den neuen Benchmark nachgemessen. Testdatenerzeugung, Pilot, Mehrfachläufe, Qualitätssicherung, Verwaltung sowie zusätzliche Studienkosten sind nicht enthalten. Andere Eingabeverteilungen, Hardware, Auslastung und FEM-Netze können die Schwellen stark verändern. Die Rang-2-Hypothese wird für diese Berechnung nicht nachträglich zum Gewinner erklärt.\n')
add('## 8. Grenzen und Empfehlung\n')
add('Der größte relative Ausreißer zeigt, dass die im Mittel gute Extrapolation nicht für jeden Fall zuverlässig ist. Für Genauigkeit innerhalb des untersuchten Bereichs ist POD–GPR ein sinnvoller Ausgangspunkt, bei deutlich höherem Fit-Aufwand. POD–MLP ist schneller trainiert; direktes MLP und die konkrete RBF-Variante bleiben Bezugspunkte innerhalb ihrer durchsuchten Räume. Keine allgemeine Methodenüberlegenheit wird behauptet. Die FEM ist eine numerische Referenz; der Pilot beweist keine globale Netzkonvergenz. Der ursprüngliche MLP-Suchraum und ein belastbarer allgemein gültiger Break-even bleiben unvollständig.\n')
add('Die erste Testauswertung brach nach dem ersten Modell durch Überschreiben einer Manifestvariablen ab. Die technische Korrektur entstand nach dem ersten Testzugriff und ist separat dokumentiert und gehasht. Die Nachtragsprüfung weist unveränderte Modelle, Auswahlregeln und Metriken aus; die beiden bereits erzeugten Split-Ergebnisse stimmen in zwölf geprüften numerischen Größen mit der Wiederholung überein. Dies macht die Korrektur transparent, nicht nachträglich vorab registriert.\n')
add('Rohdaten und Rechenschritte: `benchmark_results.mat`, `benchmark_fem_raw.csv`, `benchmark_surrogate_raw.csv`, `benchmark_summary.csv`, `break_even_scenarios.csv`, `controlled_rank_n768.csv`, `extrapolation_global_peaks.csv`, `extrapolation_outliers_paired.csv`, `extrapolation_group_summary.csv`, `extrapolation_all_seed42.csv`, `analyse_v1.py`, `report_v1.py` und `analysis_provenance.json`. Die ursprünglichen Dateien bleiben unverändert.\n')
(H/'SEMINARBERICHT_v1.md').write_text('\n'.join(R),encoding='utf-8')
print('report and scenarios written')
