# Protokoll: Optimierervergleich fuer sechs Eigenfrequenzen

Vor Pilot und Training festgelegt, 29.10.2026. Versionierte Konfiguration:
`configs/modal_frequency_optimizer_20261029_v1.json`.

## Frage und Daten

Uebertraegt sich der in der statischen Restfeldstudie beobachtete Vorteil von
L-BFGS auf eine feste [32,32]-tanh-Architektur fuer die ersten sechs
aufsteigend sortierten Eigenfrequenzen? Die Architektur ist eine
Transferhypothese, keine optimierte Frequenzarchitektur. Es werden keine
Eigenformen vorhergesagt und keine Modenfamilien verfolgt.

Es werden ausschliesslich die bestehenden 384 modalen Trainingsfaelle
300001-300384 aus `neural_comparison_20261027_v1/modal_cases` verwendet.
Parameter: L 0.6-1.2 m, b 0.06-0.10 m, h 0.08-0.14 m, E 70-210 GPa,
nu 0.25-0.35, rho 2700-8900 kg/m3. Keine FEM-Neuberechnung. Die historischen
12 Validierungs- und 64 Testfaelle werden weder geladen noch zur Auswahl
verwendet. Die CV ist Modellauswahlevidenz, kein unabhaengiger Test.

Drei neue, vor dem Pilot gespeicherte Folds entstehen ausschliesslich aus den
384 Trainings-IDs mit MATLAB-RNG twister, Seed 20261029, zufaelliger
Permutation und gleich grossen Abschnitten zu je 128 IDs. Duplicate-Check in
normierten Eingaben auf 1e-12; bei Duplikaten abbrechen statt still zu trennen.
Jeder Fold hat 256 Fit- und 128 aeussere Validierungsfaelle. Alle Kandidaten
nutzen exakt dieselben gespeicherten Folds. IDs und Datenchecksummen werden
gespeichert, bevor ein Fit beginnt.

## Ziel, Skalierung und Verfahren

Die bestehende Frequenzimplementierung verwendet `log(F_Hz)`; alle sechs
positiven Referenzfrequenzen werden so transformiert. Eingaben und log-Ziele
werden je Fold ausschliesslich anhand der 256 Fit-Faelle standardisiert. Die
regressierten standardisierten Logfrequenzen werden zuruecktransformiert und
exponentiert. Dieselbe Skalierungsregel fuer Adam, L-BFGS und GPR; externe
Folds steuern weder Early Stopping noch Hyperparameter. Keine Sortierung vor
der primaeren Metrik.

MLP: [32,32], tanh, lineare sechs Ausgaenge, standardisierte MSE, L2=1e-4,
CPU, Seeds 42/43/44, identische RNG-Initialisierung und Hashpruefung je
Fold/Seed. Adam: 250 Epochen, Batch 256, Lernrate 0.001. L-BFGS: maximal
250 Iterationen, HistorySize 10, GradientTolerance 1e-6, StepTolerance 1e-8.
Keine Validierungsdaten im Training. Interne Trainerabbrueche werden erfasst;
insbesondere ist eine nicht gefundene Schrittweite kein Konvergenznachweis.
Vergleich: neun Fits pro Optimierer, insgesamt 18. Ein train-only
GPR-Referenzfit pro Fold, ARD-Matern-5/2, Sigma=1e-4 konstant,
SigmaLowerBound=1e-8, uebrige Hyperparameter aus Fit-Daten. Kein Kernelvergleich.

## Pilot, Bewertung und Auswahl

Pilot: Fold 1, Seed 42, beide MLPs mit Budget 10 sowie ein GPR-Fit; getrennte
Artefakte, nicht in Kandidatenwertung. Pruefung von Split, Skalierung,
log/exp, positiver Ausgabe, metrischer Aggregation, gleicher Initialisierung
und Wiederaufnahme ohne Ueberschreiben. Exceptions und unterbrochene Versuche
werden erhalten; ein Retry nutzt dieselbe Konfiguration und eine neue Nummer.

Primaer: Mittelwert des absoluten relativen Fehlers ueber rohe Frequenzen,
alle 384 aeusseren Validierungsfaelle, sechs Frequenzindizes und drei Seeds.
Seeds sind Wiederholungen, keine neuen Faelle. Bei Differenz <=1e-12 gewinnt
Adam. GPR wird separat berichtet und ist nicht Gegenstand der Optimiererwahl.
Je Frequenz raw und sorted getrennt: relativer Fehler Mittel, Median,
nearest-rank P95 und Maximum; absolute Fehler in Hz; Fold-/Seed-Werte,
Ordnungsverletzungen pro Fall und benachbartem Frequenzpaar. Sorted ist eine
diagnostische Nachsortierung, die Rohwerte und Verletzungen bleiben sichtbar.
Laufzeiten, Historien und Abbruchgruende werden gespeichert.

Finalregel: Nach Auswahl drei neue MLP-Fits des ausgewaehlten Optimierers
mit denselben Settings und Seeds auf allen 384 Trainingsfaellen, ohne
Validierung oder Early Stopping. Sie bleiben ungetestete eingefrorene
Modellstaende fuer eine spaetere unabhängige Pruefung; keine Holdouts laden.
