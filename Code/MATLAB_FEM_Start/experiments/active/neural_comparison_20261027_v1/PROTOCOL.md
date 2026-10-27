# Neuronaler Modellvergleich v1 — vor Auswertung festgelegt, 27.10.2026

## Ausgangslage und Schutz alter Ergebnisse

Arbeitskopie: github_dd_branch/Code/MATLAB_FEM_Start. Ausgangsprüfung
`run_checks(false)` am 27.10.2026 in MATLAB R2025b Update 1 bestanden.
Die bereits vorhandene, unversionierte Literaturdatei wird nicht verändert.
Historische Artefakte werden nur gelesen. Neue Ergebnisse werden ausschließlich
in dieser Studie gespeichert; vorhandene fertige Artefakte werden wiederverwendet.

Statische Trainings-IDs: 1–12 und 25–396, in der gespeicherten Reihenfolge.
Die ersten n davon bilden die sechs verschachtelten Stufen. Validierung: 13–18.
Historischer Vergleich: 19–24. Herkunft laut case_provenance_n384.csv:
1–24 original_smoke, weitere Fälle nachträgliche FEM-Erweiterungen.
396 native Netze mit Knoten, quadratischen Tetraedern und Verschiebungen sind
vorhanden. Gemeinsames Auswertegitter: 21×5×5, Komponentenblockfolge ux,uy,uz.

Modal liegen zunächst 24 Referenzen vor: 12 Training, 6 Validierung, 6 historische
Tests, alle rho=7850 kg/m³. Konvergenzläufe sind keine zusätzlichen unabhängigen
Trainingsfälle. Statische Referenzen sind keine Modalreferenzen.

## Bestandsaufnahme vor Implementierung

| Verfahren | Ausgangsstatus | Befund |
|---|---|---|
| A Frequenz-MLP | fehlend | Frequency_GPR vorhanden, bislang konstante Dichte |
| B POD-MLP | vorhanden, vertieft zu prüfen | gewichtete POD, Training-only Skalierung, Validierung für Rang/Breite |
| C neuronales Restfeld | fehlend | Beam_Field_POD_GPR vorhanden, kein neuronaler Koeffizientenregressor |
| D DeepONet | vorhanden, vertieft zu prüfen | Parameter-Branch, Koordinaten-Trunk, drei Komponenten, harte Einspannung; negatives Archiv erhalten |
| E PINN | fehlend | separater 1D-Euler-Bernoulli-Prototyp erforderlich |
| F FNO | fehlend | regelmäßiges Referenzgitter vorhanden |
| G Graphnetz | fehlend | native quadratische Netze und Felder vorhanden |

## Daten, Auswahl und abschließender Test

Konfiguration: configs/neural_comparison_v1.json. Seed 20261027 für neue Designs,
42, 43 und 44 für Netze; modales Design Seed 20261028. Neue statische 64 Testpunkte werden vor dem Training als unabhängig
gleichverteiltes Design im bisherigen Parameterquader gespeichert. Ausschluss
exakter Duplikate gegenüber historischen und 64 Bestätigungsfällen prüfen.
Diese 64 Fälle dürfen erst nach Modellfixierung ausgewertet werden. Ihre Ergebnisse
sind anschließend verbraucht, auch wenn ein Modell schlecht abschneidet.

Eigenes modales Design: 384 Training, 12 Validierung, 64 Tests; dieselben ersten
fünf Parametergrenzen, rho in [2700,8900] kg/m³ unabhängig variierend. Ungedämpft,
isotrop linear-elastisch, ohne Vorspannung. Erste sechs Frequenzen in Hz,
mindestens acht Moden als Zuordnungspuffer. Quadratische Tetraeder, Netzteiler 3.
Bestehende konstante-Dichte-Fälle dienen nur der Prüfung, nicht der neuen Lernkurve.

Normierung, POD-Mittelwert und Basis ausschließlich aus jeweiligem Trainingsanteil.
POD-Ränge 2,4,8,11 (höchstens n−1), MLP-Breiten 32,64, zwei tanh-Schichten,
Adam, höchstens 300 Epochen, identische bestehende Early-Stopping-Regel.
Auswahl: kleinstes mittleres relatives gewichtetes Feld-L2 auf Validierung;
Frequenzen mittlerer absoluter relativer Fehler. Gleichstand: erster Kandidat.
Historische POD_GP/POD_RBF/POD_MLP und DeepONet separat als eingefrorene Referenzen
nachprüfen. Keine Testdaten zur Auswahl, keine stillen Reparaturen historischer Fits.
Neue DeepONet-Versuche müssen als neue Trainingsläufe in dieser Studie erkennbar sein.

## Metriken und Laufzeiten

Pro Fall: sqrt(sum(w*(u_hat-u)^2)/sum(w*u^2)), absolute gewichtete RMS-Vektornorm
in m (Gewichte jeder Komponente summieren sich zu 1), Komponenten-RMS und relative
Komponentenfehler. Bei verschwindender Referenzkomponente ist der relative Fehler
NaN statt willkürlich groß; absolute Fehler bleiben definiert. Median, nächster
Rang ceil(.95*N), Maximum. Abbildungen: median-nächster und schlechtester Fall.
Die Norm entspricht der volumen-normalisierten L2-Norm; die physikalische
L2-Norm ist zusätzlich RMS*sqrt(L*b*h), Einheit m^(5/2).

Frequenzfehler pro sortiertem Index und nach MAC-Zuordnung zur Referenzform;
MAC<0.7 oder relativer Frequenzabstand <1% kennzeichnet unklare Familien.
Ein nur frequenzvorhersagendes Netz liefert keine eigenen Modenformen:
Familienmetriken benötigen daher ein separat dokumentiertes Labelverfahren.
Sortieren darf rohe Ordnungsverletzungen nicht verbergen.

Training einschließlich aller Kandidaten separat messen. Modelle vor Zeitmessung
laden, Vorhersage aufwärmen, sieben Wiederholungen je Fall, Rohzeiten/Median/Streuung.
FEM auf denselben Testfällen neu messen; historische Datenerzeugungszeiten nur
als historischer Aufwand markieren. Rechner, Release und Toolboxversionen speichern.
Amortisation ceil((Datenerzeugung+Training)/(FEM−Vorhersage)); bei nichtpositivem
Nenner keine endliche Amortisation. Historische Datenkosten sind keine neue
kontrollierte Laufzeitmessung. Laufende andere Prozesse als Einschränkung nennen.

## Literatur und Abweichungen

Die zehn verbindlichen Referenzen stehen in Recherche/LITERATUR_NEURONALE_SURROGATE.md.
Quellenabruf am 26./27.10.2026: arXiv-Originalseiten 2,3,4,7,8 und PMLR-Originalseite 9
gelesen; Raissi-Autorenseite https://maziarraissi.github.io/PINNs/ gelesen.
Paridie: PubMed-Abstract https://pubmed.ncbi.nlm.nih.gov/36387527/;
PMC-Volltext durch Zugriffsschutz nicht lesbar. Hu-Verlagsvolltext nicht zugänglich.
Keine lokal beigefügten Volltexte identifiziert. Nicht gelesene Details werden nicht
als originalgetreue Architekturreproduktion behauptet.

1. Paridie: methodisches Vorbild für Mehrfachfrequenzregression; hier keine
Vorspannung, dafür echte Dichtevariation und logarithmisch positive Ausgaben.
2. Salvador: Original verwendet Kernel-POD; unsere lineare gewichtete POD ist
eine explizite Vereinfachung, keine Kernel-POD-Reproduktion.
3. Fresca/Manzoni: unser POD-MLP enthält keinen nichtlinearen Autoencoder und
keine erlernte zeitliche Dynamik; daher nicht als vollständiger POD-DL-ROM bezeichnen.
4. Lu: Parametervektor ersetzt gesampelte Eingabefunktion; drei statische Ausgänge.
5. Raissi: Differentialresiduum und Randverlust; 1D-Balken statt allgemeiner PDE.
6. Brivio: reduzierte Physikhybride motiviert; analytisch addiertes Restfeld ist
kein PTPI-DL-ROM und besitzt noch keinen PDE-Residualverlust.
7. Li: spektrale Faltung auf regelmäßigem Gitter, keine Aussage über Motornetze.
8./9. Pfaff/Sanchez-Gonzalez: statische Verschiebungsregression auf Netzgraphen,
keine Übernahme dynamischer Zeitschritte oder Rollout-Aussagen.
10. Hu: Übersicht zur Einordnung, keine zusätzliche Netzarchitektur;
Volltextzugriff fehlt, daraus keine spezifischen Implementierungsdetails ableiten.

## Reproduktion und Fortschritt

`openProject('blank_project.prj')` in R2025b; anschließend
`run_neural_comparison('prepare')`, `run_neural_comparison('static')`,
`run_neural_comparison('modal_data')`, `run_neural_comparison('modal_train')`.
Weitere Stufen werden mit ihrer tatsächlichen Implementierung dokumentiert.
Dieses Protokoll ist kein Ergebnisbericht. Fehlende oder fehlgeschlagene Stufen
werden ausdrücklich als solche ausgewiesen; keine geschätzten Lernkurven.
