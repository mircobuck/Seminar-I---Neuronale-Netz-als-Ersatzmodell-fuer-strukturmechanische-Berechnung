# Unabhängige Bestätigungsstudie für statische FEM-Ersatzmodelle

**Stand:** 26. Oktober 2026  
**Projekt:** MATLAB_FEM_Start  
**Untersuchung:** 64 neue Parameterfälle für einen einseitig eingespannten Balken

## Kurzfassung

Die Studie prüft, ob der auf Entwicklungsdaten beobachtete Vorteil eines hybriden Balken-POD-GPR-Modells auch auf zuvor nicht betrachteten Fällen auftritt. Das Hybridmodell erreichte über die 64 neuen Fälle einen mittleren relativen gewichteten Verschiebungsfeldfehler von **0,2383 %**. Das reine Balkenfeld erreichte **0,6892 %**, das direkte normalisierte POD-GPR **22,4462 %**.

Fallweise war das Hybridmodell 61-mal genauer als das Balkenfeld und dreimal ungenauer. Gegenüber dem direkten Modell war es in 63 Fällen genauer. Der neue Test stützt damit den beobachteten Vorteil für diese Geometrie, den untersuchten Parameterbereich und die vorgegebene Lastform. Er belegt keine garantierte Genauigkeit auf anderen Körpern oder Lastfällen.

Die 64 Fälle wurden vor der FEM-Berechnung festgelegt. Alle FEM-Referenzen wurden erfolgreich berechnet. Die beiden zuvor trainierten Modellartefakte blieben unverändert; ihre Prüfsummen wurden vor und nach dem Lauf kontrolliert. Die Fälle wurden inzwischen für diesen Vergleich verwendet und sind für spätere Modellentwicklung kein unberührter Testsatz mehr.

## 1. Forschungsfrage und untersuchte Verfahren

Ein detailliertes Finite-Elemente-Modell (FEM) löst die mechanischen Gleichungen auf einem räumlichen Netz. Für viele Parameterkombinationen kann dies zeitaufwendig sein. Ein Ersatzmodell wird anhand früherer FEM-Ergebnisse aufgebaut und soll anschließend neue Fälle schneller annähern.

Verglichen wurden drei Verfahren für **dieselbe Ausgabe**, das dreidimensionale statische Verschiebungsfeld:

1. **Balkenfeld:** ein physikalisches Euler-Bernoulli-Modell ohne trainierte Korrektur.
2. **Direktes normalisiertes POD-GPR:** ein aus FEM-Feldern trainiertes datengetriebenes Modell.
3. **Normalisiertes hybrides Balken-POD-GPR:** ein Balkenfeld plus eine aus FEM-Balken-Differenzen gelernte Korrektur.

Die Untersuchung betrifft einen parametrischen Quader als Balken. Eine Übertragung auf einen Elektromotor oder auf andere Geometrien und Lastverteilungen wurde nicht untersucht.

## 2. Physikalisches Referenzproblem

Der Quader besitzt Länge L, Breite b und Höhe h. Die linke Stirnfläche ist vollständig eingespannt. Auf die rechte Stirnfläche wirkt eine gleichmäßig verteilte Last mit der resultierenden Kraft Fz in negativer z-Richtung. Das Material ist homogen, isotrop und linear elastisch; vorausgesetzt werden kleine Verformungen.

| Parameter | Bereich | Einheit |
|---|---:|---|
| Länge L | 0,6–1,2 | m |
| Breite b | 0,06–0,10 | m |
| Höhe h | 0,08–0,14 | m |
| Elastizitätsmodul E | 70–210 | GPa |
| Querkontraktionszahl ν | 0,25–0,35 | dimensionslos |
| Stirnlast Fz | −1000 bis −100 | N |

Das diskrete statische Problem lautet

$$K(\mu)u(\mu)=f(\mu),$$

wobei K die Steifigkeitsmatrix, u die Verschiebungen, f den Lastvektor und μ die Parameter bezeichnet. Die Referenzroutine verwendet quadratische Tetraederelemente und die Netzregel Hmax = min(b,h)/3. Die Verschiebungen werden auf ein gemeinsames normiertes Gitter mit 21 × 5 × 5 = 525 Punkten interpoliert. Die 1.575 Feldwerte sind komponentenweise angeordnet: zunächst alle ux-, dann uy- und schließlich uz-Werte. Das gemeinsame Gitter erlaubt den Vergleich auf denselben räumlichen Punkten.

Die Einspannung wird im FEM-Modell vorgegeben und im gemeinsamen Referenzfeld zusätzlich auf null gesetzt. Die Spitzenverschiebung ist die z-Komponente am Mittelpunkt der freien Stirnfläche.

## 3. Aufbau und Mathematik der Modelle

### 3.1 Physikalisches Balkenfeld

Die Euler-Bernoulli-Theorie beschreibt die Biegung eines schlanken Balkens. Sie berücksichtigt die Durchbiegung und die mit der Biegung verbundene Querschnittsrotation. Die implementierte Näherung berücksichtigt weder Schubverformung noch Querschnittsverwölbung; die uy-Komponente wird zu null angenommen. Das Modell benötigt online Geometrie, Material und Last, aber keine FEM-Lösung des neuen Falls.

### 3.2 Proper Orthogonal Decomposition und Gaußprozessregression

Die Proper Orthogonal Decomposition (POD) zerlegt viele Trainingsfelder in einen Mittelwert und wenige wiederkehrende räumliche Muster. Ein Feld wird näherungsweise als

$$u \approx \bar u + \Phi a$$

geschrieben. Dabei ist Φ die POD-Basis und a ein kurzer Vektor von Koeffizienten. Der POD-Rang bestimmt, wie viele Muster verwendet werden. Ein kleiner Projektionsfehler bedeutet, dass ein bekanntes Feld mit der Basis gut dargestellt werden kann. Er bedeutet nicht automatisch, dass sich seine Koeffizienten aus neuen Parametern auch gut vorhersagen lassen.

Die Gaußprozessregression (GPR) lernt den Zusammenhang zwischen Parametern und POD-Koeffizienten. Ein Kernel beschreibt die angenommene Ähnlichkeit zweier Parameterkombinationen. Die in dieser Studie verwendeten eingefrorenen Modelle nutzen den ARD-Squared-Exponential-Kernel; ARD bezeichnet separate Längenmaßstäbe für die Eingabeparameter.

### 3.3 Physikalische Normierung und Hybridkorrektur

Die untersuchte lineare Statik besitzt bei festgehaltener Geometrie, Querkontraktionszahl und Lastform eine bekannte Kraft-/Steifigkeitsskalierung. Für die Modelle wurde festgelegt:

$$s(\mu)=\frac{F_z}{-500\,\mathrm{N}}\frac{10^{11}\,\mathrm{Pa}}{E}.$$

Der Faktor s ist dimensionslos. Das direkte Modell lernt normierte FEM-Felder; seine Vorhersage wird mit s zurückskaliert. Das Hybridmodell lernt dagegen das normierte Differenzfeld zwischen FEM und Balkennäherung. Seine Vorhersage ist

$$\hat u_{\mathrm{hybrid}}=u_{\mathrm{Balken}}+s\left(\overline{\Delta u}_{\mathrm{norm}}+\Phi_\Delta\hat a_\Delta\right).$$

Der direkte POD-Rang beträgt 2, der hybride Rang 4. Die während des Trainings bestimmten Basen, Skalierungen und Regressoren wurden für den Bestätigungstest nicht neu angepasst.

## 4. Eingefrorene Modellstände und Daten

| Modell | Artefakt | SHA-256 |
|---|---|---|
| Direkt normiert | fit_1_8.mat | 95e838bf30c923f3c1fb84b22a30c47ab5d649bc42c0eb27e92c3aafea71b0f4 |
| Hybrid normiert | fit_2_8.mat | 2cd825019503b0e6bf7a227fe466fcda30a75cd8d00276b25ede68cdd7adb4ae |

Beide Modelle verwenden die Trainings-IDs 1–12 und 25–30. Die IDs 31–36 wurden zuvor zur Entwicklung und Validierung verwendet. Sie sind keine unabhängigen Bestätigungsfälle. Die neuen Testfälle tragen die IDs 100001–100064.

Das vorab gespeicherte Protokoll sieht ein sechsdimensionales Latin-Hypercube-Sampling mit Seed 20261026 vor. Dieses Verfahren verteilt die Stichprobe über den vorgegebenen Parameterbereich; es erzeugt keine 64 unabhängigen einfachen Zufallsziehungen. Die Unabhängigkeitsprüfung betrachtete 1.384 Zeilen verfügbarer historischer CSV-Designs.

Für die konservative Äquivalenzprüfung wurden zwei Fälle als gleichartig behandelt, wenn Länge, Breite, Höhe und Querkontraktionszahl nach Normierung auf ihre jeweiligen Parameterbereiche innerhalb von 10⁻¹⁰ übereinstimmen. E und Fz dürfen sich dabei unterscheiden, weil das lineare Problem bei sonst gleichen Bedingungen die bekannte F/E-Skalierung besitzt. Der kleinste beobachtete maximale normierte Abstand zu den verfügbaren historischen Geometrie-/ν-Kombinationen betrug 0,03685. Nicht verfügbare historische Designs können durch diese Prüfung nicht ausgeschlossen werden.

## 5. Ausführung und Fehlermetriken

Vor dem Gesamtlauf wurde ein technischer FEM-Einzelaufruf erfolgreich durchgeführt. Anschließend wurden die restlichen Fälle berechnet. Jeder Fall besitzt eine eigene gespeicherte Datei mit Status, Parametern, Laufzeit und der zuletzt erfassten MATLAB-Warnung. Alle 64 Fälle waren erfolgreich; kein Fall wurde wegen seines Modellfehlers entfernt oder ersetzt.

Die Vorhersagen der drei Verfahren wurden vor der vergleichenden Fehlerauswertung gespeichert. Ihre Eingaben waren die Parameter, das Abfragegitter und die eingefrorenen Modellbestandteile; die FEM-Testfelder wurden nicht an die Vorhersage übergeben.

Der relative gewichtete Gesamtfeldfehler eines Falles ist

$$e=\frac{\|u_{\mathrm{FEM}}-\hat u\|_W}{\|u_{\mathrm{FEM}}\|_W},\qquad \|v\|_W=\sqrt{v^T Wv}.$$

W enthält normierte Trapezgewichte auf dem Abfragegitter. Die Gewichte summieren sich je Verschiebungskomponente auf eins. Für relative Komponenten- und Spitzenfehler werden Referenznormen beziehungsweise Beträge bis 10⁻¹⁴ m als ungültig behandelt. In dieser Untersuchung waren für die ausgewerteten Komponenten und Spitzenwerte keine relativen Werte ungültig. Mittelwert, Median, empirisches 95-%-Quantil und Maximum beziehen sich jeweils auf 64 Parameterfälle.

## 6. Gesamtfeldfehler

| Verfahren | Fälle | Mittelwert | Median | 95-%-Quantil | Maximum |
|---|---:|---:|---:|---:|---:|
| Reines Balkenfeld | 64 | 0,6892 % | 0,4352 % | 2,1545 % | 2,6120 % |
| Direktes normiertes POD-GPR | 64 | 22,4462 % | 6,6874 % | 84,9791 % | 504,6670 % |
| Normiertes Hybridmodell | 64 | **0,2383 %** | **0,1072 %** | **0,8932 %** | **2,1313 %** |

Der Mittelwert des direkten Modells liegt deutlich über seinem Median. Einzelne große Fehler beeinflussen ihn stark; sein Maximum tritt bei Fall 100027 auf. Das höchste Hybridmaximum tritt bei Fall 100050 auf. Das jeweils angegebene Maximum ist der schlechteste **beobachtete** Fall und keine garantierte Fehlerschranke.

![Relative Gesamtfeldfehler der drei Modelle je neuem Fall](fallfehler.png)

## 7. Paarweiser Vergleich

Der paarweise Vergleich verwendet für jedes Modell dieselbe FEM-Referenz. Die Differenz „Hybrid minus Balken“ ist in Prozentpunkten angegeben. Negative Werte bedeuten, dass der Hybrid in diesem Fall den kleineren Fehler hat. Differenzen bis 10⁻¹⁰ Prozentpunkte werden als gleich behandelt.

- Hybrid gegenüber Balken: **61 Verbesserungen**, **3 Verschlechterungen**, **0 gleiche Fälle**.
- Hybrid gegenüber direktem Modell: **63 Verbesserungen**, **1 Verschlechterung**.
- Größte beobachtete Verbesserung gegenüber Balken: **2,0250 Prozentpunkte**, Fall 100020.
- Größte beobachtete Verschlechterung gegenüber Balken: **0,2801 Prozentpunkte**, Fall 100001.

| Fall | Verschlechterung des Hybridmodells gegenüber Balken |
|---:|---:|
| 100001 | 0,2801 Prozentpunkte |
| 100047 | 0,0707 Prozentpunkte |
| 100055 | 0,0423 Prozentpunkte |

Gegenüber dem direkten Modell war Fall 100029 die einzige beobachtete Verschlechterung des Hybrids; sie betrug 0,0518 Prozentpunkte. Die vollständigen Fallwerte stehen in Anhang A.

## 8. Komponenten, Spitze und Einspannung

Neben dem Gesamtfeld wurden absolute gewichtete RMS-Fehler der Komponenten sowie der absolute Spitzenfehler berechnet. Die nachfolgenden Werte sind Mittelwerte über 64 Fälle und in Metern angegeben.

| Verfahren | ux-RMS | uy-RMS | uz-RMS | Spitzenfehler |
|---|---:|---:|---:|---:|
| Balkenfeld | 3,78 · 10⁻⁸ | 6,72 · 10⁻⁸ | 3,02 · 10⁻⁷ | 5,00 · 10⁻⁷ |
| Direkt normiert | 2,71 · 10⁻⁷ | 1,21 · 10⁻⁸ | 6,17 · 10⁻⁶ | 1,27 · 10⁻⁵ |
| Hybrid normiert | 3,80 · 10⁻⁹ | 8,63 · 10⁻⁹ | 1,02 · 10⁻⁷ | 1,76 · 10⁻⁷ |

Der Gesamtfeldfehler ersetzt keine komponentenweise Betrachtung. Besonders bei kleinen Referenzkomponenten können relative Komponentenfehler groß ausfallen, obwohl der absolute Fehler klein ist.

Die größten rohen Einspannabweichungen lagen bei 0 m für das Balkenfeld, 3,66 · 10⁻¹⁸ m für das direkte und 1,05 · 10⁻²⁰ m für das hybride Modell. Nach expliziter Randnachbearbeitung waren sie in allen drei Fällen null. Rohwerte und nachbearbeitete Werte wurden getrennt gespeichert.

## 9. Nachträgliche Diagnose

Die FEM-Felder wurden erst nach Speicherung der Vorhersagen auf die eingefrorenen POD-Basen projiziert. Diese Projektion ist eine Diagnose der Darstellbarkeit und keine online verfügbare Vorhersage.

Der mittlere relative Projektionsfehler betrug für das direkte Modell **0,0618 %** und für das hybride Modell **0,00482 %**. Beide liegen deutlich unter den jeweiligen Vorhersagefehlern. Die Basen können die betrachteten Felder beziehungsweise Korrekturfelder somit auf diesen Fällen gut darstellen; der Unterschied zu den Vorhersagefehlern zeigt, dass die Vorhersage der Koeffizienten ebenfalls eine wesentliche Rolle spielt. Er identifiziert keine einzelne technische Ursache.

![Hybridfehler gegen Trainingsabstand und Elastizitätsmodul](diagnostic.png)

![Referenz, Hybridvorhersage und Differenz für den schlechtesten Hybridfall](field_worst.png)

Die Abbildung zeigt den schlechtesten Hybridfall 100050 auf einer Gitterebene. Repräsentative Feldbilder für einen guten und einen typischen Fall wurden in diesem Lauf nicht erstellt. Fallwerte und Abstände sind in den gespeicherten CSV-Dateien verfügbar.

## 10. Laufzeiten

Die Onlinezeiten wurden auf demselben System mit MATLAB R2025b Update 1 gemessen: ein Warm-up, anschließend fünf Wiederholungen. Die Einzelmessung verwendet einen Fall; die Batchmessung umfasst alle 64 Fälle. Die Zahlen sind Mittelwerte in Millisekunden und enthalten die jeweils implementierten Prüfungen und die Randnachbearbeitung.

| Verfahren | Einzelabfrage | 64 Fälle als Batch |
|---|---:|---:|
| Balkenfeld | 2,267 ms | 0,745 ms |
| Direkt normiert | 2,729 ms | 2,702 ms |
| Hybrid normiert | 2,775 ms | 4,064 ms |

Die Einzel- und Batchwerte sind getrennte Messreihen; insbesondere der geringe Unterschied im Millisekundenbereich sollte wegen Messrauschen und Laufzeitumgebung nicht überinterpretiert werden. Der Hybrid berechnet zusätzlich Balkenfeld, Regression und Rekonstruktion.

Für den FEM-Fall 100001 wurden nach Warm-up fünf Wiederholungen einer separaten Zeitmessung durchgeführt: Netzaufbau etwa 0,050 s, Lösung 1,113 s, Interpolation 0,014 s und Gesamt 1,225 s. Die FEM-Gesamtzeit umfasst auch Problemdefinition; die Modellzeit enthält Eingabeprüfung und Randnachbearbeitung. Die Zeiten beschreiben den jeweiligen Aufruf auf diesem System. Die Offlinekosten für historische FEM-Daten und Modelltraining sind nicht darin enthalten.

## 11. Einordnung und Fazit

Der eingefrorene Hybrid zeigte auf 61 der 64 neuen Fälle einen geringeren Feldfehler als die reine Balkennäherung. In diesem vorab definierten Test bestätigt sich daher der bereits auf Entwicklungsdaten beobachtete Vorteil für den betrachteten Balkenbereich. Die drei Verschlechterungen zeigen zugleich, dass die gelernte Korrektur nicht in jedem Fall nützt.

Das direkte normierte POD-GPR schnitt auf den neuen Fällen deutlich schlechter ab. Ein kleiner POD-Projektionsfehler bei großem Vorhersagefehler grenzt die reine Darstellbarkeit als pauschale Erklärung ein; die genaue Ursache der fehlerhaften Generalisierung ist damit nicht abschließend geklärt.

Die Ergebnisse stützen Aussagen für die dokumentierte Geometrie, das lineare Material, die Lastform, die Netze und den untersuchten Parameterbereich. Sie garantieren keine Fehlergrenze für weitere Fälle. Eine neue Modelländerung müsste anschließend an neuen, bisher unbenutzten Fällen bewertet werden.

## 12. Getrennter Status der Modal-Erweiterung

Nach dem statischen Vergleich wurde eine vorhandene Modalreferenz nochmals auf ihre räumliche Übertragung geprüft. Dabei trat die Warnung MATLAB:triangulation:PtsNotInTriWarnId auf. Die Eckknotentriangulation verwendet nur die vier Eckknoten der quadratischen Tetraeder; die nachfolgende quadratische Interpolation verwendet die Mittelknoten.

Für diesen einen Fall reproduzierte die erneute Übertragung und gewichtete Normierung die gespeicherten Eigenformen mit maximaler Abweichung null. Das erklärt den geprüften Aufruf, ist aber kein allgemeiner Nachweis für alle Netze und Modencluster. Modale Balkenkandidaten, Frequenz- und Eigenformkorrektur sowie ein modaler Hybrid-Integrationslauf sind noch nicht implementiert beziehungsweise ausgeführt. Eine große Modal-Lernkurve wurde nicht gestartet.

## 13. Quellen, Artefakte und Reproduktion

| Datei | Inhalt |
|---|---|
| [PROTOKOLL.md](PROTOKOLL.md) | Vorab festgelegte Studienregeln |
| [design.csv](design.csv) | Die 64 Parameterfälle |
| [summary.csv](summary.csv) | Aggregierte Feldfehler |
| [case_metrics.csv](case_metrics.csv) | Alle Komponenten-, Spitzen- und Randfehler |
| [paired.csv](paired.csv) | Paarvergleiche und diagnostische Projektionsfehler |
| [distances.csv](distances.csv) | Abstand zum Trainingsbestand |
| [hashes_before.csv](hashes_before.csv), [hashes_after.csv](hashes_after.csv) | Prüfsummen vor und nach dem Lauf |
| FEM- und Vorhersage-MAT-Dateien | Einzelreferenzen, gespeicherte Vorhersagen und Prüfstände |
| [Modaler Zwischenstand](../modal_hybrid_followup_v1/STATUS.md) | Getrennte Übertragungsprüfung |

Die Einstiegspunkte im Projekt sind run_static_confirmation.m, evaluate_static_confirmation.m, diagnostic_static_confirmation.m, time_static_confirmation.m und time_fem_confirmation.m. Die gespeicherten Ergebnisse werden in diesem Bericht durch das Skript ausfuehrlicher_bericht.py gelesen; der Berichtsbau startet keine neue FEM-Berechnung und kein Training.

## Anhang A: Gesamtfeldfehler aller 64 Fälle

Angaben in Prozent; die letzte Spalte zeigt Hybrid minus Balken in Prozentpunkten.

| Fall-ID | Balken | Direkt normiert | Hybrid normiert | Hybrid − Balken |
|---:|---:|---:|---:|---:|

| 100001 | 0,3391 | 2,9287 | 0,6192 | 0,2801 |
| 100002 | 0,3862 | 10,0428 | 0,1273 | -0,2588 |
| 100003 | 0,2180 | 11,8391 | 0,1832 | -0,0348 |
| 100004 | 1,6495 | 4,2706 | 0,6008 | -1,0487 |
| 100005 | 0,4565 | 0,9114 | 0,0614 | -0,3951 |
| 100006 | 0,5141 | 15,2466 | 0,1219 | -0,3922 |
| 100007 | 0,1756 | 8,8166 | 0,0851 | -0,0905 |
| 100008 | 1,8893 | 8,2820 | 0,2848 | -1,6044 |
| 100009 | 0,0838 | 6,6145 | 0,0737 | -0,0101 |
| 100010 | 1,1202 | 29,7108 | 0,3479 | -0,7723 |
| 100011 | 0,4996 | 0,1558 | 0,0664 | -0,4332 |
| 100012 | 0,6411 | 2,9886 | 0,0699 | -0,5712 |
| 100013 | 0,2912 | 7,4845 | 0,0543 | -0,2370 |
| 100014 | 0,1380 | 4,7820 | 0,0693 | -0,0687 |
| 100015 | 0,3511 | 4,4598 | 0,2103 | -0,1408 |
| 100016 | 0,2194 | 3,6984 | 0,0187 | -0,2007 |
| 100017 | 1,0484 | 11,2648 | 0,1017 | -0,9467 |
| 100018 | 0,8420 | 2,5838 | 0,0480 | -0,7940 |
| 100019 | 0,2707 | 10,5535 | 0,0651 | -0,2057 |
| 100020 | 2,1124 | 5,1717 | 0,0874 | -2,0250 |
| 100021 | 0,2506 | 9,3793 | 0,0872 | -0,1634 |
| 100022 | 0,2482 | 6,8975 | 0,0557 | -0,1925 |
| 100023 | 0,1422 | 5,5709 | 0,0063 | -0,1359 |
| 100024 | 0,2456 | 12,5972 | 0,0098 | -0,2358 |
| 100025 | 0,3900 | 4,2369 | 0,0641 | -0,3259 |
| 100026 | 1,2168 | 2,2103 | 0,0765 | -1,1403 |
| 100027 | 2,6120 | 504,6670 | 2,0647 | -0,5474 |
| 100028 | 0,4417 | 0,5070 | 0,1332 | -0,3085 |
| 100029 | 1,3120 | 0,1781 | 0,2299 | -1,0821 |
| 100030 | 0,5551 | 5,2735 | 0,1022 | -0,4529 |
| 100031 | 0,5864 | 8,7261 | 0,2443 | -0,3421 |
| 100032 | 0,3343 | 0,8892 | 0,0565 | -0,2779 |
| 100033 | 0,2436 | 8,8283 | 0,1195 | -0,1241 |
| 100034 | 0,1725 | 0,4263 | 0,1339 | -0,0386 |
| 100035 | 0,2589 | 2,1849 | 0,0461 | -0,2127 |
| 100036 | 0,8727 | 7,0290 | 0,2409 | -0,6318 |
| 100037 | 0,4286 | 4,6505 | 0,0083 | -0,4203 |
| 100038 | 0,3884 | 2,1393 | 0,0424 | -0,3460 |
| 100039 | 0,4190 | 4,1724 | 0,1595 | -0,2595 |
| 100040 | 1,5658 | 79,4657 | 0,6662 | -0,8995 |
| 100041 | 1,2885 | 16,3618 | 0,3835 | -0,9049 |
| 100042 | 0,2468 | 0,8292 | 0,0332 | -0,2137 |
| 100043 | 0,2820 | 0,2372 | 0,0719 | -0,2100 |
| 100044 | 2,2527 | 97,8436 | 1,4229 | -0,8298 |
| 100045 | 0,4222 | 2,5033 | 0,0673 | -0,3549 |
| 100046 | 0,7320 | 12,3415 | 0,2661 | -0,4658 |
| 100047 | 0,1897 | 10,8546 | 0,2604 | 0,0707 |
| 100048 | 0,2128 | 8,4406 | 0,0843 | -0,1285 |
| 100049 | 0,6987 | 11,7295 | 0,2829 | -0,4158 |
| 100050 | 2,5414 | 284,2845 | 2,1313 | -0,4101 |
| 100051 | 0,7158 | 1,1476 | 0,0972 | -0,6186 |
| 100052 | 1,2954 | 9,8042 | 0,3994 | -0,8960 |
| 100053 | 1,1568 | 0,1595 | 0,0761 | -1,0807 |
| 100054 | 0,2885 | 17,2026 | 0,0270 | -0,2615 |
| 100055 | 0,0807 | 6,7603 | 0,1229 | 0,0423 |
| 100056 | 0,5844 | 5,1512 | 0,0505 | -0,5339 |
| 100057 | 0,6940 | 8,5179 | 0,1013 | -0,5928 |
| 100058 | 0,8005 | 25,4748 | 0,1696 | -0,6308 |
| 100059 | 1,1219 | 30,6479 | 0,3001 | -0,8219 |
| 100060 | 0,4089 | 1,6891 | 0,1575 | -0,2515 |
| 100061 | 0,5383 | 16,6132 | 0,2585 | -0,2798 |
| 100062 | 0,1887 | 1,1936 | 0,1121 | -0,0766 |
| 100063 | 0,3715 | 2,7528 | 0,1900 | -0,1815 |
| 100064 | 1,0693 | 42,1838 | 0,3416 | -0,7277 |
