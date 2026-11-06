# FEM-Referenzvalidierung – Protokoll

**Studien-ID:** `fem_reference_validation_v1`  
**Protokollversion:** 1.0  
**Stand:** 2026-11-01  
**Status:** vorab festgelegt; FEM-Ausführung noch ausstehend  
**Geltungsbereich:** Plausibilitätsprüfung statischer FEM-Felder und
Eigenfrequenzen sowie begrenzte Netzkonvergenzdiagnose  
**Datenschutz der Splitrollen:** ausschließlich vorhandene Trainingsfälle;
Validierungs- und Testlabels werden nicht gelesen

Dieses Protokoll wird vor den zusätzlichen FEM-Läufen gespeichert. Eine
Änderung nach Beginn der Läufe erfordert eine datierte Begründung und darf nicht
als ursprünglich geplant dargestellt werden.

## 1. Ziel

Prüfen, ob ausgewählte statische Verschiebungen und modale Eigenfrequenzen aus
dem Code-v2-FEM-Modell mit vereinfachten analytischen Balkenmodellen
physikalisch plausibel sind. Zusätzlich wird an einer kleinen, vorab festgelegten
Stichprobe untersucht, wie sich die FEM-Ergebnisse bei Netzverfeinerung ändern.

Das ist eine Referenzprüfung, kein Ersatzmodellvergleich und kein allgemeiner
Beweis der FEM-Konvergenz. Eine Übereinstimmung mit der Balkentheorie ist wegen
der unterschiedlichen Modellannahmen nicht für alle dreidimensionalen
Feldkomponenten zu erwarten.

## 2. Eingefrorene Daten und Auswahl

Als Datenquelle dient `data_generation/data`; bestehende Dateien werden nur
gelesen und nicht verändert. Für die analytische Statikprüfung werden alle 384
Fälle aus dem statischen Trainingssplit verwendet. Für eine zusätzliche
frequenzbasierte Modaldiagnostik werden die sechs gespeicherten Frequenzen aller
384 modalen Trainingsfälle gelesen.

Für Netzverfeinerung und Modenformzuordnung werden je Berechnungsart drei
Trainingsfälle festgelegt. Auswahlregel: Fälle im Trainingsdesign nach `L/h`
sortieren und die Elemente an den nullbasierten Indizes
`round(q*(384-1))` für `q = [0.1, 0.5, 0.9]` auswählen.

| Aufgabe | Quantil von `L/h` | Fall-ID | `L/h` |
|---|---:|---:|---:|
| Statik | 0.1 | 810360 | 5.8502 |
| Statik | 0.5 | 810164 | 8.2215 |
| Statik | 0.9 | 810447 | 11.3622 |
| Modal | 0.1 | 910349 | 5.6681 |
| Modal | 0.5 | 910037 | 8.2073 |
| Modal | 0.9 | 910159 | 11.7511 |

Die Auswahl nutzt keine Validierungs- oder Testparameter beziehungsweise
-labels. Die Fall-IDs werden beim Lauf nochmals gegen `design.csv` geprüft.

## 3. Analytische Statikprüfung

Für jeden statischen Trainingsfall werden FEM und Balkentheorie an den
Gitterpunkten der Balkenmittelachse (`y=0`, `z=h/2`) verglichen. Die Querachse
verläuft von der Einspannung bei `x=-L/2` bis zum freien Ende bei `x=L/2`;
die lokale Balkenkoordinate ist `s=x+L/2`.

Für die Endkraft `Fz`, Querschnitt `A=b*h`, Flächenträgheitsmoment
`Iy=b*h^3/12` und Schubmodul `G=E/(2*(1+nu))` werden zwei Modelle berechnet:

```text
w_EB(s) = Fz*s^2*(3*L-s)/(6*E*Iy)
w_T(s)  = w_EB(s) + Fz*s/(kappa*G*A)
kappa   = 5/6
```

`w_EB` ist die Euler-Bernoulli-Näherung; `w_T` ergänzt die
Timoshenko-Schubverformung. Die FEM-Stirnfläche erhält eine gleichmäßige
Traktion mit Resultierender `Fz`. Das Vorzeichen bleibt entsprechend der
FEM-Lastkonvention erhalten.

Berichtet werden pro Fall und Theorie:

- absolute und relative Abweichung der Spitzendurchbiegung,
- RMS-Abweichung entlang der Mittelachse und deren Verhältnis zur RMS-Norm der
  analytischen Kurve,
- Fallparameter und Kennzeichnung, ob die relative Norm definiert ist.

Die Achsenprüfung ist der analytischen Vergleich. Sie behauptet keine
dreidimensionale Feldgleichheit. Die Mittelachsenwerte werden aus dem
vereinbarten statischen Feldgitter gelesen; es wird nicht über das Gitter
hinaus extrapoliert.

## 4. Analytische Modaldiagnostik

Die analytische Euler-Bernoulli-Balkentheorie liefert für jede der beiden
Querschnittsbiegerichtungen eine Frequenzfamilie:

```text
f_n = beta_n^2/(2*pi*L^2) * sqrt(E*I/(rho*A))
```

Für Biegung in `z` gilt `I=b*h^3/12`; für Biegung in `y` gilt
`I=h*b^3/12`. Verwendete dimensionslose Eigenwerte sind
`beta = [1.8751040687, 4.6940911330, 7.8547574382]`.

Die vorhandenen Modal-Splitdateien enthalten nur sechs sortierte Frequenzen,
keine Modenformen. Für alle 384 Trainingsfälle werden daher die beiden
analytischen Grundfrequenzen und die sechs FEM-Frequenzen gemeinsam
protokolliert. Der jeweils nächste Frequenzwert wird als **reine
Frequenznähe-Diagnostik** ausgegeben; ohne Modenform ist das keine gesicherte
Modenzuordnung und kein alleiniger Gütenachweis.

Für die sechs festgelegten Modal-Trainingsfälle werden die FEM-Modenformen mit
den Netzverfeinerungsläufen erneut berechnet. Ihre Verschiebungsfelder auf dem
gemeinsamen Referenzgitter werden mit analytischen Euler-Bernoulli-Modenformen
über die gewichtete Modal Assurance Criterion (MAC) verglichen. Eine Zuordnung
wird nur als belastbar markiert, wenn `MAC >= 0.70`; die übrigen Modi bleiben
explizit unzugeordnet. Die Frequenzabweichung wird nur für zugeordnete Modi
berichtet.

## 5. Netzkonvergenz

Für die sechs festgelegten Fälle werden statische und modale FEM-Lösungen mit
`meshDivisor = [3, 4, 6]` erneut berechnet. Ein größerer Divisor erzeugt über
`Hmax=min(b,h)/meshDivisor` ein feineres Netz. Das umfasst höchstens 18
zusätzliche FEM-Läufe. Vorhandene Ergebnisdateien werden nicht überschrieben.

Statische Ergebnisse werden auf demselben Referenzgitter verglichen. Berichtet
werden die gewichtete relative Differenz der vollständigen Felder und die
relative Änderung der Spitzendurchbiegung zwischen aufeinanderfolgenden Netzen
3→4 und 4→6.

Modale Ergebnisse werden über die ersten sechs Moden mit einer eindeutigen,
greedy MAC-Zuordnung zwischen benachbarten Netzstufen gepaart. Pro Paar werden
MAC, Frequenzen und relative Frequenzänderung ausgegeben. Niedrige MAC-Werte
oder mehrdeutige Zuordnungen werden als Einschränkung ausgewiesen. Eine
monotone Abnahme der Fehler wird nicht vorausgesetzt.

Diese sechs Fälle sind eine begrenzte Diagnose über ausgewählte
Schlankheitsverhältnisse, kein mathematischer Konvergenzbeweis für den gesamten
Parameterraum.

## 6. Ergebnisdateien und Wiederaufnahme

Der Runner liegt unter `scripts/run_validation.m`. Er wird mit einem expliziten
Modus aufgerufen:

```matlab
run_validation("analysis")  % nur bestehende Trainings-Splits lesen
run_validation("mesh")      % nur die vorab festgelegten FEM-Netzläufe
run_validation("all")       % Analyse, danach Netzverfeinerung
```

Ergebnisse liegen ausschließlich unter `results/`. Erwartet werden
maschinenlesbare CSV- und MAT-Dateien, Laufmetadaten und eine Zusammenfassung.
Jeder FEM-Fall/Netzlauf wird separat gespeichert. Eine passende vorhandene
Laufdatei wird übersprungen; eine widersprüchliche Datei führt zum Abbruch.
Fehlgeschlagene FEM-Läufe werden mit Fall-ID, Netzstufe, Fehlerkennung und
Meldung protokolliert und nicht als erfolgreich gezählt.

Der Lauf dokumentiert MATLAB-/PDE-Version, Betriebssystem-/CPU-Angaben,
Git-Commit, Konfigurations- und Quellcode-Prüfsummen sowie die verwendeten
Trainingsdateien. Ein geänderter Code- oder Konfigurationsstand darf nicht
stillschweigend mit vorhandenen Studienergebnissen vermischt werden.

## 7. Grenzen und Interpretation

- Die analytischen Balkenmodelle sind eindimensional und bilden nicht alle
  dreidimensionalen Spannungs-, Querkontraktions- und Endeffekte der FEM ab.
- Die Timoshenko-Lösung ergänzt die Schubdurchbiegung, ersetzt aber ebenfalls
  keine 3D-Referenz.
- Die Frequenznähe in den vorhandenen Modal-Splits ist ohne Modenformen keine
  eindeutige Modenidentifikation.
- MAC-Zuordnungen aus nur sechs ausgewählten Parameterfällen belegen keine
  allgemeine Modentreue über den gesamten Datenbereich.
- Diese Studie verwendet keine Testlabels und wählt keine neuronale
  Modellvariante aus.
- Die Studie beurteilt die FEM-Referenz für den angegebenen Modellbereich; sie
  belegt nicht automatisch, dass ein späteres Surrogat die FEM ausreichend
  genau approximiert.

## Datierte Erweiterung: übrige statische Fälle (2026-11-06)

Vor der zusätzlichen Auswertung wurde der Umfang festgelegt: geprüft werden
die 384 nach der ursprünglichen Studie ergänzten statischen Trainingsfälle
sowie alle 12 statischen Validierungs- und 64 Testfälle. Zusammen sind das
460 Fälle, die nicht in der ursprünglichen analytischen Statikprüfung mit 384
Trainingsfällen enthalten waren. Die 384 ursprünglichen Trainingsfälle
werden nicht erneut berechnet; ihre gespeicherten Ergebnisse bleiben
unverändert und dienen nur für eine getrennt ausgewiesene Gesamtübersicht.

Die gleiche eindimensionale Mittelachsen- und Spitzendurchbiegungsprüfung
gegen Euler-Bernoulli und Timoshenko wird verwendet. Es werden ausschließlich
vorhandene FEM-Datendateien gelesen; es gibt keine neuen FEM-Läufe, keine
POD-MLP-Auswertung und keine Modellauswahl. Für diese zusätzliche
physikalische Referenzprüfung werden die Verschiebungsfelder der
Validierungs- und Test-Splits ausdrücklich gelesen. Die Prüfung ist daher
keine unabhängige Surrogat-Testauswertung und darf nicht zur Auswahl oder
Anpassung eines POD-MLP verwendet werden.

Die separate Implementierung ist
`scripts/run_remaining_static_validation.m`; Ergebnisse werden in einem
eigenen Unterordner `results/remaining_static_20261106/` gespeichert. Die
Ergebnisdateien der ursprünglichen `fem_reference_validation_v1`-Studie
werden nicht überschrieben.
