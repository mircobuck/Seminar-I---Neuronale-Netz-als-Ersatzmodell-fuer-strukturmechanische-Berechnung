# Versuchsverlauf

## 23.10.2026 – Klassischer POD-Galerkin-ROM, alle sechs Trainingsgrößen

Gemeinsamer quadratischer FEM-Raum, unzentrierte nodale POD und mechanische
Galerkin-Koeffizienten implementiert. 396 zusätzliche FEM-Snapshots berechnet;
gleiche physikalische Fälle und IDs wie bei KI, anderes fest abgebildetes Netz.
Ränge 1/2/4/8/11 auf Validierung untersucht; gewählt 8/11/11/8/8/8 für
N=12/24/48/96/192/384. Alle sechs Größen getestet, KI nur erneut ausgewertet.

ROM-Feldmedian etwa 0,057–0,058 %, Maximum etwa 0,111–0,113 %.
Online inklusive Assemblierung etwa 0,90–0,93 s; KI-Inferenz erheblich schneller.
Gemeinsame Voll-FEM: 1,19 s. Daten- und Modellschutz: 1084 Dateien unverändert.
Freies Residuum maximal 32,96 %, projiziertes Residuum maximal 4,65e-11;
diese Größen sind ausdrücklich getrennt zu bewerten.

[Vollständiger Bericht, Prüfungen, Kosten und Diagramme](experiments/pod_galerkin_20261023_v1/REPORT.md).

## 23.10.2026 – Anschlussverdopplung 192 → 384

192 weitere FEM-Trainingsfälle, fünf neue Modelle und gleiche Validierungs-/
Testfälle. Physik und Suchraum unverändert. Alle Stufen erfolgreich.
POD_GP: Median 0,384 %, Maximum/P95 2,682 %; damit erstmals beide Arbeitsziele
auf dem festen Vergleichssatz erfüllt. RBF-Median schlechter (5,459 %),
MLP-Median besser (3,314 %); MLP-Maximum sinkt auf 22,672 %.
Frühere Daten und Modelle per Hash unverändert, kein Pilot-Lauf.
[Aktueller Bericht und Nachweise](experiments/training_size_12_24_48_20261023/RESULTS_384.md).

## 23.10.2026 – Anschlussverdopplung 96 → 192

96 weitere Trainingsfälle ergänzt, fünf neue Modelle trainiert und getestet.
Validierung/Test, Physik und Suchraum bleiben gleich. POD_GP-Median 3,50 → 1,14 %,
RBF 5,41 → 3,64 %, MLP 13,80 → 8,11 %. MLP-Maximum verschlechtert sich allerdings
von 23,70 auf 1384,94 %. Feldziele weiterhin nicht erreicht.

Frühere Daten und Modelle per Hash unverändert. Kein Pilot-Lauf.
[Aktueller Gesamtvergleich und Protokoll](experiments/training_size_12_24_48_20261023/RESULTS_192.md).

## 23.10.2026 – Trainingsmenge 12 → 24 → 48 → 96

Auftrag: Einfluss der Trainingsmenge nachvollziehbar untersuchen; anschließend
auf Nutzerwunsch die Stufe 96 ergänzen. Alle Stufen tatsächlich durchgeführt.

Geändert: verschachtelte Trainingsmenge. Konstant: sechs Validierungs- und sechs
Testfälle, Physik, Netz, Modell-Seed und wirksamer Hyperparameter-Suchraum.
Modelle werden pro Stufe neu trainiert; ihre Auswahl erfolgt über Validierung.
Die 96er-Erweiterung wurde nach Sichtung der vorherigen Ergebnisse beauftragt.

Ergebnis: POD_GP-Median 60,65 → 23,25 → 4,66 → 3,50 %.
RBF und MLP reagieren nicht monoton. Bei n96 sinkt der maximale MLP-Feldfehler
auf 23,70 %, während sein Median bei 13,80 % bleibt. Beide Skalarmodelle
verbessern sich bei jeder Verdopplung. Feldgenauigkeitsziele nicht erreicht.

[Vollständiges Protokoll, Resultate und Nachweise](experiments/training_size_12_24_48_20261023/RESULTS.md).

84 neue FEM-Fälle; bestehende Daten und Modelle unverändert, kein Pilot-Lauf.
Für weitere Versuche zuerst Änderung, konstante Größen, Seeds und Datenaufteilung
festhalten und eigene Ausgabeordner nutzen. Frühere Modelle erhalten.


## DeepONet-Vergleich: Abschluss 25.10.2026

Genau eine neue Architekturklasse: parametrische Mehrkomponenten-DeepONet-Adaption.
Trainings-IDs exakt wie bisher, verschachtelte Mengen; Validierung 13-18 und Test 19-24.
Keine neuen FEM-Labels. Zwei Validierungskandidaten je N, Seed 42;
Gewinner plus Seeds 43-46. 36 regulaere Fits, 30 finale Modelle.
Test erst nach Einfrieren aller finalen Modelle ausgewertet; keine Test-Seed-Auswahl.

| N | DeepONet Seed-Median [%] | Seed-Spanne [%] | POD-GPR [%] |
|---:|---:|---:|---:|
| 12 | 45.7556 | 40.4299 - 56.6175 | 60.6522 |
| 24 | 52.1300 | 44.9195 - 56.4652 | 23.2465 |
| 48 | 43.2597 | 38.1102 - 52.4593 | 4.6562 |
| 96 | 31.1770 | 6.6032 - 38.7532 | 3.4969 |
| 192 | 10.4295 | 7.9507 - 12.2774 | 1.1444 |
| 384 | 8.8350 | 7.6265 - 10.5685 | 0.3839 |

Die Anfangsversionen verwenden direkte Differenzierung, die letzten fuenf
384er-Fits dlaccelerate nach Profiling und nachgewiesener exakter Gradienten-
und Verlustgleichheit am Benchmark. Architektur, Verlust und Budget unveraendert.
Unterbrechungen, Zeitmessungen, Auswahl, Fehler und Modellstaende sind protokolliert.
Vollstaendige Bewertung, Streuungen, Grenzen und Reproduktion:
[Bericht](experiments/deeponet_20261023_v1/REPORT.md).
Alte Baselines nicht nachtrainiert; pilot nicht gestartet.
