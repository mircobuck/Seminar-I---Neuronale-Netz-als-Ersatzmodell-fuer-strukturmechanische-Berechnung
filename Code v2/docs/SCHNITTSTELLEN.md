> Aktualisierung 12.11.2026: Die aktive statische Studiensteuerung ist `runStaticStudy` unter `workflows/static_comparison`. Unten stehende Aussagen zum damaligen Implementierungsstand sind historisch. Daten-/Modellvertrag und numerische Formate bleiben erhalten. Die gemeinsame Aggregation steht jetzt in `surrogate.study.summarizeErrors`; Mittelwert bleibt in Fallreihenfolge, P95 verwendet Nearest Rank.

# Schnittstellenvertrag für FEM-Ersatzmodelle – Version 1

Dieser Vertrag ist die gemeinsame Arbeitsgrundlage für Modellteams und die
Testarchitektur. Die Funktionen liegen im MATLAB-Paket `+surrogate` im Ordner
`Code v2`. `surrogate-v1` kennzeichnet diese Schnittstelle. Neue inkompatible
Änderungen benötigen eine neue Version und eine dokumentierte Migration.

## Daten

`data = surrogate.loadDataset(filePath)` liest die bestehende Code-v2-MAT-Datei
und die `design.csv` im selben Ordner; gespeicherte FEM-Daten bleiben unverändert.
Die Funktion prüft Schema, Fall-IDs, Split und Parameter gegen das Design sowie
den Vertrag. Für synthetische Daten kann `surrogate.validateDataset(data)` direkt
verwendet werden. Das Laden ist lesend; der Aufruf schützt Testdaten nicht
technisch vor Einsicht. Die Testdisziplin ist organisatorisch einzuhalten.

| Feld | Bedeutung |
|---|---|
| `contractVersion` | `"surrogate-v1"` |
| `modality` | `"static"` oder `"modal"` |
| `split` | `"train"`, `"val"` oder `"test"` |
| `caseIds` | N × 1 eindeutige ganzzahlige Fall-IDs im Split |
| `inputParameters` | N × 6 endliche, reelle Eingabeparameter |
| `parameterNames`, `parameterUnits` | sechs Namen und Einheiten in der angegebenen Reihenfolge |
| `displacementFields` | nur statisch: 1575 × N, in m, ein Fall pro Spalte |
| `normalizedGridCoordinates` | nur statisch: 3 × 525, normiertes 21 × 5 × 5-Gitter |
| `displacementComponentWeights` | nur statisch: 1575 × 1 positive Gewichte |
| `naturalFrequenciesHz` | nur modal: N × 6, in Hz, ein Fall pro Zeile |
| `modeIndices`, `frequencyUnit` | nur modal: `(1:6)'` und `"Hz"` |

Statisch: Namen `[L_m, b_m, h_m, E_Pa, nu, Fz_N]`, Einheiten
`[m, m, m, Pa, 1, N]`. Modal: `[L_m, b_m, h_m, E_Pa, nu, rho_kg_m3]`,
Einheiten `[m, m, m, Pa, 1, kg/m^3]`. Die Feldvektoren enthalten jeweils die
525 `ux`-, dann `uy`-, dann `uz`-Werte. Die Gitterreihenfolge entspricht
`ndgrid(linspace(0,1,21),linspace(0,1,5),linspace(0,1,5))`, jeweils mit `(:)`.
Gewichte stammen aus den Referenzdaten; die Feldmetrik verwendet sie direkt.
`loadDataset` ergänzt bekannte Einheiten aus diesem Vertrag; sie sind nicht als
separate Metadaten in den vorhandenen MAT-Dateien gespeichert.

## Training und Implementierung eines Verfahrens

```matlab
[model, trainingReport] = surrogate.fitModel(methodId, trainingData, config);
```

`trainingData.split` muss `"train"` sein. `config` ist eine skalare Struktur und
benötigt `seed` (nichtnegative Ganzzahl für MATLABs Zufallszahlengenerator) und
`datasetId` (nichtleerer, vom aufrufenden Studienprozess vergebener Bezeichner).
Die Kennung ist ein Metadatum und wird nicht automatisch als Hash verifiziert.
Weitere Optionen sind verfahrensspezifisch. Die Fit-Funktion erhält keine
Validierungs- oder Testlabels. Der Zufallszustand wird nach dem Training wiederhergestellt.

Ein Verfahren `methodId`, z. B. `beam_mlp`, besteht aus
`+surrogate/+models/+beam_mlp/fit.m` und `predict.m`. IDs bestehen aus kleinen
Buchstaben, Ziffern und Unterstrichen und beginnen mit einem Buchstaben.

```matlab
% Im Paket des Verfahrens:
[state, report] = fit(trainingData, config);
Y = predict(state, inputParameters);
```

`state` und `report` sind skalare Strukturen. `state` enthält trainierte
Parameter und alle zur Vorhersage nötigen Transformationen. Die gemeinsame
Funktion ergänzt Modellkennung, Aufgabe, Parameterkonvention, Trainings-IDs,
Konfiguration und MATLAB-Version. Verfahren dokumentieren zusätzliche nötige
Toolboxes und Implementierungsversionen in `state` oder `report`. Beim Laden muss
die Implementierung des Verfahrens und ihre Abhängigkeiten verfügbar sein.
Keine Function-Handles mit temporären oder externen Pfaden als persistente
Schnittstelle verwenden. `+dummy` ist nur ein synthetisches Vertragsbeispiel,
kein wissenschaftliches Ersatzmodell.

Training und Modellauswahl sind getrennt: Die Fit-Funktion trainiert eine
Konfiguration. Eine zukünftige Studiensteuerung muss Kandidaten, Validierung,
Auswahl und Freeze explizit durchführen. Sie ist hier noch nicht implementiert.
Vor der Modellentwicklung prüft `surrogate.validateTrainingSplits(train,val)`
Aufgaben, Splitrollen sowie identische IDs und Parameterzeilen zwischen beiden
Splits. Für statische Daten müssen Gitter und Gewichte übereinstimmen. Dies ist
eine exakte Duplikatprüfung und kein Nachweis statistischer Unabhängigkeit.

## Vorhersage und Artefakt

```matlab
request = struct('inputParameters', data.inputParameters, ...
    'parameterNames', data.parameterNames, ...
    'parameterUnits', data.parameterUnits, 'caseIds', data.caseIds);
prediction = surrogate.predictModel(model, request);
surrogate.saveModel('model.mat', model);  % Ziel darf nicht existieren
model = surrogate.loadModel('model.mat');
```

`request` enthält keine Referenzlabels. Die eindeutigen ganzzahligen `caseIds`
stehen in derselben Reihenfolge wie die Eingaben; für neue Anfragen können eigene
IDs verwendet werden. Sie werden unverändert in `prediction` übernommen. Das
Verfahren muss seine Ausgaben in derselben Fallreihenfolge zurückgeben; IDs
erlauben der Auswertung, unterschiedliche Reihenfolgen zwischen Vorhersage und
Referenz zu erkennen, beweisen aber nicht die interne Zuordnung eines Modells.

Das Verfahren gibt physikalische, rücktransformierte Werte zurück: statisch
1575 × N in Metern, modal N × 6 in Hz. Der Wrapper prueft Parameterreihenfolge und Einheiten der Anfrage, das
Modellgitter sowie Groesse und endliche reelle Werte der Ausgabe. Es findet keine
FEM-Berechnung, Sortierung oder Korrektur der Vorhersage statt. Ein neues Modell
entspricht genau einer Aufgabe. Die Implementierung ist unter der Paketkennung
auffindbar; unbekannte Kennungen führen zu einem Fehler.

## Gemeinsame Metriken

```matlab
options = struct('staticReferenceFloor', 0, ...
    'frequencyReferenceFloorHz', 0);
evaluation = surrogate.evaluatePrediction(prediction, referenceData, options);
```

Validierung und Abschlusstest verwenden dieselbe Funktion. Referenz und
Vorhersage müssen dieselben Fall-IDs in derselben Reihenfolge haben. Die
Schwellen sind endliche nichtnegative Werte und werden im Ergebnis dokumentiert.
Bei einer Referenznorm bzw. Frequenz **kleiner oder gleich** dem jeweiligen
Schwellwert ist der relative Fehler `NaN`, und `relativeErrorDefined` ist false.
Zusätzlich wird der absolute Fehler ausgegeben; ungültige relative Fehler dürfen
nicht stillschweigend als null interpretiert werden.

Statisch: Für jeden Fall `sqrt(sum(w .* (prediction-reference).^2))` und die
entsprechende gewichtete Referenznorm; der relative Fehler ist ihr Quotient.
Modal: absoluter Fehler in Hz und relativer Fehler pro Fall und Frequenz.
`nonpositivePrediction` und `nonmonotonePrediction` markieren Auffälligkeiten;
Werte werden nicht verändert. Die gemeinsame Funktion liefert Fehler pro Fall;
Aggregation und Studienprotokoll gehören in die jeweilige Studiensteuerung.
Für den statischen Vergleich werden Median, arithmetischer Mittelwert,
Nearest-Rank-P95 und Maximum der relativen gewichteten L2-Fallfehler berichtet.
Die Hauptmetrik ist der Mittelwert. Null-Referenzen werden ausgeschlossen und
gezählt, nicht durch einen künstlichen Nenner ersetzt. Bei zwölf Fällen ist
Nearest-Rank-P95 das Maximum. Statistiken werden zuerst pro Seed über die
Balkenfälle berechnet. Eine Zusammenfassung über Seeds muss ihre Aggregation
ausdrücklich benennen; Seeds sind keine zusätzlichen unabhängigen Balkenfälle.
Der statische Abschlusstest unter
`studies/static_final_evaluation/` aggregiert Mittelwert, Median,
Nearest-Rank-P95 und Maximum, dokumentiert `NaN`-Gründe und erzeugt eigene
Ergebnisdateien. Er ist getrennt vom Validierungsplot und trainiert weder
Modelle noch startet er FEM.

## Prüfungen und Grenzen

In `Code v2` ausführen:
`results = runtests('tests/surrogateContractTest.m');`. Der separate
synthetische Abschlusstest wird mit
`runtests('tests/staticFinalEvaluationTest.m')` geprüft. Er liest keine
produktiven Testlabels. Der Prüfstand schützt Testdaten nicht technisch vor
Zugriff; Modellauswahl, Freeze-Stand und bekannte Nutzungshistorie müssen
vorher dokumentiert werden. Die zwölf Validierungsfälle stellen keine Garantie
für eine stabile Auswahl dar.

Die Checks erkennen formale Abweichungen. Ein fehlerhaftes Verfahren kann eine
falsche interne Reihenfolge oder Skalierung trotzdem behaupten; jedes Modellteam
muss daher eigene aussagekräftige numerische Tests ergänzen. Datei- und
Versionsmetadaten ersetzen keine vollständige Reproduzierbarkeitsprüfung.

## Validierungsgrenzen nach dem Cleanup (2026-11-11)

`surrogate.loadDataset` prueft den Datenvertrag einmal beim Laden und gleicht
Fall-IDs, Split und Parameter mit `design.csv` ab. Die CSV wird dabei nur einmal
gelesen; `loadFemDataset` liefert sie bei Bedarf als zweiten Rueckgabewert.
`fitModel`, `validateTrainingSplits`, `plotStaticComparison` und
`evaluatePrediction` setzen diese Datenstruktur voraus und wiederholen die
vollstaendige Datensatzpruefung nicht. Manuell aufgebaute oder strukturell
veraenderte Daten koennen ausdruecklich mit `surrogate.validateDataset` geprueft
werden. Die Feldnamen und Dimensionen des Vertrags gelten weiterhin.

Modellartefakte aus `fitModel` werden ohne wiederholte Feldlistenpruefung geladen
und gespeichert. Fehlende Pflichtfelder und Dateien melden die MATLAB-Zugriffe
selbst. `predictModel` erwartet Modelle aus dieser Pipeline und Anfragen im
beschriebenen Format; es validiert nicht mehr saemtliche Eingabefelder und IDs.

Erhalten bleiben fachliche Pruefungen: Split-Rollen und Ueberschneidungen,
Zuordnung von Vorhersagen zu Referenzfaellen, Parameterreihenfolge und Einheiten,
Gitter, numerische Ausgaben, POD-Rang und Trainingsoptionen. Ebenso bleiben
Ueberschreibschutz, Checkpoint-/Hash-Abgleiche und Vollstaendigkeitspruefungen der
Studien bestehen. Optionale `lossMode`-/`optimizer`-Felder und historische
Modellvarianten benoetigen weiterhin `isfield`. Die Regressionstests pruefen
Berechnung und Ablauf unabhaengig von diesen Laufzeitabsicherungen.

## Direkte MLP- und RBF-Modelle

Mircos Modelle sind als `mlp` und `rbf` in `+surrogate/+models` integriert.
Das MLP hat eine tanh-Schicht und eine lineare Ausgabe. Das RBF verwendet
feste Gauss-Zentren aus gleichmaessig verteilten Trainingszeilen und trainiert
nur die lineare Ausgabe. Beide unterstuetzen statische Felder und modale
Frequenzen. `pod_mlp` bleibt die separate Variante mit POD-Reduktion.

```matlab
addpath('examples');
cfg = struct('seed',42,'hiddenWidth',64,'maxEpochs',200,'optimizer',"adam");
[model,report,metrics] = runDirectNeuralExample("mlp","static",cfg);
% Alternativ: method="rbf", mit centerCount=64 und rbfWidth=1.
% Anschliessend kann das Modell mit surrogate.saveModel gespeichert werden.
```

Die Methoden funktionieren direkt mit `surrogate.fitModel`, `predictModel`,
`evaluatePrediction`, `saveModel` und `loadModel`. Es genuegt, `Code v2`
auf den MATLAB-Pfad zu setzen; `Testverfahren` ist keine Abhaengigkeit.
Die alten MLP-/RBF-Skripte sind jetzt Aufrufbeispiele fuer diese Schnittstelle.

Konfiguration (neben dem Pflichtfeld `seed`):

| Feld | Standard | Bedeutung |
| --- | --- | --- |
| `hiddenWidth` | 64 | Neuronen der einen MLP-Schicht |
| `centerCount` | 64 | RBF-Zentren, maximal Anzahl Trainingsfaelle |
| `rbfWidth` | 1 | Gauss-Breite im standardisierten Eingaberaum |
| `optimizer` | `"adam"` | `"adam"`, `"sgdm"`, `"levenberg-marquardt"`, `"bayesian-regularization"` |
| `maxEpochs` | 200 | Maximale Trainingsepochen |
| `miniBatchSize` | 32 | Adam-/SGDM-Batchgroesse |
| `learningRate` | 1e-3 | Adam-/SGDM-Lernrate |
| `momentum` | 0.9 | SGDM-Momentum |
| `maxWorkspaceBytes` | 1073741824 | Obergrenze der LM-/BR-Speicherschaetzung |

`"sgd-momentum"` wird als Alias fuer `"sgdm"` akzeptiert. Die aufgeloesten
Optionen stehen in `model.state.settings` und `report.settings`.
Deep Learning Toolbox wird benoetigt. LM/BR verwenden `feedforwardnet`.
Die konservative Schaetzung aus Jacobi- und Hesse-Matrix weist grosse direkte
Feldmodelle vor dem Training ab; sie garantiert keinen festen RAM-Verbrauch.
Fuer statische Felder mit 1575 Ausgaben vorzugsweise Adam oder SGDM verwenden.

Mittelwerte und Standardabweichungen stammen nur aus dem Trainingssplit.
Konstante Ausgaben werden exakt rekonstruiert. Das Trainingsziel ist die MSE
pro standardisierter Ausgabe, nicht die gewichtete physikalische Feld-MSE.
Die Auswertung erfolgt trotzdem mit den gemeinsamen physikalischen Metriken.
Anders als die urspruenglichen Skripte verwenden die Adapter keine Validierung
zur Epochenwahl: Adam/SGDM liefern die letzte Iteration; LM/BR nutzen alle
uebergebenen Trainingsfaelle ohne internen Validierungs- oder Testsplit.
Dadurch sind alte Trainingsresultate nicht numerisch identisch reproduzierbar.

Integrationstests: `runtests('tests/directNeuralTest.m')`.

## Adam-Tiefenstudie fuer direkte MLP/RBF

`hiddenLayers` (Standard 1) steuert die Gesamtzahl versteckter Schichten.
Beim MLP sind das `hiddenLayers` tanh-Schichten mit je `hiddenWidth` Neuronen.
Beim RBF zaehlt die feste Gauss-Schicht mit: Es folgen `hiddenLayers-1`
tanh-Schichten mit je `hiddenWidth` Neuronen. Zentren und Gauss-Breite bleiben
fest. Die lineare Ausgabeschicht zaehlt bei beiden Methoden nicht mit.
RBF mit Tiefe 2 oder 3 ist damit ein RBF+tanh-Hybrid.

Die Studie `examples/runDirectNeuralDepthStudy.m` vergleicht beide Methoden
mit 64 Einheiten und 1/2/3 versteckten Schichten, Adam, 200 Epochen,
Lernrate 0.001, Batch 32 und drei Seeds (42/43/44). Sie verwendet 768 statische
Trainingsfaelle und die bereits genutzten 128 Validierungsfaelle. Testdaten
werden nicht geladen. Checkpoints, Daten-/Code-Hashes, Fallfehler, aggregierte
Metriken und ein Vergleichsplot werden im Studienordner gespeichert.

```matlab
addpath('examples');
summary = runDirectNeuralDepthStudy();
```

Start erfordert mindestens 1 GiB freien Platz; vor jedem neuen Training
werden mindestens 256 MiB verlangt. Nach einer Unterbrechung kann derselbe
Aufruf abgeschlossene Checkpoints wiederverwenden, sofern Code, Daten und
Konfiguration unveraendert sind.


## POD?GPR: Implementierung im Erprobungsstand

`surrogate.fitModel("pod_gpr", train, config)` trainiert ein skalares exaktes
GPR je gewichteter POD-Mode. `config` ben?tigt `rank`, `seed` und `datasetId`;
optional sind `kernel` (`ardsquaredexponential` oder `ardmatern52`),
`basisFunction` (`constant` oder `linear`) und `sigma` (Standard `1e-4`).
Die konstante numerische Sigma-Stabilisierung ist keine Messrauschannahme.
Zwei Startwerte und Warnungen stehen im Modellzustand; vollst?ndige Felder
werden durch die bestehende Vorhersageschnittstelle in Metern ausgegeben.

`surrogate.models.shared.fitPod` erzeugt die gemeinsame gewichtete Basis.
Ein unter `config.preparedPod` ?bergebener Zustand wird gegen einen SHA-256
Fingerabdruck von Feldern, Parametern, Gewichten und sortierungserhaltenden
Fall-IDs sowie gegen den Rang gepr?ft. Die Modellzust?nde sind nicht gegen
b?swillige Manipulation der Basis selbst abgesichert.

F?r direkte statische MLP/RBF-Modelle kann explizit
`lossMode="weighted_field_mse"` gew?hlt werden; der bisherige Standard bleibt
`standardized_output_mse`. Modellberichte enthalten Segmentzeiten.
Der neue unabh?ngige Studienablauf ist noch nicht fertiggestellt. Die
explorativen Piloten unter `experiments/static_pod_gpr_20261111` sind kein
Abschlusstest.
