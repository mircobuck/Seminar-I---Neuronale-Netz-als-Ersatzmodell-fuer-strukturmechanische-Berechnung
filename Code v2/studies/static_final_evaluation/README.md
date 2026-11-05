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
