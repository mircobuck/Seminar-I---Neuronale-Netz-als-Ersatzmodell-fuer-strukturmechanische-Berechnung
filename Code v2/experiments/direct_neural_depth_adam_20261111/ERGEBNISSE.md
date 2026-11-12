# MLP/RBF Adam-Tiefenstudie

18 Trainingslaeufe abgeschlossen.

768 Trainingsfaelle, 128 bereits verwendete Validierungsfaelle, Seeds 42/43/44.
64 Einheiten pro Schicht; Adam, 200 Epochen, Lernrate 0.001, Batch 32.

| Methode | Schichten | Mittelwert | Median | P95 | Maximum |
|---|---:|---:|---:|---:|---:|
| MLP | 2 | 12.022 % | 5.950 % | 42.153 % | 229.585 % |
| MLP | 3 | 12.465 % | 7.247 % | 37.179 % | 283.461 % |
| MLP | 1 | 19.649 % | 6.951 % | 70.230 % | 444.148 % |
| RBF | 3 | 24.538 % | 11.010 % | 88.556 % | 490.568 % |
| RBF | 2 | 65.513 % | 19.577 % | 354.968 % | 755.045 % |
| RBF | 1 | 160.802 % | 54.880 % | 645.238 % | 1749.314 % |

Mittelwert, Median und P95 werden zuerst pro Seed ueber Faelle berechnet,
danach ueber drei Seeds gemittelt. Maximum ist der groesste Fallfehler aller Seeds.
RBF zaehlt eine feste Gauss-Schicht plus 0/1/2 tanh-Schichten; MLP zaehlt nur tanh-Schichten.
Die Ausgabe ist jeweils linear. Trainiert wird standardisierte Ausgabe-MSE.
Dies ist eine explorative Modellwahl auf wiederverwendeter Validierung, kein Abschlusstest.

## Maximale Auslenkung

Maximum des Betrags sqrt(ux^2+uy^2+uz^2) ueber 525 Gitterpunkte, 128 Validierungsfaelle und drei Seeds. Werte in mm. Die Maxima sind keine Fehlerkennzahl und koennen bei unterschiedlichen Faellen auftreten.

| Methode | Schichten | Vorhersage maximal [mm] | FEM maximal [mm] |
|---|---:|---:|---:|
| MLP | 1 | 0,7469 | 0,8973 |
| MLP | 2 | 0,7977 | 0,8973 |
| MLP | 3 | 0,8319 | 0,8973 |
| RBF | 1 | 0,3220 | 0,8973 |
| RBF | 2 | 0,7070 | 0,8973 |
| RBF | 3 | 0,8773 | 0,8973 |

Alle 18 Modelle und 2304 Fallfehler vorhanden. Mittelwert, Median, P95 und Maximum der CSV-Ausgaben wurden unabhaengig mit PowerShell nachgerechnet: bestanden. Vergleichsplot visuell geprueft. 27 Integrationstests vor Studienstart bestanden.

