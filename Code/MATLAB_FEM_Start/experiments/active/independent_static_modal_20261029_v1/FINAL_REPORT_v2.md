# Unabhaengige Abschlusspruefung: Statik und Eigenfrequenzen

Stand: 29.10.2026. Beide Holdouts wurden vor den neuen FEM-Labels festgelegt. Es gab keine Nachwahl von Seeds oder Hyperparametern. Die Zielgroessen und Fehler der beiden Aufgaben bleiben getrennt.

## Statische Feldauswertung

Alle relativen Werte in Prozent, absolute gewichtete Vektorfeld-RMS-Werte in Metern; P95 nearest-rank (122. von 128). Zeiten: Median ueber 128 fallweise Mediane aus sieben Einzelvorhersagen.

| Modell | Seed | Mittel % | Median % | P95 % | Max % | Mittel abs. m | Median abs. m | P95 abs. m | Max abs. m | P95 <= 1 % | Vorhersage s/Fall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|
| beam | 0 | 0.68293 | 0.50180 | 2.00295 | 2.77602 | 3.055e-07 | 2.437e-07 | 8.102e-07 | 1.311e-06 | nein | 1.075e-05 |
| gpr | 42 | 0.03323 | 0.01885 | 0.11180 | 0.54490 | 1.304e-08 | 8.388e-09 | 3.824e-08 | 7.3e-08 | ja | 0.00206475 |
| mlp | 42 | 0.08822 | 0.04256 | 0.27292 | 1.33629 | 3.413e-08 | 2.187e-08 | 1.228e-07 | 3.316e-07 | ja | 0.00932395 |
| mlp | 43 | 0.06922 | 0.03621 | 0.19471 | 1.58000 | 2.673e-08 | 1.684e-08 | 7.76e-08 | 2.547e-07 | ja | 0.0100441 |
| mlp | 44 | 0.08331 | 0.05371 | 0.24488 | 1.11704 | 3.929e-08 | 2.513e-08 | 1.315e-07 | 2.228e-07 | ja | 0.00753995 |

## Modale Frequenzauswertung

Je Frequenz und Seed: rohe Ausgaben in Hz. Prozent ist der absolute relative Fehler, P95 ist nearest-rank. Das interne P95-Ziel wird je Frequenz und Seed ausgewiesen; ein mittlerer Fehler unter 1 % ist nicht hinreichend.

| Modell | Seed | Frequenz | Mittel % | Median % | P95 % | Max % | Mittel Hz | Median Hz | P95 Hz | Max Hz | P95 <= 1 % |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| gpr | 42 | 1 | 0.33123 | 0.13243 | 1.32989 | 2.78097 | 0.3658 | 0.0973 | 1.583 | 4.963 | nein |
| gpr | 42 | 2 | 0.31209 | 0.13106 | 1.48765 | 2.83800 | 0.3738 | 0.157 | 1.331 | 3.674 | nein |
| gpr | 42 | 3 | 0.34776 | 0.15451 | 1.22340 | 2.87379 | 2.18 | 0.7304 | 8.73 | 29.79 | nein |
| gpr | 42 | 4 | 0.75469 | 0.52519 | 2.29947 | 4.83197 | 5.162 | 3.359 | 19.3 | 30.01 | nein |
| gpr | 42 | 5 | 0.63242 | 0.41627 | 1.91452 | 4.24979 | 5.567 | 3.356 | 18.24 | 41.49 | nein |
| gpr | 42 | 6 | 0.54733 | 0.30601 | 1.78986 | 5.01161 | 7.978 | 3.425 | 32.74 | 89 | nein |
| mlp | 42 | 1 | 0.99509 | 0.65970 | 3.74882 | 8.79033 | 1.001 | 0.4716 | 3.249 | 15.69 | nein |
| mlp | 42 | 2 | 0.96415 | 0.56641 | 3.84686 | 9.25630 | 1.178 | 0.6203 | 3.792 | 19.42 | nein |
| mlp | 42 | 3 | 0.91313 | 0.56530 | 3.13597 | 6.61962 | 5.246 | 2.549 | 16.95 | 68.62 | nein |
| mlp | 42 | 4 | 1.15262 | 0.82830 | 3.35202 | 5.21489 | 8.189 | 5.34 | 25.74 | 60.81 | nein |
| mlp | 42 | 5 | 0.95704 | 0.71353 | 2.48093 | 3.66877 | 8.179 | 5.283 | 24.4 | 46.25 | nein |
| mlp | 42 | 6 | 1.10051 | 0.82445 | 2.88370 | 6.17572 | 14.61 | 9.375 | 46.78 | 70.45 | nein |
| mlp | 43 | 1 | 1.17277 | 0.71717 | 4.22630 | 7.49084 | 1.143 | 0.6819 | 3.536 | 13.37 | nein |
| mlp | 43 | 2 | 1.03405 | 0.73176 | 3.40737 | 8.20018 | 1.208 | 0.8121 | 3.055 | 17.21 | nein |
| mlp | 43 | 3 | 1.02035 | 0.67778 | 3.60722 | 5.88285 | 5.82 | 3.382 | 18.05 | 60.98 | nein |
| mlp | 43 | 4 | 1.04743 | 0.75874 | 2.92687 | 5.49984 | 7.382 | 4.567 | 22.7 | 64.13 | nein |
| mlp | 43 | 5 | 0.80265 | 0.64896 | 2.12633 | 3.39164 | 6.406 | 4.99 | 17.99 | 28.48 | nein |
| mlp | 43 | 6 | 1.08060 | 0.84013 | 2.72180 | 6.34579 | 14.43 | 10.07 | 39.57 | 67.2 | nein |
| mlp | 44 | 1 | 1.19123 | 0.78091 | 3.76634 | 8.46900 | 1.201 | 0.6614 | 3.837 | 15.11 | nein |
| mlp | 44 | 2 | 0.92609 | 0.62051 | 3.31716 | 8.01635 | 1.109 | 0.6431 | 3.705 | 16.82 | nein |
| mlp | 44 | 3 | 1.07659 | 0.67984 | 3.54073 | 7.09533 | 6.195 | 3.587 | 20.8 | 73.55 | nein |
| mlp | 44 | 4 | 1.03467 | 0.77239 | 2.80451 | 5.27064 | 7.124 | 4.489 | 19.34 | 61.46 | nein |
| mlp | 44 | 5 | 0.80877 | 0.60761 | 2.60772 | 3.18393 | 6.859 | 4.704 | 21.9 | 43.66 | nein |
| mlp | 44 | 6 | 1.20385 | 1.09448 | 2.73806 | 4.55662 | 16.6 | 13.52 | 43.37 | 81.12 | nein |

## Einsatzempfehlung innerhalb des getesteten Parameterraums

Statisch erfuellen 3/3 MLP-Seeds und die GPR-Referenz (ja) das P95-Arbeitsziel. Unter den hier untersuchten Modellen ist die GPR-Referenz eine praktische Vergleichs- und Einsatzoption, soweit diese Feldmetrik und der Parameterbereich die Anwendung abdecken; auch einzelne Maximalfehler sind zu beachten. Das ist kein Nachweis fuer andere Geometrien, Lasten oder eine kleinere Trainingsmenge.
Modal erfuellen 0/18 MLP-Seed-/Frequenzkombinationen und 0/6 GPR-Frequenzen das P95-Arbeitsziel. Fuer eine Anwendung, die dieses Ziel fuer jede Frequenz verlangt, ist keines der hier geprueften Modalmodelle anhand dieses Tests ausreichend belegt. Die GPR-Referenz ist ein nuetzlicher Vergleich, aber nicht durch einen Mittelwert unter 1 % fuer das P95-Ziel freigegeben. Keine Eigenform- oder Modenfamilienvalidierung.

## Auffaellige Faelle, Seedstreuung und Frequenzordnung

Die schlechtesten drei statischen Faelle je Modell/Seed (relativer Feldfehler):

| Modell | Seed | IDs und Fehler % |
|---|---:|---|
| beam | 0 | 1000008: 2.7760; 1000018: 2.5824; 1000111: 2.4999 |
| gpr | 42 | 1000111: 0.5449; 1000094: 0.2457; 1000070: 0.1300 |
| mlp | 42 | 1000111: 1.3363; 1000094: 0.6884; 1000116: 0.4254 |
| mlp | 43 | 1000111: 1.5800; 1000104: 0.3958; 1000017: 0.3945 |
| mlp | 44 | 1000111: 1.1170; 1000070: 0.4677; 1000127: 0.4613 |

Modal: schwerster roher Einzelfehler je Modell/Seed (Frequenzindex in Klammern):

| Modell | Seed | Fall (Frequenz) | relativer Fehler % | absolut Hz |
|---|---:|---|---:|---:|
| gpr | 42 | 1100105 (6) | 5.0116 | 89 |
| mlp | 42 | 1100049 (2) | 9.2563 | 19.42 |
| mlp | 43 | 1100049 (2) | 8.2002 | 17.21 |
| mlp | 44 | 1100049 (1) | 8.4690 | 15.11 |

Ordnungsverletzungen der rohen modalen Ausgaben, gezählt pro Fall und Nachbarpaar:

| Modell | Seed | Faelle | Paare 1-2 / 2-3 / 3-4 / 4-5 / 5-6 |
|---|---:|---:|---|
| gpr | 42 | 5/128 | 0 / 0 / 1 / 4 / 0 |
| mlp | 42 | 2/128 | 2 / 0 / 0 / 0 / 0 |
| mlp | 43 | 0/128 | 0 / 0 / 0 / 0 / 0 |
| mlp | 44 | 2/128 | 2 / 0 / 2 / 0 / 0 |

Statische MLP-Seedstreuung je gleichem Fall: mediane Spannweite 0.05153 Prozentpunkte; P95 0.32172 Prozentpunkte. Seeds sind keine zusaetzlichen physikalischen Faelle.

Modal: Spannweite der drei seedweisen P95-Werte je Frequenz:

| Frequenz | Min P95 % | Max P95 % | Spannweite Prozentpunkte |
|---:|---:|---:|---:|
| 1 | 3.74882 | 4.22630 | 0.47747 |
| 2 | 3.31716 | 3.84686 | 0.52970 |
| 3 | 3.13597 | 3.60722 | 0.47125 |
| 4 | 2.80451 | 3.35202 | 0.54751 |
| 5 | 2.12633 | 2.60772 | 0.48139 |
| 6 | 2.72180 | 2.88370 | 0.16190 |

Nachsortierte diagnostische Werte und saemtliche rohen Fallwerte stehen in `modal_case_metrics.csv`; eine Sortierung ist keine Modenfamilienzuordnung und verdeckt die obigen Verletzungen nicht.

## Aufwand und Grenzen

Der Vorabpilot pruefte die Vorhersage- und Metrikschnittstellen, nicht jedoch eine explizite siebenfache Vorhersagezeitmessung. Die Timing-Schleife war vor Labelerzeugung eingefroren; ihre Messwerte wurden nachtraeglich auf Vollstaendigkeit und Endlichkeit geprueft. Dieser begrenzte Pilotmangel ist in `ADDENDUM_04.md` dokumentiert.
- static: 128/128 erfolgreiche FEM-Referenzen, Summe 219.31 s, Median 1.58 s; 0 fehlgeschlagene/unterbrochene Versuche im Ledger.
- modal: 128/128 erfolgreiche FEM-Referenzen, Summe 16531.06 s, Median 10.52 s; 0 fehlgeschlagene/unterbrochene Versuche im Ledger.
  Die Wandzeit des Falls 1100048 betraegt 14903.23 s und ist auffaellig hoch; insbesondere bei einer Sitzungsunterbrechung kann sie Warte-/Stillstandszeit enthalten. Sie bleibt in der Summe; weder diese Summe noch der Einzelwert ist als reine Rechenzeit belastbar. Der Median bleibt als robuste Beschreibung zusaetzlich angegeben.

Vorhersagezeiten pro Modell:

| Aufgabe | Modell | Seed | Median s/Fall | P95 s/Fall |
|---|---|---:|---:|---:|
| modal | gpr | 42 | 0.0014564 | 0.0019638 |
| modal | mlp | 42 | 0.0072601 | 0.0085917 |
| modal | mlp | 43 | 0.00725965 | 0.0091743 |
| modal | mlp | 44 | 0.00720635 | 0.0085981 |
| static | beam | 0 | 1.075e-05 | 1.29e-05 |
| static | gpr | 42 | 0.00206475 | 0.0026619 |
| static | mlp | 42 | 0.00932395 | 0.0138873 |
| static | mlp | 43 | 0.0100441 | 0.0148742 |
| static | mlp | 44 | 0.00753995 | 0.0095206 |

Finale Fitzeiten:

| Modell | Seed | Fit s | Herkunft |
|---|---:|---:|---|
| static_mlp | 42 | 42.77 | historical |
| static_mlp | 43 | 30.88 | historical |
| static_mlp | 44 | 29.98 | historical |
| static_gpr | 42 | 10.02 | historical |
| modal_mlp | 42 | 26.42 | historical |
| modal_mlp | 43 | 25.68 | historical |
| modal_mlp | 44 | 22.25 | historical |
| modal_gpr | 42 | 13.22 | new_fit |

Historischer Entwicklungs-/Suchaufwand (verschiedene Studien und Budgets; nicht als direkter Zeitvergleich zu interpretieren):

| Vorarbeit | Fitversuche | Summe Sekunden | Messumfang |
|---|---:|---:|---|
| Statische CV architecture | 45 | 85.51 | Erfolgs- und Fehlversuche; Ledger-Wandzeiten |
| Statische CV optimizer | 9 | 228.45 | Erfolgs- und Fehlversuche; Ledger-Wandzeiten |
| Statische CV gpr | 3 | 16.54 | Erfolgs- und Fehlversuche; Ledger-Wandzeiten |
| Modale CV adam | 9 | 26.48 | Fitzeit erfolgreicher CV-Laeufe |
| Modale CV lbfgs | 9 | 185.14 | Fitzeit erfolgreicher CV-Laeufe |
| Modale CV gpr | 3 | 14.08 | Fitzeit erfolgreicher CV-Laeufe |
| Statische Lernkurven und Sampling | siehe Berichte | siehe Berichte | getrennte Datendesigns, Pilot- und FEM-Aufwand; keine Doppelzaehlung in den obigen Summen |

Die historischen Fitzeiten stammen aus frueheren Sitzungen; sie sind keine synchron gemessenen Gesamtentwicklungsaufwaende. Modell- und Architektursuche, Pilotstudien sowie die frueheren Trainings-FEM-Kosten sind getrennte, unterschiedlich umfangreiche Vorarbeiten. Eine Amortisationszahl wird nicht angegeben, weil vergleichbare vollstaendige Entwicklungskosten und ein einheitlich kontrollierter Referenz-Zeitversuch fuer alle Komponenten fehlen. Wiederholte Vorhersagemessungen messen einzelne Faelle mit geladenen Modellen, keine Systemintegration.

Vorhandene Nachweise: [FEM-Skalierungs- und Smoke-Pruefung](../../../verification/smoke_20261023_105533/REPORT.md), [POD-Galerkin-Netzvergleich](../pod_galerkin_20261023_v1/REPORT.md), [modale Qualifikation und Triangulationswarnungen](../neural_comparison_20261027_v1/PROGRESS_20261027.md). Diese Pruefungen sind keine lueckenlose Fehlergarantie fuer alle neuen Parameter; Referenzen bleiben numerische FEM-Ergebnisse mit begrenzter Netzaufloesung. Modal werden weder Eigenformen noch Familienzuordnung validiert.

## Seminarweite Ergebnismatrix

| Thema | Einordnung | Quelle |
|---|---|---|
| Modellierungsansatz | Balkenfeld plus gelerntes Restfeld liefert auf dem frueheren gemeinsamen Test einen starken Feldvergleich; direkte POD-Modelle unterscheiden sich in Darstellung und Fitverfahren. | [Gemeinsamer statischer Vergleich](../static_shared_comparison_20261028_v1/FINAL_REPORT.md) |
| Architektur und Training | [32,32]-tanh und L-BFGS wurden mit CV unter endlichem Budget ausgewaehlt; keine allgemeine Architekturoptimalitaet. | [Architektur-/Trainingsstudie](../restfield_mlp_architecture_training_20261028_v1/FINAL_REPORT_v2.md) |
| Datenmenge | 48 Faelle genuegten im urspruenglichen Design; eine designuebergreifend robuste Mindestmenge ist unbekannt. | [Lernkurve](../restfield_learning_curve_20261028_v1/FINAL_REPORT.md) und [Samplingvergleich](../restfield_sampling48_20261028_v1/FINAL_REPORT_v2.md) |
| Datenverteilung | Nur 1/6 neuer 48er-Designs erfuellte das Ziel fuer alle drei Seeds; kein konsistenter LHS-Vorteil. | [Samplingvergleich](../restfield_sampling48_20261028_v1/FINAL_REPORT_v2.md) |
| Statische Genauigkeit | Die neue Tabelle oben bewertet die mit 384 Faellen trainierten Modelle auf 128 neuen Faellen; kein Mindestdatenbeweis. | Dieser Bericht, statische Fallmetriken |
| Eigenfrequenzen | L-BFGS schlug Adam in der Modellauswahl-CV; GPR war dort im Mittel genauer. Neue rohe Testergebnisse oben; keine Eigenformvalidierung. | [Modal-CV](../modal_frequency_optimizer_20261029_v1/FINAL_REPORT_v2.md) und dieser Bericht |
| Rechenaufwand | Vergleiche nur je Modell und Messumfang; FEM-Erzeugung, Entwicklungssuche, finale Fits und Inferenz getrennt. | Dieser Bericht und Quellenstudien |
| DeepONet und RBF | Historische kleine Testsaetze und unterschiedliche Trainingsverfahren begrenzen die Aussage; DeepONet-Negativbefund erhalten. | [Historischer DeepONet-Bericht](../../archive/deeponet_20261023_v1/REPORT.md), [wissenschaftliche Synthese](../scientific_synthesis_20261026_v1/ausarbeitung.md) |
| POD-Galerkin | Auf bekanntem kleinem Testsatz sehr genau, aber Online-Assemblierung weiterhin erforderlich; kein neuer blinder Nachweis. | [POD-Galerkin](../pod_galerkin_20261023_v1/REPORT.md) |
| PINN / Fourier / Graph | Begrenzte Prototypen, keine vollstaendigen leistungsvalidierten Ersatzmodelle. | [Prototypengrenzen](../neural_comparison_20261027_v1/PROTOTYPES.md) |

## Reproduktion und ausstehende Seminararbeiten

Im Projektordner in MATLAB:

```matlab
openProject('blank_project.prj')
run_independent_static_modal('prepare')
run_independent_static_modal('pilot')
run_independent_static_modal('freeze')
run_independent_static_modal('static_data')
run_independent_static_modal('modal_data')
run_independent_static_modal('evaluate')
```

Bericht: `python scripts/python/report_independent_static_modal.py`. Erfolgreiche Faelle und versiegelte Artefakte werden wiederverwendet; Integritaetskonflikte stoppen den Lauf.

Fuer die Seminarabgabe noch erforderlich: Erkenntnisse und Grenzen in die Ausarbeitung und Praesentation uebertragen; Abbildungen, Quellen und Einheiten im Abgabedokument gegenpruefen; verbleibende FEM-Netz- und Modalzuordnungsgrenzen transparent benennen. Diese Punkte sind Dokumentationsarbeiten, keine weitere Modelloptimierung.
