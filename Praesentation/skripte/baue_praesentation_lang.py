"""Lange Fassung (18 Folien).  Aufruf: python baue_praesentation_lang.py"""
from folien_helfer import *  # noqa: F401,F403

# ================================================================ Folien
# 1 Titel
s = prs.slides.add_slide(BLANK); bg(s, NAVY)
text(s, 0.8, 1.35, 7.2, 0.4, "MASTERSEMINAR I  ·  STRUKTURMECHANIK & MACHINE LEARNING", size=13, bold=True, color=ORANGE)
text(s, 0.8, 1.9, 7.0, 2.4, "Neuronale Netze als Ersatzmodell für FEM", size=40, font=HEAD, bold=True, color=WHITE)
text(s, 0.8, 4.15, 6.6, 1.2, "MLP und POD-MLP im Vergleich mit FEM und analytischer Balkentheorie – Fokus Eigenfrequenzen",
     size=18, color=ICE)
card(s, 7.95, 1.6, 4.75, 3.6, fill=WHITE, radius=0.06)
image(s, "balken_skizze", 0, 0, box=(8.1, 1.75, 4.45, 3.3))
text(s, 0.8, 6.3, 8, 0.4, "Seminarvortrag · Wintersemester 2026/27", size=13, color=ICE)
s.notes_slide.notes_text_frame.text = ("Thema: Können neuronale Netze teure FEM-Berechnungen eines Kragbalkens ersetzen? "
    "Wir vergleichen ein direktes MLP und ein POD-MLP mit FEM und Euler-Bernoulli – Schwerpunkt Eigenfrequenzen.")

# 2 Motivation
s = content("FEM braucht Sekunden – ein Netz Millisekunden", "Motivation", NAVY,
            "Jede FEM-Modalanalyse braucht hier im Median rund 12 s. Für Optimierung, Sensitivitätsstudien oder "
            "Echtzeitanwendungen braucht man tausende Auswertungen. Ein trainiertes Netz liefert dieselbe Antwort in "
            "Millisekunden – die Frage ist, wie genau.")
card(s, 0.6, 1.85, 6.5, 4.95)
image(s, "balken_skizze", 0, 0, box=(0.8, 2.0, 6.1, 2.9))
text(s, 0.9, 5.05, 6.0, 1.6, [[("Kragbalken, 6 Eingangsgrößen: ", {"bold": True}),
     ("Geometrie L, b, h · Werkstoff E, ν · Dichte ρ (modal) bzw. Kraft F", {})],
     [("Gesucht: ", {"bold": True}), ("6 Eigenfrequenzen bzw. Verschiebungsfeld", {})]], size=15)
stat_box(s, 7.5, 1.85, 5.2, f"≈ {de(T_FEM, 0)} s", "FEM-Modalanalyse pro Fall (Median, 3D-Tetraeder)")
stat_box(s, 7.5, 3.55, 5.2, f"≈ {de(1e3 * T_NN, 0)} ms", "Vorhersage MLP / POD-MLP pro Fall")
stat_box(s, 7.5, 5.25, 5.2, f"≈ {SPEED:,.0f}×".replace(",", "."), "schneller – nach einmaligem Training", color=ORANGE)

# 3 Datenbasis
s = content("Datenbasis: FEM-Referenzen über einen Latin Hypercube", "Daten", NAVY,
            "Parameter werden per Latin-Hypercube-Sampling gezogen. Für jeden Punkt läuft eine 3D-FEM-Rechnung "
            "(MATLAB PDE Toolbox, quadratische Tetraeder). Modal: Eigenwertproblem, die sechs kleinsten Frequenzen "
            "werden gespeichert. Training und Test sind disjunkt; der Test wird nur am Ende ausgewertet.")
rows = [("Parameter", "Bereich", "Einheit"), ("Länge L", "0,6 – 1,2", "m"), ("Breite b", "0,06 – 0,10", "m"),
        ("Höhe h", "0,08 – 0,14", "m"), ("E-Modul E", "70 – 210", "GPa"), ("Querkontraktion ν", "0,25 – 0,35", "–"),
        ("Dichte ρ (modal)", "2 700 – 8 900", "kg/m³"), ("Kraft F (statisch)", "−1 000 – −100", "N")]
tbl = s.shapes.add_table(len(rows), 3, Inches(0.6), Inches(1.9), Inches(6.4), Inches(3.9)).table
for i, row in enumerate(rows):
    for j, v in enumerate(row):
        c = tbl.cell(i, j); c.text = v
        p = c.text_frame.paragraphs[0]; p.runs[0].font.size = Pt(15); p.runs[0].font.name = BODY
        p.runs[0].font.bold = i == 0
        p.runs[0].font.color.rgb = WHITE if i == 0 else INK
        c.fill.solid(); c.fill.fore_color.rgb = NAVY if i == 0 else (LIGHT if i % 2 else WHITE)
tbl.columns[0].width = Inches(2.8); tbl.columns[1].width = Inches(2.3); tbl.columns[2].width = Inches(1.3)
card(s, 7.5, 1.9, 5.2, 2.05)
text(s, 7.75, 2.05, 4.8, 0.4, "FEM-Eigenwertproblem", size=16, bold=True)
image(s, "f_fem", 0, 0, box=(7.75, 2.55, 4.7, 0.9))
text(s, 7.75, 3.45, 4.8, 0.4, "3D, quadratische Tetraeder, eingespannt", size=13, color=MUTED)
stat_box(s, 7.5, 4.25, 2.45, "384 / 64", "modal: Training / Test", vsize=30)
stat_box(s, 10.25, 4.25, 2.45, "768", "statisch: Trainingspool")
text(s, 0.6, 6.05, 12, 0.5, "Normierung, POD-Basis und Training verwenden ausschließlich Trainingsdaten.", size=13,
     color=MUTED, italic=True)

# 4 MLP
s = content("Das MLP lernt die Abbildung Parameter → Antwort direkt", METH, BLUE,
            "Mehrschichtiges Perzeptron: jede Schicht ist eine affine Abbildung gefolgt von tanh. Eingaben und Ausgaben "
            "werden mit Mittelwert und Standardabweichung des Trainings normiert. Training mit Adam auf den mittleren "
            "quadratischen Fehler, 200 Epochen, Batchgröße 32. Für die Frequenzen: 6 Eingänge, 3×128 Neuronen, 6 Ausgänge.")
image(s, "mlp_netz", 0, 0, box=(0.4, 1.8, 7.1, 4.4))
card(s, 7.8, 1.85, 4.95, 3.0)
text(s, 8.05, 2.0, 4.5, 0.4, "Vorwärtsrechnung", size=16, bold=True)
image(s, "f_mlp", 0, 0, box=(8.05, 2.45, 4.45, 0.75))
text(s, 8.05, 3.3, 4.5, 0.4, "Normierung & Verlust", size=16, bold=True)
image(s, "f_norm", 0, 0, box=(8.05, 3.75, 4.45, 0.9))
bullets(s, 7.8, 5.1, 5.0, 1.9, ["3 verdeckte Schichten × 128, tanh", "Adam, Lernrate 10⁻³, 200 Epochen",
                                "Ausgabe: alle 6 Frequenzen gleichzeitig"], size=15)

# 5 POD
s = content("POD: Antworten durch wenige Grundmuster beschreiben", METH, ORANGE,
            "Proper Orthogonal Decomposition: Die zentrierten FEM-Trainingslösungen werden als Spalten einer Matrix "
            "gesammelt, die SVD liefert orthonormale Moden φ_k, sortiert nach Energie σ_k². Jede Lösung ist dann "
            "Mittelwert plus Linearkombination weniger Moden. Beim statischen Feld reichen 2 Moden: Mittelwert und "
            "Biegemuster dominieren.")
card(s, 0.6, 1.85, 5.6, 4.0)
text(s, 0.85, 2.0, 5.1, 0.4, "1  Snapshot-Matrix & SVD", size=16, bold=True)
image(s, "f_snap", 0, 0, box=(0.85, 2.45, 5.1, 0.7))
text(s, 0.85, 3.25, 5.1, 0.4, "2  Rekonstruktion mit r Moden", size=16, bold=True)
image(s, "f_rek", 0, 0, box=(0.85, 3.7, 5.1, 0.75))
text(s, 0.85, 4.55, 5.1, 0.4, "3  Energieanteil → Wahl von r", size=16, bold=True)
image(s, "f_energie", 0, 0, box=(0.85, 4.9, 3.6, 0.92))
image(s, "statisch_podmoden", 0, 0, box=(6.5, 1.9, 6.3, 3.0))
text(s, 6.6, 5.0, 6.1, 0.9, "Beispiel statisch: Mittelwertfeld und die ersten zwei POD-Moden des Verschiebungsfeldes "
     "(1575 Werte → 2 Koeffizienten).", size=14, color=MUTED)
text(s, 0.6, 6.15, 12.1, 0.6, [[("Idee: ", {"bold": True, "color": ORANGE}),
     ("Statt 1575 Verschiebungen muss das Netz nur noch r Koeffizienten a_k lernen.", {})]], size=17)

# 6 POD-MLP
s = content("POD-MLP: Das Netz sagt nur die POD-Koeffizienten voraus", METH, ORANGE,
            "Die POD-Basis wird einmal aus den Trainingsdaten berechnet und bleibt fest. Das Netz bildet die 6 Parameter "
            "auf r Koeffizienten ab; die Rekonstruktion ist eine einfache Matrixmultiplikation. Vorteil: kleinere "
            "Ausgabeschicht und physikalisch plausible Muster. Gewählt: statisch r = 2, 3×80; modal r = 5, 3×80.")
image(s, "podmlp_pipeline", 0, 0, box=(0.5, 1.8, 12.3, 3.6))
for i, (t1, t2) in enumerate((("Offline", "SVD der Trainingslösungen → Basis Φ_r, Mittelwert ȳ"),
                              ("Training", "MLP: p → a, Ziel a = Φ_rᵀ (y − ȳ), MSE mit gemeinsamer Skala"),
                              ("Online", "ŷ = ȳ + Φ_r · MLP(p) – nur eine Matrixmultiplikation mehr"))):
    x = 0.6 + i * 4.1
    card(s, x, 5.55, 3.9, 1.35)
    text(s, x + 0.2, 5.65, 3.5, 0.4, t1, size=16, bold=True, color=ORANGE)
    text(s, x + 0.2, 6.05, 3.5, 0.85, t2, size=14)

# 7 Abschnitt Modal
divider("01", "Modalanalyse", "Sechs Eigenfrequenzen: FEM · Euler-Bernoulli · MLP · POD-MLP",
        "Schwerpunkt des Vortrags: die Eigenfrequenzen.")

# 8 Eigenformen
s = content("Die ersten sechs Eigenformen aus der FEM", MOD, NAVY,
            "Beispielfall aus der FEM-Referenzvalidierung (feines Netz). Die Moden sind farbig nach Verschiebungsbetrag. "
            "Wichtig: Neben Biegemoden in y und z tritt eine Torsionsmode auf (hier Mode 5) – diese kennt die "
            "Euler-Bernoulli-Biegetheorie nicht. Die Zuordnung ist per MAC-Wert gegen die analytischen Biegeformen geprüft. Außerdem wechselt die Reihenfolge der Moden je nach Querschnitt (b < h oder b > h).")
image(s, "eigenformen", 0, 0, box=(0.5, 1.75, 12.3, 5.0))
text(s, 0.6, 6.85, 12.1, 0.4, "Fall 910037 · L = 0,86 m, b = 77 mm, h = 105 mm · Verformung überhöht, Farbe = |u|",
     size=12, color=MUTED)

# 9 Analytik vs FEM
s = content("Euler-Bernoulli trifft die Grundmoden – nicht die höheren", MOD, NAVY,
            "Analytischer Kragbalken: f_n aus λ_n. Für die beiden ersten Biegemoden liegt die Abweichung zur FEM im "
            "Median unter 1 %. Ab Frequenzrang 3–4 wachsen die Abweichungen stark, Rang 5 und 6 liegen im Median über 60 %: "
            "dort sind in der FEM Torsions-/Längsmoden und 3D-Effekte (Schub, Rotationsträgheit) relevant.")
card(s, 0.6, 1.8, 12.1, 1.2)
image(s, "f_eb", 0, 0, box=(0.85, 1.92, 7.6, 0.95))
text(s, 8.7, 1.98, 3.8, 0.9, "I = h b³/12 (y-Biegung)\nI = b h³/12 (z-Biegung)", size=15, color=MUTED)
image(s, "analytik_vs_fem", 0, 0, box=(0.6, 3.15, 12.1, 4.0))

# 10 POD-Spektrum modal
s = content("Sechs Frequenzen lassen sich kaum komprimieren", MOD, ORANGE,
            "POD auf den 6 Frequenzen der Trainingsfälle: Der erste Modus trägt schon 97 % der Energie (gemeinsame "
            "Skalierung mit √(E/ρ)·h/L²). Trotzdem ist der Projektionsfehler bis Rang 4 noch über 1 %, weil die "
            "Modenreihenfolge über den Parameterraum wechselt (y- vs. z-Biegung, Torsion). Erst r = 5 unterschreitet "
            "0,1 % – daher r = 5 für das modale POD-MLP.")
image(s, "modal_pod_spektrum", 0, 0, box=(0.6, 1.8, 12.1, 4.45))
text(s, 0.6, 6.4, 12.1, 0.6, [[("Folge: ", {"bold": True, "color": ORANGE}),
     ("Energie ≠ Genauigkeit. Für kleine Ausgabevektoren bringt POD kaum Reduktion (6 → 5).", {})]], size=17)

# 11 Paritaet
s = content("Vorhersage gegen FEM: alle Moden auf der Diagonalen", MOD, NAVY,
            "64 unabhängige Testfälle, Mittelwert über drei Netzinitialisierungen. Punkte auf der gestrichelten "
            "Diagonalen bedeuten perfekte Übereinstimmung mit der FEM. Für Mode 1 und 2 ist zusätzlich Euler-Bernoulli "
            "eingetragen.")
image(s, "modal_paritaet", 0, 0, box=(0.6, 1.7, 12.1, 5.6))

# 12 Fehler pro Mode
s = content("Netze über alle Moden gut – Analytik nur unten", MOD, NAVY,
            f"Mittlerer relativer Fehler je Mode auf dem Testsatz. Euler-Bernoulli: hervorragend für Mode 1–2 "
            f"({de(E_EB12, 2)} %), aber {de(E_EB46, 0)} % für Mode 4–6. MLP und POD-MLP liegen über alle Moden bei rund "
            f"1–2 %. POD-MLP ist bei den höheren Moden leicht besser, bei Mode 2 schlechter. Hinweis: Die Werte gelten für "
            f"die gemittelte Vorhersage dreier Netze; ein einzelnes Netz liegt bei etwa 1,5 % (MLP) bzw. 1,8 % (POD-MLP).")
image(s, "modal_fehler_pro_mode", 0, 0, box=(0.5, 1.75, 8.6, 4.9))
stat_box(s, 9.4, 1.85, 3.3, f"{de(E_MLP, 2)} %", "MLP – mittlerer Fehler, alle Moden (Mittel aus 3 Netzen)", color=BLUE)
stat_box(s, 9.4, 3.55, 3.3, f"{de(E_POD, 2)} %", "POD-MLP – mittlerer Fehler (Mittel aus 3 Netzen)", color=ORANGE)
stat_box(s, 9.4, 5.25, 3.3, f"{de(E_EB46, 0)} %", "Euler-Bernoulli, Mode 4–6", color=GREY)

# 13 Lernkurve & Rang
s = content("Mehr Daten helfen – kleiner Rang begrenzt POD-MLP", MOD, NAVY,
            "Links: Testfehler gegen die Zahl der FEM-Trainingsfälle (je 3 Wiederholungen, Band = Min/Max). "
            "Rechts: POD-MLP mit unterschiedlichem Rang. Bei kleinem Rang dominiert der Projektionsfehler (grau) – "
            "das Netz kann nicht besser werden als die Basis.")
image(s, "modal_lernkurve", 0, 0, box=(0.5, 1.8, 6.1, 4.3))
image(s, "modal_rangstudie", 0, 0, box=(6.75, 1.8, 6.1, 4.3))
text(s, 0.7, 6.25, 5.9, 0.7, "Lernkurve: Fehler sinkt mit N", size=16, bold=True)
text(s, 6.95, 6.25, 5.9, 0.7, "Rangstudie: r ≥ 5 nötig", size=16, bold=True)

# 14 Aufwand
s = content("Einmal trainieren, danach praktisch kostenlos auswerten", MOD, NAVY,
            "Kosten: 384 FEM-Rechnungen zu je ~12 s für die Trainingsdaten, dann ~10 s Training. Danach kostet jede "
            "Vorhersage wenige Millisekunden. Die Verlustkurven zeigen stabiles Training ohne Divergenz.")
image(s, "modal_loss", 0, 0, box=(0.5, 1.8, 6.9, 4.6))
stat_box(s, 7.8, 1.85, 4.9, f"384 × {de(T_FEM, 0)} s", "FEM-Trainingsdaten (≈ 1,3 h Rechenzeit)")
stat_box(s, 7.8, 3.55, 4.9, f"≈ {de(T_FIT, 0)} s", "Training eines Netzes (CPU)")
stat_box(s, 7.8, 5.25, 4.9, f"≈ {de(1e3 * T_NN, 0)} ms", "pro Vorhersage – ab ~400 Auswertungen lohnt es sich",
         color=ORANGE)

# 15 Abschnitt Statik
divider("02", "Statik – kurz", "Verschiebungsfeld mit 1575 Werten: hier spielt POD seine Stärke aus",
        "Kurzer Blick auf die statische Studie.")

# 16 Statisches Beispiel
s = content("Biegelinie: MLP und POD-MLP liegen auf der FEM", STA, NAVY,
            "Ein typischer Testfall (Median des POD-MLP-Fehlers). Links die Biegelinie auf der Balkenachse mit "
            "Euler-Bernoulli als analytischer Referenz, rechts das 3D-Feld und das Fehlerfeld des POD-MLP. "
            "Euler-Bernoulli weicht im Mittel um ~0,4 % von der FEM ab.")
image(s, "statisch_biegelinie", 0, 0, box=(0.5, 1.7, 6.3, 3.9))
image(s, "statisch_feld", 0, 0, box=(7.0, 1.6, 5.8, 4.05))
card(s, 0.6, 5.75, 12.1, 1.2)
image(s, "f_eb_stat", 0, 0, box=(0.85, 5.88, 4.4, 0.95))
image(s, "f_feldfehler", 0, 0, box=(6.0, 5.88, 3.4, 0.95))
text(s, 9.6, 5.95, 3.0, 0.9, "gewichtete Feldnorm über 525 Gitterpunkte", size=13, color=MUTED)

# 17 Statische Ergebnisse
s = content("Statik: ~5 % Feldfehler, Extrapolation schwerer", STA, NAVY,
            "Ergebnisse der versiegelten statischen Hauptstudie (768 Trainingsfälle, Mittel über 3 Initialisierungen). "
            "Beide Netze landen bei ca. 4,6–4,8 % in der Interpolation. Außerhalb des Trainingsbereichs (Extrapolation) "
            "verdreifacht sich der Fehler; POD-MLP ist dort etwas robuster, weil die Basis physikalische Muster erzwingt.")
image(s, "statisch_ergebnisse", 0, 0, box=(0.5, 1.75, 8.9, 4.4))
stat_box(s, 9.7, 1.85, 3.0, f"{de(stat('mlp', 'interpolation'))} %", "MLP Interpolation", color=BLUE)
stat_box(s, 9.7, 3.55, 3.0, f"{de(stat('pod_mlp', 'interpolation'))} %", "POD-MLP Interpolation", color=ORANGE)
stat_box(s, 9.7, 5.25, 3.0, f"{de(stat('pod_mlp', 'extrapolation'))} %", "POD-MLP Extrapolation", color=GREY)
text(s, 0.6, 6.4, 8.8, 0.5, "Quelle: statische Hauptstudie, Testsätze Interpolation (256) und Extrapolation (128).",
     size=12, color=MUTED)

# 18 Fazit
s = prs.slides.add_slide(BLANK); bg(s, NAVY)
text(s, 0.8, 0.7, 11, 0.9, "Fazit", size=40, font=HEAD, bold=True, color=WHITE)
SPEED_TXT = f"{SPEED:,.0f}".replace(",", ".")
pts = [("Netze ersetzen die FEM", f"MLP und POD-MLP sagen alle sechs Eigenfrequenzen mit ≈ {de(E_MLP, 1)} % Fehler "
        f"voraus – rund {SPEED_TXT}× schneller."),
       ("Analytik bleibt Goldstandard – unten", f"Euler-Bernoulli: {de(E_EB12, 2)} % für Mode 1–2, "
        f"aber {de(E_EB46, 0)} % für Mode 4–6. Die Netze lernen auch Torsion und 3D-Effekte."),
       ("POD lohnt sich bei großen Ausgaben", "Feld mit 1575 Werten → 2 Moden. Bei 6 Frequenzen braucht es r = 5 – "
        "kaum Gewinn."),
       ("Grenzen", "Fehler steigen bei Extrapolation stark; Genauigkeit hängt von Datenmenge und Rang ab.")]
for i, (h1, t1) in enumerate(pts):
    x = 0.8 + (i % 2) * 6.0; y = 1.9 + (i // 2) * 2.4
    card(s, x, y, 5.7, 2.1, fill=RGBColor(0x1F, 0x30, 0x55))
    text(s, x + 0.3, y + 0.25, 5.1, 0.5, h1, size=19, bold=True, color=ORANGE)
    text(s, x + 0.3, y + 0.8, 5.1, 1.2, t1, size=15, color=WHITE)
text(s, 0.8, 6.85, 11, 0.4, "Vielen Dank – Fragen?", size=18, bold=True, color=ICE)
s.notes_slide.notes_text_frame.text = "Zusammenfassung der vier Kernaussagen."

out = BASE / "Vortrag_MLP_POD-MLP_lang.pptx"
prs.save(out)
print("gespeichert:", out)
print(f"MLP {E_MLP:.2f} % POD {E_POD:.2f} % EB12 {E_EB12:.2f} EB46 {E_EB46:.1f} speed {SPEED:.0f} TNN {T_NN*1e3:.1f} ms")
