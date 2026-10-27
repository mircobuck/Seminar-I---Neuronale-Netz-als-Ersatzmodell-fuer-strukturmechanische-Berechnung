# Prototypen der fehlenden Modellfamilien

Stand: 27.10.2026

## DeepONet

`femstudy.models.fitDeepONet` und `predictDeepONet` kapseln den vorhandenen
resumierbaren Branch-/Trunk-Ansatz. Der Parameterzweig erhält den sechs-
dimensionalen Parametervektor; der Ortszweig erhält die drei normierten
Koordinaten. Drei latente Ausgabeblöcke werden mit dem Ortszweig kombiniert.
Die harte Einspannung ist im historischen Forward-Pfad über die Ortsfaktoren
enthalten. Der negative historische Lauf bleibt in `experiments/archive`.

## PINN

Der PINN-Prototyp verwendet den eindimensionalen Euler-Bernoulli-Balken

`EI w''''(x) = 0`,

mit `w(0)=0`, `w'(0)=0`, `EI w''(L)=0` und `EI w'''(L)=-F`.
Die Einspannung wird über den Faktor `x^2` hart erfüllt. Der Implementierungs-
prototyp minimiert Differential-, Momenten- und Querkraftanteile auf
Kollokationspunkten.
Er ist ausdrücklich keine gleichwertige 3-D-FEM-Feldvorhersage.

## Fourier-Gittermodell

`fitFNO`/`predictFNO` arbeiten auf dem vorhandenen regelmäßigen Abfragegitter.
Die Eingabe enthält normierte Koordinaten, den Parametervektor und eine
Einspannungsmaske. Niedrige trigonometrische Fouriermoden werden als räumliche
Merkmale verwendet; ein regularisierter Readout wird getrennt für `ux`, `uy`
und `uz` bestimmt. Dies ist ein transparenter Fourier-Feature-Prototyp und
noch keine vollständige mehrschichtige FNO-Reproduktion nach Li et al.

## Graphmodell

`buildGraph` erzeugt aus quadratischen Tetraedern gerichtete, deduplizierte
Verbindungen. Knotenmerkmale sind Koordinaten, sechs Parameter und ein
Einspannungskennzeichen. Kantenmerkmale sind relative Position und Länge.
Sechs Message-Passing-Schritte und ein regularisierter linearer Decoder bilden
den statischen Prototyp. Elementvolumina erzeugen positive Knotengewichte.
Die native Vorhersage bleibt auf dem nativen Netz; eine Übertragung auf das
gemeinsame Gitter muss über die vorhandene quadratische FEM-Interpolation
erfolgen.

## Grenzen

Die Prototyp-Prüfung belegt nur Schnittstellen, Dimensionen, Randbedingung und
Reproduzierbarkeit. Sie ersetzt keine Lernkurve, keine unabhängige Test-
auswertung und keine Aussage über die Eignung für wechselnde Motornetze.
