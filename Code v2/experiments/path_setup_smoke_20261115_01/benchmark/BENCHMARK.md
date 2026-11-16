# Bedingter FEM-/Surrogatbenchmark

Neue serielle Messungen, ein Warm-up, vorab konfigurierte Fallpositionen und Wiederholungen.
FEM: vollstaendiger solve_case inklusive Netz, Loesung, Interpolation und Spitzenpruefung.
Surrogat: oeffentliches predictModel inklusive Transformation und POD-Rekonstruktion.
Einzelfall: Median der fallweisen Mediane. Batch-FEM: Summe der fallweisen Mediane.
Break-even: ceil(Offlinekosten/(FEMzeit-Surrogatzeit)); nur positiver Nenner.
Offlinekosten sind neue Fit-Zeit des Hauptmodells, optional neue aeussere Familiensuche.
Vorhandene Referenzdaten werden als verfuegbar angenommen; historische Erzeugungskosten sind separat.
Laden/Speichern, Qualitaetssicherung, Wiederholungsstudien und kuenftige Updates sind nicht in diesen Szenarien enthalten.
Keine allgemeine Wirtschaftlichkeit oder Genauigkeitsgarantie; keine neue Modellauswahl.
