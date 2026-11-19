# Codezaehlung

Nichtleere physische Codezeilen ohne reine Kommentarzeilen; MATLAB-Blockkommentare und Python-Docstrings ausgeschlossen.
MATLAB und Python einschliesslich dieses reproduzierbaren Zaehlwerkzeugs. Keine Agenten-/Skilldateien oder Konfigurationen.
Historische Programme und Quellkopien sind tatsaechlich entfernt; ihr Vorkommen wuerde die Zaehlausfuehrung abbrechen.

| Kategorie | Dateien | Codezeilen |
|---|---:|---:|
| 1 FEM und Datenerzeugung | 6 | 283 |
| 2 Modellaufbau und Training | 8 | 292 |
| 3 Trainingsauswahl und Suchsteuerung | 9 | 343 |
| 4 Vorhersage, Auswertung und Benchmark | 16 | 683 |
| 5 Datenvertraege, Einstieg und Laufverwaltung | 24 | 624 |
| 6 Aktuelle Beispiele | 2 | 42 |
| 7 Automatisierte Tests | 10 | 705 |

Funktion und Verwaltung: **2267** Codezeilen; Tests separat: **705**.
Ausgangsbestand: 17.544 Codezeilen in 380 Programmdateien, davon 1.092 Testzeilen und 8.099 Zeilen historischer Quellkopien.
Der Richtwert 2.356 bezeichnete eine Auswahl aktueller Funktionen, nicht den gesamten alten Bestand. Entfernte modale/alte Optimiererzweige und die schlankere FEM-Konfiguration reduzieren diesen Kern; das Zaehlwerkzeug wird nun ausdruecklich mitgezaehlt. Kategorien folgen der Hauptverantwortung einer Datei.
Nicht-Code-Artefakte stehen separat in CLEANUP_NONCODE_INVENTORY.csv; die 7.312 vorhandenen wissenschaftlichen Dateien sind mit Hashes in CLEANUP_PRESERVED_BASELINE.csv gesichert.
Dateiweise Zuordnung: CODEZAEHLUNG.csv. Reproduzierbar mit `python docs/count_code.py`.
