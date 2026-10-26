# Smoke-Prüfung vom 23.10.2026

Projekt: `C:\Users\dietz\Downloads\MATLAB_FEM_Start\MATLAB_FEM_Start`

MATLAB: 25.2.0.3042426 (R2025b) Update 1. Ausführung über MATLAB MCP.

## Änderung und Prüfung

`src/generate_dataset.m`, Zeile 28:

```matlab
tmp = string(file) + ".tmp.mat";
```

Die vorherige Array-Verkettung wurde durch skalare String-Verkettung ersetzt.
Damit wird auch bei einem String-Dateipfad ein einzelner Dateiname gebildet.
Der Code Analyzer lieferte null Fehler/Warnungen und drei Informationshinweise
(überflüssige frühere Unterdrückung sowie zwei Hinweise zur Vorallokation).

## Tatsächlich ausgeführte Aufrufe

| Aufruf | Ergebnis |
|---|---|
| `addpath('src','tests')` | Projektfunktionen aus dem richtigen Unterordner aufgelöst |
| `run_checks(true)` | Alle Assertions bestanden; drei FEM-Skalierungsfälle |
| `run_project("smoke","generate")` | 24 FEM-Fälle neu erzeugt und gespeichert |
| `run_project("smoke","train")` | Fünf Modelle neu trainiert und eingefroren |
| `run_project("smoke","evaluate")` | Sechs Testfälle ausgewertet |
| `plot_test_case("smoke","POD_GP",1)` | Drei Vergleichspanels erzeugt |

Der Plotaufruf wurde für einen größeren PNG-Export wiederholt und der finale
Export visuell geprüft. Nach dem Training erfolgte kein zweites Training.
Die zusätzlich geprüften Datenmatrizen sind vollständig endlich und haben
die Größen 1575×12 (Training), 1575×6 (Validierung), 1575×6 (Test).
`run_checks(true)` prüft außerdem POD-Rekonstruktion, gewichtete Orthogonalität,
affine RBF-Reproduktion sowie IDs und Splitgrößen beider Parameterdesigns.
Ein `matlab.unittest`-Testlauf wurde nicht ausgeführt; `run_checks` ist eine
eigene Funktion mit Assertions. `mesh_check` wurde in dieser Prüfung nicht
erneut ausgeführt. Es trat kein MATLAB-Laufzeitfehler auf.

## Gemessene Modellfehler

Feldfehler sind gewichtete relative L2-Fehler, hier als Prozent angegeben.
Die CSV-Dateien speichern sie als dimensionslose Verhältnisse.

| Feldmodell | Median | P95 | Maximum | Median POD-Projektionsfehler | Rang |
|---|---:|---:|---:|---:|---:|
| POD_GP | 60,6522 % | 2534,0135 % | 2534,0135 % | 0,0497221 % | 2 |
| POD_RBF | 23,2579 % | 792,9969 % | 792,9969 % | 0,00107824 % | 11 |
| POD_MLP | 21,4584 % | 918,3498 % | 918,3498 % | 0,0149127 % | 4 |

| Skalarmodell / Referenz | MAE der Spitzenverschiebung |
|---|---:|
| Scalar_GPR | 110,2806 µm |
| Beam_plus_GPR | 0,506780 µm |
| Balkentheorie | 0,453300 µm |

Diese Kennzahlen dürfen nicht als eine gemeinsame Rangliste verglichen werden.
Mit sechs Testfällen entspricht P95 hier dem Maximum. Die größten relativen
Feldfehler liegen bei Fall-ID 23. Dessen FEM-Spitzenverschiebung ist
−7,4546e−6 m; im Training liegen die Beträge zwischen 1,002815e−5 m und
4,1782284e−4 m. Ein kleiner Bezugswert kann hohe relative Fehler verstärken.
Die geringen POD-Projektionsfehler bei hohen Vorhersagefehlern sprechen für
eine Begrenzung durch Regression/Datenabdeckung; eine einzelne Ursache wurde
nicht nachgewiesen. Keine Anpassung an den Testdaten vorgenommen.

Der Smoke-Lauf prüft den Ablauf erfolgreich. Die im README genannten
Genauigkeitsziele (Median unter 1 %, P95 unter 3 %) sind nicht erreicht.
Die Balkenkorrektur verbessert in diesem Smoke-Test die reine Balkentheorie
nicht. Es wurden keine Modelle nachträglich optimiert oder überschrieben.

## Erhaltene Daten und Grenzen

Vor dem Lauf waren lediglich `runs/smoke/manifest.mat`,
`runs/smoke/mesh_check.csv` und `runs/pilot/manifest.mat` vorhanden.
Alle drei Dateien sind per SHA-256 unverändert. FEM-Fall-Dateien und
trainierte Modelle existierten vorher nicht. Neu entstanden 24 Fall-Dateien,
die drei Split-Dateien, `models.mat` und die Auswertungsergebnisse.
Keine temporären MAT-Dateien blieben übrig.

SHA-256 der eingefrorenen `runs/smoke/models.mat`:
`48791A7AC455E39FE57206174382F778B334ECD72323B814770028A08E4C528B`

Dieser Hash blieb während Auswertung und Diagnose unverändert.
Der Pilot-Lauf wurde nicht gestartet; dessen Ordner enthält weiterhin nur
das ursprüngliche Manifest. Die Designprüfung des Piloten in `run_checks`
berechnet oder trainiert keinen Pilot-Fall.

## Nachweise

- `existing_files.json`: vorab erfasste Dateihashes.
- `final_files.json`: finale Dateihashes aller Run-Dateien.
- `matlab_execution.log`: ausgewählte Textausgaben aus den MCP-Antworten.
- `POD_GP_test_case_1.png`: visuell geprüfter Vergleich für Testindex 1 / ID 19.
- `../../runs/smoke/test_summary.csv`: vollständige Kennzahlen und Laufzeiten.
- `../../runs/smoke/test_per_case.csv`: Fehler für jeden Testfall.
- `../../runs/smoke/validation_selection.csv`: Modellauswahl nur auf Validierung.
