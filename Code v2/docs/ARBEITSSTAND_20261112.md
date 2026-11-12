# Arbeitsstand: abgeschlossen am 12.11.2026

Die Umstrukturierung und die vollstaendige Hauptwiederholung sind abgeschlossen. Aktiver Projektordner bleibt Code v2; keine zweite aktive Projektkopie.

## Struktur und Pruefungen

runStaticStudy und setupProject bieten die expliziten Phasen im Paket staticstudy unter workflows/static_comparison. Fachkonfiguration und lokale Pfade sind getrennt. Modell- und FEM-Schnittstellen bleiben erhalten; historische Programme sind gekennzeichnet und ausserhalb des aktiven Pfads. README, Migration, Studienprotokoll und Codezaehlung dokumentieren die Bedienung.

83 bestehende Tests, 16 neue Regressionstests und nach additiver Zeitinstrumentierung 55 betroffene Tests bestanden. Der vollstaendige Smoke-Test static_comparison_smoke_20261112_attempt2 umfasst FEM, alle vier Methoden, 24 Fits, 40 Auswertungen, Wiederaufnahme, Freeze-Sperren und wiederholte Berichtserstellung. Vor Wiederaufnahme stimmten alle 72 Quellmanifestdateien exakt; die 6 gespeicherten Pruefartefakte sind weiterhin byteidentisch. Ohne fachliche Codeaenderung erfolgte keine vollstaendige Testwiederholung.

## Abgeschlossene Hauptwiederholung

Lauf: `experiments/static_comparison_refactor_20261112_attempt4`.

- Ein serieller protokollierter MATLAB-Batch, Quellcommit bei Initialisierung b2c9e23.
- Alle 76 Suchkandidaten plus 12 Bestaetigungsfits; identische vier Siegerkonfigurationen wie zuvor.
- 234 erfolgreiche Fits insgesamt, 144 ausgewertete Modelle, 288 Lauf/Split-Zeilen und 55.296 Fallzeilen.
- Alle verglichenen Fallkennzahlen exakt reproduziert. 13 Mittelwerte weichen wegen Summationsreihenfolge um maximal 9.992e-16 ab; keine Auswahl wurde angepasst.
- 90 Quellmanifest- und 894 Freeze-Eintraege sowie alle Checkpoint-Siegel erfolgreich nachgeprueft.
- Neue Fit-, Segment-, Such-, Lade-/Speicher- und Vorhersagezeiten; neuer 12-Fall-FEM-/Surrogatbenchmark, bedingter Break-even und 10 Diagramme vorhanden.
- Studienphasen 15:56:41 bis 17:44:00 Europe/Berlin, 1 h 47 min 19 s. Kein protokollierter Standby. Eigener MATLAB-Prozess und temporaerer Standby-Helfer sind beendet.

Bericht: [WIEDERHOLUNG.md](../experiments/static_comparison_refactor_20261112_attempt4/WIEDERHOLUNG.md). Laufbedingungen: [LAUFBEDINGUNGEN.md](../experiments/static_comparison_refactor_20261112_attempt4/LAUFBEDINGUNGEN.md). Maschinenlesbare Pruefung: verification.json und numerical_comparison.csv im Laufordner.

Die Referenzfaelle waren bekannt. Dies ist eine Reproduktionspruefung des Strukturumbaus, kein neuer unabhaengiger Abschlusstest. Historische Datenerzeugungskosten bleiben ausdruecklich historische Angaben. Laufzeitunterschiede zwischen Sitzungen sind kein isolierter kausaler Geschwindigkeitsnachweis.

## Bereinigung und erhaltene Daten

Der ausdruecklich freigegebene saubere Worktree github_dd_branch_v2 wurde mit git worktree remove ohne Force entfernt; Branch code-v2 und gemeinsame Git-Historie bleiben erhalten. Die Seminar-Pythonumgebung wurde nach Paketinventur entfernt. Details und Wiederherstellung: BEREINIGUNG_20261112.md und seminar_vortrag/requirements-environment-20261112.txt im Repository.

Keine wissenschaftlichen Ergebnisse, Referenzen, Vortragvideos oder Literatur geloescht. Alle 51 zu Beginn unversionierten Ausarbeitungsdateien bleiben SHA256-identisch. Grosse neue MAT-Dateien und case_results.csv bleiben bewusst lokal; kleine Tabellen, Diagramme, Berichte und Manifeste werden versioniert.

## Fruehere Unterbrechungen bleiben dokumentiert

- Erster Hauptversuch: unerwartetes Ende der MCP-MATLAB-Sitzung; aeussere Suchzeit unvollstaendig.
- attempt2: Standby 13:22:45 bis 13:50:06; eigener Prozess danach beendet.
- attempt3: Standby 13:52:20 bis 14:03:59; eigener Prozess danach beendet.

Alle Artefakte und INTERRUPTION.md bleiben erhalten. Diese Teilversuche gehen nicht in die neuen Messwerte ein. Die zwischenzeitliche Vertagung wurde durch den ausdruecklichen Auftrag zur Bereinigung und Fortsetzung aufgehoben.
