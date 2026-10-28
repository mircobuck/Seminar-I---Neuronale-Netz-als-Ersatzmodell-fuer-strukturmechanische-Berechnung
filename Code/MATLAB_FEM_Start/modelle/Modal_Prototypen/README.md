# Modalmodelle und Prototypen

## Modalmodell

- [`../Framework/+femstudy/+models/fitFrequency.m`](../Framework/+femstudy/+models/fitFrequency.m): Frequenzvorhersage.
- [`../Framework/+femstudy/+models/predictFrequency.m`](../Framework/+femstudy/+models/predictFrequency.m): Frequenzvorhersage zur Inferenz.

Ein Frequenzmodell sagt keine FEM-Eigenformen voraus.

## Neuronale Prototypen

- PINN: `../Framework/+femstudy/+models/fitPINN.m` und `predictPINN.m`.
- Fourier-Modell: `../Framework/+femstudy/+models/fitFNO.m` und `predictFNO.m`.
- Graphmodell: `../Framework/+femstudy/+models/fitGraph.m`, `predictGraph.m` und `buildGraph.m`.

Diese Pfade sind Prototypen und nicht mit vollstaendigen Modellreproduktionen
gleichzusetzen. Ihre Grenzen sind in der aktiven Vergleichsstudie dokumentiert.