# Modelluebersicht

Dieser Ordner enthaelt die aktiven MATLAB-Implementierungen, sortiert nach
Modellrichtung und gemeinsamen Grundlagen. Runner, Tests und Versuchsergebnisse
bleiben in ihren eigenen Projektbereichen.

## Modellrichtungen

- [MLP mit Adam](MLP_Adam/README.md): MLP fuer POD-Koeffizienten und weitere neuronale Varianten.
- [GPR und RBF](GPR_RBF/README.md): klassische Regressions-Baselines.
- [DeepONet](DeepONet/README.md): separater Operator-Learning-Ansatz.
- [POD und ROM](POD_ROM/README.md): Feldreduktion und physikalisches reduziertes Modell.
- [Modalmodelle und Prototypen](Modal_Prototypen/README.md): Frequenzvorhersage sowie PINN-, Fourier- und Graph-Prototypen.
- [Grundlagen](Grundlagen/README.md): gemeinsame FEM-, Daten-, Auswertungs- und Vorhersagefunktionen.
- `Framework/+femstudy`: paketierte gemeinsame Implementierungen und neuronale Modelladapter.

Der MATLAB-Quellcode liegt jetzt physisch in den Modellordnern. Runner, Tests,
Konfigurationen und Versuchsergebnisse bleiben in ihren eigenen Projektbereichen.