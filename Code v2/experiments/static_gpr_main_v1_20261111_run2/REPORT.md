# Statischer Vier-Methoden-Vergleich

Test-Freeze vor Auswertung geprueft. Details: run_results.csv und case_results.csv.

Technische Auswertekorrektur nach dem urspruenglichen Freeze: siehe evaluation_repair_v1/PROTOKOLL_NACHTRAG.md. Modelle und Auswahl blieben unveraendert.

Erfolgreiche Lauf/Split-Auswertungen: 288; fehlgeschlagene: 0.

Gewichtete relative Fehler sind Fallgroessen; Wiederholungen sind keine zusaetzlichen unabhaengigen Faelle. Interpolation und Extrapolation bleiben getrennt.

Genauigkeitsorientierter Ausgangspunkt (Interpolation, N=768): pod_gpr; mittlerer relativer Fehler 0.00549055, mediane Fit-Zeit 353.6 s und mediane Einzelfall-Vorhersage 0.007036 s. Diese Auswahl ist eine Beschreibung dieses begrenzten Vergleichs; Extrapolation, Streuung und Datenkosten in pipeline_summary.csv mitbeurteilen.

Kein Break-even wurde angegeben, da kein zeitgleich kontrollierter FEM-Vergleich vorliegt.

TipError ist die vorzeichenbehaftete Abweichung von uz am Punkt (1,0.5,0.5); MaxMagnitudeError ist die vorzeichenbehaftete Differenz der Maximalbetraege. Absolute Varianten stehen zusaetzlich in case_results.csv.

Die vollstaendigen Modell- und Datenkosten, Suchhistorie und Fehlversuche sind in den zugehoerigen Checkpoints und Tabellen dokumentiert. Analytische Balkenloesungen sind keine exakte 3D-Feldreferenz.
