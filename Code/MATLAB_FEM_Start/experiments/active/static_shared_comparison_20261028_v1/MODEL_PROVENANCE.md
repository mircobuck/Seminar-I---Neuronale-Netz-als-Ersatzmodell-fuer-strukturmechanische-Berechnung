# Modellprovenienz beim Freeze

Alle trainierten/importierten Modelle verwenden Trainings-IDs **1-12 und
25-396 (384 Fälle)** und Validierungs-IDs **13-18 (6 Fälle)**. Die eingefrorenen
neuralen Modelle wurden anhand der jeweiligen MAT-internen IDs geprüft; das
historische POD-GPR stammt aus dem n=384-`train_models`-Lauf, der genau die
gespeicherten `train.mat`/`val.mat`-Splits lädt. Der Balkenfeld-Baseline-Fall
hat keine Trainings- oder Validierungs-IDs.

SHA-256-Werte werden zusätzlich vollständig in [MODEL_MANIFEST.md](./MODEL_MANIFEST.md)
aufgeführt. Dort sind Konfiguration, Train-/Validierungsdaten, Modellartefakte,
Quellcode und Holdout-Design einzeln gehasht.

| Modell | Seed | Quellartefakt / Implementierung | Quell-SHA-256 | Eingefrorenes Artefakt-SHA-256 | Repräsentation und Auswahl |
|---|---:|---|---|---|---|
| Analytical beam field | — | `src/+femstudy/+fem/beamField.m` | `116bdb0d53a434f48a2db70d0e65beb02d17f5e177dc35377a788033f493a448` | kein Fit-Artefakt | Geschlossene Euler-Bernoulli-Feldbaseline, keine Auswahl |
| POD-MLP | 42 | `neural_comparison_20261027_v1/n384/seed42/pod.mat` | `1493707ee171c01413c9c834df2bb2b21b0346bc276b0fd8de138bedb2c948fb` | `e44b84979045fc13761e37c85283c637c3f8453e035d94bce2183ef713dd02a8` | Vollfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| POD-MLP | 43 | `neural_comparison_20261027_v1/n384/seed43/pod.mat` | `5843bc8daf187c5c853f7137ed061255ba0e264bf304d3050f36aabdc6ebe34a` | `c4fa0bafd64f2178c340fcd99a9cad65a3865a138493ea63be68f65d66954918` | Vollfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| POD-MLP | 44 | `neural_comparison_20261027_v1/n384/seed44/pod.mat` | `5740bb3165fc9984fa06d0026e8e56888136e3dc940c6e2e0230764e3877933d` | `541d6539126dc849a53717576df3f0b3ecfac5a9a9e61541e4c0bdda723b3656` | Vollfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| Beam-restfeld-MLP | 42 | `neural_comparison_20261027_v1/n384/seed42/residual.mat` | `f2ae0c4169e03c64aa6e90b0c779deee00e64318782bfce73a5c5ce169a816b6` | `b16cdab5fc255f07fdd832068d2e34b0f411d54ded6ca0d160351a008819baa7` | Balkenfeld plus Restfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| Beam-restfeld-MLP | 43 | `neural_comparison_20261027_v1/n384/seed43/residual.mat` | `2a1e05aa12b1cd4b81e549c035730b194a281d85ca880f22c9df88dcdb681f6` | `71a2c77aa2e8a0148a0d1fca0eaad68e0b70b2cfb3715dc977a0bac8be90e909` | Balkenfeld plus Restfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| Beam-restfeld-MLP | 44 | `neural_comparison_20261027_v1/n384/seed44/residual.mat` | `2005adf32a9a56052612f1d981579288c8914355096c86f77cd1b96b7bfa687a` | `525c51135dcbf0ceb77c364bedea5d4192be9f9a045694c6de2c94d7c42b6c78` | Balkenfeld plus Restfeld-POD; gespeicherte Validierungsauswahl aus Rang/Breite |
| POD-GPR | 42 | `training_size_12_24_48_20261023/n384/models.mat` | `e5882e5eba5f3dccaa1a85e311c1c81710efae34addf8b54b8eac72c4771cc77` | `752838421ad2dd9ff48bbc3617ccef6da27f4809c196805c3ff5c21839ea0697` | Vollfeld-POD, Rang 11; historisch per Validierungsfeldfehler ausgewählt |
| Beamfeld + POD-GPR-Rest | 42 | `src/+femstudy/+models/fitBeamField.m` und `models/beam_residual_gpr.mat` | `b719554b36bc67b3b86dd58c411e0f7f7f99e6111a29ed5ecd220c422c2cb59a` | `fea74c0ed297a7f81ca77f83918cf266d2d766a613428bd3896657f632e589e3` | Balkenfeld plus Rest-POD, Rang 12, ARD Matérn 5/2; Auswahl gemäß vordefiniertem Validierungsraster |

Die Quell- und Modellhashes beziehen sich auf den Freeze der Studie. Die
neuronalen und historischen POD-GPR-Trainingszeiten sind aus früheren Läufen
übernommen und keine kontrollierten, hardwaregleichen Messungen. Die neue
Restfeld-GPR-Zeit umfasst alle Kandidaten und Validierungsauswahl.
