# Projekt-Skills

Skills beschreiben wiederholbare Arbeitsabläufe. Die Rollen in [../agents/README.md](../agents/README.md) bestimmen die Zuständigkeit; ein Skill beschreibt das Vorgehen für eine konkrete Aufgabe.

## Aufbau und Benennung

Ein fertiger Skill liegt unter `skill-name/SKILL.md`. Verwende englische Namen in kebab-case mit höchstens 64 Zeichen. Jede `SKILL.md` beginnt mit YAML-Frontmatter mit den Zeichenketten `name` und `description`. Die Beschreibung nennt ausdrücklich, wann der Skill anzuwenden ist.

Die angeforderte Vorlage [_template/SKILL.md](_template/SKILL.md) ist ein Gerüst. Kopiere sie in einen benannten Ordner, passe den Namen an den Ordner an und ersetze die mit `TODO:` markierten Stellen. Die Sondernamen `_template`, `SKILL.md` und `README.md` entsprechen der gewünschten Struktur.

Ergänze `references/`, `assets/` oder `scripts/` nur, wenn der Ablauf sie benötigt. Gemeinsame Hilfen liegen unter [../../scripts/](../../scripts/).

## Nutzung in Codex

Dieser Ordner ist der vom Nutzer gewählte Vorlagenbestand. Codex dokumentiert für die automatische Erkennung projektlokaler Skills `.agents/skills/`. Eine Ablage unter `.codex/skills/` garantiert keine automatische Erkennung. Bis zur Einrichtung einen konkreten Skill im Auftrag mit Dateipfad nennen und lesen lassen.

TODO: Fertige Skills bei Bedarf nach `.agents/skills/` übernehmen oder dort gezielt verknüpfen; das unfertige Vorlagengerüst nicht als produktiven Skill aktivieren.

Quelle: [Offizielle Dokumentation zu Skills](https://learn.chatgpt.com/docs/build-skills).
