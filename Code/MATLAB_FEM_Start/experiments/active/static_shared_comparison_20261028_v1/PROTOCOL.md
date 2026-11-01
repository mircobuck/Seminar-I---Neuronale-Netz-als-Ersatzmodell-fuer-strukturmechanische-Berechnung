# Gemeinsamer statischer Modellvergleich v1

## Status und Umfang

Dieses Studienpaket vergleicht bei n=384 das analytische Balkenfeld, das
gespeicherte neuronale POD-MLP und Balken-Restfeld-MLP (je Seeds 42, 43, 44),
das vorhandene POD-GPR sowie ein neu gefittetes Balkenfeld-plus-POD-GPR auf
dem Restfeld. Die versionierte Festlegung steht in
`configs/static_shared_comparison_20261028_v1.json`.

Der Vergleich bewertet konkrete eingefrorene Modellvarianten auf denselben
Feldpunkten und Referenzfällen. Er isoliert nicht den kausalen Effekt der
Regressionsmethode: POD-Rang, Feldrepräsentation, Normierung, historische
Hyperparameterwahl und Trainingsverfahren unterscheiden sich. Ergebnisse aus
dem technischen Probelauf auf den bekannten IDs 19–24 sind keine unabhängige
Bestätigung.

## Datensplits und Provenienz

- Training: 384 gespeicherte Fälle aus
  `training_size_12_24_48_20261023/n384/train.mat`, IDs 1–12 und 25–396.
- Validierung: IDs 13–18 aus dem selben n=384-Quellversuch.
- Vorhandener POD-GPR: importiert aus `n384/models.mat`; der historische
  Trainingsrunner lädt `train.mat` und `val.mat` und wählt POD-Rang und
  Regressor anhand der Validierung. Die Originaldatei wird nicht verändert.
- Neuronale POD-MLP- und Restfeld-MLP-Modelle: je Seeds 42, 43 und 44 aus
  `neural_comparison_20261027_v1/n384/seed*/`. Die gespeicherten IDs müssen
  exakt mit dem oben genannten Split übereinstimmen.
- Neues Balkenfeld-plus-POD-GPR: Fit ausschließlich auf den vorhandenen 384
  Trainingsfeldern. POD-Ränge [2, 4, 8, 12] und Kernel
  `ardmatern52`, `ardsquaredexponential` sind vor dem Fit konfiguriert.
  Gewählt wird das kleinste mittlere relative gewichtete Feld-L2 auf IDs 13–18;
  Gleichstände folgen der Kandidatenreihenfolge.

Der Fit verwendet vorhandene Paketlogik. `fitBeamField` hat optionale
Rang-/Kernel-Kandidaten erhalten; der bisherige Aufruf ohne Optionen behält
seine historischen Kandidaten und den bisherigen Kernel bei.

## Unabhängiger Holdout

`prepare` erzeugt und versiegelt ausschließlich ein neues sechsdimensionales
maximin-Latin-Hypercube-Parameterdesign mit 64 IDs ab 700001. IDs und
Parameterkombinationen werden gegen das n=384-Design, die bekannten
Bestätigungsfälle und den bereits verwendeten neuralen Testentwurf geprüft.
Es werden dabei keine Holdout-FEM-Labels angelegt oder gelesen.

`freeze` schreibt Konfigurations-, Design-, Quellcode-, Daten- und Modellhashes
sowie die Git-Revision in das Manifest. Die modellbezogene Zuordnung steht
zusaetzlich in `MODEL_PROVENANCE.md`. Nach erfolgreicher Freeze-Pruefung wurden
`final_data` und `final_evaluate` im autorisierten Folgeauftrag ausgefuehrt.
64 von 64 Referenzen und alle neun Modell-/Seed-Varianten wurden vollstaendig
ausgewertet. Ein erster Runnerfehler nach erfolgreichem Solve von ID 700001
ist als unveraendertes Fehlerartefakt erhalten; dieselbe ID und Parameterzeile
wurde erfolgreich wiederaufgenommen, ohne einen Ersatzfall zu erzeugen.
Details und Resultate stehen in `FINAL_REPORT.md`.

## Metriken und Laufzeiten

Für jeden Modell-/Seed-/Fall-Schlüssel werden die relative gewichtete
Feld-L2-Abweichung und die absolute gewichtete RMS-Verschiebungsabweichung in
Metern gespeichert. Berichtet werden Median, nearest-rank 95. Perzentil und
Maximum, gepaarte Differenzen auf denselben Fällen und separate Seed-Streuung.
Keine Seed-Ensemble-Mittelung.

Vorhersagezeiten werden nach Laden und Aufwärmen des Modells mit sieben
Aufrufen je Fall gemessen. Historische Trainingszeiten werden mit Quelle und
Messumfang im Modellmanifest ausgewiesen und nicht als kontrollierte,
vergleichende Gesamtkostenrangfolge interpretiert. Das Restfeld-GPR protokolliert
die neue Fitzeit einschließlich Kandidatenauswahl.

## Reproduktion

Im MATLAB-Projekt:

```matlab
run_static_shared_comparison("prepare")
run_static_shared_comparison("import_fit")
run_static_shared_comparison("freeze")
run_static_shared_comparison("probe")
```

Die finalen Stufen wurden mit ausdruecklicher Autorisierung ausgefuehrt. Bei
einer neuen Wiederaufnahme zuerst das Freeze-Manifest und die Ergebnisse pruefen:

```matlab
run_static_shared_comparison("final_data")
run_static_shared_comparison("final_evaluate")
```

Jede Phase ist wiederaufnehmbar und überschreibt vorhandene Artefakte nicht.
Bei abweichender Konfiguration, Datenzuordnung, Hash oder bereits belegtem
Ausgabepfad bricht der Runner mit einer eindeutigen Fehlermeldung ab.
