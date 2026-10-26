# Projektregeln für MATLAB FEM Matheseminar

## Projekt und Stack

Dieses Projekt ist ein MATLAB-Projekt für Finite-Elemente-Methoden, Modellreduktion und Surrogatmodelle. Der erkannte Stack umfasst MATLAB-Dateien unter `src/`, dem Paket `+femstudy/` und Tests unter `tests/`. Python-Skripte dienen ergänzend der Berichtserzeugung.

## Struktur

- `.agents/skills/`: automatisch erkennbare, projektspezifische Skills.
- `.codex/agents/`: ausführbare Custom-Agents als TOML sowie lesbare Rollenbeschreibungen.
- `.codex/prompts/`: wiederverwendbare Auftragsvorlagen.
- `docs/`: Architektur, Konventionen und ADRs.
- `scripts/`: gemeinsame Hilfsskripte.
- `src/`: zentrale MATLAB-Implementierung.
- `+femstudy/`: MATLAB-Paket für FEM-, Modell- und Berichtsfunktionen.
- `tests/`: MATLAB-Tests und Prüfskripte.
- `experiments/`, `runs/`, `verification/`: nachvollziehbare Versuchsdaten und Ergebnisse.

## Befehle

MATLAB aus dem Projektwurzelordner verwenden:

- Projektlauf: `run_project`
- Tests und Checks: `tests/run_checks`
- Einzelne Tests: `tests/test_migration_phase1`, `tests/test_beam_field_hybrid`
- TODO: Nach Bestätigung der MATLAB-Version und Toolboxen die verbindlichen CI-Befehle ergänzen.

Python-Berichte nur mit der im Projekt dokumentierten Umgebung ausführen. TODO: Abhängigkeiten und einen reproduzierbaren Python-Aufruf ergänzen.

## Arbeitsregeln

Änderungen auf den Auftrag begrenzen. Bestehende Dateien nicht überschreiben, wenn der Auftrag keine gezielte Änderung verlangt. Ergebnisse unter `runs/`, `experiments/` oder `verification/` mit Datum und reproduzierbarem Aufruf dokumentieren. Keine generierten großen Artefakte ohne Auftrag neu erzeugen.

Mathematische Behauptungen, numerische Evidenz und Beweise getrennt kennzeichnen. FEM-Randbedingungen, Einheiten, Diskretisierung und Solverannahmen explizit dokumentieren.

Skills beschreiben wiederverwendbare Abläufe; Agents übernehmen abgegrenzte Rollen; Prompts liefern konkrete Aufträge. Die Rollen- und Skill-Dateien sind keine zusätzliche Berechtigung.

## Git

Der angegebene Ordner enthält aktuell kein `.git`-Verzeichnis. Daher keine Commits, Branches oder Git-Befehle als verfügbar voraussetzen. TODO: Repository-Remote und Branch-Regeln nach Git-Initialisierung ergänzen.
