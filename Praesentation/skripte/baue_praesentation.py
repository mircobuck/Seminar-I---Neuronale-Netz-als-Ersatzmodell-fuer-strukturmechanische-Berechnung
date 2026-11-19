"""Kurzfassung fuer einen ~10-minuetigen Vortrag (8 Folien).

Aufruf:  python baue_praesentation.py   ->  ../Vortrag_MLP_POD-MLP.pptx
Lange Fassung (18 Folien): baue_praesentation_lang.py
"""
from folien_helfer import *  # noqa: F401,F403

SPEED_TXT = f"{SPEED:,.0f}".replace(",", ".")

# 1 Titel ------------------------------------------------------------
s = prs.slides.add_slide(BLANK); bg(s, NAVY)
text(s, 0.8, 1.35, 7.2, 0.4, "MASTERSEMINAR I  ·  STRUKTURMECHANIK & MACHINE LEARNING", size=13, bold=True, color=ORANGE)
text(s, 0.8, 1.9, 7.0, 2.4, "Neuronale Netze als Ersatzmodell für FEM", size=40, font=HEAD, bold=True, color=WHITE)
text(s, 0.8, 4.15, 6.6, 1.2, "MLP und POD-MLP im Vergleich mit FEM und analytischer Balkentheorie – Fokus Eigenfrequenzen",
     size=18, color=ICE)
card(s, 7.95, 1.6, 4.75, 3.6, fill=WHITE, radius=0.06)
image(s, "balken_skizze", 0, 0, box=(8.1, 1.75, 4.45, 3.3))
text(s, 0.8, 6.3, 8, 0.4, "Seminarvortrag · Wintersemester 2026/27", size=13, color=ICE)
s.notes_slide.notes_text_frame.text = ("Frage: Können neuronale Netze eine teure FEM-Berechnung eines Kragbalkens ersetzen? "
    "Wir vergleichen ein direktes MLP und ein POD-MLP mit FEM und Euler-Bernoulli, Schwerpunkt Eigenfrequenzen.")

# 2 Problem & Daten ---------------------------------------------------
s = content("FEM braucht Sekunden – ein Netz Millisekunden", "Aufgabe", NAVY,
    "Eingespannter Balken, sechs Parameter: Geometrie L, b, h, Werkstoff E, ν und Dichte ρ (statisch: Kraft F). "
    "Per Latin Hypercube gezogen, jeweils eine 3D-FEM-Rechnung (MATLAB PDE Toolbox). Modal: 384 Trainings- und "
    "64 Testfälle mit je sechs Eigenfrequenzen. Eine FEM-Rechnung dauert ~12 s, das Netz nach dem Training ~7 ms.")
card(s, 0.6, 1.85, 6.5, 4.95)
image(s, "balken_skizze", 0, 0, box=(0.8, 2.0, 6.1, 2.75))
text(s, 0.9, 4.9, 6.0, 1.8, [
    [("Eingabe: ", {"bold": True}), ("L, b, h, E, ν, ρ  (statisch: F statt ρ)", {})],
    [("Ausgabe: ", {"bold": True}), ("6 Eigenfrequenzen  bzw.  Verschiebungsfeld (1575 Werte)", {})],
    [("Daten: ", {"bold": True}), ("Latin Hypercube, 3D-FEM · modal 384 Training / 64 Test", {})]], size=15)
stat_box(s, 7.5, 1.85, 5.2, f"≈ {de(T_FEM, 0)} s", "FEM-Modalanalyse pro Fall")
stat_box(s, 7.5, 3.55, 5.2, f"≈ {de(1e3 * T_NN, 0)} ms", "Vorhersage MLP / POD-MLP pro Fall")
stat_box(s, 7.5, 5.25, 5.2, f"≈ {SPEED_TXT}×", "schneller – nach einmaligem Training", color=ORANGE)

# 3 Methoden ----------------------------------------------------------
s = content("Zwei Ersatzmodelle: direkt oder über POD-Moden", "Methodik", NAVY,
    "Links das MLP: 6 Parameter rein, 3 verdeckte tanh-Schichten mit 128 Neuronen, 6 Frequenzen raus; Training mit Adam "
    "auf den mittleren quadratischen Fehler. Rechts das POD-MLP: Aus den Trainingslösungen wird per SVD eine Basis "
    "berechnet. Das Netz sagt nur die r Koeffizienten vorher, die Lösung entsteht als Mittelwert plus Linearkombination "
    "der Moden. Das lohnt sich besonders bei großen Ausgaben wie dem Verschiebungsfeld.")
for x, col_, ttl in ((0.6, BLUE, "MLP"), (6.85, ORANGE, "POD-MLP")):
    card(s, x, 1.85, 5.85, 5.0)
    text(s, x + 0.3, 2.0, 5.3, 0.5, ttl, size=22, font=HEAD, bold=True, color=col_)
image(s, "mlp_netz", 0, 0, box=(0.8, 2.5, 5.45, 2.85))
image(s, "f_mlp", 0, 0, box=(0.85, 5.55, 5.35, 0.55))
text(s, 0.9, 6.2, 5.3, 0.5, "3 × 128 tanh · Adam · 200 Epochen", size=14, color=MUTED)
image(s, "podmlp_pipeline", 0, 0, box=(7.05, 2.55, 5.45, 2.4))
image(s, "f_rek", 0, 0, box=(7.1, 5.2, 5.35, 0.75))
text(s, 7.15, 6.2, 5.3, 0.5, "Basis Φ per SVD aus Trainingsdaten · Netz lernt nur a", size=14, color=MUTED)

# 4 Eigenformen & Analytik -------------------------------------------
s = content("FEM-Eigenformen: Biegung in y und z – und Torsion", "Modalanalyse", NAVY,
    "Die sechs ersten Eigenformen aus der FEM für einen Beispielbalken. Die Biegemoden lassen sich mit der "
    "Euler-Bernoulli-Formel analytisch abschätzen. Die Torsionsmode und 3D-Effekte (Schub, Rotationsträgheit) "
    "kennt diese einfache Balkentheorie aber nicht – das wird auf der nächsten Folie wichtig.")
image(s, "eigenformen", 0, 0, box=(0.6, 1.65, 12.1, 4.15))
card(s, 0.6, 5.95, 12.1, 1.15)
image(s, "f_eb", 0, 0, box=(0.85, 6.05, 7.6, 0.95))
text(s, 8.7, 6.1, 3.8, 0.9, "Euler-Bernoulli-Kragbalken\nI = h b³/12 (y)  ·  I = b h³/12 (z)", size=14, color=MUTED)

# 5 Kernergebnis ------------------------------------------------------
s = content("Netze treffen alle Moden – Analytik nur die unteren", "Modalanalyse", NAVY,
    f"Mittlerer relativer Fehler gegenüber der FEM auf 64 Testfällen. Euler-Bernoulli ist bei Mode 1 und 2 sehr gut "
    f"({de(E_EB12, 2)} %), versagt aber ab Mode 4 ({de(E_EB46, 0)} % im Mittel über Mode 4–6). MLP und POD-MLP liegen "
    f"über alle Moden bei 1–2 %. POD-MLP braucht für die Frequenzen Rang 5 von 6 – bei so kleinen Ausgaben bringt "
    f"POD kaum Reduktion. Werte: Mittel aus drei Netzen, ein einzelnes Netz liegt bei ~1,5 bzw. 1,8 %.")
image(s, "modal_fehler_pro_mode", 0, 0, box=(0.5, 1.75, 8.6, 4.9))
stat_box(s, 9.4, 1.85, 3.3, f"{de(E_MLP, 1)} %", "MLP, alle 6 Moden", color=BLUE)
stat_box(s, 9.4, 3.55, 3.3, f"{de(E_POD, 1)} %", "POD-MLP, alle 6 Moden", color=ORANGE)
stat_box(s, 9.4, 5.25, 3.3, f"{de(E_EB46, 0)} %", "Euler-Bernoulli, Mode 4–6", color=MUTED)

# 6 Paritaet ----------------------------------------------------------
s = content("Vorhersage gegen FEM: alle Moden auf der Diagonalen", "Modalanalyse", NAVY,
    "Jeder Punkt ist ein Testfall, x-Achse FEM, y-Achse Vorhersage. Liegt ein Punkt auf der gestrichelten Linie, "
    "stimmt die Vorhersage mit der FEM überein. Beide Netze bleiben über den gesamten Frequenzbereich auf der "
    "Diagonalen, auch bei den höheren Moden.")
image(s, "modal_paritaet", 0, 0, box=(0.6, 1.7, 12.1, 5.6))

# 7 Statik ------------------------------------------------------------
s = content("Statik: Biegelinie getroffen, Extrapolation schwerer", "Statik", NAVY,
    "Kurz zur Statik: Für das Verschiebungsfeld mit 1575 Werten reicht ein POD-Rang von 2. Links ein typischer "
    "Testfall – FEM, Euler-Bernoulli und beide Netze liegen praktisch übereinander. Rechts die Hauptstudie mit 768 "
    "Trainingsfällen: rund 5 % Feldfehler innerhalb des Trainingsbereichs; außerhalb (Extrapolation) verdreifacht "
    "sich der Fehler, POD-MLP ist dort etwas robuster.")
image(s, "statisch_biegelinie", 0, 0, box=(0.5, 1.75, 5.7, 4.7))
image(s, "statisch_genauigkeit", 0, 0, box=(6.4, 1.75, 6.4, 4.7))
text(s, 0.6, 6.6, 12, 0.4, "Rechts: statische Hauptstudie, N = 768, Testsätze Interpolation (256) und Extrapolation (128).",
     size=12, color=MUTED)

# 8 Fazit -------------------------------------------------------------
s = prs.slides.add_slide(BLANK); bg(s, NAVY)
text(s, 0.8, 0.7, 11, 0.9, "Fazit", size=40, font=HEAD, bold=True, color=WHITE)
pts = [("Schnell und genau", f"MLP und POD-MLP sagen alle sechs Eigenfrequenzen mit ≈ {de(E_MLP, 1)} % Fehler voraus – "
        f"rund {SPEED_TXT}× schneller als die FEM."),
       ("Analytik nur für Grundmoden", f"Euler-Bernoulli: {de(E_EB12, 2)} % bei Mode 1–2, aber {de(E_EB46, 0)} % bei "
        "Mode 4–6. Die Netze erfassen auch Torsion und 3D-Effekte."),
       ("POD lohnt bei großen Ausgaben", "Verschiebungsfeld: 1575 Werte → 2 Moden. Sechs Frequenzen brauchen Rang 5 – "
        "kaum Gewinn."),
       ("Grenzen", "Fehler steigen außerhalb des Trainingsbereichs stark; Training braucht Hunderte FEM-Rechnungen.")]
for i, (h1, t1) in enumerate(pts):
    x = 0.8 + (i % 2) * 6.0; y = 1.9 + (i // 2) * 2.4
    card(s, x, y, 5.7, 2.1, fill=RGBColor(0x1F, 0x30, 0x55))
    text(s, x + 0.3, y + 0.25, 5.1, 0.5, h1, size=19, bold=True, color=ORANGE)
    text(s, x + 0.3, y + 0.8, 5.1, 1.2, t1, size=15, color=WHITE)
text(s, 0.8, 6.85, 11, 0.4, "Vielen Dank – Fragen?", size=18, bold=True, color=ICE)
s.notes_slide.notes_text_frame.text = "Die vier Kernaussagen zusammenfassen, dann Fragen."

out = BASE / "Vortrag_MLP_POD-MLP.pptx"
prs.save(out)
print("gespeichert:", out, "-", len(prs.slides), "Folien")
