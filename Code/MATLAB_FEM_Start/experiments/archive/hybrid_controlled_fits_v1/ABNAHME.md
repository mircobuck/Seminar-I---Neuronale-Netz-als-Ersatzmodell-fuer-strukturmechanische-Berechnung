# Technische Abnahme der kontrollierten statischen Untersuchung

| Prüfung | Kriterium / Toleranz | Ergebnis | Status und Beleg |
|---|---|---|---|
| Kontrollwiederholung direkt | gleiche Validierungsfelder; 1e-12 m | maximale Abweichung 0 m | bestanden; fit_1_1.mat, eingefrorene selection.mat |
| Laden und Vorhersagen beider Modelle | max. Feldabweichung < 1e-12 m | jeweils 0 m | bestanden; acceptance.mat, run_controlled_acceptance.m |
| Koordinatenraum | 21 × 5 × 5, Koordinatendifferenz max. 1e-12 | veränderte Koordinate abgewiesen | bestanden; acceptance.mat, controlled_predict.m |
| Schema | benötigte Felder und Status | leere Struktur abgewiesen | bestanden; run_controlled_acceptance.m; keine vollständige kryptografische Herkunftsprüfung |
| Last und Elastizitätsmodul | F < 0, E > 0 | F=0 und E=0 abgewiesen | bestanden; run_controlled_acceptance.m |
| Online-Eingaben | Modell, Parameter und Referenzkoordinaten | genau drei Argumente; keine FEM-Ziele | bestanden für controlled_predict.m; Schnittstellenprüfung, kein Ganzprogrammbeweis |
| Unterbrechung und Wiederaufnahme | erster Checkpoint unverändert, zweiter erstellt | zwei Kontroll-Fits bestanden | resume_check/resume_evidence.mat; Änderungszeit und Größe, kein Hash; defekte und fremde Checkpoints werden nicht validiert |
| Berichtsexport | vorhandene Daten und Quellen | Grafiken und PDF aus gespeicherten Artefakten erzeugt | ausgeführt; plot_controlled_fields.m, build_controlled_report.py; keine instrumentierte Aufrufüberwachung |
| GPR-Optimierungsabbruch | MATLAB stellt Verlauf bereit | API liefert hier keinen vollständigen Abbruchverlauf | offen; fitInfo je Koeffizient |

Onlinezeiten: AMD Ryzen 5 4500U, Windows PCWIN64, MATLAB R2025b Update 1, sechs Fälle je Batch, ein Warm-up und fünf Messungen. Mittelwerte in Millisekunden:

| Modell | Physik | Übertragung | GPR | Rekonstruktion | Nachbearbeitung | Gesamt |
|---|---:|---:|---:|---:|---:|---:|
| Direkt normalisiert | 0,3 | 0 | 2,0 | 0,4 | 0,5 | 4,8 |
| Hybrid normalisiert | 1,0 | 0 | 2,6 | 0,4 | 0,2 | 4,7 |

Die Übertragung ist null, weil das Balkenfeld unmittelbar an den Referenzpunkten ausgewertet wird. Gesamtzeit umfasst zusätzlich Eingabe- und Raumprüfung; kleine Zeitunterschiede sind Messrauschen. Zeiten sind Momentaufnahmen. Die tatsächlichen Messwerte stehen in acceptance.mat.

Allgemeine Produktions-Wiederaufnahme mit Integritäts- und Protokollprüfung ist nicht belegt. Es wurden keine FEM-Berechnung und keine große Lernkurve für diese Nachprüfung gestartet.
