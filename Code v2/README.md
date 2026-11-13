# Statischer FEM-Surrogatvergleich

Vier Methoden sagen aus sechs Balkenparametern das vollstaendige statische Verschiebungsfeld voraus: direktes MLP, vorhandenes RBF-Netz, POD-MLP und POD-GPR. Ausgabe: 1575 Verschiebungen in Metern auf 525 Punkten. Eigenfrequenzen gehoeren nicht zum aktiven Ablauf.

## Bereinigter aktueller Bestand

Aktiv bleiben nur der statische Vier-Methoden-Ablauf und seine Tests. Historische Programme, modale Berechnung, alte Optimierer und Quellkopien sind aus dem Arbeitsstand entfernt und im lokalen Git-Commit `4e83631` gesichert. Wissenschaftliche Daten und Ergebnisse bleiben unveraendert. [Bereinigungsnachweis](docs/STATISCHE_BEREINIGUNG.md), [Codeumfang](docs/CODEZAEHLUNG.md), [Arbeitsstand](docs/ARBEITSSTAND_20261112.md). Die vollstaendige neue Hauptstudie ist abgeschlossen: 234 erfolgreiche Fits, 288 Auswertungen, 55.296 Fallzeilen und identische numerische Kennzahlen gegenueber der unmittelbar vorherigen Wiederholung. [Ergebnisse und neue Zeiten](experiments/static_comparison_cleanup_20261113_attempt2/WIEDERHOLUNG.md), [Laufbedingungen](experiments/static_comparison_cleanup_20261113_attempt2/LAUFBEDINGUNGEN.md).

## Voraussetzungen und sicherer Start

MATLAB R2025b, Deep Learning Toolbox, Statistics and Machine Learning Toolbox, Partial Differential Equation Toolbox und Java. Fuer Diagramme: Python 3 mit Matplotlib. In MATLAB Code v2 als Ordner oeffnen oder einmal auf den Pfad setzen:

```matlab
runStaticStudy   % zeigt nur Hilfe, startet keine Berechnung
```

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
showStaticResultsExample("experiments/static_comparison_cleanup_20261113_attempt2")
```

`examples/trainStaticModelExample.m` zeigt Training und Validierung eines einzelnen Modells mit expliziten Dateipfaden. Dies sind die einzigen beiden verbleibenden Anwendungsbeispiele.

## Tests

```matlab
addpath("tests")
runStaticValidation("experiments/static_cleanup_validation_neu", ...
    "workflows/static_comparison/configs/smoke.local.json")
```

Vor Wiederholung in `smoke.local.json` einen noch nicht vorhandenen Ausgabeordner einstellen. Der Treiber beginnt mit einem ausschliesslich aus der MATLAB-Installation stammenden Pfad, aktiviert nur aktuelle Projektteile, prueft dynamische Abhaengigkeiten, alle aktuellen Unit-Tests und den vollstaendigen FEM-Smoke. Er protokolliert aufgeloeste und tatsaechlich geladene Projektfunktionen. Keine dauerhafte Pfadaenderung.

Der Smoke prueft alle vier Methoden, FEM, Wiederaufnahme, Freeze-Sperren, Auswertung und wiederholte Berichte. Die numerische Regression verwendet vorhandene Modelle/Daten des konfigurierten `reference_run` sowie `experiments/refactor_validation_20261112/baseline_predictions.mat`. Suchkandidaten und Trainingsauswahlen sind in `tests/fixtures/study_baseline.mat` gesichert; historische Programme werden nicht geladen. Die Tests verwenden `matlab.unittest`; die separate MATLAB Test Toolbox ist nicht erforderlich.

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
| `studies`, `Netzarchitekturen`, `Testverfahren` | Erhaltene historische Nicht-Code-Artefakte; keine Studienprogramme |

Details: [Schnittstellen](docs/SCHNITTSTELLEN.md), [Migration](docs/UMSTRUKTURIERUNG.md), [Studienprotokoll](docs/STATISCHE_STUDIE.md). Alte Bedienhinweise stehen unveraendert in [README_HISTORISCH](docs/README_HISTORISCH.md); sie beschreiben fruehere Einstiege.

## Historische Programme aus Git wiederherstellen

`4e83631` sichert den vollstaendigen Programmstand vor dieser Bereinigung. Dateinamen und Hashes stehen in `docs/CLEANUP_SOURCE_BASELINE.csv`; jede Entscheidung in `docs/CLEANUP_FILE_PLAN.csv`. Historische Manifeste bleiben unveraendert und beziehen sich auf ihre damaligen Quellen, nicht auf den bereinigten Bestand.

Vom Repository-Wurzelordner zeigt beispielsweise `git show "4e83631:Code v2/main.m"` den alten Einstieg. Fuer eine bewusst gewuenschte historische Reproduktion kann `git restore --source=4e83631 -- "Code v2/<Dateipfad>"` einzelne Quellen wiederherstellen. Danach ist der Arbeitsstand nicht mehr der bereinigte Studienstand. Keine zweite aktive Kopie wird fuer den aktuellen Ablauf benoetigt.

Die lokale Datenkonfiguration verweist ausdruecklich auf `data_generation/data/static/train.mat`, die zugehoerige `design.csv`, `configs/training_blocks.csv` und die bekannten FEM-Referenzen in `experiments/static_gpr_main_v1_20261111_run2`. Aus diesem historischen Ordner werden Daten, Pruefsummen und Kostenmetadaten gelesen, keine Programme. Modelle der numerischen Regression stammen ebenfalls von dort. Grosse MAT-Dateien bleiben lokal; Git allein ersetzt deren Datensicherung nicht.
