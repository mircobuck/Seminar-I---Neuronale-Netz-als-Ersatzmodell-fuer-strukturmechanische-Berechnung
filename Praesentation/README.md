# Vortrag: MLP und POD-MLP gegen FEM und Analytik

`Vortrag_MLP_POD-MLP.pptx`: 18 Folien, Schwerpunkt Modalanalyse, Sprechernotizen in jeder Folie.

## Neu erzeugen

1. **Daten** (MATLAB, Ordner `skripte`): `erzeuge_praesentationsdaten` (ca. 15 min, CPU).
   Trainiert MLP (3×128 tanh) und POD-MLP (Rang 5, 3×80 tanh) auf den modalen FEM-Daten
   (384 Training / 64 Test), dazu Lernkurve, Rangstudie, Euler-Bernoulli-Frequenzen und ein statisches Beispiel (N = 768).
   Teilläufe: `erzeuge_praesentationsdaten("verlust")` oder `erzeuge_praesentationsdaten("statisch")`.
2. **Abbildungen** (Python mit numpy, matplotlib, pillow): `python diagramme.py` → `abbildungen/`
3. **Folien** (python-pptx): `python baue_praesentation.py` → `Vortrag_MLP_POD-MLP.pptx`

## Hinweise zur Einordnung

- Die modalen Modelle sind eine Ergänzung für den Vortrag, keine versiegelte Studie. Die Hyperparameter wurden
  aus der statischen Studie übernommen und nicht für die modale Aufgabe optimiert.
- Die Fehler auf den Folien gelten für die gemittelte Vorhersage dreier Netze (Seeds 42–44). Ein einzelnes
  Netz liegt bei etwa 1,5 % (MLP) bzw. 1,8 % (POD-MLP).
- Euler-Bernoulli: Die 6 kleinsten analytischen Biegefrequenzen (y und z) werden nach Größe sortiert und Rang
  für Rang mit der FEM verglichen. Torsion kommt im Modell nicht vor.
- Die statischen Kennzahlen (Lernkurve, Interpolation und Extrapolation) stammen aus
  `Ausarbeitung/Masterseminar_Statischer_Vergleich/daten`. Das statische Beispiel ist neu trainiert, mit den
  Gewinnerkonfigurationen und ohne Java (die POD-Hilfen in Code v2 benötigen Java für den SHA-256-Fingerprint).
- Die Eigenformen stammen aus `Code v2/studies/fem_reference_validation_v1` (feines Netz, Fall 910037).
  Die Zuordnung ist per MAC-Wert geprüft.
