# Versuchsprotokoll: Architektur- und Trainingsvergleich des Balken-Restfeld-MLP

Protokollstatus: vor dem technischen Pilot und vor jedem Kandidatenfit gespeichert, 28.10.2026.
Die versionierte Konfiguration ist `configs/restfield_mlp_architecture_training_20261028_v1.json`.
Eine nachtraegliche Protokollaenderung wird datiert und begruendet; sie wird nicht als
praeregistriert dargestellt.

## Forschungsfragen und Umfang

Untersucht wird, wie drei kleine tanh-MLP-Architekturen und anschliessend Adam
gegen L-BFGS beim statischen Balken-Restfeld die Feldgenauigkeit, Streuung
zwischen Initialisierungen und Trainingszeit beeinflussen. Eine feste GPR-
Referenz wird pro Fold auf exakt denselben POD-Koeffizienten und derselben
POD-Basis gefittet. Es werden keine weiteren Modellfamilien und keine neuen
FEM-Referenzen untersucht.

Stufe A vergleicht `[16]`, `[16,16]` und `[32,32]` unter Adam. Stufe B
vergleicht Adam gegen L-BFGS fuer die in Stufe A ausgewaehlte Architektur und
dieselben drei Seeds/Folds. Der Adam-Lauf der ausgewaehlten Architektur wird
aus Stufe A wiederverwendet; er wird nicht doppelt trainiert. Gleiche
Anfangsgewichte werden pro Seed/Fold/Architektur durch identische RNG-
Initialisierung erzwungen und durch Hashes protokolliert.

## Daten und bisherige Nutzung

Einzige Labelquelle ist `experiments/active/training_size_12_24_48_20261023/n384/train.mat`
mit den 384 bereits fuer Training bestimmten IDs 1-12 und 25-396. Es werden
weder neue FEM-Laeufe noch Validierungs- oder Testlabels geladen. Die sechs
frueheren Validierungsfaelle (13-18) sind fuer dieses Paket nicht die
Auswahlstichprobe. Die frueheren Testkohorten, die 64 Labels des abgeschlossenen
statischen Vergleichs und andere Holdouts werden nicht fuer Auswahl oder
Bewertung verwendet.

Eine vorab gespeicherte, reproduzierbare gruppierte 3-Fold-Zuordnung teilt
die 384 Trainingsfaelle in drei aeussere Validierungsfolds. Bei eindeutigen
Parameterkombinationen enthaelt jeder Fold 128 Validierungs- und 256
Trainingsfaelle. Exakt gleiche, auf 1e-12 normalisierte Parameterzeilen
bleiben stets in derselben Gruppe und damit in demselben Fold. Alle Kandidaten
teilen genau diese Zuordnung. ID- und Parameterbereichsabdeckung wird
gespeichert.

Die drei aeusseren Folds dienen nur zur Kandidatenauswahl. Sie sind kein
unabhaengiger Abschlusstest und die Ergebnisse duerfen nicht als solcher
berichtet werden.

## Vorverarbeitung, gemeinsame POD und GPR

Das Ziel ist das FEM-Verschiebungsfeld abzüglich des analytischen
Euler-Bernoulli-Balkenfelds. Fuer jeden Fold werden Mittelwert, gewichtete
POD-Basis und Eingabe-/Koeffizientenskalierungen ausschliesslich anhand seiner
256 aeusseren Trainingsfaelle bestimmt. Der POD-Rang ist der erste Rang, der
mindestens 99,99 % der Trainingsenergie erreicht, begrenzt auf 32; falls die
Schwelle innerhalb der Obergrenze nicht erreicht wird, wird Rang 32 verwendet
und die erreichte Energie berichtet. Der Projektionsfehler auf dem aeusseren
Validierungsfold wird unabhaengig vom Regressionsfehler gespeichert.

MLP und GPR erhalten dieselbe Fold-POD-Basis, denselben Mittelwert, dieselben
standardisierten Koeffizientenziele und dieselben Fall-IDs. GPR nutzt den
vorab fixierten ARD-Matern-5/2-Kernel ohne aeussere Fold-Auswahl. Seine
Vorverarbeitung kommt aus den 256 Fold-Trainingszeilen. Die GPR-Rauschvarianz
Sigma=1e-4 ist die vorhandene Paketstandardeinstellung und kein zum MLP-
Gewichts-L2 aequivalentes Regularisierungsglied.

## Training und Budget

Verwendet werden MATLAB R2025b Update 1 und die dort installierte
Deep-Learning-Toolbox-Schnittstelle `trainnet`. Die Architektur hat eine
Eingabeprojektion mit tanh-Aktivierungen und linearem Koeffizienten-Ausgang.
Adam trainiert mit Batchgroesse 256, Lernrate 0,001, L2=1e-4 und maximal 250
Epochen. L-BFGS nutzt die gleiche skalierte MSE und L2-Definition, maximal 250
Batch-Iterationen, HistorySize 10, GradientTolerance 1e-6 und StepTolerance
1e-8. Es gibt kein datenabhaengiges Early Stopping; damit wird der aeussere
Fold nicht zur Trainingssteuerung verwendet. Abbruchgrund und verfuegbare
Iterations-/Loss-Historie werden gespeichert. Die Optimizer-Schrittbudgets
sind keine Gleichsetzung von Rechenaufwand; Laufzeiten und Zaehler werden
separat ausgewertet.

Stufe A: 3 Architekturen x 3 Folds x Seeds 42/43/44 = 27 Laeufe.
Stufe B: zusaetzlich 9 L-BFGS-Laeufe; Adam stammt aus Stufe A.
GPR: 3 Folds. Nach Auswahl: ein abschliessender MLP-Fit auf allen 384
Trainingsfaellen je festem Seed 42/43/44. Diese finalen Modelle werden nicht
auf alten Holdouts geprueft.

Der technische Pilot verwendet Fold 1, Architektur `[16]`, Seed 42, mit je
10 Adam-Epochen und 10 L-BFGS-Iterationen sowie einen gesonderten Fit der
festen GPR-Referenzkonfiguration. Er prueft Schnittstellen,
gemeinsame Darstellung, Initialisierung, Rekonstruktion, Metriken,
Wiederaufnahme und skaliert das Laufzeitbudget ab. Pilotergebnisse zaehlen
nicht zur Kandidatenauswahl und werden nicht als CV-Laeufe wiederverwendet.

## Auswahlregel und Metriken

Primaer ist der Mittelwert des relativen gewichteten Feld-L2-Fehlers ueber
aeussere Validierungsfaelle und Seeds. Der Referenznorm-Nenner wird bei
1e-14 m nach unten begrenzt; die Zahl der betroffenen Faelle wird erfasst.
Architektur und Optimierer werden getrennt ausgewaehlt. Bei Differenzen bis
1e-12 gilt die vorab notierte Listenreihenfolge; fuer Optimierer wird Adam
bevorzugt. Die Auswahl erfolgt auf allen Seeds/Folds, nicht anhand eines
einzelnen Seeds.

Zusaetzlich: Median, nearest-rank-P95, Maximum, gewichteter absoluter RMS-
Feldfehler, POD-Projektionsfehler, foldweise und seedweise Streuung,
gepaarte Fallfehlerdifferenzen, Trainingszeit, Iterationen/Epochen und
Abbruchgrund. Seeds sind keine zusaetzlichen physikalischen Faelle.

## Versuchszustand und Artefakte

Jeder Versuch hat eine eindeutige Run-ID und den Status geplant, laufend,
abgeschlossen, fehlgeschlagen oder abgebrochen. Erfolgreiche und
fehlgeschlagene Run-Artefakte werden unveraenderlich gespeichert; ein
Wiederanlauf prueft Konfigurations-, Daten- und relevanten Codehash. Fehler
werden nicht aus der Versuchstabelle entfernt. Der maschinenlesbare Versuch-
Ledger nennt Modell, Stufe, Fold, Seed, Fallzahlen, Laufzeit, Status, Fehler-
grund und Artefakt.

Geplante Ausgaben: Fold-/Datenmanifest, Versuchstabelle, Validierungsmetriken
je Fall, Trainingshistorien, Modellartefakte, aggregierte Architektur- und
Optimizer-Tabellen, GPR-Referenz, gepaarte Differenzen, Trainingskurven und
Fehlerverteilungsdiagramme sowie Auswahl- und Provenienzbericht.

## Vorab festgelegter Umgang mit Statusaenderungen

Ein Kandidat startet als geplant und wird unmittelbar vor dem Fit auf laufend
gesetzt. Nur ein gespeichertes Modell samt endlichen Metriken ist
abgeschlossen. Exceptions erzeugen einen fehlgeschlagenen Lauf mit
Fold/Seed/Kandidat/Ursache. Ein bewusst gestoppter Lauf ist abgebrochen; er
wird nicht als abgeschlossen gewertet. Eine spaetere Protokollkorrektur
erhaelt Datum, Anlass und genaue Auswirkung auf die Praeregistrierung.

## Datierter technischer Nachtrag (2026-10-28)

Der technische Pilot fuer Adam, L-BFGS und GPR wurde erfolgreich abgeschlossen.
Der unmittelbar anschliessende Auditlauf stoppte vor der Kampagne an einem
technischen Vergleich von SHA-256-Char-Arrays, der in MATLAB keinen skalaren
Wahrheitswert ergab. Der Audit vergleicht Hashwerte nun mit `strcmp`; die
Hashpruefungen fuer Initialgewichte, Laufmetadaten und Codeprovenienz wurden
ebenfalls auf skalare Vergleiche korrigiert.

Der Fehler betraf ausschliesslich die Audit-/Hashpruefung. Es wurde kein
Architektur- oder Optimiererkandidat gestartet. Daten, Folds,
Vorverarbeitung, Kandidaten, Seeds, Trainingsbudgets, GPR-Einstellung und
Auswahlregel bleiben unveraendert. Die drei Pilotlaeufe bleiben als getrennte
technische Versuche erhalten und werden nicht in die Kandidatenauswahl
einbezogen. Das urspruengliche `prepared.mat` wird nicht veraendert; ein
unveraenderliches Provenienz-Amendment haelt die korrigierten Codehashes fest
und verweist auf die urspruengliche Provenienz zurueck.

Beim pruefenden Wiederanlauf wurde ausserdem erkannt, dass MATLAB beim
JSON-Roundtrip Vektoren als Zeilen- beziehungsweise Spaltenvektoren laden
kann. Der gespeicherte Pilot-Laufzeitschaetzer blieb unveraendert; der Runner
vergleicht dessen numerische Werte nun unabhaengig von der Vektororientierung
und verweigert weiterhin eine inhaltlich abweichende Schaetzung. Es wurden
keine Trainingsversuche gestartet. Diese technische Korrektur ist in einem
zweiten unveraenderlichen Provenienz-Amendment dokumentiert.

Der erste Start der Architekturkampagne stoppte vor dem Fit beim Anlegen des
Versuchs-Ledgers mit einem Zeilenanzahlfehler. Der erste Korrekturversuch
normalisierte leere Texteingaben auf skalare Strings; eine nachfolgende
Diagnose identifizierte zusaetzlich die Ursache in den Seed-Schleifen. Es
wurde kein Kandidatenmodell trainiert und kein Kandidat aus der Auswertung
entfernt. Der Audit waehlt das neueste unveraenderliche Provenienzmanifest.
Die urspruenglichen Manifeste und Pilotartefakte bleiben erhalten.

Die Diagnose zeigte, dass MATLAB `jsondecode` die Seed-Arrays in dieser
Konfiguration als 3x1-Spaltenvektoren liefert. Eine `for`-Schleife iterierte
dadurch ueber die gesamte Spalte als einen Wert statt ueber drei Seeds. Alle
Seed-Schleifen verwenden nun explizit Zeilenvektoren; die Ledger-Zeile
erzwingt zusaetzlich skalare Textfelder. Dieser vierte technische Nachtrag
wird vor einem erneuten Kandidatenfit versiegelt. Versuchszahl und
Auswahlregel bleiben unveraendert.

Beim ersten Kampagnenlauf wurden fuer die `[16]`-Architektur alle neun
Fold-/Seed-Laeufe erfolgreich abgeschlossen. Die 18 Versuche fuer `[16,16]`
und `[32,32]` scheiterten an der MATLAB-`for`-Iteration ueber eine als
Spaltenvektor geladene Hidden-Layer-Konfiguration; ihre fehlgeschlagenen
Artefakte und Ledger-Eintraege bleiben erhalten. Die MLP-Fitfunktion iteriert
Hidden-Layer nun explizit ueber eine Zeilenform. Damit bleibt `[16]`
unveraendert; ihre abgeschlossenen Fits werden anhand der frueheren
Provenienz weiterverwendet. Fuer die 18 fehlgeschlagenen Versuche legt der
Wiederaufnahmepfad neue, eindeutig nummerierte Versuche an. Ein fuenftes
Provenienz-Amendment dokumentiert den Code-Fix und erlaubt ausschliesslich
Hashes, die in den unveraenderlichen vorherigen Manifesten belegt sind.

Nach Abschluss aller 27 Architektur-Fits (zuzueglich der 18 erhaltenen
Fehlversuche der ersten Mehrschicht-Iteration) stoppte der Auswahlschritt vor
der Berechnung einer Auswahl, weil der Loader seine Ergebnisstruktur als
numerisches statt als leeres Struct-Array initialisiert hatte. Der Loader
wurde korrigiert; kein Fit wurde wiederholt oder entfernt, und die
vorab festgelegte Auswahlmetrik sowie Gleichstandsregel bleiben unveraendert.
Ein sechstes Provenienz-Amendment haelt diese Auswertungskorrektur fest.

Der erneute Auswahllauf zeigte, dass ein leeres Struct-Array ohne Feldschema
ebenfalls keine erste Ergebnisstruktur aufnehmen kann. Der Loader initialisiert
nun beim ersten abgeschlossenen Lauf aus dessen tatsaechlichem Struct-Schema
und haengt danach gleichfoermige Laufdatensaetze an. Es wurden keine Fits oder
Auswahlentscheidungen erzeugt; dieser siebte technische Nachtrag wird vor der
Wiederaufnahme der Auswahl versiegelt.

Architekturwahl, Optimierervergleich, drei GPR-Referenzen und die drei
Abschlussfits auf n=384 wurden anschliessend erfolgreich gespeichert. Der
aggregierende Auswertungsschritt stoppte vor dem Schreiben seiner Tabellen,
weil eine interne Konstante drei statt der vorab festgelegten neun
Optimiererlaeufe erwartete. Die erwartete Versuchszahl wird nun direkt aus
Folds und Seeds der versionierten Konfiguration berechnet. Es wird kein Fit
wiederholt; vorhandene Auswahlentscheidungen werden nur akzeptiert, wenn ihre
Provenienz einem frueheren unveraenderlichen Manifest entspricht. Dieser
achte technische Nachtrag aendert weder Ergebnisse noch Auswahlregel.

Der erneute Aggregationslauf bestand die Grid-Pruefungen und schrieb die
vollstaendige Fallmetrik-Tabelle, stoppte danach bei derselben MATLAB-
Struct-Initialisierungsregel in der Sammlung der drei ausgewaehlten Adam-
Verlaeufe. Die Adam-Sammlung initialisiert nun beim ersten Laufdatensatz aus
dessen Schema. Die bereits gespeicherte Fallmetrik-Tabelle bleibt erhalten
und muss beim Wiederanlauf inhaltlich identisch bestaetigt werden. Es wurde
kein Fit wiederholt; ein neuntes Provenienz-Amendment protokolliert die
weitere Aggregationskorrektur.

Der folgende Wiederanlauf bestaetigte die vorhandene Fallmetrik-Tabelle und
erreichte die Bildung der gepaarten Adam-/L-BFGS-Uebersichten. Dort traf die
vertikale Verkettung auf eine zeilenfoermige Adam-Sammlung und eine
spaltenfoermige L-BFGS-Sammlung. Die Adam-Sammlung wird vor der Verkettung
explizit in Spaltenform gebracht. Keine Modelle oder Kennzahlen wurden
geaendert; ein zehnter Provenienz-Nachtrag haelt die reine Formkorrektur fest.

Danach stoppte die gepaarte Fallauswertung: Bei `intersect(...,'rows')`
wurde der Schnittmengenausgang anstelle der beiden Indexausgaenge verwendet.
Alle drei betroffenen Vergleiche nutzen nun explizit die zweiten und dritten
Ausgaenge. Diese Korrektur betrifft nur die Indizierung bereits gespeicherter
gepaarter Fallmetriken; ein elftes Provenienz-Amendment protokolliert sie vor
dem erneuten Auswertungslauf.

Der darauffolgende Lauf erzeugte die Ergebnis- und Paarvergleichstabellen,
stopte jedoch bei der Sammlung der Adam-Trainingshistorien fuer die
Optimizer-Abbildung: Auch dieser Sammler war numerisch initialisiert. Er
initialisiert jetzt wie die uebrigen Sammler aus dem ersten gefundenen
Struct-Datensatz. Bereits erzeugte Ergebnisdateien werden beim naechsten Lauf
inhaltlich geprueft; es findet kein erneutes Training statt. Ein zwoelfter
Provenienz-Nachtrag dokumentiert diese Plot-Hilfsfunktion-Korrektur.

Beim erneuten Plotlauf waren die L-BFGS-Historien spalten- und die
zurueckgegebenen Adam-Historien zeilenorientiert; die vertikale Verkettung
brach deshalb nach erfolgreicher Ergebnisaggregation ab. Beide Arrays werden
vor der Verkettung explizit in Spaltenform gebracht. Die Trainingshistorien
und Ergebnisse bleiben unveraendert. Ein dreizehnter Provenienz-Nachtrag
protokolliert diese letzte Formkorrektur.

Die komplette Runner-Auswertung wurde erfolgreich abgeschlossen. Der separate
Provenienzaudit stoppte anschliessend bei der Pruefung der Artefaktpfade, weil
die installierte MATLAB-Version `isfile` nicht auf ein ganzes String-Array
anwendet. Der Audit prueft die Pfade nun einzeln. Ergebnisdateien und Modelle
bleiben unveraendert; ein vierzehnter Provenienz-Nachtrag dokumentiert diese
ausschliesslich technische Auditkorrektur.

Der Audit zeigte, dass `readtable` die leeren Status-/Artefaktspalten der
urspruenglichen CSV als numerische `NaN`-Spalten inferiert hatte; dadurch
waren Pfad-, Abbruch- und Fehlertexte in der Ledger-Datei nicht erhalten,
obwohl die unveraenderlichen Run-Artefakte vorhanden sind. Runner und Audit
erzwingen nun String-Typen fuer Textspalten. Vor der finalen Auswertung werden
Terminalzeilen anhand ihrer Run-ID und des vorhandenen MAT-Artefakts
abgeglichen und fehlende Pfade/Abbruchangaben aus diesem Artefakt
wiederhergestellt; widerspruechliche Pfade oder Statuswerte fuehren zum
Abbruch. Ein fuenfzehnter Provenienz-Nachtrag dokumentiert diese
Provenienzreparatur. Modelle und Metriken werden nicht neu berechnet.

Der Audit-Reparaturlauf zeigte, dass das urspruengliche
`attempt_ledger_final.csv` vor dem Ledger-Reparaturschritt geschrieben worden
war und deshalb leere Textwerte als `NaN` enthielt. Diese erste eingefrorene
Datei wird nicht ueberschrieben. Der Runner vergleicht sie nun gegen das
reparierte Ledger anhand aller unveraenderten Run-/Status-/Zeit-/Hashfelder
und verifiziert die Abbruchgruende und Fehlerdetails direkt an den
unveraenderlichen Run-Artefakten. Das kanonische reparierte Ledger bleibt
`attempt_ledger.csv`. Ein siebzehnter Provenienz-Nachtrag dokumentiert diese
strikte Wiederaufnahme, ohne das alte Artefakt still zu ersetzen.

Die drei Fits auf allen 384 Trainingsfaellen haben keine aeussere
Testfallmenge; ihre In-Sample-Fehler werden daher nicht als
Generalisierungsmetrik ausgewiesen. Der abschliessende Bericht erfasst diese
Fits pro Seed anhand von Trainingsumfang, train-only POD-Rang und tatsaechlich
gemessener Trainingszeit; Genauigkeitsvergleiche beruhen ausschliesslich auf
der dreifachen aeusseren CV.

Zur Erhaltung des zuerst erzeugten Berichts wird der abschliessende Seed-
Bericht als `FINAL_REPORT_v2.md` angelegt. Diese Ausgabe ergaenzt die nach
Ledger-Reparatur validierten finalen Fitmetriken je Seed; der urspruengliche
`FINAL_REPORT.md` bleibt unveraendert als fruehere Berichtsrevision erhalten.
