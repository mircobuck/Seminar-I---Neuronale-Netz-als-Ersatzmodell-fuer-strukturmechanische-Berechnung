# Agent-Rollen

Die Dateien in diesem Ordner sind lesbare Rollenbeschreibungen für konkrete Aufträge.

| Rolle | Zuständigkeit | Ergebnis |
| --- | --- | --- |
| [planner](planner.md) | Aufgabe, Abhängigkeiten und Prüfkriterien klären | Umsetzbarer Plan |
| [implementer](implementer.md) | Beauftragte Änderungen umsetzen | Geänderte Artefakte und Prüfnachweis |
| [reviewer](reviewer.md) | Fehler und Qualitätsrisiken beurteilen | Belegte Befunde |
| [tester](tester.md) | Passende Prüfungen schreiben und ausführen | Prüfbericht mit tatsächlichen Ergebnissen |

Neue Rollen aus [_template.md](_template.md) ableiten und mit englischem Namen in kebab-case speichern. Jede Rolle nennt Rolle, Ziel, Zuständigkeit, Eingaben, Werkzeuge, erwartetes Output-Format und Grenzen.

## Zusammenspiel

Für kleine Aufgaben genügt eine passende Rolle. Bei umfangreicheren Aufgaben kann zunächst geplant, dann umgesetzt und anschließend geprüft werden. Ein passender [Skill](../skills/README.md) liefert dafür das fachliche Vorgehen; [Prompt-Vorlagen](../prompts/README.md) liefern den konkreten Auftrag.

Die Markdown-Dateien starten keine Agents und gewähren keine zusätzlichen Rechte. Eine Rolle im Auftrag mit Dateipfad nennen und lesen lassen. Die bloße Existenz dieser Dateien beauftragt keine parallele Delegation.

Codex dokumentiert native benutzerdefinierte Agents als TOML-Dateien unter `.codex/agents/`. Die hier ausdrücklich gewünschte Markdown-Struktur ist daher eine Sammlung von Rollenbeschreibungen und keine aktive Laufzeitkonfiguration.

TODO: Falls native Agent-Konfiguration gewünscht ist, Rollen gezielt in das aktuell unterstützte Format übertragen.

Quelle: [Offizielle Dokumentation zu Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents).
