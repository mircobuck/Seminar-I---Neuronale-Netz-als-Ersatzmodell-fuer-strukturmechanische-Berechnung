# Technischer Nachtrag 04: Umfang des Vorabpiloten

Der vor dem Freeze gespeicherte Pilot pruefte Vorhersageschnittstellen,
gemeinsame Darstellung, trainierte Skalierungen, Nullfehler und logarithmische
Ruecktransformation sowie das unveraenderte erneute Laden der Modellartefakte.
Er fuehrte jedoch keine explizite separate Probelauf-Messung der siebenfachen
Vorhersagezeit aus. Die zeitmessende Schleife und ihre Auswertungsregel waren
vor den Holdout-Labels eingefroren; die gespeicherten Messwerte werden nach der
Ausfuehrung auf Vollstaendigkeit und positive Endlichkeit geprueft. Damit ist
die geforderte zeitliche Pilotpruefung vor Labelerzeugung nicht vollstaendig
nachgewiesen. Keine Modelle, Designs oder Metriken wurden nach Labelzugriff
geaendert und der Freeze wurde nicht ersetzt.
