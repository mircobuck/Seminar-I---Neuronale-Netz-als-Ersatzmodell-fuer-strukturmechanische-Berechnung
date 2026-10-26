# Projektstruktur und Architektur: MATLAB_FEM_Start

Stand: 26. Oktober 2026. Diese Übersicht beschreibt den vorhandenen Projektstand und trennt implementierte Bausteine, ausgeführte Studien und offene Erweiterungen.

## Ziel und Gesamtaufbau

Das Projekt untersucht FEM-Ersatzmodelle für einen parametrischen, einseitig eingespannten Balken. Ein Finite-Elemente-Modell erzeugt Referenzdaten. Daraus werden Modelle aufgebaut, die für neue Parameter beispielsweise statische Verschiebungsfelder oder Eigenfrequenzen annähern.

Die Architektur ist teilweise migriert: Die ursprüngliche Implementierung liegt überwiegend in src, neuere Schnittstellen und Modalbausteine liegen im MATLAB-Paket +femstudy. Skripte im Projektwurzelordner steuern die Studien. Ergebnisse und eingefrorene Modelle liegen in getrennten Experimentordnern.

**Datenfluss:** Konfiguration und Parameterfälle → FEM-Referenz → gespeicherte Daten und Splits → Training und Modellartefakt → Vorhersage → Fehlerauswertung und Bericht.

Bei einer Vorhersage werden nur erlaubte Modelleingaben verwendet. FEM-Testfelder dienen anschließend dem Vergleich und nicht der Berechnung ihrer Vorhersage.

## Projektordner

Der Projektordner ist **C:\Users\dietz\Downloads\MATLAB_FEM_Start\MATLAB_FEM_Start**.

| Ordner oder Datei | Aufgabe |
|---|---|
| config.m | Parameterbereiche, Einheiten und Standardoptionen |
| run_project.m und weitere run-Skripte | Steuerung der ursprünglichen Abläufe und einzelnen Studien |
| controlled_predict.m | Vorhersage für kontrollierte normierte Modelle |
| src/ | Ursprüngliche FEM-, Daten- und Modellfunktionen |
| +femstudy/ | Neuere paketierte Architekturbausteine |
| tests/ | MATLAB-Tests und Prüfungen |
| designs/ | Parameterdesigns für smoke und pilot |
| runs/ | Ergebnisse des ursprünglichen Projektablaufs |
| experiments/ | Versionierte Studien, Modelle und Ergebnisse |
| verification/ | Prüfprotokolle und Ausführungsnachweise |
| docs/ und scripts/ | Architektur- und Konventionsdokumente sowie ergänzende Hilfsskripte |
| .agents/ und .codex/ | Lokale Agenten-, Skill- und Promptdateien |
| AGENTS.md | Lokale Arbeitsregeln für dieses Projekt |

Dateien innerhalb von experiments, runs und verification enthalten historische Ergebnisse und sind keine bloß temporären Ausgaben.

## Physikalische Konfiguration

[config.m](config.m) definiert Parameterreihenfolge und Standardeinstellungen. Statische Eingaben sind Länge L, Breite b, Höhe h, Elastizitätsmodul E, Querkontraktionszahl nu und Stirnlast Fz. Die Längen sind in Metern, E in Pascal und Fz in Newton angegeben.

Die statische Referenz ist ein linear-elastischer Quader: Eine Stirnfläche ist fest eingespannt, auf die andere wirkt eine gleichmäßig verteilte Last. Die Standardkonfiguration verwendet ein quadratisches Tetraedernetz mit Hmax = min(b,h)/3. Für das ungedämpfte Modalproblem wird statt der statischen Last die Dichte benötigt. Die bisherige kleine Modalstudie verwendet eine konstante Demonstrationsdichte.

## Ursprüngliche Implementierung: src

| Aufgabe | Wichtige Dateien unter src | Funktion |
|---|---|---|
| Statisches FEM | solve_case.m | Geometrie, Material, Netz, Last, Lösung und Gitterübertragung |
| Datenerzeugung | generate_dataset.m | Gespeicherte Datensätze und Einzelresultate aus Parameterfällen |
| Gemeinsames Gitter | reference_grid.m | 21 × 5 × 5 Punkte und zugehörige Gewichte |
| Modelltraining | train_models.m | Ursprüngliche statische Modelle aufbauen |
| POD | pod_fit.m, pod_encode.m | Feldbasis und Koeffizienten |
| Regression | fit_gps.m, fit_rbf.m, fit_mlp.m, predict_reg.m | Regression für Skalare oder POD-Koeffizienten |
| Physikbaseline | beam_tip.m | Analytische Balkenspitze |
| DeepONet | fit_deeponet.m, deeponet_forward.m, predict_deeponet.m | Training und Vorhersage des Operatornetzes |
| POD-Galerkin-ROM | rom_assemble.m, rom_observation.m, rom_predict.m | Mechanisch reduziertes Modell und räumliche Übertragung |
| Auswertung | predict_surrogate.m, evaluate_models.m, field_error.m | Vorhersage und Fehlerberechnung |

Der ursprüngliche Ablauf wird über run_project.m mit den Phasen generate, train und evaluate gesteuert. predict_new.m und plot_test_case.m dienen vorhandenen Projektläufen als weitere Einstiegspunkte. Welche Daten und Modelle ein Aufruf verwendet, hängt von Modus und Ergebnisordner ab.

## Neuere Architektur: +femstudy

Ein Pluszeichen kennzeichnet ein MATLAB-Paket. Die Datei +femstudy/+fem/modal.m wird als femstudy.fem.modal angesprochen.

| Paket | Wichtige Inhalte | Rolle |
|---|---|---|
| femstudy.data | assertCompatible, hybridContract | Raumverträglichkeit und generischer Vertrag für hybride Modelle |
| femstudy.fem | modal, compareModes, beamField | Modal-FEM, Moden-/Clustervergleich und statisches Balkenfeld |
| femstudy.models | registry, Legacy-Adapter, Frequenz-GPR und Balkenfeld-POD-GPR | Modellinventar sowie Fit- und Predict-Funktionen |
| femstudy.metrics | frequency | Frequenzmetriken |
| femstudy.report | writeIntegration | Berichtsfunktion für den Integrationslauf |

Das Paket ersetzt die ursprünglichen Funktionen nicht vollständig. Legacy-Adapter verbinden registrierte Modellnamen mit älteren Vorhersagefunktionen; neuere Versuchs- und Auswertungsskripte liegen weiterhin auch im Projektwurzelordner.

**Wichtig:** Die textuellen Statuswerte in registry.m enthalten Formulierungen wie „pending“. Sie sind nicht allein maßgeblich für den tatsächlichen Prüfstand: Spätere Experimentartefakte dokumentieren bereits durchgeführte Adapter- und Hybridprüfungen.

## Modellbestand

| Modell | Ausgabe | Grundprinzip und Onlinebedarf | Stand |
|---|---|---|---|
| Scalar_GPR | Statische Skalare | Gaußprozessregression aus Parametern | Historisch vorhanden; Adapter geprüft |
| Beam_theory | Statische Spitze | Physikalische Balkenformel ohne Training | Historisch vorhanden; Adapter geprüft |
| Beam_plus_GPR | Statische Spitze | Balkenformel plus gelernte skalare Korrektur | Historisch vorhanden; Adapter geprüft |
| POD_GP | Statisches Feld | POD-Basis; GPR sagt Feldkoeffizienten voraus | Historisch vorhanden; Adapter geprüft |
| POD_RBF | Statisches Feld | POD-Basis und Radialbasisregression | Historisch vorhanden; Adapter geprüft |
| POD_MLP | Statisches Feld | POD-Basis und neuronale Regression | Historisch vorhanden; Adapter geprüft |
| POD_Galerkin | Statisches Feld | Reduzierte mechanische Gleichung mit Online-Matrixaufbau und Übertragung | Historisch untersucht; Adapter an einem Fall geprüft |
| DeepONet | Statisches Feld | Neuronales Parameter-/Ortsmodell | Historisch untersucht; Adapter geprüft |
| Frequency_GPR | Aufsteigend sortierte Frequenzen | GPR für logarithmierte Eigenfrequenzen | Kleiner Modal-Integrationslauf ausgeführt |
| Beam_Field_POD_GPR | Statisches Feld | Balkenfeld plus gelerntes POD-GPR-Korrekturfeld | Implementiert und in kleinen Versuchen untersucht |
| Normiertes direktes und hybrides POD-GPR | Statisches Feld | Last-/Steifigkeitsnormierung mit eingefrorenen POD- und GPR-Modellen | Separate Versuchsartefakte; auf 64 neuen Fällen ausgewertet |

Die normierten Modelle besitzen eigene gespeicherte Artefakte und werden unter anderem über controlled_predict.m verwendet. Sie sind keine zusätzlichen Einträge des allgemeinen Modellregisters.

Ein hybrides modales Balkenmodell, gelernte Eigenform-Surrogate, gelernte reduzierte Matrizen und neuronale Physikkorrekturen sind nach dem zuletzt dokumentierten Stand nicht implementiert. Das vorhandene Frequenz-GPR verfolgt keine physikalischen Modenfamilien und erzeugt keine Eigenformen.

## Datenräume und Datenfluss

Die FEM-Lösung lebt zunächst auf den Knoten und Freiheitsgraden des jeweiligen Netzes. Für den fallübergreifenden Vergleich werden Verschiebungen auf ein gemeinsames normiertes Abfragegitter interpoliert:

- xi: 3 × 525 normierte Koordinaten.
- S: 1.575 × N Verschiebungswerte für N Fälle.
- Komponentenreihenfolge: alle ux, anschließend uy, anschließend uz.
- X: N × 6 statische Parameterwerte.
- Y: skalare Zielgrößen wie Spitzenverschiebung und Gittermaximum.
- w: Gewichte auf dem gemeinsamen Gitter; sie summieren sich je Komponente auf eins.

Das Abfragegitter ist nicht das native FEM-Netz. Gleiche Matrixabmessungen allein beweisen deshalb keine Raumkompatibilität. femstudy.data.assertCompatible prüft unter anderem Raumkennung, Einheiten, Reihenfolge und Randbedingungen. Für den POD-Galerkin-ROM sind passende native FEM-Räume, Freiheitsgrade und Operatoren erforderlich; datengetriebene POD-Basen auf Abfragepunkten können nicht ohne Weiteres mit nativen Matrizen kombiniert werden.

## Studiensteuerung im Projektwurzelordner

| Einstiegspunkt | Zweck |
|---|---|
| run_project.m | Ursprünglicher smoke-/pilot-Ablauf |
| run_training_size_study.m | Historische statische Trainingsgrößenreihe |
| run_rom_study.m, run_rom_logged.m | POD-Galerkin-Studie |
| run_deeponet_study.m, run_deeponet_logged.m | DeepONet-Studie |
| run_migration_phase1.m | Kleiner Architektur- und Modal-Integrationslauf |
| run_hybrid_static_audit.m | Eingefrorener statischer Hybridvergleich |
| run_hybrid_diagnostics.m, run_gpr_cause_analysis.m | Nachträgliche POD-/GPR-Diagnose |
| run_controlled_gpr_fits.m | Vorab definierte kontrollierte Folge-Fits |
| run_static_confirmation.m | Design, FEM-Einzelfälle und Vorhersagen der Bestätigungsstudie |
| evaluate_static_confirmation.m | Vergleich gespeicherter Vorhersagen mit FEM |
| diagnostic_static_confirmation.m | Nachträgliche Abstands- und Feldbilddiagnose |
| time_static_confirmation.m, time_fem_confirmation.m | Zeitmessungen für Vorhersage beziehungsweise FEM |

Dies sind experimentelle Einstiegspunkte, keine einheitliche vollständig abgesicherte Produktionspipeline. Manche erzeugen Daten oder trainieren Modelle; sie sollten nicht allein zum Lesen dieser Übersicht ausgeführt werden.

## Experimente und Ergebnisablagen

| Ordner unter experiments | Inhalt |
|---|---|
| training_size_12_24_48_20261023/ | Historische statische Lernkurve und Trainingsgrößen |
| pod_galerkin_20261023_v1/ | POD-Galerkin-ROM-Studie |
| deeponet_20261023_v1/ | DeepONet-Studie und historische Vergleiche |
| architecture_phase1_v1/ | Architektur- und kleiner Modal-Integrationslauf |
| definitions/ | Entwürfe für spätere Studienkonfigurationen |
| hybrid_beam_phase1_v1/ | Erste statische Balkenfeld-Hybridvariante |
| hybrid_static_audit_v1/ | Eingefrorener statischer Vergleich und Diagnose |
| hybrid_gpr_diagnosis_v1/ | Ursachenanalyse der eingefrorenen GPR-Modelle |
| hybrid_controlled_fits_v1/ | Kontrollierte Fits und normalisierte Modellvarianten |
| static_confirmation_v1/ | Unabhängiger statischer Vergleich mit 64 neuen Fällen |
| modal_hybrid_followup_v1/ | Beginn der modalen Folgearbeit: bisher Übertragungsprüfung |
| scientific_synthesis_20261026_v1/ | Wissenschaftlich-technische Gesamtausarbeitung |

Historische Artefakte und neue Ergebnisse sind in getrennten Ordnern abgelegt. analysis_v2.mat ist die maßgebliche Version der GPR-Kernelkorrelationsdiagnose; die entsprechenden Werte aus dem älteren analysis.mat sind wegen eines Diagnosefehlers ungültig.

## Beispiel: Bestätigungsstudie für das statische Feld

Vorabprotokoll und Modellhashes → 64 neue Parameterfälle → FEM-Referenzen und drei eingefrorene Vorhersagen → fallweise Metriken → gepaarter Vergleich und Bericht.

Das Protokoll und die Modelle wurden vor dem neuen Vergleich festgelegt. Die vorhergesagten Felder wurden getrennt gespeichert; erst danach wurden sie mit FEM-Referenzen verglichen. Die nachträgliche POD-Projektion nutzt Referenzfelder als Diagnose und gehört nicht zum Online-Vorhersagepfad.

Wichtige Artefakte liegen in [experiments/static_confirmation_v1/](experiments/static_confirmation_v1/), unter anderem PROTOKOLL.md, design.csv, einzelne FEM-MAT-Dateien, predictions.mat, case_metrics.csv, paired.csv und [VOLLSTAENDIGER_BERICHT.md](experiments/static_confirmation_v1/VOLLSTAENDIGER_BERICHT.md). Die 64 Fälle wurden für den Vergleich verwendet und sind kein unberührter Test für spätere Modelländerungen.

## Tests, Berichte und Nachweise

- tests/run_checks.m: grundlegende Projektprüfungen.
- tests/test_migration_phase1.m: unter anderem Raum-, Split- und Modalprüfungen.
- tests/test_beam_field_hybrid.m: Prüfungen rund um Balkenfeld und Hybrid.
- tests/deeponetTest.m: DeepONet-bezogene Tests.
- verification/: gespeicherte Nachweise früherer Aufrufe.
- Python-Skripte im Projekt und in Experimentordnern: Aufbereitung vorhandener Ergebnisse und Berichtserstellung.

Ein vorhandener Test oder eine vorhandene Funktion bedeutet nicht, dass alle denkbaren Fälle und Schnittstellen vollständig abgenommen sind. Konkrete Ergebnisse und Grenzen stehen in den jeweiligen Experimentberichten.

## Aktuelle Grenzen und offene Architekturarbeit

- Die Migration in +femstudy ist unvollständig; alte und neue Aufrufpfade bestehen nebeneinander.
- Ein vollständiges allgemeines Metrikregister, umfassende Daten- und Registryverträge sowie durchgängige Status- und Cacheprüfungen sind noch nicht vollständig umgesetzt.
- Das Wiederverwenden einzelner gespeicherter Zustände ist keine allgemeine kryptografische Integritätsprüfung sämtlicher Checkpoints.
- Die modale Übertragung wurde nachträglich an einem vorhandenen Fall erneut geprüft. Die dort erklärte Warnung und die exakte Reproduktion dieses Falls beweisen noch keine allgemeine Robustheit für alle Netze oder Modencluster.
- Ein modales Hybridmodell und ein entsprechender Integrationslauf sind noch offen; die große Modal-Lernkurve wurde nicht gestartet.
- README und ältere Architekturdokumente enthalten zeitgebundene Zwischenstände. Für konkrete Ergebnisse sind die jeweils neueren Experimentartefakte maßgeblich.

## Weiterführende Dokumente

- [Bisherige Architekturphase](ARCHITEKTUR_PHASE1.md): ursprünglicher Migrationsplan und Integrationsnachweise; teilweise zeitlich überholt.
- [Wissenschaftlich-technische Gesamtausarbeitung](experiments/scientific_synthesis_20261026_v1/ausarbeitung.md): physikalischer und mathematischer Hintergrund sowie historische Ergebnisse.
- [Statische Bestätigungsstudie](experiments/static_confirmation_v1/VOLLSTAENDIGER_BERICHT.md): 64-Fall-Vergleich mit Einzelfallanhang.
- [Modaler Zwischenstand](experiments/modal_hybrid_followup_v1/STATUS.md): bisherige Übertragungsprüfung und offene Umsetzung.
- [Projektregeln](AGENTS.md): lokale Arbeits- und Dokumentationsregeln.
