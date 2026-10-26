---
name: matlab-fem-workflow
description: Verwenden, wenn MATLAB-FEM-Code, Modellreduktion, Surrogatmodelle oder zugehörige Tests und Verifikationsläufe in diesem Projekt geändert, analysiert oder geprüft werden.
---

# MATLAB-FEM-Arbeitsablauf

## Vorgehen

1. `AGENTS.md`, `README.md` sowie die betroffenen Dateien unter `src/`, `+femstudy/` und `tests/` lesen.
2. Eingaben, Randbedingungen, Einheiten, Diskretisierung und erwartete Ausgaben vor Änderungen festhalten.
3. Die kleinste passende Änderung im beauftragten Bereich umsetzen.
4. Bestehende Prüfungen unter `tests/` ausführen; bei Experimenten den Aufruf und die Artefakte unter `experiments/`, `runs/` oder `verification/` dokumentieren.
5. Ergebnisse, nicht ausgeführte Prüfungen und offene Annahmen getrennt berichten.

## MATLAB-Hinweise

MATLAB-Paketfunktionen unter `+femstudy/` über ihre qualifizierten Namen verwenden. Keine Pfadänderungen dauerhaft in MATLAB-Startdateien eintragen. Numerische Stichproben sind Evidenz, aber kein mathematischer Beweis.

## Grenzen

Keine Dateien außerhalb des Auftrags ändern. Keine generierten Ergebnisdateien als Quelldateien behandeln. Keine Toolbox oder MATLAB-Version als vorhanden annehmen, wenn sie nicht geprüft wurde.

## Ausgabe

Geänderte Dateien, fachliche Annahmen, ausgeführte Prüfungen mit tatsächlichem Ergebnis und verbleibende `TODO:`-Punkte nennen.
