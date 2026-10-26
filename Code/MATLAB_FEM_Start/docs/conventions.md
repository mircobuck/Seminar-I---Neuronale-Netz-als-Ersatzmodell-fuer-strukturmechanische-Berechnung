# Konventionen

## Sprache und Dateinamen

Dokumentation und Vorlagen werden auf Deutsch geschrieben und in UTF-8 gespeichert. Neue Datei- und Ordnernamen sind englisch in kebab-case. Die ausdrücklich vorgegebenen Namen `AGENTS.md`, `SKILL.md`, `README.md`, `_template/` und `_template.md` sind Ausnahmen. Bestehende Referenzen nicht umbenennen.

MATLAB-Funktionen verwenden `camelCase` wie im bestehenden Code; Paketfunktionen bleiben unter `+femstudy/+...`. Python-Skripte folgen PEP 8, soweit keine bestehende Schnittstelle entgegensteht. Neue Tests gehören unter `tests/`.

## Referenzen und Mathematik

Generierte Ergebnisse unter `runs/`, `experiments/` oder `verification/` ablegen; Quelldateien und reproduzierbare Definitionen davon getrennt halten.

Definitionen und Voraussetzungen vor ihrer Verwendung benennen. Symbole konsistent verwenden. Beweise, Beispiele, Vermutungen und numerische Experimente erkennbar unterscheiden. Quellen mit Titel und relevanter Seite, Satznummer oder Abschnitt angeben; keine bibliografischen Details erfinden.

TODO: Einheitliche mathematische Notation, Einheiten und Zitierweise festlegen.

## Befehle und Prüfungen

Der erkannte Stack ist MATLAB mit ergänzenden Python-Berichtsskripten. Verbindliche Toolboxen und die MATLAB-Version sind noch zu bestätigen.

| Zweck | Projektbefehl | Stand |
| --- | --- | --- |
| Projektlauf | `run_project` | Vorhanden, MATLAB erforderlich |
| Tests und Checks | `tests/run_checks` | Vorhanden, Ergebnis je Lauf dokumentieren |
| Einzeltests | `tests/test_migration_phase1`, `tests/test_beam_field_hybrid` | Vorhanden |
| Python-Bericht | TODO: Umgebung und Abhängigkeiten dokumentieren | Nicht abschließend eingerichtet |

Bis dahin Änderungen auf nachvollziehbare Belege, gültige lokale Markdown-Links und konsistente Notation prüfen. Bei fertig erzeugten Dokumenten auch den gerenderten Stand prüfen. Fehlende Voraussetzungen und nicht ausgeführte Prüfungen offen nennen.

## Änderungen und Commits

Änderungen auf die beauftragte Aufgabe begrenzen. Bei diesem Setup werden vorhandene Dateien übersprungen, statt sie zu überschreiben.

Im angegebenen Ordner wurde kein Git-Repository gefunden. Bis zur Initialisierung oder Korrektur des Pfads keine Git-Befehle voraussetzen. Danach kleine thematisch zusammenhängende Commits mit `type: kurze Beschreibung` verwenden, etwa `docs: Projektstruktur ergänzen`.

TODO: Git-Nutzung, Branch-Regeln und gegebenenfalls erforderliche Prüfungen festlegen.
