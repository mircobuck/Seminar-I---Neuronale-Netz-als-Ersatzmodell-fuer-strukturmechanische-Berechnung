# Gesamtbericht: FEM-Ersatzmodelle und Migrationstest

Stand: 25. Oktober 2026. Dieser Bericht verbindet die gespeicherten historischen statischen Studien mit dem tatsächlich ausgeführten kleinen Integrationslauf der Architekturmigration. Historische Ergebnisse und neue Prüfungen werden getrennt bezeichnet. Die Migration ist noch nicht vollständig abgeschlossen.

## 1. Fragestellung und Versuchskörper

Untersucht wird ein linear elastischer Quader als eingespannter Balken. In der Statik wirkt eine vertikale Last an der freien Stirnfläche; die Zielgrößen sind Verschiebungsfelder und skalare Verschiebungen. Bei der Modalanalyse wird der unbelastete, ungedämpfte Körper mit gleicher Einspannung betrachtet. Gesucht sind die ersten sechs aufsteigend sortierten Eigenfrequenzen und zugehörige FEM-Eigenformen.

Die Parameterbereiche der historischen Studie sind L = 0,6–1,2 m, b = 0,06–0,10 m, h = 0,08–0,14 m, E = 70–210 GPa und ν = 0,25–0,35. Die statische Last liegt zwischen −1000 und −100 N. Für die Modaluntersuchung wird Fz nicht als Eingang verwendet und die Dichte konstant auf 7850 kg/m³ gesetzt; diese Dichte ist eine Demonstrationsannahme.

Ein unabhängiger Fall ist eine Parameterkombination, nicht ein Gitterpunkt oder eine einzelne Mode. Die Feldvergleiche verwenden ein gemeinsames 21 × 5 × 5-Abfragegitter. Bei der relativen gewichteten Feldnorm summieren sich die Trapezgewichte auf eins je Komponente. Die zugrunde liegende Verschiebungsnorm hat die Einheit Meter. Das Gittermaximum ist nicht notwendigerweise das Maximum im gesamten Körper.

## 2. Historische statische Lernkurve

Bereits vor der Migration wurden sechs verschachtelte Trainingsmengen mit 12, 24, 48, 96, 192 und 384 Fällen untersucht. Die Validierungsfälle 13–18 und Testfälle 19–24 blieben über diese Reihe gleich. Die 384 Trainingsfälle umfassen IDs 1–12 und 25–396. Die Testfälle wurden in früheren Untersuchungen bereits betrachtet und sind daher kein neuer blinder Test. Die folgenden Werte sind **historische Ergebnisse**, keine neu trainierten Modelle aus der aktuellen Migration.

Median des relativen gewichteten Feldfehlers auf sechs Testfällen in Prozent:

| Trainingsfälle | POD-GPR | POD-RBF | POD-MLP | DeepONet, Median über fünf Seed-Mediane |
|---:|---:|---:|---:|---:|
| 12 | 60,652 | 23,258 | 21,458 | 45,756 |
| 24 | 23,247 | 26,307 | 9,851 | 52,130 |
| 48 | 4,656 | 18,409 | 13,374 | 43,260 |
| 96 | 3,497 | 5,406 | 13,799 | 31,177 |
| 192 | 1,144 | 3,636 | 8,109 | 10,429 |
| 384 | 0,384 | 5,459 | 3,314 | 8,835 |

Die DeepONet-Spalte aggregiert fünf Seeds; für die älteren POD-Regressoren ist hier keine entsprechende Seed-Streuung belegt. Bei N = 384 lagen die DeepONet-Seed-Mediane zwischen 7,626 % und 10,568 %. Der historische POD-Galerkin-ROM lag auf diesem Test bei ungefähr 0,057 % Medianfeldfehler; sein gemeinsames FEM-Netz unterscheidet sich von den fallweisen Referenznetzen. Dies ist bei direkten Vergleichen zu beachten.

Der frühere DeepONet-Bericht weist für die kleine y-Komponente bei N = 384 einen Median des komponentenweisen relativen Fehlers von 1466,17 % über 30 Seed-Fall-Kombinationen aus; der zugehörige Median des absoluten gewichteten RMS-Fehlers beträgt etwa 0,858 µm. Große relative Werte können bei kleinen Referenzkomponenten auftreten. Diese historische Beobachtung ist kein vorgegebenes Ergebnis für künftige Reproduktionen; Implementierung und Kennzahlen sind ergebnisoffen zu prüfen.

Details zu Trainingsverfahren, Zeiten, Komponentenfehlern und Einschränkungen stehen im historischen [DeepONet-Gesamtbericht](../deeponet_20261023_v1/REPORT.md) und im dortigen PDF unter `output/pdf/`.

## 3. Aktueller statischer Integrationstest

In der Migration wurden bestehende eingefrorene Modelle über neue Adapter und über ihre bisherigen direkten Funktionsaufrufe verglichen. Für Scalar_GPR, Beam_plus_GPR, POD_GP, POD_RBF, POD_MLP, Beam_theory und DeepONet wurden sechs Testfälle verglichen; für POD_Galerkin wurde ein Testfall verglichen. Die maximale Differenz zwischen jeweiligem Adapter und direktem Aufruf war in allen geprüften Fällen null. Dieser Test prüft die Weiterleitung; er ist noch kein vollständiger Abgleich gegen alle historisch gespeicherten Kennzahlen.

Ein zusätzlicher kleiner Scalar-GPR wurde mit den ersten zwölf Trainingsfällen als Schnittstellenprobe trainiert und separat gespeichert. Historische Modelle wurden dafür nicht überschrieben. Die folgenden sechsfalligen Feldfehler aus dem Adapterlauf stammen jeweils von den verwendeten eingefrorenen N=384-Modellen; DeepONet verwendet hier ausschließlich Seed 42, nicht den Median über fünf Seeds:

| Modell | Median relativer Feldfehler |
|---|---:|
| POD-GPR | ca. 0,38 % |
| POD-RBF | ca. 5,46 % |
| POD-MLP | ca. 3,31 % |
| DeepONet, Seed 42 | ca. 10,57 % |

Für die signierte Spitzenverschiebung betrug der mittlere absolute Fehler des historischen Scalar-GPR etwa 0,729 µm und von Beam_plus_GPR etwa 0,00767 µm. Diese sechs Fallfehler sind nicht mit einer unabhängigen großen Teststichprobe gleichzusetzen.

## 4. Modal-FEM und Netzprüfung

Drei ausgewählte Trainingsparameterfälle, IDs 1, 6 und 12, wurden jeweils auf drei quadratischen Tetraedernetzen mit Hmax = min(b,h)/2, /3 und /4 berechnet. Die ersten sechs Frequenzen wurden über ein gemeinsames Abfragegitter und Eigenformähnlichkeiten zugeordnet; nahe Moden werden anhand einer konfigurierbaren 1-%-Abstandsheuristik als Cluster betrachtet. Für Cluster werden Unterräume und numerischer Rang geprüft; Puffermoden sollen Randfälle sichtbar machen. Die Heuristik und weitere Grenzfälle müssen noch umfassender geprüft werden.

| Fall | Größte relative Änderung einer der sechs Frequenzen von Netz /3 zu /4 | 2-%-Grenze |
|---:|---:|---|
| 1 | 0,1198 % | bestanden |
| 6 | 0,1785 % | bestanden |
| 12 | 0,1061 % | bestanden |

Diese Stichprobe zeigt Stabilität für die geprüften Fälle, keine flächendeckende Konvergenz im Parameterraum. Die Detaildateien `convergence_*.mat` und `comparison_*.mat` enthalten Frequenzen, Formen, Zuordnungen und Vergleiche. Bei der Übertragung gibt MATLAB eine Warnung zu nicht von der Eckknoten-Triangulation referenzierten Punkten aus; die quadratischen Mittelknoten werden in den Formfunktionen verwendet.

Für einen separaten Skalierungstest wurde die Dichte bei unverändertem Netz von 7850 auf 15700 kg/m³ verdoppelt. Die Frequenzverhältnisse wichen relativ um maximal 1,74 · 10⁻⁹ vom erwarteten Faktor 1/√2 ab. Die veränderte Dichte gehört nur zur Prüfung, nicht zur konstanten Studiendichte.

## 5. Kleiner Frequenz-GPR-Integrationslauf

Berechnet wurden 12 Trainingsfälle, sechs Validierungsfälle (13–18) und sechs Testfälle (19–24). Für jede der sechs Frequenzen wird ein GPR auf logarithmierten Frequenzen angepasst. Zwei Kernel wurden getrennt nur mit Trainingsdaten und train-only Eingangsskalierung angepasst. Die Validierung wählte den Kandidaten mit dem kleineren mittleren relativen Frequenzfehler; anschließend wurde dieser unverändert auf dem Test ausgewertet. Seed 42 bezeichnet diesen Integrationslauf, keine Wiederholungsstudie.

| Kernel | Mittlerer Validierungsfehler |
|---|---:|
| ARD-Matérn-5/2 | 8,163 % |
| ARD-Squared-Exponential | 3,856 % |

Der zweite Kandidat wurde gewählt. Auf sechs Testfällen ergab sich über Fälle und Frequenzen ein mittlerer relativer Fehler von **3,366 %** sowohl vor als auch nach der aufsteigenden Sortierung. Bei keinem Testfall war die vorhergesagte Reihenfolge verletzt. Die Sortierung verwendet keine FEM-Testwerte. Sie bedeutet Spektrumsvorhersage und keine Verfolgung physikalischer Modenfamilien.

| Sortierte Frequenz | Mittlerer relativer Testfehler |
|---:|---:|
| 1 | 1,810 % |
| 2 | 3,050 % |
| 3 | 1,668 % |
| 4 | 5,595 % |
| 5 | 3,687 % |
| 6 | 4,386 % |

Das sind Mittelwerte über jeweils dieselben sechs Parameterfälle, keine 36 unabhängigen Fälle. `frequency_evaluation.mat` enthält Referenzwerte, unsortierte und sortierte Vorhersagen sowie einzelne Fehler. `frequency_model.mat` enthält den eingefrorenen gewählten Kandidaten und die Validierungsergebnisse.

## 6. Technische Prüfungen und Grenzen

Vier MATLAB-Unit-Tests bestanden: Ablehnung unterschiedlicher Raumidentitäten, Frequenzsortierungsmetriken, Erkennung einer Trainings-/Validierungsüberschneidung sowie Vorzeichen- und Clusterrotation bei einem synthetischen Beispiel. Ein gespeichertes Frequenzmodell wurde erneut geladen und reproduzierte seine Vorhersage. Ein erneuter Datenlauf erkannte vorhandene und kompatible einzelne Modaldateien. Der LaTeX-Kurzbericht wurde kompiliert und visuell geprüft.

Noch offen sind ein vollständiges Metrikregister für Modalresiduen und Massennormen, umfassende Datensatz- und Registryverträge, vollständige Status-/Cache- und Wiederaufnahmetests, der Vergleich mit allen historischen Kennzahlen und ein vollständiger Herkunftsaudit zusätzlicher möglicher Fälle. Für die größeren Validierungs- und Testmengen wurden noch keine neuen unabhängigen Fälle gezogen oder berechnet. Der vorgeschlagene Umfang ist 384 Trainingsfälle plus je 64 neue unabhängige Validierungs- und Testfälle, höchstens 512 Modal-Fälle. Die große Lernkurve wurde nicht gestartet.

Die neue Arbeit liegt in diesem Experimentordner und im Paket `+femstudy`; historische Daten und Modelle wurden für den Lauf nicht überschrieben. Ein vollständiger nachträglicher Hash-Abgleich aller historischen Dateien wurde in diesem Migrationslauf nicht durchgeführt.

## 7. Quellen und Nachvollziehbarkeit

- [Architektur, Modellbestand und offene Punkte](../../ARCHITEKTUR_PHASE1.md)
- [Kompilierter Integrations-Kurzbericht](integration_report.pdf) und [LaTeX-Quelle](integration_report.tex)
- [Entwurf für die größere Modalstudie](../definitions/modal_study_draft_v1.json)
- [Historischer ausführlicher DeepONet- und Modellvergleich](../deeponet_20261023_v1/REPORT.md)
- Ausführung: `run_migration_phase1('convergence')`, `('density')`, `('static')`, `('data')`, `('train')`, `('evaluate')`; Modelltraining ist gegen Überschreiben eines bestehenden Modells geschützt.
