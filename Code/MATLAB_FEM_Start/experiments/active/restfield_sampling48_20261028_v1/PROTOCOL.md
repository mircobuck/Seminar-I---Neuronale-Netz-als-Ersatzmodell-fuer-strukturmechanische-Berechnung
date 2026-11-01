# Versuchsprotokoll: Trainingsdatenverteilung bei 48 Referenzfaellen

Datum: 28.10.2026. Vor neuen FEM-Referenzen und Trainingslaeufen gespeichert.
Konfiguration: `configs/restfield_sampling48_20261028_v1.json`.

## Frage und festgelegter Umfang

Wie empfindlich ist das P95-Arbeitsziel <= 1 % gegen die Auswahl von 48
Trainingsfaellen? Hat Maximin-LHS in diesen Wiederholungen einen praktischen
Vorteil gegenueber unabhaengigen gleichverteilten Zufallsstichproben?
Es gibt genau drei Datendesigns je Strategie, drei MLP-Seeds je Design und
eine GPR-Referenz je Design: 288 neue Trainingsreferenzen, 18 MLP- und sechs
GPR-Kampagnenfits. Kein weiterer Trainingsumfang, kein finaler Holdout.

## Sampling und IDs

Unabhaengige RNG-Neuinitialisierung (`twister`) pro Design. Uniform verwendet
`rand(48,6)` im normierten Wuerfel. LHS verwendet `lhsdesign(48,6)` mit
`Criterion=maximin`, `Iterations=100`, `Smooth=on`. Die Optimierung betrifft
nur den geometrischen Abstand, nie FEM- oder Modellfehler. Es gibt keine
nachtraegliche Designwahl und keine Kopplung gleich nummerierter Designs.

| Design | Seed | IDs (einschliesslich) |
|---|---:|---|
| uniform_01 | 20261101 | 900001-900048 |
| uniform_02 | 20261102 | 900049-900096 |
| uniform_03 | 20261103 | 900097-900144 |
| lhs_01 | 20261104 | 900145-900192 |
| lhs_02 | 20261105 | 900193-900240 |
| lhs_03 | 20261106 | 900241-900288 |

Parameterraum unveraendert: L [0.6,1.2] m, b [0.06,0.10] m,
h [0.08,0.14] m, E [70,210] GPa, nu [0.25,0.35], Fz [-1000,-100] N.
Alle sechs Designs werden vor FEM gespeichert. IDs sowie normierte
Parameterkombinationen werden gegen vorhandene Designdateien in configs,
experiments und runs sowie die feste Entwicklungsvalidierung geprueft.
Unter den sechs Designs und innerhalb jedes Designs ebenfalls disjunkt;
Chebyshev-Abstand > 1e-10. Bei Kollision wird gestoppt, nicht neu gezogen.
Die gespeicherten MAT-Designs sind die exakte numerische Quelle; CSVs sind
lesbare Exporte. Keine Wiederverwendung approximativ aehnlicher Referenzen.

## Referenzkonfiguration und Entwicklungsvalidierung

Gleiche statische 3-D-FEM-Konfiguration wie in der Lernkurve: quadratische
Tetraeder, Hmax=min(b,h)/3, Referenzgitter 21x5x5, Verschiebungen in m,
Klemmrand, Endlast und maxDeflectionRatio=0.02 wie im vorhandenen Solver.
Keine Netz- oder Parameteranpassung bei schwierigen Faellen. Fehler mit
ID, Parametern und Stack speichern. Wiederaufnahme wiederholt denselben
Fall mit neuer Versuchsnummer. Jeder erfolgreiche Fall bleibt unveraendert.
Unvollstaendige 48er-Designs duerfen nicht ausgewertet werden.

Die 128 vorhandenen Entwicklungsfaelle (800001-800128) werden mit ihren
Pruefsummen aus `restfield_learning_curve_20261028_v1` uebernommen.
Sie sind ausschliesslich Auswertungsdaten. Die historische n=48-Stichprobe
wird gesondert als Vergleichsevidenz gezeigt und nicht als vierte Wiederholung
einer Strategie gezaehlt. Fruehere Testlabels werden nicht ausgewertet.

## Modelle und Vorverarbeitung

Train-only Restfeld = FEM minus analytisches Balkenfeld. Je Design eine
gewichtete zentrierte POD: erster Rang mit >=99.99 % Trainingsenergie,
begrenzt durch 32, n-1 und numerischen Rang. Falls die Energieschwelle nicht
erreichbar ist, verfuegbaren Rang nehmen und erreichte Energie berichten.
MLP und GPR erhalten dieselbe Basis, Mittelwerte, Trainingskoeffizienten und
Trainings-IDs. Eingabe- und Koeffizientenskalierung ausschliesslich aus diesen
48 Faellen; bestehende Implementierungen unveraendert verwenden.

MLP [32,32], tanh, trainnet-MSE auf standardisierten Koeffizienten, L2=1e-4,
L-BFGS maximal 250 Iterationen, HistorySize 10, GradientTolerance 1e-6,
StepTolerance 1e-8, CPU, Seeds 42/43/44. Kein Early Stopping und keine
Hyperparameteranpassung. GPR ARD-Matern-5/2, Seed 42, Sigma=1e-4 konstant,
SigmaLowerBound=1e-8, Trainingsfit der uebrigen Hyperparameter durch fitrgp
wie in der Vorstudie. Kein neuer Kernelvergleich.

## Pilot und Abbruchregeln

Pilot auf uniform_01; seine 48 FEM-Faelle zaehlen zu den 288. Zwei getrennte
10-Iterations-MLP-Fits mit Seed 42 pruefen identische Initialgewichte und
reproduzierbare Vorhersagen. Ein gesonderter GPR-Fit prueft gemeinsame
Skalierung/Darstellung. Pilotmodelle sind keine Kampagnenmodelle. Pruefungen:
reproduzierbare Designs, Split-Trennung, train-only Vorverarbeitung,
gewichtete Orthonormalitaet/Rekonstruktion, Metrikidentitaet, vollstaendige
Zuordnungen, Wiederaufnahme und Artefaktschutz. Vor weiteren Fits muss der
Pilot bestanden sein.

Training endet am konfigurierten Budget, an den unveraenderten internen
Trainertoleranzen oder einem dokumentierten Trainerabbruch. Insbesondere
"Suitable learning rate not found" bleibt als auswertbarer Modellstand
enthalten und gilt nicht als Konvergenznachweis. Exceptions werden erhalten;
Wiederholung nur mit unveraenderter Konfiguration und neuer Versuchsnummer.
Auswertung nicht vollstaendiger Kampagnen ist keine abschliessende Bilanz.

## Metriken und vorab festgelegte Auswertung

Relativer gewichteter Feld-L2-Fehler: sqrt(sum(w.*(prediction-reference).^2))
geteilt durch max(sqrt(sum(w.*reference.^2)),1e-14 m). Der absolute Zaehler
wird als bisheriger gewichteter RMS-Feldfehler berichtet; Gewichte sind je
Komponente auf eins normiert (Vektorfeldnorm, nicht noch durch drei geteilt).
Je Design/Modell/Seed: Mittel, Median, nearest-rank P95 (122. von 128), Max,
absolute Mittel/Median/P95/Max, POD-Rang/Energie und Projektionsfehler,
Trainingszeit, Iterationen und Trainerabbruchgrund. Keine Fehlerausreisser
entfernen. Keine gepoolte Seed-Verteilung als Erfuellungskriterium.

Pro Strategie zaehlen: MLP-Laeufe mit P95 <= 0.01 von neun; Designs mit
allen drei erfolgreichen Seeds von drei; GPR-Designs mit Zielerfuellung
von drei. Seed-Streuung innerhalb Designs: Spannweite und Standardabweichung
der drei P95-Werte. Design-Streuung: Spannweite und Standardabweichung der
jeweiligen Designmittel ueber MLP-Seeds sowie der schlechtesten Seed-P95.
GPR entsprechend ueber drei Designs. Fallstreuung bleibt in den 128
Fallmetriken und deren Quantilen sichtbar.

Strategievergleich deskriptiv: Zielerfuellungszahlen, Fehlerniveau,
Spannweiten und Ueberlappung der Designs. Nur drei Designs pro Strategie,
keine weitreichende statistische Ueberlegenheitsbehauptung oder Garantie.
Die Schlussfolgerung bleibt Entwicklungsevidenz auf derselben, bereits zur
Datenbedarfsauswahl verwendeten Validierung.

## Artefakte und Reproduktion

Einmalig geschriebene, SHA-256-gesicherte MAT-Artefakte fuer Designs,
Vorverarbeitung, Fallversuche, Modelle und Ergebnisdatensatz. Pro Versuch
unveraenderliche Start- und Ergebnisdateien; fehlendes Ergebnis nach einem
Abbruch bleibt erkennbar. Bestehende Artefakte vor Wiederverwendung pruefen.
Quellcode, MATLAB-/Toolboxstand, Daten und Konfiguration werden eingefroren.
Tabellen und Abbildungen sind abgeleitete, ebenfalls geschuetzte Ausgaben.
Technische Nachtraege separat speichern und weder Design noch Training
anhand unguenstiger Validierungsresultate aendern.
