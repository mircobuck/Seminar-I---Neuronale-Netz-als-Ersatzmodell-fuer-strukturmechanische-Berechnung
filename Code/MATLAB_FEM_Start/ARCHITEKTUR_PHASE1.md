# Architekturmigration: Phase 1

Stand: laufende Implementierung. Historische Dateien in `experiments/` bleiben unverändert. Neue Berechnungen liegen unter `experiments/architecture_phase1_v1`.

## Modellbestand

| ID | Implementierung | Ausgabe / Methode | Daten und Online-Dienst | Status |
|---|---|---|---|---|
| Scalar_GPR | modelle/Grundlagen/train_models.m, modelle/GPR_RBF/fit_gps.m, modelle/Grundlagen/predict_surrogate.m | Statik, Skalare; GPR | Parameter und Skalare; kein FEM-Dienst | historisch vorhanden; Adapter getestet |
| POD_GP | modelle/POD_ROM/pod_fit.m, modelle/GPR_RBF/fit_gps.m, modelle/Grundlagen/predict_surrogate.m | Statik, Feld; POD und GPR | Parameter und Felder; kein FEM-Dienst | historisch vorhanden; Adapter getestet |
| POD_RBF | modelle/POD_ROM/pod_fit.m, modelle/GPR_RBF/fit_rbf.m, modelle/Grundlagen/predict_surrogate.m | Statik, Feld; POD und RBF | Parameter und Felder; kein FEM-Dienst | historisch vorhanden; Adapter getestet |
| POD_MLP | modelle/POD_ROM/pod_fit.m, modelle/MLP_Adam/fit_mlp.m, modelle/Grundlagen/predict_surrogate.m | Statik, Feld; POD und MLP | Parameter und Felder; kein FEM-Dienst | historisch vorhanden; Adapter getestet |
| Beam_theory | modelle/Grundlagen/beam_tip.m | Statik, Skalar; physikalische Balkentheorie | Geometrie, Material, Last; Balkenformel | historisch vorhanden; Adapter getestet |
| Beam_plus_GPR | modelle/Grundlagen/beam_tip.m, modelle/Grundlagen/train_models.m, modelle/GPR_RBF/fit_gps.m | Statik, Skalar; Balken plus GPR-Korrektur | Parameter und Skalare; Balkenformel | historisch vorhanden; Adapter getestet |
| POD_Galerkin | modelle/POD_ROM/rom_assemble.m, modelle/POD_ROM/rom_observation.m, modelle/POD_ROM/rom_predict.m | Statik, Feld; physikalisches POD-Galerkin-ROM | native FEM-Snapshots; Online-Matrixaufbau und Übertragung | historisch geprüft; Adapter getestet |
| DeepONet | modelle/DeepONet/fit_deeponet.m, modelle/DeepONet/deeponet_forward.m, modelle/DeepONet/predict_deeponet.m | Statik, Feld; neuronales Operatornetz | Parameter, Felder, Abfragepunkte | historisch geprüft; Adapter getestet |
| Frequency_GPR | modelle/Framework/+femstudy/+models/fitFrequency.m, predictFrequency.m | Modal, sortierte Frequenzen; GPR | Trainingsfrequenzen und Parameter | implementiert und im Integrationslauf getestet |

Eigenform-Surrogate, gelernte reduzierte Matrizen und neuronale Physikkorrekturen sind nicht implementiert. Die vorhandene Balken-GPR-Korrektur ist eine skalare und keine Feldkorrektur.

## Verträge und Auswertung

Modalparameter sind L, b, h in m, E in Pa, nu dimensionslos, rho in kg/m³. Es gibt keine Last als Modal-Eingabe. Ergebnisse speichern Frequenzen in Hz, native Eigenformen im komponentenweisen Knotenblock und auf ein festes normiertes 21×5×5-Gitter übertragene Eigenformen. Raumidentitäten müssen zu Matrizen, Gewichten und Randbedingungen passen; gleiche Dimensionen genügen nicht. Native FEM- und Query-Räume sind verschieden.

Die Query-Feldnorm ist sqrt(sum(w .* u.^2)); die eindimensionalen Trapezgewichte summieren sich pro Komponente zu 1 und über drei Komponenten zu 3. Für Verschiebungsfelder hat die Norm die Einheit m; eine nahe-null-Schwelle muss in m angegeben werden. Modalformen werden für Query-Vergleiche auf diese Norm eins normiert; daraus folgt keine Massennormierung. Die Clusterregel von 1 % ist eine konfigurierbare Heuristik. Rangprüfung und Puffermoden-Grenzen sind erforderlich; ein nicht eindeutiger Cluster verhindert einen Konvergenznachweis.

Frequenz-GPR passt für jede Trainingsmenge beide Kernel getrennt an. Skalierung und Kernelparameter stammen nur aus Training; die Validierung wählt anhand des mittleren relativen Fehlers, ohne erneutes Anpassen auf Validierung. Testdaten kommen erst nach Auswahl. Rohvorhersagen und aufsteigend sortierte Vorhersagen werden getrennt abgelegt; Sortieren verwendet keine Testwerte und verfolgt keine physikalischen Modenfamilien. Seed 42 ist der Integrationsseed, keine Wiederholungsstudie.

## Geplante spätere hybride Feldkorrektur

Das Feld ist übertragenes günstiges Physikfeld plus gelerntes Korrekturfeld. `femstudy.data.hybridContract` verlangt Physikmodell-ID und Version, Last und Randbedingungen, explizite Übertragung, Differenzfeld-POD und train-only Vorverarbeitung sowie getrennte Zeiten für Physik, Übertragung, Regression und Rekonstruktion. Später notwendig: Physikadapter und dessen versionierte Konfiguration, paarweise FEM-/Physikfelder auf nachweislich kompatiblen Räumen, Trainings-Split-IDs, Differenzfeld-POD, je ein POD-GPR- oder POD-MLP-Adapter und Tests; diese Modellfamilien werden hier nicht implementiert.

## Größere Modalstudie: Entwurf, kein Lauf

Die historischen n384-Daten verwenden 384 Trainingsfälle, sechs Validierungsfälle (IDs 13–18) und sechs Testfälle (IDs 19–24). Diese sechs Fälle je Split sind ein kleiner Integrationsdatensatz und sechs Moden pro Fall sind keine zusätzlichen unabhängigen Fälle. Trainingsfälle dürfen nicht nachträglich zu unabhängigen Tests umgewidmet werden. Für eine größere Studie sind als Planungsbudget bis zu 384 Trainingsfälle plus 64 neue unabhängige Validierungs- und 64 neue unabhängige Testfälle vorgesehen, also maximal 512 Modalberechnungen. Verfügbarkeit, unabhängige Ziehung und Ähnlichkeiten gegen alle historischen Parametersätze müssen vor Festlegung überprüft werden. Die Daten müssen neu erzeugt und deren Kosten gemessen werden; es handelt sich nicht um vorhandene Modal-FEM-Daten. Für Auswahlsamen und Trainingszufall sind separate Felder vorzusehen; identische Wiederholungen sind keine unabhängigen Wiederholungen.

Keine umfassende Lernkurve automatisch starten. Zuerst Integrationslauf, Netzkonvergenz und endgültige Datensatzdefinition abschließen. Historische Vorhersagen ergebnisoffen reproduzieren; Abweichungen untersuchen und Korrekturen getrennt versionieren.

## Tatsächlicher Stand und offene Arbeiten

Getestet: statischer Direkt-/Adaptervergleich für alle acht Modelle; maximale Abweichung jeweils null. DeepONet wurde auf sechs Fällen verglichen, POD-Galerkin auf einem Fall mit explizitem Netz- und Montagedienst. Ein neuer Scalar_GPR wurde auf den ersten zwölf Trainingsfällen eingefroren. Ein Gleichheitsvergleich gegen gespeicherte historische Kennzahlen und eine vollständige Auswertung aller acht Modelle stehen noch aus.

Getestet: drei Modal-Netzvergleiche auf Hmax=min(b,h)/2, /3 und /4; die größte Frequenzänderung zwischen den feinsten Stufen für die ersten sechs Moden betrug 0,1198 %, 0,1785 % und 0,1061 %. Die Ergebnisse der drei konkreten Parameterfälle sind kein allgemeiner Nachweis für den gesamten Parameterraum. Der Dichtetest mit identischem Netz ergab eine maximale relative Abweichung von 1,74e-9 gegenüber 1/sqrt(2). Die Gitterübertragung meldet MATLABs Warnung, dass einige Eingabepunkte von der Eckknoten-Triangulation nicht referenziert werden; sie verwendet die quadratischen Mittelknoten dennoch in den Formfunktionen.

Getestet: 12 Modaltrainingsfälle, IDs 13–18 für Validierung und 19–24 für Test. ARD-Matérn-5/2 und ARD-Squared-Exponential erzielten 8,163 % bzw. 3,856 % mittleren Validierungsfehler. Der eingefrorene zweite Kandidat erzielte 3,366 % mittleren relativen Testfehler vor und nach Sortierung; keine der sechs Vorhersagen verletzte die Reihenfolge. Speichern/Laden und Wiederaufnahme vorhandener Fälle wurden geprüft. Vier Unit-Tests prüften Raumidentität, Sortierungsmetriken, Split-Überlappung und Vorzeichen-/Clusterrotation.

Implementiert, aber noch nicht vollständig: Raumidentitätsprüfung und Frequenzmetrik, Frequenz-GPR, Modal-FEM, einfache Modellliste, eingeschränkte Stufensteuerung und Hybrid-Vertragsprüfung. Geplant beziehungsweise offen: vollständiges unabhängiges Metrikregister einschließlich Residuen und Massennormen, umfassende Registry- und Datensatzverträge, Stufenstatus und versionsbasierte Cache-Hashes, vollständige Resume-/Fehlerszenarien und historische Kennzahlenvergleiche. Die Netzzuordnung nutzt eine vereinfachte MAC-/Clusterheuristik; weitere Grenzfälle und Konvergenzmetriken sind zu prüfen. Die Stufensperre verhindert parallele Läufe; nach einem harten Abbruch ist `run.lock` erst nach Prüfung, dass kein Lauf mehr aktiv ist, manuell zu entfernen.

Die erzeugte größere Studien-JSON ist bewusst nicht ausführbar und setzt Generierungsverfahren und Seeds noch nicht fest. Eine Untersuchung weiterer vorhandener Designs, ein vollständiger Fall-Herkunftsaudit und die endgültige unabhängige Stichprobenziehung stehen aus. Der Integrationsbericht ist ein kurzer Nachweis, kein vollständiger wissenschaftlicher Studienbericht.
