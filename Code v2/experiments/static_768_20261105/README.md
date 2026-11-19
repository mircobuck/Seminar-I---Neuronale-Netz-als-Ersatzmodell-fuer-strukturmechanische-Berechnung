# Erweiterung der statischen Trainingsmenge auf 768 Faelle

Beauftragt und gestartet am 5. November 2026.

`scripts/matlab/extend_static_training_768.m` ergaenzt 384 statische
FEM-Trainingsfaelle im vorhandenen Ordner `data_generation/data/static`.
Die urspruenglichen 384 Trainingsfaelle werden unveraendert uebernommen.
`backup_384` sichert den bisherigen Trainingssplit und das Design.
Die neuen Parameter stammen aus einem separaten Latin Hypercube mit Seed
20261105 innerhalb derselben Parametergrenzen. Das kombinierte Design
ist daher kein neu erzeugter Latin Hypercube mit 768 Punkten.

Validierungs-, Test- und Modaldaten werden nicht geaendert. Der Lauf verwendet
nur die bestehenden zwoelf statischen Validierungsfaelle. Er erzeugt und
verwendet keine neuen Testlabels. `unchanged_data_hashes.csv` dokumentiert
die SHA-256-Pruefsummen dieser Datendateien vor dem Start.

`examples/runStatic768Study.m` fuehrt nach der FEM-Erweiterung ausschliesslich
die neue Stufe mit 768 Trainingsfaellen aus: Breiten 64/128, versteckte
Schichten 1 bis 6, Seeds 42/43/44, also 36 Trainingslaeufe. Die bisherigen
200 Epochen, Adam-Einstellungen und der POD-Rang 10 bleiben erhalten.
Der Batchlauf exportiert keine Lernkurvendiagramme.
Die Reihenfolge der ersten 384 Trainingsfaelle je Seed entspricht der
historischen Permutation; die neuen Faelle werden dahinter angehaengt.
Fruehere gespeicherte Modelle und Auswertungen werden nicht ueberschrieben.

Start beziehungsweise Wiederaufnahme aus `Code v2`:

```matlab
addpath('examples')
runStatic768Study(fullfile(pwd,'experiments','static_768_20261105'))
```

`STATUS.txt`, `run.log` und `matlab_batch.log` zeigen den Fortschritt.
`ERROR.txt` wird bei einem Fehler geschrieben. Einzelne neue FEM-Faelle
werden sofort im bestehenden `static/cases` gespeichert und bei einer
Wiederaufnahme geprueft und wiederverwendet. Erst nach allen 384 neuen
FEM-Faellen werden `static/design.csv` und `static/train.mat` aktualisiert.
Die Ergebnisse der Netztrainings stehen in den Architektur-Unterordnern
und in `summary_768.csv`, einschließlich mittlerem absolutem Fehler,
Median und P95.
`comparison_384_768.csv` vergleicht je Architektur die Medianwerte der drei
Seeds für die Trainingsgrößen 384 und 768.

Die urspruengliche `data_generation_v1.json` und die damaligen
Provenienzdateien bleiben als Beschreibung des urspruenglichen Designs
erhalten. `static/training_extension_768.json` dokumentiert die Erweiterung.
Der urspruengliche Generator verweigert bewusst ein abweichendes Design;
zur Wiederaufnahme dieser Erweiterung den oben genannten Runner verwenden.

## Stand der POD-MLP-Läufe

Die vorgesehenen Lernkurven fuer 12, 24, 48, 96, 192, 384 und 768
Trainingsfaelle sind abgeschlossen: Breiten 64/128, ein bis sechs versteckte
Schichten und Seeds 42/43/44. Die 384er- und 768er-Modelle wurden zudem auf
dem statischen Testsatz ausgewertet; dieser nachtraegliche Vergleich ist
deskriptiv und keine unabhaengige Testbestaetigung.

Ein zusaetzlicher Pilotlauf mit zehn versteckten Schichten und 256 Neuronen
je Schicht ist noch offen und wurde nicht gestartet. Vorgesehen ist zunaechst
ein Lauf mit 768 Trainingsfaellen, der ausschliesslich anhand der
Validierungsdaten beurteilt wird. Die Testdaten werden nicht zur
Architekturauswahl verwendet.
