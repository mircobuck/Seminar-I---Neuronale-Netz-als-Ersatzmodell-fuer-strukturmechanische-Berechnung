# Versuchsreihe: Einfluss der Trainingsmenge

**Aktualisierung:** Die Reihe wurde anschließend auf 96 Trainingsfälle erweitert.
Der aktuelle Gesamtstand steht in [RESULTS.md](RESULTS.md). Der unveränderte
Stand vor dieser Erweiterung ist zusätzlich in `milestone_48/` archiviert.

Datum: 23.10.2026, Europe/Berlin. MATLAB 25.2.0.3042426 (R2025b) Update 1.

**Status: abgeschlossen.** Die beiden neuen Stufen wurden jeweils genau einmal trainiert und getestet. Kein MATLAB-Laufzeitfehler. Kein Pilot-Lauf.

## Fragestellung und vorab festgelegtes Protokoll

Was bewirkt eine Verdopplung der Trainingsdaten von 12 auf 24 und danach auf 48 F?lle bei derselben Modellierungs- und Auswahlstrategie?

- Die vorhandenen f?nf Smoke-Modelle bilden die 12er-Basis. Sie wurden kopiert und nicht neu trainiert.
- Die Trainingss?tze sind verschachtelt: 12 urspr?ngliche F?lle; zus?tzlich 12 F?lle f?r n24; zus?tzlich 24 F?lle f?r n48.
- Alle sechs Validierungsf?lle und alle sechs Testf?lle bleiben exakt identisch, einschlie?lich Parameter, FEM-Felder, Zielwerte und Laufzeitmetadaten.
- Originale IDs: Training 1?12, Validierung 13?18, Test 19?24. Erg?nzungen: IDs 25?36 und 37?60.
- 36 neue Punkte aus einem zuf?llig geschichteten Latin-Hypercube-Design mit Seed 20261023 und twister. Die ersten zw?lf sind vorab die erste Erweiterung. Die zusammengesetzten Trainingss?tze sind keine jeweils neu optimierten LHS-Designs.
- Parameterbereiche, lineare statische Physik, FEM-Netzregel, Referenzgitter und Plausibilit?tsgrenzen bleiben gleich.
- Modell-Seed 42. GP-Kernel und Rauschparameter, RBF-Regularisierungskandidaten, MLP-Breiten, 300 maximale Epochen, Batchgr??e 16, Early Stopping und CPU-Ausf?hrung bleiben gleich.
- Effektive POD-Rangkandidaten in allen drei Stufen: **[2, 4, 8, 11]**. Der urspr?ngliche Code kappt [2, 4, 8, 12, 20] bei zw?lf Trainingsf?llen auf diese Liste. Diese wirksame Liste wurde f?r die Reihe eingefroren, damit der Suchraum nicht gleichzeitig w?chst.
- Skalierung, POD-Basis und Regression werden je Stufe nur aus dem jeweiligen Trainingssatz gelernt. Gew?hlter Rang, Regularisierung und Netzbreite d?rfen sich nach der unver?nderten Validierungsregel unterscheiden.
- Bei unver?ndertem MLP-Epochenlimit wachsen mit der Datenmenge auch die Optimierungsschritte je Epoche. Es handelt sich nicht um einen Vergleich mit identischer Zahl an Optimierungsschritten.
- Das Protokoll und beide Erweiterungen wurden vor neuen FEM-Berechnungen und vor dem Training gespeichert. Nach der ersten Testauswertung wurde nichts angepasst.

Das vorab gespeicherte Protokoll steht in [PLAN.md](PLAN.md); maschinenlesbare Konfigurationen in `protocol.mat`. Die Eingabe-CSV-Dateien verwenden 17 signifikante Stellen und wurden nach dem Schreiben auf exakt unver?nderte Zahlen zur?ckgelesen.

## Ergebnisse: medianer relativer Feldfehler

Alle Werte in Prozent; kleiner ist besser. Dies sind gewichtete relative L2-Fehler auf denselben sechs Testf?llen.

| Modell | 12 Training | 24 Training | 48 Training |
|---|---:|---:|---:|
| POD_GP | 60,6522 % | 23,2465 % | 4,6562 % |
| POD_RBF | 23,2579 % | 26,3073 % | 18,4086 % |
| POD_MLP | 21,4584 % | 9,8507 % | 13,3738 % |

## Ergebnisse: gr??ter relativer Feldfehler

| Modell | 12 Training | 24 Training | 48 Training |
|---|---:|---:|---:|
| POD_GP | 2534,0135 % | 127,0418 % | 63,8077 % |
| POD_RBF | 792,9969 % | 91,3578 % | 98,9255 % |
| POD_MLP | 918,3498 % | 1102,5588 % | 1411,7165 % |

Bei sechs Testf?llen ist das hier verwendete P95 gleich dem Maximum.

## Ergebnisse: skalare Spitzenverschiebung

MAE in Mikrometern. Diese Gr??e wird getrennt von den relativen Feldfehlern betrachtet.

| Modell | 12 Training | 24 Training | 48 Training |
|---|---:|---:|---:|
| Scalar_GPR | 110,2806 ?m | 39,5396 ?m | 19,1077 ?m |
| Beam_plus_GPR | 0,5068 ?m | 0,1359 ?m | 0,1145 ?m |
| Balkentheorie ohne Lernen | 0,4533 ?m | 0,4533 ?m | 0,4533 ?m |

## Gew?hlte Feldmodelle und Validierung

| Training | Modell | POD-Rang | RBF-Lambda / MLP-Breite | Validierungs-Mittelfehler |
|---:|---|---:|---:|---:|
| 12 | POD_GP | 2 | ? | 155,0269 % |
| 12 | POD_RBF | 11 | 0 | 96,2133 % |
| 12 | POD_MLP | 4 | 64 | 61,6811 % |
| 24 | POD_GP | 11 | ? | 54,9683 % |
| 24 | POD_RBF | 11 | 0 | 78,2257 % |
| 24 | POD_MLP | 2 | 32 | 58,4994 % |
| 48 | POD_GP | 11 | ? | 23,6238 % |
| 48 | POD_RBF | 11 | 0 | 34,5896 % |
| 48 | POD_MLP | 4 | 32 | 41,7793 % |

## Einordnung der beobachteten Wirkung

- **POD_GP profitiert deutlich und in beiden Schritten:** Median 60,65 ? 23,25 ? 4,66 %. Auch das Maximum sinkt von 2534,01 auf 63,81 %. Die urspr?nglichen Ziele (Median <1 %, P95 <3 %) sind trotzdem nicht erf?llt.
- **POD_RBF reagiert nicht monoton:** Der Median verschlechtert sich zuerst und verbessert sich dann. Das Maximum wird mit der ersten Verdopplung viel kleiner, steigt beim zweiten Schritt aber leicht von 91,36 auf 98,93 %.
- **POD_MLP reagiert ebenfalls nicht monoton:** bester Median bei 24 F?llen (9,85 %), danach 13,37 %. Gleichzeitig w?chst der schlechteste Fehler 918,35 ? 1102,56 ? 1411,72 %. Mehr Daten allein beseitigen diesen Ausrei?er nicht.
- Die gr??ten Feldfehler aller drei Modelle liegen bei allen Trainingsgr??en auf Fall-ID 23. Dessen FEM-Spitzenverschiebung ist nur etwa 7,455 ?m; relative Fehler sind bei kleinen Bezugswerten besonders empfindlich.
- Beide Skalarmodelle verbessern ihren MAE bei beiden Verdopplungen. Beam_plus_GPR ist ab 24 F?llen in diesem Vergleich genauer als die reine Balkentheorie.
- Die POD-Projektionsfehler bleiben klein; genaue Werte stehen in comparison.csv. Das spricht daf?r, dass f?r die hohen Vorhersagefehler insbesondere Regression und Datenabdeckung untersucht werden sollten. Dies ist eine Einordnung, kein Nachweis einer einzelnen Ursache.

Die Datenmenge ist der bewusst ver?nderte Versuchsparameter. Aussagen zur Allgemeing?ltigkeit sind begrenzt: nur eine verschachtelte Stichprobe, ein Modell-Seed und sechs Testf?lle. Der Testsatz war bereits aus dem Smoke-Lauf bekannt und ist daher ein fester Vergleichssatz, kein neuer blinder Holdout. Er wurde in dieser Reihe weder zum Training noch zur Auswahl der Einstellungen verwendet.

## Tats?chlich ausgef?hrte Stufen

Einmal `run_training_size_study("prepare")`, danach die folgenden sechs Stufen ?ber MATLAB MCP und einmal `summarize`:

| Stufe | Beginn (Europe/Berlin) | Dauer [s] | Erfolgreich |
|---|---|---:|---|
| generate24 | 2026-10-23 11:12:42 | 17,146 | ja |
| train24 | 2026-10-23 11:13:07 | 15,516 | ja |
| evaluate24 | 2026-10-23 11:13:46 | 1,023 | ja |
| generate48 | 2026-10-23 11:13:53 | 40,524 | ja |
| train48 | 2026-10-23 11:14:47 | 15,052 | ja |
| evaluate48 | 2026-10-23 11:15:26 | 0,681 | ja |

Die Erzeugung hat **12 + 24 = 36 neue FEM-F?lle** berechnet. Die zweite Erweiterung verwendet alle bisherigen F?lle wieder. Insgesamt liegen 60 unterschiedliche physikalische F?lle vor (48 Training, 6 Validierung, 6 Test).

Nach jeder Datenerzeugung sowie vor Training und Test wurden Anzahl, Dimension, endliche Werte, disjunkte IDs, unver?nderte Physik und identische Validierungs-/Testdaten gepr?ft. Abschlie?end wurden alle 24 Trainingsf?lle der ersten Erweiterung einschlie?lich FEM-Feldern und Skalarzielen exakt in den ersten 24 F?llen der zweiten Erweiterung nachgewiesen.

Der Code Analyzer meldete f?r den neuen Versuchsrunner null Fehler/Warnungen und drei Hinweise zur Vorallokation kleiner Ergebnistabellen. Die bestehenden Solver-, Trainings- und Evaluierungsfunktionen wurden nicht ge?ndert. `run_checks(true)` und `mesh_check` wurden f?r diese reine Datenerweiterung nicht erneut ausgef?hrt; ihr voriger Pr?fstatus bleibt dokumentiert.

Laufzeiten enthalten Cache-/Warmup-Effekte, Modellauswahl und beim MLP unterschiedliches Early Stopping. Sie sind keine kontrollierte Hardware-Benchmarkmessung.

## Erhaltung und Nachvollziehbarkeit

- Alle **35 zuvor vorhandenen Run-Dateien**, darunter das urspr?ngliche models.mat, s?mtliche Smoke-FEM-Daten und das Pilot-Manifest, sind per SHA-256 unver?ndert.
- Die Baseline wurde vollst?ndig nach n12 kopiert. n24 und n48 haben eigene Modelle und Ergebnisse. Kein vorhandenes Modell wurde ?berschrieben.
- Vor dem Training wurden Quellcode und urspr?ngliche Dokumentation nach source_snapshot kopiert. Die ?bereinstimmung der ausf?hrbaren Quellen wurde abschlie?end gepr?ft.
- Rohdaten und Designs aller Stufen sind vorhanden. Die Zahlen der CSV-Ergebnistabellen sind in SI bzw. als dimensionslose Verh?ltnisse gespeichert; die Tabellen hier rechnen nur in Prozent und ?m um.

## Dateien

- [Lernkurve](learning_curve.png): Median und Maximum, logarithmische Fehlerachsen.
- [Vollst?ndiger Vergleich](comparison.csv): alle f?nf Modelle, Feld-/Skalarfehler, POD-Projektionsfehler und Modelllaufzeiten.
- [Einzelfehler](case_errors.csv): jeder Testfall in jeder Stufe.
- [Ausgew?hlte Modelle](selected_models.csv): Rang, Hyperparameter und Validierungsfehler.
- [Ausf?hrungsjournal](events.csv) und logs/: Zeitstempel, Status und tats?chliche MATLAB-Ausgaben je Stufe.
- protocol.mat, baseline_design.csv, design_n24.csv, design_n48.csv, additional_training_design.csv und case_provenance.csv: genaue Konfiguration und Datenherkunft.
- n12/, n24/, n48/: FEM-Fall-Dateien, Splits, Modelle, Kandidatenauswahl und Testvorhersagen.
- original_files.json, preservation_check.txt und artifact_hashes.json: Dateiintegrit?t.
- nested_data_verification.txt: Pr?fung der vollst?ndigen Verschachtelung.

## Wiederholen oder fortsetzen

F?r eine bereits vorbereitete Stufe: `run_training_size_study("train24",studyDir)` usw. Der Runner verweigert vorhandene Modelle und bereits gespeicherte Auswertungen. Zum vollst?ndigen Wiederholen muss ein neuer Studienordner verwendet werden:

```matlab
newDir = fullfile(pwd,"experiments","training_size_repeat_01");
run_training_size_study("prepare",newDir);
for stage = ["generate24","train24","evaluate24", ...
             "generate48","train48","evaluate48","summarize"]
    run_training_size_study(stage,newDir);
end
```

Die Skripte starten ausschlie?lich diese Reihe und keinen Pilot-Lauf. F?r eine andere Untersuchung zuerst ein neues Protokoll und einen neuen Ausgabeordner festlegen; eingefrorene Modelle erhalten.
