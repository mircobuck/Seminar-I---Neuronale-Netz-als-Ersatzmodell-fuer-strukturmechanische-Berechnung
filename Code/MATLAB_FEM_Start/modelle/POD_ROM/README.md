# POD und ROM

- [`pod_fit.m`](pod_fit.m): Aufbau der POD-Basis.
- [`pod_encode.m`](pod_encode.m): Projektion von Feldern auf POD-Koeffizienten.
- [`rom_assemble.m`](rom_assemble.m), [`rom_observation.m`](rom_observation.m) und [`rom_predict.m`](rom_predict.m): reduziertes physikalisches Modell.
- [`../Framework/+femstudy/+models/fitBeamField.m`](../Framework/+femstudy/+models/fitBeamField.m): hybrider Balken-/POD-Feldpfad.

POD ist auch Bestandteil des MLP-Feldmodells und daher nicht nur eine alternative
Modellrichtung.