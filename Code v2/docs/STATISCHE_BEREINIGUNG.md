# Bereinigung auf den statischen Vier-Methoden-Ablauf

Stand 12.11.2026: Codebereinigung und gezielte Pruefungen abgeschlossen; neue volle Hauptwiederholung folgt aus diesem Stand.

## Sicherung und tatsaechliche Entfernung

Ausgangscommit 1ca58df; Sicherungscommit **4e83631** vor jeder Loeschung. Alle 380 Programmdateien waren versioniert; auch ignorierte und unversionierte Bestaende wurden geprueft, keine ungesicherte Programmdatei entfernt. CLEANUP_SOURCE_BASELINE.csv nennt Pfade, SHA256 und Codezeilen. Keine Branchwechsel, Remote-Pushes, Force-Operationen oder zusaetzliche aktive Archivkopie.

306 alte Programme/Quellkopien entfernt, zusaetzlich fem_core/config.m durch die schlanke staticFemConfig.m ersetzt. Betroffen: alte studies, Netzarchitekturen, Testverfahren, scripts, historische Beispiele, main.m, modale FEM, dummy-Testmodell, alte Optimierer, einmalige Reparaturprogramme und Quell-Snapshots in experiments. Wissenschaftliche Dateien in denselben Ordnern wurden erhalten. CLEANUP_FILE_PLAN.csv dokumentiert jede Ausgangsdatei: 49 unveraendert behalten, 25 angepasst/ersetzt, 306 entfernt. Neu sind der aktuelle Validierungstreiber und die statische FEM-Konfiguration; keine historische Codekopie bleibt aktiv.

## Daten und Abhaengigkeiten

**7.312 bestehende Nicht-Code-Dateien unveraendert**, keine fehlt; SHA256-Vergleich in CLEANUP_PRESERVED_CHECK.json und CLEANUP_PRESERVED_BASELINE.csv. Dazu gehoeren vorhandene FEM-Daten, Modelle, Tabellen, Diagramme, Berichte, Konfigurationen und historische Manifeste. Ausarbeitung und Literatur ausserhalb Code v2 wurden nicht angefasst. Nicht-Code-Inventar separat: CLEANUP_NONCODE_INVENTORY.csv.

Die Abhaengigkeitsanalyse startete bei runStaticStudy und beiden Beispielen, ergaenzt um alle acht dynamischen fit/predict-Funktionen. MATLAB requiredFilesAndProducts fand vorab 63 lokale Abhaengigkeiten, keine davon in der ersatzlosen Entfernungsliste. Python studyPlots.py und seine Aufrufe, JSON/CSV-Konfiguration, Daten-Lader, gespeicherte Regressionen und Wiederaufnahme wurden gesondert geprueft. Aktuelle Aufloesung und tatsaechlich geladene Funktionen stehen im neuen Validierungsordner. Die praktische Pruefung lief in einem neuen MATLAB-Batch mit anfangs ausschliesslich MATLAB-Installationspfaden; keine historischen Projektpfade oder vorgeladenen Funktionen.

Historische Verzeichnisse liefern ausschliesslich explizit konfigurierte Daten: Trainingspool und Design unter data_generation/data/static, bekannte Referenzen unter static_gpr_main_v1_20261111_run2, Vorhersagebaseline unter refactor_validation_20261112. Aktuelle Tests verwenden die kleine versionierte study_baseline.mat fuer Kandidaten und Teilmengen, keine alten Studienprogramme. Alte Manifeste bleiben unveraendert; historische Quellen lassen sich aus 4e83631 wiederherstellen (README).

## Pruefnachweis

- **71/71 Unit-Tests bestanden**, keine fehlgeschlagen oder unvollstaendig. Alle vier Methoden, gespeicherte Vollpoolmodelle, exakt gleiche Vorhersagen und numerischen Fehler, alle 76 Kandidaten und Trainingsauswahlen, POD, gewichtete Fehler, Vertraege, Checkpoints und Schutzpruefungen.
- MATLAB Code Analyzer: keine Syntaxfehler; verbleibende Hinweise sind unnoetige Suppressionen und kleine wachsende Verwaltungstabellen.
- Vollstaendiger Smoke mit neuen statischen FEM-Referenzen (4 Validierung, 4 Interpolation, 12 Extrapolation), 24 Fits und 40 Lauf/Split-Auswertungen.
- Training erneut aufgerufen: Modellhashes identisch. Auswertung vor Freeze und Training/Tuning danach abgelehnt. Manipulation eines Freeze-Metadatums erkannt und exakt zurueckgesetzt.
- Bericht zweimal ohne neue Fits/FEM; Diagramme erzeugt, Modellhashes identisch. Quell- und Freeze-Manifeste nachgeprueft.

Nachweise: experiments/static_cleanup_validation_20261112 und experiments/static_comparison_cleanup_smoke_20261112. 71 Tests ersetzen die historisch breitere Suite; entfernte Programme werden nicht aus Testgruenden aktiv gehalten. Vorhersagen/Metriken bleiben numerisch gleich; nur die obsolete modale Metrikkonfiguration entfaellt aus aktuellen Ergebnisstrukturen.

## Codeumfang

Vorher 380 Programmdateien mit **17.544 Codezeilen**, darunter **1.092 Testzeilen** und 8.099 Zeilen historischer Quellkopien. Der fruehere Richtwert 2.356 beschrieb nur eine Auswahl aktueller Funktionen. Nachher **65 Funktions-/Verwaltungsdateien mit 2.267 Zeilen**, separat **10 Testdateien mit 705 Zeilen**, insgesamt **2.972 Zeilen**. Die funktionale Zaehlung schliesst das reproduzierbare Python-Zaehlwerkzeug ein. Reduktion durch entfernte modale/alte Optimiererzweige und historische FEM-Konfiguration; keine notwendige Funktion fuer eine Zielzahl entfernt, keine kuenstliche Zeilenverdichtung.

Alle sieben gewuenschten Kategorien und Einzeldateien: CODEZAEHLUNG.md / CODEZAEHLUNG.csv. Konfigurationen, Dokumentation, Daten und Modelle werden nicht als Code gezaehlt.

## Neue Hauptwiederholung

Zielordner experiments/static_comparison_cleanup_20261112. Unveraenderte Fachkonfiguration, vier Methoden, 76 Suchkandidaten, Trainingsgroessen 48 bis 768, Seeds 42/43/44 und kontrollierte POD-Raenge. Bekannte FEM-Referenzen werden wiederverwendet; diese Wiederholung ist kein neuer unabhaengiger Abschlusstest. Vollstaendige Durchfuehrung und neue Zeitmessungen sind noch ausstehend und werden hier erst nach erfolgreichem Abschluss bestaetigt.
