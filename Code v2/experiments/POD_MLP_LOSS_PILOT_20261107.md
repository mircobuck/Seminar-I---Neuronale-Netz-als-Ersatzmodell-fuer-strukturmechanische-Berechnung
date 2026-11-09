# POD-MLP-Loss-Probelauf

## Fragestellung

Verbessert eine Trainings-Loss, die dem gewichteten Feldfehler entspricht,
die Validierung gegenüber der bisherigen, pro POD-Koeffizient standardisierten
MSE? Getestet werden 64 Neuronen pro versteckter Schicht und 1, 2 oder 3
versteckte Schichten.

## Vergleich der Losses

- `per_coefficient_mse` (bisherige Loss): POD-Koeffizienten werden einzeln mit
  ihrer Trainings-Standardabweichung skaliert; trainiert wird MSE auf den
  skalierten Koeffizienten.
- `weighted_field_mse` (Probelauf): alle POD-Koeffizienten werden mit derselben
  gemeinsamen Skala normiert. Da die POD-Basis bezüglich der
  Verschiebungsfeld-Gewichte orthonormal ist, ist die Summe der quadrierten
  Koeffizientenfehler proportional zum quadrierten gewichteten Feldfehler.

Die zweite Loss ist damit – bis auf einen für alle Fälle gleichen Faktor –
eine MSE auf den gewichteten Feldfehler. Sie ändert nicht die POD-Basis,
Architektur, Daten, Optimierer oder Trainingsdauer.

## Festgehaltene Versuchsbedingungen

- Trainingssplit: alle 768 statischen Trainingsfälle.
- Validierung: die bestehenden 12 statischen Validierungsfälle; keine
  Validierungsdaten werden zum Fitten oder für die POD-Basis verwendet.
- Testsplit: wird von diesem Versuch nicht geladen oder ausgewertet.
- Neuronen je versteckter Schicht: 64.
- Versteckte Schichten: 1, 2 und 3.
- Seeds: 42, 43 und 44; dieselben Seeds werden für beide Losses verwendet.
- POD-Rang 10, tanh-Aktivierung, Adam, Lernrate 0,001, 200 Epochen,
  Batchgröße 32, CPU-Ausführung und letztes Trainingsmodell.
- Gesamtumfang: 2 Losses × 3 Tiefen × 3 Seeds = 18 Modellläufe.

Berichtet werden pro Modell der mittlere gewichtete absolute Feldfehler in
Metern, der Median und der Nearest-Rank-P95 des relativen gewichteten
Feldfehlers. Die drei Seeds sind Trainingswiederholungen, keine zusätzlichen
Validierungsfälle. Die Validierungsstichprobe ist klein; dieser Probelauf ist
diagnostisch und kein unabhängiger Abschlusstest.

## Ausführung und Artefakte

Start in MATLAB aus dem Ordner `Code v2`:

```matlab
addpath('examples')
result = runPodMlpLossPilot();
```

Der Runner liegt in `examples/runPodMlpLossPilot.m`. Er speichert Modelle,
`summary.csv`, fallweise Validierungsmetriken und `loss_pilot.mat` in
`experiments/pod_mlp_loss_pilot_20261107/`. Der Ausgabeordner darf noch nicht
existieren. MATLAB-Version, Einstellungen, Seeds, Trainings- und
Validierungs-IDs sowie die Kennzeichnung, dass Testdaten nicht geladen wurden,
werden in den Ergebnissen mitgespeichert.

## Ergebnisse

Durchgelaufen am 7. November 2026 mit MATLAB R2025b: alle 18 Modelle wurden
trainiert und auf denselben 12 Validierungsfällen bewertet. Kein Testsplit
wurde geladen. Alle Läufe behielten im Trainingssatz mit POD-Rang 10 praktisch
100 % der gewichteten POD-Energie.

Mittelwerte über die drei Seeds je Architektur:

| Loss | Schichten | Median relativer Fehler | P95 relativer Fehler | Mittlerer absoluter Feldfehler |
|---|---:|---:|---:|---:|
| Pro Koeffizient standardisierte MSE | 1 | 8,02 % | 47,45 % | 6,264 µm |
| Pro Koeffizient standardisierte MSE | 2 | 7,35 % | 35,05 % | 5,240 µm |
| Pro Koeffizient standardisierte MSE | 3 | 4,23 % | 64,75 % | 4,625 µm |
| Gewichtete Feld-MSE | 1 | 3,57 % | 20,60 % | 2,695 µm |
| Gewichtete Feld-MSE | 2 | **1,35 %** | **10,40 %** | **1,013 µm** |
| Gewichtete Feld-MSE | 3 | 2,20 % | 17,53 % | 1,407 µm |

Über alle neun Architektur-/Seed-Paare sank der mittlere Median relativer
Fehler von 6,54 % auf 2,37 %, der mittlere absolute Fehler von 5,376 auf
1,705 µm und der über Seeds gemittelte P95 von 49,08 % auf 16,18 %. Der
Medianfehler verbesserte sich in allen neun gepaarten Läufen; der P95 in acht
von neun (Ausnahme: 1 Schicht, Seed 42). Damit ist die Loss-Hypothese auf
diesen Validierungsdaten vielversprechend, aber nicht bewiesen: 12 Fälle sind
eine kleine Validierungsstichprobe, und bei 12 Werten entspricht Nearest-Rank-
P95 dem größten Einzelfehler. Das Ergebnis rechtfertigt einen breiteren,
vorab festgelegten Validierungsversuch, nicht die Auswahl anhand des bereits
eingesehenen Testsets.

Die komplette Seed-Tabelle steht in `pod_mlp_loss_pilot_20261107/summary.csv`;
alle Fallwerte stehen in `pod_mlp_loss_pilot_20261107/validation_case_errors.csv`.
Die gespeicherten Modelle sind in den beiden Loss-Unterordnern abgelegt.
