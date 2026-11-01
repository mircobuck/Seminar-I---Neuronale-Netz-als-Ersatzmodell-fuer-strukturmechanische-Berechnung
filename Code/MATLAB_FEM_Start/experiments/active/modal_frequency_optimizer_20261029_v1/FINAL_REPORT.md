# Kontrollierter Optimierervergleich: Eigenfrequenzen

Stand: 29.10.2026. Dreifache Kreuzvalidierung innerhalb von 384 vorhandenen Modal-Trainingsfaellen; kein unabhaengiger Abschlusstest. Sechs aufsteigend sortierte Frequenzen sind keine Eigenformvorhersage und kein Modenfamilien-Tracking.

Auswahl nach vorab festgelegter mittlerer relativer Fehlerquote der rohen Hz-Ausgaben: **LBFGS**. Adam: 5.50239 %, L-BFGS: 0.99786 %. Gleichstand bis 1e-12 waere fuer Adam entschieden worden.

Die feste GPR-Referenz erreicht ueber dieselben 384 aeusseren Faelle und sechs Frequenzen 0.60690 % mittleren relativen Fehler. Dieser Referenzvergleich verwendet trainierte GPR-Hyperparameter pro Fold und dient nicht zur Optimiererwahl.

## Fold- und Seedlaeufe

| Modell | Fold | Seed | Mittel roh % | Fit s | Stopp | Faelle mit Ordnungsverletzung % | Verletzte Nachbarpaare |
|---|---:|---:|---:|---:|---|---:|---:|
| gpr | 1 | 42 | 0.64194 | 3.79 | GPR fit completed; convergence not separately certified | 0.78 | 1 |
| adam | 1 | 42 | 5.95664 | 2.24 | Max epochs completed | 11.72 | 21 |
| adam | 1 | 43 | 5.73927 | 3.36 | Max epochs completed | 10.94 | 14 |
| adam | 1 | 44 | 5.47667 | 3.95 | Max epochs completed | 7.03 | 12 |
| lbfgs | 1 | 42 | 1.11515 | 19.11 | Max iterations completed | 0.78 | 1 |
| lbfgs | 1 | 43 | 1.11648 | 20.86 | Max iterations completed | 1.56 | 4 |
| lbfgs | 1 | 44 | 1.09617 | 19.57 | Max iterations completed | 1.56 | 4 |
| gpr | 2 | 42 | 0.54802 | 4.96 | GPR fit completed; convergence not separately certified | 1.56 | 2 |
| adam | 2 | 42 | 5.24218 | 3.04 | Max epochs completed | 0.78 | 1 |
| adam | 2 | 43 | 5.30227 | 2.88 | Max epochs completed | 0.78 | 1 |
| adam | 2 | 44 | 4.99028 | 2.77 | Max epochs completed | 1.56 | 2 |
| lbfgs | 2 | 42 | 0.95381 | 21.69 | Max iterations completed | 0.78 | 1 |
| lbfgs | 2 | 43 | 0.87873 | 20.15 | Max iterations completed | 0.78 | 1 |
| lbfgs | 2 | 44 | 0.97210 | 21.36 | Max iterations completed | 0.78 | 1 |
| gpr | 3 | 42 | 0.63074 | 5.33 | GPR fit completed; convergence not separately certified | 0.78 | 2 |
| adam | 3 | 42 | 5.68496 | 2.32 | Max epochs completed | 3.12 | 5 |
| adam | 3 | 43 | 5.54595 | 2.77 | Max epochs completed | 3.12 | 5 |
| adam | 3 | 44 | 5.58329 | 3.14 | Max epochs completed | 2.34 | 4 |
| lbfgs | 3 | 42 | 0.94378 | 21.34 | Max iterations completed | 1.56 | 2 |
| lbfgs | 3 | 43 | 0.95248 | 20.41 | Max iterations completed | 0.78 | 1 |
| lbfgs | 3 | 44 | 0.95207 | 20.65 | Max iterations completed | 1.56 | 2 |

## Nach Frequenz und Darstellung

Relative Fehler in Prozent, absolute in Hz. Die MLP-Quantile enthalten drei Seed-Wiederholungen pro Fall; Seeds sind keine unabhaengigen physikalischen Faelle. Separate Fold-/Seed-Quantile: `mode_fold_seed_summary.csv`.

| Modell | Frequenzindex | Darstellung | Mittel % | Median % | P95 % | Max % | Mittel Hz | Median Hz | P95 Hz | Max Hz |
|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| adam | 1 | raw | 5.4449 | 4.6262 | 13.1994 | 30.6915 | 4.935 | 3.356 | 15.238 | 54.861 |
| adam | 1 | sorted | 5.4044 | 4.6291 | 13.0375 | 30.6915 | 4.911 | 3.356 | 15.238 | 54.861 |
| adam | 2 | raw | 5.7175 | 4.8618 | 14.0691 | 28.1402 | 7.608 | 4.923 | 23.544 | 118.749 |
| adam | 2 | sorted | 5.7236 | 4.8768 | 13.9206 | 28.1402 | 7.603 | 4.948 | 23.544 | 118.749 |
| adam | 3 | raw | 5.2857 | 4.4589 | 13.4808 | 27.8374 | 28.702 | 19.746 | 90.442 | 269.741 |
| adam | 3 | sorted | 5.3149 | 4.4947 | 13.6545 | 27.8374 | 28.946 | 19.929 | 90.081 | 269.741 |
| adam | 4 | raw | 5.7410 | 4.7395 | 14.3811 | 28.9719 | 38.988 | 28.012 | 115.359 | 377.859 |
| adam | 4 | sorted | 5.6741 | 4.6889 | 14.2690 | 28.9719 | 38.453 | 27.738 | 112.018 | 377.859 |
| adam | 5 | raw | 5.4157 | 4.5247 | 14.1726 | 28.0478 | 48.057 | 33.695 | 145.144 | 628.797 |
| adam | 5 | sorted | 5.4157 | 4.5247 | 14.1726 | 28.0478 | 48.057 | 33.695 | 145.144 | 628.797 |
| adam | 6 | raw | 5.4095 | 4.4149 | 14.4537 | 29.1275 | 71.638 | 49.642 | 218.006 | 633.879 |
| adam | 6 | sorted | 5.4095 | 4.4149 | 14.4537 | 29.1275 | 71.638 | 49.642 | 218.006 | 633.879 |
| lbfgs | 1 | raw | 0.9245 | 0.5834 | 3.1636 | 9.1400 | 0.890 | 0.428 | 3.390 | 20.902 |
| lbfgs | 1 | sorted | 0.9197 | 0.5834 | 3.1636 | 8.9842 | 0.881 | 0.428 | 3.390 | 18.527 |
| lbfgs | 2 | raw | 1.0260 | 0.6584 | 3.4494 | 8.3687 | 1.313 | 0.685 | 4.440 | 25.824 |
| lbfgs | 2 | sorted | 1.0218 | 0.6584 | 3.4494 | 8.3687 | 1.304 | 0.685 | 4.440 | 25.824 |
| lbfgs | 3 | raw | 0.8821 | 0.5815 | 3.0451 | 8.2192 | 4.964 | 2.611 | 18.023 | 100.908 |
| lbfgs | 3 | sorted | 0.8686 | 0.5815 | 3.0065 | 8.2192 | 4.825 | 2.604 | 17.732 | 67.169 |
| lbfgs | 4 | raw | 1.1953 | 0.8779 | 3.5091 | 8.5169 | 8.201 | 5.108 | 26.262 | 131.035 |
| lbfgs | 4 | sorted | 1.1809 | 0.8738 | 3.4615 | 7.7746 | 8.033 | 5.108 | 25.537 | 119.614 |
| lbfgs | 5 | raw | 0.8657 | 0.6577 | 2.4530 | 5.1437 | 7.433 | 4.913 | 24.267 | 99.025 |
| lbfgs | 5 | sorted | 0.8657 | 0.6577 | 2.4530 | 5.1437 | 7.433 | 4.913 | 24.267 | 99.025 |
| lbfgs | 6 | raw | 1.0935 | 0.8616 | 2.8334 | 8.4233 | 15.315 | 9.649 | 52.056 | 124.757 |
| lbfgs | 6 | sorted | 1.0935 | 0.8616 | 2.8334 | 8.4233 | 15.315 | 9.649 | 52.056 | 124.757 |
| gpr | 1 | raw | 0.3651 | 0.1958 | 1.2384 | 6.2236 | 0.340 | 0.142 | 1.251 | 7.644 |
| gpr | 1 | sorted | 0.3611 | 0.1958 | 1.2384 | 6.2236 | 0.336 | 0.142 | 1.251 | 7.644 |
| gpr | 2 | raw | 0.3994 | 0.2228 | 1.3083 | 4.8633 | 0.480 | 0.236 | 1.698 | 7.179 |
| gpr | 2 | sorted | 0.3956 | 0.2228 | 1.2472 | 4.8633 | 0.476 | 0.236 | 1.696 | 7.179 |
| gpr | 3 | raw | 0.4082 | 0.2054 | 1.4676 | 7.8089 | 2.377 | 0.886 | 9.721 | 54.529 |
| gpr | 3 | sorted | 0.4046 | 0.2074 | 1.4676 | 7.8089 | 2.352 | 0.888 | 10.525 | 54.529 |
| gpr | 4 | raw | 0.9340 | 0.5819 | 2.7411 | 5.6295 | 6.641 | 3.366 | 20.934 | 72.256 |
| gpr | 4 | sorted | 0.9146 | 0.5807 | 2.7410 | 5.6295 | 6.430 | 3.366 | 20.148 | 72.256 |
| gpr | 5 | raw | 0.7531 | 0.5009 | 2.2989 | 5.2764 | 6.358 | 3.946 | 20.908 | 44.728 |
| gpr | 5 | sorted | 0.7515 | 0.5009 | 2.2989 | 5.2764 | 6.349 | 3.946 | 20.908 | 44.728 |
| gpr | 6 | raw | 0.7816 | 0.4658 | 2.5591 | 10.1430 | 10.072 | 5.695 | 33.354 | 93.194 |
| gpr | 6 | sorted | 0.7816 | 0.4658 | 2.5591 | 10.1430 | 10.072 | 5.695 | 33.354 | 93.194 |

## Streuung und Ordnungsverletzungen

Mittlere rohe Fehler der neun Fold-/Seed-Fits (GPR drei Folds); Spannweite und Stichprobenstandardabweichung sind deskriptiv:

| Modell | Min % | Max % | SD Prozentpunkte | Faelle mit Verletzung | verletzte Nachbarpaare |
|---|---:|---:|---:|---:|---:|
| adam | 4.99028 | 5.95664 | 0.29045 | 53/1152 | 65 |
| lbfgs | 0.87873 | 1.11648 | 0.08759 | 13/1152 | 17 |
| gpr | 0.54802 | 0.64194 | 0.05130 | 4/384 | 5 |

Seed- und Foldstreuung getrennt: je Mittelwert zuerst ueber die andere Achse gemittelt; Werte in Prozent und SD in Prozentpunkten.

| Modell | Seed-Mittel: Bereich | Seed-SD | Fold-Mittel: Bereich | Fold-SD |
|---|---:|---:|---:|---:|
| adam | 5.35008–5.62793 | 0.14085 | 5.17824–5.72419 | 0.28700 |
| lbfgs | 0.98256–1.00678 | 0.01331 | 0.93488–1.10927 | 0.09675 |
| gpr | nicht anwendbar | - | 0.54802–0.64194 | 0.05130 |

Separate Anzahl fuer jedes benachbarte Frequenzpaar: `ordering_by_pair.csv`. Rohe Vorhersagen und nachsortierte Ergebnisse sind getrennt gespeichert; Nachsortieren geht nicht in die Auswahl ein. Fold- und Seedstreuung je Frequenz stehen in `mode_fold_seed_summary.csv`.

## Technische Integritaet und Aufwand

Die 384 vorhandenen Trainingsfaelle wurden mit drei vorab gespeicherten Folds (256 Fit / 128 Validierung) verwendet. Log-Ziele und alle Skalierungen stammen ausschliesslich aus dem jeweiligen Fit-Fold. GPR und MLP nutzen dieselbe Transformation; GPR-Kernel ARD-Matern-5/2 und Sigma=1e-4 waren festgelegt. Pilot und Audit prueften Split, log/exp, Skalierung, initiale Gewichte, Aggregation und Wiederaufnahme. Keine frueheren Holdout-Labels, keine neuen FEM-Referenzen.

- adam: 26.48 s summierte CV-Fitzeit; 9 Fits.
- lbfgs: 185.14 s summierte CV-Fitzeit; 9 Fits.
- gpr: 14.08 s summierte CV-Fitzeit; 3 Fits.

Versuchsledger: 0 fehlgeschlagene oder unterbrochene Versuche. Ein auswertbarer Trainingsstand ist kein Konvergenznachweis; exakte Stopgruende stehen oben und im Ledger.

Drei finale Fits der ausgewaehlten Konfiguration auf allen 384 Trainingsfaellen sind gespeichert; sie sind nicht unabhaengig getestet. Die fruehere Frequenzstudie bleibt separate historische Evidenz.

| Finaler Seed | Fit s | Stopp |
|---:|---:|---|
| 42 | 26.42 | Max iterations completed |
| 43 | 25.68 | Max iterations completed |
| 44 | 22.25 | Max iterations completed |

## Artefakte und Wiederaufnahme

`fold_assignments.csv`, `source_checksums.csv`, `prepared.mat`, `manifest.mat`, `pilot_passed.mat`, `cv_run_summary.csv`, `cv_case_frequency_metrics.csv`, `mode_summary.csv`, `mode_fold_seed_summary.csv`, `ordering_by_pair.csv`, `training_history.csv`, `all_training_history.csv`, `selection.csv`, `attempt_ledger_cv.csv`, `attempt_ledger_final.csv` und die einzelnen versiegelten Modellartefakte.

Im Projektordner:

```matlab
openProject('blank_project.prj')
run_modal_frequency_optimizer('prepare')
run_modal_frequency_optimizer('pilot')
run_modal_frequency_optimizer('campaign')
run_modal_frequency_optimizer('evaluate')
run_modal_frequency_optimizer('final')
run_modal_frequency_optimizer('ledger')
export_modal_training_history
```

Bericht: `python scripts/python/report_modal_frequency_optimizer.py`. Bestehende erfolgreiche Modellartefakte werden geprueft und wiederverwendet; abweichende Daten oder Code stoppen den Lauf.
