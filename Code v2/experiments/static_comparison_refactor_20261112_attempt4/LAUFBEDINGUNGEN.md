# Laufbedingungen und Phasenzeiten

Ein einzelner versteckter MATLAB-Batchprozess (Worker-PID 116208, Launcher 130864). Start 12.11.2026 15:54:53.826 Europe/Berlin; Bericht vollstaendig 17:44:00. Studienphasen ab 15:56:41: 6439 s (1 h 47 min 19 s). MATLAB-Start und Initialisierung sind in diesen Phasenzeiten nicht enthalten. Zeitstempel aus dem Batchlog sind sekundengenau, innere Timer stehen in den Ergebnisdateien. Quellcommit bei Initialisierung: b2c9e23.

Eine ausschliesslich fuer die Laufzeit gestartete SetThreadExecutionState-Sperre verhinderte automatischen Leerlauf-Standby. Keine dauerhafte Energieeinstellung geaendert. Helfer und eigener MATLAB-Prozess sind beendet. Systemprotokoll von 15:54:50 bis zur Abschlusspruefung: kein Kernel-Power-Standbyereignis 42 und kein Power-Troubleshooter-Aufwachereignis 1 (power_events_check.json). Keine Zeit wurde nachtraeglich um Standbyanteile bereinigt.

Keine zusaetzlichen Studienjobs gestartet. Die bereits vorhandene andere MATLAB/MCP-Sitzung zeigte in einer kontrollierten Stichprobe nur 0.1875 s CPU-Zuwachs ueber etwa eine Minute. Hintergrundlast und sonstige Systemeffekte werden dadurch nicht vollstaendig ausgeschlossen. Neue/historische Laufzeitunterschiede sind kein isolierter kausaler Beschleunigungsnachweis fuer den Strukturumbau.

Freier Speicher unmittelbar nach Bereinigung: 1.908 GiB (Startschwelle 1.75 GiB). In 96 protokollierten Laufzeitstichproben: Minimum 2.260 GiB. Die 512-MiB-Checkpointreserve wurde nicht unterschritten. Auszug aus dem Prozessmonitor: runtime_monitor.log (lokal, ignoriert); Phasenprotokoll: batch_phases.txt.

| Phase | Beginn (Europe/Berlin) | Ende | Dauer [s] |
|---|---|---|---:|
| generate | 2026-11-12T15:56:41 | 2026-11-12T15:56:43 | 2 |
| tune | 2026-11-12T15:56:43 | 2026-11-12T16:35:31 | 2328 |
| train | 2026-11-12T16:35:31 | 2026-11-12T17:38:03 | 3752 |
| freeze | 2026-11-12T17:38:03 | 2026-11-12T17:38:34 | 31 |
| evaluate | 2026-11-12T17:38:34 | 2026-11-12T17:41:45 | 191 |
| benchmark | 2026-11-12T17:41:45 | 2026-11-12T17:43:25 | 100 |
| report | 2026-11-12T17:43:25 | 2026-11-12T17:44:00 | 35 |

Zeitmessung im Benchmark: 12 festgelegte Faelle, 24 gemessene FEM-Aufrufe plus Warm-up; pro Methode 360 Einzelfallmessungen und 30 Batches mit 12 Faellen plus Warm-ups. Rohdaten bleiben erhalten. Laden separat; keine Ergebnisanalyse parallel zu den Benchmarkmessungen ausgefuehrt.

Abschlusspruefung: 90 Quellmanifest- und 894 Freeze-Eintraege sowie alle Siegel stimmen. Die 6 gespeicherten Testartefakte und die 51 urspruenglich unversionierten Ausarbeitungsdateien blieben byteidentisch. Alle 10 Diagramme lassen sich dekodieren; vier repraesentative Diagramme wurden visuell auf Lesbarkeit und vollstaendige Achsen geprueft.
