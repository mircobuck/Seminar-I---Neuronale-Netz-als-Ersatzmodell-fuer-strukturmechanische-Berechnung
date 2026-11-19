# Abschluss der bereinigten statischen Hauptstudie

Versuch: `static_comparison_cleanup_20261113_attempt2`. MATLAB R2025b, serielle CPU-Ausfuehrung. Vier Methoden, unveraenderte 76 Suchkandidaten, Trainingsgroessen 48/96/192/384/768. Vorhandene FEM-Referenzen wurden unveraendert wiederverwendet. **Bekannte Referenzfaelle: kein neuer unabhaengiger Abschlusstest.**

## Umfang und Nachweise

Abgeschlossen: 234 versiegelte Fits, davon 88 Such-/Bestaetigungsfits und 146 Trainingsfits (58 Hauptpipeline, 78 kontrollierte POD, 8 Verteilungsstudie, 2 zusaetzliche GPR-Zeitwiederholungen). 144 Modelle mit je zwei Testsplit-Auswertungen: 288 erfolgreiche Lauf/Split-Zeilen, 55296 Fallzeilen. Keine fehlgeschlagenen Auswertungen oder undefinierten relativen Feldfehler.

Alle Dateien der Quell- und Freeze-Manifeste sowie Checkpoint-Siegel wurden nach Abschluss erneut geprueft. Numerischer Vergleich: numerical_comparison.csv und comparison_immediate_previous.csv; maschinenlesbarer Nachweis: verification.json. Vor dem Hauptlauf bestanden 71/71 aktuelle Tests und der vollstaendige FEM-Smoke. Quellstand der Hauptstudie: 5ba4840 (Funktionscode unveraendert seit d2357ff); danach keine Aenderungen an Funktionscode oder Konfiguration. Die Pruefung der vorhandenen Modelle ergab exakt gleiche Vorhersagen und numerische Fehler. Nachweise: ../../docs/STATISCHE_BEREINIGUNG.md und ../static_cleanup_validation_20261112.

Der neue Hauptlauf begann mit einem MATLAB-Installationspfad ohne historische Projektprogramme. Historische Quellen sind nur noch ueber Sicherungscommit 4e83631 erreichbar. Die Abschlusspruefung verwendete den dort gesicherten CSV-/Hashpruefer temporaer ausserhalb des aktiven Projekts; es wurde keine alte Programmkopie in Code v2 wiederhergestellt.

Phasenzeiten und Standby-/Speicherpruefung: [LAUFBEDINGUNGEN.md](LAUFBEDINGUNGEN.md). Neue Zeitmessungen stammen ausschliesslich aus diesem Studienprozess.

## Vergleich mit der bisherigen Hauptstudie

Alle Lauf-, Split- und Fallidentitaeten wurden zugeordnet. Der Vergleich umfasst Feldfehler, Referenznormen, Spitzen-/Maximalfehler und POD-Zerlegung; Zeiten sind bewusst nicht auf Gleichheit geprueft. Prueftoleranz je numerischem Wert: 1e-12 absolut + 1e-12 relativ zum historischen Wert.

| Tabelle | Kennzahl | Abweichende Werte | Max. absolute Differenz | Ausserhalb Toleranz |
|---|---|---|---|---|
| run_results.csv | avg | 13 | 9.99e-16 | 0 |
| case_results.csv | Relative | 0 | 0 | 0 |

Gegenueber der unmittelbar vorherigen Wiederholung static_comparison_refactor_20261112_attempt4 sind saemtliche verglichenen numerischen Lauf- und Fallkennzahlen exakt identisch (comparison_immediate_previous.csv).

Alle 55.296 Fallzeilen sind in den verglichenen Kennzahlen exakt identisch (einschliesslich gleicher undefinierter POD-Felder bei direkten Modellen). Nur 13 Mittelwerte unterscheiden sich um maximal 9.992e-16: Der historische studyReport sortiert die Fehler vor der Mittelwertbildung; summarizeErrors erhaelt fuer den Mittelwert die Fallreihenfolge und sortiert nur fuer P95. Die beobachtete Abweichung ist damit durch Gleitkomma-Summation erklaert; Median, P95, Maximum und absolute Mittelwerte sind exakt gleich.

Die gewaehlten Konfigurationen sind in `VERGLEICH.md` gegen die historischen Auswahlobjekte geprueft. Keine nachtraegliche Anpassung anhand der bekannten Testwerte.

| Methode | Kandidaten | Fits inkl. Bestaetigung | Gewinner-ID | Neue aeussere Suchzeit [s] |
|---|---|---|---|---|
| MLP | 16 | 20 | 4 | 502.029 |
| RBF | 24 | 28 | 20 | 567.000 |
| POD-MLP | 12 | 16 | 4 | 261.033 |
| POD-GPR | 24 | 24 | 20 | 1051.934 |

Aeussere Gesamtsuchzeit einschliesslich Verwaltung: 2382.436 s.

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
| distribution\skew_mlp | extrapolation | 39.626 | 13.469 |
| distribution\skew_mlp | interpolation | 14.283 | 13.469 |
| distribution\skew_pod_gpr | extrapolation | 30.624 | 15.049 |
| distribution\skew_pod_gpr | interpolation | 5.082 | 15.049 |
| distribution\skew_pod_mlp | extrapolation | 52.083 | 11.933 |
| distribution\skew_pod_mlp | interpolation | 15.265 | 11.933 |
| distribution\skew_rbf | extrapolation | 62.125 | 11.740 |
| distribution\skew_rbf | interpolation | 23.349 | 11.740 |
| distribution\space_mlp | extrapolation | 19.717 | 18.977 |
| distribution\space_mlp | interpolation | 5.454 | 18.977 |
| distribution\space_pod_gpr | extrapolation | 13.915 | 15.323 |
| distribution\space_pod_gpr | interpolation | 2.902 | 15.323 |
| distribution\space_pod_mlp | extrapolation | 41.679 | 9.806 |
| distribution\space_pod_mlp | interpolation | 6.969 | 9.806 |
| distribution\space_rbf | extrapolation | 43.247 | 11.718 |
| distribution\space_rbf | interpolation | 7.652 | 11.718 |

## Kontrollierte POD-Raenge bei N=768

Je Rang ein gemeinsamer trainingsbasierter POD-Zustand. Eigenstaendige Fit-Kosten sind oeffentlicher Fit mit vorberechneter Basis plus einmalige gemeinsame POD-Zeit; dies ist eine additive Kostenschaetzung. Je Zeile ein Modell mit Seed 42.

| Lauf | Split | Mittlere Projektion [%] | Mittlerer Fehler [%] | Fit + gemeinsame POD [s] | POD-Anteil [s] | Modell [MiB] |
|---|---|---|---|---|---|---|
| controlled\n768_rep1_rank10_pod_gpr | extrapolation | 0.001151 | 3.853 | 233.800 | 0.512359 | 24.777 |
| controlled\n768_rep1_rank10_pod_gpr | interpolation | 0.000787 | 0.549 | 233.800 | 0.512359 | 24.777 |
| controlled\n768_rep1_rank10_pod_mlp | extrapolation | 0.001151 | 11.627 | 39.665 | 0.512359 | 0.624 |
| controlled\n768_rep1_rank10_pod_mlp | interpolation | 0.000787 | 3.993 | 39.665 | 0.512359 | 0.624 |
| controlled\n768_rep1_rank15_pod_gpr | extrapolation | 0.000809 | 3.854 | 373.212 | 0.613254 | 37.246 |
| controlled\n768_rep1_rank15_pod_gpr | interpolation | 0.000526 | 0.549 | 373.212 | 0.613254 | 37.246 |
| controlled\n768_rep1_rank15_pod_mlp | extrapolation | 0.000809 | 14.397 | 35.238 | 0.613254 | 0.796 |
| controlled\n768_rep1_rank15_pod_mlp | interpolation | 0.000526 | 3.056 | 35.238 | 0.613254 | 0.796 |
| controlled\n768_rep1_rank2_pod_gpr | extrapolation | 0.115419 | 3.861 | 86.242 | 0.617090 | 5.088 |
| controlled\n768_rep1_rank2_pod_gpr | interpolation | 0.058786 | 0.560 | 86.242 | 0.617090 | 5.088 |
| controlled\n768_rep1_rank2_pod_mlp | extrapolation | 0.115419 | 13.850 | 36.207 | 0.617090 | 0.348 |
| controlled\n768_rep1_rank2_pod_mlp | interpolation | 0.058786 | 5.022 | 36.207 | 0.617090 | 0.348 |

## Neue Laufzeitmessungen

Die folgende Tabelle verwendet die vorab festgelegten Vollpool-Hauptmodelle mit Seed 42. Der vollstaendige oeffentliche Fit umfasst die Modellpipeline; Validierungsvorhersage und Speichern liegen ausserhalb. Netzwerkaufbau und Optimierung sind additive Zeitinstrumentierung, keine Aenderung des Trainings. Bei GPR bezeichnet Regression den gesamten Koeffizientenfit. Nicht anwendbare Segmente erscheinen als n/a. Die historischen Segmentfelder ueberlappen: Regression umfasst bei MLP/RBF Netzaufbau plus Optimierung, bei POD-MLP die Optimierung, bei GPR den gesamten Koeffizientenfit. Diese Spalten duerfen nicht zusammenaddiert werden. Der Center-Zweig enthaelt nur bei RBF einen Zentrenfit; bei MLP misst er den leeren Zweig.

| Methode | Fit neu [s] | Fit historisch [s] | Vorverarbeitung [s] | POD [s] | Center-Zweig [s] | Netzaufbau [s] | Optimierung [s] | Regression [s] | Laden [s] | Speichern [s] |
|---|---|---|---|---|---|---|---|---|---|---|
| MLP | 60.398 | 52.672 | 0.036644 | n/a | 0.000998 | 0.295670 | 60.026539 | 60.322917 | 0.126101 | 0.175580 |
| RBF | 52.987 | 43.708 | 0.019518 | n/a | 0.006814 | 0.021931 | 52.925886 | 52.947823 | 0.082522 | 0.078655 |
| POD-MLP | 32.677 | 32.263 | 0.000641 | 0.673457 | n/a | 0.037771 | 31.950537 | 31.950537 | 0.073121 | 0.075212 |
| POD-GPR | 419.634 | 353.569 | 0.007064 | 0.483284 | n/a | n/a | n/a | 418.977592 | 0.879892 | 2.677130 |

Drei deterministische GPR-Fit-Zeitwiederholungen [s]: 419.634431, 412.615947, 371.144965; Median 412.615947 s. Keine drei unabhaengigen Modellreplikate. Trainings-/Validierungs-IDs, Rang/Seed und alle Validierungsfallfehler sind identisch (`gpr_repeat_verification.json`). Neuronale Seeds 42/43/44 erzeugen dagegen verschiedene Initialisierungen. Neue und historische Zeiten stammen aus getrennten Sitzungen; Unterschiede sind kein isolierter Nachweis einer durch die Bereinigung verursachten Beschleunigung.

Vorhersage ueber den vollstaendigen oeffentlichen Aufruf nach Warm-up, 30 Wiederholungen. Einzelfall und Batch 128: Median und IQR der Zeitwiederholungen.

| Methode | Einzel Median / IQR [ms] | Batch 128 Median / IQR [ms] |
|---|---|---|
| MLP | 9.620 / 1.747 | 12.622 / 2.337 |
| RBF | 9.149 / 1.637 | 12.084 / 1.400 |
| POD-MLP | 8.741 / 1.080 | 10.134 / 0.920 |
| POD-GPR | 7.012 / 1.250 | 44.094 / 3.288 |

## Begrenzter neuer FEM-/Surrogatbenchmark

Zwoelf vorab festgelegte Interpolationsfaelle, FEM-Warm-up und zwei Messungen pro Fall in umgekehrter Reihenfolge. Surrogate: Warm-up, 30 Einzelmessungen je Fall und 30 Batches mit allen zwoelf Faellen. Einzelzeiten sind Mediane der fallweisen Mediane; FEM-Batch ist die Summe dieser Fallmediane. Aufbau, Netz, Loesung und Interpolation sind im FEM-Aufruf enthalten; Transformation und POD-Rekonstruktion im Surrogataufruf. Rohdaten und Metadaten stehen unter `benchmark/`.

| Methode | FEM Einzel [s] | FEM IQR zwischen Faellen [s] | Surrogat Einzel [ms] | Surrogat IQR zwischen Faellen [ms] | FEM 12 seriell [s] | Surrogat Batch 12 [ms] |
|---|---|---|---|---|---|---|
| MLP | 2.794 | 2.197 | 9.712 | 0.383 | 35.001 | 10.744 |
| RBF | 2.794 | 2.197 | 8.289 | 0.491 | 35.001 | 9.615 |
| POD-MLP | 2.794 | 2.197 | 9.495 | 0.525 | 35.001 | 16.528 |
| POD-GPR | 2.794 | 2.197 | 6.946 | 0.248 | 35.001 | 17.836 |

## Bedingter Break-even

`ceil(Offlinekosten / (FEMzeit - Surrogatzeit))`, nur bei positiver Zeitersparnis. Offlinekosten: neuer Fit des Hauptmodells, optional neue aeussere Suche der Familie. Fuer Batchbetrieb wird auf ganze 12er-Batches aufgerundet. Vorhandene Trainings-/Referenzdaten werden als verfuegbar angenommen. Laden, Speichern, Qualitaetspruefung, Wiederholungsstudien und kuenftige Updates sind hier ausgeschlossen. Die Tabelle ist keine allgemeine Wirtschaftlichkeits- oder Genauigkeitsgarantie.

| Methode | Suche enthalten | Offline [s] | Break-even Einzelfaelle | Break-even Faelle in 12er-Batches |
|---|---|---|---|---|
| MLP | 0 | 60.398 | 22 | 24 |
| MLP | 1 | 562.427 | 203 | 204 |
| RBF | 0 | 52.987 | 20 | 24 |
| RBF | 1 | 619.987 | 223 | 216 |
| POD-MLP | 0 | 32.677 | 12 | 12 |
| POD-MLP | 1 | 293.710 | 106 | 108 |
| POD-GPR | 0 | 419.634 | 151 | 144 |
| POD-GPR | 1 | 1471.568 | 529 | 516 |

Historische Datenerzeugungskosten bleiben separat in `reference_costs_historical.csv` und werden nicht als neue Messungen ausgegeben. Der kleine FEM-Benchmark ersetzt keine Messung einer vollstaendigen neuen Trainingsdatenerzeugung.

## Einordnung und Artefakte

POD-GPR erzielt im vorliegenden Vollpoolvergleich den kleinsten mittleren Interpolationsfehler. Extrapolation bleibt deutlich schwieriger. Grosse relative Fehler bei kleinen Referenznormen muessen zusammen mit absoluten Feld- und Spitzenfehlern beurteilt werden. Die bekannte wissenschaftliche Ergaenzung in `../static_gpr_supplement_v1_20261112/SEMINARBERICHT_v1.md` enthaelt die Fall- und Lastgruppendiagnose; ihre historischen Zeiten sind von diesen neuen Messungen zu trennen.

Tabellen: `run_results.csv`, `case_results.csv`, `pipeline_summary.csv`, `search_costs.csv`, `search_attempts.csv`, `gpr_fit_timing_repeats.csv`, `comparison_previous.csv`. Diagramme: `plots/`. Quell-/Konfigurationsbindung: `source_manifest.csv`, `resolved_config.json`, `environment.mat`; vor Testauswertung erzeugtes Siegel: `freeze_manifest.csv`. Fruehere unterbrochene Versuche bleiben getrennt erhalten und gehen nicht in neue Zeiten ein.
