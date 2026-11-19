# Abschlusstest statischer Ersatzmodelle

Dieser Prüfstand bewertet gespeicherte, vertragskonforme Modelle auf denselben
statischen Testfällen. Er trainiert keine Modelle und rechnet keine FEM. Seine
Softwaretests verwenden ausschließlich synthetische Daten.

## Vor einem echten Test

Vor dem ersten Öffnen der Testlabels Modellauswahl und Freeze dokumentieren:
Modellartefakte und Seeds, Auswahlregel, Datenkennung, gewählte Schwellwerte,
Code- und Modellstand sowie den bekannten bisherigen Umgang mit Testlabels.
Ein bereits für Modellentscheidungen verwendeter Testsatz ist nicht mehr als
unabhängiger Abschlusstest zu interpretieren. Die nachfolgenden Angaben sind
eine Dokumentation der Entscheidung; das Programm kann sie nicht verifizieren
und schützt die Daten nicht vor anderen Zugriffen. Insbesondere gibt es keine
technische Zugangssperre für Testlabels.

Aus `Code v2` ein vorbereitendes Beispiel für den späteren Aufruf:

```matlab
addpath('studies/static_final_evaluation')
config = studyConfigTemplate();
config.datasetFile = 'ABSOLUTER_PFAD_ZU_TEST_MAT';
config.datasetId = 'VERSION_DER_REFERENZDATEN';
config.selectionRule = 'VORAB_DOKUMENTIERTE_AUSWAHLREGEL';
config.freezeDescription = 'MODELLVERSION_UND_FREEZE_STAND';
config.testLabelHistory = 'BEKANNTE_BISHERIGE_NUTZUNG_DER_TESTLABELS';
config.metricConfig.staticReferenceFloor = 0; % vorab festlegen, in m
config.models = struct('label', 'POD_MLP_ADAM_64_SEED42', ...
    'file', 'ABSOLUTER_PFAD_ZUM_EINGEFRORENEN_MODELL');
% Weitere Modelle als eigene Einträge in config.models ergänzen.
result = runStaticFinalEvaluation(config, 'PFAD_ZU_NEUEM_AUSGABEORDNER');
```

Das Template hält die statischen Metriken und Summary-Statistiken bereits fest;
zu wählen und zu dokumentieren ist insbesondere `staticReferenceFloor` in
Metern. Modellnamen sollten Methode, Optimierer und Konfiguration nennen, etwa
`POD_MLP_ADAM_64`; verschiedene Seeds werden als separate Modellläufe mit
eigenem Namen wie `POD_MLP_ADAM_64_SEED42` geführt und niemals als zusätzliche
Fälle gezählt. Der Testsplit ist fest vorgegeben. Die Datendatei benötigt die
zugehörige `design.csv`.

Die Konfiguration wird vor dem Laden der Referenzdaten in den Ausgabeordner
geschrieben. Alle Modelle erhalten dieselben Testparameter und Fall-IDs in
derselben Reihenfolge. Der Lauf lädt gespeicherte Artefakte über
`surrogate.loadModel`, sagt über `surrogate.predictModel` vorher und bewertet
mit `surrogate.evaluatePrediction`. Er trainiert keine Modelle und startet keine
FEM. Ausgewertet werden ausschließlich statische Verschiebungsfelder.

`case_errors.csv` enthält pro erfolgreichem Modell und Fall ID, gewichteten
Absolutfehler [m], Referenznorm [m], relativen Fehler und dessen
Definiert-Kennzeichnung. Ein relativer Wert bleibt bei einer Referenznorm
kleiner oder gleich dem festgelegten Schwellwert undefiniert (`NaN`); Fallzeile,
Grund und Anzahl bleiben sichtbar. Die Zusammenfassung weist für absolute und
definierte relative Fehler Mittelwert, Median, Nearest-Rank-P95 und Maximum
aus. Die drei PNG-Plots zeigen mittleren absoluten Fehler, Median des absoluten
Fehlers und P95 des absoluten Fehlers, jeweils in Metern.

Der vorab festgelegte Test aller 12 Breiten-/Tiefenkombinationen und Seeds
42/43/44 kann mit `runStaticTrainingTestEvaluation(OUTPUTDIR,TRAININGCASES)`
für die gespeicherten 384er- oder 768er-Modelle gestartet werden.
`runStatic768TestEvaluation(OUTPUTDIR)` bleibt als Kurzaufruf für die
768er-Stufe verfügbar. Der Aufruf prüft zunächst alle 36 Modellartefakte und
ihre Trainingsfallzahl, dokumentiert danach Auswahl und Freeze und lädt
anschließend die unveränderten Testlabels. Diese Aufrufe exportieren keine
Plots. Werden beide Trainingsstufen am selben Testsatz ausgewertet, ist ein
nachträglicher Stufenvergleich nicht mehr als unabhängige Testauswertung zu
interpretieren.

Wenn vorhandene Testlabels bereits ausgewertet oder für Modellentscheidungen
eingesehen wurden, kann `runIndependentPodMlpTest(OUTPUTROOT)` einen neuen
statischen Testsplit erzeugen. Der Lauf friert vor der FEM-Berechnung alle 36
gespeicherten 768-Fall-Modelle samt SHA-256-Hashes ein, erstellt 64 neue
Latin-Hypercube-Fälle innerhalb derselben Parametergrenzen, prüft ID- und
Parameterüberschneidungen mit dem bestehenden Design und berechnet neue FEM-
Referenzfelder. Anschließend bewertet er alle Modelle auf denselben Fällen.
Ergebnisse und Referenzdaten werden unter `OUTPUTROOT` gespeichert; der
Ausgabeordner darf noch nicht existieren. Die Testlabels werden beim Lauf
erzeugt, daher kann die FEM-Phase abhängig von der Laufzeit je Fall dauern.

Für den unabhängigen Abschlusstest der bevorzugten Loss-Variante startet
`runWeightedLossIndependentTest(OUTPUTROOT)` mit drei zuvor eingefrorenen
Modellen (`weighted_field_mse`, Breite 64, zwei versteckte Schichten,
768 Trainingsfälle, Seeds 42/43/44). Die Auswahl basiert ausschließlich auf
den bereits ausgewerteten Validierungsdaten. Der Runner prüft und hasht die
Modelle, erzeugt 128 neue statische Latin-Hypercube-Testfälle mit Seed
`20261110` und IDs ab `814001`, prüft auf ID- und exakte Parameterüberschneidung
mit den bekannten Designs und wertet erst danach alle drei Modelle auf den
neuen FEM-Referenzen aus. Ausgabe und Modell-Freeze liegen im neuen Ordner
`experiments/pod_mlp_weighted_independent_test_20261109/`; dieser Ordner darf
noch nicht existieren. Die Testfälle dürfen nach Sichtung der Ergebnisse nicht
für weitere Modellauswahl oder Abstimmung verwendet werden.

Der Lauf wurde am 9. November 2026 abgeschlossen: alle 128 FEM-Fälle und
alle drei Modellbewertungen waren erfolgreich; undefinierte relative Fehler
gab es nicht. Die relative Metrik ist in Prozent angegeben, der P95 verwendet
Nearest Rank.

| Seed | Mittlerer Absolutfehler [m] | Median relativ | P95 relativ |
|---:|---:|---:|---:|
| 42 | 2,00e-6 | 1,62 % | 6,64 % |
| 43 | 2,02e-6 | 1,74 % | 9,92 % |
| 44 | 2,78e-6 | 2,86 % | 31,14 % |

Der Median dieser drei Seed-Metriken beträgt 2,02e-6 m mittleren
Absolutfehler, 1,74 % Medianfehler und 9,92 % P95. Diese Werte gelten für
die eingefrorene Konfiguration und diesen Testentwurf; die drei Seeds sind
keine zusätzlichen Testfälle. Der Testsplit ist nach Sichtung nicht mehr
unberührt und darf nicht zur nachträglichen Modellauswahl verwendet werden.
Die Einzelergebnisse stehen in
`experiments/pod_mlp_weighted_independent_test_20261109/evaluation/summary.csv`.

## Breitenstudie mit zwei versteckten Schichten

`examples/runPodMlpWidthStudy.m` vergleicht Breiten von 16, 20, 32, 40, 64,
80, 100 und 128 Neuronen je versteckter Schicht bei konstant zwei Schichten. Alle
Modelle verwenden `weighted_field_mse`, 768 Trainingsfälle, Adam mit
Lernrate 0,001, 200 Epochen und Seeds 42/43/44. Ausgewertet werden dieselben
128 Validierungsfälle (IDs 813001–813128), die bereits für vorherige
Modellvergleiche verwendet wurden. Die Studie ist explorativ; Testdaten werden
nicht geladen.

Der Lauf ist abgeschlossen und liegt unter
`experiments/pod_mlp_width_study_20261109_with128/`. Die ursprüngliche Studie
unter `experiments/pod_mlp_width_study_20261109/` bleibt erhalten. Ihre 18
Modelle und Einzelfehler wurden unverändert übernommen; nur Breite 100 wurde
mit denselben drei Seeds und Trainings-IDs ergänzt. Anschließend wurden die
21 Modelle aus `pod_mlp_width_study_20261109_with100/` unverändert übernommen
und um drei Läufe mit Breite 128 ergänzt. Der gemeinsame Vergleich enthält
24 Modelle und 3072 Fallfehler. Die folgenden Kennzahlen sind
je Breite erst pro Seed über 128 Fälle bestimmt und anschließend als Median
über die drei Seeds zusammengefasst:

| Neuronen je Schicht | Mittlerer Absolutfehler [m] | Median relativ | P95 relativ |
|---:|---:|---:|---:|
| 16 | 2,66e-6 | 3,37 % | 19,65 % |
| 20 | 1,95e-6 | 2,47 % | 18,52 % |
| 32 | 1,73e-6 | 2,03 % | 12,83 % |
| 40 | 1,57e-6 | 1,63 % | 19,03 % |
| 64 | 1,51e-6 | 1,61 % | 13,72 % |
| 80 | 1,54e-6 | 1,77 % | 15,48 % |
| 100 | 1,76e-6 | 2,17 % | 17,36 % |
| 128 | 1,71e-6 | 2,00 % | 15,13 % |

Breite 64 hatte in diesem Vergleich den niedrigsten aggregierten Medianfehler
und mittleren Absolutfehler; der niedrigste P95 trat bei Breite 32 auf. Die
Ergebnisse zeigen keinen monotonen Gewinn durch weiteres Verbreitern.
Breite 100 verschlechtert alle drei aggregierten Kennzahlen gegenüber 64
und 80 Neuronen. Breite 128 verbessert die drei Kennzahlen gegenüber 100,
bleibt bei Absolutfehler und Median aber hinter 64 und 80 zurück. Die
Einzelergebnisse aller Seeds und Fälle stehen in `model_metrics.csv` und
`validation_case_errors.csv`; `summary_by_width.csv` enthält die Aggregation.
`error_by_width.png` und `error_by_case.png` sind die exportierten MATLAB-
Plots, die editierbaren MATLAB-Figuren liegen als `.fig` daneben.

## POD-Rangstudie

`examples/runPodMlpRankStudy.m` vergleicht POD-Ränge 1, 2, 4, 6, 8, 10,
15 und 20 bei Breite 64 und zwei versteckten Schichten. Konstant bleiben
`weighted_field_mse`, `tanh`, Adam mit Lernrate 0,001, 200 Epochen,
Batchgröße 32 und dieselben 768 Trainingsfälle mit derselben Reihenfolge
je Seed 42/43/44. Die drei bestehenden Rang-10-Modelle aus der Breitenstudie
dienen als Kontrolle; die anderen 21 Modelle werden neu trainiert.

Bewertet werden ausschließlich die bereits verwendeten 128 Validierungsfälle
813001–813128. Der Vergleich bleibt explorativ; Testdaten werden nicht geladen.
Die POD-Basis und die Normierung werden allein aus Trainingsdaten bestimmt.
Erhaltene POD-Energie bezeichnet die gewichtete, zentrierte Variation der
Trainingsfelder und ist keine Genauigkeitsangabe für die Netzvorhersage.

Zusätzlich zur vollständigen POD-MLP-Vorhersage wird das Referenzfeld auf die
jeweilige Trainings-POD-Basis projiziert. Der Fehler dieser Projektion misst
die Begrenzung durch die Modenzahl bei exakt bekannten Koeffizienten. Er ist
eine Diagnose mit Referenzdaten, keine praktisch verfügbare Netzvorhersage.
Der Runner prüft die gewichtete quadratische Zerlegung in Projektionsfehler
und Koeffizientenvorhersagefehler für jeden Fall. Eine Rangänderung verändert
auch die Ausgabedimension, die Initialisierung und die gemeinsame RMS-Skala
der Zielkoeffizienten in der bestehenden Implementierung.

Ergebnisse und wiederaufnehmbare Modellartefakte liegen unter
`experiments/pod_mlp_rank_study_20261110/`. `model_metrics.csv` enthält die
Seed-Metriken und `validation_case_errors.csv` die einzelnen Fallfehler.
`summary_by_rank.csv` aggregiert per Median über die drei Seeds. Der P95 wird
pro Modell als Nearest Rank über die 128 Fälle berechnet. `model_manifest.csv`
dokumentiert Pfade, SHA-256-Hashes und wiederverwendete Kontrollen.
`error_by_rank.fig/.png` zeigt den Rangvergleich;
`pod_projection_diagnostics.fig/.png` zeigt die POD-Diagnose.

Der Lauf ist abgeschlossen: 24 Modellbewertungen auf jeweils 128 Fällen,
darunter 21 neu trainierte Modelle und drei unveränderte Rang-10-Kontrollen.
Die Kontrolle reproduziert die bisherigen Absolut-, Median- und P95-Metriken.

| POD-Rang | Mittlerer Absolutfehler [µm] | Median relativ | P95 relativ |
|---:|---:|---:|---:|
| 1 | 2,25 | 3,14 % | 25,01 % |
| 2 | 1,49 | 1,76 % | 14,93 % |
| 4 | 1,81 | 2,22 % | 24,92 % |
| 6 | 1,54 | 2,04 % | 14,75 % |
| 8 | 1,46 | 1,74 % | 17,31 % |
| 10 | 1,51 | 1,61 % | 13,72 % |
| 15 | 1,20 | 1,32 % | 12,05 % |
| 20 | 1,41 | 1,75 % | 15,89 % |

Alle Tabellenwerte sind Mediane über die drei Seed-Metriken. Rang 15 ist in
diesem Vergleich bei allen drei aggregierten Kennzahlen am besten; sein
Medianfehler liegt etwa 18 % unter Rang 10. Eine monotone Verbesserung mit
steigendem Rang ist nicht erkennbar. Der reine POD-Projektionsmedian sinkt
von 1,384 % bei Rang 1 auf 0,0469 % bei Rang 2 und 0,000308 % bei Rang 15.
Ab Rang 2 ist der Darstellungsfehler damit viel kleiner als der gesamte
Netzfehler. Der Vorteil von Rang 15 belegt keine entsprechend große Verbesserung
der POD-Darstellung; Rang beeinflusst zugleich das zu trainierende Netz.
Dies ist eine explorative Rangwahl bei festem Trainingsbudget, keine neue
unabhängige Testbewertung oder universelle Aussage zum optimalen POD-Rang.

```matlab
addpath('examples')
result = runPodMlpRankStudy();
```

## Frischer Vergleich der beiden POD-MLP-Losses

`runPodMlpFreshValidationComparison(OUTPUTDIR,CASECOUNT,DESIGNSEED,IDSTART)`
friert die 210 historischen
`per_coefficient_mse`-Modelle und die 210 `weighted_field_mse`-Modelle ein und
vergleicht sie auf neuen statischen Validierungsfällen. Ohne weitere
Argumente verwendet die Funktion 12 Fälle, Seed `20261108` und IDs ab
`812001`. Die Modelle
decken Breiten 64/128, Tiefen 1–5, Trainingsmengen 12/24/48/96/192/384/768
und Seeds 42/43/44 ab. Jedes alte/neue Modellpaar muss dieselben Trainings-
Fall-IDs verwenden. Alle Modellartefakte werden geladen, auf Konfiguration und
Trainings-IDs geprüft und mit SHA-256 gehasht, bevor neue FEM-Labels entstehen.

Der Lauf erzeugt anschließend einen nur aus Validierungsfällen bestehenden
statischen Entwurf mit den übergebenen Seed- und ID-Werten. Im Standardfall
sind dies Seed `20261108` und IDs 812001–812012. Er
prüft ID- und exakte Parameterzeilen-Überschneidungen mit den bekannten
Designs und startet `run_data_generation_v2("static_val", ...)`; Training,
Testlabels und erneutes Training werden nicht ausgeführt. Die neuen Fälle
bleiben Validierungsdaten, nicht ein finaler Testsplit. Werden sie danach für
Modell- oder Loss-Auswahl verwendet, sind sie nicht mehr unangetastet.

Der Standard-Ausgabeordner ist
`experiments/pod_mlp_fresh_validation_20261108/` und muss neu sein. Die
Ausgabe enthält vor Beginn der FEM-Referenzberechnung `model_freeze.csv`,
`model_freeze.mat` und `FREEZE_BEFORE_LABELS.txt`. Nach der Auswertung werden
`model_metrics.csv` (420 Modell-/Seed-Zeilen),
`validation_case_errors.csv` (420 × CASECOUNT Modell-/Fall-Zeilen; bei 12
Fällen 5.040, bei 128 Fällen 53.760),
`comparison_by_architecture.csv` (70 Architektur-/Trainingsmengen-Zeilen)
und `summary_by_training_count.csv` geschrieben. Die Architekturvergleiche
aggregieren jeweils die drei Seeds per Median; Seeds zählen nicht als
zusätzliche FEM-Fälle. Relative Fehler werden in Prozent ausgegeben und der
P95 verwendet Nearest Rank. Die vollständigen MATLAB-Ergebnisse und
Metadaten liegen zusätzlich in `fresh_validation_comparison.mat`.

Aufruf aus dem Ordner `Code v2` in MATLAB:

```matlab
addpath('studies/static_final_evaluation')
result = runPodMlpFreshValidationComparison();
```

Für eine zusätzliche, nicht überlappende 128-Fall-Stichprobe wird ein eigener
Ausgabeordner, Seed und ID-Bereich verwendet, zum Beispiel:

```matlab
result = runPodMlpFreshValidationComparison( ...
    'experiments/pod_mlp_fresh_validation_128_20261108', ...
    128, 20261109, 813001);
```

Die Fälle sind eine unabhängige Validierungsstichprobe gegenüber den
vorherigen Designs. Der P95 ist bei zwölf Fällen der größte Einzelwert und
bei 128 Fällen der 122. Wert der sortierten Fehler; auch mit 128 Fällen
bleibt er eine Schätzung mit Stichprobenunsicherheit.
Für eine endgültige unverzerrte Leistungsangabe darf die Architektur nicht
nach Sichtung dieser Vergleichsergebnisse ausgewählt und anschließend auf
denselben Fällen als unabhängig bewertet werden.

## Optimizer-Pilot: Adam, RMSProp und SGDM

`runPodMlpOptimizerPilot(OUTPUTDIR)` hält die bevorzugte
`weighted_field_mse`, `tanh` und die übrigen Studieneinstellungen konstant.
Verglichen werden Adam (bestehende gewichtete Modelle als Kontrolle), RMSProp
und SGDM für 128 Neuronen, 1 bzw. 2 versteckte Schichten, 768 Trainingsfälle
und Seeds 42/43/44. Alle Modelle verwenden dieselben Trainingsfall-IDs je
Seed und werden auf denselben 128 Validierungsfällen aus
`pod_mlp_fresh_validation_128_20261108` ausgewertet.

Für RMSProp und SGDM werden jeweils sechs Modelle neu trainiert (2 Optimizer
× 2 Tiefen × 3 Seeds). Lernrate 0,001, maximal 200 Epochen, Batchgröße 32,
CPU-Ausführung und letzte Epoche bleiben wie in der bisherigen Studie. Die
Optimizer-spezifischen Standardwerte von MATLAB für zusätzliche Parameter
wie Momentum bzw. Quadratskalierung werden verwendet; es findet in diesem
Pilot keine individuelle Hyperparameteroptimierung pro Optimizer statt.
Dieser Vergleich beantwortet deshalb zunächst, wie die Verfahren mit den
gleichen allgemeinen Einstellungen abschneiden, nicht welches Verfahren nach
separater Hyperparameteroptimierung das beste wäre.

Die Adam-Kontrollen werden vor dem Neutraining auf passende Konfiguration und
Trainings-IDs geprüft und samt SHA-256 in `adam_control_freeze.csv`
dokumentiert. `model_metrics.csv`, `validation_case_errors.csv` und
`model_manifest.csv` werden nach jedem abgeschlossenen Modell aktualisiert.
Die abschließenden Dateien `summary_by_optimizer.csv` und
`optimizer_comparison.csv` berichten Median über Seeds für mittleren
Absolutfehler, Median und P95 des relativen Feldfehlers. Ein vorhandener
Ausgabeordner wird nicht überschrieben; Standard ist
`experiments/pod_mlp_optimizer_pilot_20261108/`.

Die 128 Validierungsfälle wurden bereits für frühere Modellvergleiche
verwendet; der Optimizer-Pilot ist daher explorativ und nicht als unabhängige
Abschlussprüfung zu interpretieren. Aus `Code v2` starten:

```matlab
addpath('studies/static_final_evaluation')
result = runPodMlpOptimizerPilot();
```

## Adam-Lernratenstudie

`runPodMlpLearningRateStudy(OUTPUTDIR)` hält Adam, `weighted_field_mse`,
`tanh`, 128 Neuronen, 768 Trainingsfälle, POD-Rang 10, 200 Epochen,
Batchgröße 32 und Seeds 42/43/44 konstant. Verglichen werden feste Lernraten
`1e-4`, `3e-4`, `1e-3`, `3e-3` und `1e-2` für eine und zwei versteckte
Schichten. Das sind 30 Lernrate-/Tiefen-/Seed-Kombinationen. Die sechs
bestehenden Modelle mit Lernrate `1e-3` dienen als eingefrorene Kontrolle;
die übrigen 24 Modelle werden neu trainiert. Für jeden Seed werden exakt
dieselben 768 Trainings-IDs verwendet. Alle Modelle werden auf denselben 128
Validierungsfällen bewertet.

Der Lauf schreibt die verwendeten Seeds und IDs, MATLAB-Version,
Metrikdefinition, Lernraten und Adam-Kontrollhashes in den Ausgabeordner.
Jedes neue Modell wird gespeichert und in CSV/MAT-Checkpoints protokolliert,
damit ein unterbrochener Lauf mit identischem Studienordner fortgesetzt
werden kann. Hauptkennzahl ist der mittlere absolute gewichtete Feldfehler;
Median und Nearest-Rank-P95 des relativen Feldfehlers werden ergänzend
berichtet. Für Vergleiche wird zuerst pro Modell/Seed aggregiert und danach
der Median über die drei Seeds gebildet.

Die fünf Lernraten wurden mit derselben Epochenzahl und ohne Lernratenplan
getestet. Bei einer Schicht waren `0.003` bei Hauptkennzahl und Median am
besten; bei zwei Schichten gewann `0.001` bei allen drei Kennzahlen. Über
beide Tiefen gemittelt war `0.003` nach mittlerem absoluten Fehler am besten;
`0.01` hatte einen knapp kleineren mittleren P95. Die Ergebnisse sind
tiefenabhängig und begründen keine universell optimale Lernrate. Da die
Validierungsfälle bereits für andere Vergleiche verwendet wurden, bleibt der
Lernratenlauf explorativ. Vollständige Tabellen stehen in
`experiments/pod_mlp_learning_rate_study_20261108/`; der Studienbericht
enthält die Ergebnisinterpretation. Standardausgabe:
`experiments/pod_mlp_learning_rate_study_20261108/`.

```matlab
addpath('studies/static_final_evaluation')
result = runPodMlpLearningRateStudy();
```

Jeder Seed ist ein eigener Lauf und wird nicht als unabhängiger FEM-Fall
gezählt. Fehlgeschlagene Modellartefakte werden in `run_status.csv` mit
Fehlermeldung protokolliert; erfolgreiche Modelle werden trotzdem ausgewertet.
`study_config.mat`, `results.mat`, CSV-Dateien und Plots werden nur in einem
neuen Ausgabeordner angelegt. Vorhandene Ergebnisordner werden nicht
überschrieben. Datenkennung und Artefaktpfade sind dokumentierte Angaben;
Hashes oder ein tatsächlicher Freeze werden nicht verifiziert.

## Softwaretest

```matlab
results = runtests({'tests/surrogateContractTest.m', ...
    'tests/podMlpTest.m', 'tests/staticFinalEvaluationTest.m'});
```

Der Ablauf- und Kennzahlentest erzeugt ausschließlich synthetische Daten und
Dummy-Modelle in einem temporären Ordner. Er prüft mehrere Modelle auf denselben
Fällen, Fall-IDs, ungültige Artefakte, Modellfehler, undefinierte relative
Werte und den Schutz vor Überschreiben. Diese Tests öffnen keine produktiven
Testlabels und führen keine FEM aus.
