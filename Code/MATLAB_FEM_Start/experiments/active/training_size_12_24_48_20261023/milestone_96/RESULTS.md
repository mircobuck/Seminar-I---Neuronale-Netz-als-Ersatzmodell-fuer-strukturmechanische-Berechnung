# Trainingsmenge: 12 → 24 → 48 → 96 Fälle

Stand: 23.10.2026. Alle Stufen abgeschlossen über MATLAB MCP mit
MATLAB 25.2.0.3042426 (R2025b) Update 1.

## Versuchsaufbau

Nur die Trainingsdatenmenge wurde planmäßig erweitert. Jeder Trainingssatz
enthält den vollständigen vorherigen Satz. Sechs Validierungs- und sechs
Testfälle bleiben numerisch exakt identisch. Physik, Netzregel, Referenzgitter,
GP-Einstellungen, RBF-Kandidaten, MLP-Einstellungen und Modell-Seed 42 bleiben
gleich. Die wirksamen POD-Rangkandidaten sind für alle Stufen [2, 4, 8, 11].
Skalierung, POD und Regression werden jeweils neu aus Training gelernt;
gewählte Ränge und Hyperparameter dürfen sich nach der gleichen
Validierungsregel unterscheiden. Keine Auswahl anhand neuer Testfehler.

Die ersten 36 zusätzlichen Punkte sind ein randomisiertes LHS mit Seed
20261023: zwölf davon ergänzen n24, alle 36 ergänzen n48. Auf weiteren
Nutzerauftrag kamen 48 LHS-Punkte mit Seed 20261024 für n96 hinzu.
Die zusammengesetzten Datensätze sind verschachtelt und keine jeweils
neu optimierten LHS-Designs. Alle Designs sind gespeichert und wurden mit
17 signifikanten Stellen verlustfrei nach CSV geschrieben und zurückgelesen.

Vorabprotokolle: [PLAN.md](PLAN.md) und [PLAN_EXTENSION_96.md](PLAN_EXTENSION_96.md).
Die Erweiterung auf 96 wurde erst nach Kenntnis der 48er-Ergebnisse beauftragt.
Der Testsatz war bereits bekannt: Dies ist eine explorative Vergleichsreihe,
kein neuer blinder Holdout. Ein Daten- und Modell-Seed, sechs Testfälle.

## Median des relativen Feldfehlers

Gewichteter relativer L2-Fehler in Prozent, jeweils auf denselben Testfällen.

| Modell | 12 | 24 | 48 | 96 |
|---|---:|---:|---:|---:|
| POD_GP | 60,65 % | 23,25 % | 4,66 % | 3,50 % |
| POD_RBF | 23,26 % | 26,31 % | 18,41 % | 5,41 % |
| POD_MLP | 21,46 % | 9,85 % | 13,37 % | 13,80 % |

## Größter relativer Feldfehler

| Modell | 12 | 24 | 48 | 96 |
|---|---:|---:|---:|---:|
| POD_GP | 2534,01 % | 127,04 % | 63,81 % | 17,21 % |
| POD_RBF | 793,00 % | 91,36 % | 98,93 % | 76,47 % |
| POD_MLP | 918,35 % | 1102,56 % | 1411,72 % | 23,70 % |

Bei sechs Testfällen ist das verwendete P95 hier gleich dem Maximum.

## MAE der skalaren Spitzenverschiebung

In Mikrometern; eine andere Kennzahl als der relative Feldfehler.

| Modell | 12 | 24 | 48 | 96 |
|---|---:|---:|---:|---:|
| Scalar_GPR | 110,2806 | 39,5396 | 19,1077 | 4,0849 |
| Beam_plus_GPR | 0,5068 | 0,1359 | 0,1145 | 0,0802 |
| Balkentheorie ohne Lernen | 0,4533 | 0,4533 | 0,4533 | 0,4533 |

## Beobachtung und Grenzen

- POD_GP verbessert Median und Maximum bei jeder Verdopplung.
- RBF verbessert sich insgesamt deutlich, aber nicht monoton in jedem Schritt.
- MLP zeigt keine stetige Verbesserung des Medians. Die 96er-Stufe beseitigt
  jedoch den vorher extremen relativen Ausreißer weitgehend. Ein guter Median
  allein hätte diese Entwicklung verdeckt.
- Beide Skalarmodelle verbessern ihren MAE bei jedem Schritt. Die gelernte
  Balkenkorrektur übertrifft ab n24 die reine Balkentheorie auf diesem Testsatz.
- Die niedrigen POD-Projektionsfehler sprechen für eine Begrenzung durch
  Regression/Datenabdeckung statt vorwiegend durch die Basis; dies ist eine
  Einordnung und kein Nachweis einer einzelnen Ursache.
- Die ursprünglichen Feldziele Median <1 % und P95 <3 % sind weiterhin nicht
  erreicht. Einzelne Testfehler und Validierungsfehler bleiben relevant.
- Die MLP-Batchgröße bleibt 16 und das Epochenlimit 300. Mit mehr Daten wächst
  die Zahl der Optimierungsschritte pro Epoche; Early Stopping bleibt aktiv.
  Trainingszeiten sind durch Warmup und Early Stopping keine kontrollierten
  Hardware-Benchmarks.

## Tatsächlich ausgeführt und geprüft

Die 12er-Basis wurde vollständig kopiert, nicht nachtrainiert. Danach jeweils
einmal generate/train/evaluate für n24, n48 und n96; abschließend summarize.
Es wurden 12 + 24 + 48 = **84 neue FEM-Fälle** berechnet. Zusammen mit den
ursprünglichen 24 liegen 108 verschiedene physikalische Fälle vor:
96 Training, sechs Validierung und sechs Test.

Prüfungen: verlustfreier Design-CSV-Rundlauf, Fallanzahl, Feldmatrixdimensionen,
endliche Werte, disjunkte IDs, identische Physik und unveränderte Holdout-Daten.
Die vollständigen 24 Fälle wurden in n48 und die vollständigen 48 Fälle in n96
einschließlich Parameter, FEM-Feldern und Skalarzielen exakt nachgewiesen.
Die ursprünglichen Skalierungstests und mesh_check wurden nicht erneut gestartet.

Beim ersten prepare96-Aufruf verwendete MATLAB noch die alte geladene
Runner-Version und meldete `Unknown study stage: prepare96`. Nach Prüfung des
Funktionspfads wurde gezielt `clear run_training_size_study; rehash` ausgeführt.
Danach war die Vorbereitung erfolgreich. Vor diesem Fehler wurden keine
n96-Daten erzeugt; kein Training musste wiederholt werden. Die neun eigentlichen
Generate-/Train-/Evaluate-Stufen liefen erfolgreich; Details in events.csv.

Alle 35 ursprünglichen Run-Dateien und alle 148 vor der letzten Erweiterung
vorhandenen n12/n24/n48-Dateien sind per SHA-256 unverändert. Kein bestehendes
Modell überschrieben. Kein Pilot-Lauf gestartet.

## Nachweise und Weiterarbeit

- [Lernkurve](learning_curve.png): Median und Maximum für alle vier Stufen.
- [comparison.csv](comparison.csv): alle fünf Modelle, genaue Fehler, POD-Floors
  und Laufzeiten; CSV-Fehler sind Verhältnisse, keine Prozentwerte.
- [case_errors.csv](case_errors.csv): Einzelfehler jedes Testfalls pro Stufe.
- [selected_models.csv](selected_models.csv): tatsächlich gewählte Parameter
  und Validierungsfehler. Für n96: GP Rang 11; RBF Rang 11/Lambda 1e-4;
  MLP Rang 4/Breite 32.
- [events.csv](events.csv) und logs/: Zeitstempel, Laufzeiten, Status und
  tatsächliche MATLAB-Ausgaben aller neun Berechnungsstufen.
- protocol.mat / extension_n96.mat: vollständige Konfigurationen.
- design_n24.csv / design_n48.csv / design_n96.csv: genaue Eingaben.
- case_provenance.csv / case_provenance_n96.csv: Datenherkunft und IDs.
- n12/, n24/, n48/, n96/: unveränderte Modelle, Rohdaten und Resultate je Stufe.
- milestone_48/: eingefrorener Bericht, Tabellen und Plot vor dem 96er-Auftrag.
- source_snapshot/ und source_snapshot_n96/: ausführbare Quellstände.
- original_files.json / files_before_n96.json / preservation_check.txt:
  Belege für den Erhalt bestehender Dateien.
- artifact_hashes.json: finale Hashes der Studienartefakte.

Der Runner `run_training_size_study.m` verweigert das Überschreiben von Modellen
und bereits vorhandenen Testauswertungen. Stufen lassen sich gezielt fortsetzen.
Für Wiederholungen einen neuen Studienordner angeben. Die 96er-Erweiterung wird
nach Abschluss der 48er-Stufe durch prepare96, generate96, train96, evaluate96
und summarize ausgeführt. Das Pilot-Projekt bleibt getrennt.
