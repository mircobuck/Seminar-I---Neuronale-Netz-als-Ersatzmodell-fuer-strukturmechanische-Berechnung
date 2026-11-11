# Ergebnis der erneuten L2-Auswertung

Stand: 11. November 2026. Alle Werte unten stammen aus neu berechneten
Vorhersagen gespeicherter POD-MLP-Modelle auf denselben 128 bereits verwendeten
Validierungsfällen, mit 768 Trainingsfällen und drei Seeds (42/43/44).

## Beste Konfiguration je Untersuchung

Auswahl nach dem kleinsten über die drei Seeds gemittelten mittleren relativen
gewichteten L2-Fallfehler. Median, Mittelwert und P95 sind ebenfalls jeweils
über die drei Seeds gemittelt. **Maximum** bezeichnet in dieser Tabelle den
größten tatsächlich beobachteten Fallfehler über alle drei Seeds.

| Untersuchung | Beste untersuchte Einstellung | Median | Mittelwert | P95 | Maximum |
|---|---|---:|---:|---:|---:|
| Architektur/Loss | Breite 64, 3 versteckte Schichten, POD-Rang 10, gewichtete Feld-MSE | 2,34 % | 4,04 % | 12,27 % | 53,97 % |
| Optimierer | Adam, Breite 128, 2 versteckte Schichten, POD-Rang 10 | 1,97 % | 4,30 % | 16,06 % | 62,03 % |
| Lernrate | 0,001 mit Adam, Breite 128, 2 versteckte Schichten, POD-Rang 10 | 1,97 % | 4,30 % | 16,06 % | 62,03 % |
| Netzbreite | 80 Neuronen, 2 versteckte Schichten, Adam, POD-Rang 10 | 1,87 % | 3,71 % | 15,25 % | 54,80 % |
| POD-Rang | Rang 15, Breite 64, 2 versteckte Schichten, Adam | 1,42 % | 2,92 % | 11,68 % | 34,22 % |

Alle genannten Modelle verwenden die gewichtete Feld-MSE, Lernrate 0,001,
200 Epochen und Batchgröße 32. Optimierer- und Lernratenstudie führen hier
dasselbe Adam-Kontrollmodell als beste Konfiguration auf; dies sind keine zwei
unabhängigen Bestätigungen.

## Einordnung

Die vier Kennzahlen beleuchten unterschiedliche Eigenschaften. Beispielsweise
hat die beste Architektur einen höheren Median als das Adam-Kontrollmodell
mit Breite 128, aber einen kleineren Mittelwert und P95. Die Rangfolge hängt
deshalb von der vorab festgelegten Auswahlmetrik ab. Hier bleibt der Mittelwert
die Hauptmetrik; die übrigen Kennzahlen werden gleichberechtigt berichtet.

Die unterschiedlichen Auswahlstudien sind kein vollständiges gemeinsames
Hyperparametergitter. Eine Kombination aus Breite 80, drei Schichten und
POD-Rang 15 wurde durch diese Auswertung nicht untersucht. Für eine solche
Aussage wäre ein eigener Trainingsversuch erforderlich.

Auch beim Rang-15-Modell beträgt der größte beobachtete Fallfehler noch
34,22 %. Ein guter Mittelwert allein belegt daher keine gleichmäßig hohe
Genauigkeit für alle Balkenvarianten.

Die Validierung wurde bereits mehrfach für Modellentscheidungen verwendet.
Diese Ergebnisse sind eine erneute explorative Auswertung, kein unabhängiger
Abschlusstest. Produktive Testlabels wurden für diese Neuauswertung nicht
geladen. Es wurden keine Netze neu trainiert und keine FEM-Fälle neu erzeugt.

## Umfang und Nachvollziehbarkeit

- 516 Modelleinträge aus fünf Studien, teilweise mit wiederverwendeten Kontrollen.
- 936 Modell/Validierungsdatensatz-Auswertungen und 71.088 Fallvorhersagen.
- Architektur/Loss: Breiten 64/128, 1–5 versteckte Schichten, sieben
  Trainingsgrößen (12 bis 768), zwei Losses und drei Seeds; ausgewertet auf
  den ursprünglichen 12 und den vorhandenen 128 Validierungsfällen.
- 312 Konfiguration/Datensatz-Gruppen mit jeweils drei Seeds.
- Die neu berechneten Fehler aller 516 Modelleinträge auf den 128 Fällen
  stimmen mit den archivierten Fallfehlern bis auf numerische Rundung überein;
  die größte absolute Differenz im relativen Fehler beträgt rund 4,55e-13.
- Eine unabhängige PowerShell-Prüfung bestätigt die Normierung aller 71.088
  Fallfehler, die vier Kennzahlen aller 936 Läufe und die Aggregation aller
  312 Konfiguration/Datensatz-Gruppen.

Die vollständigen Tabellen stehen in `configuration_summary.csv`,
`run_metrics.csv` und `case_errors.csv`. Der ausführliche Bericht und die
Vergleichsdiagramme liegen im selben Ordner. `MaximumPercent` in der
Konfigurations-CSV bezeichnet den **Mittelwert der drei Seed-Maxima**;
`WorstObservedMaximumPercent` entspricht dem tatsächlichen Maximum oben.
