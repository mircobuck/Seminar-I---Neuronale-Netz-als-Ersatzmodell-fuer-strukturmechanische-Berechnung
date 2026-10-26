# Prüfstatus

## Lokale MATLAB-MCP-Prüfung am 23.10.2026

MATLAB 25.2.0.3042426 (R2025b) Update 1. Alle angeforderten Smoke-Stufen
wurden tatsächlich ausgeführt und ohne MATLAB-Laufzeitfehler abgeschlossen:

- `addpath('src','tests')`
- `run_checks(true)`: POD-Rekonstruktion und gewichtete Orthogonalität,
  RBF-Reproduktion an neuen Punkten, Split-/ID-Prüfungen beider Designs,
  drei FEM-Läufe für Kraft- und E-Modul-Skalierung bestanden.
- `run_project("smoke","generate")`: 24 neue FEM-Fälle; Splits 12/6/6.
- `run_project("smoke","train")`: fünf Modelle erstmals trainiert und eingefroren.
- `run_project("smoke","evaluate")`: Auswertung auf sechs Testfällen abgeschlossen.
- `plot_test_case("smoke","POD_GP",1)`: ausgeführt; für einen größeren,
  visuell geprüften PNG-Export ein zweites Mal ausgeführt.
- Zusätzliche Datenprüfung: endliche Feld-/Skalarwerte; Feldmatrizen
  1575×12, 1575×6 und 1575×6. Keine temporären MAT-Dateien übrig.

In `src/generate_dataset.m` wurde die temporäre Datei auf
`tmp = string(file) + ".tmp.mat";` umgestellt. Der Code Analyzer meldete
keine Fehler/Warnungen, lediglich drei Hinweise. Weitere Codekorrekturen
waren für die ausgeführten MATLAB-Aufrufe nicht erforderlich.

| Feldmodell | Median relativer L2-Fehler | P95 / Maximum | Median POD-Projektionsfehler | Gewählter Rang |
|---|---:|---:|---:|---:|
| POD_GP | 60,6522 % | 2534,0135 % | 0,0497221 % | 2 |
| POD_RBF | 23,2579 % | 792,9969 % | 0,00107824 % | 11 |
| POD_MLP | 21,4584 % | 918,3498 % | 0,0149127 % | 4 |

Scalar_GPR: Spitzenverschiebungs-MAE **110,2806 µm**.
Beam_plus_GPR: Spitzenverschiebungs-MAE **0,506780 µm**.
Balkentheorie ohne Lernmodell: Spitzenverschiebungs-MAE **0,453300 µm**.
Skalar-MAE und relative Feldfehler sind unterschiedliche Kennzahlen.

Der Ablauf funktioniert; die Genauigkeitsziele sind nicht erreicht. Bei nur
sechs Testfällen ist das verwendete P95 hier identisch mit dem Maximum.
Die größten Feldfehler betreffen jeweils Fall-ID 23 mit nur etwa 7,455 µm
FEM-Spitzenverschiebung. Die niedrigen POD-Projektionsfehler sprechen dafür,
dass hauptsächlich die Regression/Datenabdeckung begrenzt, nicht die Basis.
Dies ist eine Einordnung der beobachteten Ergebnisse, kein Nachweis einer
einzelnen Ursache. Es wurde nicht anhand des Testsatzes nachtrainiert.

Vorhandene Manifeste und `mesh_check.csv` wurden per SHA-256 als unverändert
bestätigt. Zu Beginn gab es keine FEM-Fall-Dateien oder trainierten Modelle.
Die neu eingefrorene `models.mat` wurde nach dem Training nicht überschrieben.
Der Pilot-Lauf wurde nicht gestartet; `run_checks(true)` prüft lediglich auch
die bereits vorhandene Pilot-Designliste.

Details, Dateihashes und Plot: `verification/smoke_20261023_105533/`.
Messwerte: `runs/smoke/test_summary.csv`, `test_per_case.csv` und
`validation_selection.csv`.

## Historische Prüfungen der Erstellungsumgebung

- smoke: 24 distinct parameter rows, correct split counts, ranges and LHS strata.
- pilot: 160 distinct parameter rows, correct split counts, ranges and LHS strata.
- Independent NumPy weighted POD reference: relative reconstruction error 4.78e-16.
- Independent NumPy RBF reference: unseen-point affine reproduction error 1.56e-14.
- Static file checks: main function names match filenames; no control-character corruption; trainer never loads test.mat.

Diese unabhängigen Algebra- und Dateiprüfungen liefen in Python. Sie sind keine Ausführung oder Syntaxprüfung des MATLAB-Codes. MATLAB und Octave fehlen hier. FEM, Toolbox-Kompatibilität, GPR, MLP, Wiederaufnahme und Gesamtablauf müssen mit den enthaltenen MATLAB-Tests lokal geprüft werden. Es wurden keine FEM-Labels oder Benchmarkresultate erfunden.
