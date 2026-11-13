# Laufbedingungen und neue Zeitmessungen

Ein einzelner MATLAB-Batchprozess, Worker 14232, Launcher 126160; Quellcommit 5ba4840. Start 2026-11-13T10:07:05.1884840+01:00; letzte Reportphase 2026-11-13T12:06:16 Europe/Berlin. Die sieben Studienphasen dauerten **7044 s (1 h 57 min 24 s)**. MATLAB-Start und Initialisierung liegen davor. Die Zeitstempel im Batchlog sind sekundengenau, innere Fit-/Vorhersagetimer stehen in den Ergebnisdateien.

Dieser erfolgreiche Versuch lief ohne protokollierten Standby: kein Kernel-Power-Ereignis 42 und kein Power-Troubleshooter-Ereignis 1 zwischen Start und Abschlusspruefung (power_events_check.json). Die temporaere SetThreadExecutionState-Sperre verhinderte automatischen Leerlauf-Standby. Keine dauerhafte Energieeinstellung wurde geaendert. Eigener MATLAB-Prozess und Helfer 115596 sind beendet.

Start mit 2.475 GiB frei, oberhalb der 1,75-GiB-Startschwelle. Minimum in 123 protokollierten Laufzeitstichproben: 1.924 GiB. Die 512-MiB-Reserve wurde eingehalten. Lokales Rohprotokoll: ../static_comparison_cleanup_20261113_attempt2.runtime.log. Phasen: batch_phases.txt und phase_times.csv.

Keine zusaetzliche Studie wurde parallel gestartet. Eine vorhandene MATLAB/MCP-Sitzung blieb bestehen; ihre beiden Prozesse nahmen in einer etwa 17-minuetigen Stichprobe zusammen nur rund 1,84 CPU-Sekunden zu. Andere Hintergrundlast, Speicherknappheit und thermische Effekte werden dadurch nicht ausgeschlossen. Im neuen Lauf sind einzelne Fits langsamer als zuvor; diese Sitzungen liefern keinen isolierten kausalen Geschwindigkeitsnachweis fuer die Codebereinigung. Alle neuen Zeiten werden unveraendert ausgewiesen.

Der vorherige Versuch static_comparison_cleanup_20261112 endete nach einer Speicherunterbrechung und spaeter manuellem Standby mit unvollstaendiger Suche. Seine 34 Checkpoints und Fehlerprotokolle bleiben erhalten, gehen aber nicht in die neuen Messwerte ein. Die nach ausdruecklicher Freigabe entfernten pip-/npm-Download-Caches und beide Unterbrechungen sind in ../../docs/CLEANUP_INTERRUPTION_20261112.md dokumentiert. Keine Zeit wurde nachtraeglich um Standbyanteile bereinigt.

| Phase | Beginn | Ende | Dauer [s] |
|---|---|---|---:|
| generate | 2026-11-13T10:08:52 | 2026-11-13T10:08:55 | 3 |
| tune | 2026-11-13T10:08:55 | 2026-11-13T10:48:40 | 2385 |
| train | 2026-11-13T10:48:40 | 2026-11-13T11:59:12 | 4232 |
| freeze | 2026-11-13T11:59:12 | 2026-11-13T11:59:47 | 35 |
| evaluate | 2026-11-13T11:59:47 | 2026-11-13T12:03:28 | 221 |
| benchmark | 2026-11-13T12:03:28 | 2026-11-13T12:05:35 | 127 |
| report | 2026-11-13T12:05:35 | 2026-11-13T12:06:16 | 41 |

Benchmark: 12 vorab festgelegte Interpolationsfaelle, FEM-Warm-up und 24 gemessene FEM-Aufrufe; je Methode 360 Einzelfallmessungen und 30 Batches mit 12 Faellen, jeweils nach Warm-up. Keine Ergebnisanalyse wurde parallel zu diesen Benchmarkmessungen gestartet. Alle acht Break-even-Zeilen wurden unabhaengig aus Offlinekosten und gemessenen Einsparungen nachgerechnet.

Abschlusspruefung: 85 Quell-/Inputeintraege, 889 Freeze-Eintraege und alle Checkpoint-Siegel stimmen. 234 Fits, 288 Auswertungen und 55.296 Fallzeilen. Beide zusaetzlichen GPR-Fits haben exakt gleiche Trainings-/Validierungs-IDs, Rang, Seed und numerische Validierungsfallfehler. Alle zehn Diagramme sind dekodierbar; vier repraesentative Diagramme wurden visuell geprueft.

Break-even bleibt bedingt auf bereits vorhandene Referenzdaten und den dokumentierten Messumfang. Neue Vollpool-Fit-Zeiten: MLP 60,3979 s, RBF 52,9865 s, POD-MLP 32,6767 s, POD-GPR 419,6344 s. FEM-Einzelfallmedian im neuen Benchmark: 2,79375 s. Ohne Suchkosten ergeben sich 22/20/12/151 Einzelfaelle; mit Suche 203/223/106/529. Nicht enthalten sind neue Datenerzeugung, Laden/Speichern, Qualitaetssicherung und spaetere Updates. Vollstaendige Segmentzeiten und Annahmen: WIEDERHOLUNG.md.
