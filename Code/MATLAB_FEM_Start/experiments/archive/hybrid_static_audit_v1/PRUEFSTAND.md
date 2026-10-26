# Statischer Hybridvergleich: Zwischenstand

Training IDs 1–12 und 25–30, interne Validierung 31–36, historisch betrachteter explorativer Test 19–24. Die Splits wurden auf Überschneidungen und identische physikalische Parameterzeilen geprüft. Die Validierungsfälle gehören zum historischen Trainingsbestand und sind keine unabhängige Bestätigung.

Vor der Testauswertung festgelegt: Für beide POD-Ansätze Ränge 1, 2, 4, 8, 12 und Kernel ARD-Matérn-5/2 und ARD-Squared-Exponential; Auswahl anhand mittleren relativen gewichteten Validierungsfeldfehlers. Das Balkenfeld ist ein weiterer Kandidat. protocol.mat und selection.mat enthalten Protokoll, gefrorene Kandidaten, Validierungswerte und GPR-Fitzeiten.

Validierung: Balken 0,5215 %, bestes direktes POD-GPR 113,834 %, bestes hybrides POD-GPR 0,8544 %. Die Auswahl bevorzugt das Balkenfeld. Der direkte Kandidat hat Rang 2, der hybride Rang 4; beide verwenden Squared-Exponential. Die großen Unterschiede müssen weiter untersucht werden.

Historisch betrachteter Test nach eingefrorener Auswahl: Median Balken 0,4626 %, direktes POD-GPR 32,2441 %, Hybrid 0,1785 %. Hybrid ist bei IDs 19 und 23 schlechter als das Balkenfeld; für ID 23 beträgt der Fehler 2,3117 % gegenüber 1,0641 %. Diese Fälle wurden bereits früher betrachtet und dürfen nicht zur nachträglichen Modellwahl verwendet werden.

Diagnostische Projektion der tatsächlichen Test-Differenzfelder auf die Trainings-POD: Median relativer Gesamtfeldfehler 0,00797 %. Der größere Vorhersagefehler deutet hier auf einen relevanten Regressionsanteil hin; wahre Projektionskoeffizienten dienen ausschließlich der Diagnose. Relative Fehler sind nicht additiv. Einzelwerte und die gewichtete absolute Differenz zwischen Vorhersage und Projektion in Metern stehen in exploratory_test.mat.

Getrennte Balkenprüfungen: Verdoppelung der Kraft, Verdoppelung von E und Lastvorzeichenwechsel; Absoluttoleranz 1e-14, alle bestanden. Die frühere kombinierte F/E-Prüfung ersetzt diese Tests nicht.

Offen: vollständige Komponenten-, Spitzen- und Randmetriken auf allen Splits, Komprimierungskurven, Feldbilder, wiederholte Laufzeitmessungen, Speichern/Laden und gezielte Unterbrechung dieser neuen Kandidaten, Abnahmematrix, umfassender Bericht und Modalmodell. Die Warnung der Modalübertragung ist vor dessen Umsetzung zu klären. Das bestehende Modell aus hybrid_beam_phase1_v1 wurde nicht überschrieben.
