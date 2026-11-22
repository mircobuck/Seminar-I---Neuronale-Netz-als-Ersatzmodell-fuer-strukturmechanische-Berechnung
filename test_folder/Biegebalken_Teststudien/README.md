# Biegebalken-Teststudien

Start in MATLAB:

```matlab
run_all_beam_studies
```

Um nur bestimmte Studien auszuführen, übergib die Studiennummern. Zum Beispiel startet dieser Befehl die fünf noch offenen Studien 4 bis 8:

```matlab
run_all_beam_studies(4:8)
```

Auch einzelne oder nicht zusammenhängende Studien sind möglich, etwa `run_all_beam_studies([2 5 8])`.

Das Skript erzeugt acht Studien: konstanter Querschnitt und Querschnittssprung, jeweils mit einer und zwei versteckten Tanh-Schichten sowie 80 und 160 Trainingsfällen. Es verwendet fünf feste Seeds, trennt Training, Validierung, Interpolation und Extrapolation auf Ebene vollständiger Balkenfälle und speichert alle Ergebnisse in `results/run_...`.

Die Vollstudie führt 1.420 Trainingsläufe aus. Jede Studie exportiert `main_plot`, `loss`, bei zwei Layern zusätzlich `architecture_heatmaps`, jeweils als PNG, PDF und FIG. CSV- und MAT-Dateien enthalten die Kennzahlen und Rohdaten.

Die Kraft ist nicht Netzeingang. Das Netz lernt `w/F` als Funktion von Position und Geometrie; anschließend wird mit der Kraft skaliert. Dadurch bleibt die bekannte Linearität der Euler-Bernoulli-Lösung erhalten.
