# Vorab festgelegte ergänzende Berichtsauswertung

Das Skript `analysis_static_gpr.py` wird vor dem Test-Freeze bereitgestellt und
mit dem Freeze-Manifest gehasht. Es verändert keine Modelle, Konfigurationen,
Auswahlregeln oder ursprünglichen Ergebnistabellen. Es prüft das Manifest,
erzeugt eine separate Zusammenfassung der vorab geforderten Feld- und
POD-Fehler sowie eine Berichtsversion und dokumentiert die Prüfsummen seiner
Eingaben und Ausgaben. Bei nur einem Lauf bleibt die Laufstreuung undefiniert;
die ursprüngliche MATLAB-Tabelle bleibt erhalten.
