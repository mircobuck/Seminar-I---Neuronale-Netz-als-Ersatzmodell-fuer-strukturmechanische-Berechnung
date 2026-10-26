# Hybridmodell: Zwischenstand

Implementiert: Euler-Bernoulli-Feld auf dem normierten Abfragegitter und statisches Korrekturmodell mit gewichteter POD und Matérn-5/2-GPR. Die Balkenachse liegt bei y=0 und z=h/2; u_y=0 ist eine Modellannahme, ebenso werden Schub- und Querschnittsverformungen nicht dargestellt. Vorhersagen speichern das rohe Feld und das nachträglich an der Einspannung auf null gesetzte Feld getrennt.

Training: IDs 1–12 und 25–30; interne Validierung: IDs 31–36; Rangwahl über mittleren relativen Feldfehler auf Validierung aus [1,2,4,8,12], gewählter Rang 4. Der GPR-Kernel war fest Matérn-5/2; eine Auswahl zwischen Regressionskonfigurationen wurde noch nicht implementiert.

Tatsächlich gemessen: mittlerer Validierungsfeldfehler 0,91 % hybrid gegenüber 0,52 % für das reine Balkenfeld. Auf den bereits historisch betrachteten Testfällen 19–24: Median 0,17 % hybrid gegenüber 0,46 % Balkenfeld. Diese explorativen Werte sind keine unabhängige Bestätigung. Ein direkter POD-GPR mit Rang 4 wurde auf der internen Validierung probeweise berechnet, jedoch noch nicht über alle Ränge ausgewählt; ein fairer vollständiger Vergleich steht aus.

Geprüft wurden Balkenspitze, Einspannung und gleichzeitige F-/E-Skalierung sowie Laden des gespeicherten statischen Modells. Das modale Balkenmodell, Modal-GPR, Modalzuordnung, der vollständige Metrik- und Laufzeitvergleich und der LaTeX-Bericht sind noch nicht implementiert.
