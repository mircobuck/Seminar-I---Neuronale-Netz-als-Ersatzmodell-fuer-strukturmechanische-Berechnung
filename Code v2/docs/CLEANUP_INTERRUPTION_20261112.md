# Kontrollierte Speicherunterbrechung und Freigabe

Die bereinigte Hauptstudie startete am 12.11.2026 um 21:28:56 Europe/Berlin mit 2,1755 GiB frei und Quellcommit d2357ff. Ab 21:30:42 lief die Suche. Alle 20 MLP-Such-/Bestaetigungsfits wurden erfolgreich gespeichert. Am naechsten RBF-Checkpoint stoppte requireSpace kontrolliert um ca. 21:42:15: 297 MiB frei statt der geforderten 512 MiB. Kein fehlgeschlagener Fit und kein unvollstaendiger Fit-Ordner wurde angelegt.

Die Systemplatte sank danach bis auf 0 freie Bytes. Zu diesem Zeitpunkt belegte die neue Studie erst rund 16 MiB. Ein parallel beobachteter fremder Git-add-Prozess und weniger als 0,7 GiB freier physischer RAM zeigten Hintergrundaktivitaet; deren kausaler Anteil am Platzverlust ist nicht eindeutig nachgewiesen. Keine Git-Packdatei oder wissenschaftliche Datei wurde geloescht. Zeiten aus dieser Phase enthalten die tatsaechlichen Systembedingungen und sind kein isolierter Performancevergleich.

Der Nutzer gab daraufhin beide zusaetzlichen Download-Caches ausdruecklich zur Entfernung frei. Absolute Pfade und fehlende Reparse-Points wurden erneut geprueft:

- C:/Users/dietz/AppData/Local/pip/Cache: 702.100.462 Bytes; entfernt 21:43:33.
- C:/Users/dietz/AppData/Local/npm-cache/_cacache: 1.622.635.107 Bytes; entfernt 21:43:44.

Installierte Umgebungen, npm-Ausfuehrungsumgebungen, Projekte und wissenschaftliche Ergebnisse blieben erhalten. Freier Speicher danach: 2,1671 GiB. Pakete koennen bei kuenftigem Bedarf erneut heruntergeladen werden; es wurden nur Download-Caches entfernt.

Vor Wiederaufnahme wurden alle Quell-/Inputmanifestdateien und die 20 Ergebnissiegel geprueft. Die Modellhashes sind in CLEANUP_RESUME_MODELS_20261112.csv gesichert. MATLAB prueft beim Wiederverwenden zusaetzlich Modellhash, Trainings-/Validierungsdaten, IDs und Konfiguration. Quellcode, Fachkonfiguration und Auswahlregeln bleiben unveraendert. Die beiden Batchlogs bleiben getrennt erhalten; Suchzeitprotokolle addieren aktive Sitzungen, nicht die Unterbrechungsdauer.


## Zweite Unterbrechung: manueller Standby

Die Wiederaufnahme lief ab 21:46:25 am 12.11.2026. Nach 13 RBF-Kandidaten meldet das Systemereignis 42 um 21:52:34 Standby mit Ursache Button or Lid; spaeter folgte Ruhezustand. Reaktivierung am 13.11.2026 gegen 10:03 Uhr. RBF-Kandidat 14 erhielt dadurch eine aeussere Fit-Zeit von 43.910,14 s. Das unveraenderte Familienbudget war anschliessend verbraucht; die Studie brach mit study:ConfirmationIncomplete ab. Dieser Versuch ist kein gueltiger vollstaendiger Hauptstudien- oder Zeitnachweis. Zeitwerte werden nicht um Standbyanteile bereinigt, Budgets nicht nachtraeglich gelockert.

Alle 34 Checkpoints und beide Fehlerberichte bleiben erhalten. Neuer vollstaendiger Versuch: experiments/static_comparison_cleanup_20261113_attempt2. Alle Fits werden dort neu ausgefuehrt. Im lokalen Konfigurationsbeispiel aendert sich ausschliesslich output_dir; Methoden, Kandidaten, Seeds, Budgets und Fachcode bleiben unveraendert. Die bestandenen 71 Tests und der Smoke gelten weiterhin fuer exakt denselben Funktionscode.
