# Diagnose des eingefrorenen statischen Vergleichs

Stand: Die Modal-Erweiterung wurde noch nicht begonnen. Dieser Zwischenbericht basiert auf den zuvor eingefrorenen Kandidaten in selection.mat und den gespeicherten Ergebnissen in diagnostics_v1.mat. Die Funktion run_hybrid_diagnostics liest diese Modelle und bestehende FEM-Daten; sie trainiert keine Modelle. plot_hybrid_diagnostics erstellt Abbildungen ausschließlich aus den gespeicherten Diagnosen.

## Zentrale Befunde

| Split | Balken Mittel / Median / Maximum | Direktes POD-GPR | Hybrid |
|---|---|---|---|
| Training | 0,590 / 0,461 / 1,836 % | 0,0550 / 0,0443 / 0,1628 % | 0,00472 / 0,00277 / 0,02696 % |
| Interne Validierung | 0,5215 / 0,4620 / 0,8698 % | 113,834 / 36,711 / 347,857 % | 0,8544 / 0,5462 / 2,6836 % |
| Historischer Test | 0,6563 / 0,4626 / 1,7197 % | 67,828 / 32,244 / 255,707 % | 0,7359 / 0,1785 / 2,3117 % |

Das Maximum ist der schlechteste beobachtete Fall und keine garantierte Fehlerschranke. Der historische Test wurde bereits betrachtet und ist kein unabhängiger Bestätigungstest. Nach dem vorab festgelegten mittleren Validierungsfehler gewinnt das Balkenfeld. Die Hybridkorrektur verbessert es nicht zuverlässig: auf dem historischen Test ist sie bei zwei der sechs Fälle schlechter.

Die gewichtete POD-Orthonormalität (Frobeniusnorm des Fehlers von V'WV gegenüber I) beträgt 8,08e-16 für die direkte und 2,98e-15 für die hybride Basis. Die gespeicherten Eingabemittelwerte und -standardabweichungen stimmen mit den 18 Trainingsfällen überein. Speichern/Laden des direkten Kandidaten reproduzierte das rohe Validierungsfeld exakt. Das prüft wesentliche Teile der Verarbeitung, belegt aber noch nicht die vollständige Korrektheit aller Schnittstellen und Einheiten.

Der mittlere relative Projektionsfehler der direkten POD liegt im Training bei 0,0550 %, auf der Validierung bei 0,0654 % und auf dem historischen Test bei 0,0670 %. Die Trainingstrunkierung ist daher erwartungsgemäß nicht null. Dagegen liegt der direkte Vorhersagefehler auf der Validierung bei 113,834 %. Die erste direkte POD-Koeffizientenabweichung hat dort einen RMS-Wert von 2,431e-5 m, die zweite von 3,9e-7 m. Der dominierende Unterschied entsteht für diese Daten zwischen tatsächlichen und vorhergesagten Koeffizienten; die genauere Ursache des GPR-Generaliserungsfehlers ist noch nicht bewiesen.

Die mittleren Hybrid-Projektionsfehler betragen 0,00472 % (Training), 0,01185 % (Validierung) und 0,01127 % (historischer Test), jeweils bezogen auf das vollständige FEM-Feld. Auch hier ist der Validierungs-Vorhersagefehler mit 0,8544 % erheblich größer als die Projektionsuntergrenze. Die auf Testdaten bestimmten tatsächlichen Koeffizienten sind Diagnosen und werden nicht an die Vorhersage übergeben. Relative Fehler sind nicht additiv.

Die größte rohe Einspannabweichung auf Validierung betrug 2,73e-18 m (direkt) und 1,06e-20 m (hybrid); nach explizitem Nullsetzen ist sie null. Komponenten-RMS und relative Komponentenfehler, Spitzenwerte, Randkorrekturen, Fallwerte sowie tatsächliche und vorhergesagte Koeffizienten sind für alle drei Splits im MAT-Artefakt gespeichert. Für relative Komponentenwerte gilt die Schwelle 1e-14 m für die gewichtete Komponentennorm; darunter wird NaN statt eines relativen Wertes ausgegeben. Gewichte summieren sich pro Komponente auf eins und insgesamt auf drei.

Die gespeicherten GP-Kernelparameter, Sigma und Log-Likelihood sind je Koeffizient im MAT-Artefakt enthalten. Optimierungsstatus und Warnungen wurden im ursprünglichen eingefrorenen Fit nicht protokolliert und dürfen nicht nachträglich als bestanden ausgegeben werden.

Abbildungen: validation_case_errors.pdf, validation_coefficients.pdf und projection_vs_prediction.pdf. Sie zeigen den internen Validierungssplit; Nummer 1 in der Projektionsgrafik bezeichnet direktes POD-GPR, Nummer 2 die Hybridkorrektur.

## Abnahmestand

| Anforderung | Prüfung und Toleranz | Ergebnis | Status / Beleg |
|---|---|---|---|
| Split-Trennung und exakte Parameterduplikate | IDs und eindeutige Zeilen | 18/6/6 disjunkt | bestanden; protocol.mat und run_hybrid_static_audit.m |
| POD-Orthonormalität | Frobeniusnorm V'WV-I | maximal 2,98e-15 | bestanden; diagnostics_v1.mat |
| Train-only Eingabeskalierung | gespeicherte Mittel/Standardabweichungen gegen Training | Abweichung 0 | bestanden; diagnostics_v1.mat |
| Laden und Vorhersage | direktes Modell, rohe Validierung, exakte Gleichheit | gleich | bestanden; erneut ausgeführter MATLAB-Aufruf |
| FEM-freier Berichtsexport | plot_hybrid_diagnostics liest MAT-Artefakt | drei PDFs erzeugt | ausgeführt; plot_hybrid_diagnostics.m |
| Separate Kraft-/E-/Vorzeichenprüfung | 1e-14 m absolute Toleranz | zuvor bestanden | historischer Aufruf, kein persistiertes Einzelprotokoll; nicht erneut geprüft |
| Wiederaufnahme nach gezielter Unterbrechung | kontrollierter Abbruch und Wiederaufnahme | nicht ausgeführt | nicht geprüft |
| Raum- und Schema-Kompatibilität | gezielter Negativtest für diese Kandidaten | nicht ausgeführt | nicht geprüft |
| Keine FEM-Ziele in Vorhersagediensten | struktureller und negativer Test | nicht ausgeführt | nicht geprüft |
| Trainingsoptimierung und Warnungen | Fit-Protokolle | ursprüngliche Warnungen fehlen | nicht geprüft |

Es fehlen weiterhin systematische POD-Komprimierungskurven, Feldbilder, getrennte wiederholte Laufzeitmessungen, vollständige Regressionstests und ein umfassender wissenschaftlicher Abschlussbericht. Eine Aussage, dass das direkte POD-GPR insgesamt korrekt implementiert ist, ist deshalb noch nicht gerechtfertigt. Die Modal-Erweiterung und eine große Modal-Lernkurve wurden nicht gestartet.
