# Vollständiger POD-MLP-Lossvergleich

## Ziel

Die im Probelauf vielversprechende `weighted_field_mse` wird über denselben
Architektur- und Trainingsgrößenplan wie die bestehende
`per_coefficient_mse`-Studie verglichen. Die Loss ist eine MSE auf POD-
Koeffizienten mit gemeinsamer Trainings-RMS-Skalierung. Wegen der gewichteten
Orthonormalität der POD-Basis ist sie proportional zum quadrierten gewichteten
Feldfehler.

Mathematisch gilt für die aus gewichteter SVD erzeugte Basis `Phi`:
`Phi' * W * Phi = I`. Daher ist bei zwei Koeffizientenvektoren `c` und `c_hat`
der quadratische gewichtete Feldfehler
`||Phi*c_hat - Phi*c||_W^2 = sum((c_hat-c).^2)`. Die neue Loss berechnet die
mittlere quadratische Abweichung der Koeffizienten, nachdem alle Ausgänge mit
derselben positiven RMS-Skala aus dem Trainingssatz geteilt wurden. MSE mittelt
zusätzlich über die Anzahl POD-Moden; das ist ein weiterer konstanter Faktor
und ändert das Optimierungsziel nicht. Die bisherige Loss skaliert dagegen
jeden Modus mit seiner eigenen Standardabweichung und verändert damit seine
relative Gewichtung.

Die Skalierung wird nur aus Trainingskoeffizienten berechnet. Validierungsdaten
werden ausschließlich zur Modellbewertung verwendet.

Der Probelauf hat dieselben zwölf Validierungsfälle bereits zum Vergleichen
der Losses verwendet. Deshalb ist auch diese größere Studie auf denselben
Validierungsfällen explorativ und nicht unabhängig. Ihre Resultate beantworten
die Vergleichsfrage unter kontrollierten Bedingungen, beweisen aber keine
allgemeine Verbesserung. Der vorher eingesehene Testsplit wird nicht erneut
für die neue Loss verwendet.

## Versuchsplan

| Merkmal | Werte |
|---|---|
| Loss | `weighted_field_mse` |
| Neuronen je versteckter Schicht | 64, 128 |
| Versteckte Schichten | 1, 2, 3, 4, 5 |
| Trainingsfälle | 12, 24, 48, 96, 192, 384, 768 |
| Seeds | 42, 43, 44 |
| Modellläufe | 2 × 5 × 7 × 3 = 210 |
| Validierung | dieselben 12 statischen Fälle |
| Testdaten | werden vom Runner nicht geladen |

Für jeden Seed sind die Trainingsmengen verschachtelt. Die ersten 384 IDs
verwenden dieselbe seeded Permutation wie die vorherige Studie; für 768 Fälle
kommen die übrigen 384 IDs in einer zusätzlichen seeded Permutation dazu.
Dieselbe Auswahl wird für alle Breiten und Tiefen wiederverwendet.

Die drei Seeds sind gepaarte Wiederholungen derselben vorgegebenen
Trainingsfall-Auswahl und Initialisierungsseeds. Bei Adam, Initialisierung und
Mini-Batch-Reihenfolge bleiben die Seeds gleich; der gezielte Unterschied
zwischen den verglichenen historischen und neuen Läufen ist die
Zielkoeffizienten-Skalierung/Loss. Die historische Studie wird nicht erneut
trainiert, sondern aus ihrer vorhandenen aggregierten CSV als Referenz gelesen.

Konstant gehalten werden POD-Rang 10, tanh, Adam, Lernrate 0,001, 200 Epochen,
Batchgröße `min(32, Trainingsfallzahl)`, CPU und die letzte Trainingsiteration.
Pro Lauf werden die POD-Basis und Eingabe-/Koeffizientenmittelwerte allein aus
der jeweiligen Trainingsmenge bestimmt.

Die neue Loss verwendet weiterhin MATLABs eingebaute `trainnet(...,"mse",...)`;
es ist keine eigene Gradientenfunktion nötig. Geändert wird die
Koeffizienten-Normierung, die bestimmt, welche Fehler die MSE gewichtet.

Der Vergleichsrunner verbindet die neue Studie anhand von Breite, Tiefe und
Fallzahl mit der bestehenden aggregierten Auswertung
`learning_curve_metrics_12_to_768_widths_1to5.csv`. Die alte und neue Tabelle
verwenden jeweils den Median über drei Seed-Metriken; Seed-Runs werden nie als
zusätzliche Fälle gezählt. Der alte Datensatz ist als historischer
Referenzwert ausgewiesen, nicht neu trainiert.

## Ausführung und Artefakte

Aus MATLAB R2025b im Ordner `Code v2` starten:

```matlab
addpath('examples')
result = runPodMlpLossStudy();
```

Der Runner liegt in `examples/runPodMlpLossStudy.m`. Standardmäßig schreibt er
nach `experiments/pod_mlp_loss_study_20261107/`. Der Lauf kann bei
Unterbrechung mit demselben Ausgabeordner fortgesetzt werden. Konfiguration
sowie Trainings-/Validierungs-IDs werden vor den Läufen gespeichert; pro
Modell werden Artefakt, Seed-Metriken und Fallfehler fortlaufend gesichert.
Ein vorhandener Ordner wird nur mit passender gespeicherter
Studienkonfiguration fortgesetzt.

Die Konfiguration enthält MATLAB-Version, Datasetkennung, vollständige
Trainings- und Validierungs-IDs, Breiten, Tiefen, Fallzahlen, Seeds und
Optimierungseinstellungen. Vorhandene Modelle werden nur wiederverwendet,
wenn Konfiguration und Trainings-IDs exakt zum jeweiligen Lauf passen.

Ergebnisdateien:

- `summary_runs.csv`: eine Zeile pro Modell/Seed.
- `summary_by_architecture.csv`: Median, Minimum und Maximum über Seeds je
  Breite, Tiefe und Trainingsfallzahl.
- `comparison_old_vs_weighted_loss.csv`: Vergleich zur bisherigen Loss und
  Differenzen (positive Verbesserung bedeutet geringeren Fehler bei neuer
  Loss).
- `validation_case_errors.csv`: Fallmetriken auf dem Validierungssplit.
- `models/`: trainierte Gewichte pro Modelllauf.
- `study_config.mat`, `loss_study_results.mat`: Studienstand und Ergebnisse.

## Ergebnisse

Abgeschlossen am 8. November 2026 mit MATLAB R2025b: alle 210 Modelle wurden
trainiert. Es entstanden 2.520 fallweise Metrikzeilen (210 Modellläufe × 12
Validierungsfälle). Kein Testsplit wurde geladen.

Die Tabelle vergleicht pro Trainingsfallzahl den Durchschnitt über die zehn
Kombinationen aus Breite und Tiefe der jeweiligen Kennzahl, die zuvor je
Kombination über drei Seeds aggregiert wurde. „Besser“ zählt, in wie vielen
der zehn Kombinationen der neue Medianfehler unter dem alten lag.

| Trainingsfälle | Medianfehler alt | Medianfehler neue Loss | Kombinationen mit besserem Median | P95 alt | P95 neue Loss |
|---:|---:|---:|---:|---:|---:|
| 12 | 28,49 % | 29,41 % | 5/10 | 344,41 % | 230,37 % |
| 24 | 37,48 % | 45,76 % | 2/10 | 391,76 % | 295,43 % |
| 48 | 39,86 % | 27,22 % | 10/10 | 377,88 % | 280,31 % |
| 96 | 28,87 % | 20,52 % | 10/10 | 151,86 % | 159,59 % |
| 192 | 20,53 % | 9,92 % | 8/10 | 127,15 % | 59,30 % |
| 384 | 11,43 % | 4,71 % | 10/10 | 97,62 % | 21,43 % |
| 768 | 7,78 % | 2,66 % | 10/10 | 41,58 % | 13,95 % |

Über alle 70 Kombinationen war der Medianfehler in 55/70, der mittlere
absolute Feldfehler in 60/70 und der P95 in 57/70 Kombinationen niedriger.
Der stärkste und konsistenteste Gewinn zeigt sich ab 48 Trainingsfällen;
bei 12 und 24 Fällen wird der Median im Durchschnitt schlechter, obwohl der
P95 im Durchschnitt sinkt. Bei 96 Fällen verbessert sich der Median, während
der P95 leicht ansteigt.

**Fazit:** Die neue Loss ist für mittlere und große Trainingsmengen sehr
vielversprechend und verbessert häufig sowohl typische als auch hohe Fehler.
Sie ist aber kein universeller Gewinn, besonders bei sehr kleinen
Trainingsmengen. Der P95 ist bei nur zwölf Validierungsfällen gleich dem
größten Einzelfehler und damit stark schwankungsanfällig. Außerdem wurden
dieselben Validierungsfälle bereits für den vorherigen Loss-Probelauf
angesehen; diese Vollstudie ist daher explorativ, nicht unabhängig. Der zuvor
eingesehene Testsplit wurde nicht erneut verwendet.

Die vollständigen Ergebnisse stehen in `pod_mlp_loss_study_20261107/`:
`summary_runs.csv` enthält alle Seeds, `summary_by_architecture.csv` die
Seed-Aggregate und `comparison_old_vs_weighted_loss.csv` den direkten
historischen Vergleich. `validation_case_errors.csv` enthält alle 2.520
fallweisen Fehler. Die 210 Modellartefakte liegen unter `models/`.

## Frischer Validierungsvergleich auf 12 neuen FEM-Fällen

Am 8. November 2026 wurden die beiden Loss-Varianten zusätzlich auf zwölf
neuen statischen Validierungsfällen verglichen. Vor der Berechnung der neuen
FEM-Referenzen wurden alle 420 gespeicherten Modelle geladen, hinsichtlich
Architektur, Loss und paarweise identischer Trainingsfall-IDs geprüft und
per SHA-256 eingefroren. Kein Modell wurde neu trainiert; Testdaten wurden
nicht geladen.

Der neue Latin-Hypercube-Entwurf verwendet Seed `20261108` und IDs 812001 bis
812012. Alle zwölf Zeilen sind dem Validierungssplit zugeordnet; der statische
FEM-Lauf hat genau diese zwölf Fälle berechnet. Der allgemeine Design-Schritt
legt zusätzlich eine modale Design-CSV mit Konfigurations-Standardwerten an,
hat dafür aber keine modalen FEM-Referenzen berechnet. Die Ergebnisprüfung
bestätigte 420 Freeze- und Modellzeilen, 5.040 fallweise Zeilen, 70
Architekturvergleiche und sieben aggregierte Trainingsgrößen.

Die Tabelle fasst pro Trainingsgröße den Durchschnitt über zehn Breiten-/
Tiefenkombinationen zusammen. Innerhalb jeder Kombination wurde zuerst der
Median über drei Seeds gebildet. Fehlerwerte sind gewichtete Feldfehler;
relative Werte sind Prozent. Ein niedrigerer Wert ist besser.

| Trainingsfälle | Median alt | Median neue Loss | Architekturen mit besserem Median | P95 alt | P95 neue Loss | Architekturen mit besserem P95 | Absolutfehler alt [m] | Absolutfehler neue Loss [m] |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 12  | 48,72 % | 54,84 % | 2/10  | 944,63 % | 884,02 % | 5/10 | 6,1768e-5 | 5,6324e-5 |
| 24  | 49,82 % | 41,31 % | 7/10  | 1.396,20 % | 1.719,30 % | 2/10 | 5,5592e-5 | 5,2635e-5 |
| 48  | 46,79 % | 44,02 % | 6/10  | 1.025,80 % | 1.316,30 % | 4/10 | 5,1651e-5 | 4,8630e-5 |
| 96  | 39,32 % | 29,50 % | 10/10 | 467,84 % | 423,47 % | 4/10 | 4,0206e-5 | 3,2212e-5 |
| 192 | 27,72 % | 13,07 % | 10/10 | 263,16 % | 182,56 % | 9/10 | 2,6245e-5 | 1,4455e-5 |
| 384 | 15,81 % | 6,87 %  | 10/10 | 106,42 % | 52,63 % | 8/10 | 1,8016e-5 | 8,8131e-6 |
| 768 | 13,07 % | 4,35 %  | 10/10 | 86,05 % | 29,88 % | 8/10 | 1,5339e-5 | 5,5437e-6 |

Über alle 70 Kombinationen war der Median der neuen Loss in 55/70, der P95 in
40/70 und der mittlere absolute Fehler in 67/70 Kombinationen niedriger.
Besonders ab 96 Trainingsfällen ist der Mediangewinn konsistent; bei 12
Fällen ist der durchschnittliche Median schlechter, und bei 24/48 Fällen
verschlechtert sich der P95 im Mittel. Die neue Loss ist daher auch auf den
frischen Fällen nicht für jede Kennzahl und jede Trainingsgröße überlegen,
zeigt aber klare Vorteile bei typischen Fehlern und absoluten Feldfehlern für
größere Trainingsmengen.

Der P95 ist bei nur zwölf Validierungsfällen der größte Einzelfehler
(Nearest-Rank). Relative Fehler reagieren zudem stark auf Fälle mit kleiner
Referenznorm, da die Metrik hier vorab mit Referenzschwelle 0 berechnet wurde.
Die zwölf Fälle sind unabhängige Validierungsfälle gegenüber den früher
verwendeten Labels, aber kein unangetasteter finaler Testsatz, sobald diese
Ergebnisse zur Auswahl oder Abstimmung herangezogen werden.

Alle Daten, Modellhashes und Ergebnis-CSV-Dateien liegen unter
`experiments/pod_mlp_fresh_validation_20261108/`; Ausführungsdetails stehen
in `studies/static_final_evaluation/README.md`.

## Erweiterte Prüfung auf 128 neuen Validierungsfällen

Am 8. November 2026 wurde derselbe gepaarte Vergleich auf 128 weiteren
statischen FEM-Fällen wiederholt. Verwendet wurden Seed `20261109` und IDs
813001–813128. Vor der Berechnung wurden die gleichen 420 Modelle erneut
geprüft und gehasht. Es gab weder ID- noch exakte Parameterzeilen-
Überschneidungen mit den bekannten Designs. Es wurden nur statische
Validierungsreferenzen gerechnet; kein Modell wurde trainiert und keine
Testlabels wurden geladen. Die Prüfung bestätigte 128 Fälle, 420 Modellläufe,
53.760 Modell-Fall-Zeilen und 70 Architektur-/Trainingsmengenvergleiche.

Die folgende Tabelle zeigt je Trainingsgröße den Durchschnitt über zehn
Breiten-/Tiefenkombinationen. Pro Kombination wird zuerst der Median über
drei Seeds gebildet. Bei den 128 Fällen ist der Nearest-Rank-P95 der
122. sortierte Fallfehler.

| Trainingsfälle | Median alt → neu | Architekturen mit besserem Median | P95 alt → neu | Architekturen mit besserem P95 | Absolutfehler alt → neu [m] | Architekturen mit besserem Absolutfehler |
|---:|---:|---:|---:|---:|---:|---:|
| 12  | 49,51 % → 38,72 % | 10/10 | 358,13 % → 404,05 % | 5/10  | 3,8649e-5 → 3,1157e-5 | 10/10 |
| 24  | 40,06 % → 36,73 % | 8/10  | 596,70 % → 496,26 % | 8/10  | 3,1873e-5 → 2,9234e-5 | 8/10 |
| 48  | 39,24 % → 30,31 % | 9/10  | 726,52 % → 573,66 % | 9/10  | 3,1257e-5 → 2,6494e-5 | 10/10 |
| 96  | 28,18 % → 20,12 % | 10/10 | 378,64 % → 286,72 % | 10/10 | 2,1985e-5 → 1,7090e-5 | 9/10 |
| 192 | 21,65 % → 11,14 % | 10/10 | 242,44 % → 144,15 % | 9/10  | 1,5957e-5 → 8,6750e-6 | 10/10 |
| 384 | 13,74 % → 5,94 %  | 10/10 | 115,25 % → 49,35 %  | 10/10 | 1,0044e-5 → 4,2787e-6 | 10/10 |
| 768 | 9,52 % → 3,49 %   | 10/10 | 74,43 % → 26,77 %   | 10/10 | 6,8551e-6 → 2,4889e-6 | 10/10 |

Über alle 70 Kombinationen verbesserte `weighted_field_mse` den Median in
67/70, den P95 in 61/70 und den mittleren absoluten Feldfehler in 67/70
Kombinationen. Anders als in der 12-Fall-Stichprobe zeigt sich beim P95 damit
ebenfalls ein klar überwiegender Vorteil; bei 12 Trainingsfällen ist der
aggregierte P95 allerdings weiterhin höher. Bei Trainingsmengen ab 96 war
der Median in allen zehn Architekturen besser; ab 96 war auch der P95 in
mindestens neun von zehn Architekturen besser.

Für **128 Neuronen je Schicht und 384 Trainingsfälle** waren auf diesen 128
Fällen Median und P95 der neuen Loss bei allen fünf Tiefen niedriger:

| Versteckte Schichten | Median alt → neu | P95 alt → neu |
|---:|---:|---:|
| 1 | 16,85 % → 11,30 % | 208,79 % → 101,17 % |
| 2 | 14,26 % → 2,54 %  | 138,91 % → 24,16 % |
| 3 | 13,97 % → 4,13 %  | 89,26 % → 31,05 % |
| 4 | 12,17 % → 5,35 %  | 68,51 % → 22,06 % |
| 5 | 9,18 % → 5,97 %   | 51,18 % → 47,02 % |

Das ist ein deutlich konsistenteres Signal zugunsten der neuen Loss als die
vorangegangenen zwölf Fälle. Es beweist aber nicht, dass die Loss in jeder
anderen Datenverteilung überlegen ist. Auch eine größere Breite liefert
keinen einheitlichen Vorteil: Bei 384 Trainingsfällen und neuer Loss waren
128 Neuronen gegenüber 64 Neuronen bei den fünf Tiefen in Median und P95 in
drei Fällen besser und in zwei schlechter. Für Breite 64 war Tiefe 3 am
besten nach Median/P95, für Breite 128 Tiefe 2; eine universelle beste
Netzgröße ist damit weiterhin nicht belegt.

Die 128 Fälle sind nun eine größere, unabhängige Validierungsstichprobe
gegenüber den vorherigen Designs, aber nach Sichtung nicht mehr als
unangetasteter finaler Testsatz zu verwenden. Ergebnisse, Freeze und FEM-
Referenzen liegen in `experiments/pod_mlp_fresh_validation_128_20261108/`.

## Zwischenfazit zu Netzgröße und Loss

Die Untersuchung mit 128 neuen Validierungsfällen stützt klar, dass
`weighted_field_mse` im untersuchten Aufbau im Allgemeinen besser abschneidet
als `per_coefficient_mse`: Über 70 Architektur-/Trainingsgrößen-
Kombinationen war der Medianfehler in 67, der P95 in 61 und der mittlere
absolute Feldfehler in 67 Kombinationen niedriger. Das ist ein deutlicher
empirischer Vorteil auf den hier untersuchten Daten, jedoch keine Garantie für
beliebige Datenverteilungen oder Konfigurationen.

Für eine generelle Vergrößerung des Netzes gibt es dagegen keinen vergleichbar
konsistenten Hinweis. Mehr Neuronen oder mehr Schichten führen nicht
zuverlässig zu niedrigeren Fehlern. Zum Beispiel war bei 768 Trainingsfällen
und neuer Loss die Breite 64 bei 2 Schichten besser als 128 Neuronen beim
Median; bei 3 Schichten lag 64 ebenfalls vor 128. Für Breite 128 hatte 2
Schichten den niedrigsten Median, während 4 Schichten einen ähnlich niedrigen
Wert und 3 bzw. 5 Schichten höhere Werte ergaben. Bei 384 Trainingsfällen
und 128 Neuronen war die neue Loss zwar für alle fünf Tiefen besser als die
alte, aber die optimale Tiefe hing von der Kennzahl ab. Damit ist mehr
Kapazität nicht als eigenständige Verbesserung belegt; einzelne größere
Varianten können dennoch gut abschneiden.

**Arbeitsfazit:** Die neue Loss ist die bevorzugte Variante für den nächsten
Studienabschnitt. Die Netzgröße sollte nicht allein aufgrund der Annahme
„größer ist besser“ erhöht werden. Eine konkrete Architektur ist anhand einer
vorab festgelegten Hauptmetrik auszuwählen und danach auf einem separaten,
unangetasteten Testsatz zu prüfen. Die 128 neuen Fälle wurden bereits zur
Analyse verwendet und sind dafür nicht mehr unabhängig.

## Optimizer-Pilot: Adam, RMSProp und SGDM

Als nächster explorativer Schritt wird die neue Loss `weighted_field_mse`
beibehalten. Verglichen werden Adam, RMSProp und SGDM bei 128 Neuronen sowie
1 und 2 versteckten Schichten, mit 768 Trainingsfällen und Seeds 42/43/44.
Adam wird durch die bereits trainierten gewichteten Modelle kontrolliert;
RMSProp und SGDM werden für insgesamt 12 Modellläufe neu trainiert (2
Optimizer × 2 Tiefen × 3 Seeds). Alle drei Verfahren verwenden pro Seed
dieselben Trainingsfall-IDs und werden auf denselben 128 Validierungsfällen
ausgewertet.

Konstant bleiben `tanh`, POD-Rang 10, Lernrate 0,001, Batchgröße 32, 200
Epochen, CPU und die letzte Epoche. Adam-Kontrollen werden vor den neuen
Trainingsläufen auf Einstellungen/Trainings-IDs geprüft und gehasht.
RMSProp/SGDM verwenden MATLABs jeweilige Standardwerte zusätzlicher
Optimizerparameter; es wird in diesem Pilot keine individuelle
Hyperparameteroptimierung durchgeführt. Der Vergleich isoliert daher den
Effekt des Verfahrens bei gleichen allgemeinen Einstellungen, nicht die
optimale erreichbare Leistung jedes Verfahrens. Die 128 Validierungsfälle
wurden bereits in vorherigen Studien betrachtet; auch dieser Pilot bleibt
explorativ und ist keine unabhängige Abschlussprüfung.

Runner und ausführliche Methodik: `studies/static_final_evaluation/README.md`
und `studies/static_final_evaluation/runPodMlpOptimizerPilot.m`.

### Ergebnisse

Der Pilot wurde am 8. November 2026 abgeschlossen. Es wurden zwölf neue
Modelle trainiert (RMSProp und SGDM × zwei Tiefen × drei Seeds); die sechs
Adam-Kontrollen wurden aus der bestehenden gewichteten Loss-Studie geladen.
Damit umfasst die Auswertung 18 Modell-/Seed-Zeilen und 2.304
Modell-/Validierungsfall-Zeilen. Die Adam-Kontrollen wurden vor dem Training
gehasht; alle drei Verfahren verwendeten dieselben Trainings-IDs und
Validierungsfälle.

| Optimizer | Versteckte Schichten | Mittlerer absoluter Fehler [m] | Median relativer Fehler | P95 relativer Fehler |
|---|---:|---:|---:|---:|
| Adam | 1 | 4,80e-6 | 6,67 % | 55,74 % |
| RMSProp | 1 | 6,25e-6 | 9,56 % | 63,05 % |
| SGDM | 1 | 2,54e-5 | 31,63 % | 567,42 % |
| Adam | 2 | 1,71e-6 | 2,00 % | 15,13 % |
| RMSProp | 2 | 5,87e-6 | 11,12 % | 68,49 % |
| SGDM | 2 | 1,04e-5 | 13,67 % | 147,79 % |

Die drei Kennzahlen sind jeweils über die Seeds aggregiert: der Mittelwert
des absoluten Fehlers sowie Median und Nearest-Rank-P95 des relativen Fehlers
pro Modell werden zunächst berechnet und danach über Seeds mit dem Median
zusammengefasst. Adam war in beiden Tiefen bei allen drei Kennzahlen besser
als RMSProp und SGDM. Der Abstand war besonders groß für SGDM mit einer
versteckten Schicht.

**Fazit für diesen Pilot:** Mit der unveränderten Lernrate 0,001, 200 Epochen
und den Standardwerten der Optimizer-Parameter war Adam klar am besten.
RMSProp und SGDM sollten daher nicht ohne gesonderte Hyperparameterabstimmung
als Ersatz übernommen werden. Der Pilot vergleicht die Verfahren bei gleichen
allgemeinen Einstellungen; er zeigt nicht ihre jeweils optimal erreichbare
Leistung. Außerdem wurden die 128 Validierungsfälle bereits für frühere
Vergleiche verwendet. Diese Ergebnisse sind explorativ und nicht unabhängig.

Vollständige Modelle, Fallfehler, Konfiguration und Hashmanifest liegen unter
`experiments/pod_mlp_optimizer_pilot_20261108_v2/`.

### Festlegung für die nächste Studienphase

Für den nächsten Schritt bleibt Adam der Optimizer. Die belastbare Aussage
aus dem bisherigen Pilot ist ausdrücklich auf gleiche Grundeinstellungen
beschränkt: Bei Lernrate 0,001, 200 Epochen und den jeweils verwendeten
Standardwerten war Adam in den getesteten 1- und 2-Schicht-Netzen besser als
RMSProp und SGDM. Daraus folgt nicht, dass Adam nach individueller Abstimmung
jedem anderen Optimizer überlegen wäre.

Die nächste Untersuchung optimiert daher Adam selbst, ohne gleichzeitig
Optimizer, Loss, Aktivierung und Architektur zu wechseln. Die bevorzugte
`weighted_field_mse`, `tanh` und Adam bleiben gesetzt. Als erste
Trainingsparameter sollen Lernrate und Lernratenplan systematisch variiert
werden; die übrigen Einstellungen und Fall-IDs werden je Vergleich
konstant gehalten. Auswahl und Kennzahlen sind vor dem nächsten Lauf
festzulegen. Da die bisherigen zwölf und 128 neuen Validierungsfälle bereits
für Modellvergleiche verwendet wurden, dienen sie höchstens der explorativen
Entwicklung und nicht als unangetasteter Abschlusstest.

### Adam-Lernratenpilot

Der erste Optimierungsschritt ist ein fester Lernratenvergleich ohne
Lernratenplan. Verglichen werden `1e-4`, `3e-4`, `1e-3`, `3e-3` und `1e-2`
für Breite 128, Tiefen 1/2, 768 Trainingsfälle und Seeds 42/43/44. Die neue
Loss, `tanh`, Adam, 200 Epochen, Batchgröße 32, POD-Rang 10, CPU und
Trainingsfall-IDs je Seed bleiben gleich. Alle Modelle werden auf denselben
128 Validierungsfällen bewertet. Die sechs Modelle bei `1e-3` liegen bereits
vor und werden nach Hash-/Konfigurationsprüfung als Kontrolle wiederverwendet;
24 Modelle mit den anderen Lernraten werden neu trainiert.

Die Hauptkennzahl ist der mittlere absolute gewichtete Feldfehler.
Median und Nearest-Rank-P95 des relativen Feldfehlers sind ergänzende
Kennzahlen. Zunächst werden jeweils die Metriken pro Modelllauf berechnet,
danach wird der Median über die drei Seeds gebildet. Die Laufkonfiguration,
Trainings- und Validierungs-IDs, Hashes der Adam-Kontrollen und Ergebnisse
werden im Ausgabeordner gespeichert; nach jedem Modell wird ein Checkpoint
geschrieben. Ein passender Ordner kann bei Unterbrechung fortgesetzt werden.

Dieser Pilot sucht eine feste Lernrate innerhalb des getesteten Bereichs für
die untersuchte Konfiguration. Er testet noch keine Lernratenpläne und
begründet keine universelle optimale Lernrate. Da die 128 Validierungsfälle
bereits zuvor betrachtet wurden, bleibt auch dieser Schritt explorativ.
Runner und detaillierte Anleitung:
`studies/static_final_evaluation/runPodMlpLearningRateStudy.m` und
`studies/static_final_evaluation/README.md`.

### Ergebnisse des Adam-Lernratenpiloten

Der Lauf wurde am 8. November 2026 abgeschlossen. Er enthält die fünf
Lernraten, zwei Tiefen und drei Seeds (30 Kombinationen insgesamt). Die sechs
Modelle bei `1e-3` wurden aus der bestehenden Adam-Studie übernommen; 24
Modelle wurden neu trainiert. Alle verwenden dieselben 768 Trainings-IDs je
Seed und dieselben 128 Validierungsfälle. Die Auswertung bestätigte 30
Modellzeilen und 3.840 Fallmessungen.

Die folgende Tabelle zeigt je Lernrate und Tiefe den Median über Seeds der
pro Modell berechneten Kennzahlen:

| Lernrate | Schichten | Mittlerer absoluter Feldfehler [m] | Median relativer Fehler | P95 relativer Fehler |
|---:|---:|---:|---:|---:|
| 0,0001 | 1 | 2,80e-5 | 35,44 % | 653,11 % |
| 0,0001 | 2 | 6,72e-6 | 9,24 % | 85,61 % |
| 0,0003 | 1 | 1,53e-5 | 20,83 % | 251,70 % |
| 0,0003 | 2 | 2,45e-6 | 2,91 % | 31,95 % |
| 0,0010 | 1 | 4,80e-6 | 6,67 % | 55,74 % |
| 0,0010 | 2 | **1,71e-6** | **2,00 %** | **15,13 %** |
| 0,0030 | 1 | **3,22e-6** | **4,49 %** | 37,90 % |
| 0,0030 | 2 | 2,48e-6 | 3,26 % | 31,22 % |
| 0,0100 | 1 | 3,30e-6 | 5,46 % | **32,32 %** |
| 0,0100 | 2 | 3,86e-6 | 5,18 % | 36,37 % |

Für **eine Schicht** schnitt `0,003` beim mittleren absoluten Fehler und
Median am besten ab; `0,01` hatte dort den niedrigsten P95. Für **zwei
Schichten** war die bisherige Rate `0,001` bei allen drei Kennzahlen am
besten. Gemittelt über beide Tiefen hatte `0,003` den niedrigsten mittleren
absoluten Fehler (2,85e-6 m) und Median (3,88 %); `0,01` hatte den knapp
niedrigsten durchschnittlichen P95 (34,34 % gegenüber 34,56 % bei `0,003`).
Die Unterschiede der aggregierten P95-Werte zwischen diesen beiden Raten
sind gering.

**Fazit:** Der Zusammenhang zwischen Lernrate und Fehler ist in diesem
Versuch nicht monoton: Eine kleinere Lernrate ist nicht automatisch besser,
und eine größere nicht automatisch schlechter. Die kleinen Raten `1e-4` und
`3e-4` waren hier deutlich schlechter, während `0,003` bei einer Schicht die
beste Hauptkennzahl lieferte. Bei zwei Schichten blieb `0,001` am besten;
`0,01` war bei einer Schicht beim P95 am niedrigsten. Es gibt somit keine
einzelne Rate, die für beide Tiefen und alle Kennzahlen gewinnt. Falls eine
gemeinsame Rate für beide untersuchten Tiefen erforderlich ist, ist `0,003`
nach der vorab festgelegten Hauptkennzahl (mittlerer absoluter Feldfehler)
ein vorläufiger Kandidat. Für ein konkretes 2-Schicht-Modell sollte `0,001`
beibehalten werden. Das ist eine explorative Auswahl auf bereits betrachteten
Validierungsfällen, keine unabhängige Bestätigung oder statistische
Signifikanzbehauptung. Lernratenpläne wurden nicht getestet.

Vollständige Modelle, Fallwerte, Hashes und Tabellen liegen in
`experiments/pod_mlp_learning_rate_study_20261108/`: insbesondere
`summary_by_learning_rate.csv`, `comparison_vs_1e-3.csv`,
`summary_across_depths.csv` und `model_metrics.csv`.
