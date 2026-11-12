# Umstrukturierung direkt in Code v2

## Entscheidungen und Dateizuordnung

| Alter Ort | Aktiver Ort | Zweck |
|---|---|---|
| main.m ohne Argument: statischer und modaler Gesamtworkflow | runStaticStudy.m | Sicherer, ausschliesslich statischer Einstieg mit ausdruecklichen Phasen; main zeigt ohne Argument nur Hinweis |
| Verteilte addpath-Aufrufe | setupProject.m | Nur Code v2 und workflows/static_comparison aktivieren; onCleanup stellt vorherigen Pfad wieder her |
| studies/static_gpr_v1/runStaticGprStudy.m | runStaticStudy.m und +staticstudy/initialize, configure | Bedienung, Initialisierung und lokale/fachliche Konfiguration trennen |
| studies/static_gpr_v1/study_config.json und studyCandidates.m | workflows/static_comparison/configs/study.json und +staticstudy/candidates.m | Identische Kandidaten und Reihenfolge zentral versionieren |
| Fall-ID-Grenze 810460 in Tuning, Training, Verteilung | configs/training_blocks.csv und +staticstudy/trainingBlocks.m | Expliziter Join ueber Fall-ID; Ursprungsblock gegen backup_384/design.csv dokumentiert |
| studyGenerate.m, studyDesign.m | +staticstudy/generate.m, createDesign.m | Statische FEM mit demselben solve_case, explizite Ausschlussdesigns statt Pilotordnernamen |
| studyTuning.m, studyTraining.m | +staticstudy/tuning.m, training.m | Auswahl, Lernkurven, kontrollierte POD und Verteilung; checkpointbasierte Wiederaufnahme |
| studyFitCheckpoint.m | +staticstudy/fitCheckpoint.m | Unveraenderte numerische Fits, getrennte Validierung und persistente Ergebnisidentitaet |
| evaluation_repair_v1/studyEvaluationRepaired.m | +staticstudy/evaluation.m, observeModel.m, timePrediction.m | Manifest und Lastparameter eindeutig benennen; Checkpointschleife, Fallfehler und Zeitmessung trennen |
| evaluation_repair_v1/studyReportRepaired.m | +staticstudy/report.m und comparePrevious.m | Gespeicherte Ergebnisse auswerten; keine neue FEM/Modellwahl |
| Ergaenzung benchmark_v1.m | +staticstudy/benchmark.m | Derselbe vorab dokumentierte Messumfang, neue Modelle/Zeiten, eigene Rohdaten und Break-even-Szenarien |
| Wiederholte Kennzahlausdruecke | +surrogate/+study/summarizeErrors.m | Gemeinsamer Mittelwert, Median, Nearest-Rank-P95, Maximum, NaN-Zaehler |
| README.md als Sammlung historischer Einzelstudien | README.md plus docs/README_HISTORISCH.md | Kurze aktuelle Bedienung; alter Inhalt unveraendert archiviert |

Historische Programme, Optimierervarianten und vorhandene Studienartefakte wurden nicht verschoben oder geloescht. Die neue aktive Paketstruktur vermeidet Ueberlagerungen mit den alten study*-Funktionen. Netzarchitekturen und Testverfahren bleiben historische Programme ausserhalb des aktiven Pfads. Adam mit Validierung/Bestnetz in historischen Routinen ist nicht mit der aktiven Last-Iteration-Variante gleichgesetzt.

## Erhaltene Schnittstellen und fachliche Unterschiede

surrogate-v1, MAT-Datenstruktur D, Modellartefakte, Feldreihenfolge und Einheiten bleiben erhalten. Keine Aenderung an Physik, Normalisierung, Loss, POD-Basis, GPR-Fitverfahren oder Trainings-Zufallsfolge. Die Modellberichte erhalten nur additive Zeiten fuer Netzaufbau und Training; bisherige Segmentfelder bleiben lesbar. Bei GPR bleibt fitrgp ein gemeinsamer interner Aufbau-/Optimierungsaufruf; POD und Skalierung werden separat gemessen, ohne eine nicht messbare interne Trennung vorzut?uschen.

Der neue Mittelwert wird in urspruenglicher Fallreihenfolge gebildet. Der alte reparierte Bericht sortierte zuvor die Fehler und bildete dann den Mittelwert; mathematisch identisch, aber Rundungsdifferenzen von etwa 1e-17 sind moeglich. Die historische Tuningberechnung bleibt exakt erhalten. Vorhersagen und Fallfehler werden auf exakte Gleichheit geprueft.

Der neue Ablauf verwendet keine historischen Budgetstartpunkte. Das optionale Gesamtbudget startet neu; das Suchbudget und die Auswahlregeln bleiben erhalten. Trainingsdaten werden nicht neu erzeugt. Der Standardmodus referenziert die bestehenden geprueften Datensaetze an ihrem bisherigen Ort. Lokale Pfade sind getrennt von Fachparametern. Relative Pfade werden immer gegen Code v2 aufgeloest.

## Gebuendelte Pruefungen

Vollstaendige Quell-/Inputmanifeste werden an Phasengrenzen geprueft, nicht erneut unmittelbar vor/nach jedem einzelnen Fit oder FEM-Fall. Vor Testauswertung und Benchmark sowie danach wird das vollstaendige Freeze geprueft. Interne Referenzleser nutzen die zuvor gepruefte Phase; der explizite Referenzzugriff prueft die Freeze-Sperre weiterhin. Die Reportphase liest nur vorhandene Auswertungen und prueft ihre Hashes.

Erhalten: Datenvertrag beim Laden, statische Aufgabe, Dimensionen/Einheiten/Fallreihenfolge, Train/Val-Rollen, ID- und normalisierte Parameterueberschneidungen, trainingsbasierte Skalierung/POD, endliche Modellausgaben, Checkpointkonfiguration und Datenfingerprints, Modellhashes, unveraenderte Auswahl, Freeze-Sperre, freier Speicher. Keine globale Option zum Abschalten wissenschaftlicher Kontrollen.

Neue Laeufe haben eigene source_manifest.csv, resolved_config.json, reference_locations.json, environment.mat und freeze_manifest.csv. Git sichert den Quellzustand; die Manifeste binden dazu Daten, Konfiguration, Checkpoints und Ergebnisse. Alte Manifeste werden nicht angepasst. Modelle und grosse Falltabellen neuer Laeufe bleiben lokal; kleine Tabellen, Berichte und Provenienz werden gezielt versioniert.

## Tests und bisherige Befunde

83 bestehende Tests bestanden vor dem Umbau: Vertr?ge, direkte Netze, POD-MLP/GPR, Loss, verschachtelte Auswahlen, statische Auswertung und technische Reparatur. 16 neue Regressionstests pruefen unter anderem alle Kandidaten samt Reihenfolge, identische Trainingsauswahlen, exakte gespeicherte Modellvorhersagen und Fallfehler, Kennzahlen, sicheren Einstieg, Testzugriff und Checkpointablehnung.

Der erste Smoke-Versuch blieb unter experiments/static_comparison_smoke_20261112 erhalten. Er erzeugte FEM-Referenzen und trainierte/validierte alle vier Methoden, scheiterte aber an der abschliessenden Vollstaendigkeitspruefung: Bei einer alleinigen Seedangabe lief die alte Schleifenform einmal mit einem leeren Seed. reshape(...,1,[]) behebt den Randfall. Dieser Versuch ist keine erfolgreiche Hauptstudie. Weitere Pruefnachweise stehen in TESTNACHWEIS.md.

## Ergebnisvergleich und Codeumfang

Die Wiederholung schreibt comparison_previous.csv und VERGLEICH.md. Neue und historische Laufzeiten bleiben getrennte Spalten. Abweichungen fuehren nicht zu nachtraeglicher Anpassung der Modelle. Es handelt sich um bekannte Referenzfaelle, nicht um einen neuen unabhaengigen Abschlusstest.

Dateiweise reproduzierbare Codezaehlung: CODEZAEHLUNG.csv und CODEZAEHLUNG.md. Die Anzahl der Codezeilen ist kein Optimierungsziel.

Abgeschlossen am 12.11.2026: Hauptwiederholung static_comparison_refactor_20261112_attempt4, 234 erfolgreiche Fits, 288 Auswertungen. Identische Modellwahl und Fallkennzahlen; nur 13 Mittelwerte mit Rundungsdifferenzen bis 9.992e-16 durch die dokumentierte Summationsreihenfolge. Ergebnisse, neue Laufzeiten und bedingter Break-even: [WIEDERHOLUNG.md](../experiments/static_comparison_refactor_20261112_attempt4/WIEDERHOLUNG.md).
