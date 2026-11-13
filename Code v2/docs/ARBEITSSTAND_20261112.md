# Arbeitsstand: abgeschlossen am 13.11.2026

Code v2 enthaelt nur noch den aktuellen statischen Vier-Methoden-Ablauf, zwei Beispiele und seine relevanten Tests. Historische Programme und Quellkopien sind aus dem Arbeitsstand entfernt und im lokalen Commit 4e83631 gesichert. Alle 7.312 geschuetzten Daten-/Ergebnisdateien blieben byteidentisch erhalten.

## Nachweise

- 71/71 aktuelle Unit-Tests und vollstaendiger FEM-Smoke in frischem MATLAB-Prozess bestanden, einschliesslich gespeicherter Vorhersagen, Wiederaufnahme, Freeze und Report-only.
- Vollstaendige neue Hauptstudie: experiments/static_comparison_cleanup_20261113_attempt2, Quellcommit 5ba4840, Funktionscode seit d2357ff unveraendert.
- 234 erfolgreiche Fits, 288 Auswertungen, 55.296 Fallzeilen; alle verglichenen numerischen Kennzahlen exakt wie in der unmittelbar vorherigen Wiederholung.
- 85 Quell-/Inputeintraege, 889 Freeze-Eintraege und alle Siegel geprueft. Neue Zeiten und Benchmark, acht nachgerechnete Break-even-Szenarien, zehn Diagramme.
- Erfolgreiche Studienphasen: 1 h 57 min 24 s, ohne protokollierten Standby; MATLAB-Batch und temporaerer Helfer beendet.
- Aktueller Codeumfang: 2.184 Funktionszeilen plus 83 Zeilen Zaehlwerkzeug; Tests separat 705 Zeilen. Gesamt 2.972 statt vorher 17.544 Zeilen mit historischen Programmen und Quellkopien.

Details: [Bereinigungsnachweis](STATISCHE_BEREINIGUNG.md), [Codezaehlung](CODEZAEHLUNG.md), [Ergebnisse und neue Zeiten](../experiments/static_comparison_cleanup_20261113_attempt2/WIEDERHOLUNG.md), [Laufbedingungen](../experiments/static_comparison_cleanup_20261113_attempt2/LAUFBEDINGUNGEN.md).

Die unterbrochenen Versuche bleiben getrennt erhalten; ihre Zeiten wurden nicht als neue erfolgreiche Messungen verwendet. Ursache und zusaetzlich freigegebene Cache-Bereinigung: CLEANUP_INTERRUPTION_20261112.md. Historische Ergebnisse und Manifeste wurden nicht umgeschrieben. Keine offenen beauftragten Arbeiten, keine Remote-Pushes.
