# Statischer Samplingvergleich: Trainingsstatus und Fehler

Datierte Ergaenzung, 29.10.2026. Keine neuen Trainingslaeufe; Quelle: `experiments/active/restfield_sampling48_20261028_v1/summary.csv`. Alle 18 auswertbaren Laeufe bleiben erhalten.

| Design | Seed | Abbruchgrund | P95 % | Ziel <= 1 % |
|---|---:|---|---:|---|
| uniform_01 | 42 | Max iterations completed | 1.4565 | nein |
| uniform_01 | 43 | Max iterations completed | 0.7979 | ja |
| uniform_01 | 44 | Suitable learning rate not found | 0.8382 | ja |
| uniform_02 | 42 | Max iterations completed | 0.7879 | ja |
| uniform_02 | 43 | Max iterations completed | 1.4881 | nein |
| uniform_02 | 44 | Suitable learning rate not found | 1.2492 | nein |
| uniform_03 | 42 | Suitable learning rate not found | 0.8515 | ja |
| uniform_03 | 43 | Suitable learning rate not found | 0.7560 | ja |
| uniform_03 | 44 | Max iterations completed | 0.7776 | ja |
| lhs_01 | 42 | Suitable learning rate not found | 1.0462 | nein |
| lhs_01 | 43 | Max iterations completed | 0.7443 | ja |
| lhs_01 | 44 | Suitable learning rate not found | 1.6880 | nein |
| lhs_02 | 42 | Max iterations completed | 0.4306 | ja |
| lhs_02 | 43 | Max iterations completed | 0.8565 | ja |
| lhs_02 | 44 | Max iterations completed | 1.3236 | nein |
| lhs_03 | 42 | Suitable learning rate not found | 1.3158 | nein |
| lhs_03 | 43 | Suitable learning rate not found | 2.7171 | nein |
| lhs_03 | 44 | Suitable learning rate not found | 2.5672 | nein |

Neun Fits endeten mit nicht gefundener Schrittweite: Mittelwert des Lauf-P95 1.448 %, Median 1.249 %, Ziel bei 3/9. Neun erreichten das Iterationslimit: Mittelwert 0.963 %, Median 0.798 %, Ziel bei 6/9. Auch ein Iterationslimit belegt keine Konvergenz. Die deskriptive Differenz ist nicht kausal interpretierbar: Design, Seed, Daten und Optimierungsverlauf sind vermischt; insbesondere stammen drei Abbrueche aus demselben schwierigen LHS-Design. Die zugehoerigen drei Seeds sind keine unabhaengigen Designs.

48 Faelle genuegten im urspruenglichen Design; eine zuverlaessige Uebertragung auf andere 48-Fall-Designs wurde nicht bestaetigt. Ein konsistenter LHS-Vorteil ist nicht belegt; eine designuebergreifend robuste Mindestdatenmenge ist weiterhin unbekannt. Die verwendete Entwicklungsvalidierung ist kein unabhaengiger Abschlusstest.
