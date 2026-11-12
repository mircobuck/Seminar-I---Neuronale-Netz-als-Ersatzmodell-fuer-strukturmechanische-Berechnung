# Protokoll der Struktur-Wiederholung

Fachliche Grundlage: studies/static_gpr_v1/PROTOKOLL_v1.md und study_config.json, Hauptstudie static_gpr_main_v1_20261111_run2, wissenschaftliche Ergaenzung static_gpr_supplement_v1_20261112. Neue Referenzunabhaengigkeit wird nicht behauptet. Bereits bekannte Testergebnisse werden nicht zur Anpassung von Methoden oder Auswahlregeln eingesetzt.

## Unveraenderte Untersuchung

Sechs Eingaben, 1575 Verschiebungen; MLP, RBF, POD-MLP, POD-GPR. Trainingsgroessen 48/96/192/384/768. Drei blockausgeglichene verschachtelte Auswahlen, beim Vollpool eine eindeutige Auswahl. Neuronale Initialisierungen 42/43/44 beim Vollpool und bei der Bestaetigung. Auswahl bei N=384: mittlerer gewichteter relativer Validierungsfeldfehler, Gleichstand P95 und Kandidaten-ID. Top zwei neuronale Kandidaten werden mit drei Seeds bestaetigt. Exakt die bisherigen 76 Kandidaten in gleicher Reihenfolge: 16 MLP, 24 RBF, 12 POD-MLP, 24 POD-GPR. Zeitbudget je Familie 5400 s (erste Stufe 60 Prozent). Keine neuen Suchraeume.

Kontrollierte POD-Raenge 2/10/15 mit gemeinsamem trainingsbasiertem POD-Zustand je Auswahl und Rang. Parameterverteilung bei N=192 aus der festgelegten N=384-Auswahl, gleiche Randanker und Blockquoten. Originale Losses, Normalisierung, Trainingsdefaults, Zufallsfolgen und FEM bleiben erhalten.

Validierung 128, Interpolation 256, Extrapolation 128. Extrapolation genau eine Parameterseite 5-10 Prozent ausserhalb der Intervallbreite. Bestehende gepruefte Referenzen bleiben unveraendert und werden ueber eigene neue Manifeste gebunden. Der neue Lauf dokumentiert die technische Auswertekorrektur vor seinem eigenen Freeze.

## Kennzahlen und Streuung

Gewichteter relativer L2-Feldfehler pro Fall. Mittelwert, Median, Nearest-Rank-P95, Maximum. Undefinierte relative Fehler bleiben NaN und werden gezaehlt; nichtendliche ungueltige Ausgaben werden abgelehnt. Keine kuenstlichen Nullfehler. Die Auswahl erfordert vollstaendig definierte Validierungsfehler.

Zuerst Kennzahlen ueber Balkenfaelle je Lauf, danach Zusammenfassung ueber Trainingsauswahlen oder Initialisierungen. Bei N=768 sind neuronale Seeds Initialisierungsstreuung; die drei GPR-Fits derselben Konfiguration sind deterministische Zeitwiederholungen und keine zusaetzlichen unabh?ngigen Modelle. Das groesste beobachtete Maximum bleibt vom Mittel der Maxima unterscheidbar.

## Zeitmessung

Serielle CPU-Ausfuehrung. Oeffentlicher fitModel-Aufruf vollstaendig gemessen; Modellbericht enthaelt Segmentzeiten. Modellladen und Speichern getrennt. Aeussere Suchzeit einschliesslich Verwaltung und Fehlversuchen. Oeffentliche Vorhersage inklusive Transformation und POD-Rekonstruktion nach Warm-up: 30 Wiederholungen, einzeln und Batch 128. Historische Datenerzeugungszeiten bleiben als historische Angaben gekennzeichnet.

Begrenzter neuer FEM-Benchmark: Interpolationspositionen 1,24,47,70,93,116,139,162,185,208,231,254, ein FEM-Warm-up, zwei Wiederholungen pro Fall mit umgekehrter Reihenfolge. Je Surrogat Seed 42, Warm-up, 30 Einzel- und 12er-Batch-Aufrufe. Fallweise Mediane, danach Median/IQR zwischen Faellen. FEM-Batchkosten sind die Summe fallweiser Mediane. Bedingter Break-even mit positivem Nenner, neuen Fit- und optional Suchzeiten, vorhandenen Daten als verfuegbare Ressource. Keine allgemeine Wirtschaftlichkeitsbehauptung.

## Absicherung und Wiederaufnahme

Git-Commit und SHA-256-Manifeste identifizieren neuen Quellstand, Konfiguration, Referenzen und Modelle. Vollstaendige Pruefung vor/nach jeder Phase; erneut vor Testzugriff. Einzelne Fits pruefen ihre Konfiguration, Fall-IDs, Datenfingerprints und Modellhash. Training/Validierung bleiben getrennt. Erzeugung und Training nach Freeze sind gesperrt. Alte Manifeste werden nicht umgeschrieben. Keine pauschale Abschaltung von Pruefungen.

Optionales Gesamtbudget startet mit dem neuen Lauf; kein historischer Budgetzeitpunkt. Ohne Gesamtbudget bleibt die Studie checkpointbasiert unterbrechbar. Das fachliche Suchbudget bleibt unveraendert.
