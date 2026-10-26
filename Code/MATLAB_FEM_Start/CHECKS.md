# Prüfstatus

## POD-Galerkin, 23.10.2026

Alle sechs Größen 12/24/48/96/192/384 implementiert und tatsächlich ausgewertet.
Mechanikprüfungen bestanden: Randbedingungen/DOFs, Material-/Lastskalierung,
Symmetrie/SPD, Voll-FEM/nullspace-Abgleich, quadratische Interpolation und
Reproduktion einer in der Basis enthaltenen Referenzlösung. Zusätzliche
Prüfungen zu Splits, identischem Ausgaberaster, Projektionsfehlern und Erhalt
aller vorherigen Run-Dateien erfolgreich. Keine matlab.unittest-Suite gestartet.
[Details und verbleibende Einschränkungen](experiments/pod_galerkin_20261023_v1/REPORT.md).

384er-Erweiterung vom 23.10.2026 erfolgreich erzeugt, trainiert und ausgewertet;
Verschachtelung und Dateierhalt geprüft. POD_GP erfüllt die beiden Fehlerziele
auf den sechs festen Testfällen. [Aktueller Bericht](experiments/training_size_12_24_48_20261023/RESULTS_384.md).

192er-Erweiterung vom 23.10.2026 ebenfalls erfolgreich erzeugt, trainiert und
ausgewertet. Verschachtelung und Dateierhalt bestätigt; MLP-Ausreißer erneut
stark erhöht. Details im [aktuellen Versuchsbericht](experiments/training_size_12_24_48_20261023/RESULTS_192.md).

## Ergänzung: Trainingsmengenreihe vom 23.10.2026

12/24/48/96 Trainingsfälle mit identischen sechs Validierungs- und sechs
Testfällen wurden tatsächlich verglichen. Die neun neuen Generate-/Train-/
Evaluate-Stufen waren erfolgreich. Verschachtelung und Erhalt vorhandener
Dateien wurden geprüft. Details und Einschränkungen: [Versuchsverlauf](EXPERIMENTS.md)
und [Gesamtergebnisse](experiments/training_size_12_24_48_20261023/RESULTS.md).

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


## DeepONet-Vergleich: Abschluss 25.10.2026

Tatsaechlich ueber MATLAB MCP ausgefuehrt:

- Audit aller sechs verschachtelten Splits, 396 eindeutige Parameterzeilen,
  Einheiten/Parameterreihenfolge, identische Holdouts, Quadratur und Gitter.
- Sieben matlab.unittest-Pruefungen: Tensor/Komponenten, exakte Einspannung,
  Einzel-/Batchgleichheit, Punktpermutation, endliche Gradienten,
  Zweifall-Ueberanpassung und Wiederherstellung des besten Checkpoint-Netzes.
- Nach kleinen Analyzer-Bereinigungen alle sieben Tests nochmals bestanden.
- Zehn neue MATLAB-Dateien statisch geprueft: final keine Analyzer-Meldungen.
- Alle 30 DeepONet-Testfelder endlich; train-only Skalierung pro Modell exakt
  reproduziert; Spitzen- und Gittermaximaldefinition gegen Referenzfelder geprueft.
- Alle sieben Baselines je N neu ausgewertet und online mit Warmup plus fuenf
  Wiederholungen gemessen. ROM-Feldpfad reproduziert die vorher geprueften Felder.
- Direkte/gecachte Gradienten: am N=384-Benchmark exakt gleicher Verlust und
  exakt gleiche Gradienten; gemessener Gradientenaufruf ca. 0,064 vs. 0,016 s.
- Vorhandene FEM-/ROM-Mechanikpruefungen referenziert, nicht neu ausgefuehrt.
- PDF gerendert; Seitenraender, Tabellen und Diagramme visuell kontrolliert.

Nachweise: experiments/deeponet_20261023_v1/unit_test_results.csv,
code_analyzer_final.json, final_data_audit.txt, pdf_layout_checks.json und
preservation_check.json. Gesamtergebnis im dortigen REPORT.md.
Historische Aussagen weiter oben bleiben als damaliger Stand erhalten.
