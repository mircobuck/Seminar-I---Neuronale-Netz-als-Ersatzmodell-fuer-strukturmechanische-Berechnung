# Code v2: FEM-Referenzdaten

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
