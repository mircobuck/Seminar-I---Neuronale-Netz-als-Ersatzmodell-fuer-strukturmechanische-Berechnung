"""Arbeitet die Anmerkungen in die von Hand bearbeitete PPTX ein.

Aufruf:  python aktualisiere_praesentation.py EINGABE.pptx AUSGABE.pptx
Vorher: fem_nachrechnung.py, vortragsbilder_v2.py
"""
import sys

from pptx.oxml.ns import qn

from folien_helfer import (DATA, IMG, MUTED, Image, Inches, Presentation, T_NN, de, np, read, text)
from vortragsbilder_v2 import daten, fehler

R = daten()
E = {k: fehler(R, k) for k in ("eb", "mlp", "pod")}
EB12 = fehler(R, "eb", (1, 2))
T = np.median([float(z["gesamt_s"]) for z in read(DATA / "fem_nachrechnung_zeiten.csv")])
X = f"{round(T / T_NN, -1):.0f}"

prs = Presentation(sys.argv[1])
F = list(prs.slides)


def sh(s, i):
    return next(x for x in s.shapes if x.shape_id == i)


def setze(s, i, t, absatz=0):
    r = sh(s, i).text_frame.paragraphs[absatz].runs
    r[0].text = t
    for x in r[1:]:
        x._r.getparent().remove(x._r)


def weg(s, *ids):
    for i in ids:
        e = sh(s, i)._element
        e.getparent().remove(e)


def bild(s, i, name, box):
    """Bild an gleicher Stelle der Ebenenreihenfolge ersetzen, proportional in box."""
    p = sh(s, i)
    _, rid = s.part.get_or_add_image_part(str(IMG / f"{name}.png"))
    b = p._element.find(qn("p:blipFill"))
    blip = b.find(qn("a:blip"))
    blip.set(qn("r:embed"), rid)
    for kind, tag in ((blip, "a:extLst"), (b, "a:srcRect")):
        x = kind.find(qn(tag))
        if x is not None:
            kind.remove(x)
    w, h = Image.open(IMG / f"{name}.png").size
    k = min(box[2] / w, box[3] / h)
    p.width, p.height = Inches(w * k), Inches(h * k)
    p.left, p.top = Inches(box[0] + (box[2] - w * k) / 2), Inches(box[1] + (box[3] - h * k) / 2)
    p.name = name


def lage(s, i, y=None, w=None):
    q = sh(s, i)
    if y is not None:
        q.top = Inches(y)
    if w is not None:
        q.width = Inches(w)


def notiz(s, t):
    s.notes_slide.notes_text_frame.text = t


# 1 Titel: neues Balkenbild
bild(F[0], 6, "biegebalken", (8.1, 1.75, 4.45, 3.3))

# 2 Aufgabe
s = F[1]
weg(s, 7, 10, 13)
setze(s, 3, "FEM braucht Sekunden, ein Netz Millisekunden")
bild(s, 5, "biegebalken", (0.8, 1.85, 6.1, 2.85))
setze(s, 8, f"≈ {de(T)} s")
setze(s, 9, "3D-FEM pro Balken (6 Moden)")
setze(s, 12, "Vorhersage MLP / POD-MLP pro Balken")
setze(s, 14, f"≈ {X}×")
for i in (8, 9, 11, 12, 14, 15):
    lage(s, i, w=4.9)
notiz(s, "Eingespannter Balken, sechs Parameter: L, b, h, E, ν und ρ (statisch: F statt ρ). Per Latin Hypercube gezogen, "
      "je Fall eine 3D-FEM-Rechnung. Modal: 384 Trainings- und 64 Testbalken mit je sechs Eigenfrequenzen. "
      f"Zeiten: FEM-Nachrechnung der 64 Testbalken, Median {de(T)} s (davon rund 0,9 s Eigenwertlösung), Netz "
      f"{de(1e3 * T_NN, 0)} ms, beides auf demselben Laptop. Die FEM-Zeit stammt aus einer eigenen Implementierung "
      "(scikit-fem), nicht aus der MATLAB PDE Toolbox, mit der die Daten erzeugt wurden. Die früher genannten 12 s waren "
      "die Gesamtzeit der Datenerzeugung auf einem anderen Rechner (mit Vernetzung, Suche über ein Frequenzband und "
      "Interpolation).")

# 4 Statik
s = F[3]
weg(s, 7)
text(s, 0.6, 5.85, 6.2, 0.6, [[("Euler-Bernoulli: ", {"bold": True}),
     ("analytische Biegetheorie ohne Schub, dient als Kontrolle", {})],
     "w(x) = F x² (3L − x) / (6 E I). Fehler werden gegen die FEM berechnet."], size=13, space_after=2,
     name="Erklaerung Euler-Bernoulli")
notiz(s, "Was ist Euler-Bernoulli? Die klassische analytische Biegetheorie: Querschnitte bleiben eben und senkrecht zur "
      "Balkenachse, Schubverformung wird vernachlässigt. Sie ist unsere unabhängige Kontrollkurve. Die Referenz für alle "
      "Fehlerangaben ist die FEM. " + s.notes_slide.notes_text_frame.text)

# 5 (ausgeblendet): nur Notiz richtigstellen
notiz(F[4], "Die sechs ersten Eigenformen aus der FEM für einen Beispielbalken. Biegemoden: Euler-Bernoulli. "
      "Die Torsionsmode wird getrennt mit der Saint-Venant-Theorie berechnet. Deshalb müssen die Moden vor "
      "dem Vergleich nach Typ zugeordnet werden.")

# 6 Kernergebnis
s = F[5]
weg(s, 5, 8, 14)
setze(s, 3, "Ab Mode 3 sind die Netze genauer als Euler-Bernoulli")
bild(s, 4, "modal_fehler_pro_mode_v2", (0.5, 1.65, 8.8, 4.6))
setze(s, 6, f"{de(E['mlp'])} %")
setze(s, 9, f"{de(E['pod'])} %")
setze(s, 12, f"{de(E['eb'])} %")
setze(s, 13, "Euler-Bernoulli, alle 6 Moden")
for i in (6, 7, 9, 10, 12, 13):
    lage(s, i, w=3.0)
text(s, 0.6, 6.5, 12.1, 0.5, "Mittel über 64 unterschiedliche Biegebalken (Testfälle), Moden nach Schwingungstyp "
     "zugeordnet. Torsion und Längsschwingung mit klassischer Stabtheorie. Netze: gemittelte Vorhersage aus "
     "3 Trainings.", size=12, color=MUTED, name="Hinweis")
notiz(s, "Mittlerer relativer Fehler zur FEM über 64 verschiedene Testbalken. Die Moden sind nach Typ zugeordnet "
      "(Biegung y/z, Torsion, Längs); dazu wurde jeder Balken mit einer zweiten FEM nachgerechnet. Euler-Bernoulli: "
      f"{de(EB12, 2)} % bei Mode 1–2, {de(E['eb'])} % über alle sechs. Grund: Die Balken sind gedrungen (L/h von gut 4 "
      "bis 15). Bei höheren Moden zählen Schub und Rotationsträgheit, und genau das vernachlässigt Euler-Bernoulli. "
      f"Die Netze liegen über alle Moden bei {de(E['mlp'])} bzw. {de(E['pod'])} %. Bei Mode 1 und 2 ist Euler-Bernoulli "
      "genauer als die Netze, ab Mode 3 sind es die Netze. Ein einzelnes Netz statt des Mittels aus dreien: etwa 1,5 bzw. 1,8 %.")

# 7 Ein grosses Diagramm
s = F[6]
weg(s, 5)
setze(s, 3, "Mode 5: Netze treffen die FEM, Euler-Bernoulli nicht")
bild(s, 4, "modal_paritaet_mode5", (0.9, 1.6, 11.5, 5.5))
notiz(s, "Jeder Punkt ist einer der 64 Testbalken, x-Achse FEM, y-Achse Vorhersage. Auf der gestrichelten Linie stimmt "
      "die Vorhersage mit der FEM überein. MLP und POD-MLP liegen auf der Linie. Euler-Bernoulli liegt bei den Balken "
      "darüber, deren fünfte Mode die zweite Biegung in z ist (16 von 64, bis 25 %): Ohne Schubverformung ist das Modell "
      "zu steif. Wo Mode 5 eine Torsion ist (48 von 64), passt die klassische Torsionstheorie gut.")

# 8 Fazit
s = F[7]
setze(s, 5, f"MLP und POD-MLP sagen alle sechs Eigenfrequenzen mit {de(E['mlp'])} bis {de(E['pod'])} % Fehler voraus, "
      f"rund {X}× schneller als die FEM.")
setze(s, 7, "Analytik stark bei den Grundmoden")
setze(s, 8, f"Euler-Bernoulli: {de(EB12)} % bei Mode 1–2, {de(E['eb'])} % über alle 6 Moden. "
      "Ab Mode 3 sind die Netze genauer.")

prs.save(sys.argv[2])
print("gespeichert", sys.argv[2], E, "EB12", EB12, "T", T, "x", X)
