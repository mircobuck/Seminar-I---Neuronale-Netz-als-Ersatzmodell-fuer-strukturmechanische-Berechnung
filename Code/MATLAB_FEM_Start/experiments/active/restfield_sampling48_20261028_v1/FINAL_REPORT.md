# Abschlussbericht: Einfluss der Trainingsdatenverteilung bei 48 Faellen

Stand: 29.10.2026. Die 128 verwendeten Faelle sind Entwicklungsvalidierung, kein unabhaengiger Abschlusstest.

## Zielerfuellung und Vergleich

| Strategie | MLP-Laeufe mit P95 <= 1 % | Designs: alle drei Seeds <= 1 % | GPR-Designs <= 1 % |
|---|---:|---:|---:|
| uniform | 6/9 | 1/3 | 2/3 |
| lhs | 3/9 | 0/3 | 2/3 |

Insgesamt erreichen 9 von 18 MLP-Fits das Ziel; bei 1 von sechs Designs erreichen alle drei Seeds das Ziel.

Die Bereiche der jeweils schlechtesten MLP-Seed-P95 ueberlappen; ein konsistenter Vorteil von LHS ist damit anhand dieser sechs Designs nicht belegt.

Die drei Seeds desselben Designs sind wiederholte Modellinitialisierungen, keine unabhaengigen Trainingsdesigns. Der Vergleich umfasst nur drei unabhaengig erzeugte Designs je Strategie; die Werte erlauben keine belastbare allgemeine Ueberlegenheits- oder Zuverlaessigkeitsbehauptung.

## Design- und Seedstreuung

| Strategie | MLP: Designmittel der drei Seed-P95 | MLP: jeweils schlechtester Seed-P95 | GPR-P95 |
|---|---|---|---|
| uniform | 0.795–1.175 %; SD 0.192 Prozentpunkte | 0.851–1.488 %; SD 0.359 Prozentpunkte | 0.517–1.141 %; SD 0.318 Prozentpunkte |
| lhs | 0.870–2.200 %; SD 0.699 Prozentpunkte | 1.324–2.717 %; SD 0.723 Prozentpunkte | 0.373–1.059 %; SD 0.343 Prozentpunkte |

Spannweite und Stichproben-SD beziehen sich auf je drei Designs; SD in Prozentpunkten. Innerhalb jedes Designs:

| Design | Mittel P95 % | Seed-SD Prozentpunkte | Min P95 % | Max P95 % |
|---|---:|---:|---:|---:|
| uniform_01 | 1.0309 | 0.3692 | 0.7979 | 1.4565 |
| uniform_02 | 1.1751 | 0.3559 | 0.7879 | 1.4881 |
| uniform_03 | 0.7950 | 0.0500 | 0.7560 | 0.8515 |
| lhs_01 | 1.1595 | 0.4819 | 0.7443 | 1.6880 |
| lhs_02 | 0.8702 | 0.4467 | 0.4306 | 1.3236 |
| lhs_03 | 2.2000 | 0.7694 | 1.3158 | 2.7171 |

## Vollstaendige Ergebnisse

Relative Fehler und Projektion in Prozent; absolute gewichtete Vektorfeld-RMS-Werte in Metern. P95 ist nearest-rank, der 122. von 128 sortierten Faellen.

| Design | Modell | Seed | POD-Rang | Mittel % | Median % | P95 % | Max % | Abs. Mittel m | Abs. Median m | Abs. P95 m | Abs. Max m | Projektion Mittel % | Projektion P95 % | Fit s | Iterationen | Abbruchgrund |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| uniform_01 | gpr | 42 | 5 | 0.1635 | 0.0749 | 0.5166 | 1.9118 | 6.59e-08 | 3.53e-08 | 3.04e-07 | 7.36e-07 | 0.00388 | 0.01475 | 0.25 | 0 | GPR fit returned; convergence not separately certified |
| uniform_01 | mlp | 42 | 5 | 0.3528 | 0.1601 | 1.4565 | 2.8271 | 1.32e-07 | 7.62e-08 | 4.63e-07 | 1.27e-06 | 0.00388 | 0.01475 | 18.81 | 250 | Max iterations completed |
| uniform_01 | mlp | 43 | 5 | 0.2813 | 0.1492 | 0.7979 | 3.1564 | 1.22e-07 | 7.57e-08 | 3.69e-07 | 1.13e-06 | 0.00388 | 0.01475 | 20.46 | 250 | Max iterations completed |
| uniform_01 | mlp | 44 | 5 | 0.2335 | 0.1421 | 0.8382 | 1.3520 | 1.19e-07 | 6.66e-08 | 4.71e-07 | 1.46e-06 | 0.00388 | 0.01475 | 15.31 | 245 | Suitable learning rate not found |
| uniform_02 | gpr | 42 | 5 | 0.2258 | 0.0989 | 1.1407 | 1.6431 | 9.55e-08 | 3.98e-08 | 4.22e-07 | 9.03e-07 | 0.00391 | 0.01419 | 0.25 | 0 | GPR fit returned; convergence not separately certified |
| uniform_02 | mlp | 42 | 5 | 0.2349 | 0.1387 | 0.7879 | 1.5032 | 1.12e-07 | 6.75e-08 | 5.03e-07 | 1.09e-06 | 0.00391 | 0.01419 | 15.73 | 250 | Max iterations completed |
| uniform_02 | mlp | 43 | 5 | 0.3469 | 0.2022 | 1.4881 | 3.2545 | 1.4e-07 | 8.67e-08 | 4.58e-07 | 1.03e-06 | 0.00391 | 0.01419 | 16.66 | 250 | Max iterations completed |
| uniform_02 | mlp | 44 | 5 | 0.3350 | 0.1675 | 1.2492 | 3.8557 | 1.37e-07 | 8.65e-08 | 5.04e-07 | 1.04e-06 | 0.00391 | 0.01419 | 12.01 | 198 | Suitable learning rate not found |
| uniform_03 | gpr | 42 | 5 | 0.1999 | 0.0940 | 0.7202 | 2.0742 | 9.31e-08 | 4.61e-08 | 3.56e-07 | 9.38e-07 | 0.00367 | 0.01301 | 0.48 | 0 | GPR fit returned; convergence not separately certified |
| uniform_03 | mlp | 42 | 5 | 0.2300 | 0.1325 | 0.8515 | 1.4395 | 1.16e-07 | 5.65e-08 | 3.95e-07 | 1.19e-06 | 0.00367 | 0.01301 | 16.24 | 232 | Suitable learning rate not found |
| uniform_03 | mlp | 43 | 5 | 0.2189 | 0.0925 | 0.7560 | 3.1455 | 9.96e-08 | 5.1e-08 | 4.39e-07 | 1.02e-06 | 0.00367 | 0.01301 | 14.49 | 235 | Suitable learning rate not found |
| uniform_03 | mlp | 44 | 5 | 0.2044 | 0.1206 | 0.7776 | 1.5114 | 1.05e-07 | 6.11e-08 | 3.78e-07 | 1.06e-06 | 0.00367 | 0.01301 | 15.62 | 250 | Max iterations completed |
| lhs_01 | gpr | 42 | 5 | 0.2049 | 0.1167 | 0.7174 | 1.6858 | 1.08e-07 | 5.2e-08 | 5.34e-07 | 1.15e-06 | 0.00397 | 0.01225 | 0.28 | 0 | GPR fit returned; convergence not separately certified |
| lhs_01 | mlp | 42 | 5 | 0.2770 | 0.1403 | 1.0462 | 2.5229 | 1.28e-07 | 5.77e-08 | 5.96e-07 | 1.25e-06 | 0.00397 | 0.01225 | 12.85 | 199 | Suitable learning rate not found |
| lhs_01 | mlp | 43 | 5 | 0.2017 | 0.1073 | 0.7443 | 1.4449 | 1.15e-07 | 4.57e-08 | 6.38e-07 | 1.4e-06 | 0.00397 | 0.01225 | 26.03 | 250 | Max iterations completed |
| lhs_01 | mlp | 44 | 5 | 0.3593 | 0.1823 | 1.6880 | 2.7658 | 1.47e-07 | 7.99e-08 | 5.63e-07 | 1.16e-06 | 0.00397 | 0.01225 | 29.14 | 247 | Suitable learning rate not found |
| lhs_02 | gpr | 42 | 5 | 0.1244 | 0.0708 | 0.3725 | 1.1476 | 6.07e-08 | 3.82e-08 | 1.88e-07 | 6.14e-07 | 0.00494 | 0.01664 | 1.18 | 0 | GPR fit returned; convergence not separately certified |
| lhs_02 | mlp | 42 | 5 | 0.1806 | 0.1199 | 0.4306 | 1.4708 | 8.67e-08 | 5.36e-08 | 2.54e-07 | 8.17e-07 | 0.00494 | 0.01664 | 22.94 | 250 | Max iterations completed |
| lhs_02 | mlp | 43 | 5 | 0.2068 | 0.1246 | 0.8565 | 1.7965 | 8.79e-08 | 5.71e-08 | 2.45e-07 | 7.43e-07 | 0.00494 | 0.01664 | 20.74 | 250 | Max iterations completed |
| lhs_02 | mlp | 44 | 5 | 0.3349 | 0.1756 | 1.3236 | 3.2549 | 1.27e-07 | 8.97e-08 | 3.93e-07 | 8.87e-07 | 0.00494 | 0.01664 | 25.48 | 250 | Max iterations completed |
| lhs_03 | gpr | 42 | 4 | 0.2527 | 0.0923 | 1.0594 | 3.6680 | 8.32e-08 | 4.74e-08 | 2.58e-07 | 5.63e-07 | 0.00718 | 0.01987 | 0.33 | 0 | GPR fit returned; convergence not separately certified |
| lhs_03 | mlp | 42 | 4 | 0.4198 | 0.1746 | 1.3158 | 5.2784 | 1.18e-07 | 9.25e-08 | 3.36e-07 | 4.81e-07 | 0.00718 | 0.01987 | 12.52 | 154 | Suitable learning rate not found |
| lhs_03 | mlp | 43 | 4 | 0.5518 | 0.2191 | 2.7171 | 5.7151 | 1.67e-07 | 1.24e-07 | 4.35e-07 | 8.31e-07 | 0.00718 | 0.01987 | 15.76 | 184 | Suitable learning rate not found |
| lhs_03 | mlp | 44 | 4 | 0.5259 | 0.1758 | 2.5672 | 6.1787 | 1.52e-07 | 1.1e-07 | 4.55e-07 | 6.75e-07 | 0.00718 | 0.01987 | 16.21 | 187 | Suitable learning rate not found |

## Historische 48-Fall-Stichprobe und Einordnung

Die historische Stichprobe erzielte Seed 42: 0.514 %, Seed 43: 0.456 %, Seed 44: 0.585 %; GPR: 0.529 %. Sie ist gesonderte Vergleichsevidenz und wurde nicht als zusaetzliche Designwiederholung gezaehlt. Die fruehere Aussage '48 Trainingsfaelle reichen' galt fuer dieses eine Design und diese Entwicklungsvalidierung. Die neuen Zielzaehlungen zeigen, wie diese Aussage fuer die hier untersuchten Designs einzuordnen ist; eine Garantie fuer beliebige Designs oder einen spaeteren Test folgt daraus nicht.

## Technik, Aufwand und Grenzen

Alle sechs vorab gespeicherten Designs bestehen aus 48 vorab zugeordneten Faellen; Sampling und Vergleich erfolgen ohne FEM- oder Fehler-getriebene Auswahl. Die 128 zuvor erzeugten Entwicklungsreferenzen wurden unveraendert und pruefsummengesichert uebernommen. Die gleichen Validierungsfaelle wurden fuer alle Modelle verwendet.

Je Design wurden Mittelwert, gewichtete POD und beide Skalierungen ausschliesslich aus 48 Trainingsfaellen bestimmt. MLP und GPR teilen dieselbe Darstellung. Der Pilot pruefte Designreproduktion, Fallzuordnung, Split-Trennung, gemeinsame Skalierung, Rekonstruktion, Metriken, gleiche Initialgewichte und Wiederaufnahme. Bei der Auswertung wurden Rekonstruktion und Fallmetriken erneut berechnet. Alle MATLAB-MAT-Artefakte besitzen SHA-256-Siegel.

FEM: 657.01 s fuer 288 erfolgreiche Faelle; 0 fehlgeschlagene oder unterbrochene Versuche. Kampagnen-Fitzeit: MLP 327.00 s, GPR 2.77 s. Das sind gemessene Fit-/Solverzeiten ohne gesamte Vor- und Nachverarbeitung und ohne Pilotfits.

Im Modell-Ledger stehen 0 fehlgeschlagene oder unterbrochene Versuche; 9 der 18 MLP-Kampagnenlaeufe endeten mit 'Suitable learning rate not found'. Ein auswertbarer Modellstand ist kein Konvergenznachweis. Weitere Abbruchgruende stehen einzeln in der Ergebnistabelle.

Die Fallstreuung ist in den Fallmetriken, Quantilen und der Grafik dokumentiert; die Grafik mittelt dort zur Darstellung pro Fall ueber Seeds und zaehlt diese nicht als neue Faelle. FEM- und MLP-Zeiten sind maschinenabhaengig. Die Validierung wurde bereits bei der vorigen Datenbedarfsauswahl genutzt und jetzt erneut zur Entwicklungsentscheidung verwendet.

## Dateien und Reproduktion

`summary.csv`, `case_metrics.csv`, `design_summary.csv`, `strategy_summary.csv`, `target_counts.csv`, `design_target_counts.csv`, `attempt_ledger.csv`, `fem_ledger.csv`, `training_history.csv`, `sampling_comparison.png`, `source_checksums.csv`, `SHA256SUMS.csv` und versiegelte MAT-Artefakte liegen im Studienordner. Der Originalcode und die Umgebung sind im Manifest erfasst.

Im Projektordner in MATLAB R2025b:

```matlab
openProject('blank_project.prj')
run_restfield_sampling48('prepare')
run_restfield_sampling48('pilot')
run_restfield_sampling48('data')
run_restfield_sampling48('campaign')
run_restfield_sampling48('evaluate')
```

Anschliessend im Projektordner: `python scripts/python/report_restfield_sampling48.py`. Wiederaufnahmen pruefen bestehende Artefakte und erzeugen fuer fehlgeschlagene oder unterbrochene Versuche neue nummerierte Versuche; Konflikte fuehren zum Abbruch.
