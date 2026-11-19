# Statischer Vier-Methoden-Vergleich

Test-Freeze vor Auswertung geprueft. Details: run_results.csv und case_results.csv.

Wiederholung auf bereits bekannten Referenzfaellen, kein neuer unabhaengiger Abschlusstest. Gepruefte Auswertekorrektur ist vor diesem Freeze integriert.

Erfolgreiche Lauf/Split-Auswertungen: 40; fehlgeschlagene: 6.

Gewichtete relative Fehler sind Fallgroessen; Wiederholungen sind keine zusaetzlichen unabhaengigen Faelle. Interpolation und Extrapolation bleiben getrennt.

Genauigkeitsorientierter Ausgangspunkt (Interpolation, N=768): pod_gpr; mittlerer relativer Fehler 1.1702, mediane Fit-Zeit 0.302 s und mediane Einzelfall-Vorhersage 0.002108 s. Diese Auswahl ist eine Beschreibung dieses begrenzten Vergleichs; Extrapolation, Streuung und Datenkosten in pipeline_summary.csv mitbeurteilen.

Der separate kontrollierte Benchmark und bedingte Break-even stehen nach der Benchmarkphase unter benchmark/. Historische Erzeugungskosten sind keine neuen Messwerte.

TipError ist die vorzeichenbehaftete Abweichung von uz am Punkt (1,0.5,0.5); MaxMagnitudeError ist die vorzeichenbehaftete Differenz der Maximalbetraege. Absolute Varianten stehen zusaetzlich in case_results.csv.

Die vollstaendigen Modell- und Datenkosten, Suchhistorie und Fehlversuche sind in den zugehoerigen Checkpoints und Tabellen dokumentiert. Analytische Balkenloesungen sind keine exakte 3D-Feldreferenz.
