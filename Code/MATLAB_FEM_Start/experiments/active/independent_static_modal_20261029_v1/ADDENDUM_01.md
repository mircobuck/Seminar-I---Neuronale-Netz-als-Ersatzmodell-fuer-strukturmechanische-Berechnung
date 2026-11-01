# Technischer Nachtrag 01, 29.10.2026

Der erste Vorbereitungsaufruf brach vor Modellergaenzung, Holdout-Design und
FEM ab: Die Lernkurven-Vorverarbeitung speichert das Gitter nicht selbst.
Der Adapter uebernimmt das Gitter aus der bereits geprueften n=384-Trainingsdatei
und vergleicht die POD-Gewichte mit deren Gewichten. Keine Modellauswahl,
kein Holdout-Label und keine geplante Versuchseinstellung wurde geaendert.
