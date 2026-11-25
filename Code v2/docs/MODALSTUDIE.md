# Modalstudie: sechs Eigenfrequenzen

`runModalStudy` vergleicht MLP, RBF, POD-MLP und POD-GPR auf den sechs kleinsten,
aufsteigend sortierten Eigenfrequenzen. Die Ausgaben sind Frequenzraenge in Hz,
keine raeumlichen Eigenformen und keine ueber Geometrien verfolgten Modenfamilien.

## Aufbau

- `runModalStudy.m`: expliziter Einstieg ohne automatische Phasenfolge.
- `workflows/modal_comparison/+modalstudy`: Konfiguration, Referenzzugriff,
  Studienphasen und MATLAB-Berichtsdiagramme.
- `+surrogate`: gemeinsame vier Modellimplementierungen fuer Statik und Modalaufgabe.
  `models.shared.targets` liefert intern eine Ausgabe-mal-Fall-Matrix und Gewichte.
  Checkpoints, Kandidaten, Suche, Zeitprotokoll und Datei-Hashes liegen unter `surrogate.study`;
  die alten `staticstudy`-Aufrufe bleiben als kleine Weiterleitungen erhalten.

Oeffentlicher Modalvertrag: `surrogate-modal-v1`, `inputParameters` N x 6,
`frequencyHz` N x 6, `caseIds` N x 1 und `modeIndices` 6 x 1.
Parameterreihenfolge: L_m, b_m, h_m, E_Pa, nu, rho_kg_m3; Dichte in kg/m^3.
Das vorhandene MAT-Schema `modal-natural-frequencies-v1` und seine Dateien werden
nicht umgeschrieben. Statische Schnittstellen und historische Modellartefakte bleiben lesbar.

Die POD wird aus zentrierten Trainingsfrequenzen mit Einheitsgewichten berechnet.
Ihre Basis hat 6 x r Eintraege. Rang 6 ist die Kontrolle ohne Dimensionsreduktion.
Direkte Netze standardisieren jede Ausgabe; POD-MLP verwendet eine gemeinsame
Koeffizientenskala (`shared_output_mse`). Eingabestatistiken, POD und Skalen sehen
keine Validierungs- oder Testlabels. Im gespeicherten internen POD-Zustand bleibt
der Name `fieldMean` aus Kompatibilitaetsgruenden erhalten; im Modalmodell ist er
der Mittelwert der sechs Frequenzen.

## Daten und Aussagegrenzen

Standard: vorhandene 384 Trainings-, 12 Validierungs- und 64 Testfaelle unter
`data_generation/data/modal`. Die Testfaelle sind bereits aus der Praesentation
bekannt. Der neue Lauf ist daher eine Wiederholung auf bekannter Referenzbasis,
kein unabhaengiger Abschlusstest und kein Extrapolationstest. Die kleine
Validierungsmenge begrenzt die Belastbarkeit der Hyperparameterauswahl.

Alle Modellziele bleiben FEM-Frequenzen. Die vorhandene Referenzpruefung zeigte
bei den Frequenzraengen 5/6 mediane Abweichungen der reinen Biegeanalytik von
etwa 44/37 Prozent. Euler-Bernoulli wird deshalb nur separat verglichen: sechs
Wurzeln je Biegerichtung, daraus die sechs kleinsten Frequenzen. Es fehlen unter
anderem Torsion und dreidimensionale Effekte; Ranggleichheit ist keine Modenzuordnung.

`solve_modal_case` verwendet denselben eingespannten Quader wie die alten Daten,
quadratische Elemente und `Hmax=min(b,h)/3`. Die Suche beginnt bei 2000 Hz und
verdoppelt die Obergrenze bis hoechstens 128000 Hz, bis mindestens sechs positive
Frequenzen vorliegen. MATLABs Kreisfrequenzen werden durch 2*pi geteilt.
Es werden keine Modenfelder interpoliert oder als Lernziele gespeichert.

## Startbefehle – noch nicht ausgefuehrt

Alle relativen Konfigurationspfade beziehen sich auf `Code v2`, unabhaengig vom
aktuellen MATLAB-Ordner. `setupProject` aendert nur den Sitzungspfad, nicht `savepath`.
Vor jedem neuen Lauf in einer Kopie von `local.example.json` einen neuen Ausgabeordner
festlegen. Die Standarddatei nennt `experiments/modal_comparison_v1`.

```matlab
runModalStudy % nur Hilfe
cfg = "workflows/modal_comparison/configs/study.json";
local = "workflows/modal_comparison/configs/local.example.json";
```

Nach ausdruecklicher Startfreigabe zuerst die drei vorgegebenen Trainingsfaelle
gegen die alte FEM-Referenz pruefen, dann einen kleinen realen Gesamttest ausfuehren:

```matlab
setupProject; addpath("tests");
checkModalFem(fullfile(pwd,"experiments","modal_preflight_neu"));
smokeLocal = prepareModalSmoke(fullfile(pwd,"experiments","modal_smoke_neu"));
runModalWorkflowSmoke("workflows/modal_comparison/configs/smoke.json",smokeLocal);
```

Ein Fehler stoppt diese Folge. Die FEM-Pruefung verlangt fuer alle sechs Frequenzen
jedes der drei Faelle eine relative Abweichung <= 1e-5. Keine historischen Dateien
oder Toleranzen automatisch anpassen, um ein abweichendes Ergebnis zu akzeptieren.

Danach jede Hauptphase explizit aufrufen:

```matlab
runModalStudy("init",cfg,local);
runModalStudy("generate",cfg,local);
runModalStudy("tune",cfg,local);
runModalStudy("train",cfg,local);
runModalStudy("freeze",cfg,local);
runModalStudy("evaluate",cfg,local);
runModalStudy("benchmark",cfg,local);
runModalStudy("report",cfg,local);
```

`generate` registriert standardmaessig vorhandene Daten. Mit `reference_mode="generate"`
berechnet es stattdessen die vorgegebenen Designfaelle in eigenen Unterordnern neu.
Die unveraenderten Originaldateien bleiben als Herkunft dokumentiert.
Testlabels werden im oeffentlichen Referenzzugriff erst nach Freeze geoeffnet.
Die Sperre ist eine Ablaufkontrolle, keine Dateisystem-Zugriffssperre.

Abgeschlossene Versuche werden geprueft und wiederverwendet. Konfiguration,
Quelldateien oder Referenzdaten duerfen waehrend eines Laufs nicht wechseln.
Geaenderte Dateien, unvollstaendige Siegel oder widerspruechliche Checkpoints
fuehren zum Abbruch. Alte Freeze-Manifeste werden niemals nachtraeglich angepasst;
auch eine erneute statische Studie nach einer Quellaenderung braucht einen neuen Lauf.

## Such- und Trainingsplan

Die versionierte `study.json` enthaelt 8 MLP-, 12 RBF-, 16 POD-MLP- und 32 POD-GPR-Kandidaten.
Auswahlmetrik: Mittel von abs(Vorhersage-FEM)/FEM ueber alle Validierungsfaelle und
sechs Ränge; danach Nearest-Rank-P95 und Kandidatennummer. Die besten zwei
neuronalen Kandidaten werden mit Seeds 42/43/44 bestaetigt. Insgesamt hoechstens
80 Suchfits inklusive zwoelf zusaetzlicher Bestaetigungsfits.

`modalstudy.runPlan` beschreibt zentral die folgenden 72 Fits:

- 58 Hauptfits: 24/48/96/192 Faelle mit drei verschachtelten Auswahlen fuer vier
  Methoden; 384 Faelle mit drei Netzinitialisierungen fuer MLP/RBF/POD-MLP und
  einem POD-GPR-Modell.
- 12 kontrollierte Vollpool-Fits: POD-Rang 1 bis 6 fuer beide POD-Methoden, Seed 42.
- Zwei weitere Vollpool-GPR-Fits nur fuer Zeitwiederholungen.

Es gibt keine kuenstliche Zweiblock-Einteilung und keine zusaetzliche Verteilungsstudie.
Neuronale Fits verwenden CPU, Adam, 200 Epochen und Batchgroesse 32. Pro Familie
gilt ein Suchbudget von 5400 Sekunden; laufende Fits werden nicht hart abgebrochen.
Die Kandidatensuche startet neue Fits nur vor ihrer Budgetgrenze. Erfolgreiche
Hauptmodelle aller vier Methoden sind Voraussetzung fuer den Freeze.

## Ergebnisse und Zeitbedarf

`REPORT.md`, `run_results.csv`, `mode_results.csv`, `case_results.csv`,
`pod_diagnostics.csv`, Suchprotokolle und `figures/` entstehen durch `report`.
Vorhersagen werden weder sortiert noch abgeschnitten. Nichtpositive Frequenzen,
Reihenfolgeverletzungen und fehlgeschlagene Auswertungen werden sichtbar erfasst.
POD-Fehlerzerlegung: quadrierte Hz-Norm; sie ist nicht die relative Auswahlmetrik.

Die historischen Praesentationsvorhersagen werden anhand der Fall-ID, des Rangs
und der FEM-Referenz abgeglichen. Seed-42-Einzelmodelle und Drei-Netz-Ensembles
stehen getrennt in `historical_comparison.csv`; sie werden nicht zur Auswahl benutzt.

Benchmark: zwoelf vorgegebene Testfaelle, zwei FEM-Wiederholungen plus ein Warm-up,
30 Vorhersagewiederholungen je Methode fuer Einzelfaelle und Stapel. Einzelfallzeiten
sind Mediane der fallweisen Mediane; Batch-FEM ist deren Summe. Laden bleibt separat.
Break-even verwendet Hauptfit, optional Suchzeit, und setzt vorhandene Trainingsdaten voraus.
Historische Datenerzeugungszeiten sind keine neuen Benchmarkmessungen.

**Vorlaeufig 1–2 Stunden Rechenzeit, 3 Stunden ohne Standby reservieren**, einschliesslich
FEM-Pruefung und kleinem Gesamttest. Der Plan umfasst maximal 152 Fits; konkrete
Laufzeiten haengen vor allem von der GPR-Optimierung ab. Die Schaetzung stuetzt sich
auf vorhandene modale MLP/POD-MLP-Fits (ca. 10–19 s), bisherige GPR-Messungen und
modale FEM-Zeiten (Median ca. 12 s). Fuer die neue Hauptstudie gibt es noch keine Messung.

## Kleine Implementierungstests

```matlab
setupProject; addpath("tests");
results = runtests({"tests/modalModelsTest.m","tests/modalStudyTest.m"});
assertSuccess(results);
```

Diese Tests verwenden synthetische Frequenzen, Mini-Netze und kuenstliche
Ergebnisdateien. Sie starten keine realen FEM-Laeufe und keine Hauptstudie.
Die vorhandenen statischen Testklassen sichern weiterhin gespeicherte Vorhersagen,
Metriken, Kandidaten und Trainingsauswahlen ab. `checkModalFem` und
`runModalWorkflowSmoke` sind absichtlich separate, explizit aufgerufene Funktionen.
