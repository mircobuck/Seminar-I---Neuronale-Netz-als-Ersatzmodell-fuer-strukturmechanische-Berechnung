# Projektstand fuer weiterarbeitende Agenten

Stand: 27. Oktober 2026. Dies ist eine datierte Orientierung, kein Ersatz fuer
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

Zum protokollierten Stand:

- `run_checks(false)` bestanden.
- `neuralStudyTest`: 5/5; `neuralPrototypeTest`: 3/3 bestanden.
- Vorbereitung und `prototype_checks` reproduzierbar ausgefuehrt.
- Statische n=12-Stufe fuer drei Seeds gerechnet; n=24/48/96/192/384 fehlen
  in diesem neuen Versuch.
- 176 modale FEM-Referenzen aus dem geplanten Trainings-/Validierungsbereich
  gespeichert und gegen den versiegelten Entwurf geprueft. Die Erzeugung der
  uebrigen 220 Referenzen wurde wegen Laufzeit kontrolliert angehalten; der
  Runner ist pro Fall wiederaufnehmbar.
- Modale Lernkurve, finale Testreferenzen, Modenfamilienauswertung,
  vollstaendige Berichte und kontrollierte Laufzeitvergleiche sind offen.

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
