# Ergänzung v1: wissenschaftliche Darstellung des statischen Vier-Methoden-Vergleichs

Stand 12.11.2026. Kennzeichnungen: **[H]** ursprüngliche Hauptstudie, **[D]** nachträgliche beschreibende Auswertung, **[B]** zusätzlicher Zeitbenchmark, **[Hyp]** Folgehypothese. Die Hauptstudie und ihre Modelle bleiben unverändert.

## 1. Fragestellung und Aufbau [H]

Aus sechs Eingabeparametern sollen die vollständigen statischen FEM-Verschiebungsfelder an 525 Punkten mit drei Komponenten (1575 Werte) vorhergesagt werden. Verglichen wurden direktes MLP, die vorhandene RBF-Variante, POD–MLP und POD–GPR. Eigenfrequenzen sind ausgeschlossen. Der Trainingspool umfasst 768 Fälle aus zwei Blöcken; für Lernkurven wurden N=48, 96, 192, 384 und 768 betrachtet. Die neuen Referenzen umfassen 128 Validierungs-, 256 Interpolations- und 128 Extrapolationsfälle. Extrapolation betrifft genau einen Parameter, 5–10 % der Trainingsintervallbreite außerhalb einer Grenze.

Die Auswahl erfolgte bei N=384 auf einer blockausgeglichenen Trainingsauswahl anhand des mittleren gewichteten relativen Validierungsfeldfehlers; Gleichstände wurden über P95 und Konfigurations-ID behandelt. Neuronale Topkandidaten wurden mit Seeds 42/43/44 bestätigt; die GPR-Auswahl folgt dem deterministischen Protokoll. Die gewählte Familienkonfiguration wurde für alle Lernkurvengrößen festgehalten: Es fand keine separate Optimierung für jedes N statt. Modell- und Auswahlfreeze erfolgte vor Testlabelzugriff.

## 2. Ausgewählte Konfigurationen [H]

| Methode | Ausgewählte Konfiguration | Loss / Anpassung | Rang |
|---|---|---|---:|
| MLP | 3 verborgene Schichten × 128 | gewichtete Feld-MSE; Adam | – |
| RBF | feste Gaußschicht mit 64 Zentren und Breitenparameter 2; danach 2 Tanh-Schichten × 64 (hiddenLayers=3) | gewichtete Feld-MSE; Adam | – |
| POD–MLP | 3 verborgene Schichten × 80 | gewichtete Feld-MSE; Adam | 2 |
| POD–GPR | ARD-Matérn-5/2, linearer Mittelwert, konstantes numerisches Sigma 0,001 | exakte GPR, zwei Starts | 15 |

Neuronale Grundwerte: CPU, maximal 200 Epochen, Batch 32, Lernrate 0,001. GPR-Parameter für Adam in der gemeinsamen gespeicherten Konfigurationsstruktur sind für GPR nicht wirksam. GPR verwendet zwei Startlängenskalen und Quasi-Newton mit maximal 500 Iterationen; Sigma ist keine physikalische Rauschschätzung. Der tatsächlich untersuchte direkte MLP-Suchraum umfasste Breiten 64/128, Tiefen 2/3, Lernraten 0,0005/0,001 und beide Losses. Die ursprünglich vorgesehenen Breiten 32/80 fehlen: Einschränkung des Suchraums, kein Beleg der Ungültigkeit des durchgeführten Vergleichs.

## 3. Vollpool: Genauigkeit und ursprüngliche Fit-Zeiten [H/D]

| Methode | Interpolation Mittel / P95 / Maximum | Extrapolation Mittel / P95 / Maximum | Fit-Hauptmodell Seed 42 | Neuronale Fit-Zeiten Seeds 42/43/44 |
|---|---:|---:|---:|---|
| MLP | 4.64 % / 14.78 % / 58.59 % | 16.24 % / 50.74 % / 638.23 % | 52.67 s | 52.67, 59.93, 54.07 s |
| RBF | 7.41 % / 22.57 % / 97.21 % | 32.67 % / 102.03 % / 1253.55 % | 43.71 s | 43.71, 45.16, 44.40 s |
| POD–MLP | 4.78 % / 15.73 % / 43.78 % | 13.74 % / 47.82 % / 286.56 % | 32.26 s | 32.26, 35.57, 35.22 s |
| POD–GPR | 0.55 % / 2.20 % / 6.65 % | 3.85 % / 15.85 % / 88.55 % | 353.57 s | nicht zutreffend |

Mittelwert und P95 sind je Lauf über Fälle berechnet und für neuronale Modelle über drei Initialisierungen gemittelt; Maximum ist das größte beobachtete Fallmaximum. GPR hat im Vollpool eine Datenwahl und einen ausgewerteten Hauptlauf. Die Fit-Zeit dieses Hauptmodells beträgt **353,5687942 s**, nicht den Median der Zeitwiederholungen.

Drei GPR-Fit-Zeitmessungen derselben Konfiguration: 353.5687942, 337.1902846, 336.1487963 s; Median **337.1902846 s**, Minimum 336.1487963 s, Maximum 353.5687942 s. Die Checkpoints bestätigen identische Konfiguration, Trainings-IDs und Trainings-/Validierungsfingerprints. Alle drei Zeiten messen den öffentlichen `fitModel`-Aufruf ohne Speichern und Validierungsvorhersage. Sie sind Wiederholungen der Zeitmessung, keine unabhängigen Modelle oder Datenziehungen; die drei neuronalen Seeds messen dagegen unterschiedliche Initialisierungen. Zeitbedingungen waren seriell geplant, verbleibende Systemeffekte sind nicht auszuschließen.

## 4. Lernkurven und Verteilung [H]

| Methode | N=48 | N=96 | N=192 | N=384 | N=768 |
|---|---:|---:|---:|---:|---:|
| MLP | 114.93 % | 10.96 % | 5.58 % | 4.91 % | 4.64 % |
| RBF | 29.48 % | 13.27 % | 11.22 % | 8.14 % | 7.41 % |
| POD–MLP | 145.46 % | 28.80 % | 9.71 % | 4.29 % | 4.78 % |
| POD–GPR | 29.31 % | 7.72 % | 2.69 % | 1.25 % | 0.55 % |

Bei N=192 verringerte das raumfüllende gegenüber dem auf kleine Längen konzentrierten Design den mittleren Interpolationsfehler in dieser separaten Studie: MLP 5,45 statt 14,28 %, RBF 7,65 statt 23,35 %, POD–MLP 6,97 statt 15,27 %, POD–GPR 2,90 statt 5,08 %. Fallzahl, Randpunkte und Testfälle waren gleich. Dies ist ein deskriptiver Vergleich der konkreten Designs.

## 5. Kontrollierter POD-Rang und Kosten bei N=768 [D]

Ein gemeinsamer POD-Zustand wurde pro Rang und Auswahl bereitgestellt. Eigenständige Fit-Zeit = gemessener öffentlicher Fit mit vorberechneter Basis plus separat gemessene gemeinsame POD-Zeit; dies ist eine additive Schätzung der eigenständigen Pipeline. Einzelfall- und Batch-128-Zeiten sind Mediane der vollständigen Vorhersageaufrufe; sie stammen aus der ursprünglichen Messung. Pro Zeile liegt ein kontrollierter Lauf mit Seed 42 vor, kein Mittel über drei neuronale Initialisierungen.

| Split | Methode | Rang | Läufe | Projektion | Feldfehler | Fit inkl. POD | Einzel / Batch 128 | Modellgröße |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| extrapolation | POD–GPR | 2 | 1 | 0.1154 % | 3.861 % | 70.53 s | 2.21 / 7.32 ms | 5.34 MB |
| extrapolation | POD–GPR | 10 | 1 | 0.0012 % | 3.853 % | 217.62 s | 5.19 / 30.61 ms | 25.98 MB |
| extrapolation | POD–GPR | 15 | 1 | 0.0008 % | 3.854 % | 348.22 s | 7.61 / 48.96 ms | 39.06 MB |
| extrapolation | POD–MLP | 2 | 1 | 0.1154 % | 13.850 % | 32.45 s | 10.90 / 14.25 ms | 0.37 MB |
| extrapolation | POD–MLP | 10 | 1 | 0.0012 % | 11.627 % | 39.40 s | 10.33 / 12.57 ms | 0.65 MB |
| extrapolation | POD–MLP | 15 | 1 | 0.0008 % | 14.397 % | 38.40 s | 8.32 / 9.99 ms | 0.83 MB |
| interpolation | POD–GPR | 2 | 1 | 0.0588 % | 0.560 % | 70.53 s | 2.21 / 7.32 ms | 5.34 MB |
| interpolation | POD–GPR | 10 | 1 | 0.0008 % | 0.549 % | 217.62 s | 5.19 / 30.61 ms | 25.98 MB |
| interpolation | POD–GPR | 15 | 1 | 0.0005 % | 0.549 % | 348.22 s | 7.61 / 48.96 ms | 39.06 MB |
| interpolation | POD–MLP | 2 | 1 | 0.0588 % | 5.022 % | 32.45 s | 10.90 / 14.25 ms | 0.37 MB |
| interpolation | POD–MLP | 10 | 1 | 0.0008 % | 3.993 % | 39.40 s | 10.33 / 12.57 ms | 0.65 MB |
| interpolation | POD–MLP | 15 | 1 | 0.0005 % | 3.056 % | 38.40 s | 8.32 / 9.99 ms | 0.83 MB |

Die Projektion ist ein mittlerer relativer Anteil; 0,00 % nach Rundung bedeutet nicht exakt null. Rang 2 versus 15 bei POD–GPR: Interpolation 0,560 % versus 0,549 %, Extrapolation 3,861 % versus 3,854 %, bei etwa 70,53 versus 348,22 s eigenständigem Fit. **[Hyp]** Ein kleiner Rang könnte bei diesem Problem ein günstiges Genauigkeits-/Aufwandsverhältnis bieten. Diese nach Testeinsicht formulierte Hypothese erfordert eine neue vorab definierte Prüfung; der Validierungssieger Rang 15 wird in dieser Studie nicht ersetzt.

## 6. Extrapolationsdiagnose [D]

Für die Diagnose wurden die maximalen relativen Fehler je Familie über alle Vollpoolläufe bestimmt. Alle vier Maxima betreffen Fall **830644**. Die Parameter sind L=0,692972916 m, b=0,088804909 m, h=0,129583372 m, E=203010440886,835 Pa, ν=0,281823598 und Fz=−29,9501651 N. Fz liegt oberhalb der oberen Trainingsgrenze −100 N, um 70,049835 N bzw. 7,7833 % der Intervallbreite von 900 N. Die gewichtete FEM-Referenznorm beträgt 5,07563×10⁻⁷ m.

| Methode / Seed des globalen Maximums | Absoluter Feldfehler | Relativer Feldfehler | Spitzenfehler | Maximumfehler |
|---|---:|---:|---:|---:|
| MLP / 43 | 0.003239 mm | 638.23 % | 0.007050 mm | 0.005042 mm |
| RBF / 44 | 0.006363 mm | 1253.55 % | 0.013717 mm | 0.011660 mm |
| POD–MLP / 42 | 0.001454 mm | 286.56 % | 0.002986 mm | 0.000911 mm |
| POD–GPR / 42 | 0.000449 mm | 88.55 % | -0.000923 mm | 0.000923 mm |

Für denselben Fall nachfolgend alle vier vorab festgelegten Seed-42-Modelle: Die angegebenen Spitzen- und Maximalwerte sind FEM-Wert plus gespeicherte vorzeichenbehaftete Abweichung. Sie sind keine Mittelwerte über Seeds.

| Methode, Seed 42 | relativer Fehler | FEM-Spitze / Vorhersage | FEM-Maximum / Vorhersage |
|---|---:|---:|---:|
| MLP | 553.61 % | -0.001033 / 0.005000 mm | 0.001043 / 0.005052 mm |
| POD–GPR | 88.55 % | -0.001033 / -0.001955 mm | 0.001043 / 0.001966 mm |
| POD–MLP | 286.56 % | -0.001033 / 0.001953 mm | 0.001043 / 0.001954 mm |
| RBF | 763.73 % | -0.001033 / 0.007900 mm | 0.001043 / 0.008453 mm |

Die folgenden Gruppenwerte verwenden nur die vier Seed-42-Hauptmodelle, je 10 oder 11 Fälle pro Gruppe. Sie sind explorativ; einzelne Fallkombinationen unterscheiden sich und Gruppenunterschiede belegen keine Kausalität.

| Parameter / Seite | Fälle | MLP | RBF | POD–MLP | POD–GPR |
|---|---:|---:|---:|---:|---:|
| L_m / lower | 11 | 39.07 % | 45.82 % | 19.12 % | 4.87 % |
| L_m / upper | 11 | 3.71 % | 6.06 % | 7.06 % | 0.64 % |
| b_m / lower | 11 | 4.18 % | 8.74 % | 4.75 % | 0.43 % |
| b_m / upper | 11 | 4.52 % | 13.32 % | 7.46 % | 0.69 % |
| h_m / lower | 11 | 4.85 % | 14.20 % | 4.13 % | 2.09 % |
| h_m / upper | 11 | 11.78 % | 17.76 % | 7.97 % | 2.03 % |
| E_Pa / lower | 11 | 4.57 % | 13.28 % | 3.81 % | 2.04 % |
| E_Pa / upper | 11 | 7.33 % | 16.97 % | 8.51 % | 1.44 % |
| nu / lower | 10 | 7.35 % | 17.61 % | 7.18 % | 0.72 % |
| nu / upper | 10 | 2.94 % | 12.79 % | 6.05 % | 0.67 % |
| Fz_N / lower | 10 | 5.47 % | 8.22 % | 6.59 % | 1.08 % |
| Fz_N / upper | 10 | 128.55 % | 240.88 % | 88.37 % | 31.20 % |

Die 13 größten relativen Fehler je Methode hatten bei MLP/RBF/POD–MLP eine mediane Referenznorm von 2,54×10⁻⁶ m, bei GPR 4,94×10⁻⁶ m; der Median aller 128 Referenznormen war 5,04×10⁻⁵ m. Unter diesen jeweils 13 Fällen lagen 7/9/6/8 in der Fz-oberhalb-Gruppe (MLP/RBF/POD–MLP/GPR); diese Gruppe enthält insgesamt zehn Fälle. Kleine Referenznormen und die Lastgruppe gehen hier häufig mit großen relativen Fehlern einher. Der absolute Feldfehler von Fall 830644 ist nicht null; zudem sind die mittleren absoluten Fehler in der Fz-unterhalb-Gruppe bei allen Methoden größer als in der Fz-oberhalb-Gruppe. Kleine Normen erklären folglich einen Teil der relativen Zuspitzung, aber nicht sämtliche absoluten Abweichungen. Korrelationen und Gruppenwerte sind beschreibend, keine kausale Analyse. Details und alle 512 Seed-42-Fallzeilen stehen in den CSV-Dateien.

## 7. Zusätzlicher FEM-/Surrogatbenchmark [B]

Vorab festgelegte 12 Positionen im Interpolationsdatensatz, unabhängig vom Surrogatfehler; gleiche Eingaben, eingefrorene Vollpoolmodelle Seed 42, MATLAB R2025b, AMD Ryzen 5 4500U (6 Kerne). Serielle Messung, kein zusätzlich gestarteter Studienjob. Ein FEM-Warm-up; anschließend zwei vollständige solve_case-Aufrufe je Fall in umgekehrter Reihenfolge. Die FEM-Zeit umfasst Geometrie, Netz, Lösung, Interpolation aller 525 Punkte sowie Spitzenabfrage und Prüfungen. Pro Surrogat Warm-up und 30 Einzelaufrufe je Fall sowie 30 gemeinsame 12er-Batches; öffentliche Vorhersage mit Rücktransformation und Prüfung. Modelle werden vorab geladen, Ladezeiten separat; Dateizugriffe ausgeschlossen. Die Fälle stammen aus der Interpolation und sind nicht repräsentativ für beliebige zukünftige Verteilungen.

| Methode | FEM Einzelfall: Median (IQR zwischen Fällen) | Surrogat Einzel: Median (IQR zwischen Fällen) | FEM seriell 12 Fälle | Surrogat Batch 12 | Modell laden |
|---|---:|---:|---:|---:|---:|
| MLP | 2.189 (1.734) s | 9.252 (0.348) ms | 29.418 s | 10.684 ms | 5.708 s |
| RBF | 2.189 (1.734) s | 8.445 (0.478) ms | 29.418 s | 9.835 ms | 0.609 s |
| POD–MLP | 2.189 (1.734) s | 8.491 (0.519) ms | 29.418 s | 10.146 ms | 0.313 s |
| POD–GPR | 2.189 (1.734) s | 7.573 (0.265) ms | 29.418 s | 18.469 ms | 1.641 s |

Die FEM-Einzelfallwerte sind zunächst Mediane aus zwei Wiederholungen je Fall; anschließend werden Median und IQR über die zwölf Fälle gebildet. Der FEM-12er-Wert ist die Summe dieser fallweisen Mediane, keine Messung eines optimierten FEM-Batchsolvers. Batch-Zeiten sind Mediane aus 30 Aufrufen; ihre IQR und alle Rohzeiten stehen in den Benchmark-CSVs. Der erste gemessene Ladevorgang kann Start-/Cacheeffekte enthalten. FEM umfasst zusätzliche Spitzenabfrage und Prüfungen; die Zeitumfänge sind deshalb dokumentiert vergleichbar, aber nicht exakt identisch.

### Bedingte Break-even-Rechnung [B/D]

Für ein Einzelfall-Szenario: Q_BE = ceil(C_offline / (t_FEM − t_Surrogat)), nur für positiven Nenner. C_offline enthält den gemessenen Fit des Seed-42-Hauptmodells, optional die äußere Familiensuche. Fit und Suche stammen aus der früheren Hauptstudie, die Vorhersage- und FEM-Zeiten aus dem neuen Benchmark auf derselben Maschine; sie wurden nicht in derselben Sitzung gemessen. Für den 12er-Fall wird die gleiche Formel auf die Kosten pro Batch angewandt und anschließend mit 12 multipliziert. Es handelt sich um grobe Szenarien auf Basis von Medianen, ohne Unsicherheitsintervall und ohne Einbezug von Lade-/Speicherkosten, wiederholten Modellaktualisierungen oder Qualitätssicherung.

| Methode | Einzelfälle: vorhandene Daten, Fit | Einzelfälle: Fit + Suche | 12er-Fälle: vorhandene Daten, Fit | 12er-Fälle: Fit + Suche |
|---|---:|---:|---:|---:|
| MLP | 25 | 356 | 24 | 324 |
| RBF | 21 | 346 | 24 | 312 |
| POD–MLP | 15 | 153 | 24 | 144 |
| POD–GPR | 163 | 714 | 156 | 636 |

Bei vorhandenen Trainings- und Validierungsdaten werden diese als versunkene beziehungsweise verfügbare Ressource behandelt. Für eine hypothetische Neuerzeugung ist nur eine unvollständige historische Kostenannahme verfügbar: 1632,92 s summierte historische Trainings-Solverzeit plus 566,11 s aktive Validierungserzeugung, zusammen 2199,03 s. Die historische Trainings-Gesamtzeit fehlt; diese gemischte Annahme ist weder eine kontrolliert neu gemessene Vollerzeugung noch eine belastbare untere Schranke. Als reine Rechenillustration ergibt sie folgende zusätzliche Szenarien:
- MLP: 1034 Einzelfälle mit Fit; 1365 mit Fit und Suche.
- RBF: 1029 Einzelfälle mit Fit; 1354 mit Fit und Suche.
- POD–MLP: 1024 Einzelfälle mit Fit; 1161 mit Fit und Suche.
- POD–GPR: 1171 Einzelfälle mit Fit; 1723 mit Fit und Suche.

Die historischen Zahlen sind Annahmen, nicht durch den neuen Benchmark nachgemessen. Testdatenerzeugung, Pilot, Mehrfachläufe, Qualitätssicherung, Verwaltung sowie zusätzliche Studienkosten sind nicht enthalten. Andere Eingabeverteilungen, Hardware, Auslastung und FEM-Netze können die Schwellen stark verändern. Die Rang-2-Hypothese wird für diese Berechnung nicht nachträglich zum Gewinner erklärt.

## 8. Grenzen und Empfehlung

Der größte relative Ausreißer zeigt, dass die im Mittel gute Extrapolation nicht für jeden Fall zuverlässig ist. Für Genauigkeit innerhalb des untersuchten Bereichs ist POD–GPR ein sinnvoller Ausgangspunkt, bei deutlich höherem Fit-Aufwand. POD–MLP ist schneller trainiert; direktes MLP und die konkrete RBF-Variante bleiben Bezugspunkte innerhalb ihrer durchsuchten Räume. Keine allgemeine Methodenüberlegenheit wird behauptet. Die FEM ist eine numerische Referenz; der Pilot beweist keine globale Netzkonvergenz. Der ursprüngliche MLP-Suchraum und ein belastbarer allgemein gültiger Break-even bleiben unvollständig.

Die erste Testauswertung brach nach dem ersten Modell durch Überschreiben einer Manifestvariablen ab. Die technische Korrektur entstand nach dem ersten Testzugriff und ist separat dokumentiert und gehasht. Die Nachtragsprüfung weist unveränderte Modelle, Auswahlregeln und Metriken aus; die beiden bereits erzeugten Split-Ergebnisse stimmen in zwölf geprüften numerischen Größen mit der Wiederholung überein. Dies macht die Korrektur transparent, nicht nachträglich vorab registriert.

Rohdaten und Rechenschritte: `benchmark_results.mat`, `benchmark_fem_raw.csv`, `benchmark_surrogate_raw.csv`, `benchmark_summary.csv`, `break_even_scenarios.csv`, `controlled_rank_n768.csv`, `extrapolation_global_peaks.csv`, `extrapolation_outliers_paired.csv`, `extrapolation_group_summary.csv`, `extrapolation_all_seed42.csv`, `analyse_v1.py`, `report_v1.py` und `analysis_provenance.json`. Die ursprünglichen Dateien bleiben unverändert.
