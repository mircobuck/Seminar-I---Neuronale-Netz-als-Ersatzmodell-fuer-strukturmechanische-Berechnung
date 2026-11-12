# Statischer FEM-Surrogatvergleich

Vier Methoden sagen aus sechs Balkenparametern das vollstaendige statische Verschiebungsfeld voraus: direktes MLP, vorhandenes RBF-Netz, POD-MLP und POD-GPR. Ausgabe: 1575 Verschiebungen in Metern auf 525 Punkten. Eigenfrequenzen gehoeren nicht zum aktiven Ablauf.

## Abgeschlossene Wiederholung

Die Hauptwiederholung vom 12.11.2026 ist abgeschlossen: 234 erfolgreiche Fits, 288 Auswertungen, identische Modellwahl und reproduzierte Fallkennzahlen. [Ergebnisse und neue Zeiten](experiments/static_comparison_refactor_20261112_attempt4/WIEDERHOLUNG.md), [Laufbedingungen](experiments/static_comparison_refactor_20261112_attempt4/LAUFBEDINGUNGEN.md), [Arbeitsstand](docs/ARBEITSSTAND_20261112.md). Grosse Modell- und MAT-Dateien bleiben lokal.

## Voraussetzungen und sicherer Start

MATLAB R2025b, Deep Learning Toolbox, Statistics and Machine Learning Toolbox, Partial Differential Equation Toolbox und Java. Fuer Diagramme: Python 3 mit Matplotlib. In MATLAB Code v2 als Ordner oeffnen oder einmal auf den Pfad setzen:

```matlab
runStaticStudy   % zeigt nur Hilfe, startet keine Berechnung
```

`main` zeigt ohne Argument einen Hinweis auf den historischen gemischten Ablauf. Seine ausdruecklichen alten Modi bleiben verfuegbar.

## Konfiguration und Phasen

Wissenschaftliche Einstellungen: `workflows/static_comparison/configs/study.json`. Suchkandidaten und ihre Reihenfolge, Seeds, Trainingsgroessen, POD-Raenge, Referenzanzahlen und Messwiederholungen sind versioniert. Die Falllisten in `training_blocks.csv` ordnen die beiden Trainingsbloecke ausdruecklich zu.

Lokale Pfade: `workflows/static_comparison/configs/local.example.json`. Fuer einen weiteren Lauf diese kleine JSON in eine eigene lokale Datei kopieren und `output_dir` auf einen neuen Ordner setzen. `training_file`, `reference_run`, `training_blocks` und `python` sind dort anpassbar. Alle relativen Dateipfade beziehen sich auf Code v2, auch bei einem anderen aktuellen MATLAB-Ordner. `python` ist ein ausfuehrbarer Interpretername oder absoluter Interpreterpfad.

```matlab
cfg = "workflows/static_comparison/configs/study.json";
local = "workflows/static_comparison/configs/local.example.json";
runStaticStudy("init", cfg, local)
runStaticStudy("generate", cfg, local)
runStaticStudy("tune", cfg, local)
runStaticStudy("train", cfg, local)
runStaticStudy("freeze", cfg, local)
runStaticStudy("evaluate", cfg, local)
runStaticStudy("benchmark", cfg, local)
runStaticStudy("report", cfg, local)
```

`generate` prueft im Standardmodus die wiederverwendeten Referenzen. Die alten MAT-Dateien bleiben am bisherigen Ort. Mit `reference_mode="generate"` erzeugt der Ablauf eigene statische Validierungs-/Testreferenzen; der Trainingspool wird separat bereitgestellt. Der Smoke-Test prueft diese FEM-Erzeugung.

Die Wiederholung verwendet bereits bekannte Referenzfaelle und ist **kein neuer unabhaengiger Abschlusstest**. Auswahl erfolgt ausschliesslich auf Validierung. Testlabels sind im oeffentlichen Ablauf bis zum Freeze gesperrt. Ein Freeze ist eine Ablaufkontrolle, keine Dateisystem-Zugriffssperre.

Phasen sind wiederaufnehmbar; gleiche Konfiguration und gleicher Quellstand sind erforderlich. Abgeschlossene Fit-Checkpoints werden verifiziert und wiederverwendet. Code oder Inputaenderungen erfordern einen neuen Ausgabeordner. Training nach Freeze wird abgelehnt. Keine zweite aktive Projektkopie, keine dauerhafte MATLAB-Pfadaenderung.

## Vorhandene Ergebnisse darstellen

`report` liest gespeicherte Auswertungen und erzeugt Tabellen und Diagramme ohne FEM, Training oder neue Modellwahl. Fuer eine schlanke Darstellung beliebiger vorhandener Tabellen:

```matlab
oldPath = path;
cleanup = onCleanup(@() path(oldPath));
addpath("examples")
showStaticResultsExample("experiments/static_comparison_refactor_20261112_attempt4")
```

`examples/trainStaticModelExample.m` zeigt Training und Validierung eines einzelnen Modells mit expliziten Dateipfaden. Andere Beispiele sind historische Versuche und nicht Teil des aktiven Pfads.

## Tests

```matlab
r = runtests("tests/staticWorkflowTest.m"); assertSuccess(r)
r = runtests("tests/surrogateContractTest.m"); assertSuccess(r)
r = runtests("tests/podGprTest.m"); assertSuccess(r)
addpath("tests")
runStaticWorkflowSmoke("workflows/static_comparison/configs/smoke.json", ...
    "workflows/static_comparison/configs/smoke.local.json")
```

Der Smoke-Test braucht einen neuen Ausgabeordner und prueft alle vier Methoden, FEM, Wiederaufnahme, Freeze, Auswertung und Bericht. Der gespeicherte Vorhersagevergleich benoetigt die lokalen Baseline-Artefakte unter `experiments/refactor_validation_20261112`.

## Ablage

| Pfad | Aufgabe |
|---|---|
| `+surrogate` | Modelle, gemeinsame Schnittstelle, POD, Fallfehler und gemeinsame Aggregation |
| `fem_core` | Physikalische FEM-Referenzberechnung |
| `workflows/static_comparison` | Aktuelle Konfiguration und klar benannte Studienfunktionen im Paket `staticstudy` |
| `data_generation` | Bestehende Referenzdaten und historische Erzeugungskonfigurationen |
| `experiments` | Artefakte konkreter Laeufe; grosse MAT-Dateien neuer Laeufe bleiben lokal |
| `tests` | Vertrags-, Modell-, numerische Regressions- und Ablaufpruefungen |
| `docs` | Schnittstellen, Migration, Studienprotokoll und Nachweise |
| `studies` | Historische Einzelstudien, nicht auf dem aktiven Pfad |

Details: [Schnittstellen](docs/SCHNITTSTELLEN.md), [Migration](docs/UMSTRUKTURIERUNG.md), [Studienprotokoll](docs/STATISCHE_STUDIE.md). Alte Bedienhinweise stehen unveraendert in [README_HISTORISCH](docs/README_HISTORISCH.md); sie beschreiben fruehere Einstiege.
