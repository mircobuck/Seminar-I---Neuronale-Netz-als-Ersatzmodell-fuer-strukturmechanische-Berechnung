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
