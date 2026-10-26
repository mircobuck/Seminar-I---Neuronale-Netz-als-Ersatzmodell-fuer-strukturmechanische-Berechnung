# MATLAB FEM Startprojekt

Neu: Klassischer POD-Galerkin-ROM auf gemeinsamem quadratischem FEM-Netz für
alle sechs Trainingsgrößen. Umsetzung, tatsächliche Prüfungen, vollständige
Online-Kosten und Vergleich mit den KI-Modellen stehen im
[ROM-Bericht](experiments/pod_galerkin_20261023_v1/REPORT.md).
Einstieg: `run_rom_study` bzw. `run_rom_logged`; bestehende Daten bleiben erhalten.

Aktueller lokaler Stand vom 23.10.2026: Smoke-Ablauf und die Trainingsmengenreihe
12/24/48/96 wurden unter MATLAB R2025b tatsächlich ausgeführt. Aktuelle Resultate
und Nachweise stehen im [Versuchsverlauf](EXPERIMENTS.md). Die folgenden Angaben
zur fehlenden MATLAB-Ausführung beziehen sich auf die ursprüngliche
Erstellungsumgebung; der lokale Prüfstand steht in CHECKS.md.

Dieses Paket setzt die erste statische Benchmarkstufe des Leitfadens um.
Es liefert Code und Parameterlisten, **keine bereits berechneten FEM-Zielwerte**.
MATLAB war in der Erstellungsumgebung nicht verfügbar. Der MATLAB-Code wurde dort
nicht ausgeführt. Die mitgelieferten MATLAB-Tests müssen lokal ausgeführt werden.

## 1 Voraussetzungen

- MATLAB R2024a oder neuer; Partial Differential Equation Toolbox.
- Statistics and Machine Learning Toolbox für GPR und Quantile.
- Deep Learning Toolbox optional für POD-MLP. Fehlt `trainnet`, wird MLP übersprungen.
- CPU genügt. Die Beispiele erzwingen für das MLP CPU-Ausführung.
- ZIP entpacken und `MATLAB_FEM_Start` als Current Folder öffnen.

## 2 Reihenfolge

```matlab
addpath('src','tests')
run_checks(false)              % Algebra, Datensplits, keine FEM
run_checks(true)               % zusätzlich drei FEM-Skalierungsfälle
mesh_check("smoke")           % acht FEM-Läufe, zwei Parameterfälle
run_project("smoke","generate") % 24 FEM-Fälle, pro Fall Checkpoint
run_project("smoke","train")
run_project("smoke","evaluate")
```

Die Probestufe prüft den Ablauf, nicht die erreichbare wissenschaftliche Genauigkeit.
Erst danach:

```matlab
run_project("pilot","generate") % 160 FEM-Fälle
run_project("pilot","train")
run_project("pilot","evaluate")
u = predict_new("pilot","POD_GP",[1 .08 .12 140e9 .30 -500]);
```

Eine Unterbrechung der Datenerzeugung lässt sich mit demselben `generate`-Aufruf
fortsetzen. Ein vorhandener Fall wird wiederverwendet; fehlgeschlagene Fälle werden
nicht stillschweigend gelöscht. Die Manifestprüfung verhindert ein Vermischen
unterschiedlicher Physik- oder Netzkonfigurationen. Änderungen erfordern einen neuen
Ausgabeordner. Trainierte Modelle werden nicht automatisch überschrieben.

## 3 Parameter und Stichproben

Die mitgelieferten CSV-Dateien sind feste Latin-Hypercube-Designs, getrennt pro Split,
mit Basis-Seed 1001 (smoke) beziehungsweise 1002 (pilot). Pro Split wird
Basis-Seed + 10000 × Splitindex (0, 1, 2) verwendet. Sie wurden mit NumPy 2.x und
SciPy `qmc.LatinHypercube` erzeugt; die konkreten CSV-Werte sind die maßgebliche
Reproduktionsgrundlage. Es handelt sich ausschließlich um Eingaben, nicht um Labels.

| Parameter | Bereich | Einheit |
|---|---:|---|
| Länge L | 0.6–1.2 | m |
| Breite b | 0.06–0.10 | m |
| Höhe h | 0.08–0.14 | m |
| Elastizitätsmodul E | 70–210 | GPa; CSV in Pa |
| Querkontraktionszahl nu | 0.25–0.35 | 1 |
| Resultierende Stirnkraft Fz | −1000 bis −100 | N |

Diese Bereiche sind ein Vorschlag für den Einstieg, keine von dir bestätigten
Materialdaten. Die Last ist gleichmäßig auf die rechte Stirnfläche verteilt;
links gilt vollständige Einspannung. Kein Eigengewicht, keine Vorspannung.
Dichte wird deshalb nicht als Eingang verwendet. Ein Verschiebungsquotient über
0.02 führt zum Abbruch als Plausibilitätsprüfung für kleine Verformungen.

| Modus | Training | Validierung | Test |
|---|---:|---:|---:|
| smoke | 12 | 6 | 6 |
| pilot | 64 | 32 | 64 |

Die Testfälle sind ausschließlich Parameterinterpolation derselben Quaderfamilie.
Sie belegen weder Extrapolation noch neue Topologien. Verschiedene Netzversionen
eines Falls dürfen später nicht auf Training und Test verteilt werden.

## 4 Welche Daten entstehen

`runs/pilot/cases/case_XXXX.mat` enthält je einen echten MATLAB-FEM-Lauf:
Parameter, Verschiebungsfeld auf einem Referenzgitter, FEM-Knoten/Elemente,
ursprüngliche Knotenverschiebungen, Laufzeit und Knotenzahl.

Zusätzlich entstehen separate `train.mat`, `val.mat`, `test.mat`, jeweils mit `D`:

- `D.X`: N×6 Parameter in SI, Reihenfolge L,b,h,E,nu,Fz.
- `D.S`: 1575×N Felder auf 21×5×5 Abfragepunkten; alle ux, dann uy, dann uz.
- `D.Y`: N×2; vorzeichenbehaftetes uz am Stirnflächenmittelpunkt und maximales
  Verschiebungsmaß **auf dem gemeinsamen Abfragegitter**.
- `D.xi`: 3×525 normierte Referenzkoordinaten; `D.w`: 1575×1 Quadraturgewichte.
- `D.id`: eindeutige IDs; `D.seconds`: FEM-Ende-zu-Ende-Zeit inklusive Aufbereitung.

Die Feldrepräsentation bildet jede Quadergeometrie auf den Einheitswürfel ab.
Sie ist keine gemeinsame konforme FEM-Basis für eine Galerkin-Projektion.
Die Referenzgewichte ergeben eine Volumenmittel-Norm; der konstante Volumenfaktor
eines einzelnen Quaders kürzt sich im relativen Feldfehler heraus.

Spannungen, Dehnungen, Reaktionen und Modalgrößen werden in dieser Startversion
noch nicht als Trainingsziele erzeugt. Dafür ist zunächst die Referenzqualität zu
sichern; insbesondere singuläre Spannungsmaxima an der Einspannung sind ungeeignet.

## 5 Implementierte Modelle

1. **Scalar_GPR**: je ein GP für Stirnverschiebung und Gittermaximum.
2. **POD_GP**: trainierte POD-Basis plus GP je Koeffizient.
3. **POD_RBF**: dieselbe POD-Konstruktion mit kubischer RBF und linearem Polynom.
4. **POD_MLP**: POD plus kleines neuronales Netz, wenn Toolbox verfügbar.
5. **Beam_plus_GPR**: Euler-Bernoulli-Spitzenverschiebung plus GP für FEM-Differenz.
6. Balkentheorie allein wird als nicht lernende Vergleichsreferenz ausgewertet.

POD-Rang und Regressionsparameter werden ausschließlich anhand des Validierungssatzes
gewählt. Eingangsskalierung, Ausgangsskalierung und POD stammen aus Training.
Die MLP-Auswahl nutzt einen Seed für einen schnellen ersten Lauf; für belastbare
Ergebnisse folgen fünf Seeds und Lernkurven. Der Test wird erst nach Einfrieren der
Modelle geladen. `test_per_case.csv`: Relativfehler bedeutet bei Feldmodellen
gewichteter L2-Fehler, bei Skalarmodellen relativer Spitzenfehler; nicht miteinander
als eine gemeinsame Kennzahl ranken.

Die übrigen fünf Leitfadenansätze (reduzierte Matrizen, hierarchisches GNN,
Geom-DeepONet, GINO, GINOT) sind **nicht als fertige Trainingsimplementierungen in
 diesem Paket enthalten**. Sie erfordern zusätzliche gemeinsame FEM-Räume,
Graph-/Geometriefeatures oder eigene Operatorarchitekturen. Der nächste sinnvolle
Schritt nach diesem Benchmark ist Modal-ROM oder GNN, abhängig vom Projektziel.

## 6 Ergebnisse lesen und Entscheidung treffen

`validation_selection.csv` dokumentiert Kandidaten und Validierungsfehler.
`models.mat` enthält eingefrorene Modelle samt Konfiguration und IDs.
`test_summary.csv` enthält Feldmedian, 95-Prozent-Quantil, schlechtesten Feldfehler,
POD-Projektionsuntergrenze, skalare MAEs und Laufzeiten. Nicht zutreffende Werte sind NaN.
`test_predictions.mat` hält Vorhersagen und Balkenvergleich bereit.

Für das Feldmodell ist der POD-Projektionsfehler die beste erreichbare Fehlergrenze
in der festen Basis. Liegt er hoch: Daten/Basis/Rang verbessern. Ist er niedrig und
der Surrogatfehler hoch: Regression oder Trainingsdaten verbessern.

Zunächst angestrebte, noch nicht nachgewiesene Kriterien: Netzänderung der
Verschiebung unter 1 Prozent; später Testmedian unter 1 Prozent und 95-Prozent-
Quantil unter 3 Prozent. Diese Zahlen sind Arbeitsziele, keine Garantien. Eine
sinnvolle FEM-Referenztoleranz sollte deutlich kleiner als die Surrogattoleranz sein.
Der Netztest mit zwei Fällen ersetzt keine vollständige Konvergenzstudie.

`meshDivisor=3` ist nur ein Ausgangswert. Steigere ihn nach `mesh_check`, falls nötig,
und nutze dann einen neuen Run-Ordner. Kleine Hmax erhöhen Laufzeit und Speicher.
Die Online-Zeit misst einen einzelnen neuen Fall inklusive Rekonstruktion,
CPU-Warmup durch timeit; Training enthält auch die Hyperparametersuche.
POD-Zeit und direkte skalare GP-Zeit liefern unterschiedliche Ausgaben, also
keinen fairen unmittelbaren Geschwindigkeitsvergleich.

Break-even für künftige Abfragen: zusätzliche Offlinekosten geteilt durch
(FEM-Zeit pro Abfrage minus Surrogatzeit pro Abfrage), sofern der Nenner positiv ist.
Als Offlinekosten Trainingsdatengenerierung und Modellauswahl ansetzen; Validierung
und Test für eine vollständige Projektkostenrechnung separat mitberichten.

## 7 Quellen und Prüfstatus

MATLAB-Schnittstellen siehe:
- https://www.mathworks.com/help/pde/ug/femodel.html
- https://www.mathworks.com/help/pde/ug/pde.staticstructuralresults.html
- https://www.mathworks.com/help/stats/fitrgp.html
- https://www.mathworks.com/help/deeplearning/ref/trainnet.html

Die Datei CHECKS.md beschreibt die tatsächlich in der Erstellungsumgebung
vorgenommenen Prüfungen. FEM-, GPR- und MLP-Läufe stehen bis zum lokalen MATLAB-Test aus.

## 8 Feldvergleich anzeigen

Nach dem Testlauf:

```matlab
plot_test_case("pilot","POD_GP",1)
```

Die drei Panels zeigen dasselbe Testfeld als FEM-Referenz, Vorhersage und absoluten
Fehler. Beide Verschiebungsplots verwenden dieselbe Farbskala.


## DeepONet-Vergleich: Abschluss 25.10.2026

30 finale parametrische DeepONets (N=12,24,48,96,192,384; Seeds 42-46)
liegen im separaten Ordner experiments/deeponet_20261023_v1.
Sieben Unit-Tests bestanden; alle Modelle auf identischen sechs Testfaellen
ausgewertet. Bei N=384: DeepONet-Seed-Median 8,835 % Feldfehler,
POD-GPR 0,384 %, klassischer ROM etwa 0,057 %. Kleine uy-Komponente bei
DeepONet etwa 1466 % relativer Medianfehler: derzeit kein Genauigkeitsvorteil
als allgemeiner Ersatz fuer alle Verschiebungskomponenten.

- [PDF-Gesamtbericht](experiments/deeponet_20261023_v1/output/pdf/FEM_Ersatzmodelle_DeepONet_Vergleich.pdf)
- [Bearbeitbarer Bericht](experiments/deeponet_20261023_v1/REPORT.md)
- [Alle Modelllaeufe](experiments/deeponet_20261023_v1/comparison_all_runs.csv)
- [Quellstand, Reproduktion und Befunde](experiments/deeponet_20261023_v1/review_notes.md)

Vorhersage: addpath('src'); a=load('experiments/deeponet_20261023_v1/n384/seed42/model.mat');
H=predict_deeponet(a.model,X,xi); % X: N mal 6 in SI; xi: 3 mal Q; H: [ux;uy;uz] in m.
Bestehende Modelle und FEM-Daten erhalten. Kein groesserer pilot-Lauf gestartet.
