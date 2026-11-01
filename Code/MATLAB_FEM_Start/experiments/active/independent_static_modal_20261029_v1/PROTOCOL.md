# Unabhaengige Abschlusspruefung: Statik und Eigenfrequenzen

Vor Erzeugung neuer Referenzlabels gespeichert, 29.10.2026. Konfiguration:
`configs/independent_static_modal_20261029_v1.json`. Keine Modellauswahl oder
Tuning anhand der Holdouts. Die beiden Holdouts sind getrennte Aufgaben.

## Eingefrorene Modelle

Statik: drei finale [32,32]-tanh-L-BFGS-Restfeld-MLPs, Seeds 42-44, und
ARD-Matern-5/2-Restfeld-GPR aus der Lernkurvenstudie auf denselben 384
Trainings-IDs 1-12 und 25-396; gemeinsame train-only gewichtete POD, Rang
erster Rang mit >=99.99 % Trainingsenergie, hoechstens 32; Mittelwert und
Skalierungen nur aus Training. Analytisches Balkenfeld datenfrei. MLP und GPR
verwenden denselben Mittelwert, dieselbe Basis und Koeffizienten.

Modal: drei finale L-BFGS-MLPs auf 384 IDs 300001-300384, Seeds 42-44;
fehlende finale GPR wird mit festem ARD-Matern-5/2 und Sigma=1e-4 aus den
384 vorhandenen Trainingsfaellen auf log(Frequenzen) gefittet. Eingabe- und
Logzielskalierung nur aus Training. Keine Kernel- oder Seedwahl. Die sechs
Ausgaenge sind aufsteigende Frequenzindizes, keine Eigenformen oder
Modenfamilienzuordnung.

Die Quellen und Trainingszuordnung werden mit vorhandenen Pruefsummen und
gespeicherten Modell-/POD-Metadaten geprueft. Vor dem ersten Holdout-Label
werden Modelle, Konfiguration, Implementierung, Designs und technischer Pilot
in einem unveraenderlichen Manifest mit SHA-256 eingefroren.

## Zwei vorab gespeicherte Holdout-Designs

Je 128 unabhaengig von allen beobachteten Fehlern erzeugte Punkte. Statisch
maximin-LHS im unveraenderten sechsparametrigen Raum, Seed 20261110,
100 Optimierungsiterationen, IDs 1000001-1000128. Modal unabhaengiges
gleichverteiltes rand-Design im bestehenden modalen Parameterraum, Seed
20261111, IDs 1100001-1100128. Beide verwenden RNG twister. Die vollstaendigen
Designs werden vor FEM gespeichert. IDs und normierte Parameterkombinationen
werden gegen bekannte Trainings-, Entwicklungs- und Testdesigns sowie intern
geprueft; Chebyshev-Abstand > 1e-10. Bei Kollision abbrechen, nicht neu ziehen.

Statik-FEM wie vorher: `solve_case`, quadratische Elemente, Netzteiler 3,
Gitter 21x5x5 und Deflektionsgrenze 0.02. Modal-FEM wie vorher:
`femstudy.fem.modal(x,3)`, aufsteigende erste sechs Frequenzen. Ein Fehler
bleibt mit ID und Parametern bestehen; Retry derselbe Punkt und neue
Versuchsnummer. Keine Ersetzung schwieriger Punkte. Auswertung nur mit allen
128 erfolgreichen Referenzen je Aufgabe.

## Technischer Pilot und Metriken

Vor Freeze Schnittstellen auf wenigen bestehenden Trainingsfaellen pruefen:
gemeinsame Darstellung, korrekte Rekonstruktion, Log-/Hz-Transformation,
absolute und relative Metriken, Zeiterfassung, Reihenfolgepruefung und
Wiederaufnahme. Pilotresultate sind keine Abschlussgenauigkeit.

Statisch: je Modell/Seed relativer gewichteter Feld-L2 (Referenznormboden
1e-14 m), absoluter gewichteter Vektorfeld-RMS in m, Mittel, Median,
nearest-rank-P95 (122. von 128), Maximum, schlechteste Faelle. P95 <= 1 %
je Seed als internes Arbeitsziel. Modal: je Modell/Seed und Frequenzindex
dieselben Statistiken der absoluten relativen Rohfehler und absoluten Fehler
in Hz; P95 <= 1 % getrennt je Frequenz und Seed. Nachsortierte Werte nur
als Diagnose; rohe Ordnungsverletzungen pro Fall und Nachbarpaar dokumentieren.
Es gibt keine gemeinsame Fehlerkennzahl fuer Statik und Modal.

Vorhersagezeiten: Modelle vorladen, ein Aufwaermaufruf, danach sieben
Einzelfallaufrufe je Modell/Seed/Fall mit `tic/toc`, Median pro Fall und
Streuung dieser Mediane berichten. FEM-Zeiten pro Referenz und Fehlversuch
protokollieren. Historische Trainings- und Suchaufwaende getrennt und mit
ihren Laufzeitbedingungen angeben; keine Amortisationszahl ohne vergleichbare
Vollkosten und ausreichend belastbare zeitliche Messungen.

Bei Integritaetskonflikt nicht ersetzen oder neu einfrieren. Evaluation und
Fehlversuche versioniert speichern, keine Ergebnisse rueckwirkend ausfiltern.
