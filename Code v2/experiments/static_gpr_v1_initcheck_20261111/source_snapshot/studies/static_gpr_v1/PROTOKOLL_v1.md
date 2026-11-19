# Statische Surrogatvergleichsstudie - Protokoll v1.0

Vor Beginn der Hauptstudie festgelegt. Vorarbeiten sind explorativ und werden nicht als unabhaengiger Test oder als vorregistriert ausgegeben. Geltungsbereich sind vollstaendige statische 3D-FEM-Verschiebungsfelder; Eigenfrequenzen sind ausgeschlossen. Die maschinenlesbaren Werte stehen in study_config.json. Neue Hauptstudien-IDs beginnen bei 830001.

## Daten und Design

Der Trainingspool umfasst je 384 Faelle aus dem urspruenglichen und dem ergaenzten Block. Drei reproduzierbare, blockausgeglichene verschachtelte Auswahlfolgen enthalten 48, 96, 192, 384 und 768 Faelle; der Vollpool ist identisch und zaehlt nicht als dreifache Datenstreuung. Samen fuer Design, Fallauswahl und Netzinitialisierung sind getrennt.

Neue Validierung (128), Interpolationstest (256) und Extrapolationstest (128) werden unabhaengig erzeugt. Interpolation und Validierung: Latin Hypercube innerhalb der urspruenglichen Grenzen. Extrapolation: genau eine der zwoelf Parameterseiten 5-10 % der jeweiligen Intervallbreite ausserhalb, Gruppen moeglichst gleich gross. Vorausberechnete Ersatzkandidaten derselben Rolle/Gruppe ersetzen fehlgeschlagene FEM-Faelle in fester Reihenfolge. Physikalische Zulaessigkeit, Finite Werte und Kleinauslenkung unter 0,02 werden geprueft. Ueberschneidungstoleranz: 1e-10 der Bereichsbreite in Maximumsnorm gegen alle bekannten Designs, Pilotfaelle und neue Kandidaten. Historische Test- und Validierungsfaelle bleiben historische Evidenz.

Pilot: 48 statische Netzlaeufe erfolgreich, einschliesslich zwoelf Extrapolationsfaellen auf drei Netzstufen; 587,49 s verstrichene Zeit. Diese kleine Stichprobe beweist keine Netzkonvergenz im gesamten Bereich. Auf Grundlage der gemessenen Standardnetzzeiten bleiben die geplanten neuen Fallzahlen unveraendert.

## Modelle und Auswahl

Stufenweise Suche bei N=384 und einer blockausgeglichenen Auswahl; Kandidaten erhalten denselben Seed 42. Pro Familie hoechstens 5400 s einschliesslich Fehlversuchen; keine Kandidaten nach Ablauf starten, einzelne laufende Kandidaten duerfen zu Ende laufen. Fuer die erste Stufe sind hoechstens 60 % des Familienbudgets vorgesehen; die restliche Zeit dient der Bestaetigung. Die Suchreihenfolge ist vorab durch Code und Konfiguration definiert, fehlgeschlagene und wegen Zeitlimit nicht gestartete Versuche werden berichtet.

MLP: Breite 64/128, Tiefe 2/3, Lernrate 0,0005/0,001, standardisierte oder gewichtete Loss. RBF: Zentren 32/64, Breite 0,5/1/2, Tiefe 2/3, beide Losses, uebrige Netzbreite 64. POD-MLP: Rang 2/10/15, Breite 64/80, Tiefe 2/3, gewichtete Loss. POD-GPR: Rang 2/10/15, ARD-Squared-Exponential/ARD-Matern-5/2, Mittelwert konstant/linear, numerisches Sigma 1e-4/1e-3. Adam: 200 Epochen, Batch 32, Standardlernrate 0,001. GPR: exakte Fit-/Predict-Methode, zwei dokumentierte Starts, Quasi-Newton bis 500 Iterationen. Sigma ist numerische Stabilisierung und keine physikalische Messrauschannahme.

Kandidatenwahl anhand des mittleren gewichteten relativen Feldfehlers auf der neuen Validierung; Gleichstand nach P95 und dann Konfigurations-ID. Top zwei neuronale Kandidaten werden auf derselben Fallauswahl mit Seeds 42/43/44 bestaetigt; Auswahl nach Mittelwert der drei Seed-Metriken. GPR ist deterministisch und wird nicht als unabhaengige Modellstreuung wiederholt. Testlabels sind bis zum Freeze fuer Modellwahl gesperrt.

Der Pipelinevergleich verwendet familienweise ausgewaehlte Konfigurationen fuer alle Trainingsgroessen. Der kontrollierte POD-Vergleich verwendet dieselben Trainingsfaelle, Mittelwerte, gewichteten Basen und Raenge 2/10/15, wobei die gewaehlten Regressoreinstellungen konstant bleiben. Fuer N=768 wird eine eindeutige Fallauswahl verwendet, finale neuronale Modelle werden zusaetzlich mit drei Initialisierungen bewertet. Parameterverteilung gesondert bei N=192: raumfuellende und zum niedrigen Laengenbereich konzentrierte Auswahl, blockausgeglichen und mit identischen Randfaellen.

## Messungen und Test

Serielle CPU-Laeufe; keine konkurrierenden Studienjobs; blockweise ausgeglichene Methodenfolge. Gesamtzeit des oeffentlichen Fit-Aufrufs und separat dessen Segmente, aeussere Suchzeit einschliesslich Fehler, Modellgroesse sowie gemeinsame und eigenstaendige POD-Kosten protokollieren. Vorhersage: nach separatem Warm-up 30 vollstaendige oeffentliche Aufrufe fuer einen Fall und einen Batch von 128 Faellen; Median und Interquartilsabstand, Laden und Speichern getrennt. FEM-Solverzeit und verstrichene Zeit nach Split getrennt.

Pro Fall: gewichteter relativer und absoluter Feldfehler; vorzeichenbehaftetes uz am normierten Punkt (1,0.5,0.5); maximaler Verschiebungsbetrag ueber das Referenzgitter. Pro Lauf Mittelwert, Median, Nearest-Rank-P95 und groesstes beobachtetes Maximum. NaNs und Fehlerfaelle zaehlen. Bei POD gewichtete Projektions-, Regressions- und Rekonstruktionsfehler samt quadratischer Zerlegung ausweisen. Wiederholungen sind keine zusaetzlichen Testfaelle. Interpolation und Extrapolation getrennt auswerten.

Die Phasensteuerung erfordert vor Testlabelzugriff ein verifiziertes Freeze-Manifest mit Quellstand, Konfiguration, Daten, Auswahlregel und allen Modellhashes. Dies ist eine Sperre im Studienablauf, keine Dateisystemzugriffskontrolle. Nach Testeinsicht keine nachtraegliche Auswahl fuer denselben Abschlusstest. Vorhandene analytische Balkenreferenzen dienen nur zur Plausibilisierung, nicht als exakte 3D-Feldloesung.

Alle Checkpoints erfordern unveraenderte Pruefsummen fuer Programmstand einschliesslich uneingecheckter Dateien, Konfiguration und Inputdaten. Fehlversuche bleiben protokolliert. Aenderung erfordert eine neue Studie. Vor neuen Checkpoints muessen mindestens 512 MiB frei sein. Das kumulierte 24-h-Budget beginnt konservativ am 11.11.2026 um 14:00 UTC; bei der Initialisierung wird die bis dahin verstrichene Zeit, mindestens jedoch 3600 s, angerechnet; wegen Betriebssystemplanung sind harte Abbrueche waehrend eines einzelnen FEM-/Trainingslaufs nicht vorgesehen.

Die statischen Diagramme werden nach der MATLAB-Auswertung durch das mitgehashte lokale Python-/Matplotlib-Skript erzeugt; diese Hilfssoftware beeinflusst die Modellanpassung nicht.
