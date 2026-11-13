# Bereinigung auf den statischen Vier-Methoden-Ablauf

Abgeschlossen am 13.11.2026: Codebereinigung, eigenstaendige Pruefungen, vollstaendige neue Hauptstudie und Ergebnisvergleich bestanden.

## Sicherung und tatsaechliche Entfernung

Ausgangscommit 1ca58df; Sicherungscommit **4e83631** vor jeder Loeschung. Alle 380 Programmdateien waren versioniert; auch ignorierte und unversionierte Bestaende wurden geprueft, keine ungesicherte Programmdatei entfernt. CLEANUP_SOURCE_BASELINE.csv nennt Pfade, SHA256 und Codezeilen. Keine Branchwechsel, Remote-Pushes, Force-Operationen oder zusaetzliche aktive Archivkopie.

306 alte Programme/Quellkopien entfernt, zusaetzlich fem_core/config.m durch die schlanke staticFemConfig.m ersetzt. Betroffen: alte studies, Netzarchitekturen, Testverfahren, scripts, historische Beispiele, main.m, modale FEM, dummy-Testmodell, alte Optimierer, einmalige Reparaturprogramme und Quell-Snapshots in experiments. Wissenschaftliche Dateien in denselben Ordnern wurden erhalten. CLEANUP_FILE_PLAN.csv dokumentiert jede Ausgangsdatei: 49 unveraendert behalten, 25 angepasst/ersetzt, 306 entfernt. Neu sind der aktuelle Validierungstreiber und die statische FEM-Konfiguration; keine historische Codekopie bleibt aktiv.

## Daten und Abhaengigkeiten

**7.312 bestehende Nicht-Code-Dateien unveraendert**, keine fehlt; SHA256-Vergleich in CLEANUP_PRESERVED_CHECK.json und CLEANUP_PRESERVED_BASELINE.csv. Dazu gehoeren vorhandene FEM-Daten, Modelle, Tabellen, Diagramme, Berichte, Konfigurationen und historische Manifeste. Ausarbeitung und Literatur ausserhalb Code v2 wurden nicht angefasst. Nicht-Code-Inventar separat: CLEANUP_NONCODE_INVENTORY.csv.

Die Abhaengigkeitsanalyse startete bei runStaticStudy und beiden Beispielen, ergaenzt um alle acht dynamischen fit/predict-Funktionen. MATLAB requiredFilesAndProducts fand vorab 63 lokale Abhaengigkeiten, keine davon in der ersatzlosen Entfernungsliste. Python studyPlots.py und seine Aufrufe, JSON/CSV-Konfiguration, Daten-Lader, gespeicherte Regressionen und Wiederaufnahme wurden gesondert geprueft. Nach Bereinigung wurden erneut 63 lokale Abhaengigkeiten aufgeloest; 71 tatsaechlich geladene Projektfunktionen lagen ausschliesslich in zugelassenen aktuellen Bereichen. Beide Listen stehen im neuen Validierungsordner. Die praktische Pruefung lief in einem neuen MATLAB-Batch mit anfangs ausschliesslich MATLAB-Installationspfaden; keine historischen Projektpfade oder vorgeladenen Funktionen.

Historische Verzeichnisse liefern ausschliesslich explizit konfigurierte Daten: Trainingspool und Design unter data_generation/data/static, bekannte Referenzen unter static_gpr_main_v1_20261111_run2, Vorhersagebaseline unter refactor_validation_20261112. Aktuelle Tests verwenden die kleine versionierte study_baseline.mat fuer Kandidaten und Teilmengen, keine alten Studienprogramme. Alte Manifeste bleiben unveraendert; historische Quellen lassen sich aus 4e83631 wiederherstellen (README).

## Pruefnachweis

- **71/71 Unit-Tests bestanden**, keine fehlgeschlagen oder unvollstaendig. Alle vier Methoden, gespeicherte Vollpoolmodelle, exakt gleiche Vorhersagen und numerischen Fehler, alle 76 Kandidaten und Trainingsauswahlen, POD, gewichtete Fehler, Vertraege, Checkpoints und Schutzpruefungen.
- MATLAB Code Analyzer: keine Syntaxfehler; verbleibende Hinweise sind unnoetige Suppressionen und kleine wachsende Verwaltungstabellen.
- Vollstaendiger Smoke mit neuen statischen FEM-Referenzen (4 Validierung, 4 Interpolation, 12 Extrapolation), 24 Fits und 40 Lauf/Split-Auswertungen.
- Training erneut aufgerufen: Modellhashes identisch. Auswertung vor Freeze und Training/Tuning danach abgelehnt. Manipulation eines Freeze-Metadatums erkannt und exakt zurueckgesetzt.
- Bericht zweimal ohne neue Fits/FEM; Diagramme erzeugt, Modellhashes identisch. Quell- und Freeze-Manifeste nachgeprueft.

Nachweise: experiments/static_cleanup_validation_20261112 und experiments/static_comparison_cleanup_smoke_20261112. 71 Tests ersetzen die historisch breitere Suite; entfernte Programme werden nicht aus Testgruenden aktiv gehalten. Vorhersagen/Metriken bleiben numerisch gleich; nur die obsolete modale Metrikkonfiguration entfaellt aus aktuellen Ergebnisstrukturen.

## Codeumfang

Vorher 380 Programmdateien mit **17.544 Codezeilen**, darunter **1.092 Testzeilen** und 8.099 Zeilen historischer Quellkopien. Der fruehere Richtwert 2.356 beschrieb nur eine Auswahl aktueller Funktionen. Erneut nach derselben aktuellen Zaehlregel ergeben sich fuer diese damaligen 65 Dateien 2.355 Zeilen: Die Referenz hatte zusaetzlich die einzeilige Python-Moduldokumentation von studyPlots.py mitgezaehlt. Nachher **65 Funktions-/Verwaltungsdateien mit 2.267 Zeilen**, separat **10 Testdateien mit 705 Zeilen**, insgesamt **2.972 Zeilen**. Davon sind 2.184 Zeilen eigentlicher Funktionscode und 83 Zeilen des reproduzierbaren Python-Zaehlwerkzeugs. Die 1.092 bisherigen Testzeilen beziehen sich auf tests/; zusaetzlich entfiel das 17-zeilige Dummy-Testmodell ausserhalb dieses Ordners. Reduktion durch entfernte modale/alte Optimiererzweige und historische FEM-Konfiguration; keine notwendige Funktion fuer eine Zielzahl entfernt, keine kuenstliche Zeilenverdichtung.

Alle sieben gewuenschten Kategorien und Einzeldateien: CODEZAEHLUNG.md / CODEZAEHLUNG.csv. Konfigurationen, Dokumentation, Daten und Modelle werden nicht als Code gezaehlt.

## Neue Hauptwiederholung: erfolgreich abgeschlossen

Ordner: **experiments/static_comparison_cleanup_20261113_attempt2**. Quellcommit **5ba4840**, Funktionscode unveraendert seit **d2357ff**. Der erfolgreiche Lauf erfolgte nach den bestandenen Pruefungen in einem frischen MATLAB-Prozess mit anfangs ausschliesslich MATLAB-Installationspfaden. Gegenueber dem vorherigen Versuch aenderte sich ausschliesslich der Ausgabeordner; Fachkonfiguration, Budgets, Daten und Auswahlregeln blieben unveraendert. Alle 67 Bindungen des erfolgreichen Smoke-Quell-/Inputmanifests stimmten vor dem neuen Lauf weiterhin exakt.

- Vier Methoden, alle 76 Suchkandidaten plus 12 Bestaetigungsfits, unveraenderte Sieger 4/20/4/20.
- Alle Trainingsmengen 48/96/192/384/768, Trainingsauswahlen, neuronalen Seeds, kontrollierten POD-Raenge, GPR-Zeitwiederholungen und Verteilungsfits durchgefuehrt.
- **234 erfolgreiche Fits, 144 ausgewertete Modelle, 288 Modell/Split-Auswertungen, 55.296 Fallzeilen**. Keine fehlgeschlagenen Fits/Auswertungen oder undefinierten relativen Feldfehler.
- Alle verglichenen numerischen Lauf- und Fallkennzahlen gegenueber static_comparison_refactor_20261112_attempt4 **exakt identisch**. Gegenueber der urspruenglichen Hauptstudie nur die bereits erklaerten 13 Mittelwertabweichungen bis 9,992e-16 durch Summationsreihenfolge; keine neue Methodenabweichung.
- **85 Quell-/Inputeintraege, 889 Freeze-Eintraege und alle Siegel gueltig**. Zusaetzlich stimmen saemtliche 75 aktuellen Quelldateien einschliesslich Tests, Beispielen und Zaehlwerkzeug bytegenau mit dem Vor-Lauf-Commit 5ba4840 ueberein (CLEANUP_FINAL_SOURCE.csv). Beide GPR-Zeitwiederholungen haben identische Daten-IDs, Rang, Seed und numerische Validierungsfehler. Die 20 beim ersten Versuch wiederaufgenommenen Modelle blieben ebenfalls byteidentisch erhalten.
- Neue Fit-, Segment-, Such-, Vorhersage- und FEM-Zeiten; alle acht Break-even-Szenarien nachgerechnet. Zehn Diagramme dekodiert, vier repraesentative Darstellungen visuell geprueft.
- Studienphasen 13.11.2026 10:08:52 bis 12:06:16 Europe/Berlin: **7.044 s = 1 h 57 min 24 s**, ohne protokollierten Standby. Eigener MATLAB-Prozess und temporaerer Standby-Helfer beendet.
- Nach Abschluss erneut alle **7.312 geschuetzten Bestandsdateien unveraendert**, keine fehlt. Grosse Modelle und MAT-Dateien bleiben lokal erhalten; Git enthaelt Quellen, kompakte Ergebnisse und Provenienz, keine neue Vollkopie grosser Datensaetze.

Ergebnisbericht: [WIEDERHOLUNG.md](../experiments/static_comparison_cleanup_20261113_attempt2/WIEDERHOLUNG.md). Neue Messbedingungen: [LAUFBEDINGUNGEN.md](../experiments/static_comparison_cleanup_20261113_attempt2/LAUFBEDINGUNGEN.md). verification.json, numerical_comparison.csv, comparison_immediate_previous.csv, gpr_repeat_verification.json, benchmark_verification.json und plot_validation.json dokumentieren die Abschlusspruefung. completion_artifacts.csv bindet alle 1.430 abgeschlossenen Laufartefakte per SHA256; keine Quellkopie wurde angelegt.

Die bekannte Referenzbasis wurde unveraendert wiederverwendet; dies ist eine Reproduktion, kein neuer unabhaengiger Abschlusstest. Benchmark und Break-even gelten fuer die dokumentierten Annahmen, insbesondere bereits vorhandene Daten. Die Zeiten stammen aus dieser Sitzung; Unterschiede zu frueheren Sitzungen sind kein isolierter Beschleunigungsnachweis.

## Unterbrechungen, Sicherung und offene Punkte

Der Versuch vom 12.11.2026 blieb nach externer Speicherknappheit und spaeter manuellem Standby unvollstaendig. Seine Daten, 34 Checkpoints und Fehlerberichte bleiben erhalten. Er wurde nicht als erfolgreicher Zeitnachweis ausgegeben. Nach ausdruecklicher Nutzerfreigabe wurden ausschliesslich die dokumentierten pip-/npm-Download-Caches entfernt. Details: CLEANUP_INTERRUPTION_20261112.md und CLEANUP_STANDBY_EVENTS_20261113.json.

Relevante lokale Commits: **4e83631** (vollstaendige Quellsicherung), **d2357ff** (bereinigter und gepruefter statischer Bestand), **5ba4840** (Unterbrechungsnachweis und neuer Ausgabeordner). Der abschliessende Ergebniscommit fuegt Berichte, Tabellen, Diagramme und Nachweise hinzu; Funktionscode und Studienkonfiguration bleiben auf 5ba4840.

**Keine beauftragten Arbeitspunkte offen.** Historische Quellen sind aus 4e83631 wiederherstellbar; sie sind im aktuellen Arbeitsstand nicht als aktive Archivkopie vorhanden. Es erfolgte kein Remote-Push.
