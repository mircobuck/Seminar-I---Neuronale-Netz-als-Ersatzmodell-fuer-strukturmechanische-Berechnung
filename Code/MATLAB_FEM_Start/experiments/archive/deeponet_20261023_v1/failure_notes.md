# Fehler- und Entwicklungsprotokoll

- Beim ersten Daten-Audit schlug der Vergleich einer leeren ID-Liste fehl:
  MATLAB unterscheidet die Form einer leeren Spalte von `[]`. Die Prüfung
  wurde für den ersten, noch leeren Vorgänger explizit abgefangen. Danach
  bestand der vollständige Audit aller sechs Größen. Keine FEM- oder
  Modelldatei wurde dabei geändert.
- Der bewusst kurze interne Workflow-Smoke (vier Trainingsfälle, zwei
  Validierungsfälle, zwei interne Testfälle, 100 Epochen) hatte einen
  medianen internen Test-Feldfehler von etwa 74,3 %. Er ist eine technische
  Ablaufprüfung, kein Genauigkeitsnachweis. Die offiziellen Testfälle
  wurden dafür nicht verwendet.
- Der separate Zweifall-Überanpassungstest bestand nach 3000 Epochen die
  vorab festgelegte Grenze von maximal 3 % relativem Feldfehler. Dies ist
  kein Nachweis einer Memorierung bis Maschinengenauigkeit.
- Reguläre Such-/Trainings-/Auswertungsfehler werden unabhängig hiervon
  vollständig in `events.csv` mit Status FAIL und Diagnose festgehalten.
  Schlechte numerische Modellgenauigkeit wird als Ergebnis ausgewiesen
  und nicht mit einem technischen Laufabbruch verwechselt.

- Die Ausfuehrungssteuerung wurde nach N=192 in einzelne Fits fuer die
  grosse Suche aufgeteilt, um den MCP-Timeout von 600 Sekunden pro Aufruf
  einzuhalten. Checkpoints und finale Modelle bleiben erhalten. Suchbudget,
  Trainingsoptionen und Auswahlregel wurden nicht veraendert.

- Beim ersten Berichtsaufbau war die Zeichenkodierung der JSON-Metadaten
  irrtuemlich als UTF-16 angenommen. Sie wurde anhand der Dateisignatur
  korrigiert; der Bericht wurde anschliessend neu erzeugt. Keine Messwerte
  oder Modelle wurden dadurch veraendert.
- Die statische Analyse fand einen unbenutzten Rueckgabewert im Zeitmesser
  und eine missverstaendliche lokale Testvariable. Beide wurden bereinigt.
  Der gemessene Baseline-Quellstand ist separat unter source_snapshot_measured
  archiviert. Alle zehn Dateien sind danach ohne Analyzer-Meldungen; die
  sieben Tests wurden erfolgreich wiederholt.
