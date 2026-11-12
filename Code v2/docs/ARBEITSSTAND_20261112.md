# Arbeitsstand der Umstrukturierung und Wiederholung

## Abgeschlossen

Die aktive Struktur liegt direkt in Code v2: runStaticStudy, setupProject, Paket staticstudy unter workflows/static_comparison, zentrale Fachkonfiguration und separate lokale Pfade. Gemeinsame Modelle und FEM-Schnittstellen sind erhalten. Historische Programme sind gekennzeichnet und nicht Teil des aktiven Pfads. README, Migration, Protokoll, Codezaehlung und Testnachweise liegen vor.

83 bestehende Tests bestanden. 16 neue Regressionstests bestanden; nach additiver Zeitinstrumentierung wurden 55 betroffene Modell-/Workflowtests erfolgreich ausgefuehrt. Gespeicherte Vorhersagen und Fallfehler aller vier Methoden stimmen exakt mit der vor dem Umbau erfassten Baseline ueberein. Suchkandidaten und Trainingsauswahlen sind unveraendert.

Der vollstaendige Smoke-Test in static_comparison_smoke_20261112_attempt2 ist erfolgreich: statische FEM, 24 Fits, 40 Auswertungen, Wiederaufnahme ohne Modellveraenderung, Freeze-/Testzugriffssperren, Benchmark und wiederholte reine Berichtserstellung. Kein modal ausgefuehrter Zweig.

Alle 51 zu Beginn noch unversionierten Dateien der vorhandenen Ausarbeitung wurden nachher per SHA-256 verglichen und blieben inhaltlich unveraendert. Nachweis: ORIGINALDATEIEN_PRUEFUNG.csv. Bestehende versionierte Referenz-/Modell-/Ergebnisdateien wurden nicht veraendert.

## Nicht abgeschlossen: kontrollierte Hauptwiederholung

Die Hauptstudie wurde gestartet, aber kein Hauptversuch ist vollstaendig abgeschlossen. Es gibt keine neuen abschliessenden Vier-Methoden-Ergebnisse und keine vollstaendige neue Laufzeit- oder Break-even-Auswertung. Historische Zeiten werden nicht als neue Messungen ausgegeben.

- static_comparison_refactor_20261112: unerwartetes Ende der MCP-MATLAB-Sitzung nach vier versiegelten MLP-Kandidaten; aeussere Suchzeit nicht abgeschlossen.
- static_comparison_refactor_20261112_attempt2: Windows-Standby 13:22:45 bis 13:50:06 Europe/Berlin; Kandidat 7 enthaelt 1702.80 s Fit-Zeit. Der eigene Batchprozess wurde nach Feststellung beendet. Die Zeit wird nicht nachtraeglich gekuerzt.
- static_comparison_refactor_20261112_attempt3: erneuter Windows-Standby 13:52:20 bis 14:03:59 Europe/Berlin direkt beim Studienstart. Der eigene Batchprozess wurde beendet.

Die Unterbrechungen sind pro Versuch in INTERRUPTION.md dokumentiert. Alle Artefakte bleiben erhalten. Die ersten abgeschlossenen neuen MLP-Kandidaten lieferten dieselben Validierungskennzahlen wie die historischen Gegenstuecke; daraus wird kein vollstaendiger Studiennachweis abgeleitet.

## Konkrete Voraussetzung und Fortsetzung

Fuer kontrollierte Messungen muss der Rechner waehrend des gesamten seriellen Laufs wach bleiben (kein Zuklappen/Standby). Der Nutzer wurde hierzu um Rueckmeldung gebeten; weitere automatische Neustarts wurden gestoppt. Lokale Konfiguration ist auf einen noch nicht gestarteten neuen Ordner static_comparison_refactor_20261112_attempt4 vorbereitet.

Danach init, generate (Referenzwiederverwendung), tune, train, freeze, evaluate, benchmark und report ausfuehren. Die Fachkonfiguration und Auswahlregeln bleiben unveraendert. Nach erfolgreichem Lauf sind Ergebnisgleichheit/Abweichungen, neue Zeiten, bedingte Break-even-Szenarien, Diagramme und der abschliessende Ergebniscommit noch zu pruefen und zu dokumentieren.

Die vorhandenen Referenzfaelle sind bekannt; auch die spaetere Wiederholung ist kein neuer unabhaengiger Abschlusstest.
