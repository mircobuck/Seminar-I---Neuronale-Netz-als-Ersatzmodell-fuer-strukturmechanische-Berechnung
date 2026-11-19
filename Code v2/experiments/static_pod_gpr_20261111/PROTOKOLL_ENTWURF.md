# Studienprotokoll ? Entwurf, nicht eingefroren

Gegenstand sind vollst?ndige statische 3D-FEM-Verschiebungsfelder in Metern. Modalgr??en sind ausgeschlossen. Der Studienablauf ist noch nicht fertig implementiert; dieses Dokument und `study_config.json` sind kein g?ltiger Modell- oder Test-Freeze.

## Entwurf der Aufteilung

Der bestehende Trainingspool hat zwei Bl?cke zu je 384 F?llen. Vorgesehen sind verschachtelte blockausgeglichene Mengen von 48, 96, 192, 384 und 768 F?llen mit drei Auswahlen. Bei 768 sind alle Auswahlen identisch. Geplant sind 128 neue Validierungs-, 256 neue Interpolations- und 128 neue Extrapolationsf?lle. Letztere variieren jeweils einen Parameter 5?10 % der Intervallbreite au?erhalb des Trainingsintervalls.

Historische Test- und Validierungsdaten sind kein neuer unabh?ngiger Abschlusstest. Designs sind auf ?bereinstimmung der normierten Parametervektoren mit Toleranz 1e-10 zu pr?fen. Wiederholungen, Ersatzregeln, Datensatz- und Quelldatei-Hashes sind vor Studienstart verbindlich festzulegen und zu pr?fen.

## Vergleich und Auswahl

Direktes MLP, feste RBF-Variante, POD?MLP und POD?GPR sind auf denselben F?llen anhand des mittleren gewichteten relativen Feldfehlers auf der neuen Validierung zu w?hlen. Neuronale Kandidaten verwenden Adam, 200 Epochen, Lernrate 0,001 und Batch 32. GPR verwendet exakte Anpassung, ARD-Squared-Exponential oder ARD-Mat?rn-5/2, konstante oder lineare Mittelwertfunktion und konstantes numerisches Sigma 1e-4 oder 1e-3 im skalierten Koeffizientenraum. Das Sigma ist keine Aussage ?ber physikalisches Rauschen.

Bei POD?MLP und POD?GPR m?ssen f?r den kontrollierten Vergleich F?lle, gewichtete Basis, Mittelwert und Rang identisch sein. R?nge 2, 10 und 15 sind nur bei ausreichendem numerischem Rang zul?ssig. Die Abweichung der unterschiedlichen Trainingsziele ist explizit zu dokumentieren. Pro Familie sollen h?chstens 90 Minuten ?u?ere Suche verwendet werden; das Gesamtbudget einschlie?lich Piloten betr?gt 24 Stunden.

## Auswertung und Sperre

Vor Auswertung neuer Testlabels m?ssen Konfigurationen, Auswahlregel, endg?ltige Modelle und Pr?fsummen eingefroren sein. Dazu fehlt noch eine funktionsf?hige technische Studiensteuerung; der ?ffentliche Loader erzwingt diese Sperre nicht. Interpolation und Extrapolation sind separat zu berichten. Fehlerkennzahlen, Zeitmessprotokoll, Ausgangsgr??en und Umgang mit Fehlern folgen dem vom Nutzer best?tigten Plan; sie sind im ausf?hrbaren Ablauf noch nicht vollst?ndig implementiert.

## Bisherige Pilotierung

Die vorhandenen Piloten sind explorativ und d?rfen weder als unabh?ngiger Test noch als Freeze verwendet werden. Ihre vor dem Start fehlende vollst?ndige Codeprovenienz ist in `BESTAND_UND_STATUS.md` dokumentiert. Vor einem Hauptlauf m?ssen Protokoll, Code und Konfiguration nach Abschluss des FEM-Piloten unver?nderlich gespeichert und die gesamte Phasensteuerung gepr?ft werden.
