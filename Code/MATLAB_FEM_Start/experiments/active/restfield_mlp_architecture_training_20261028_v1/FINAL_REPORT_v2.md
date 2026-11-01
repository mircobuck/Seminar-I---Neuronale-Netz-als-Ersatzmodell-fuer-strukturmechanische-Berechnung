# Architektur- und Trainingsvergleich des Balken-Restfeld-MLP

Stand: 2026-10-28

## Validierungsstrategie und Integritaet

Dreifache gruppierte Kreuzvalidierung innerhalb der 384 bestehenden Trainingsfaelle. Pro Fold wurden 256 Faelle trainiert und 128 Faelle ausschliesslich zur aeusseren Kandidatenauswahl verwendet. Die CV ist kein unabhaengiger Abschlusstest. POD, Rang, Mittelwerte und Skalierung stammen pro Fold nur aus den 256 Trainingsfaellen.

Die 64 Labels des abgeschlossenen statischen Holdouts, die frueheren Testkohorten und neue FEM-Berechnungen wurden nicht verwendet. Deren Status als verbrauchte Tests bleibt unveraendert.

## Auswahl

Faelle mit Referenznorm unter dem vorab festgelegten Nennerboden 1.0e-14 m: 0.

Architektur: **[32,32]**. Optimierer: **lbfgs**. Auswahlmetriken und Tie-Break sind in der versionierten Konfiguration festgelegt.

## Architekturvergleich

| Architektur | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean POD projection | Mean train s |
|---|---:|---:|---:|---:|---:|---:|---:|
| [16] | 0.0043905077 | 0.0017178509 | 0.018079959 | 0.077371012 | 1.3707297e-07 | 4.1999376e-05 | 2.71 |
| [16,16] | 0.0037278768 | 0.0016639386 | 0.013790633 | 0.063963746 | 1.2539665e-07 | 4.1999376e-05 | 2.675 |
| [32,32] | 0.0023743919 | 0.0011977793 | 0.0084668402 | 0.059854495 | 9.0478624e-08 | 4.1999376e-05 | 1.641 |

## Optimierervergleich

| Optimierer | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean train s |
|---|---:|---:|---:|---:|---:|---:|
| adam | 0.0023743919 | 0.0011977793 | 0.0084668402 | 0.059854495 | 9.0478624e-08 | 1.641 |
| lbfgs | 0.00085311971 | 0.00050226565 | 0.0025732022 | 0.011524573 | 3.9794079e-08 | 24.07 |

## GPR-Referenz

| Modell | Kernel | Mean rel. error | Median | P95 | Maximum | Mean abs. RMS (m) | Mean POD projection |
|---|---|---:|---:|---:|---:|---:|---:|
| GPRReference | fixed-kernel | 0.00039747589 | 0.00024247901 | 0.0012876033 | 0.0034844959 | 1.9888644e-08 | 4.1999376e-05 |

GPR nutzt dieselbe Fold-POD-Darstellung und denselben Koeffizientenfit-Split. Seine feste Sigma-Einstellung ist nicht dieselbe Regularisierungsdefinition wie das MLP-Gewichts-L2.

## Finale Fits auf n=384 (keine Testauswertung)

| Seed | Trainingsfaelle | POD-Rang | Iterationen | Fit s | Abbruchgrund |
|---:|---:|---:|---:|---:|---|
| 42 | 384 | 5 | 250 | 42.77 | Max iterations completed |
| 43 | 384 | 5 | 250 | 30.88 | Max iterations completed |
| 44 | 384 | 5 | 250 | 29.98 | Max iterations completed |

## Kampagnenstatus

Finale MLP-Fits auf jeweils 384 Trainingsfaellen: 3.
Fehlgeschlagene oder abgebrochene Versuche (einschliesslich erfolgreicher Retries davor): 18.

Laufstatus und Fehlergruende: `attempt_ledger.csv` und `attempt_ledger_final.csv`; CV-Ergebnisse je Fall in `cross_validation_case_metrics.csv`; finale Fitzeiten und Seed-/Rangzuordnung in `final_fit_seed_training.csv`; Trainingshistorien in `training_history.csv`. Architektur- und Optimiererdiagramme sowie Kurven liegen als PNG im Studienordner.

Die finale 384-Fall-Fit-Konfiguration ist nur fuer einen spaeteren, neu festgelegten unabhaengigen Test eingefroren. Dieser Auftrag erzeugt keinen neuen Holdout und wertet keine bereits verbrauchten Testfaelle aus.

## Reproduktion

```matlab
openProject('blank_project.prj')
run_restfield_architecture_training('prepare')
run_restfield_architecture_training('pilot')
run_restfield_architecture_training('architecture')
run_restfield_architecture_training('select_architecture')
run_restfield_architecture_training('optimizer')
run_restfield_architecture_training('select_optimizer')
run_restfield_architecture_training('gpr')
run_restfield_architecture_training('final_fit')
run_restfield_architecture_training('evaluate')
```

## Provenienz

Config SHA-256: `de98fbb3ba0a9b774128603a53ce8d4427e97cd27784011f683506a153452e63`
Training data SHA-256: `0ef09c4360774c9a8192f0c9edb3e7d2ed7eeef62361afec1c9e37b4df2bb182`
Git revision at preparation: `aca50b7d74e9d49b3e19fc074c88b9deb25feba6`
Selected architecture: `[32,32]`
MATLAB: 25.2.0.3042426 (R2025b) Update 1; cores reported: 6. Keine neue FEM-Referenzberechnung.
