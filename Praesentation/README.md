# Vortrag: MLP und POD-MLP gegen FEM und Analytik

- `Vortrag_MLP_POD-MLP_v2.pptx`: **aktueller Stand**, von Hand bearbeitete Kurzfassung mit eingearbeiteten Anmerkungen
  (`skripte/aktualisiere_praesentation.py EINGABE AUSGABE`, vorher `fem_nachrechnung.py` und `vortragsbilder_v2.py`)
- `Vortrag_MLP_POD-MLP.pptx`: Kurzfassung für ~10 min, 8 Folien (`skripte/baue_praesentation.py`)
- `Vortrag_MLP_POD-MLP_lang.pptx`: ausführliche Fassung, 18 Folien (`skripte/baue_praesentation_lang.py`)

Beide mit Schwerpunkt Modalanalyse und Sprechernotizen auf jeder Folie. Die gemeinsamen Bausteine stehen in `skripte/folien_helfer.py`.

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
- **Überholt:** In `Vortrag_MLP_POD-MLP.pptx` und `..._lang.pptx`, in `modal_test_vorhersagen.csv` (Spalte `analytic`)
  sowie in `analytik_vs_fem.png` und `modal_fehler_pro_mode.png` ist Euler-Bernoulli nur nach Frequenzrang und nur mit
  Biegemoden verglichen. Dadurch stehen Biegemoden gegen Torsions- und Längsmoden (bis 74 % Scheinfehler). Auch die 12 s
  und der Faktor 1.865 sind dort überholt. Gültig: `modal_moden_identifiziert.csv` und v2.
- FEM-Zeit in v2: Median der Nachrechnung mit scikit-fem auf demselben Laptop wie die Netzmessung, keine Messung der
  MATLAB PDE Toolbox. Die im Datensatz gespeicherten Zeiten enthalten Ausreißer bis 84.859 s.
- Die statischen Kennzahlen (Lernkurve, Interpolation und Extrapolation) stammen aus
  `Ausarbeitung/Masterseminar_Statischer_Vergleich/daten`. Das statische Beispiel ist neu trainiert, mit den
  Gewinnerkonfigurationen und ohne Java (die POD-Hilfen in Code v2 benötigen Java für den SHA-256-Fingerprint).
- Die Eigenformen stammen aus `Code v2/studies/fem_reference_validation_v1` (feines Netz, Fall 910037).
  Die Zuordnung ist per MAC-Wert geprüft.
