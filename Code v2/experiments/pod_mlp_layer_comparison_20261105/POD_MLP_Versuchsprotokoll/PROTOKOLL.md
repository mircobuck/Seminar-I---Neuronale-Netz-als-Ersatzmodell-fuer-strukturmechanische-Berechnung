# Versuchsprotokoll: POD-MLP-Architekturvergleich

Stand: 5. November 2026. Dieses Protokoll fasst die gespeicherten Lernkurven für statische Verschiebungsfelder zusammen.

## Ziel und Versuchsplan

Untersucht wird, wie Netzbreite und Anzahl versteckter Schichten den Validierungsfehler des POD-MLP beeinflussen. Das Netz sagt zehn POD-Koeffizienten voraus; daraus wird das Verschiebungsfeld rekonstruiert.

| Merkmal | Untersuchte Werte |
|---|---|
| Neuronen je versteckter Schicht | 64 und 128 |
| Versteckte Schichten | 1, 2, 3, 4, 5 und 6 |
| Trainingsfälle | 12, 24, 48, 96, 192 und 384 |
| Seeds | 42, 43 und 44 |
| Umfang | 2 × 6 × 6 × 3 = 216 Modellläufe |
| Validierung | dieselben 12 statischen Validierungsfälle je Lauf |

Die Trainingsmengen sind je Seed verschachtelt. Die gespeicherten Trainings- und Validierungs-IDs wurden zwischen den Architekturen verglichen. POD-Basis und Normierung werden für jeden Lauf aus seiner jeweiligen Trainingsmenge bestimmt. Die Ergebnisse sind Validierungswerte; ein unabhängiger Abschlusstest wurde für diesen Vergleich nicht durchgeführt.

## Gemeinsame Einstellungen

- Gewichtete, mittelwertzentrierte POD; Rang 10.
- Vollständig verbundene versteckte Schichten mit tanh-Aktivierung; Ausgangsschicht für zehn POD-Koeffizienten.
- Optimierer Adam, Lernrate 0,001, 200 Epochen, MSE als Trainingsverlust und letzte Trainingsiteration als Modell.
- Batchgröße: Minimum aus 32 und der Anzahl Trainingsfälle. CPU-Training.
- Bewertet werden der mittlere gewichtete absolute Feldfehler in Metern sowie Median und P95 des gewichteten relativen Feldfehlers. P95 wird nach Nearest Rank bestimmt und ist bei zwölf definierten Werten der größte Wert.
- Es handelt sich um dieselben Trainingseinstellungen, nicht um für jede Tiefe einzeln optimierte Hyperparameter.

## Ergebnisüberblick bei 384 Trainingsfällen

Die Bereiche zeigen das Minimum und Maximum der jeweils drei Seed-Ergebnisse, nicht Konfidenzintervalle.

| Neuronen | Schichten | Medianfehler über Seeds | P95 über Seeds |
|---:|---:|---:|---:|
| 64 | 1 | 13,40–19,61 % | 165,13–287,10 % |
| 64 | 2 | 7,73–10,57 % | 49,68–177,85 % |
| 64 | 3 | 1,49–7,54 % | 61,56–99,29 % |
| 64 | 4 | 12,57–13,74 % | 44,44–71,22 % |
| 64 | 5 | 12,78–17,94 % | 39,26–78,88 % |
| 64 | 6 | 9,36–15,94 % | 27,66–105,21 % |
| 128 | 1 | 9,91–15,43 % | 85,37–249,81 % |
| 128 | 2 | 5,80–11,05 % | 87,62–118,02 % |
| 128 | 3 | 10,75–15,13 % | 25,43–198,52 % |
| 128 | 4 | 6,79–8,14 % | 17,91–89,08 % |
| 128 | 5 | 5,94–11,49 % | 36,80–68,95 % |
| 128 | 6 | 9,87–13,32 % | 31,69–109,64 % |

## Dateien und Nachvollziehbarkeit

- `alle_versuchslaeufe.csv`: eine Zeile pro Lauf mit Architektur, Trainingsgröße, Seed, mittlerem Absolutfehler, Median, P95, Anzahl undefinierter relativer Fehler und Modellpfad relativ zum Arbeitsordner.
- `alle_validierungsfaelle.csv`: 2.592 Zeilen mit jeder Kombination aus Modelllauf und Validierungsfall. Relative Fehler sind als Verhältnis angegeben: 0,1 entspricht 10 %.
- Die jeweiligen Modellordner enthalten `learning_curve.mat` mit Trainings-IDs, Berichten und fallweisen Metriken sowie die trainierten Modelle. Die Ordner heißen `mein_lernkurven_lauf`, `lernkurven_2_hidden_layer` bis `lernkurven_6_hidden_layer` und `lernkurven_128_1_layer` bis `lernkurven_128_6_layer`.
- Die 64er-Vergleichsgrafiken liegen in `lernkurven_6_hidden_layer`; die 128er-Vergleichsgrafiken in `lernkurven_128_6_layer`.

Alle 216 Kombinationen und Modellpfade wurden auf Vollständigkeit geprüft. Unterschiedliche Seeds sind unabhängige Trainingsläufe, keine zusätzlichen Validierungsfälle.
