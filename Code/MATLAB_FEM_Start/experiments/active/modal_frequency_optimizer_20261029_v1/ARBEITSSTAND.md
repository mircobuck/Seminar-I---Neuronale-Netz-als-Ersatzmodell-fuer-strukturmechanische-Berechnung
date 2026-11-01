# Arbeitsstand: Frequenz-Optimierervergleich

Stand: 29.10.2026. Abgeschlossen als Entwicklungsevidenz, kein Abschlusstest.
Vorabprotokoll und Konfiguration, 384 bestehende Trainings-IDs und drei Folds
wurden vor den Fits gespeichert. Pilot bestanden; 18 MLP- und drei GPR-CV-Fits
sowie drei finale L-BFGS-MLPs auf n=384 liegen vor. Kein FEM-Neulauf und kein
historisches Holdout-Label wurde verwendet. Die trainierten MLPs erreichten
alle ihr Budget, was keine Konvergenz garantiert.

Primaermetrik der rohen Hz-Ausgaben: Adam 5.50239 %, L-BFGS 0.99786 %;
GPR-Referenz 0.60690 %. L-BFGS wurde nach vorab festgelegter Regel ausgewaehlt.
Raw und nachsortiert, Fall- und frequenzweise Metriken, Fold-/Seed-Streuung,
Ordnungsverletzungen, Historien, Kosten und Versuchstabelle sind im Bericht
`FINAL_REPORT_v2.md` und den CSV-Dateien enthalten. Vor einer unabhaengigen
Pruefung bleiben die drei finalen Fits ungetestete Modellstaende.
