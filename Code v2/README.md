# Code v2: FEM-Referenzdaten

## POD-MLP für statische Verschiebungsfelder

Das Modell `pod_mlp` berechnet eine gewichtete, mittelwertzentrierte POD-Basis
aus den Trainingsfeldern und trainiert ein MLP mit Adam auf deren Koeffizienten.
Basis und Normierung stammen ausschließlich aus dem Trainingssplit. Das Modell
liefert vollständige Felder in Metern über die gemeinsame Schnittstelle.

Beispiel aus `Code v2` (die Zieldatei darf noch nicht existieren):

```matlab
addpath('examples')
[model, report, metrics] = podMlpExample('pod_mlp_model.mat');
```

Das Beispiel nutzt Trainings- und Validierungsdaten, keine Testdaten. Rang,
Netzbreite und Adam-Einstellungen stehen im Beispiel; der Standardrang ist 10.
Das Training verwendet die letzte Epoche ohne Validierungsdaten zur Steuerung.
Die Auswertung nutzt den gemeinsamen gewichteten Feldfehler. Voraussetzung ist
MATLAB R2025b mit Deep Learning Toolbox. Modelltests:
`runtests('tests/podMlpTest.m')`.

### Modellvergleich auf dem Validierungssplit

`examples/plotSurrogateValidation.m` lädt das vorhandene Pilotmodell und zeigt
den gewichteten absoluten Feldfehler pro Fall in Metern sowie Median und P95
des gewichteten relativen Feldfehlers in Prozent. P95 verwendet Nearest Rank.
Die Zusammenfassung verwendet nur definierte relative Fehler; die Anzahl der
undefinierten Werte steht im Plot. Fallwerte bleiben in `results` erhalten.

Der Modellpfad steht am Anfang des Skripts. Das vorgegebene Pilotmodell liegt
zwei Ordner oberhalb von `Code v2`; auf einem anderen Rechner muss der Pfad
angepasst werden. Weitere gespeicherte Modelle können in der `models`-Liste
ergänzt werden, sobald sie die gemeinsame `surrogate`-Schnittstelle erfüllen.
Das Skript lädt ausschließlich statische Validierungsdaten und ist kein
Abschlusstest. Aus `Code v2` starten:

```matlab
run('examples/plotSurrogateValidation.m')
```

### Abschlusstest auf statischen Verschiebungsfeldern

Der separate Prüfstand unter
[`studies/static_final_evaluation`](studies/static_final_evaluation/README.md)
wertet gespeicherte Modelle auf demselben statischen Testsplit aus. Er ist
vorbereitet, führt aber keinen echten Abschlusstest aus. Auswahl, Freeze-Stand,
Testlabel-Nutzung, Metriken und Schwellenwerte müssen vor einem späteren
Testlauf dokumentiert werden. Der Ablauf trainiert keine Modelle, startet
keine FEM und bietet keine technische Zugangssperre für Testlabels. Der
bestehende Validierungsplot bleibt davon getrennt.

Für eine Lernkurve mit 12, 24, 48, 96, 192 und 384 Trainingsfällen und drei
Seeds kann ein noch nicht existierender Ausgabeordner gewählt werden:

```matlab
addpath('examples')
[summary, outputDir] = runPodMlpLearningCurve('pfad/zum/neuen_ordner');
plotPodMlpLearningCurve(outputDir)  % gespeicherte Ergebnisse erneut plotten
```

Die Teilmengen sind je Seed verschachtelt; Basis und Normierung werden für
jeden Lauf neu aus dessen Trainingsdaten bestimmt. Gespeichert werden die
18 Modelle, Fall-IDs, Validierungsmetriken, eine CSV und drei Lernkurven. Der
Absolutfehler ist der mittlere gewichtete Fehler über alle Validierungsfälle;
Median und P95 beziehen sich auf den relativen gewichteten Feldfehler. Der
POD-Rang ist 10; bei weniger als 32 Fällen entspricht die Batchgröße der
Fallzahl. Die Ergebnisse sind Pilotwerte auf dem Validierungssplit.

### Probelauf: Trainings-Loss

`examples/runPodMlpLossPilot.m` vergleicht bei 64 Neuronen und 1–3
versteckten Schichten die bisherige pro Koeffizient standardisierte MSE mit
einer gemeinsamen Koeffizientenskalierung. Wegen der gewichteten
POD-Orthonormalität entspricht deren MSE bis auf einen konstanten Faktor dem
quadrierten gewichteten Feldfehler. Der Vergleich nutzt dieselben 768
Trainingsfälle, 12 Validierungsfälle und Seeds 42–44; Testdaten werden nicht
geladen. Pro Loss, Tiefe und Seed entsteht ein gespeichertes Modell.
Versuchsplan und Ergebnisdokumentation:
[`experiments/POD_MLP_LOSS_PILOT_20261107.md`](experiments/POD_MLP_LOSS_PILOT_20261107.md).
Ergebnisse: `experiments/pod_mlp_loss_pilot_20261107/summary.csv`.

Der vollständige Vergleich der neuen Loss über die Breiten 64/128, Tiefen 1–5
und Trainingsgrößen 12–768 mit drei Seeds umfasst 210 Modellläufe.
Versuchsplan und Dokumentation:
[`experiments/POD_MLP_LOSS_STUDY_20261107.md`](experiments/POD_MLP_LOSS_STUDY_20261107.md).
Starten mit `addpath('examples'); result = runPodMlpLossStudy();`. Der Runner
vergleicht die Ergebnisse direkt mit der vorhandenen alten-Loss-Studie und
nutzt ausschließlich Validierungsdaten.
Der Lauf vom 8. November 2026 ist abgeschlossen; der direkte Vergleich liegt
in `experiments/pod_mlp_loss_study_20261107/comparison_old_vs_weighted_loss.csv`.

### Frischer Validierungsvergleich der Loss-Funktionen

Für einen Vergleich auf zwölf neuen statischen Fällen kann
`studies/static_final_evaluation/runPodMlpFreshValidationComparison.m`
verwendet werden. Der Runner prüft und hasht zuerst alle 420 gespeicherten
Modelle der beiden Loss-Studien, einschließlich identischer Trainings-IDs
innerhalb jedes Modellpaars. Erst danach erstellt er mit Seed `20261108` und
IDs 812001–812012 ein Validierungsdesign und berechnet ausschließlich dessen
statische FEM-Labels. Training und Testlabels werden nicht erzeugt oder
geladen. Die dokumentierte Methodik und Ergebnisdateien stehen in
[`studies/static_final_evaluation/README.md`](studies/static_final_evaluation/README.md).

Dieser Ordner enthaelt einen getrennten Datenworkflow fuer statische
Verschiebungsfelder und modale Eigenfrequenzen. Die benötigten FEM-Kernfunktionen liegen unter `fem_core` in diesem Ordner.
Der Workflow benötigt den benachbarten Ordner `Code` nicht. Designs und neu
erzeugte Referenzdaten werden unter `data_generation/data` gespeichert.

## Fallzahlen und Zuweisung

| Datentyp | Training | Validierung | Test | Gesamt |
|---|---:|---:|---:|---:|
| Statische Verschiebungsfelder | 384 | 12 | 64 | 460 |
| Modale Eigenfrequenzen | 384 | 12 | 64 | 460 |

Die Testdesigns verwenden neue Fall-IDs und neue Parameterkombinationen. Die
Design-CSV ordnet jede ID genau einem Split zu. Training und Validierung
werden getrennt von Testreferenzen erzeugt. F?r eine unabh?ngige Bewertung
Testlabels erst nach Abschluss der Modellauswahl berechnen.

## Start in MATLAB R2025b

In MATLAB den Ordner `Code v2` als aktuellen Ordner w?hlen und starten:

```matlab
main
```

Dies erzeugt die Designs und berechnet nacheinander statische und modale
Trainings-, Validierungs- und Testf?lle. Der Lauf kann lange dauern und kann
nach einer Unterbrechung mit demselben Befehl fortgesetzt werden. Einzelne
F?lle werden unmittelbar gespeichert; die Split-Datei entsteht, sobald alle
F?lle des Splits vorliegen. Laufzeit und Speicherbedarf h?ngen vom Rechner ab.

Alternativ sind einzelne Phasen verf?gbar:

```matlab
main("train_val")  % nur Training und Validierung
main("test")       % nur Testf?lle
main("smoke")      % kurzer Probelauf in data_generation/smoke
```

F?r eine unverzerrte Absch?tzung der Modellg?te empfiehlt es sich, Testlabels
erst nach Abschluss der Modellauswahl zu berechnen: dazu zuerst
`main("train_val")`, sp?ter `main("test")` ausf?hren. `main` ohne Argument
berechnet ausdr?cklich alle Splits.

Die Konfiguration liegt in `data_generation/configs/data_generation_v1.json`.
Vor der ersten Berechnung Fallzahlen und Parameterbereiche pr?fen. Bereits
vorhandene Ergebnisse werden nicht ?berschrieben. Konfiguration, ausgew?hlte
Quelldateien und MATLAB-/PDE-Toolbox-Version werden zur Wiederaufnahme
abgeglichen; bei Abweichungen bricht der Lauf ab. F?r einen neuen Studienstand
einen neuen Ausgabeordner verwenden. Java muss in MATLAB verf?gbar sein, da
die Herkunftspr?fung SHA-256 ?ber Java berechnet.

## Ergebnisstruktur

```text
data_generation/
  configs/data_generation_v1.json
  data/
    static/design.csv
    static/cases/<id>.mat
    static/train.mat
    static/val.mat
    static/test.mat                 # erst nach static_test
    modal/design.csv
    modal/cases/<id>.mat
    modal/train.mat
    modal/val.mat
    modal/test.mat                  # erst nach modal_test
```

Die statischen Referenzen enthalten das Feld `S`, skalare Antwortwerte `Y`,
Feldgitter und Gewichte. Die Modalreferenzen enthalten die ersten sechs
Eigenfrequenzen in Hz; sie sind keine Eigenform-Surrogate.

## Berechnungsumfang

`design` rechnet keine FEM-Faelle. `static_train_val` rechnet 396 statische
FEM-Faelle und `modal_train_val` rechnet 396 modale FEM-Faelle. Die beiden
Testschritte rechnen jeweils 64 zusaetzliche FEM-Faelle. Der vollstaendige
Lauf umfasst somit bis zu 920 FEM-Referenzfaelle und benoetigt PDE Toolbox.

## Daten mit sprechenden Feldnamen laden

Die Funktion `loadFemDataset` liest eine fertige Split-Datei, ohne sie zu
?ndern. Sie ?bersetzt die urspr?nglichen Namen in verst?ndliche Feldnamen:

```matlab
data = loadFemDataset(fullfile("data_generation", "data", ...
    "static", "train.mat"));
parameters = data.inputParameters;
fields = data.displacementFields;
```

Die F?lle stehen in `inputParameters` zeilenweise, in `displacementFields`
spaltenweise. Bei modalen Daten hei?t die Zielmatrix `naturalFrequenciesHz`.
Parameterreihenfolge und Einheiten stehen in `parameterNames`. Die MAT-Dateien
selbst behalten das urspr?ngliche Schema und k?nnen weiterverwendet werden.

## Eigenständiger FEM-Kern und bestehende Daten

Die FEM-Funktionen liegen in `fem_core`. MATLAB R2025b, die PDE Toolbox und
Java bleiben Voraussetzung. Der frühere Runner liegt dort als Textdatei
ausschließlich zur Prüfung der ursprünglichen Herkunftsangaben. Die bestehenden
`provenance.txt`-Dateien und FEM-Ergebnisse werden nicht verändert. Beim
ersten erneuten Lauf wird zusätzlich `standalone_provenance.txt` geschrieben,
damit auch der neue Runner geprüft werden kann.

## Schnittstelle für Ersatzmodelle

Der verbindliche Vertrag und Beispiele für Daten, Training, Modellartefakte,
Vorhersage und Auswertung stehen in [docs/SCHNITTSTELLEN.md](docs/SCHNITTSTELLEN.md).
Das Paket `+surrogate` enthält die gemeinsame Basis; `+surrogate/+models/+dummy`
ist ausschließlich ein synthetisches Schnittstellenbeispiel. Die projektspezifischen
Skills liegen in `.agents/skills/create-fem-surrogate` und
`.agents/skills/test-fem-surrogates`.

Die Prüfungen lassen sich aus `Code v2` ohne FEM-Berechnung starten:

```matlab
results = runtests('tests/surrogateContractTest.m');
```

Eine Studiensteuerung für Kandidatenauswahl, Modell-Freeze und Abschlussberichte
ist noch nicht implementiert. Testlabels werden durch den Loader nicht technisch
gesperrt; der Umgang damit muss im Studienprotokoll festgelegt werden.
