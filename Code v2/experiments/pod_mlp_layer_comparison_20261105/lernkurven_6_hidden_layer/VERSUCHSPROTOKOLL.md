# Versuchsprotokoll POD-MLP: Vergleich der Schichtzahlen

## Versuchsaufbau

- Aufgabe: Statische Verschiebungsfelder; gewichtete, mittelwertzentrierte POD mit Rang 10.
- Anzahl Trainingsfälle: 12, 24, 48, 96, 192 und 384.
- Versteckte Schichten: 1, 2, 3, 4, 5 und 6; jeweils 64 Neuronen mit tanh-Aktivierung.
- Trainingsverfahren: Adam, Lernrate 0,001, 200 Epochen, MSE; letzte Iteration.
- Mini-Batch-Größe: min(32, Anzahl Trainingsfälle).
- Seeds: 42, 43, 44; je Seed verschachtelte Trainingsmengen. POD-Basis und Normierung werden je Lauf ausschließlich auf dessen Trainingsfällen bestimmt.
- Umfang: 6 Schichtzahlen × 6 Trainingsgrößen × 3 Seeds = 108 Modellläufe.
- Auswertung: dieselben 12 Validierungsfälle; gewichteter mittlerer Absolutfehler in Metern, Median und P95 der relativen Feldfehler. P95 nach Nearest-Rank entspricht bei 12 Fällen dem größten Wert.
- Ein unabhängiger Abschlusstest wurde im Rahmen dieses Vergleichs nicht durchgeführt.
- Die gespeicherten Trainings-IDs und Validierungs-IDs wurden über alle sechs Varianten auf Übereinstimmung geprüft.

## Ergebnisübersicht bei 384 Trainingsfällen

| Versteckte Schichten | Medianfehler: Bereich über Seeds | P95: Bereich über Seeds |
|---:|---:|---:|
| 1 | 13.40–19.61 % | 165.13–287.10 % |
| 2 | 7.73–10.57 % | 49.68–177.85 % |
| 3 | 1.49–7.54 % | 61.56–99.29 % |
| 4 | 12.57–13.74 % | 44.44–71.22 % |
| 5 | 12.78–17.94 % | 39.26–78.88 % |
| 6 | 9.36–15.94 % | 27.66–105.21 % |

## Dateien

- `versuchsfaelle.csv`: alle 108 Kombinationen mit Median und P95.
- `vergleich_1_bis_6_median.png`, `vergleich_1_bis_6_p95.png`, `vergleich_1_bis_6_absolut.png`: Vergleich, getrennt nach Seed.
- Einzelne Modelle und `learning_curve.mat` liegen in `mein_lernkurven_lauf` bzw. den Ordnern `lernkurven_2_hidden_layer` bis `lernkurven_6_hidden_layer` im Arbeitsordner. In den MAT-Ergebnissen sind die Trainings-IDs und fallweisen Validierungsmetriken gespeichert.
