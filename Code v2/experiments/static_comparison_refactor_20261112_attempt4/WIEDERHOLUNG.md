# Abschluss der statischen Struktur-Wiederholung

Versuch: `static_comparison_refactor_20261112_attempt4`. MATLAB R2025b, serielle CPU-Ausfuehrung. Vier Methoden, unveraenderte 76 Suchkandidaten, Trainingsgroessen 48/96/192/384/768. Vorhandene FEM-Referenzen wurden unveraendert wiederverwendet. **Bekannte Referenzfaelle: kein neuer unabhaengiger Abschlusstest.**

## Umfang und Nachweise

Abgeschlossen: 234 versiegelte Fits, davon 88 Such-/Bestaetigungsfits und 146 Trainingsfits (58 Hauptpipeline, 78 kontrollierte POD, 8 Verteilungsstudie, 2 zusaetzliche GPR-Zeitwiederholungen). 144 Modelle mit je zwei Testsplit-Auswertungen: 288 erfolgreiche Lauf/Split-Zeilen, 55296 Fallzeilen. Keine fehlgeschlagenen Auswertungen oder undefinierten relativen Feldfehler.

Alle Dateien der Quell- und Freeze-Manifeste sowie die Checkpoint-Siegel wurden nach Abschluss erneut geprueft. Numerischer Vergleich: `numerical_comparison.csv`, maschinenlesbarer Nachweis: `verification.json`, reproduzierbar mit `python verify_results.py` im Laufordner. Die vorher bestandenen 83 Basistests, 16 neuen Regressionstests und 55 nach Zeitinstrumentierung betroffenen Tests stehen in `../../docs/TESTNACHWEIS.md`. Vor dem Lauf waren alle 72 Dateien des erfolgreichen Smoke-Quellmanifests byteidentisch; deshalb keine komplette Testwiederholung.

Phasenzeiten und Standby-/Speicherpruefung: [LAUFBEDINGUNGEN.md](LAUFBEDINGUNGEN.md). Die sechs gespeicherten Testartefakte stimmen mit ihren dokumentierten SHA256-Werten ueberein (`test_evidence_check.txt`).

## Vergleich mit der bisherigen Hauptstudie

Alle Lauf-, Split- und Fallidentitaeten wurden zugeordnet. Der Vergleich umfasst Feldfehler, Referenznormen, Spitzen-/Maximalfehler und POD-Zerlegung; Zeiten sind bewusst nicht auf Gleichheit geprueft. Prueftoleranz je numerischem Wert: 1e-12 absolut + 1e-12 relativ zum historischen Wert.

| Tabelle | Kennzahl | Abweichende Werte | Max. absolute Differenz | Ausserhalb Toleranz |
|---|---|---|---|---|
| run_results.csv | avg | 13 | 9.99e-16 | 0 |
| case_results.csv | Relative | 0 | 0 | 0 |

Alle 55.296 Fallzeilen sind in den verglichenen Kennzahlen exakt identisch (einschliesslich gleicher undefinierter POD-Felder bei direkten Modellen). Nur 13 Mittelwerte unterscheiden sich um maximal 9.992e-16: Der historische studyReport sortiert die Fehler vor der Mittelwertbildung; summarizeErrors erhaelt fuer den Mittelwert die Fallreihenfolge und sortiert nur fuer P95. Die beobachtete Abweichung ist damit durch Gleitkomma-Summation erklaert; Median, P95, Maximum und absolute Mittelwerte sind exakt gleich.

Die gewaehlten Konfigurationen sind in `VERGLEICH.md` gegen die historischen Auswahlobjekte geprueft. Keine nachtraegliche Anpassung anhand der bekannten Testwerte.

| Methode | Kandidaten | Fits inkl. Bestaetigung | Gewinner-ID | Neue aeussere Suchzeit [s] |
|---|---|---|---|---|
| MLP | 16 | 20 | 4 | 469.379 |
| RBF | 24 | 28 | 20 | 579.595 |
| POD-MLP | 12 | 16 | 4 | 259.582 |
| POD-GPR | 24 | 24 | 20 | 1017.830 |

Aeussere Gesamtsuchzeit einschliesslich Verwaltung: 2326.930 s.

## Vollpool: Interpolation und Extrapolation

Mittel und P95 zuerst ueber Faelle je Lauf, danach Mittel ueber drei neuronale Initialisierungen. Maximum: groesstes beobachtetes Fallmaximum. GPR: ein ausgewerteter deterministischer Hauptlauf. Alle Fehler in Prozent.

| Methode | Interpolation Mittel / P95 / Maximum [%] | Extrapolation Mittel / P95 / Maximum [%] |
|---|---|---|
| MLP | 4.6354 / 14.7834 / 58.5947 | 16.2426 / 50.7380 / 638.2322 |
| RBF | 7.4069 / 22.5747 / 97.2120 | 32.6663 / 102.0311 / 1253.5507 |
| POD-MLP | 4.7796 / 15.7260 / 43.7814 | 13.7405 / 47.8185 / 286.5552 |
| POD-GPR | 0.5491 / 2.2027 / 6.6507 | 3.8536 / 15.8510 / 88.5498 |

## Lernkurven und Verteilungsstudie

Mittlerer Interpolationsfeldfehler in Prozent. Unterhalb N=768 streuen die Laeufe ueber drei Trainingsauswahlen; beim Vollpool ueber neuronale Initialisierungen. Diese Streuungsarten sind keine zusaetzlichen unabhaengigen Balkenfaelle.

| Methode | 48 | 96 | 192 | 384 | 768 |
|---|---|---|---|---|---|
| MLP | 114.929 | 10.963 | 5.578 | 4.915 | 4.635 |
| RBF | 29.478 | 13.265 | 11.215 | 8.144 | 7.407 |
| POD-MLP | 145.457 | 28.800 | 9.714 | 4.289 | 4.780 |
| POD-GPR | 29.312 | 7.717 | 2.694 | 1.248 | 0.549 |

| Design/Lauf | Split | Mittlerer Fehler [%] | Neue Fit-Zeit [s] |
|---|---|---|---|
| distribution\skew_mlp | extrapolation | 39.626 | 13.134 |
| distribution\skew_mlp | interpolation | 14.283 | 13.134 |
| distribution\skew_pod_gpr | extrapolation | 30.624 | 14.334 |
| distribution\skew_pod_gpr | interpolation | 5.082 | 14.334 |
| distribution\skew_pod_mlp | extrapolation | 52.083 | 8.340 |
| distribution\skew_pod_mlp | interpolation | 15.265 | 8.340 |
| distribution\skew_rbf | extrapolation | 62.125 | 10.306 |
| distribution\skew_rbf | interpolation | 23.349 | 10.306 |
| distribution\space_mlp | extrapolation | 19.717 | 12.946 |
| distribution\space_mlp | interpolation | 5.454 | 12.946 |
| distribution\space_pod_gpr | extrapolation | 13.915 | 13.674 |
| distribution\space_pod_gpr | interpolation | 2.902 | 13.674 |
| distribution\space_pod_mlp | extrapolation | 41.679 | 8.295 |
| distribution\space_pod_mlp | interpolation | 6.969 | 8.295 |
| distribution\space_rbf | extrapolation | 43.247 | 10.133 |
| distribution\space_rbf | interpolation | 7.652 | 10.133 |

## Kontrollierte POD-Raenge bei N=768

Je Rang ein gemeinsamer trainingsbasierter POD-Zustand. Eigenstaendige Fit-Kosten sind oeffentlicher Fit mit vorberechneter Basis plus einmalige gemeinsame POD-Zeit; dies ist eine additive Kostenschaetzung. Je Zeile ein Modell mit Seed 42.

| Lauf | Split | Mittlere Projektion [%] | Mittlerer Fehler [%] | Fit + gemeinsame POD [s] | POD-Anteil [s] | Modell [MiB] |
|---|---|---|---|---|---|---|
| controlled\n768_rep1_rank10_pod_gpr | extrapolation | 0.001151 | 3.853 | 213.714 | 0.371180 | 24.777 |
| controlled\n768_rep1_rank10_pod_gpr | interpolation | 0.000787 | 0.549 | 213.714 | 0.371180 | 24.777 |
| controlled\n768_rep1_rank10_pod_mlp | extrapolation | 0.001151 | 11.627 | 33.645 | 0.371180 | 0.624 |
| controlled\n768_rep1_rank10_pod_mlp | interpolation | 0.000787 | 3.993 | 33.645 | 0.371180 | 0.624 |
| controlled\n768_rep1_rank15_pod_gpr | extrapolation | 0.000809 | 3.854 | 337.615 | 0.430487 | 37.246 |
| controlled\n768_rep1_rank15_pod_gpr | interpolation | 0.000526 | 0.549 | 337.615 | 0.430487 | 37.246 |
| controlled\n768_rep1_rank15_pod_mlp | extrapolation | 0.000809 | 14.397 | 32.448 | 0.430487 | 0.796 |
| controlled\n768_rep1_rank15_pod_mlp | interpolation | 0.000526 | 3.056 | 32.448 | 0.430487 | 0.796 |
| controlled\n768_rep1_rank2_pod_gpr | extrapolation | 0.115419 | 3.861 | 65.764 | 0.451747 | 5.088 |
| controlled\n768_rep1_rank2_pod_gpr | interpolation | 0.058786 | 0.560 | 65.764 | 0.451747 | 5.088 |
| controlled\n768_rep1_rank2_pod_mlp | extrapolation | 0.115419 | 13.850 | 31.625 | 0.451747 | 0.348 |
| controlled\n768_rep1_rank2_pod_mlp | interpolation | 0.058786 | 5.022 | 31.625 | 0.451747 | 0.348 |

## Neue Laufzeitmessungen

Die folgende Tabelle verwendet die vorab festgelegten Vollpool-Hauptmodelle mit Seed 42. Der vollstaendige oeffentliche Fit umfasst die Modellpipeline; Validierungsvorhersage und Speichern liegen ausserhalb. Netzwerkaufbau und Optimierung sind additive Zeitinstrumentierung, keine Aenderung des Trainings. Bei GPR bezeichnet Regression den gesamten Koeffizientenfit. Nicht anwendbare Segmente erscheinen als n/a. Die historischen Segmentfelder ueberlappen: Regression umfasst bei MLP/RBF Netzaufbau plus Optimierung, bei POD-MLP die Optimierung, bei GPR den gesamten Koeffizientenfit. Diese Spalten duerfen nicht zusammenaddiert werden. Der Center-Zweig enthaelt nur bei RBF einen Zentrenfit; bei MLP misst er den leeren Zweig.

| Methode | Fit neu [s] | Fit historisch [s] | Vorverarbeitung [s] | POD [s] | Center-Zweig [s] | Netzaufbau [s] | Optimierung [s] | Regression [s] | Laden [s] | Speichern [s] |
|---|---|---|---|---|---|---|---|---|---|---|
| MLP | 47.110 | 52.672 | 0.011978 | n/a | 0.000025 | 0.012156 | 47.082023 | 47.094182 | 0.078860 | 0.095595 |
| RBF | 39.020 | 43.708 | 0.015521 | n/a | 0.001380 | 0.010534 | 38.989850 | 39.000388 | 0.082792 | 0.066330 |
| POD-MLP | 32.050 | 32.263 | 0.000171 | 0.442538 | n/a | 0.019854 | 31.575200 | 31.575200 | 0.084268 | 0.058830 |
| POD-GPR | 333.970 | 353.569 | 0.007335 | 0.515298 | n/a | n/a | n/a | 333.444690 | 0.591526 | 1.506635 |

Drei deterministische GPR-Fit-Zeitwiederholungen [s]: 333.970225, 343.168339, 341.675738; Median 341.675738 s. Keine drei unabhaengigen Modellreplikate. Trainings-/Validierungs-IDs, Rang/Seed und alle Validierungsfallfehler sind identisch (`gpr_repeat_verification.json`). Neuronale Seeds 42/43/44 erzeugen dagegen verschiedene Initialisierungen. Neue und historische Zeiten stammen aus getrennten Sitzungen; Unterschiede sind kein isolierter Nachweis einer durch den Strukturumbau verursachten Beschleunigung.

Vorhersage ueber den vollstaendigen oeffentlichen Aufruf nach Warm-up, 30 Wiederholungen. Einzelfall und Batch 128: Median und IQR der Zeitwiederholungen.

| Methode | Einzel Median / IQR [ms] | Batch 128 Median / IQR [ms] |
|---|---|---|
| MLP | 9.799 / 1.812 | 12.361 / 1.199 |
| RBF | 9.362 / 1.700 | 12.324 / 1.680 |
| POD-MLP | 8.287 / 1.053 | 9.670 / 1.093 |
| POD-GPR | 6.973 / 1.463 | 44.137 / 4.127 |

## Begrenzter neuer FEM-/Surrogatbenchmark

Zwoelf vorab festgelegte Interpolationsfaelle, FEM-Warm-up und zwei Messungen pro Fall in umgekehrter Reihenfolge. Surrogate: Warm-up, 30 Einzelmessungen je Fall und 30 Batches mit allen zwoelf Faellen. Einzelzeiten sind Mediane der fallweisen Mediane; FEM-Batch ist die Summe dieser Fallmediane. Aufbau, Netz, Loesung und Interpolation sind im FEM-Aufruf enthalten; Transformation und POD-Rekonstruktion im Surrogataufruf. Rohdaten und Metadaten stehen unter `benchmark/`.

| Methode | FEM Einzel [s] | FEM IQR zwischen Faellen [s] | Surrogat Einzel [ms] | Surrogat IQR zwischen Faellen [ms] | FEM 12 seriell [s] | Surrogat Batch 12 [ms] |
|---|---|---|---|---|---|---|
| MLP | 2.132 | 1.610 | 9.033 | 0.263 | 29.387 | 10.248 |
| RBF | 2.132 | 1.610 | 8.690 | 0.588 | 29.387 | 10.083 |
| POD-MLP | 2.132 | 1.610 | 9.016 | 0.259 | 29.387 | 10.416 |
| POD-GPR | 2.132 | 1.610 | 6.902 | 0.316 | 29.387 | 16.652 |

## Bedingter Break-even

`ceil(Offlinekosten / (FEMzeit - Surrogatzeit))`, nur bei positiver Zeitersparnis. Offlinekosten: neuer Fit des Hauptmodells, optional neue aeussere Suche der Familie. Fuer Batchbetrieb wird auf ganze 12er-Batches aufgerundet. Vorhandene Trainings-/Referenzdaten werden als verfuegbar angenommen. Laden, Speichern, Qualitaetspruefung, Wiederholungsstudien und kuenftige Updates sind hier ausgeschlossen. Die Tabelle ist keine allgemeine Wirtschaftlichkeits- oder Genauigkeitsgarantie.

| Methode | Suche enthalten | Offline [s] | Break-even Einzelfaelle | Break-even Faelle in 12er-Batches |
|---|---|---|---|---|
| MLP | 0 | 47.110 | 23 | 24 |
| MLP | 1 | 516.489 | 244 | 216 |
| RBF | 0 | 39.020 | 19 | 24 |
| RBF | 1 | 618.615 | 292 | 264 |
| POD-MLP | 0 | 32.050 | 16 | 24 |
| POD-MLP | 1 | 291.632 | 138 | 120 |
| POD-GPR | 0 | 333.970 | 158 | 144 |
| POD-GPR | 1 | 1351.800 | 637 | 564 |

Historische Datenerzeugungskosten bleiben separat in `reference_costs_historical.csv` und werden nicht als neue Messungen ausgegeben. Der kleine FEM-Benchmark ersetzt keine Messung einer vollstaendigen neuen Trainingsdatenerzeugung.

## Einordnung und Artefakte

POD-GPR erzielt im vorliegenden Vollpoolvergleich den kleinsten mittleren Interpolationsfehler. Extrapolation bleibt deutlich schwieriger. Grosse relative Fehler bei kleinen Referenznormen muessen zusammen mit absoluten Feld- und Spitzenfehlern beurteilt werden. Die bekannte wissenschaftliche Ergaenzung in `../static_gpr_supplement_v1_20261112/SEMINARBERICHT_v1.md` enthaelt die Fall- und Lastgruppendiagnose; ihre historischen Zeiten sind von diesen neuen Messungen zu trennen.

Tabellen: `run_results.csv`, `case_results.csv`, `pipeline_summary.csv`, `search_costs.csv`, `search_attempts.csv`, `gpr_fit_timing_repeats.csv`, `comparison_previous.csv`. Diagramme: `plots/`. Quell-/Konfigurationsbindung: `source_manifest.csv`, `resolved_config.json`, `environment.mat`; vor Testauswertung erzeugtes Siegel: `freeze_manifest.csv`. Fruehere unterbrochene Versuche bleiben getrennt erhalten und gehen nicht in neue Zeiten ein.
