# Finaler unabhaengiger 64-Fall-Test

Stand: 28. Oktober 2026. Der Test verwendet die vor dem Zugriff auf die
Holdout-Labels eingefrorenen Modelle und das versiegelte 64-Fall-Design. Das
Arbeitsziel **P95 <= 1 %** ist ein internes vorlaeufiges Projektziel, keine
Anforderung der Seminaraufgabe.

## Abschluss und Integritaet

- 64 von 64 versiegelten FEM-Referenzfaellen erfolgreich und vollstaendig
  ausgewertet.
- Neun Modell-/Seed-Varianten, 576 eindeutige Modell-/Seed-/Fall-Zeilen,
  2.304 gepaarte Fallvergleiche und 4.032 Vorhersagezeitmessungen.
- Keine nichtendlichen Feldmetriken, keine fehlenden Modell-/Seed-/Fall-Schluessel.
- Die Konfiguration, Holdout-Datei, Trainings-/Validierungsdaten und Modell-
  artefakte stimmen mit den eingefrorenen Hashes ueberein. Die neun im
  Freeze-Manifest aufgefuehrten Varianten stimmen mit den geladenen Modellen
  ueberein. Training, Validierung und der zuvor bekannte Testsplit sind
  ID-disjunkt; die Holdout-Parameterkombinationen wurden im vorbereitenden
  Design gegen die verfuegbaren bekannten Designs geprueft.

### Wiederaufnahme und dokumentierter Runner-Fehler

Der erste `final_data`-Aufruf loeste FEM-ID 700001 erfolgreich, brach danach
aber wegen eines Runnerfehlers ab (`cfg.fieldPointCount` war in der lokalen
Funktion nicht verfuegbar). Der Fehler wurde vor dem finalen Lauf erkannt und
als unveraenderter Fehlerdatensatz
`holdout_cases/case_700001.mat` erhalten. Der Runner wurde nur fuer die
Fehlerbehandlung/Wiederaufnahme korrigiert, nicht fuer Modell, Rang, Parameter,
Auswahl oder Metrik. Derselbe versiegelte Fall mit derselben Parameterzeile
wurde in `case_700001_attempt_002.mat` erneut berechnet und erfolgreich
gespeichert. Es gab keinen Ersatzfall und keine Modellentscheidung anhand
dieses Labels. Die 64 erfolgreichen Referenzen schliessen den erfolgreichen
Wiederholungsdatensatz ein; die Laufzeit des ersten, nicht als Referenz
verwendeten Versuchs ist nicht in den 64 Referenz-FEM-Zeiten enthalten.

## Feldfehler je Modell und Seed

Relative Fehler sind Prozent. Absolute Fehler sind die gewichtete Feld-RMS
Abweichung in Mikrometern; P95 ist nearest-rank `ceil(0.95*N)`.

| Modell | Seed | Median rel. | P95 rel. | Max rel. | Median abs. (µm) | P95 abs. (µm) | Max abs. (µm) | P95 <= 1 % |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Analytical beam field | — | 0,4571 | 2,3768 | 2,7192 | 0,2368 | 0,8548 | 1,2226 | Nein |
| POD-MLP | 42 | 6,1035 | 37,096 | 131,963 | 3,1438 | 10,8058 | 23,4919 | Nein |
| POD-MLP | 43 | 3,5500 | 25,815 | 74,590 | 1,7487 | 6,6294 | 19,8713 | Nein |
| POD-MLP | 44 | 2,7568 | 18,722 | 72,763 | 1,7330 | 7,6691 | 13,5700 | Nein |
| Beam-residual MLP | 42 | 0,03415 | 0,4404 | 4,1111 | 0,02511 | 0,11895 | 0,17195 | Ja |
| Beam-residual MLP | 43 | 0,02866 | 0,1575 | 0,5625 | 0,01726 | 0,05672 | 0,18186 | Ja |
| Beam-residual MLP | 44 | 0,03735 | 0,2600 | 1,9406 | 0,02064 | 0,05824 | 0,15390 | Ja |
| POD-GPR | 42 | 0,4850 | 2,5714 | 12,9877 | 0,18286 | 1,67614 | 6,36861 | Nein |
| Beam field + POD-GPR residual | 42 | 0,02049 | 0,1000 | 0,1797 | 0,01010 | 0,05774 | 0,07445 | Ja |

Die drei MLP-Seeds werden getrennt berichtet, nicht als Ensemble. Die
Seed-Streuung ihrer seedweisen Medianfehler betraegt:

| Modell | Seed-Medianbereich | Median der Seed-Mediane |
|---|---:|---:|
| POD-MLP | 2,7568–6,1035 % | 3,5500 % |
| Beam-residual MLP | 0,02866–0,03735 % | 0,03415 % |

Die Seed-Streuung ist hier von der Streuung der 64 Testfaelle getrennt. Beim
Restfeld-MLP erfuellen alle drei Seeds das P95-Arbeitsziel; Seed 42 hat jedoch
einen isolierten groesseren Maximalfehler. Keine Seed-Auswahl anhand des
Holdouts wurde vorgenommen.

## Gepaarte Vergleiche

Die folgenden Differenzen sind fuer dieselben 64 Testfaelle gepaart. Positive
`A-B` bedeutet hoehere Fehler fuer A:

| A | B | Median A-B (Prozentpunkte) | Faelle A schlechter als B |
|---|---|---:|---:|
| POD-MLP seed 42 | Beam-residual MLP seed 42 | +6,0786 | 100,0 % |
| POD-GPR | Beam field + POD-GPR residual | +0,4613 | 100,0 % |
| POD-GPR | Beam-residual MLP seed 43 | +0,4453 | 98,4 % |
| Analytical beam field | Beam field + POD-GPR residual | +0,4385 | 100,0 % |
| Beam-residual MLP seed 43 | Beam field + POD-GPR residual | +0,00850 | 62,5 % |

Die vollstaendige Paarmatrix pro Fall, einschliesslich aller Seeds, liegt in
`independent_holdout_paired_case_differences.csv`; gruppierte Kennzahlen sind
in `independent_holdout_paired_summary.csv`.

## Groesste Fehler und Feldabweichungen

Alle genannten Parameter liegen innerhalb des vorab festgelegten Parameter-
bereichs. Wiederkehrende Fehlerursache bei den Restfeldmodellen sind kleine
relative laterale `uy`-Fehlerkomponenten: ihre absoluten Fehler bleiben klein,
aber die Referenzkomponente ist ebenfalls klein. Die groessten spezifischen
Feldabweichungen:

- POD-MLP seed 42: groesster Fall ID 700028, relativer Feldfehler 131,96 %.
  `uz`-Komponentenfehler 132,97 %, maximale punktweise Vektorabweichung
  17,98 µm. Parameter: L=0,6608 m, b=0,09251 m, h=0,12974 m,
  E=146,04 GPa, nu=0,34074, Fz=-339,42 N.
- POD-MLP seeds 43 und 44: beide groesster Fall ID 700019
  (Fz=-133,13 N); Gesamtfehler 74,59 % bzw. 72,76 %. Die `uy`-Fehler sind
  relativ 101,6 % bzw. 109,4 %, waehrend ihre absoluten gewichteten
  Komponenten-RMS nur etwa 0,0060 bzw. 0,0065 µm betragen.
- Beam-residual MLP seed 42: groesster Fall ebenfalls ID 700019, 4,111 %;
  `uy`-Fehler 168,6 % relativ, aber 0,00994 µm absolut. Seed 44 hat dort
  1,941 % Gesamtfehler und 0,00450 µm absoluten `uy`-Fehler. Seed 43s
  groesster Fehler liegt bei ID 700002 und betraegt 0,5625 %.
- Beam field + POD-GPR residual: groesster Fall ID 700028, 0,1797 %; die
  `uy`-Fehlerkomponente ist 8,09 % relativ, jedoch 0,00155 µm absolut.
- POD-GPR: groesster Fall ID 700033, 12,99 %; groesster absoluter
  punktweiser Vektorfehler 13,09 µm, bei Fz=-108,99 N und E=72,12 GPa.
- Analytical beam field: groesster Fall ID 700023, 2,719 %. Das analytische
  Feld setzt `uy=0`; die FEM enthaelt eine kleine, endliche laterale
  Komponente, wodurch deren relativer Komponentenfehler 100 % ist.

Pro Modell-/Seed-Variante sind Parameter, komponentenweise absolute und
relative Fehler sowie die Referenzposition des maximalen punktweisen Fehlers
in `independent_holdout_worst_cases.csv` gespeichert.

## Laufzeit und Kosten

Die Holdout-FEM-Zeiten stammen aus dem einheitlichen `solve_case`-Messumfang:
64 erfolgreiche Referenzen, zusammen **110,05 s**, Median **1,5835 s**,
nearest-rank-P95 **3,0311 s**, Maximum **4,1773 s**. Zusaetzlich wurde die
FEM-Berechnung fuer ID 700001 beim ersten Runnerfehler einmal ausgefuehrt,
aber nicht als Referenzlabel verwendet; ihr gemessener Versuch dauerte etwa
4,05 s.

Vorhersagezeiten wurden fuer alle Modelle einheitlich nach Modell-Laden,
einem Aufwaermruf und sieben Aufrufen je Fall gemessen. Median der 64
fallweisen Medianzeiten:

| Modell | Seed | Median Vorhersagezeit je Fall |
|---|---:|---:|
| Analytical beam field | — | 0,0125 ms |
| POD-MLP | 42 / 43 / 44 | 6,507 / 6,439 / 6,748 ms |
| Beam-residual MLP | 42 / 43 / 44 | 6,863 / 6,375 / 5,720 ms |
| POD-GPR | 42 | 2,909 ms |
| Beam field + POD-GPR residual | 42 | 3,247 ms |

Das neue Restfeld-GPR benoetigte einschliesslich des festgelegten
Rang-/Kernelrasters und der Validierungsauswahl etwa **105,0 s**. Die
neuronalen und historische POD-GPR-Trainingszeiten sind uebernommene
historische Messungen, keine hardware- und messumfangsgleichen Neumessungen;
sie tragen keine belastbare Rangfolge der Gesamtkosten.

Ein grober Break-even fuer das neue Restfeld-GPR waere bei den gemessenen
Medianzeiten etwa 67 Vorhersagen gegenueber separaten FEM-Loesungen
(105 s / (1,5835 s - 0,00325 s)). Das ist nur eine lokale Laufzeitschaetzung,
keine reproduzierte Amortisationsstudie: weitere Wiederholungen, Hardware-
und Prozesslastkontrolle sowie Kosten fuer Datenerzeugung/Deployment fehlen.

## Wissenschaftliche Einordnung

1. **Restfeldmodelle:** Ja. Beide Restfeldansätze zeigen auf dem unabhaengigen
   Holdout deutlich geringere Fehler als Vollfeld-POD-MLP und POD-GPR. Alle
   drei Restfeld-MLP-Seeds und das neue Restfeld-GPR erreichen P95 <= 1 %.
2. **Seed-Zuverlaessigkeit:** Die Restfeld-MLP-Medianfehler sind ueber die
   drei Seeds eng, aber Maximalfehler unterscheiden sich deutlich. Das
   Vollfeld-POD-MLP bleibt ueber alle Seeds schwach und streut staerker.
3. **Arbeitsziel:** Erfuellt wird es von Beam-residual MLP fuer jeden der
   Seeds 42/43/44 sowie von Beam field + POD-GPR residual. Es ist kein
   Seminar-Aufgabenkriterium.
4. **Vergleichbarkeit:** Die Modellvarianten unterscheiden sich in
   Feldrepraesentation, POD-Rang und historischer Auswahl-/Trainingshistorie.
   Der Test zeigt die Leistung dieser konkreten eingefrorenen Varianten,
   nicht einen isolierten kausalen Vorteil des Regressortyps.
5. **Kosten:** Vorhersage- und neue FEM-Zeiten sind fuer diesen Lauf mit
   einheitlichem Protokoll messbar. Historische Trainingszeiten sind nur
   herkunftsmarkierte Orientierung. Eine robuste Amortisationsrangfolge ueber
   alle Modelle ist damit nicht belegt.

Der einzelne n=384-Holdout begruendet keine Mindestzahl benoetigter
Trainingsfaelle. Aussagen zur Datenmenge muessen sich auf die getrennten
Lernkurven stuetzen.

## Empfohlenes naechstes Arbeitspaket

Ein kontrollierter MLP-gegen-GPR-Methodenvergleich mit derselben vorab
train-only berechneten POD-Basis, identischen Trainings-/Validierungs-IDs,
gleicher Feldrepräsentation und dokumentiertem, angeglichenem
Validierungsauswahlbudget. Das wuerde die derzeitige Vergleichsluecke zwischen
Regressionsmethode und unterschiedlichen Darstellungen gezielt adressieren;
dieser Folgeversuch ist noch nicht implementiert.

## Verwendete Befehle

Im MATLAB-Projekt:

```matlab
openProject('blank_project.prj')
run_static_shared_comparison("probe")
run_static_shared_comparison("final_data")
run_static_shared_comparison("final_evaluate")
analyze_static_shared_holdout()
```

Zur Abschlussverifikation nach der Berichtserstellung in MATLAB R2025b:

```matlab
openProject('blank_project.prj')
addpath('tests')
run_checks(false)
results = runtests({fullfile('tests','staticSharedComparisonTest.m'), ...
    fullfile('tests','neuralStudyTest.m')});
assertSuccess(results)
messages = checkcode(fullfile('scripts','matlab', ...
    'analyze_static_shared_holdout.m'),'-id');
assert(isempty(messages))
run_static_shared_comparison('final_evaluate')
analyze_static_shared_holdout()
```

Finale Ergebnisse: `final_evaluation.mat`,
`independent_holdout_summary_by_model_seed.csv`,
`independent_holdout_case_metrics.csv`,
`independent_holdout_paired_case_differences.csv`,
`independent_holdout_prediction_timings.csv`,
`independent_holdout_worst_cases.csv`,
`independent_holdout_prediction_costs.csv` und
`independent_holdout_fem_cost.csv`.
