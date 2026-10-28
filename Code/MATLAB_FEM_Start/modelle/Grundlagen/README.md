# Gemeinsame Grundlagen

- `solve_case.m`, `generate_dataset.m` und `reference_grid.m`: FEM-Referenz und Datenerzeugung.
- `train_models.m` und `evaluate_models.m`: bisheriger Trainings- und Auswertungsablauf.
- `predict_reg.m` und `predict_surrogate.m`: gemeinsame Modellvorhersage.
- `beam_tip.m` und `field_error.m`: Balkenbaseline und Feldmetrik.

Diese Funktionen werden von mehreren Modellrichtungen verwendet und liegen deshalb
nicht in einem einzelnen Modellordner.