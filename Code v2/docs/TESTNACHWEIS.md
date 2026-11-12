# Pruefnachweis vor der Hauptwiederholung

Stand 12.11.2026. MATLAB R2025b Update 1, serielle Ausfuehrung.

| Pruefung | Ergebnis |
|---|---|
| Bestehende Vertrags-, Modell-, Loss-, POD-, Teilmengen- und Auswertetests vor Umbau | 83/83 bestanden |
| Neue Workflow-Regression | 16/16 bestanden |
| Nach additiver Zeitinstrumentierung: Workflow, direkte Netze, POD-MLP, gewichtete direkte Loss | 55/55 bestanden |
| Gespeicherte Vollpoolmodelle aller vier Methoden: Vorhersagen und Fallfehler gegen Baseline auf 128 Validierungsfaellen | Exakt identisch |
| Alle 76 Suchkandidaten in identischer Reihenfolge und alle verschachtelten Trainingsauswahlen | Exakt identisch |
| Gemeinsame Kennzahlen gegen unabhaengige Referenzformeln; P95/undefinierte Faelle | Bestanden |
| Geaenderte Checkpointkonfiguration / geaenderte Trainingsfelder | Abgelehnt |
| Statischer FEM-Smoke: 4 Validierungs-, 4 Interpolations-, 12 Extrapolationsfaelle | Erfolgreich, keine modale FEM |
| Alle vier Methoden, N=16/32, kontrollierte POD, Verteilungszweig | 24 erfolgreiche Fits, 40 erfolgreiche Lauf/Split-Auswertungen |
| Training erneut aufrufen | Modelle byteidentisch wiederverwendet |
| Testauswertung vor Freeze und Training/Tuning nach Freeze | Abgelehnt |
| Manipuliertes eingefrorenes Metadatum | Vor Testzugriff erkannt; danach exakt wiederhergestellt |
| Bericht zweimal ohne neues Training/FEM | Bestanden, Modellhashes unveraendert |
| Begrenzter Smoke-Benchmark, Warm-up, zwei konfigurierte Faelle | Erfolgreich |

Nachweise lokal: experiments/refactor_validation_20261112/{baseline_tests,baseline_predictions,workflow_tests,final_model_workflow_tests}.mat. Erfolgreicher Integrationstest: experiments/static_comparison_smoke_20261112_attempt2/smoke_validation.complete, run_results.csv, source_manifest.csv und freeze_manifest.csv. Der erste fehlgeschlagene Versuch bleibt erhalten und ist in UMSTRUKTURIERUNG.md beschrieben.

MATLAB Code Analyzer: keine Syntaxfehler. Verbleibende Hinweise betreffen kleine wachsende Tabellen in Generierungs-/Berichts-/Benchmarkverwaltung, nicht numerische Modellrechnung. Die Grenzen sind durch konfigurierte Fall-/Laufzahlen festgelegt; eine rein kosmetische Vorallokation wurde nicht mit einer Rechenaenderung vermischt.

Rundung: Die Mittelwertbildung ueber sortierte statt urspruenglich geordnete Fehler erzeugte bei einem ersten Test Abweichungen bis 1.4e-17. Die zentrale Funktion behaelt nun die historische Tuning-Summationsreihenfolge. Vorhersagen und Fallfehler blieben dabei exakt gleich.
