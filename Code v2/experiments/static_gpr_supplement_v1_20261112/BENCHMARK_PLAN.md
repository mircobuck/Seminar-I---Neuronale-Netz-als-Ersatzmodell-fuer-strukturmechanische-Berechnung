# Separater FEM-/Surrogatbenchmark v1

Vor Messbeginn festgelegt. Zwölf Interpolationsfälle an den 1-basierten Positionen 1, 24, 47, 70, 93, 116, 139, 162, 185, 208, 231 und 254 der gespeicherten Reihenfolge; keine Auswahl nach Modellfehler. Dieselben Eingaben für alle Methoden. Originale eingefrorene Vollpoolmodelle, Seed 42 bei neuronalen Modellen.

Serielle Messung auf derselben Maschine in einer MATLAB-Sitzung ohne andere Studienjobs. Ein separater FEM-Warm-up am ersten ausgewählten Fall; danach zwei vollständige FEM-Durchläufe pro Fall in wechselnder Reihenfolge. `solve_case` umfasst Geometrie, Netz, Lösung, Interpolation aller 525 Punkte und zusätzlich Spitzenabfrage und Prüfungen; kein Dateizugriff im Messintervall. FEM-Fälle werden einzeln gelöst, keine FEM-Batchoptimierung.

Modelle vor der Messung einmal laden; Laden separat erfassen. Je Methode ein Warm-up für Einzelfall und 12er-Batch, danach 30 Aufrufe je Fall und 30 für denselben 12er-Batch. Öffentlicher `predictModel`-Aufruf einschließlich Transformation, Rekonstruktion und Ausgabeprüfung; Dateizugriffe ausgeschlossen. Zur Vergleichbarkeit der Einzelfall-Szenarien wird der Median aller zwölf fallweisen Mediane verwendet. FEM-Batchkosten sind die Summe der zwölf fallweisen Mediane; das ist ein serielles Szenario, keine Messung eines FEM-Batchsolvers.

Alle Rohzeiten, Fall-IDs, Parameter, Umgebung und Modellpfade in separaten Dateien speichern. Kein erneutes Training, keine Auswahl anhand der Testfehler. Zeitliche Streuung und Reihenfolgeeffekte bleiben bei dieser kleinen Messung begrenzt erfassbar. Benchmark und alle Folgerechnungen sind nachträglich und keine Modellvalidierung.
