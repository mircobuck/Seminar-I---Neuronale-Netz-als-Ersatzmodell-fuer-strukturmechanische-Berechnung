# GPR-Ursachenanalyse v1

Nur Training IDs 1–12 und 25–30 und interne Validierung IDs 31–36; historische Testfälle werden nicht für Entscheidungen verwendet. Bestehende eingefrorene Modelle und Diagnosen bleiben unverändert.

Vorab festgelegte Hypothesen: (1) falsche Rückskalierung oder Vertauschung der Koeffizienten, (2) unzureichende gemeinsame Abdeckung im standardisierten Parameterraum, (3) kleine Kernelkorrelation beziehungsweise ungewöhnliche Kernelgewichte, (4) begrenzte Generalisierung trotz niedrigen Trainingsfehlers. Prüfungen: manuelle Rekonstruktion gegen gespeicherte Funktionen; Skalierungsmittel und -streuung gegen trainierte POD-Koeffizienten; Test mit bekannten Koeffizienten; Vergleich von marginalen Bereichsüberschreitungen und nächsten Nachbarn; ARD-Kernelkorrelation und Rekonstruktion des prädiktiven Mittels. Optimierungswarnungen des historischen Fits sind nicht verfügbar und werden nicht erfunden.

Es werden zunächst keine neuen Fits ausgeführt. Wenn diese Analysen die Ursache nicht ausreichend klären, bleibt sie ausdrücklich offen. Keine Modellwahl auf historischen Testfällen.
