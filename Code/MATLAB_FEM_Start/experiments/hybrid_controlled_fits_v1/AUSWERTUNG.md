# Kontrollierte GPR-Untersuchung: Ergebnisse und Abnahmestand

Die Kandidaten und die Auswahl anhand der Trainings-Log-Likelihood wurden vorab in PROTOKOLL.md festgelegt. Alle neuen Fits verwenden ausschließlich Training 1–12 und 25–30 sowie interne Validierung 31–36. Die historischen Testfälle 19–24 wurden nicht geladen. Sie waren zuvor bereits untersucht und sind keine unabhängige Bestätigung. MATLAB R2025b Update 1; Seed 42; Batchgröße sechs; ursprüngliche Auswahl und Modelle bleiben erhalten.

Die Kontrollwiederholung des direkten Modells reproduzierte die zuvor eingefrorenen Validierungsvorhersagen exakt. Die historische Initialisierung war nicht vollständig protokolliert. Der Versuch mit train-only gewichteter POD und ARD-Squared-Exponential verwendet Rang 2 direkt und Rang 4 hybrid. Drei Starts pro Gruppe wurden nach Summe der Trainings-Log-Likelihoods gewählt; nachfolgende Validierungswerte dienen der Entwicklungsdiagnose.

| Modell / Variante | Mittlerer relativer Validierungsfehler | Mittlerer Projektionsfehler |
|---|---:|---:|
| Balken ohne Korrektur | 0,5215 % | nicht anwendbar |
| Direkt, Kontrollwiederholung | 113,834 % | 0,0654 % |
| Direkt, festes Sigma, beste Trainings-Log-Likelihood | 113,835 % | 0,0654 % |
| Direkt, lernbares Sigma, beste Trainings-Log-Likelihood | 113,808 % | 0,0654 % |
| Direkt, F/E-normalisiert, eigener POD-Raum | 10,687 % | 0,0488 % |
| Hybrid, Kontrollwiederholung | 0,8544 % | 0,01185 % |
| Hybrid, festes Sigma, beste Trainings-Log-Likelihood | 0,8544 % | 0,01185 % |
| Hybrid, lernbares Sigma, beste Trainings-Log-Likelihood | 0,8544 % | 0,01185 % |
| Hybrid, F/E-normalisiert, eigener POD-Raum | 0,1289 % | 0,00443 % |

Die F/E-Normierung nutzt s=(F/(-500 N))*(10^11 Pa/E), teilt Trainingsfelder beziehungsweise Differenzfelder durch s und multipliziert die Vorhersage wieder damit. Sie ist dimensionslos, auf den vorliegenden Lastbereich mit F<0 und E>0 beschränkt und beruht auf linearer Elastizität bei gleicher Lastform und festgehaltenen übrigen Parametern. Das geänderte Ergebnis umfasst sowohl eine neue POD-Basis als auch GPR-Training; es isoliert keine einzelne Ursache. Die wiederholt für Entwicklung verwendete Validierung belegt keine unabhängige Generalisierung. Der rein physikalische Balken gewann die ursprünglich eingefrorene Auswahl; das normalisierte Hybridmodell zeigt auf derselben internen Validierung einen kleineren Mittelwert, ist aber eine spätere Entwicklungsvariante und kein nachträglicher Gewinner des eingefrorenen Protokolls.

Alle drei Starts mit lernbarem Sigma erzeugten pro Koeffizient MATLAB-Warnungen: das Anfangs-Sigma 1e-4 liegt weniger als 0,001 über der Untergrenze, und MATLAB hebt den Startwert automatisch an. Die erfasste Warnung steht in den fitInfo-Strukturen. Ein fehlendes historisches Optimierungsprotokoll darf nicht als unauffällig ausgegeben werden. Andere Starts und lernbares Sigma bringen für den direkten Validierungsmittelwert bei dieser begrenzten Konfiguration keine praktische Verbesserung; dies beweist keine eindeutige Ursache.

Die manuelle Rückskalierung und GPR-Auswertung der ursprünglichen Fits stimmen bis auf Rundung; analysis_v2.mat ist maßgeblich. Die Kernelkorrelationen der früheren Datei analysis.mat sind wegen eines korrigierten Fehlers in der Diagnose ungültig, die ursprünglichen Modelle waren davon nicht betroffen. Wenige Fälle, Hyperparameterschätzung und Abdeckung bleiben mögliche, nicht isoliert belegte Ursachen.

fit_summary.csv enthält Training, Validierung, Projektion, Trainings-Log-Likelihood und Fitzeiten. validation_cases.csv enthält Fallwerte, absolute gewichtete Komponenten-RMS, Spitzen- und rohe Randfehler. Die MAT-Fitdateien enthalten Koeffizienten, Basis, Modelle, Parameter, Warnungen, IDs und Felder. GPR-Zeiten in summary.mat sind fünf Wiederholungen nach einem Warm-up, jeweils Batch sechs, ausschließlich Regression; sie sind keine gesamten Onlinezeiten. Grafiken validation_candidates.pdf, pod_compression.pdf und field_cases.pdf zeigen die Entwicklungsvalidierung. Die Regeneration dieser Grafiken trainiert kein Modell und führt keine FEM aus.

Abnahme: Die gespeicherten normalisierten Modelle liefern nach Laden identische Vorhersagefelder (maximal 0 m). Ungültiges Schema, abweichender Raum, F=0 und E=0 wurden abgewiesen. Eine gezielte Unterbrechung und Wiederaufnahme von zwei Kontroll-Fits gelang. Näheres und Grenzen stehen in ABNAHME.md.
