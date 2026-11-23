"""Gemeinsame Kennzahlen und Folienbausteine fuer die Vortragsskripte (python-pptx)."""
import csv
from pathlib import Path

import numpy as np
from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt, Emu

HERE = Path(__file__).resolve().parent
BASE = HERE.parent
IMG = BASE / "abbildungen"
DATA = BASE / "daten"
STAT = BASE.parent / "Ausarbeitung" / "Masterseminar_Statischer_Vergleich" / "daten"

NAVY = RGBColor(0x14, 0x21, 0x3D)
INK = RGBColor(0x1B, 0x24, 0x30)
MUTED = RGBColor(0x5B, 0x64, 0x70)
LIGHT = RGBColor(0xF2, 0xF4, 0xF7)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
BLUE = RGBColor(0x2A, 0x78, 0xD6)
ORANGE = RGBColor(0xEB, 0x68, 0x34)
ICE = RGBColor(0xC9, 0xD6, 0xEA)
HEAD, BODY = "Cambria", "Calibri"

W, H = 13.333, 7.5


def read(p):
    with open(p, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


# ------------------------------------------------------------ Kennzahlen
P = read(DATA / "modal_test_vorhersagen.csv")


def err(key, modes=range(1, 7)):
    r = [x for x in P if int(x["mode"]) in modes]
    f = np.array([float(x["fem"]) for x in r]); y = np.array([float(x[key]) for x in r])
    return 100 * np.mean(np.abs(y - f) / f)


E_MLP, E_POD = err("mlpMean"), err("podMlpMean")
E_EB12, E_EB46 = err("analytic", (1, 2)), err("analytic", (4, 5, 6))
E_MLP12, E_POD12 = err("mlpMean", (1, 2)), err("podMlpMean", (1, 2))
E_MLP46, E_POD46 = err("mlpMean", (4, 5, 6)), err("podMlpMean", (4, 5, 6))
T_FEM = float(read(DATA / "modal_fem_zeit.csv")[0]["femMedian_s"])
Z = read(DATA / "modal_zeiten.csv")
T_NN = np.median([float(z["predMlpSingle_s"]) for z in Z] + [float(z["predPodMlpSingle_s"]) for z in Z])
T_FIT = np.median([float(z["fitMlp_s"]) for z in Z] + [float(z["fitPodMlp_s"]) for z in Z])
SPEED = T_FEM / T_NN
S = read(STAT / "pipeline_summary_corrected.csv")
def stat(m, role):
    return 100 * float(next(r for r in S if r["role"] == role and r["method"] == m and r["n"] == "768")["meanError"])
B = read(STAT / "benchmark_summary.csv")
T_FEM_STAT = float(B[0]["femSingleMedian"])


def de(x, d=1):
    return f"{x:.{d}f}".replace(".", ",")


# ------------------------------------------------------------ Hilfen
prs = Presentation()
prs.slide_width, prs.slide_height = Inches(W), Inches(H)
BLANK = prs.slide_layouts[6]


def bg(slide, color):
    f = slide.background.fill; f.solid(); f.fore_color.rgb = color


def text(slide, x, y, w, h, runs, size=16, color=INK, font=BODY, bold=False, align=PP_ALIGN.LEFT,
         anchor=MSO_ANCHOR.TOP, italic=False, space_after=6, name=None):
    """runs: str oder Liste von Absaetzen; Absatz = str oder Liste (text, opts)."""
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    if name: tb.name = name
    tf = tb.text_frame; tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = anchor
    paras = runs if isinstance(runs, list) else [runs]
    for i, para in enumerate(paras):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align; p.space_after = Pt(space_after)
        segs = para if isinstance(para, list) else [(para, {})]
        for seg in segs:
            t, o = (seg, {}) if isinstance(seg, str) else seg
            r = p.add_run(); r.text = t
            r.font.size = Pt(o.get("size", size)); r.font.name = o.get("font", font)
            r.font.bold = o.get("bold", bold); r.font.italic = o.get("italic", italic)
            r.font.color.rgb = o.get("color", color)
    return tb


def bullets(slide, x, y, w, h, items, size=16, color=INK):
    tb = text(slide, x, y, w, h, "", size=size, color=color)
    tf = tb.text_frame
    from pptx.oxml.ns import qn
    for i, it in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(10)
        pPr = p._p.get_or_add_pPr()
        pPr.set("marL", str(Emu(Inches(0.28)))); pPr.set("indent", str(-Emu(Inches(0.28))))
        bu = pPr.makeelement(qn("a:buChar"), {"char": "•"}); pPr.append(bu)
        segs = it if isinstance(it, list) else [(it, {})]
        for seg in segs:
            t, o = (seg, {}) if isinstance(seg, str) else seg
            r = p.add_run(); r.text = t; r.font.size = Pt(o.get("size", size)); r.font.name = BODY
            r.font.bold = o.get("bold", False); r.font.color.rgb = o.get("color", color)
    return tb


def image(slide, name, x, y, w=None, h=None, box=None):
    """Bild einpassen. box=(x,y,w,h): proportional einpassen und zentrieren."""
    path = IMG / f"{name}.png"
    if box:
        bx, by, bw, bh = box
        iw, ih = Image.open(path).size
        s = min(bw / iw, bh / ih); w, h = iw * s, ih * s
        x, y = bx + (bw - w) / 2, by + (bh - h) / 2
    kw = {}
    if w: kw["width"] = Inches(w)
    if h: kw["height"] = Inches(h)
    pic = slide.shapes.add_picture(str(path), Inches(x), Inches(y), **kw)
    pic.name = name
    return pic


def card(slide, x, y, w, h, fill=LIGHT, line=None, radius=0.08):
    s = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h))
    s.adjustments[0] = radius
    s.fill.solid(); s.fill.fore_color.rgb = fill
    if line: s.line.color.rgb = line; s.line.width = Pt(1.25)
    else: s.line.fill.background()
    s.shadow.inherit = False
    return s


def tag(slide, label, color):
    s = card(slide, 0.6, 0.38, 0.22 + 0.105 * len(label), 0.32, fill=color, radius=0.5)
    tf = s.text_frame; tf.margin_left = tf.margin_right = Inches(0.05); tf.margin_top = tf.margin_bottom = 0
    p = tf.paragraphs[0]; p.alignment = PP_ALIGN.CENTER
    r = p.add_run(); r.text = label.upper(); r.font.size = Pt(11); r.font.bold = True
    r.font.name = BODY; r.font.color.rgb = WHITE
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE


def content(title, section, color, notes=""):
    s = prs.slides.add_slide(BLANK); bg(s, WHITE)
    tag(s, section, color)
    text(s, 0.6, 0.8, 12.1, 0.9, title, size=32, font=HEAD, bold=True, color=INK, name="Titel")
    if notes: s.notes_slide.notes_text_frame.text = notes
    return s


def stat_box(slide, x, y, w, value, label, color=INK, vsize=40):
    card(slide, x, y, w, 1.55)
    text(slide, x + 0.25, y + 0.15, w - 0.5, 0.75, value, size=vsize, font=HEAD, bold=True, color=color)
    text(slide, x + 0.25, y + 0.95, w - 0.5, 0.55, label, size=13, color=MUTED)


def divider(num, title, sub, notes=""):
    s = prs.slides.add_slide(BLANK); bg(s, NAVY)
    text(s, 0.9, 2.3, 3, 1.2, num, size=72, font=HEAD, bold=True, color=ORANGE)
    text(s, 0.9, 3.5, 11, 1.0, title, size=40, font=HEAD, bold=True, color=WHITE)
    text(s, 0.9, 4.5, 11, 0.8, sub, size=18, color=ICE)
    if notes: s.notes_slide.notes_text_frame.text = notes
    return s


METH, MOD, STA = "Methodik", "Modalanalyse", "Statik"
GREY = MUTED

