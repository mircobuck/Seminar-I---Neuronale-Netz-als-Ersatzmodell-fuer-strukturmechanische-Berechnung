# Ausgangssicherung vor Codebereinigung

Ausgangspunkt: 1ca58df. Keine versionierten Aenderungen zu Beginn. Alle erfassten MATLAB-, Python- und PowerShell-Programme sowie die textuelle FEM-Quellkopie sind bereits versioniert. 310 weitere nicht versionierte und 1129 ignorierte Dateien in Code v2 wurden inventarisiert; keine davon ist eine zu entfernende Programmdatei. Grosse Daten werden nicht zusaetzlich in Git aufgenommen.

CLEANUP_SOURCE_BASELINE.csv erfasst jeden Programmstand; CLEANUP_PRESERVED_BASELINE.csv bindet bestehende Daten, Modelle, Konfigurationen, Berichte, Tabellen, Bilder und Manifeste. Diese nicht programmatischen Artefakte werden bei der Bereinigung erhalten. Metadaten unter .agents/.codex sind nicht Teil des MATLAB-Funktionsbestands und bleiben unberuehrt.
