# Statische Modellvergleiche

Abgeleitet aus bereits gespeicherten Studien; es wurden keine FEM-Faelle neu berechnet und keine Modelle neu trainiert.

## 1. Statische Verschiebungsfelder

Fehlerwerte der gewichteten relativen Feld-L2-Norm in Prozent. Bei mehreren Seeds sind Median, P95 und Maximum jeweils der Median der seedweisen Kennzahlen; die Seed-Spanne zeigt Minimum bis Maximum der seedweisen Medianfehler. `NaN` bedeutet nicht verfuegbar/nicht berichtet.

| Modell | n | Medianfeldfehler | P95 | Maximum | Seeds | Seed-Spanne | Testfaelle/Kohorte |
|---|---:|---:|---:|---:|---:|---:|---|
| Beam_Field_POD_GPR (normalized hybrid) | 18 | 0.1072% | 0.8932% | 2.131% | 1 | - | 64 / static confirmation: 64 cases |
| Beam_theory_field | 0 | 0.6152% | 1.71% | 3.192% | 0 | - | 64 / neural comparison: 64 final cases |
| Beam_theory_field | 0 | 0.4352% | 2.154% | 2.612% | 0 | - | 64 / static confirmation: 64 cases |
| DeepONet | 12 | 45.76% | 966.5% | 966.5% | 5 | 40.43-56.62% | 6 / historical shared IDs 19-24 |
| DeepONet | 24 | 52.13% | 93.94% | 93.94% | 5 | 44.92-56.47% | 6 / historical shared IDs 19-24 |
| DeepONet | 48 | 43.26% | 61.61% | 61.61% | 5 | 38.11-52.46% | 6 / historical shared IDs 19-24 |
| DeepONet | 96 | 31.18% | 51.24% | 51.24% | 5 | 6.603-38.75% | 6 / historical shared IDs 19-24 |
| DeepONet | 192 | 10.43% | 28.16% | 28.16% | 5 | 7.951-12.28% | 6 / historical shared IDs 19-24 |
| DeepONet | 384 | 8.835% | 16.28% | 16.28% | 5 | 7.626-10.57% | 6 / historical shared IDs 19-24 |
| DeepONet | 384 | 7.461% | 33.99% | 65.55% | 5 | 6.432-9.927% | 64 / neural comparison: 64 final cases |
| Legacy_POD_GP | 384 | 0.46% | 3.032% | 16.15% | 1 | - | 64 / neural comparison: 64 final cases |
| Legacy_POD_MLP | 384 | 4.944% | 42.18% | 185.2% | 1 | - | 64 / neural comparison: 64 final cases |
| Legacy_POD_RBF | 384 | 2.805% | 14.92% | 69.15% | 1 | - | 64 / neural comparison: 64 final cases |
| Neural_pod | 12 | 37.26% | 239.9% | 403.8% | 3 | 37.02-48.97% | 64 / neural comparison: 64 final cases |
| Neural_pod | 24 | 40% | 293.3% | 780.7% | 3 | 38.92-53.78% | 64 / neural comparison: 64 final cases |
| Neural_pod | 48 | 34.37% | 438% | 1198% | 3 | 23.53-38.47% | 64 / neural comparison: 64 final cases |
| Neural_pod | 96 | 12.1% | 124.8% | 211.7% | 3 | 10.27-14.08% | 64 / neural comparison: 64 final cases |
| Neural_pod | 192 | 12.9% | 164.6% | 593.1% | 3 | 7.77-32.37% | 64 / neural comparison: 64 final cases |
| Neural_pod | 384 | 2.951% | 37.53% | 139.9% | 3 | 2.856-4.944% | 64 / neural comparison: 64 final cases |
| Neural_residual | 12 | 0.3755% | 2.706% | 5.938% | 3 | 0.3553-0.4444% | 64 / neural comparison: 64 final cases |
| Neural_residual | 24 | 0.2886% | 1.381% | 3.611% | 3 | 0.2749-0.2926% | 64 / neural comparison: 64 final cases |
| Neural_residual | 48 | 0.2005% | 1.016% | 3.103% | 3 | 0.195-0.2037% | 64 / neural comparison: 64 final cases |
| Neural_residual | 96 | 0.117% | 0.7437% | 1.429% | 3 | 0.04677-0.1984% | 64 / neural comparison: 64 final cases |
| Neural_residual | 192 | 0.04341% | 0.2324% | 0.8266% | 3 | 0.04077-0.07552% | 64 / neural comparison: 64 final cases |
| Neural_residual | 384 | 0.0345% | 0.3476% | 0.5488% | 3 | 0.03112-0.05316% | 64 / neural comparison: 64 final cases |
| POD_GP | 12 | 60.65% | 2534% | 2534% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_GP | 24 | 23.25% | 127% | 127% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_GP | 48 | 4.656% | 63.81% | 63.81% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_GP | 96 | 3.497% | 17.21% | 17.21% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_GP | 192 | 1.144% | 7.109% | 7.109% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_GP | 384 | 0.3839% | 2.682% | 2.682% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 12 | 0.05713% | 0.112% | 0.112% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 24 | 0.05808% | 0.1117% | 0.1117% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 48 | 0.05796% | 0.112% | 0.112% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 96 | 0.05711% | 0.111% | 0.111% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 192 | 0.05704% | 0.1114% | 0.1114% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_Galerkin | 384 | 0.05716% | 0.1127% | 0.1127% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 12 | 21.46% | 918.3% | 918.3% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 24 | 9.851% | 1103% | 1103% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 48 | 13.37% | 1412% | 1412% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 96 | 13.8% | 23.7% | 23.7% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 192 | 8.109% | 1385% | 1385% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_MLP | 384 | 3.314% | 22.67% | 22.67% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 12 | 23.26% | 793% | 793% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 24 | 26.31% | 91.36% | 91.36% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 48 | 18.41% | 98.93% | 98.93% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 96 | 5.406% | 76.47% | 76.47% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 192 | 3.636% | 15.89% | 15.89% | 1 | - | 6 / historical shared IDs 19-24 |
| POD_RBF | 384 | 5.459% | 12.16% | 12.16% | 1 | - | 6 / historical shared IDs 19-24 |

## 2. Statische Kennwerte

Spitzenverschiebungs-MAE in Mikrometern; diese Werte sind keine Feldfehler und separat zu lesen. `Beam_plus_GPR` bezeichnet die Balkentheorie mit skalarer GPR-Korrektur.

| Modell | n | Spitze-MAE (um) | Testfaelle/Kohorte |
|---|---:|---:|---|
| Beam_plus_GPR | 12 | 0.50678 | 6 / historical shared IDs 19-24 |
| Beam_plus_GPR | 24 | 0.135887 | 6 / historical shared IDs 19-24 |
| Beam_plus_GPR | 48 | 0.114526 | 6 / historical shared IDs 19-24 |
| Beam_plus_GPR | 96 | 0.0802199 | 6 / historical shared IDs 19-24 |
| Beam_plus_GPR | 192 | 0.0248183 | 6 / historical shared IDs 19-24 |
| Beam_plus_GPR | 384 | 0.00767443 | 6 / historical shared IDs 19-24 |
| Beam_theory | 0 | 0.453303 | 6 / historical shared IDs 19-24 |
| Beam_theory | 0 | 0.500179 | 64 / static confirmation: 64 cases |
| Scalar_GPR | 12 | 110.281 | 6 / historical shared IDs 19-24 |
| Scalar_GPR | 24 | 39.5396 | 6 / historical shared IDs 19-24 |
| Scalar_GPR | 48 | 19.1077 | 6 / historical shared IDs 19-24 |
| Scalar_GPR | 96 | 4.08488 | 6 / historical shared IDs 19-24 |
| Scalar_GPR | 192 | 3.33496 | 6 / historical shared IDs 19-24 |
| Scalar_GPR | 384 | 0.728552 | 6 / historical shared IDs 19-24 |

## Vergleichbarkeit und Herkunft

Die Tabellen bewahren die Testkohorte jeder Zahl. Die bekannten Testfaelle 19-24, die 64 neuralen Finalfaelle und die 64 Faelle der statischen Bestaetigungsstudie sind unterschiedliche Kohorten. Werte aus verschiedenen Kohorten sind daher keine gepaarte Rangliste. Die neuen 64-Fall-Modelle und ihre eingefrorenen Referenzen teilen dagegen dieselbe Testkohorte. Das Beam_Field_POD_GPR-Ergebnis ist die naechstliegende eingefrorene normalisierte Hybridvariante, nicht die Behauptung identischer Artefakte.

CSV-Spalten `Source` und `Notes` enthalten die jeweiligen Quelldateien und Details.
