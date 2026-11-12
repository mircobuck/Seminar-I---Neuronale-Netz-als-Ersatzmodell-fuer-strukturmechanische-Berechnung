# Statischer Vier-Methoden-Vergleich

Diese ergänzende Auswertung verwendet ausschließlich die nach dem geprüften Freeze erzeugten Ergebnistabellen. Interpolation und Extrapolation bleiben getrennt.

## Vollpool: Fehler und Aufwand

| Methode | Läufe | Interpolation Mittel / P95 / Maximum | Extrapolation Mittel / P95 / Maximum | Fit Median | Einzelfall Median | Batch 128 Median |
|---|---:|---:|---:|---:|---:|---:|
| mlp | 3 | 4.64 % / 14.78 % / 58.59 % | 16.24 % / 50.74 % / 638.23 % | 54.07 s | 9.82 ms | 13.52 ms |
| rbf | 3 | 7.41 % / 22.57 % / 97.21 % | 32.67 % / 102.03 % / 1253.55 % | 44.40 s | 8.74 ms | 11.91 ms |
| pod_mlp | 3 | 4.78 % / 15.73 % / 43.78 % | 13.74 % / 47.82 % / 286.56 % | 35.22 s | 10.58 ms | 12.34 ms |
| pod_gpr | 1 | 0.55 % / 2.20 % / 6.65 % | 3.85 % / 15.85 % / 88.55 % | 353.57 s | 7.04 ms | 44.57 ms |

Mittelwert und P95 werden je Lauf über Balkenfälle berechnet und anschließend über Läufe gemittelt. Maximum ist das größte tatsächlich beobachtete Fallmaximum. Bei 768 Fällen unterscheiden sich die neuronalen Läufe in der Initialisierung; POD–GPR hat eine Datenwahl und keine geschätzte Modellstreuung.

## Datenmenge

| Methode | N=48 | N=96 | N=192 | N=384 | N=768 |
|---|---:|---:|---:|---:|---:|
| mlp | 114.93 % | 10.96 % | 5.58 % | 4.91 % | 4.64 % |
| rbf | 29.48 % | 13.27 % | 11.22 % | 8.14 % | 7.41 % |
| pod_mlp | 145.46 % | 28.80 % | 9.71 % | 4.29 % | 4.78 % |
| pod_gpr | 29.31 % | 7.72 % | 2.69 % | 1.25 % | 0.55 % |

Die Tabelle zeigt den mittleren relativen Interpolationsfeldfehler; vollständige Streuungs- und Zeitangaben stehen in der korrigierten CSV.

## Zusätzliche Auslenkungsfehler im Vollpool

| Methode | Split | Mittlerer Betrag Spitzenfehler | Mittlerer Betrag Maximumfehler |
|---|---|---:|---:|
| mlp | interpolation | 0.0057 mm | 0.0058 mm |
| mlp | extrapolation | 0.0106 mm | 0.0107 mm |
| rbf | interpolation | 0.0071 mm | 0.0073 mm |
| rbf | extrapolation | 0.0173 mm | 0.0177 mm |
| pod_mlp | interpolation | 0.0049 mm | 0.0049 mm |
| pod_mlp | extrapolation | 0.0083 mm | 0.0082 mm |
| pod_gpr | interpolation | 0.0007 mm | 0.0007 mm |
| pod_gpr | extrapolation | 0.0023 mm | 0.0023 mm |

Die Spitze bezeichnet vorzeichenbehaftetes uz bei (1, 0.5, 0.5); das Maximum ist der Betrag über alle 525 Gitterpunkte.

## Einfluss der Trainingsverteilung bei N=192

| Methode | Verteilung | Split | Mittlerer relativer Feldfehler |
|---|---|---|---:|
| mlp | ungleichmäßig | extrapolation | 39.63 % |
| mlp | ungleichmäßig | interpolation | 14.28 % |
| pod_gpr | ungleichmäßig | extrapolation | 30.62 % |
| pod_gpr | ungleichmäßig | interpolation | 5.08 % |
| pod_mlp | ungleichmäßig | extrapolation | 52.08 % |
| pod_mlp | ungleichmäßig | interpolation | 15.27 % |
| rbf | ungleichmäßig | extrapolation | 62.12 % |
| rbf | ungleichmäßig | interpolation | 23.35 % |
| mlp | raumfüllend | extrapolation | 19.72 % |
| mlp | raumfüllend | interpolation | 5.45 % |
| pod_gpr | raumfüllend | extrapolation | 13.92 % |
| pod_gpr | raumfüllend | interpolation | 2.90 % |
| pod_mlp | raumfüllend | extrapolation | 41.68 % |
| pod_mlp | raumfüllend | interpolation | 6.97 % |
| rbf | raumfüllend | extrapolation | 43.25 % |
| rbf | raumfüllend | interpolation | 7.65 % |

Beide Auswahlen haben gleiche Fallzahl, gleiche äußere Grenzen und dieselben Auswertungsfälle. Es ist eine separate Einflussuntersuchung.

## Kontrollierter POD-Vergleich

| Methode | Rang | Split | Projektion | Koeffizientenregression | Rekonstruktion |
|---|---:|---|---:|---:|---:|
| pod_gpr | 10 | extrapolation | 0.00 % | 3.85 % | 3.85 % |
| pod_gpr | 10 | interpolation | 0.00 % | 0.55 % | 0.55 % |
| pod_mlp | 10 | extrapolation | 0.00 % | 11.63 % | 11.63 % |
| pod_mlp | 10 | interpolation | 0.00 % | 3.99 % | 3.99 % |
| pod_gpr | 15 | extrapolation | 0.00 % | 3.85 % | 3.85 % |
| pod_gpr | 15 | interpolation | 0.00 % | 0.55 % | 0.55 % |
| pod_mlp | 15 | extrapolation | 0.00 % | 14.40 % | 14.40 % |
| pod_mlp | 15 | interpolation | 0.00 % | 3.06 % | 3.06 % |
| pod_gpr | 2 | extrapolation | 0.12 % | 3.85 % | 3.86 % |
| pod_gpr | 2 | interpolation | 0.06 % | 0.55 % | 0.56 % |
| pod_mlp | 2 | extrapolation | 0.12 % | 13.85 % | 13.85 % |
| pod_mlp | 2 | interpolation | 0.06 % | 5.02 % | 5.02 % |

Die gewichtete quadratische Fehlerzerlegung gilt fallweise; die obigen Mittelwerte der Wurzeln sind nicht additiv. Ungültige Zerlegungsmarkierungen: 0. Details stehen in controlled_pod_diagnostics.csv.

## Such- und Referenzkosten

| Position | Zeit |
|---|---:|
| Suche mlp | 721.25 s |
| Suche rbf | 708.47 s |
| Suche pod_mlp | 299.29 s |
| Suche pod_gpr | 1203.16 s |
| Suche all | 2933.05 s |
| FEM historical_training_pool: Solver / aktive Erzeugungszeit | 1632.92 / nicht definiert s |
| FEM val: Solver / aktive Erzeugungszeit | 454.75 / 566.11 s |
| FEM interpolation: Solver / aktive Erzeugungszeit | 690.54 / 861.80 s |
| FEM extrapolation: Solver / aktive Erzeugungszeit | 434.57 / 533.08 s |

Deterministische Vollpool-GPR-Fit-Zeitmessungen: 353.57 s, 337.19 s, 336.15 s. Diese Wiederholungen sind keine unabhängigen Datensätze.

## Einordnung und Grenzen

- Fehlgeschlagene Lauf-/Split-Auswertungen: 0; undefinierte relative Fallfehler: 0.
- Die RBF-Variante verwendet feste Gauß-Zentren und Breiten; Ergebnisse gelten für diese Implementierung und diesen begrenzten Suchraum.
- Die Testfälle werden über dieselben Modelle wiederholt vorhergesagt; Netz-Seeds sind keine zusätzlichen unabhängigen Balkenfälle.
- Netzdiagnosen und eindimensionale Balkentheorien sind Plausibilitätsprüfungen, keine exakte Referenz aller 3D-Feldkomponenten.
- Ein belastbarer Break-even und Spitzen-RAM wurden nicht gemessen; keine GPR-Unsicherheiten wurden als kalibrierte Fehlergrenzen ausgegeben.
- Die ursprünglichen Tabellen bleiben erhalten; bei nur einem Lauf ist die Streuung in pipeline_summary_corrected.csv als undefiniert markiert.

Für einen genauigkeitsorientierten Ausgangspunkt auf der untersuchten Interpolationsverteilung ist pod_gpr anhand des Vollpool-Mittelwerts zuerst zu prüfen. Die Extrapolationsfehler, Streuung und Kosten in der Tabelle bestimmen, ob diese Wahl für den konkreten Einsatz tragfähig ist.
