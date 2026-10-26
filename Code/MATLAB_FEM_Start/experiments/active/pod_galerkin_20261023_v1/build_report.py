"""Rebuild the report from the saved, actually evaluated experiment tables."""
from pathlib import Path
import csv
import json
import math

folder = Path(__file__).resolve().parent

def read(name):
    with (folder / name).open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))

rows = read("comparison.csv")
case_rows = read("per_case.csv")
lookup = {(int(row["TrainingCases"]), row["Model"]): row for row in rows}
counts = [12, 24, 48, 96, 192, 384]
rom = [lookup[n, "POD_Galerkin"] for n in counts]
stats = json.loads((folder / "verification_statistics.json").read_text())
worst_rows=[]
for row in rows:
    cases=[c for c in case_rows if c['TrainingCases']==row['TrainingCases'] and c['Model']==row['Model']]
    metric='FieldRelativeL2' if not math.isnan(float(row['FieldMedianRelL2'])) else 'TipRelativeError'
    worst=max(cases,key=lambda c:float(c[metric]))
    worst_rows.append({'TrainingCases':row['TrainingCases'],'Model':row['Model'],
                       'Metric':metric,'CaseID':worst['CaseID'],'RelativeError':worst[metric]})
with (folder/'worst_cases.csv').open('w',encoding='utf-8',newline='') as handle:
    writer=csv.DictWriter(handle,fieldnames=list(worst_rows[0]));writer.writeheader();writer.writerows(worst_rows)
assert all(r['CaseID']=='23' for r in worst_rows if r['Model']=='POD_Galerkin')

def fmt(value, scale=1, digits=4):
    number = float(value) * scale
    return "–" if math.isnan(number) else f"{number:.{digits}f}".replace(".", ",")

def offline(row):
    return sum(float(row[key]) for key in (
        "TrainingSnapshotSeconds", "ValidationSnapshotSeconds", "OfflineBasisAndSelectionSeconds"))

text = ["""# POD-Galerkin-ROM gegenüber den vorhandenen KI-Ersatzmodellen

Stand: 23.10.2026. **Implementiert und vollständig ausgewertet** für alle
tatsächlich untersuchten Trainingsgrößen 12, 24, 48, 96, 192 und 384.
MATLAB 25.2.0.3042426 (R2025b) Update 1; Ausführung über MATLAB MCP.

Der klassische ROM benötigt schon bei zwölf Trainingsfällen wenig Daten für
eine gute Feldvorhersage: rund 0,057 % Median und 0,112 % schlechtester Fehler.
Mehr Trainingsfälle verbessern dieses Ergebnis kaum. Die gesamte Online-Zeit
beträgt rund 0,90–0,93 s, weil weiterhin vollständig assembliert wird.
Die KI-Inferenz ist erheblich schneller. Die Genauigkeit ist auf diesem
kleinen, bereits bekannten Testsatz gemessen, nicht allgemein garantiert.

## Tatsächlich untersuchte Daten und Schutz bestehender Ergebnisse

Die sechs Größen wurden aus der bestehenden Lernkurventabelle und eingefrorenen
Modellen ermittelt. Der nur konfigurierte Pilot mit 64 Trainingsfällen wurde
bisher nicht ausgeführt und gehört deshalb nicht zu dieser Vergleichsreihe.
Es wurde kein Pilot-Lauf gestartet.

Alle ROMs verwenden exakt die jeweiligen KI-Trainings-IDs. Validierung:
IDs 13–18; Test: IDs 19–24. Die Eingangswerte sind identisch, die Netze nicht.
Es gibt nur die bereits vorhandene Datenreihe und den ursprünglichen
Modell-Seed 42, keine zusätzlichen Trainingswiederholungen. POD-Galerkin
enthält keinen stochastischen Regressor. Die ursprünglichen Design-Seeds
und Eingabedateien sind unter source_designs archiviert.

Für die gemeinsame nodale Basis wurden **396 zusätzliche FEM-Snapshots**
berechnet: 384 Training, sechs Validierung, sechs Test. Die verschachtelten
Teilmengen verwenden diese Snapshots wieder. Die Test-Snapshots und Testlabels
wurden erst nach Einfrieren aller sechs ROMs in die neue Berechnung geladen.
Der Testsatz war allerdings bereits aus der vorherigen Lernkurve bekannt;
dies ist keine neue blinde Bestätigung. Es erfolgte keine Anpassung nach den
neuen Testresultaten.

Alle **1084 zuvor vorhandenen Run-/Lernkurvendateien** sind per SHA-256
unverändert. Neue Modelle und ergänzte Vergleichstabellen liegen ausschließlich
in diesem neuen Studienordner. Die fünf bestehenden KI-Modelle je Größe wurden
nicht nachtrainiert. Fehlende Spitzenfehler ihrer Feldvorhersagen wurden neu
berechnet. Ihre ursprünglichen medianen Feldfehler werden bis auf 1e-12 reproduziert.

## Mechanisch konsistenter gemeinsamer FEM-Raum

Ausgangspunkt ist ein quadratisches Tetraedernetz am Mittelpunkt des
Parameterbereichs: L=0,9 m, b=0,08 m, h=0,11 m, Hmax=0,08/3 m.
Das tatsächlich gespeicherte Netz hat 5586 Knoten, 3257 Tetraeder,
16758 Gesamtfreiheitsgrade, 249 festgehaltene und **16509 freie Freiheitsgrade**.
Die gespeicherten Knoten und Elemente sind die Reproduktionsgrundlage.

Referenzkoordinaten liegen in [0,1]^3. Die physikalische Abbildung lautet
`x=L*(xi-1/2), y=b*(eta-1/2), z=h*zeta`. Konnektivität, Knotenreihenfolge und
Blockreihenfolge `[ux;uy;uz]` bleiben erhalten und werden bei jeder Assemblierung
geprüft. `fegeometry(nodes',elements')` übernimmt das abgebildete Netz.
Materialzuordnung und rechte Stirnflächenlast verwenden die jeweiligen Werte
E, nu und `Fz/(b*h)`. Die Summe der assemblierten Lastkomponenten wird bei jedem
Aufruf gegen `[0,0,Fz]` geprüft.

Die Assemblierung verwendet ausdrücklich `assembleFEMatrices(m,"none")`.
Aus den ungekürzten Matrizen werden `Kfull=K+A+Q` und `ffull=F+G` gebildet.
Die geometrisch bestimmten linken Knoten sind in allen drei Komponenten
homogen eingespannt. Ihre Freiheitsgrade werden genau einmal eliminiert:

```text
ufull = J * uf
Kf = J' * Kfull * J       ff = J' * ffull
Kr = V' * Kf * V         fr = V' * ff
a = Kr \\ fr             uROM = V * a
```

`J` ist die feste Einbettung der freien Freiheitsgrade. Die Randwerte sind null,
deshalb ist kein Lifting-Term erforderlich. `H(:,free)==0` und `R==0` werden
geprüft. Es werden keine bereits gekürzten Kc-Matrizen nochmals eliminiert.
Ein eigener Test bestätigt die Übereinstimmung mit der MATLAB-nullspace-Lösung
`B*(Kc\\Fc)+ud` und mit `solve(m)`.

Für jedes N wird V ausschließlich aus seinen **unzentrierten nodalen
Trainingslösungen** durch SVD gebildet. Kandidaten: **1, 2, 4, 8, 11**;
Rangwahl nach kleinstem mittleren Validierungs-Feldfehler auf der ursprünglichen
Referenz. Keine Tests, Zentrierung, Verschiebungsmittelwerte oder Regressoren
gehen in diese Koeffizientenberechnung ein.

## Ausgabe, Normen und Projektionsuntergrenze

Eine feste quadratische Tetraeder-Auswertematrix O bildet die freien nodalen
Lösungen auf genau dasselbe 21×5×5-Referenzgitter ab. Die Kantenzuordnung der
quadratischen Mittelknoten wird aus ihren Koordinaten ermittelt. Konstante und
lineare Felder sowie die Übereinstimmung mit `interpolateDisplacement` sind
geprüft. Es wird keine interpolierte 1575-dimensionalen Gitterbasis mit den
ursprünglichen FEM-Matrizen multipliziert.

Feldfehler: `||sqrt(W)*(Sref-H)|| / ||sqrt(W)*Sref||` mit den ursprünglichen
Quadraturgewichten. Spitzenverschiebung: signiertes uz am Stirnflächenmittelpunkt,
der im Gitter enthalten ist. Maximum: größter Verschiebungsbetrag auf denselben
525 Punkten. Die Spitzen- und Maximalfehler werden als MAE in Metern gespeichert.
Rein skalare Modelle erhalten keinen künstlichen Feldfehler.

Die beste Ausgabeprojektion berechnet diagnostisch
`min_b ||sqrt(W)*(Sref - O*V*b)||`. Diese testabhängigen Projektionskoeffizienten
werden nur zur Fehleruntergrenze verwendet, nie für die eigentliche Vorhersage.
Für KI-POD-Modelle wird deren vorhandener Mittelwert korrekt berücksichtigt.
Die Galerkin-Koeffizienten minimieren den Energiefehler im gemeinsamen FEM-Raum,
nicht diesen Ausgabe-L2-Fehler gegen die andere FEM-Diskretisierung.

## Feldgenauigkeit für alle Trainingsgrößen

Alle folgenden Feldfehler sind Prozent; CSV-Dateien speichern Verhältnisse.
Bei sechs Testfällen entspricht das verwendete P95 hier dem Maximum.

| N | Rang | ROM-Median | ROM-P95/Maximum | beste Ausgabeprojektion (Median) | POD_GP-Median | POD_RBF-Median | POD_MLP-Median |
|---:|---:|---:|---:|---:|---:|---:|---:|
"""]
for n, row in zip(counts, rom):
    values = [str(n), row["PODRank"], fmt(row["FieldMedianRelL2"],100),
              fmt(row["FieldWorstRelL2"],100), fmt(row["OutputProjectionMedian"],100,6)]
    values += [fmt(lookup[n,name]["FieldMedianRelL2"],100) for name in ["POD_GP","POD_RBF","POD_MLP"]]
    text.append("| " + " | ".join(values) + " |")

text.append("""
Die gemeinsame Voll-FEM weicht auf dem Testsatz selbst im Median um **0,0601 %**,
maximal um **0,1117 %** von der bisherigen Referenz ab. Über alle 396 Fälle
beträgt die größte Abweichung **0,2111 %**, auf Validierung maximal **0,0706 %**.
Das sind Unterschiede zwischen zwei Diskretisierungen, kein Beweis für den
Fehler einer davon gegenüber der exakten Kontinuumslösung. Eine neue
Netzkonvergenzstudie wurde nicht durchgeführt.

Das ROM-Plateau liegt somit in derselben Größenordnung wie die Netzabweichung.
Die Ausgabe-Projektionsuntergrenze ist trotzdem deutlich kleiner als der
Galerkin-Fehler. Das widerspricht der Theorie nicht: Energie-Minimum und
Ausgabe-L2-Minimum sind verschiedene Aufgaben; zusätzlich ist die berichtete
Referenzlösung auf einem anderen Netz entstanden. Eine gelegentlich kleinere
ROM-Abweichung als die gemeinsame Voll-FEM beweist keine höhere Kontinuumsgenauigkeit.
Der schlechteste ROM-Testfall ist bei allen sechs Größen **Fall-ID 23**.
worst_cases.csv enthält die schlechtesten Fall-IDs aller Methoden und Größen,
mit getrennter Kennzeichnung von Feld- und skalarem Relativfehler.

## Gleichgewicht und Energie

Freies Residuum: `||Kf*uROM-ff||/||ff||`.
Projiziertes Residuum: `||V'*(Kf*uROM-ff)||/||fr||`.
Energiefehler: `sqrt(e'*Kf*e/(uFOM'*Kf*uFOM))` gegen die Voll-FEM auf dem
gemeinsamen Netz. Alle Werte werden zusätzlich pro Testfall gespeichert.

| N | freies Residuum, Median [%] | relativer Energiefehler, Median [%] |
|---:|---:|---:|
""")
for n,row in zip(counts,rom):
    text.append(f"| {n} | {fmt(row['FreeResidualMedian'],100)} | {fmt(row['EnergyErrorMedian'],100)} |")
text.append("""
Das maximale freie Residuum beträgt **32,96 %**, der maximale relative
Energiefehler **0,2555 %**, das maximale projizierte Residuum **4,65e-11**.
Der ROM erfüllt das Gleichgewicht im Ansatzraum, nicht jede einzelne freie
FEM-Gleichung exakt. Ein kleiner Feldfehler darf deshalb nicht als verschwindendes
vollständiges Residuum ausgegeben werden. Für KI-Gitterfelder werden Residuum
und Energiefehler als nicht verfügbar markiert; ein willkürliches Rückheben
ins FEM-Netz würde keinen fairen Vergleich liefern.

## Gemeinsame skalare Ausgaben bei N=384

| Modell | Spitzen-MAE [µm] | MAE des Gittermaximums [µm] |
|---|---:|---:|
""")
for name in ["POD_Galerkin","Scalar_GPR","Beam_plus_GPR","POD_GP","POD_RBF","POD_MLP","FullFEM_common"]:
    row=lookup[384,name]
    text.append(f"| {name} | {fmt(row['TipMAE_m'],1e6,6)} | {fmt(row['MaxGridMAE_m'],1e6,6)} |")
text.append("""
Die gelernte Balkenkorrektur ist für die einzelne Spitzenverschiebung bei
N=384 genauer und schneller als der ROM, liefert aber kein Verschiebungsfeld.
Sie wird deshalb nicht mit Feld-L2-Kennzahlen gerankt.

## Vollständige Online-Zeit und isolierte reduzierte Lösung

Pro ROM-Testfall wurden drei vollständige Online-Auswertungen gemessen,
einschließlich neuer Geometrie und voller Assemblierung. Für KI-Modelle:
ein Warmup und fünf vollständige Inferenzmessungen pro Fall. Tabelle:
Median der fallweisen Mediane, keine bloße reduzierte Lösezeit.

| N | ROM gesamt [s] | Geometrie [s] | Assemblierung [s] | Projektion [s] | reduzierte Lösung [µs] | Rekonstruktion/Ausgabe [ms] |
|---:|---:|---:|---:|---:|---:|---:|
""")
for n,row in zip(counts,rom):
    vals=[str(n),fmt(row['OnlineSeconds']),fmt(row['GeometrySeconds']),fmt(row['AssemblySeconds']),
          fmt(row['ProjectionSeconds']),fmt(row['ReducedSolveSeconds'],1e6,2),fmt(row['ReconstructionSeconds'],1e3,3)]
    text.append('| '+' | '.join(vals)+' |')
text.append("""
Die Mediane einzelner Komponenten müssen sich nicht exakt zum Median der
Gesamtzeit addieren. Residuen, Cholesky-Diagnose und Energiefehler werden nach
der Online-Zeitmessung berechnet; sie sind Auswertungsdiagnostik.
Die isolierte reduzierte Lösung dauert nur ungefähr 22–25 µs, die ganze
ROM-Auswertung aber etwa 0,9 s. Die Assemblierung dominiert eindeutig.
Eine affine Zerlegung oder vorab projizierte Geometriekomponenten wurden
bewusst nicht behauptet oder implementiert.

Die gemeinsame Voll-FEM benötigt median **1,1887 s** pro Fall; das ergibt
nur etwa **1,28–1,33-fache** Beschleunigung durch den vollständigen ROM.
Die alte, fallweise vernetzte FEM hatte auf denselben Testfällen median
**1,3983 s**, ist aber eine andere Diskretisierung und ein anderer Messlauf.
POD_GP benötigt hier je nach Rang und N ungefähr 0,65–2,76 ms, RBF 24–50 µs,
MLP 7,65–11,48 ms. Für reine Online-Geschwindigkeit gewinnen die KI-Modelle.

## Offline-Kosten einschließlich zusätzlicher FEM-Daten

396 neue Snapshots kosteten zusammen **497,692 s**, einschließlich ihrer
Geometrie, Assemblierung, Voll-Lösung und Ausgabe. Die separate Mechanikprüfung
kostete 47,181 s. Snapshots werden zwischen N wiederverwendet; die folgenden
Summen sind die einem einzelnen Modell zurechenbaren Kosten, nicht sechsfach
tatsächlich neu berechnete Datensätze. Die sechs Validierungssnapshots kosten
gemeinsam 8,421 s; sechs Testsnapshots sind Bewertungskosten und nicht Training.

| N | Trainings-Snapshots [s] | Datenladen/Basis/Rangwahl [s] | Summe einschließlich Validierung [s] |
|---:|---:|---:|---:|
""")
for n,row in zip(counts,rom):
    text.append(f"| {n} | {fmt(row['TrainingSnapshotSeconds'],digits=3)} | {fmt(row['OfflineBasisAndSelectionSeconds'],digits=3)} | {fmt(offline(row),digits=3)} |")
text.append(f"""
Die Dateien nN/offline_costs.csv trennen Datenladen, SVD-Basisbildung und Rangwahl
nochmals. Die Rangwahl enthält die ausgeführten vollen Validierungsassemblierungen
für jeden Kandidaten. Bei KI werden die vorhandenen gemessenen Fit-/Auswahlkosten
und ursprünglichen FEM-Zeiten wiederverwendet; sie stammen aus früheren Läufen.
Diese Fit-Zeiten enthalten nicht den gemeinsamen Dateilade-Overhead des alten
Trainers. Mesh-/Beobachter-Erstellung sind einmalige Vorbereitungskosten und
wurden initial nicht separat getimt; sie sind nicht in den obigen Modellkosten.
Dies und Warmup, Cache sowie unterschiedliche Netze begrenzen exakte Kostenaussagen.

Unter dem expliziten Kostenmodell Trainings-FEM + Validierungs-FEM + Fit/Rangwahl
benötigt ROM12 **{fmt(offline(rom[0]),digits=2)} s**, während POD_GP384
**{fmt(offline(lookup[384,'POD_GP']),digits=2)} s** benötigt. Beide unterschreiten
auf diesem festen Testsatz Median 1 % und P95 3 %; der ROM liefert dabei das
genauere Feld. Sein niedrigerer Anfangsaufwand kann für wenige Abfragen günstiger
sein. Mit den gemessenen Online-Zeiten ergibt sich ein rein illustrativer
Kostenschnitt bei ungefähr **{stats['cost_crossover_queries_ROM12_vs_GP384']:.0f} Abfragen**:
danach holt der teurere Aufbau von POD_GP384 durch dessen schnelle Inferenz auf.
Das ist eine nachträgliche, testsatzabhängige Szenariorechnung mit historischen
Offline-Zeiten, keine belastbare allgemeine Amortisationsgrenze. Wenn die
KI-Modelle ohnehin bereits trainiert vorliegen, sind deren Offline-Kosten
versunken und ihre weitere Nutzung online wesentlich günstiger.

## Tatsächlich erfolgreiche Prüfungen

- Randbedingungen, freie DOF- und Knotenzuordnung, exakte Lastresultierende.
- Übereinstimmung Matrixlösung / solve(m): relativer Fehler 0 in diesem Lauf.
- Übereinstimmung mit nullspace-Assemblierung ohne doppelte Elimination: 0.
- Quadratische Auswertung gegen interpolateDisplacement: 2,46e-16.
- Doppelte Kraft: Skalierungsfehler 0; doppeltes E: 7,68e-12.
- Basis mit enthaltener Referenzlösung: relativer Reproduktionsfehler 1,78e-12.
- Symmetrie und positive Definitheit: voller Funktionstest sowie alle
  reduzierten Kandidaten/Testsysteme geprüft, erfolgreiche Cholesky-Zerlegung.
- Alle Trainings- und Validierungs-IDs und Modell-Seeds stimmen mit den
  eingefrorenen KI-Metadaten überein; alle Gitter und Quadraturgewichte identisch.
- 396 unterschiedliche physikalische Parameterzeilen über die disjunkten Splits.
- 42 Modell/Größen-Zusammenfassungen und 252 fallweise Vergleichszeilen.
- Alle neuen FEM-Snapshots haben endliche Lösungen und bestehen die freie
  Voll-FEM-Residuenprüfung. Alle Ausgabeprojektionen sind höchstens so fehlerhaft
  wie die tatsächliche Galerkin-Vorhersage.
- Originale KI-Feldmediane werden innerhalb 1e-12 reproduziert; 1084 Dateien
  der bisherigen Ergebnisse sind per SHA-256 unverändert.

Es wurde die eigene Funktion run_rom_study("checks") ausgeführt, keine
matlab.unittest-Suite. Ein Hinweis auf unreferenzierte Mittelknoten beim
linearen Such-Triangulationsobjekt ist harmlos: Die quadratischen Mittelknoten
werden anschließend über die tatsächlichen Elemente ausgewertet. Es gab keinen
MATLAB-Laufzeitfehler. Die statische Analyse meldete einen nicht benötigten
Initialwert einer Ergebnistabelle, keinen Syntaxfehler.

## Dateien, Diagramme und Wiederholung

- [Vergleichstabelle](comparison.csv): alle Feld-, Skalar-, Zeit- und Offline-Kennzahlen.
- [Fallweise Kennzahlen](per_case.csv): auch Residuen, Energie und Projektionsfehler.
- [Schlechteste Fälle](worst_cases.csv): Fall-ID und verwendete Fehlerdefinition.
- [Netzabweichung und FEM-Kosten](mesh_discrepancy_and_cost.csv): alle 396 Fälle.
- [Feldfehler](field_error.png), [gesamte Online-Zeit](online_time.png),
  [Basis-/Auswahlkosten](offline_cost.png), [Offline inklusive FEM](offline_total.png),
  [gewählte Ränge](pod_rank.png), [Projektion gegen Galerkin](projection_vs_rom.png).
- protocol.mat: tatsächliches Referenznetz, freie DOFs, Auswertematrix,
  Konfiguration und MATLAB-Version. Diese gespeicherten Arrays verwenden;
  ein erneutes generateMesh muss nicht bitidentische Daten erzeugen.
- nN/model.mat, validation_selection.csv, offline_costs.csv,
  online_timing_samples.csv, test_predictions.mat: eingefrorene Modelle und Rohwerte.
- snapshots/: gemeinsame nodale Voll-FEM-Lösungen samt Parametern, IDs und Zeiten.
- source_designs/: ursprüngliche Designs und Protokolle einschließlich Seeds.
- source_snapshot_final/: ausgeführter Quellstand; source_snapshot/: früher
  archivierter Entwicklungsstand des Mechaniktests.
- events.csv, logs/, checks.mat und die Verifikationsdateien: tatsächliche
  Ausführung und Assertions. Die ersten sechs Validierungssnapshots und der
  Mechaniktest liegen zeitlich vor Einführung des Journal-Wrappers; ihre
  Messwerte sind in den Snapshot-Dateien beziehungsweise checks.mat gespeichert.
- protected_original_files.json / preservation_check.txt: alte Dateien erhalten.
- artifact_hashes.json: finale Artefakthashes; build_report.py erzeugt diesen
  Bericht erneut aus den gespeicherten Resultaten.

Numerische Schritte im Projektordner: run_rom_study("prepare"), "checks",
"validation", "snapshots" mit Start/Endindex, "fit" mit N für alle sechs Größen,
dann "testdata", "evaluate" mit N und "summarize". run_rom_logged führt dieselben
Schritte mit Protokollierung aus. Vorhandene Modelle und Auswertungen sind gegen
Überschreiben geschützt; Snapshot-Blöcke lassen sich fortsetzen. Für einen
neuen Versuch einen neuen Ausgabeordner im Runner festlegen.

Ein vorhandenes ROM kann direkt ohne erneutes Training verwendet werden:

```matlab
addpath('src')
out = fullfile(pwd,'experiments','pod_galerkin_20261023_v1');
p = load(fullfile(out,'protocol.mat'),'mesh');
a = load(fullfile(out,'n12','model.mat'),'model');
x = [.9 .08 .11 140e9 .30 -550]; % L,b,h,E,nu,Fz in SI
[H,y,u,timing] = rom_predict(p.mesh,a.model.V,x);
```

H enthält das Feld im bisherigen Ausgabeformat, y die Spitzenverschiebung und
das Gittermaximum, u die freien nodalen Freiheitsgrade. Die Geometrie wird online
neu abgebildet und die volle Matrix assembliert; ein Regressor ist nicht beteiligt.

Die abschließende Diagrammformatierung wurde durch erneutes summarize erzeugt;
keine Basisbildung, Rangwahl oder Testvorhersage wurde dafür wiederholt.

## Einschränkungen und Entscheidung

Der klassische ROM ist hier **datensparsam und für Verschiebungsfelder genau**,
aber durch die vollständige Assemblierung **kein schnellerer KI-Ersatz**.
Er ist interessant, wenn die Mechanik verfügbar ist und man mit wenigen
Trainings-FEM-Fällen genaue Felder benötigt. Für sehr viele Abfragen oder nur
einzelne skalare Größen sind die vorhandenen KI-/Balkenkorrekturmodelle günstiger.

Es bleiben: kleiner und bereits bekannter Testsatz, nur eine Designreihe/ein
Modell-Seed, gemeinsame statt identische FEM-Netze, keine Konvergenzstudie,
homogene Einspannung, lineare Statik und dieselbe Quaderfamilie. Keine Aussagen
zu neuen Topologien, Nichtlinearität, Dynamik, Spannungsmaxima oder Extrapolation.
Das vollständige freie Residuum ist trotz kleiner Ausgabefehler nicht null.
Eine affine/hyperreduzierte Assemblierung wäre eine getrennte Untersuchung;
für die geometrischen Parameter wurde hier keine unbelegte Zerlegung angenommen.

Offizielle API-Grundlagen: [fegeometry](https://www.mathworks.com/help/pde/ug/fegeometry.html)
und [assembleFEMatrices](https://www.mathworks.com/help/pde/ug/assemblefematrices.html).
Die Syntax wurde zusätzlich mit der lokalen R2025b-Hilfe geprüft.
""")
(folder / "REPORT.md").write_text("\n".join(text), encoding="utf-8")
print(folder / "REPORT.md")
