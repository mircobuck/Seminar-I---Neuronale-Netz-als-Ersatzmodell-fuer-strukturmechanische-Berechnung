# Modalstudie: sechs Eigenfrequenzen

MLP, RBF, POD-MLP und POD-GPR. Frequenzraenge 1 bis 6, keine Eigenformvorhersage.
Bekannte Referenzfaelle: kein neuer unabhaengiger Abschlusstest und kein Extrapolationstest.
Auswahl ausschliesslich auf Validierung; insbesondere bei 12 Validierungsfaellen sind Rangfolgen unsicher.
POD-Basis und Normalisierung stammen ausschliesslich aus den Trainingsdaten.
Fehler sind abs(Vorhersage-FEM)/FEM; alle sechs Frequenzraenge erhalten gleiches Gewicht.
Wiederholungen sind keine zusaetzlichen unabhaengigen Testfaelle. Keine nachtraegliche Sortierung oder Begrenzung der Vorhersagen.
Euler-Bernoulli beschreibt hier nur Biegung: Rangvergleich ist keine Modenidentifikation oder vollstaendige 3D-Referenz.
Historische Praesentationsmodelle: Einzelmodell Seed 42 und Ensemble aus drei Netzen getrennt in historical_comparison.csv.
POD-Fehlerzerlegung verwendet die quadrierte euklidische Hz-Norm, nicht den relativen Auswahlfehler.

Auswertungen: 10 erfolgreich, 0 fehlgeschlagen.
Train/Val/Test: 16/4/4. Benchmark vorhanden: 1.

Ergebnisse: run_results.csv, mode_results.csv, case_results.csv, pod_diagnostics.csv und figures/.
Suchkosten und Fehlversuche: search_costs.csv, search_attempts.csv. GPR-Zeitwiederholungen: gpr_timing_repeats.csv.
Benchmark: neue serielle FEM-Zeiten gegen predictModel inklusive Transformation und Rekonstruktion; getrennte Ladezeit.
Break-even setzt vorhandene Trainingsdaten voraus; Offlinekosten = Hauptfit, optional Suche. Keine allgemeine Wirtschaftlichkeitsaussage.
