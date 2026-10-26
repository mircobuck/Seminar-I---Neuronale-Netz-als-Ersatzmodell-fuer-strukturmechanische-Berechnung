# Erweiterung auf 192 Trainingsfälle

Abgeschlossen am 23.10.2026 über MATLAB MCP unter R2025b Update 1.
Vorheriger Gesamtstand: [RESULTS.md](milestone_96/RESULTS.md).

## Kontrollierter Aufbau

96 neue FEM-Trainingsfälle ergänzen unverändert die bisherigen 96. Validierung
und Test bleiben jeweils dieselben sechs Fälle. Physik, Netz, Referenzgitter,
Modell-Seed 42 und Suchraum sind gleich, insbesondere POD-Ränge [2, 4, 8, 11].
Skalierung, Basis und Regression werden nur auf dem neuen Trainingssatz gelernt;
Modellauswahl erfolgt weiterhin anhand der Validierung.

Die Ergänzung verwendet 96 randomisierte LHS-Punkte mit Seed 20261025 (twister),
IDs 109–204. Protokoll vor der Berechnung: [PLAN_EXTENSION_192.md](PLAN_EXTENSION_192.md).
CSV-Eingaben wurden mit 17 signifikanten Stellen geschrieben und verlustfrei
zurückgelesen. Der kombinierte Satz ist verschachtelt, kein neu optimiertes LHS.

## Median des relativen Feldfehlers

Gewichteter relativer L2-Fehler in Prozent auf demselben Testsatz.

| Modell | 12 | 24 | 48 | 96 | 192 |
|---|---:|---:|---:|---:|---:|
| POD_GP | 60,65 % | 23,25 % | 4,66 % | 3,50 % | 1,14 % |
| POD_RBF | 23,26 % | 26,31 % | 18,41 % | 5,41 % | 3,64 % |
| POD_MLP | 21,46 % | 9,85 % | 13,37 % | 13,80 % | 8,11 % |

## Maximum des relativen Feldfehlers

| Modell | 96 | 192 |
|---|---:|---:|
| POD_GP | 17,21 % | 7,11 % |
| POD_RBF | 76,47 % | 15,89 % |
| POD_MLP | 23,70 % | 1384,94 % |

Mit sechs Testfällen ist das hier verwendete P95 gleich dem Maximum.
Der MLP-Median allein würde die starke Verschlechterung des Ausreißers verdecken.
Eine stetige Verbesserung des MLP ist durch die Reihe nicht belegt.
POD_GP und POD_RBF verbessern bei dieser Verdopplung Median und Maximum.
Die ursprünglichen Ziele Median <1 % und P95 <3 % sind weiterhin nicht erreicht.

## Skalare Spitzenverschiebung: MAE in µm

| Modell | 96 | 192 |
|---|---:|---:|
| Scalar_GPR | 4,0849 | 3,3350 |
| Beam_plus_GPR | 0,08022 | 0,02482 |
| Balkentheorie ohne Lernen | 0,4533 | 0,4533 |

Gewählte n192-Feldmodelle: GP Rang 11; RBF Rang 11/Lambda 0; MLP Rang 4/Breite 32.
Mittlerer Validierungs-Feldfehler: 0,9662 %, 5,0249 % bzw. 54,5604 %.
Alle Kandidaten, Einzelfehler und genauen Kennzahlen sind gespeichert.

## Ausführung und Prüfungen

Einmal prepare192, generate192, train192, evaluate192 und summarize ausgeführt.
Neue FEM-Erzeugung: 163,227 s; Training inklusive Modellauswahl: 30,465 s;
Auswertung: 0,796 s. Alle drei Berechnungsstufen erfolgreich, kein Laufzeitfehler.
Die Basismodelle wurden nicht erneut trainiert. Keine Optimierung anhand neuer
Testfehler durchgeführt. Der Code Analyzer zeigte einen ungenutzten Parameter
im neuen Vorbereitungsschritt und drei Hinweise zur Tabellenvorallokation;
keine Syntaxfehler. Bestehende Solver und Modellfunktionen blieben unverändert.

Geprüft wurden Fallanzahlen, Dimensionen, endliche FEM-Werte, disjunkte IDs,
identische Physik, identische Validierungs-/Testdaten und die vollständige
numerische Übernahme aller bisherigen 96 Trainingsfälle einschließlich X, S, Y.
Alle 35 ursprünglichen Run-Dateien sowie alle 265 zuvor vorhandenen Dateien
der Stufen n12/n24/n48/n96 sind per SHA-256 unverändert.

Damit liegen jetzt 204 unterschiedliche Fälle vor: 192 Training, sechs
Validierung und sechs Test. Seit Beginn der Erweiterungsreihe wurden insgesamt
180 neue FEM-Fälle berechnet. Kein bestehendes Modell überschrieben;
kein Pilot-Lauf gestartet.

Die Wahl zur weiteren Verdopplung erfolgte nach Sichtung bisheriger Resultate.
Es bleibt eine explorative Reihe mit einem Daten-/Modell-Seed und kleinem,
bereits bekanntem Testsatz. Gleiches MLP-Epochenlimit bedeutet bei mehr Daten
mehr Optimierungsschritte pro Epoche; Laufzeiten enthalten Warmup/Early Stopping.

## Nachweise

- [comparison.csv](comparison.csv), [case_errors.csv](case_errors.csv),
  [selected_models.csv](selected_models.csv): vollständige Ergebnisse aller fünf Stufen.
- [Lernkurve](learning_curve.png): Median und Maximum über alle Stufen.
- [events.csv](events.csv) und logs/: tatsächliche Ausgaben, Status und Laufzeiten.
- extension_n192.mat, design_n192.csv, additional_training_design_n192.csv,
  case_provenance_n192.csv: Konfiguration und genaue neue Eingaben.
- n192/: neue Modelle, FEM-Rohdaten, Splits, Auswahl und Vorhersagen.
- milestone_96/: archivierter Bericht, Ergebnisse und Grafik bis 96.
- source_snapshot_n192/: ausführbarer Quellstand dieser Erweiterung.
- files_before_n192.json / preservation_check_n192.txt: Erhalt früherer Ergebnisse.
- artifact_hashes_n192.json: finale Dateihashes.

Fortsetzen über `run_training_size_study(stage)`; die neuen Stufen heißen
prepare192, generate192, train192 und evaluate192. Vorhandene Modelle und
Testauswertungen werden vom Runner vor Überschreiben geschützt.
