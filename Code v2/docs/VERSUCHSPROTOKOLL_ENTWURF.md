# Versuchsprotokoll – Entwurf für FEM-Ersatzmodelle

**Version:** 0.1  
**Status:** Entwurf; vor dem ersten Modelllauf abzustimmen  
**Geltungsbereich der ersten Stufe:** statische Verschiebungsfelder eines
einseitig eingespannten Balkens  
**Erste Modellfamilie:** direktes MLP

Dieses Protokoll trennt einen gemeinsamen Vergleichskern von späteren
Modulabschnitten für POD-MLP, DeepONet und weitere Verfahren. Die Ein- und
Ausgabeform sowie die gemeinsamen Metriken sollen für alle Modellmodule gleich
bleiben. Modellabhängige Vorverarbeitung, Architektur und Trainingsparameter
werden je Modul vor dessen Läufen festgelegt.

## 1. Ziel und Forschungsfragen

Die erste Stufe untersucht, wie genau ein direktes MLP statische FEM-
Verschiebungsfelder für bisher nicht zum Modellfit verwendete Balkenparameter
vorhersagt. Sie soll außerdem zeigen, wie empfindlich die Ergebnisse gegenüber
Trainings-Seed und verfügbarer Trainingsfallzahl sind.

Fragen:

1. Wie genau approximiert das MLP die FEM-Verschiebungsfelder im festgelegten
   Parameterbereich?
2. Wie unterscheiden sich die Fehler räumlich und zwischen den drei
   Verschiebungskomponenten?
3. Wie stark streuen die Ergebnisse zwischen Seeds und Validierungsfällen?
4. Wie verändert sich der Fehler mit der Zahl der Trainingsfälle?
5. Sind ausgewählte FEM-Ergebnisse mit einer analytischen
   Euler-Bernoulli-Balkennäherung plausibel?

Die Frage 5 ist eine Prüfung der Referenzrechnung. Sie ist nicht mit der Frage
gleichzusetzen, wie gut das MLP FEM-Daten reproduziert.

## 2. Untersuchungsgegenstand und Daten

### 2.1 Erste Stufe: Statik

Eingaben pro Fall sind die sechs Parameter
`[L_m, b_m, h_m, E_Pa, nu, Fz_N]`. Zielgröße ist das statische
Verschiebungsfeld auf dem gemeinsamen normierten `21 × 5 × 5`-Referenzgitter.
Die drei Komponenten `ux`, `uy` und `uz` liegen blockweise vor; das vollständige
Feld hat 1575 Werte pro Fall in Metern.

Der aktuelle Hauptdatensatz sieht 384 Trainings-, 12 Validierungs- und
64 Testfälle vor. Die Fall-IDs und Splits stehen im jeweiligen `design.csv`.
Die Testdateien sind bereits vorhanden. Vor einem Abschlusstest ist daher
festzustellen und zu dokumentieren, ob Testlabels bereits eingesehen oder für
Modellentscheidungen verwendet wurden. Bis dahin werden sie nicht für Auswahl,
Anpassung oder Fehleranalyse herangezogen.

### 2.2 Datenrollen

- **Fit-Daten:** bestimmen Modellparameter und jede gelernte Vorverarbeitung.
- **Validierungsdaten:** dienen ausschließlich der vorab festgelegten
  Kandidatenauswahl und Diagnostik.
- **Testdaten:** werden erst nach dem Freeze von Modellen, Konfigurationen und
  Auswahlregel einmalig für die Abschlussbewertung verwendet.

Normierung, Mittelwerte und alle sonstigen datenabhängigen Transformationen
werden ausschließlich aus dem jeweiligen Fit-Anteil bestimmt. Testlabels sind
kein Ersatz für Validierungsdaten.

## 3. Referenzprüfung: FEM gegen analytische Balkennäherung

Vor der Modellbewertung wird eine Plausibilitätsprüfung für ausgewählte
statische Größen durchgeführt. Als analytische Vergleichsgröße dient die
Durchbiegung entlang der Balkenachse auf der neutralen Achse sowie die
Spitzendurchbiegung.

Für einen Euler-Bernoulli-Kragbalken mit einer äquivalenten Querkraft `Fz` am
freien Ende gilt im linearen Kleinverformungsbereich:

```text
uz(x) = Fz * x^2 * (3*L - x) / (6*E*Iy)
Iy    = b * h^3 / 12
uz(L) = Fz * L^3 / (3*E*Iy)
```

`x` wird von der Einspannung aus gemessen. Das Vorzeichen folgt der im
FEM-Modell verwendeten Lastkonvention. Die FEM belastet die Stirnfläche mit
gleichmäßiger Traktion; deren Resultierende ist die für die Balkennäherung
verwendete Endkraft.

Der Vergleich ist auf die passenden Gitterpunkte der neutralen Achse
beschränkt. Berichtet werden:

- FEM- und analytische Spitzendurchbiegung in Metern,
- absoluter und relativer Unterschied der Spitzendurchbiegung,
- absoluter und relativer Fehler entlang der verglichenen Achsenpunkte,
- Parameter und Annahmen des jeweiligen Falls.

Die Balkentheorie ist eine eindimensionale Näherung und muss nicht mit dem
vollständigen dreidimensionalen FEM-Feld übereinstimmen. Abweichungen werden
fachlich eingeordnet und nicht automatisch als FEM-Fehler gewertet.

Die konfigurierte FEM-Netzfeinheit ist durch ihre bloße Angabe nicht als
konvergiert belegt. Ein Netzkonvergenzvergleich an vorab festgelegten
repräsentativen Fällen ist als eigene Referenzprüfung vorzusehen. Fälle,
Netzstufen und Rechenbudget sind vor deren Berechnung zu protokollieren; diese
Prüfung ist nicht Teil einer bereits durchgeführten Auswertung.

## 4. Modellmodul A: direktes MLP

Das direkte MLP erhält die sechs Eingabeparameter und sagt das vollständige
statische Feld im vereinbarten Format voraus. Die Ausgabe wird in physikalische
Einheiten zurücktransformiert und über `surrogate-v1` bereitgestellt.

Vor dem ersten Kandidatenlauf sind mindestens festzulegen und einzufrieren:

- Kandidatenarchitekturen und Aktivierungsfunktion,
- Eingabe- und Ausgabenormierung,
- Verlustfunktion und etwaige Komponenten-/Punktgewichtung,
- Optimierer, Lernrate und weitere Trainingsparameter,
- Epochen- oder Iterationsbudget sowie Abbruchregel,
- Seed-Liste und Umgang mit fehlgeschlagenen Läufen,
- Auswahlmetrik und Gleichstandsregel.

Die Modellkonfiguration darf nicht anhand der Testfehler angepasst werden.

## 5. Validierung und Modellauswahl

Die zwölf vorhandenen Validierungsfälle sind eine kleine Stichprobe. Für die
Auswahl zwischen MLP-Kandidaten wird daher als Entwurf eine vorab festgelegte
dreifache Kreuzvalidierung innerhalb der 384 Trainingsfälle vorgeschlagen:

- dieselben drei Folds für alle MLP-Kandidaten,
- je Fold 256 Fit-Fälle und 128 äußere Validierungsfälle,
- keine doppelten Parameterkombinationen über Fold-Grenzen,
- alle datenabhängigen Transformationen ausschließlich aus den 256
  Fit-Fällen,
- der äußere Fold wird nicht zum Early Stopping oder zur Vorverarbeitung
  verwendet.

Die Folds und Seeds müssen vor dem ersten Kandidatenlauf gespeichert werden.
Die Kreuzvalidierung dient der Auswahl und ist kein unabhängiger
Abschlusstest. Nach der Auswahl wird die festgelegte Konfiguration mit
festgelegten Seeds auf allen 384 Trainingsfällen neu trainiert.

Falls diese Strategie für das verfügbare Zeit- oder Rechenbudget ungeeignet ist,
muss vor den Kandidatenläufen eine Alternative mit Begründung und geringerer
Aussagekraft dokumentiert werden.

## 6. Welche Größen werden verglichen?

### 6.1 Hauptvergleich: MLP-Vorhersage gegen FEM-Referenz

Verglichen wird auf denselben Fällen und denselben Gitterpunkten:

| Größe | Vergleich und Einheit | Zweck |
|---|---|---|
| Vollständiges Verschiebungsfeld `ux, uy, uz` | MLP gegen FEM; Feldwerte in m | Primäre Bewertung der gesamten Feldvorhersage |
| Gewichteter relativer Feldfehler je Fall | dimensionslos | Primäre Genauigkeitsmetrik |
| Absoluter gewichteter Feldfehler je Fall | m gemäß Referenzgewichten | Ergänzung, insbesondere bei kleinen Referenznormen |
| Fehler je Komponente `ux`, `uy`, `uz` | absolut und relativ, komponentenweise | Erkennen, ob eine Komponente den Gesamtfehler dominiert |
| Punktweise absolute Abweichung | m, räumlich auf dem Gitter | Erkennen räumlicher Fehlerbereiche |
| Spitzendurchbiegung am freien Ende | MLP gegen FEM, in m; absoluter und relativer Fehler | Verständliche technische Kennzahl |
| Verschiebung an der Einspannung | MLP gegen den erwarteten Nullwert, in m | Randbedingungsdiagnostik |

Die primäre Feldmetrik ist der bereits implementierte gewichtete relative
Feldfehler:

```text
e_rel = sqrt(sum(w .* (u_MLP - u_FEM).^2))
        / sqrt(sum(w .* u_FEM.^2))
```

`w` sind die vertraglich festgelegten Referenzgewichte. Zusätzlich wird der
Zähler der Formel als absoluter gewichteter Feldfehler berichtet. Ein
Referenzschwellwert für sehr kleine Nenner muss vor der Auswertung festgelegt
werden. Relative Fehler unterhalb dieses Schwellwerts werden als undefiniert
markiert, nicht als null ersetzt.

Für jede Metrik werden Fallwerte gespeichert. Zusammenfassungen enthalten
Mittelwert, Median, nearest-rank-P95 und Maximum. Zusätzlich werden Ergebnisse
je Fold und je Seed sowie die Streuung zwischen Seeds getrennt von der
Streuung zwischen Fällen ausgewiesen. Seeds sind keine zusätzlichen
unabhängigen physikalischen Fälle.

### 6.2 Referenzvergleich: FEM gegen Balkentheorie

Dieser Vergleich wird getrennt vom MLP-Ergebnis berichtet:

- FEM gegen analytische Durchbiegung auf der ausgewählten neutralen Achse,
- FEM- gegen analytische Spitzendurchbiegung,
- absolute und relative Abweichung mit dokumentierten Modellannahmen.

Er beantwortet, ob ausgewählte FEM-Ausgaben zur Balkennäherung plausibel sind;
er ersetzt keine Prüfung des vollständigen 3D-Feldes.

### 6.3 Rechenaufwand

Je Modellvariante werden getrennt erfasst:

- Trainingszeit pro Lauf,
- Vorhersagezeit pro Fall und für eine festgelegte Batchgröße,
- Iterationen/Epochen, verfügbare Auswertungszähler und Abbruchgrund,
- Hardware, MATLAB-/Toolbox-Version und Messbedingungen.

FEM-Zeit wird nur dann direkt gegenübergestellt, wenn Messumfang und
Bedingungen nachvollziehbar und vergleichbar sind. Eine Amortisationsrechnung
wird nicht aus ungleichen historischen Zeitmessungen abgeleitet.

## 7. Trainingsdatenumfang und Lernkurven

Der Einfluss der Trainingsfallzahl wird als eigene Untersuchung ausgewertet.
Als Entwurf werden verschachtelte Teilmengen von **32, 64, 128 und 256 Fällen**
innerhalb jedes Fit-Folds vorgeschlagen. Die Fall-IDs je Teilmenge werden
gespeichert und für alle Modellkandidaten identisch verwendet. Jede Größe wird
mit denselben vorab festgelegten Seeds trainiert.

Der abschließende Fit mit allen 384 Trainingsfällen ist die nach der
Kandidatenauswahl trainierte Bereitstellungskonfiguration, nicht ein zusätzlicher
Kreuzvalidierungs-Fit. Aus einer einzelnen Trainingsgröße oder einem einzelnen
Testlauf wird keine Mindestzahl benötigter Referenzfälle abgeleitet.

## 8. Laufprotokoll und Umgang mit Änderungen

Jeder Versuch erhält eine eindeutige Lauf-ID. Eine maschinenlesbare Tabelle
erfasst mindestens:

- Modellmodul, Architektur, Optimierer und Hyperparameter,
- Fold, Seed, Trainingsfallzahl und verwendete Fall-IDs,
- Code-, Daten- und Konfigurationskennung,
- Startzeit, Laufzeit, Status und Abbruchgrund,
- Vorverarbeitung und gegebenenfalls POD-Rang,
- Fallmetriken und Pfad zu Modell- und Verlaufsartefakten.

Zulässige Laufstatus: `geplant`, `laufend`, `abgeschlossen`,
`fehlgeschlagen` und `abgebrochen`. Fehlgeschlagene Läufe bleiben in der
Auswertungstabelle sichtbar.

Ergänzungen für POD-MLP, DeepONet oder weitere Verfahren erhalten jeweils einen
eigenen, datierten Protokollabschnitt. Der gemeinsame Kern der Datenrollen,
Ausgabegrößen, Metriken und Testdisziplin bleibt bestehen. Änderungen nach
Beginn eines Versuchs werden datiert und begründet und nicht als vorab geplant
dargestellt.

## 9. Spätere Module

- **POD-MLP:** gleiche statische Ausgabefelder und Hauptmetriken. POD-Basis und
  Skalierung werden ausschließlich aus dem jeweiligen Fit-Fold bestimmt.
  Zusätzlich wird der POD-Projektionsfehler berichtet, um Reduktions- und
  Netzfehler auseinanderzuhalten.
- **DeepONet:** gleiche Feldwerte am vereinbarten Referenzgitter; die interne
  Verarbeitung von Parameter- und Ortskoordinaten ist modellspezifisch.
- **Modalmodelle:** separates Protokollmodul für die sechs Eigenfrequenzen in
  Hz. Verglichen werden absolute und relative Fehler pro Frequenzposition und
  Fall. Eine analytische Zuordnung der sortierten Frequenzpositionen zu
  Biegemoden muss vor einem Vergleich mit Balkenformeln festgelegt werden.

Diese späteren Module sind nicht Bestandteil der ersten MLP-Auswertung und
werden nicht rückwirkend als in Modul A enthalten dargestellt.

## 10. Offene Punkte vor Freigabe

1. Wurden die vorhandenen Testlabels bereits eingesehen oder für Entscheidungen
   verwendet?
2. Werden die vorgeschlagenen drei Folds und Seeds verwendet, und wie werden
   die Fall-IDs reproduzierbar zugeordnet?
3. Welche MLP-Architekturen, Aktivierung, Verlustfunktion und Trainingsbudgets
   werden tatsächlich verglichen?
4. Welcher Referenzschwellwert gilt für den relativen Feldfehler?
5. Welche Fälle und Netzstufen umfasst die FEM-Konvergenzprüfung?
6. Ist der Zeitrahmen ausreichend für die Lernkurven und Seeds?

Bis diese Punkte entschieden sind, bleibt dieses Dokument ein Entwurf und
autorisiert weder neue FEM-Berechnungen noch Modellläufe oder die Auswertung
der vorhandenen Testlabels.
