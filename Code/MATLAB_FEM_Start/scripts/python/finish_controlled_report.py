from pathlib import Path

root = Path(__file__).resolve().parent
out = root / 'experiments/hybrid_controlled_fits_v1'
analysis = out / 'AUSWERTUNG.md'
text = analysis.read_text(encoding='utf-8')
text = text[:text.index('Abnahme:')] + 'Abnahme: Die gespeicherten normalisierten Modelle liefern nach Laden identische Vorhersagefelder (maximal 0 m). Ungültiges Schema, abweichender Raum, F=0 und E=0 wurden abgewiesen. Eine gezielte Unterbrechung und Wiederaufnahme von zwei Kontroll-Fits gelang. Näheres und Grenzen stehen in ABNAHME.md.\n'
analysis.write_text(text, encoding='utf-8')
matrix = '''# Technische Abnahme der kontrollierten statischen Untersuchung

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
'''
(out / 'ABNAHME.md').write_text(matrix, encoding='utf-8')
old = (root / 'experiments/architecture_phase1_v1/GESAMTBERICHT_TESTLAEUFE.md').read_text(encoding='utf-8')
diagram = '''
## Aufbau des Untersuchungsablaufs

Parameter und Fall-IDs → FEM-Referenz / Balkenmodell → Trainingsfälle: POD und Regression → eingefrorenes Modell → interne Validierung und Fehler.

Das beschreibt den Entwicklungsablauf; es ist keine unabhängige Teststudie. Die neuen Fits verwenden keine historischen Testfälle.
'''
closing = '''
## Abschließende Antworten

Die kleinen POD-Projektionsfehler, die geprüfte Koeffizienten-Rückskalierung und die reproduzierte manuelle GPR-Auswertung schließen diese Stellen als alleinige pauschale Erklärung der großen Fehler aus. Die korrigierte Analyse belegt keine durchgängig verschwindenden Kernelkorrelationen. Eine eindeutige Ursache der schlechten Generalisierung bleibt offen.

Die nach Trainings-Log-Likelihood ausgewählten anderen Startwerte und lernbares Sigma verbessern den Validierungsmittelwert praktisch nicht. Die neue physikalische Normierung senkt ihn auf 10,687 % beim direkten und 0,1289 % beim hybriden Modell; gegenüber 0,5215 % beim reinen Balken ist der Hybrid auf der wiederholt genutzten Entwicklungsvalidierung besser. Zugleich ändern sich POD-Basis und Regression, sodass der einzelne Wirkmechanismus offen bleibt.

Zur unabhängigen Bewertung sind neue, bislang weder für Training noch Entwicklung betrachtete Parameterkombinationen mit FEM-Referenzen erforderlich. Ein einzelner Seed und sechs interne Validierungsfälle erlauben keine Aussage über statistische Robustheit.

Reproduktion aus dem Projektordner mit MATLAB R2025b: addpath(pwd,'src'); run_controlled_gpr_fits; export_controlled_metrics; run_controlled_acceptance; summarize_controlled_gpr; plot_controlled_fields. run_controlled_gpr_fits verwendet vorhandene Checkpoints wieder; seine Wiederaufnahme prüft ihre Herkunft und Integrität nicht. Berichtsbau: python build_controlled_report.py, anschließend zweimal lualatex -interaction=nonstopmode -halt-on-error -no-shell-escape gesamtbericht.tex im Ergebnisordner.
'''
(out / 'GESAMTBERICHT.md').write_text(old + '\n' + diagram + '\n' + text + '\n' + matrix + '\n' + closing, encoding='utf-8')
