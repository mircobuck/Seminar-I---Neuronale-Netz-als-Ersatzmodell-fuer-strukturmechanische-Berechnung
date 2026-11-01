# Abschlussbericht: Lernkurven und Datenbedarf

Stand: 28.10.2026. Entwicklungsvalidierung mit 128 neuen festen Faellen; keine unabhaengige Abschlusspruefung.

## Befund

Die kleinste untersuchte Trainingsgroesse mit P95 <= 1 % fuer alle drei MLP-Seeds ist **48**; auch 96, 192 und 384 erfuellen das Ziel. GPR erreicht das Ziel erstmals bei **48** Faellen und ebenfalls bei allen groesseren untersuchten Groessen. Dies ist eine Aussage ueber diese feste Entwicklungsstichprobe; die Stichprobe wurde zur Datenbedarfsauswahl verwendet und benoetigt spaetere unabhaengige Bestaetigung. P95 ist nearest-rank (122. sortierter Fall bei 128).

Die analytische Balkenreferenz erreicht P95 2,371 % und ist unabhaengig von n. Die Seedstreuung ist bei n=12 und n=24 gross; ein gepooltes Perzentil wird nicht zur Entscheidung verwendet. Verbesserungen sind nicht zwingend monoton: zum Beispiel steigt der P95 von Seed 43 zwischen n=192 und n=384.

## Vollstaendige Ergebnistabelle

Relative Werte in Prozent; absolute gewichtete RMS-Werte in Metern; Projektion ist der mittlere relative Projektionsfehler. Zeiten sind gemessene Fitzeiten.

| n | Modell | Seed | Rang | Mittel % | Median % | P95 % | Max % | Mittel abs. m | Max abs. m | Projektion % | Fit s | Abbruchgrund |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 12 | beam | 0 | 4 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00857 | 0.00 | analytical |
| 12 | gpr | 42 | 4 | 0.5558 | 0.2818 | 2.0536 | 3.4665 | 2.04e-07 | 1.09e-06 | 0.00857 | 0.61 | GPR fit completed |
| 12 | mlp | 42 | 4 | 0.5816 | 0.2949 | 2.2313 | 5.0847 | 2.04e-07 | 1.28e-06 | 0.00857 | 8.25 | Suitable learning rate not found |
| 12 | mlp | 43 | 4 | 0.7337 | 0.2916 | 3.1506 | 7.6354 | 2.28e-07 | 1.22e-06 | 0.00857 | 8.22 | Suitable learning rate not found |
| 12 | mlp | 44 | 4 | 0.8455 | 0.3309 | 3.0400 | 10.1402 | 2.46e-07 | 1.31e-06 | 0.00857 | 4.89 | Suitable learning rate not found |
| 24 | beam | 0 | 4 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00710 | 0.00 | analytical |
| 24 | gpr | 42 | 4 | 0.4897 | 0.1997 | 2.1890 | 4.9045 | 1.57e-07 | 1.14e-06 | 0.00710 | 0.13 | GPR fit completed |
| 24 | mlp | 42 | 4 | 0.2923 | 0.1433 | 1.0836 | 3.1964 | 1.35e-07 | 1.21e-06 | 0.00710 | 5.98 | Suitable learning rate not found |
| 24 | mlp | 43 | 4 | 0.3087 | 0.1688 | 0.9843 | 3.7885 | 1.29e-07 | 1.18e-06 | 0.00710 | 6.61 | Suitable learning rate not found |
| 24 | mlp | 44 | 4 | 0.5835 | 0.2109 | 2.5228 | 8.1438 | 1.72e-07 | 1.2e-06 | 0.00710 | 5.90 | Suitable learning rate not found |
| 48 | beam | 0 | 5 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00396 | 0.00 | analytical |
| 48 | gpr | 42 | 5 | 0.1524 | 0.0805 | 0.5290 | 1.3547 | 8.7e-08 | 9.59e-07 | 0.00396 | 0.20 | GPR fit completed |
| 48 | mlp | 42 | 5 | 0.1475 | 0.0899 | 0.5139 | 1.1763 | 9.61e-08 | 1.16e-06 | 0.00396 | 13.18 | Suitable learning rate not found |
| 48 | mlp | 43 | 5 | 0.1545 | 0.0966 | 0.4564 | 1.1574 | 1.07e-07 | 1.2e-06 | 0.00396 | 13.33 | Max iterations completed |
| 48 | mlp | 44 | 5 | 0.1823 | 0.1055 | 0.5855 | 1.2707 | 1.03e-07 | 1.26e-06 | 0.00396 | 11.21 | Suitable learning rate not found |
| 96 | beam | 0 | 5 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00352 | 0.00 | analytical |
| 96 | gpr | 42 | 5 | 0.0970 | 0.0425 | 0.2939 | 2.0573 | 5.58e-08 | 7.61e-07 | 0.00352 | 0.52 | GPR fit completed |
| 96 | mlp | 42 | 5 | 0.0917 | 0.0550 | 0.2626 | 0.7079 | 6.43e-08 | 9.77e-07 | 0.00352 | 12.54 | Max iterations completed |
| 96 | mlp | 43 | 5 | 0.0698 | 0.0480 | 0.1852 | 0.4116 | 6.61e-08 | 1.05e-06 | 0.00352 | 13.14 | Max iterations completed |
| 96 | mlp | 44 | 5 | 0.1136 | 0.0598 | 0.4167 | 0.7681 | 7.14e-08 | 9.07e-07 | 0.00352 | 11.98 | Max iterations completed |
| 192 | beam | 0 | 5 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00365 | 0.00 | analytical |
| 192 | gpr | 42 | 5 | 0.0413 | 0.0289 | 0.1363 | 0.2434 | 3.05e-08 | 5.52e-07 | 0.00365 | 1.44 | GPR fit completed |
| 192 | mlp | 42 | 5 | 0.0701 | 0.0433 | 0.1733 | 0.6809 | 5.56e-08 | 7.97e-07 | 0.00365 | 11.59 | Max iterations completed |
| 192 | mlp | 43 | 5 | 0.0809 | 0.0543 | 0.2733 | 0.8700 | 5.07e-08 | 7.91e-07 | 0.00365 | 12.53 | Max iterations completed |
| 192 | mlp | 44 | 5 | 0.0839 | 0.0504 | 0.2274 | 0.7767 | 4.74e-08 | 5.64e-07 | 0.00365 | 12.26 | Max iterations completed |
| 384 | beam | 0 | 5 | 0.7559 | 0.4653 | 2.3713 | 3.1173 | 3.06e-07 | 1.52e-06 | 0.00392 | 0.00 | analytical |
| 384 | gpr | 42 | 5 | 0.0283 | 0.0188 | 0.0882 | 0.2471 | 1.6e-08 | 1.83e-07 | 0.00392 | 10.02 | GPR fit completed |
| 384 | mlp | 42 | 5 | 0.0732 | 0.0519 | 0.1989 | 0.6070 | 3.34e-08 | 1.96e-07 | 0.00392 | 42.77 | Max iterations completed |
| 384 | mlp | 43 | 5 | 0.0875 | 0.0437 | 0.3288 | 0.9214 | 3.51e-08 | 2.5e-07 | 0.00392 | 30.88 | Max iterations completed |
| 384 | mlp | 44 | 5 | 0.0784 | 0.0466 | 0.2276 | 0.5139 | 3.54e-08 | 3.16e-07 | 0.00392 | 29.98 | Max iterations completed |

## Durchfuehrung und Integritaet

Versionierte Konfiguration und Protokoll wurden vor FEM und Training gespeichert. Das maximin-LHS-Design (Seed 20261030) wurde vor der FEM-Erzeugung gespeichert und gegen 708 bekannte Designzeilen und IDs abgeglichen; minimaler normalisierter Chebyshev-Abstand 0,0929812. Alle 128 FEM-Faelle wurden erfolgreich erzeugt; keine Fehlversuche. IDs 800001-800128 sind Entwicklungsvalidierung. Trainingsdateien und gemeinsam enthaltene Felder wurden auf Uebereinstimmung geprueft.

POD-Mittelwert, Basis, Koeffizienten und Skalierung wurden je Trainingsgroesse ausschliesslich aus Trainingsfaellen berechnet. MLP und GPR teilen diese Darstellung: fuer alle Groessen wurden IDs, Projektionen sowie Eingabe- und Koeffizientenmittelwerte und -standardabweichungen verglichen. Der technische Pilot mit n=12 und 10 L-BFGS-Iterationen pruefte ausserdem Rekonstruktion, Metrikidentitaet und wiederholtes Aufrufen ohne erneutes Training. Ein erneuter Kampagnenaufruf nutzte die bestehenden Laufdateien.

Die 384er-Fits wurden wiederverwendet: Trainingsdatenhash und IDs, POD-Mittelwert, Basis, Gewichte, Rang und Koeffizienten sowie gespeicherte Konfiguration stimmen ueberein. Die drei Fitzeiten stammen daher aus der Vorstudie und wurden nicht erneut aufgewendet. Vorbereitungs- und Codeaenderungen sind in den technischen Nachtraegen mit Pruefsummen dokumentiert.

FEM-Rechenzeit gesamt: 198.22 s. Kampagnen-Fitzeiten MLP insgesamt einschliesslich wiederverwendeter Vorstudienfits: 255.24 s; davon neu: 151.61 s. GPR-Fitzeiten gesamt: 12.92 s. Zeiten sind nicht Gesamtlaufzeiten und haengen von Hardware und Umgebung ab. Pilot und Vorverarbeitung sind darin nicht enthalten.

Alle 30 Kampagnenlaeufe und drei Pilotlaeufe sind im Ledger erfasst; keine Fehlerartefakte. Einige L-BFGS-Laeufe endeten mit "Suitable learning rate not found", andere am Iterationslimit. Das ist kein Nachweis erfolgreicher Konvergenz; diese Laeufe blieben vollstaendig in der Auswertung. Trainingshistorien, Fallmetriken und FEM-Ledger sind gesondert gespeichert.

## Artefakte und Wiederaufnahme

- `summary.csv`, `case_metrics.csv`, `attempt_ledger.csv`, `development_fem_ledger.csv`, `training_history.csv` und `learning_curves_v3.png`.
- `prepared.mat`, `provenance_amendment_01.json`, `provenance_amendment_02.json` und `SHA256SUMS.csv` enthalten Provenienz und Pruefsummen.
- MATLAB R2025b Update 1; Toolbox- und Rechnerdaten in `prepared.mat`.

```matlab
openProject('blank_project.prj')
run_restfield_learning_curve('prepare')
run_restfield_learning_curve('fem')
run_restfield_learning_curve('pilot')
run_restfield_learning_curve('campaign')
run_restfield_learning_curve('evaluate')
```

Aufruf aus dem Projektordner. Bestehende erfolgreiche Faelle und Fits werden geprueft und nicht erneut berechnet; Auswertungsausgaben werden erhalten. Bei abweichender Provenienz wird abgebrochen. Fuer eine vollstaendige Neuberechnung muss eine neue versionierte Studie angelegt werden; die vorhandenen Ergebnisse nicht ueberschreiben.

Das eingefrorene Originalprotokoll enthaelt durch einen Kodierungsfehler einzelne Fragezeichen; `PROTOCOL_READABLE.md` ist eine nachtraegliche Lesefassung. Das Original und seine urspruengliche Pruefsumme bleiben erhalten.
