# Pruefungen vor dem Hauptlauf

- `staticGprStudyTest`: 5/5 bestanden, einschliesslich fehlendem Freeze, geaendertem eingefrorenem Artefakt, geaenderter Checkpoint-Konfiguration und synthetischer Auswertung mit einer nach dem Freeze hinzugefuegten, nicht beruecksichtigten Modellkopie.
- Nach Aufnahme der Statusspalten wurde `staticGprStudyTest/frozenSyntheticPipeline` erneut ausgefuehrt: 1/1 bestanden.
- Der reale Referenz-Probelauf `static_gpr_v1_generation_pilot_v2_20261111` erzeugte zwei 1575-komponentige Validierungsfelder, durchlief die Quellenpruefung und nahm dieselben Checkpoints erfolgreich wieder auf. Diese Pilotfaelle sind kein Bestandteil der Hauptsplits.
- Ein erster Freeze-Test hatte aufgrund automatischer Trennzeichenerkennung bei Windows-Pfaden versagt; explizite CSV-Einstellungen korrigierten das Problem. Ein MATLAB-Grafiktest wurde wegen Grafik-Handshake-Timeout beendet; der synthetische Test der statischen Python-/Matplotlib-Figuren war danach erfolgreich.
- Zuvor bestanden die dokumentierten Vertrags- und Modelltests im Ordner `static_pod_gpr_20261111`. Schnittstellen- und synthetische Tests belegen keine Genauigkeit der Studienmodelle.
- Das vor dem Freeze bereitgestellte ergaenzende Auswertungsskript wurde mit synthetischen Tabellen geprueft: Freeze-Hash, undefinierte Streuung bei einem Lauf und POD-Fehlerzerlegung bestanden. Das Testfixture liegt in `static_gpr_analysis_fixture_20261111`.
