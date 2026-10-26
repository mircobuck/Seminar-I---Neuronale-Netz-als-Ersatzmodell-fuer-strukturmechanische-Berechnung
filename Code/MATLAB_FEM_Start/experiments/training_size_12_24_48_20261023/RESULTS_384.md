# Erweiterung auf 384 Trainingsfälle

Abgeschlossen am 23.10.2026 über MATLAB MCP, MATLAB R2025b Update 1.
Vorheriger Stand: [Bericht bis 192](milestone_192/RESULTS_192.md).

## Versuchsaufbau

192 neue FEM-Trainingsfälle ergänzen die bisherigen 192 unverändert.
Validierung und Test bleiben dieselben jeweils sechs Fälle. Gleich bleiben
Physik, Netzregel, Referenzgitter, Modell-Seed 42, GP-Einstellungen,
RBF-Kandidaten und MLP-Trainingsregeln. POD-Rangkandidaten: [2, 4, 8, 11].
Skalierung, POD und Regression werden jeweils aus dem eigenen Trainingssatz
gelernt. Die Auswahlregel verwendet weiterhin ausschließlich die Validierung.

Vorab gespeichert: [PLAN_EXTENSION_384.md](PLAN_EXTENSION_384.md).
192 neue randomisierte LHS-Punkte, Seed 20261026 (twister), IDs 205–396.
Die ursprünglichen 192 Trainingsfälle sind vollständig enthalten; der gesamte
Satz ist verschachtelt, kein neu optimiertes LHS. CSV-Eingaben verwenden
17 signifikante Stellen und wurden verlustfrei zurückgelesen.

## Median des relativen Feldfehlers

Gewichteter relativer L2-Fehler in Prozent auf identischen Testfällen.

| Modell | 12 | 24 | 48 | 96 | 192 | 384 |
|---|---:|---:|---:|---:|---:|---:|
| POD_GP | 60,65 % | 23,25 % | 4,66 % | 3,50 % | 1,14 % | 0,384 % |
| POD_RBF | 23,26 % | 26,31 % | 18,41 % | 5,41 % | 3,64 % | 5,459 % |
| POD_MLP | 21,46 % | 9,85 % | 13,37 % | 13,80 % | 8,11 % | 3,314 % |

## Größter relativer Feldfehler

| Modell | 192 | 384 |
|---|---:|---:|
| POD_GP | 7,109 % | 2,682 % |
| POD_RBF | 15,887 % | 12,159 % |
| POD_MLP | 1384,945 % | 22,672 % |

Mit sechs Testfällen ist das verwendete P95 hier gleich dem Maximum.
POD_GP erfüllt auf diesem Vergleichssatz erstmals beide Arbeitsziele:
Median <1 % und P95 <3 %. Das belegt keine allgemeine Genauigkeitsgarantie.
RBF verbessert das Maximum, verschlechtert aber den Median. MLP verbessert
beide Kennzahlen deutlich; seine vorigen Ausreißerschwankungen bleiben ein
Grund, ihn nicht allein nach dem Median zu beurteilen.

## Skalare Spitzenverschiebung: MAE in µm

| Modell | 192 | 384 |
|---|---:|---:|
| Scalar_GPR | 3,33496 | 0,72855 |
| Beam_plus_GPR | 0,0248183 | 0,0076744 |
| Balkentheorie ohne Lernen | 0,4533 | 0,4533 |

Gewählte n384-Feldmodelle: GP Rang 11; RBF Rang 11/Lambda 0;
MLP Rang 4/Breite 32. Mittlerer Validierungsfehler: 0,7064 %, 4,4480 %
und 5,8625 %. Die genauen Werte und alle Kandidaten sind gespeichert.

## Ausführung und Prüfungen

Einmal prepare384, generate384, train384, evaluate384 und summarize ausgeführt.
Alle drei Berechnungsstufen erfolgreich, ohne MATLAB-Laufzeitfehler:
FEM-Erzeugung 306,556 s; Training/Modellauswahl 256,112 s; Auswertung 0,813 s.
Rohprotokolle und Zeitstempel stehen in events.csv und logs/.

Geprüft: Fallanzahlen, Dimensionen, endliche Feld-/Skalarwerte, disjunkte IDs,
identische Physik und exakt identische Validierungs-/Testdaten. Die Parameter,
FEM-Felder und skalaren Ziele aller bisherigen 192 Trainingsfälle sind exakt
im neuen Satz enthalten. Alle 35 ursprünglichen Run-Dateien und alle 478
zuvor vorhandenen Dateien in n12/n24/n48/n96/n192 sind per SHA-256 unverändert.

Die bestehenden Solver-, Trainings- und Evaluierungsfunktionen wurden nicht
verändert. Der Code Analyzer zeigt weiterhin einen ungenutzten Parameter im
älteren Vorbereitungsschritt und drei Hinweise zur Tabellenvorallokation;
keine Syntaxfehler. Die früheren FEM-Skalierungsprüfungen und mesh_check wurden
für die reine Datenerweiterung nicht erneut ausgeführt.

Jetzt liegen 396 unterschiedliche Fälle vor: 384 Training, sechs Validierung,
sechs Test. Seit der ursprünglichen Smoke-Stufe wurden 372 neue FEM-Fälle
ergänzt. Kein bestehendes Modell überschrieben, kein Pilot-Lauf gestartet.

## Grenzen und Nachvollziehbarkeit

Die Erweiterung wurde nach Sichtung bisheriger Ergebnisse beauftragt. Ein
Seed und sechs bereits bekannte Testfälle erlauben nur einen explorativen
Vergleich. Es wurde nicht anhand neuer Testfehler nachoptimiert. Das gleiche
MLP-Epochenlimit bedeutet bei mehr Daten mehr Optimierungsschritte je Epoche;
Early Stopping bleibt aktiv. Laufzeiten sind keine kontrollierten Benchmarks.

- [comparison.csv](comparison.csv): alle fünf Modelle über sechs Trainingsgrößen.
- [case_errors.csv](case_errors.csv): jeder Testfall und jede Stufe.
- [selected_models.csv](selected_models.csv): Auswahl und Validierungsfehler.
- [Lernkurve](learning_curve.png): Median und Maximum. Für den finalen Export
  wurden beide Achsen logarithmisch skaliert, damit die Verdopplungen gleich
  weit auseinanderliegen und die kleinen Trainingsgrößen lesbar bleiben.
- extension_n384.mat, design_n384.csv, additional_training_design_n384.csv,
  case_provenance_n384.csv: genaue Konfiguration, Eingaben und Herkunft.
- n384/: neue Modelle, Kandidaten, FEM-Rohdaten, Splits und Vorhersagen.
- milestone_192/: archivierter Stand vor dieser Erweiterung.
- source_snapshot_n384/: ausgeführter Quellstand.
- files_before_n384.json und preservation_check_n384.txt: Dateierhalt.
- artifact_hashes_n384.json: finale Hashes der Studienartefakte.

Runner-Stufen: prepare384, generate384, train384, evaluate384, summarize.
Der Runner verweigert das Überschreiben bereits gespeicherter Modelle und
Testauswertungen. Für weitere Untersuchungen ein neues Protokoll verwenden.
