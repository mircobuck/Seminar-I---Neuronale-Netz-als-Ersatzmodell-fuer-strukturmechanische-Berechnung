
# FEM-Referenzvalidierung – Ergebnisbericht

**Studie:** `fem_reference_validation_v1`  
**Ausgeführt:** 2026-11-01  
**Status:** abgeschlossen; 18 von 18 FEM-Läufen erfolgreich  
**Protokoll:** [protocol.md](../protocol.md)  
**Ausführung:** [run_validation.m](../scripts/run_validation.m)  
**Provenienz:** [study_manifest.txt](study_manifest.txt)

## Kurzfazit

Die FEM-Ergebnisse sind für die untersuchten Fälle plausibel und zeigen bei
Netzverfeinerung nur kleine Änderungen. Die Studie validiert jedoch weder den
gesamten Parameterraum noch ein neuronales Ersatzmodell.

Die statischen FEM-Mittelachsenwerte stimmen im Median besser mit
Euler-Bernoulli als mit der hier verwendeten Timoshenko-Kurve überein. Die
Timoshenko-Ergänzung der Schubverformung führt nicht in jedem Fall zu einer
Verbesserung; die beiden Balkentheorien bilden unterschiedliche Näherungen an
das dreidimensionale Modell. Die Frequenznähe der ersten Biegemoden ist gut,
während Abweichungen bei höheren Moden deutlich größer sein können.

## Daten- und Laufumfang

- Für die analytische Statikprüfung wurden ausschließlich die 384 Fälle des
  statischen Trainingssplits gelesen.
- Für die Frequenzdiagnostik wurden ausschließlich die 384 Fälle des modalen
  Trainingssplits gelesen.
- Die Netzstudie verwendete die sechs vorab festgelegten Trainingsfälle und
  die Netzdivisoren 3, 4 und 6: drei statische und drei modale Fälle mit je
  drei Netzstufen.
- Alle 18 Läufe wurden als `completed` protokolliert; es gab keine
  fehlgeschlagenen FEM-Läufe.
- Validierungs- und Testlabels wurden nicht eingelesen oder verwendet.

## Analytische Vergleiche

### Statische Mittelachse

Relative Fehler gegenüber den analytischen Kurven über 384 Fälle:

| Theorie | Achsen-RMS-Fehler Median | P95 | Maximum | Spitzendurchbiegung Median | P95 | Maximum |
|---|---:|---:|---:|---:|---:|---:|
| Euler-Bernoulli | 0,4076 % | 1,8787 % | 3,4440 % | 0,3515 % | 1,6023 % | 2,9459 % |
| Timoshenko | 0,9354 % | 1,5854 % | 2,1838 % | 0,8003 % | 1,3503 % | 1,8629 % |

Euler-Bernoulli hat hier den kleineren Medianfehler; Timoshenko hat bei P95
und Maximum kleinere Fehler. Daher ist keine der beiden Näherungen für jedes
Fehlermaß überlegen. Die zusätzlichen Timoshenko-Ergebnisse sind als
Vergleichsmodell zu verstehen, nicht als erwartete exakte 3D-Lösung.

### Modale Frequenzen

Für jeden Trainingsfall wurde die nächste FEM-Frequenz zur jeweiligen
analytischen Grundfrequenz gesucht. Dies bleibt eine Frequenznähe-Diagnostik,
keine sichere Modenidentifikation:

| Biegerichtung | Median | P95 | Maximum |
|---|---:|---:|---:|
| Biegung in z | 0,6246 % | 2,0231 % | 3,2479 % |
| Biegung in y | 0,1650 % | 0,6850 % | 1,2211 % |

Die Gegenüberstellung von Modenformen auf den sechs ausgewählten Fällen ergab
42 Zuordnungen mit `MAC >= 0,70` und 12 explizit nicht zugeordnete Fälle mit
niedrigem MAC. Bei den zugeordneten Moden lag der relative Frequenzfehler
zwischen 0,0375 % und 12,9747 %. Die größere Abweichung tritt bei einer
höheren Biegemode auf; daraus folgt keine entsprechende Abweichung für die
Grundfrequenzen.

### Ergänzender Vergleich aller sechs Frequenzen

Auf Nachfrage wurden zusätzlich für alle 384 Fälle des Modal-Trainingssplits
die sechs niedrigsten analytischen Euler-Bernoulli-Biegeschwingungsfrequenzen
aus beiden Biegerichtungen berechnet. Die FEM-Frequenzen und analytischen
Frequenzen wurden jeweils aufsteigend sortiert und Rang für Rang verglichen;
Modenformen wurden dabei nicht verwendet. Die analytische Frequenzfamilie
verwendet die ersten sechs Kragträger-Wurzeln je Biegerichtung. Dieser
Zusatzvergleich liest weiterhin keine Validierungs- oder Testlabels.

| Frequenzrang | Häufigste analytische Biegemode | Median absoluter Fehler | P95 | Maximum | Fälle mit Fehler <= 1 % | Fälle mit Fehler <= 5 % |
|---:|---|---:|---:|---:|---:|---:|
| 1 | y-Biegung, 1. Mode (352/384) | 0,155 % | 0,632 % | 1,184 % | 380/384 | 384/384 |
| 2 | z-Biegung, 1. Mode (352/384) | 0,646 % | 2,024 % | 3,248 % | 265/384 | 384/384 |
| 3 | y-Biegung, 2. Mode (352/384) | 3,436 % | 8,159 % | 12,250 % | 5/384 | 278/384 |
| 4 | z-Biegung, 2. Mode (352/384) | 6,773 % | 32,614 % | 47,601 % | 0/384 | 98/384 |
| 5 | y-Biegung, 3. Mode (352/384) | 44,293 % | 61,311 % | 67,160 % | 0/384 | 0/384 |
| 6 | z-Biegung, 3. Mode (327/384) | 37,166 % | 53,469 % | 61,283 % | 0/384 | 0/384 |

Über alle 2.304 Rangvergleiche beträgt der Median des absoluten relativen
Fehlers 5,069 %, das 95. Perzentil 52,982 % und der größte Fehler 67,160 %.
Diese Gesamtwerte werden von den höheren Frequenzrängen dominiert und sollten
nicht als eine einzelne Gütekennzahl für alle sechs Moden missverstanden
werden.

**Einordnung:** Die ersten beiden Frequenzen stimmen sehr gut mit den
analytischen Grundbiegefrequenzen überein. Ab Rang 3 nimmt die Übereinstimmung
ab; die 3. analytischen Biegemoden stimmen mit den FEM-Frequenzen im Rang 5
und 6 schlecht überein. Damit sind nicht alle sechs FEM-Frequenzen durch das
verwendete einfache Balkenmodell bestätigt. Das beweist nicht, dass die
höheren FEM-Frequenzen falsch sind: Das Euler-Bernoulli-Modell berücksichtigt
hier weder Torsions-/Axialmoden noch die vollständigen 3D-, Schub- und
Rotationsinertieeffekte. Die Rangzuordnung ist ein reiner Frequenzvergleich,
keine Identifikation der tatsächlichen FEM-Modenfamilien.

## Netzverfeinerung

Die Bereiche geben Minimum und Maximum über die drei repräsentativen Fälle
beziehungsweise über die sechs verfolgten Moden pro Fall an:

| Größe | Mesh 3 → 4 | Mesh 4 → 6 |
|---|---:|---:|
| Statisches gewichtetes Feldänderungsmaß | 0,0260–0,0471 % | 0,0244–0,0435 % |
| Relative Änderung der Spitzendurchbiegung | 0,0216–0,0389 % | 0,0202–0,0355 % |
| Relative Frequenzänderung | 0,0128–0,1719 % | 0,0143–0,1205 % |

Die Mesh-3-Neuberechnungen stimmen für die drei ausgewählten statischen Fälle
und deren gespeicherte Felder sowie für alle 18 Frequenzen der drei modalen
Fälle exakt mit den vorhandenen Produktionsreferenzen überein
(relative Differenz 0 in den gespeicherten Vergleichen). Das ist eine
Konsistenzprüfung der Implementierung, kein unabhängiger Nachweis der
Modellrichtigkeit.

## Einschränkungen und Hinweise

- Die Balkenlösungen sind eindimensionale Näherungen und erfassen nicht alle
  dreidimensionalen Effekte der FEM.
- Die Netzergebnisse umfassen nur drei vorab ausgewählte Geometrien je
  Berechnungsart; sie belegen keine Konvergenz über den gesamten
  Parameterraum.
- Die Modenformzuordnung ist auf sechs Frequenzindizes und drei Fälle
  beschränkt. Niedrige MAC-Werte wurden nicht künstlich einer Mode zugeordnet.
- MATLAB meldete bei den modalen Beobachtungen, dass Punkte der quadratischen
  Mesh-Knotenliste von der Tetraeder-Triangulation nicht referenziert werden.
  Der Beobachtungscode trianguliert hierfür die Eckknoten und nutzt die
  quadratischen Freiheitsgrade anschließend in der Interpolation. Alle
  angefragten Referenzpunkte passierten die vorhandenen Punktlage- und
  Interpolationsassertionen; die Warnung wurde dennoch nicht unterdrückt.
- Der MATLAB Code Analyzer meldet 11 nicht-funktionale Hinweise, vor allem
  Schleifenwachstum und nicht verwendete Argumente/Ausgaben. Die ausgeführte
  Version ist anhand des Skript-Hashes im Manifest nachvollziehbar; das Skript
  wurde nach der Ausführung nicht verändert.
- Diese Studie bewertet FEM-Referenzen, nicht die Güte oder Generalisierung
  eines Ersatzmodells. Ein MLP-Vergleich sollte erst anschließend und mit
  weiterhin unangetastetem Testsplit erfolgen.

## Ergebnisdateien

- [static_axis_errors.csv](static_axis_errors.csv) und
  [static_axis_profiles.csv](static_axis_profiles.csv)
- [modal_frequency_screen.csv](modal_frequency_screen.csv)
- [static_mesh_convergence.csv](static_mesh_convergence.csv)
- [modal_mesh_convergence.csv](modal_mesh_convergence.csv)
- [modal_analytical_mode_matches.csv](modal_analytical_mode_matches.csv)
- [modal_all6_frequency_comparison.csv](modal_all6_frequency_comparison.csv) und
  [modal_all6_frequency_summary.csv](modal_all6_frequency_summary.csv)
- [modal_mesh3_vs_stored.csv](modal_mesh3_vs_stored.csv)
- [mesh_run_attempts.csv](mesh_run_attempts.csv) und
  [mesh_study_summary.mat](mesh_study_summary.mat)
