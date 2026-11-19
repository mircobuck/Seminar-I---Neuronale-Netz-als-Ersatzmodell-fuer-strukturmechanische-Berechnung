# Aktueller statischer Schnittstellenvertrag

`surrogate-v1` bleibt das Speicherformat fuer statische Daten und Modelle. Der aktive Umfang ist auf `static` und die Methoden `mlp`, `rbf`, `pod_mlp`, `pod_gpr` begrenzt. Historische modale Modelle erfordern ihre Quellen aus Git-Commit `4e83631`.

## Daten

`surrogate.loadDataset(filePath)` liest die vorhandene MAT-Struktur D und die benachbarte `design.csv`, prueft IDs, Parameter, Rollen und physikalische Einheiten. Es schreibt keine Referenzen um. `surrogate.validateDataset(data)` prueft synthetische Vertragsdaten.

| Feld | Form und Bedeutung |
|---|---|
| contractVersion, modality, split | surrogate-v1; static; train/val/test |
| caseIds | N eindeutige ganzzahlige IDs |
| inputParameters | N x 6: L_m, b_m, h_m, E_Pa, nu, Fz_N |
| parameterNames, parameterUnits | obige Reihenfolge; m, m, m, Pa, 1, N |
| displacementFields | 1575 x N in Metern; ux, uy, uz mit je 525 Werten |
| normalizedGridCoordinates | 3 x 525; ndgrid auf 21 x 5 x 5 normierten Punkten |
| displacementComponentWeights | 1575 x 1 positive Gewichte aus den Referenzdaten |

`validateTrainingSplits(train,val)` prueft Rollen, Aufgaben, gleiche Gitter/Gewichte sowie disjunkte IDs und Parameterzeilen. Exakte Duplikatfreiheit beweist keine statistische Unabhaengigkeit. Diese Schutzpruefungen bleiben aktiv.

## Training und Vorhersage

```matlab
[model, report] = surrogate.fitModel(methodId, train, config);
surrogate.saveModel("model.mat", model);
model = surrogate.loadModel("model.mat");
request = struct('inputParameters', val.inputParameters, ...
    'parameterNames', val.parameterNames, 'parameterUnits', val.parameterUnits, ...
    'caseIds', val.caseIds);
prediction = surrogate.predictModel(model, request);
metric = surrogate.evaluatePrediction(prediction, val, ...
    struct('staticReferenceFloor', 1e-12));
```

Training verlangt den Split train und explizite seed/datasetId. Der Zufallszustand wird wiederhergestellt. Die vier dynamischen Paketaufrufe werden durch feste Methodenzulassung und praktische Tests abgesichert. Direkte Netze und POD-MLP verwenden den bestehenden Adam/trainnet-Ablauf mit letzter Trainingsiteration; POD-GPR behaelt fitrgp. Numerische Normalisierung, Gewichte, Loss, POD-Rekonstruktion und Feldreihenfolge bleiben erhalten. saveModel lehnt Ueberschreiben ab; Modelle enthalten Transformationen, Vertragsmetadaten und Trainingskonfiguration.

Die Vorhersage braucht Eingaben und Modell, keine FEM- oder Referenzlabels. Ausgaben enthalten caseIds, displacementFields und das normierte Gitter. Die Auswertung verlangt identische Fall- und Gitterreihenfolge. Pro Fall gilt absolut sqrt(sum(w.*(Y-R).^2)) und relativ absolut/sqrt(sum(w.*R.^2)); unterhalb der expliziten Referenzschwelle ist der relative Fehler undefiniert. summarizeErrors aggregiert in Fallreihenfolge, P95 mit Nearest Rank.

## Studiensteuerung

runStaticStudy zeigt ohne Argument nur Hilfe. Explizite Phasen: init, generate, tune, train, freeze, evaluate, benchmark, report. Fachliche Auswahl ausschliesslich auf Validierung; Testreferenzen werden im oeffentlichen Ablauf erst nach Freeze geladen. Freeze ist eine Ablaufkontrolle, keine Dateisystem-Zugriffssperre.

Quell-/Inputmanifeste und Checkpoints binden Code, Konfiguration und Daten. Ein geaenderter Quellstand verlangt einen neuen Laufordner. report liest gespeicherte Tabellen und erzeugt Diagramme mit dem aktuellen studyPlots.py; es trainiert nicht und berechnet keine FEM. Alte Laufmanifeste werden durch die Bereinigung nicht umgeschrieben. Vorhandene Tabellen lassen sich unabhaengig mit examples/showStaticResultsExample.m darstellen.
