# Statischer Vier-Methoden-Vergleich

Diese ergänzende Auswertung verwendet ausschließlich die nach dem geprüften Freeze erzeugten Ergebnistabellen. Interpolation und Extrapolation bleiben getrennt.

## Vollpool: Fehler und Aufwand

| Methode | Läufe | Interpolation Mittel / P95 / Maximum | Extrapolation Mittel / P95 / Maximum | Fit Median | Einzelfall Median | Batch 128 Median |
|---|---:|---:|---:|---:|---:|---:|
| mlp | 0 | 3.00 % / 8.00 % / 10.00 % | 3.00 % / 8.00 % / 10.00 % | nicht definiert s | nicht definiert ms | nicht definiert ms |
| rbf | 0 | 3.00 % / 8.00 % / 10.00 % | 3.00 % / 8.00 % / 10.00 % | nicht definiert s | nicht definiert ms | nicht definiert ms |
| pod_mlp | 0 | 3.00 % / 8.00 % / 10.00 % | 3.00 % / 8.00 % / 10.00 % | nicht definiert s | nicht definiert ms | nicht definiert ms |
| pod_gpr | 1 | 3.00 % / 8.00 % / 10.00 % | 3.00 % / 8.00 % / 10.00 % | 10.00 s | 10.00 ms | 20.00 ms |

Mittelwert und P95 werden je Lauf über Balkenfälle berechnet und anschließend über Läufe gemittelt. Maximum ist das größte tatsächlich beobachtete Fallmaximum. Bei 768 Fällen unterscheiden sich die neuronalen Läufe in der Initialisierung; POD–GPR hat eine Datenwahl und keine geschätzte Modellstreuung.

## Datenmenge

| Methode | N=48 | N=96 | N=192 | N=384 | N=768 |
|---|---:|---:|---:|---:|---:|
| mlp | fehlt | fehlt | fehlt | fehlt | 3.00 % |
| rbf | fehlt | fehlt | fehlt | fehlt | 3.00 % |
| pod_mlp | fehlt | fehlt | fehlt | fehlt | 3.00 % |
| pod_gpr | fehlt | fehlt | fehlt | fehlt | 3.00 % |

Die Tabelle zeigt den mittleren relativen Interpolationsfeldfehler; vollständige Streuungs- und Zeitangaben stehen in der korrigierten CSV.

## Zusätzliche Auslenkungsfehler im Vollpool

| Methode | Split | Mittlerer Betrag Spitzenfehler | Mittlerer Betrag Maximumfehler |
|---|---|---:|---:|
| mlp | interpolation | nicht definiert mm | nicht definiert mm |
| mlp | extrapolation | nicht definiert mm | nicht definiert mm |
| rbf | interpolation | nicht definiert mm | nicht definiert mm |
| rbf | extrapolation | nicht definiert mm | nicht definiert mm |
| pod_mlp | interpolation | nicht definiert mm | nicht definiert mm |
| pod_mlp | extrapolation | nicht definiert mm | nicht definiert mm |
| pod_gpr | interpolation | nicht definiert mm | nicht definiert mm |
| pod_gpr | extrapolation | nicht definiert mm | nicht definiert mm |

Die Spitze bezeichnet vorzeichenbehaftetes uz bei (1, 0.5, 0.5); das Maximum ist der Betrag über alle 525 Gitterpunkte.

## Einfluss der Trainingsverteilung bei N=192

| Methode | Verteilung | Split | Mittlerer relativer Feldfehler |
|---|---|---|---:|

Beide Auswahlen haben gleiche Fallzahl, gleiche äußere Grenzen und dieselben Auswertungsfälle. Es ist eine separate Einflussuntersuchung.

## Kontrollierter POD-Vergleich

| Methode | Rang | Split | Projektion | Koeffizientenregression | Rekonstruktion |
|---|---:|---|---:|---:|---:|
| pod_mlp | 2 | interpolation | 10.00 % | 15.00 % | 18.03 % |

Die gewichtete quadratische Fehlerzerlegung gilt fallweise; die obigen Mittelwerte der Wurzeln sind nicht additiv. Ungültige Zerlegungsmarkierungen: 0. Details stehen in controlled_pod_diagnostics.csv.

## Such- und Referenzkosten

| Position | Zeit |
|---|---:|
| Suche all | 10.00 s |
| FEM val: Solver / aktive Erzeugungszeit | 2.00 / 3.00 s |

Deterministische Vollpool-GPR-Fit-Zeitmessungen: 10.00 s, 11.00 s. Diese Wiederholungen sind keine unabhängigen Datensätze.

## Einordnung und Grenzen

- Fehlgeschlagene Lauf-/Split-Auswertungen: 0; undefinierte relative Fallfehler: 0.
- Die RBF-Variante verwendet feste Gauß-Zentren und Breiten; Ergebnisse gelten für diese Implementierung und diesen begrenzten Suchraum.
- Die Testfälle werden über dieselben Modelle wiederholt vorhergesagt; Netz-Seeds sind keine zusätzlichen unabhängigen Balkenfälle.
- Netzdiagnosen und eindimensionale Balkentheorien sind Plausibilitätsprüfungen, keine exakte Referenz aller 3D-Feldkomponenten.
- Ein belastbarer Break-even und Spitzen-RAM wurden nicht gemessen; keine GPR-Unsicherheiten wurden als kalibrierte Fehlergrenzen ausgegeben.
- Die ursprünglichen Tabellen bleiben erhalten; bei nur einem Lauf ist die Streuung in pipeline_summary_corrected.csv als undefiniert markiert.

Für einen genauigkeitsorientierten Ausgangspunkt auf der untersuchten Interpolationsverteilung ist mlp anhand des Vollpool-Mittelwerts zuerst zu prüfen. Die Extrapolationsfehler, Streuung und Kosten in der Tabelle bestimmen, ob diese Wahl für den konkreten Einsatz tragfähig ist.
