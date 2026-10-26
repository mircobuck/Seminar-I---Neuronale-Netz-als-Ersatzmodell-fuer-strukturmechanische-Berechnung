# Architekturüberblick

## Erkannter Ausgangsstand

Stand: 26.10.2026. Das Projekt ist ein MATLAB-FEM-Arbeitsstand mit `src/`, dem Paket `+femstudy/`, MATLAB-Prüfungen unter `tests/`, Versuchsdaten unter `experiments/` und Ergebnissen unter `runs/` sowie `verification/`. Ergänzende Python-Skripte erzeugen Berichte.

Im angegebenen Ordner und seinem direkten Elternordner wurde kein `.git`-Verzeichnis gefunden. Der Git-Status ist daher TODO und darf nicht vorausgesetzt werden.

## Bereiche

| Pfad | Zweck |
| --- | --- |
| `AGENTS.md` | Projektregeln, MATLAB-Kommandos und Grenzen |
| `.agents/skills/` | Automatisch erkennbare projektlokale Skills |
| `.codex/skills/` | Skill-Vorlagen und Dokumentation |
| `.codex/agents/` | TOML-Custom-Agents und lesbare Rollenbeschreibungen |
| `.codex/prompts/` | Wiederverwendbare Auftragsvorlagen |
| `docs/` | Architektur, Konventionen und Entscheidungsdokumentation |
| `scripts/` | Künftige gemeinsam verwendete Hilfsskripte |

Die projektweiten Regeln stehen in `AGENTS.md`; Hinweise zur Codex-Einbindung stehen in den jeweiligen READMEs.

## Geplante Erweiterungen

TODO: FEM-Teilproblem, mathematische Zielgrößen und erwartete Seminarergebnisse ergänzen.

TODO: Verbindliche MATLAB-Version und benötigte Toolboxes dokumentieren.

TODO: Den Ablauf von Eingabedaten über Solver und Modellreduktion bis zu den Verifikationsartefakten ergänzen.

TODO: Relevante Architekturentscheidungen unter [decisions/](decisions/) mit der dortigen Vorlage festhalten.
