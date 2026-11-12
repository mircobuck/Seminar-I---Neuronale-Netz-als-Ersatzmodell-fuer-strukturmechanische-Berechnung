# Statische Surrogatvergleichsstudie ? Protokoll v1.0

Vor Beginn der Hauptstudie festgelegt. Vorarbeiten sind explorativ und werden nicht als unabh?ngiger Test oder als vorregistriert ausgegeben. Geltungsbereich sind vollst?ndige statische 3D-FEM-Verschiebungsfelder; Eigenfrequenzen sind ausgeschlossen. Die maschinenlesbaren Werte stehen in study_config.json.

## Daten und Design

Der Trainingspool umfasst je 384 F?lle aus dem urspr?nglichen und dem erg?nzten Block. Drei reproduzierbare, blockausgeglichene verschachtelte Auswahlfolgen enthalten 48, 96, 192, 384 und 768 F?lle; der Vollpool ist identisch und z?hlt nicht als dreifache Datenstreuung. Samen f?r Design, Fallauswahl und Netzinitialisierung sind getrennt.

Neue Validierung (128), Interpolationstest (256) und Extrapolationstest (128) werden unabh?ngig erzeugt. Interpolation und Validierung: Latin Hypercube innerhalb der urspr?nglichen Grenzen. Extrapolation: genau eine der zw?lf Parameterseiten 5?10 % der jeweiligen Intervallbreite au?erhalb, Gruppen m?glichst gleich gro?. Vorausberechnete Ersatzkandidaten derselben Rolle/Gruppe ersetzen fehlgeschlagene FEM-F?lle in fester Reihenfolge. Physikalische Zul?ssigkeit, Finite Werte und Kleinauslenkung unter 0,02 werden gepr?ft. ?berschneidungstoleranz: 1e-10 der Bereichsbreite in Maximumsnorm gegen alle bekannten Designs, Pilotf?lle und neue Kandidaten. Historische Test- und Validierungsf?lle bleiben historische Evidenz.

Pilot: 48 statische Netzl?ufe erfolgreich, einschlie?lich zw?lf Extrapolationsf?llen auf drei Netzstufen; 587,49 s verstrichene Zeit. Diese kleine Stichprobe beweist keine Netzkonvergenz im gesamten Bereich. Auf Grundlage der gemessenen Standardnetzzeiten bleiben die geplanten neuen Fallzahlen unver?ndert.

## Modelle und Auswahl

Stufenweise Suche bei N=384 und einer blockausgeglichenen Auswahl; Kandidaten erhalten denselben Seed 42. Pro Familie h?chstens 5400 s einschlie?lich Fehlversuchen; keine Kandidaten nach Ablauf starten, einzelne laufende Kandidaten d?rfen zu Ende laufen. F?r die erste Stufe sind h?chstens 60 % des Familienbudgets vorgesehen; die restliche Zeit dient der Best?tigung. Die Suchreihenfolge ist vorab durch Code und Konfiguration definiert, fehlgeschlagene und wegen Zeitlimit nicht gestartete Versuche werden berichtet.

MLP: Breite 64/128, Tiefe 2/3, Lernrate 0,0005/0,001, standardisierte oder gewichtete Loss. RBF: Zentren 32/64, Breite 0,5/1/2, Tiefe 2/3, beide Losses, ?brige Netzbreite 64. POD?MLP: Rang 2/10/15, Breite 64/80, Tiefe 2/3, gewichtete Loss. POD?GPR: Rang 2/10/15, ARD-Squared-Exponential/ARD-Matern-5/2, Mittelwert konstant/linear, numerisches Sigma 1e-4/1e-3. Adam: 200 Epochen, Batch 32, Standardlernrate 0,001. GPR: exakte Fit-/Predict-Methode, zwei dokumentierte Starts, Quasi-Newton bis 500 Iterationen. Sigma ist numerische Stabilisierung und keine physikalische Messrauschannahme.

Kandidatenwahl anhand des mittleren gewichteten relativen Feldfehlers auf der neuen Validierung; Gleichstand nach P95 und dann Konfigurations-ID. Top zwei neuronale Kandidaten werden auf derselben Fallauswahl mit Seeds 42/43/44 best?tigt; Auswahl nach Mittelwert der drei Seed-Metriken. GPR ist deterministisch und wird nicht als unabh?ngige Modellstreuung wiederholt. Testlabels sind bis zum Freeze f?r Modellwahl gesperrt.

Der Pipelinevergleich verwendet familienweise ausgew?hlte Konfigurationen f?r alle Trainingsgr??en. Der kontrollierte POD-Vergleich verwendet dieselben Trainingsf?lle, Mittelwerte, gewichteten Basen und R?nge 2/10/15, wobei die gew?hlten Regressoreinstellungen konstant bleiben. F?r N=768 wird eine eindeutige Fallauswahl verwendet, finale neuronale Modelle werden zus?tzlich mit drei Initialisierungen bewertet. Parameterverteilung gesondert bei N=192: raumf?llende und zum niedrigen L?ngenbereich konzentrierte Auswahl, blockausgeglichen und mit identischen Randf?llen.

## Messungen und Test

Serielle CPU-L?ufe; keine konkurrierenden Studienjobs; blockweise ausgeglichene Methodenfolge. Gesamtzeit des ?ffentlichen Fit-Aufrufs und separat dessen Segmente, ?u?ere Suchzeit einschlie?lich Fehler, Modellgr??e sowie gemeinsame und eigenst?ndige POD-Kosten protokollieren. Vorhersage: nach separatem Warm-up 30 vollst?ndige ?ffentliche Aufrufe f?r einen Fall und einen Batch von 128 F?llen; Median und Interquartilsabstand, Laden und Speichern getrennt. FEM-Solverzeit und verstrichene Zeit nach Split getrennt.

Pro Fall: gewichteter relativer und absoluter Feldfehler; vorzeichenbehaftetes uz am normierten Punkt (1,0.5,0.5); maximaler Verschiebungsbetrag ?ber das Referenzgitter. Pro Lauf Mittelwert, Median, Nearest-Rank-P95 und gr??tes beobachtetes Maximum. NaNs und Fehlerf?lle z?hlen. Bei POD gewichtete Projektions-, Regressions- und Rekonstruktionsfehler samt quadratischer Zerlegung ausweisen. Wiederholungen sind keine zus?tzlichen Testf?lle. Interpolation und Extrapolation getrennt auswerten.

Die Phasensteuerung erfordert vor Testlabelzugriff ein verifiziertes Freeze-Manifest mit Quellstand, Konfiguration, Daten, Auswahlregel und allen Modellhashes. Dies ist eine Sperre im Studienablauf, keine Dateisystemzugriffskontrolle. Nach Testeinsicht keine nachtr?gliche Auswahl f?r denselben Abschlusstest. Vorhandene analytische Balkenreferenzen dienen nur zur Plausibilisierung, nicht als exakte 3D-Feldl?sung.

Alle Checkpoints erfordern unver?nderte Pr?fsummen f?r Programmstand einschlie?lich uneingecheckter Dateien, Konfiguration und Inputdaten. Fehlversuche bleiben protokolliert. ?nderung erfordert eine neue Studie. Das kumulierte 24-h-Budget ber?cksichtigt konservativ 2000 s f?r die bereits verstrichene Vorphase; wegen Betriebssystemplanung sind harte Abbr?che w?hrend eines einzelnen FEM-/Trainingslaufs nicht vorgesehen.
