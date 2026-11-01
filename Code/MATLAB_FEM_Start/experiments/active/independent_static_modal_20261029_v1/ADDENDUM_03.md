# Technischer Nachtrag 03: Werkzeug-Zeitlimit und Unterbrechung

Der modale FEM-Aufruf ueberschritt das 600-Sekunden-Zeitlimit des MATLAB-
Werkzeugs. Der zugrunde liegende MATLAB-Prozess lief nachweislich weiter und
schrieb fortlaufend neue Fallartefakte; die eingefrorenen Modelle und Designs
wurden nicht neu erzeugt. Fall 1100048 weist eine Wandzeit von rund 14.903 s
auf, zeitlich passend zur Unterbrechung der Sitzung. Diese Zeit bleibt im
Ledger, darf aber nicht als reine Solver-Rechenzeit interpretiert werden.
Kein Fall wurde deshalb ersetzt oder aus der Genauigkeitsauswertung entfernt.
