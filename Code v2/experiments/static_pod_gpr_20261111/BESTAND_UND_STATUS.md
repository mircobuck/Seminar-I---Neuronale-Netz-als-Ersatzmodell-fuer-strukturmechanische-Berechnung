# Bestandsaufnahme und Arbeitsstand

Status: Implementierung begonnen. Der vollst?ndige Studienablauf und der unabh?ngige Vergleich sind noch nicht durchgef?hrt. Die JSON-Datei ist ein Entwurf und kein eingefrorenes Protokoll.

- Der statische Trainingspool umfasst nach MAT-Dimensionen und `training_extension_768.json` 768 F?lle aus zwei Bl?cken zu je 384; das urspr?ngliche Design umfasst IDs 810001?810460. Die HDF-Speicherorientierung im Manifest ist gegen?ber der MATLAB-Feldmatrix transponiert. Der urspr?ngliche Entwurf nennt 12 Validierungs- und 64 Testf?lle; sp?tere Studien haben weitere Datens?tze erzeugt. `design_manifest.csv` listet aufgefundene statische Designs und deren Dateipr?fsummen; erg?nzend enth?lt `dataset_manifest.csv` die gefundenen MAT-Dateien mit Fallzahl und Pr?fsumme; die Pr?fung aller historischen Labelnutzungen ist noch nicht vollst?ndig.
- Die erneute L2-Auswertung untersucht bereits mehrfach verwendete 128 Validierungsf?lle. Architektur-, Loss-, Lernraten-, Optimierer-, Breiten- und Rangstudien sind keine gemeinsame vollst?ndige Gittersuche.
- Die direkte MLP/RBF-Tiefenstudie umfasst laut Ergebnisdatei 18 L?ufe und verwendet standardisierte Ausgabe-MSE. Die RBF-Zentren und -Breiten sind fest; weitere tanh-Schichten sind trainierbar. Das bevorzugte POD?MLP verwendete gewichtete Feld-MSE.
- Die Laufzeitdatei der Rang-15-Studie f?hrt historische Rang-10-Fitzeiten als Vergleich auf. Sie sind keine gemessenen Rang-15-Trainingszeiten.
- Die statische FEM-Validierung belegt Plausibilit?t an den untersuchten F?llen und eine begrenzte Netzdiagnose, nicht die Konvergenz im gesamten Raum.
- MATLAB R2025b, Statistik-, Deep-Learning- und PDE-Funktionen wurden ?berpr?ft. Eine zun?chst nicht antwortende MATLAB-MCP-Sitzung wurde durch einen separaten Batchlauf umgangen.

## Noch offen

Datenherkunft und bisherige Labelnutzung vollst?ndig pr?fen; Studienprotokoll und Implementierung der getrennten Phasen vervollst?ndigen; neue Referenzdaten erzeugen; Pilot, Hyperparametersuche, Freeze und unabh?ngige Tests durchf?hren; vollst?ndige Laufzeitmessungen, Plots und Abschlussbericht erstellen. Keine neuen Testlabels wurden ausgewertet.

## Bekannte Nutzung der statischen Datens?tze

| Datensatz | F?lle | Bisherige Nutzung |
|---|---:|---|
| urspr?nglicher Trainingsblock | 384 | Training und statische analytische FEM-Plausibilit?tspr?fung |
| erg?nzter Trainingsblock | 384 | Training und erg?nzende statische Plausibilit?tspr?fung |
| urspr?ngliche Validierung | 12 | Modellstudien und erg?nzende FEM-Plausibilit?tspr?fung |
| urspr?nglicher Test | 64 | fr?here Testl?ufe und erg?nzende FEM-Plausibilit?tspr?fung |
| frische Validierung 2026-11-08 | 12 | Loss-Vergleich |
| weitere Validierung 2026-11-08 | 128 | mehrfach verwendete Architektur-, Optimierer-, Lernraten-, Breiten-, Rang- und direkte Tiefenstudien |
| unabh?ngiger Test 2026-11-06 | 64 | fr?herer POD?MLP-Abschlusstest |
| unabh?ngiger Test 2026-11-09 | 128 | fr?herer POD?MLP-Abschlusstest der gewichteten Loss |
| Smoke-Design | 4 | technische Erprobung, kein wissenschaftlicher Abschlusstest |

Dies beschreibt die aufgefundenen Artefakte; noch nicht ausgeschlossen sind weitere statische Daten ohne `design*.csv`. Keiner dieser Test- oder Validierungssplits wird der neuen Studie als unabh?ngiger Abschlusstest oder als Training zugeordnet.

## Bisheriger explorativer POD-Pilot

Ein erster Versuch wurde vor Training abgebrochen, weil das aktuelle Design bereits beide Trainingsbl?cke enth?lt. Der zweite Versuch verwendet 24 F?lle je Block, Rang 2 und dieselbe trainingsbasierte POD-Basis. Er evaluiert nur die historische 12-Fall-Validierung. Fallauswahl und gespeicherte Ergebnisse stehen in `exploratory_pilot_attempt2`; die einzelnen Fit- und Vorhersagezeiten sind keine kontrollierte Laufzeitstudie. Die beobachteten Fehlermittelwerte betragen 52,7 % f?r POD?MLP und 18,7 % f?r POD?GPR. Aus zw?lf mehrfach genutzten F?llen und jeweils einer Konfiguration folgt keine allgemeine Methodenrangfolge.

Die explorativen Pilotl?ufe speichern derzeit keine vollst?ndigen Code-Pr?fsummen; ihre genaue Programmversion ist daher nicht vollst?ndig rekonstruierbar. Sie sind nicht als Grundlage des sp?teren Freeze oder als reproduzierbarer Hauptvergleich geeignet.

## Bisherige technische Pr?fungen

In einer MATLAB-R2025b-Batchsitzung bestanden 56 Pr?fungen aus `surrogateContractTest`, `podMlpTest`, `directNeuralTest` und dem ersten Stand von `podGprTest`. Anschlie?end bestanden drei Pr?fungen der direkten gewichteten Loss, einschlie?lich konstanter Felder. Nach Erg?nzung der POD-Fehlerzerlegung, des Mat?rn-Kernels und der Studienhilfsfunktionen bestanden im korrigierten Lauf alle 12 neu ausgew?hlten Tests; die tabellarischen Ergebnisse stehen in `new_test_results_corrected.csv`. Der Vertragstest pr?ft Kompatibilit?t, nicht wissenschaftliche Prognoseg?te.

## Abgeschlossener statischer FEM-Pilot

Alle 48 Netzl?ufe (24 F?lle auf Stufe 3; zw?lf Extrapolationsf?lle zus?tzlich auf Stufe 4 und 6) waren erfolgreich. Die 24 Stufe-3-Solverzeiten summieren sich auf 74,08 s, die zw?lf Stufe-6-Zeiten auf 435,80 s; die verstrichene Zeit f?r den gesamten Pilot betrug 587,49 s. Die Werte sind Machbarkeitsmessungen, keine kontrollierten Vergleichslaufzeiten.

Die gr??te gewichtete relative Felddifferenz zwischen Stufe 3 und 6 betr?gt 0,170 %, zwischen 4 und 6 0,0761 %. Der Median der Unterschiede 4 zu 6 betr?gt 0,0432 %. Das sind Differenzen auf zw?lf gezielt ausgew?hlten F?llen, keine abgesicherten Fehlerschranken und kein Konvergenznachweis ?ber den gesamten Extrapolationsbereich. `fem_pilot/pilot_results.csv` enth?lt einzelne Laufwerte; `fem_pilot/mesh_4_to_6.csv` die zus?tzliche paarweise Auswertung.

Ein sp?terer Testlauf der neuen Tests meldete zun?chst drei Unterschiede in der Gro?schreibung der von MATLAB gelieferten GPR-Optionsnamen; die Testvergleiche wurden angepasst und erneut ausgef?hrt. Das urspr?ngliche Ergebnis bleibt in `new_test_results.csv` erhalten.
