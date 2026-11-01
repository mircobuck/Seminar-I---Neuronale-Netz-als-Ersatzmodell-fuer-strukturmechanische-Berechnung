# Projektstand fuer weiterarbeitende Agenten

Stand: 28. Oktober 2026. Dies ist eine datierte Orientierung, kein Ersatz fuer
den aktuellen Git-Status, die Versuchskonfigurationen oder die Ergebnisberichte.
Vor Aenderungen zuerst `AGENTS.md`, danach diesen Stand und den betroffenen
Versuchsbericht lesen. Status und Arbeitskopie vor Beginn selbst verifizieren.

## Projektziel und Arbeitsablauf

Das Projekt untersucht Ersatz- und reduzierte Modelle fuer einen parametrisierten
Kragtraeger-FEM-Benchmark. FEM-Berechnungen erzeugen Referenzfaelle:

- **Statik:** Parameter wie Geometrie, Material und Last als Eingabe;
  Verschiebungsfeld und skalare Groessen als Zielwerte.
- **Modalanalyse:** Geometrie, Material und Dichte als Eingabe;
  Eigenfrequenzen und FEM-Eigenformen als Referenzwerte.

Typischer Studienablauf:

1. Konfiguration, Parameterdesign, Fall-IDs und Splits festlegen.
2. FEM-Referenzdaten erzeugen oder geprueft wiederverwenden.
3. Vorverarbeitung und gegebenenfalls Feldreduktion ausschliesslich mit
   Trainingsdaten bestimmen.
4. Modell auf Trainingsdaten anpassen und Kandidaten anhand der Validierung
   auswaehlen.
5. Modelle einfrieren und erst dann auf Testdaten auswerten.
6. Fehler, Laufzeiten, Provenienz und Grenzen dokumentieren.

Eigenfrequenzen und Eigenformen sind unterschiedliche Zielgroessen. Ein Modell,
das Frequenzen vorhersagt, ist kein Eigenform-Surrogat. Ebenso ist ein
implementiertes Modell nicht automatisch ueber alle Trainingsgroessen getestet
oder als Ersatzmodell wissenschaftlich bestaetigt.

## Implementierte Modellfamilien

### Statische skalare Groessen

- `Scalar_GPR`: GPR-Baseline fuer skalare Groessen.
- `Beam_theory`: analytische Balkentheorie fuer die Spitzenverschiebung.
- `Beam_plus_GPR`: analytische Spitzenverschiebung mit gelernter skalarer
  GPR-Korrektur; kein Feldmodell.

### Statische Verschiebungsfelder

- `POD_GP`, `POD_RBF`, `POD_MLP`: gewichtete POD reduziert die FEM-Felder auf
  Koeffizienten; GP, RBF beziehungsweise MLP regressieren diese Koeffizienten.
- `POD_Galerkin`: physikalisches POD-Galerkin-ROM mit reduzierter Mechanik.
- `DeepONet`: Parameter-/Ortsmodell fuer das Verschiebungsfeld.
- `Beam_Field_POD_GPR`: Balkenphysik plus POD-GPR auf dem Differenzfeld. Code
  vorhanden; laut Modellregister ist die Validierung noch offen.
- Neue neuronale Varianten im Versuch `neural_comparison_20261027_v1`:
  neuronales POD-MLP und neuronales Restfeldmodell. Bisherige neue Lernkurve:
  nur n=12 fuer Seeds 42, 43 und 44.

### Modalmodelle

- `Frequency_GPR`: sagt Eigenfrequenzen voraus, nicht Eigenformen. Im
  Architektur-Integrationsversuch mit kleinem Datensatz getestet.
- `fitNeural(..., "frequency", ...)`: neuronaler Frequenzregressor ist als
  Modellpfad vorhanden. Die neue variable-Dichte-Studie ist noch nicht
  abgeschlossen.
- **Kein fertiges Ersatzmodell fuer FEM-Eigenformen** ist derzeit ausgewiesen.
  Vorhandene FEM-Moden dienen als Referenzdaten, nicht als Nachweis eines
  Eigenform-Surrogats.

Die zentrale Paketimplementierung liegt unter `src/+femstudy`; aeltere
Implementierungen unter `src` bleiben fuer historische Studien erhalten.
Das Modellregister unter `src/+femstudy/+models/registry.m` bildet nicht
zwangsläufig jeden experimentellen Prototypen oder neuen Studienpfad ab.

## Prototypen, nicht als vollstaendige Modellvergleiche werten

Der aktuelle neuronale Versuch enthaelt Schnittstellen-/Machbarkeitsprototypen:

- **PINN:** eindimensionaler Euler-Bernoulli-Balken; kein 3-D-FEM-Feld-PINN.
- **Fourier-Gittermodell:** Fourier-Features und regularisierter Readout;
  keine vollstaendige mehrschichtige FNO-Reproduktion.
- **Graphmodell:** statischer Message-Passing-Prototyp auf quadratischen
  Tetraedern; kein vollstaendiger dynamischer MeshGraphNet-Simulator.
- **DeepONet-Adapter:** Paketadapter fuer den vorhandenen Ansatz; der fruehere
  DeepONet-Vergleich bleibt ein negativer, archivierter Studienbefund.

Die Aussagegrenzen stehen in
`experiments/active/neural_comparison_20261027_v1/PROTOTYPES.md`.

## Aktive Arbeit und verifizierter Stand

Der aktive Versuch `neural_comparison_20261027_v1` ist durch
`configs/neural_comparison_v1.json` und `PROTOCOL.md` vorab festgelegt.
Details und Resultate stehen im Versuch selbst; dieses Dokument dupliziert sie
nicht vollstaendig.

Der PDF-Bericht mit MATLAB-erzeugten Ergebnisplots ist
[project-status-20261028.pdf](./project-status-20261028.pdf). Die einzelnen
Plots liegen als PNG und editierbare MATLAB-FIG-Dateien im Ordner
`experiments/active/neural_comparison_20261027_v1/figures`; reproduzierbar
erzeugt werden sie mit `create_project_status_report` nach dem Oeffnen des
MATLAB-Projekts.

Der einheitliche Benutzer-Einstieg fuer den aktuellen Vergleich ist jetzt
`run_study`. Die Phasen `prepare_study_data`, `train_study_models`,
`evaluate_study_models` und `plot_study_results` trennen Daten, Fits, finale
Tests und Plots. Der bestehende `run_neural_comparison` bleibt als interner,
wiederaufnehmbarer Studien-Runner erhalten; historische Studien-Runner sind
nicht entfernt oder in diesen Main umgeleitet.

Zum aktualisierten Auswertungsstand:

- `run_checks(false)` bestanden.
- `neuralStudyTest`: 5/5; `neuralPrototypeTest`: 3/3 bestanden.
- Vorbereitung und `prototype_checks` reproduzierbar ausgefuehrt.
- Die statische Lernkurve (n=12 bis 384, drei Seeds, POD-MLP und Restfeld-MLP)
  sowie 64 unabhaengige statische FEM-Testfaelle sind ausgewertet. Bester
  n=384-Restfeldlauf: 0,0311 % Medianfehler; vollstaendige Kennzahlen im
  Versuchsordner, nicht mit historischen Studien vermischen.
- 396 modale Trainings-/Validierungsreferenzen und 64 unabhaengige
  Modaltestreferenzen liegen vor. Frequenz-GPR und Frequenz-MLP wurden fuer
  alle Trainingsgroessen trainiert und ausgewertet; n=384-GPR: 0,395 %
  Medianfehler der Frequenzen.
- MATLAB Code Analyzer ohne Befunde; Detailpruefungen und alle relativen
  Testfehlerwerte gueltig. Die wiederkehrende Triangulationswarnung bei
  Modalprojektion ist im Versuchsfortschritt festgehalten.
- Die Frequenzstudie sagt keine Eigenformen voraus. MAC-basierte
  Modenfamilienauswertung und kontrollierte Amortisationsanalyse sind nicht
  abgeschlossen; siehe Grenzen und Daten im Versuchsbericht.

Reproduktion und Stufen stehen in `scripts/matlab/run_neural_comparison.m`;
den tatsaechlich implementierten Stufen folgen, nicht eine geplante Stufe
als verfuegbar voraussetzen.

## Fruehere Befunde

- Die verschachtelte Trainingsgroessenstudie bis n=384 und der
  POD-Galerkin-Vergleich sind abgeschlossen dokumentiert.
- Im frueheren festen Vergleich erzielte POD-GPR bei n=384 einen
  Feldmedianfehler von rund 0,384 %. Diese Zahl gehoert zu genau dieser
  Studie und ist kein Ergebnis der neuen neuronalen Studie.
- Der DeepONet-Vergleich ist archiviert und fiel im damaligen Vergleich
  deutlich schlechter als POD-GPR aus.
- Die unabhaengige statische 64-Fall-Bestaetigungsstudie ist ein verbrauchter
  Bestaetigungssatz; nicht als unberuehrter Testsatz wiederverwenden.

Der gemeinsame statische n=384-Vergleich ist auf dem vorab versiegelten,
unabhaengigen 64-Fall-Holdout abgeschlossen. Alle neun Modell-/Seed-Varianten
wurden auf allen 64 Referenzfaellen ausgewertet. Das interne Arbeitsziel
P95 <= 1 % erreichen alle drei Beam-Restfeld-MLP-Seeds sowie Beamfeld plus
POD-GPR auf dem Restfeld. Der erste FEM-Aufruf fuer ID 700001 scheiterte nach
erfolgreichem Solve an einem Runnerfehler; der Fehlerdatensatz blieb erhalten
und dieselbe ID wurde ohne Ersatzfall erfolgreich wiederaufgenommen. Details
und Einschraenkungen stehen in
`experiments/active/static_shared_comparison_20261028_v1/FINAL_REPORT.md`.
Als naechstes einzelnes Arbeitspaket wird dort ein kontrollierter MLP-gegen-
GPR-Vergleich mit gemeinsamer train-only POD-Basis, identischen Splits und
angeglichenem Auswahlbudget empfohlen; noch nicht implementiert.

Der kontrollierte Architektur- und Trainingsvergleich des Balken-Restfeld-MLP
ist abgeschlossen und auditiert. Drei gruppierte Folds innerhalb der
vorhandenen n=384-Trainingsdaten wurden ausgewertet; gewaehlt wurden
Architektur [32,32] und L-BFGS. Drei finale Modelle wurden auf allen 384
Trainingsfaellen gefittet. Es wurden weder Holdout-Faelle zur Auswahl genutzt
noch neue FEM-Labels erzeugt. Ergebnisse und Grenzen stehen im Bericht der
Studie und im Studienindex. Die CV ist kein unabhaengiger Abschlusstest.

## Grenzen der bisherigen Methodikvergleiche

- Ein Optimierervergleich ist nicht belegt: Die untersuchten MLP-Modelle
  verwenden Adam; mehrere Architektur-/Breitenkandidaten sind kein Vergleich
  unterschiedlicher Optimierer.
- Ein Samplingvergleich ist nicht belegt: Lernkurven und Bestaetigungsstudien
  mit jeweils festgelegter Datenverteilung vergleichen nicht verschiedene
  Trainingsdatenverteilungen bei gleicher Fallzahl.
- Der gemeinsame statische n=384-Vergleich bewertet vorhandene Modellvarianten
  auf gemeinsamen Referenzfaellen. Abweichende POD-Raenge, Normierungen,
  Auswahlbudgets und historische Fit-Verfahren verhindern eine isolierte
  kausale Aussage MLP gegen GPR. Der unabhaengige 64-Fall-Test zeigt die
  konkreten Ergebnisse, beseitigt diese methodischen Unterschiede aber nicht.

Der Studienindex ist `docs/experiment-index.md`; Berichte und Kennzahlen
verifizieren, bevor sie fuer neue Schlussfolgerungen zitiert werden.

## Orientierung fuer Aenderungen

- Nur `github_dd_branch/Code/MATLAB_FEM_Start` ist die kanonische bearbeitbare
  Projektkopie. Projektregeln stehen in `AGENTS.md`.
- Neue MATLAB-Paketlogik gehoert nach `src/+femstudy`, Studienrunner nach
  `scripts/matlab`, versionierte Eingaben nach `configs`.
- Neue Studien erhalten eigene versionierte Ausgabeordner unter
  `experiments/active` und einen Eintrag in `docs/experiment-index.md`.
- Bestehende Ergebnisartefakte nicht ueberschreiben; negative Ergebnisse
  aufbewahren. Vorhandene lokale Aenderungen anderer Arbeit nicht verwerfen.
- Die Arbeitskopie war beim Erstellen dieses Dokuments nicht sauber. Vor
  Aenderungen stets `git status` pruefen und bestehende Aenderungen integrieren.
- MATLAB R2025b ist laut Projektunterlagen vorhanden. Keine FEM- oder
  toolboxintensiven Studien automatisch starten; Laufzeit und Datenkosten
  koennen erheblich sein. Fuer normales gezieltes Codearbeiten zuerst
  `run_checks(false)` ausfuehren.


## Lernkurvenstudie Restfeld (28.10.2026)

`experiments/active/restfield_learning_curve_20261028_v1` ist abgeschlossen. Auf 128 neuen Entwicklungsvalidierungsfaellen erreichen alle drei MLP-Seeds sowie GPR das P95-Arbeitsziel erstmals bei n=48 und auch bei 96, 192 und 384. Einige L-BFGS-Laeufe endeten wegen nicht gefundener Schrittweite; Einzelheiten und Einschraenkungen stehen im Abschlussbericht. Die Entwicklungsvalidierung ist kein unabhaengiger Abschlusstest.

## Trainingsdatenverteilung bei 48 Faellen (29.10.2026)

`experiments/active/restfield_sampling48_20261028_v1` ist abgeschlossen.
Sechs neue Designs (drei uniform, drei Maximin-LHS) mit je 48 neu berechneten
Trainingsreferenzen wurden auf derselben 128-Fall-Entwicklungsvalidierung
untersucht. P95 <= 1 % erreichen 9/18 MLP-Laeufe; nur bei 1/6 Designs alle
drei Seeds. GPR erreicht das Ziel bei 4/6 Designs. In dieser kleinen
Stichprobe ist kein konsistenter praktischer LHS-Vorteil belegt. Die fruehere
Aussage zum Datenbedarf von 48 Faellen gilt fuer das damalige Design und ist
keine robuste Garantie fuer beliebige Datendesigns. Neun MLP-Fits meldeten
`Suitable learning rate not found`; sie sind als auswertbare Modellstaende,
nicht als nachgewiesen konvergiert, enthalten. Unabhaengiger Abschlusstest
bleibt offen. Versuchstabelle, Metriken und Grenzen stehen im Studienbericht.

Ergaenzung 29.10.2026: 48 Faelle genuegten im urspruenglichen Design; eine
zuverlaessige Uebertragung auf andere 48-Fall-Designs wurde nicht bestaetigt.
Ein konsistenter LHS-Vorteil ist nicht belegt. Eine designuebergreifend
robuste Mindestdatenmenge ist weiterhin unbekannt. Die deskriptive Auswertung
der L-BFGS-Abbruchgruende steht in `docs/static_sampling_termination_analysis_20261029.md`;
ein kausaler Zusammenhang ist nicht belegt.

## Eigenfrequenzen: kontrollierter Optimierervergleich (29.10.2026)

`experiments/active/modal_frequency_optimizer_20261029_v1` verglich Adam und
L-BFGS bei festem [32,32]-tanh-MLP und logarithmischen Frequenzzielen auf den
384 vorhandenen Modal-Trainingsfaellen. Drei gespeicherte Folds, Seeds 42-44;
keine bisherigen Holdout-Labels und keine neuen FEM-Faelle. Mittlerer relativer
CV-Fehler der rohen sechs Frequenzen: Adam 5.50239 %, L-BFGS 0.99786 %, feste
GPR-Referenz 0.60690 %. L-BFGS wurde nach der vorab festgelegten Metrik fuer
die neuronale Konfiguration ausgewaehlt; drei Fits auf allen 384 Faellen sind
gespeichert und benoetigen unabhaengige Pruefung. Die Budgets und Laufzeiten
der Optimierer unterscheiden sich, und ein Budgetende belegt keine
Konvergenz. Frequenzsortierung ist keine Eigenformvorhersage und kein
Modenfamilien-Tracking; rohe Ordnungsverletzungen bleiben dokumentiert.

## Unabhaengige statische und modale Abschlusspruefung (29.10.2026)

`experiments/active/independent_static_modal_20261029_v1`: zwei neue
Holdouts mit je 128 vollstaendigen FEM-Faellen, vor Labelzugriff eingefrorene
Modelle und Designs, keine nachtraegliche Modellauswahl. Statische P95 der
drei 384-Fall-Restfeld-MLPs: 0.273 %, 0.195 %, 0.245 %; die gemeinsame
Restfeld-GPR: 0.112 %. Alle vier erfuellen das interne Feld-P95-Ziel von 1 %.
Der groesste MLP-Feldfehler erreicht 1.58 %. Das Ergebnis belegt keine
designuebergreifende Mindestdatenmenge.

Modale Rohvorhersage: keine der 18 MLP-Seed-/Frequenzkombinationen und keine
der sechs GPR-Frequenzen erreicht P95 <= 1 %. Die MLP-P95 liegen zwischen
2.126 und 4.226 %, die GPR-P95 zwischen 1.223 und 2.299 %. Niedrigere mittlere
Fehler sind keine Erfuellung des P95-Ziels. Eigenformen/Modenfamilien wurden
nicht validiert. Vorabpilot, Integritaetsaudit und Wiederaufnahme sind im
Bericht dokumentiert; die gesonderte Zeitmessungs-Pilotpruefung wurde vor dem
Freeze nicht vollstaendig ausgefuehrt. Ein Modal-FEM-Fall enthaelt wegen einer
Sitzungsunterbrechung stark erhoehte, nicht als reine Rechenzeit auswertbare
Wandzeit. Details und Seminarmatrix: `FINAL_REPORT_v2.md`.
