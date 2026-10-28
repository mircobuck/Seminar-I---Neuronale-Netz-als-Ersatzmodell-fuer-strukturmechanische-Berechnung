# MLP mit Adam

## Implementierung

- [`fit_mlp.m`](fit_mlp.m): gemeinsamer MLP-Fitter. Definiert zwei `tanh`-Schichten und trainiert mit `trainnet` und Adam.
- [`../Grundlagen/predict_reg.m`](../Grundlagen/predict_reg.m): Vorhersage des trainierten MLP-Regressors.
- [`../Grundlagen/train_models.m`](../Grundlagen/train_models.m): aelterer POD-MLP-Vergleich; trainiert daneben weitere Baselines.
- [`../Framework/+femstudy/+models/fitNeural.m`](../Framework/+femstudy/+models/fitNeural.m): neuronaler Modellpfad fuer POD-Felder, Restfelder oder Frequenzen; ruft `fit_mlp` auf.
- [`../Framework/+femstudy/+models/predictNeural.m`](../Framework/+femstudy/+models/predictNeural.m): Vorhersage fuer den neueren neuronalen Modellpfad.
- [`scripts/matlab/run_neural_comparison.m`](../../scripts/matlab/run_neural_comparison.m): Runner der aktuellen neuronalen Vergleichsstudie.

Das klassische Feldmodell sagt POD-Koeffizienten voraus; das Verschiebungsfeld wird
anschliessend mit der POD-Basis rekonstruiert. Die Trainingsoptionen und Adam-Parameter
stehen in `fit_mlp.m`.