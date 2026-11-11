# Softwarevalidierung

Stand: 11. November 2026.

Ausgeführt wurden `surrogateContractTest`, `staticComparisonTest` und
`staticFinalEvaluationTest`: 24 von 25 Prüfungen bestanden. Alle Prüfungen
der Fehlerberechnung und der Vergleichs-/Abschlusstestfunktionen bestanden.

Der bestehende Test `surrogateContractTest/productionTrainCanBeLoaded`
erwartet fest 384 statische Trainingsfälle. Tatsächlich enthält der vorhandene,
bereits erweiterte Datensatz 768 Fälle; dies ist in
`data_generation/data/static/training_extension_768.json` dokumentiert.
Der Test wurde nicht durch eine Abschwächung seiner Erwartung verändert.
Diese veraltete Fallzahlprüfung ist getrennt von den numerischen
Metrikprüfungen zu betrachten.

Die Neuauswertung prüft zusätzlich Modell-Hashes, Split-Trennung, dieselbe
Fallzuordnung, die L2-Formel, gepaarte Trainings-IDs im Loss-Vergleich und
die Übereinstimmung mit den archivierten Fallfehlern.

Die unabhängige CSV-Prüfung ist in `INDEPENDENT_CSV_VERIFICATION.txt`
dokumentiert. Der verwendete Prüfer ist
`studies/static_final_evaluation/verifyL2Export.ps1`.

Nach der letzten Änderung am Vergleichsplot wurden dessen drei bestehenden
Tests erneut ausgeführt: alle bestanden. Zusätzlich wurden der Mittelwert
und das Maximum gegen bekannte synthetische Fallfehler geprüft: bestanden.
Die Tabellen hierzu stehen in `software_tests.csv` und
`plot_tests_after_final_changes.csv`.

MATLAB Code Analyzer meldet für die zentrale Vergleichsfunktion, den neuen
Neuauswertungs-Runner und den angepassten Lernkurven-Runner keine Befunde.
In älteren Plot-/Exportfunktionen bestehen Formatierungs-, ungenutzte
Variablen- beziehungsweise Grafik-Performancehinweise. Es wurden keine
numerischen Fehler daraus beobachtet.
