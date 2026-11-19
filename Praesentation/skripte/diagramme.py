"""Erzeugt alle Abbildungen fuer den Vortrag aus ../daten (und den Studien-CSVs).

Keine Modellanpassung - nur Darstellung. Aufruf:  python diagramme.py
Benoetigt numpy und matplotlib.
"""
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
DATA = HERE.parent / "daten"
OUT = HERE.parent / "abbildungen"
OUT.mkdir(exist_ok=True)
STAT = ROOT / "Ausarbeitung" / "Masterseminar_Statischer_Vergleich" / "daten"
VALID = ROOT / "Code v2" / "studies" / "fem_reference_validation_v1" / "results"

# Farben: FEM = Referenz (dunkel), Analytik = grau, MLP = blau, POD-MLP = orange
INK, MUTED, GRID = "#1b2430", "#5b6470", "#d9dde2"
FEM, ANA, MLP, POD = "#1b2430", "#8a929c", "#2a78d6", "#eb6834"
plt.rcParams.update({
    "font.family": "Calibri", "font.size": 13, "axes.edgecolor": MUTED,
    "axes.labelcolor": INK, "xtick.color": MUTED, "ytick.color": MUTED,
    "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True,
    "grid.color": GRID, "grid.linewidth": 0.8, "legend.frameon": False,
    "savefig.dpi": 220, "savefig.bbox": "tight", "savefig.facecolor": "white",
    "mathtext.fontset": "cm",
})


def read(path):
    with open(path, encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def save(name, trim=False):
    plt.savefig(OUT / f"{name}.png")
    plt.close("all")
    if trim:  # 3D-Achsen lassen viel Weissraum - automatisch beschneiden
        from PIL import Image, ImageChops
        im = Image.open(OUT / f"{name}.png").convert("RGB")
        bbox = ImageChops.difference(im, Image.new("RGB", im.size, "white")).getbbox()
        if bbox:
            pad = 20
            im.crop((max(bbox[0] - pad, 0), max(bbox[1] - pad, 0), min(bbox[2] + pad, im.width),
                     min(bbox[3] + pad, im.height))).save(OUT / f"{name}.png")


def de(v, fmt):
    return format(v, fmt).replace(".", ",")


def log_ticks(ax, ticks):
    """Logarithmische y-Achse mit lesbaren Dezimalzahlen statt 10er-Potenzen."""
    from matplotlib.ticker import FixedLocator, NullFormatter, NullLocator
    ax.yaxis.set_major_locator(FixedLocator(ticks))
    ax.yaxis.set_minor_locator(NullLocator()); ax.yaxis.set_minor_formatter(NullFormatter())
    ax.set_yticks(ticks, [de(t, "g") for t in ticks])


def col(rows, key):
    return np.array([float(r[key]) for r in rows])


# ------------------------------------------------------------- Formeln
FORMELN = {
    "f_mlp": r"$\mathbf{h}^{(\ell)}=\tanh\!\left(\mathbf{W}^{(\ell)}\mathbf{h}^{(\ell-1)}+\mathbf{b}^{(\ell)}\right),\quad \hat{\mathbf{y}}=\mathbf{W}^{(L)}\mathbf{h}^{(L-1)}+\mathbf{b}^{(L)}$",
    "f_norm": r"$\tilde{x}_j=\dfrac{x_j-\mu_j}{\sigma_j}\qquad \mathcal{L}=\dfrac{1}{N}\sum_{i=1}^{N}\left\Vert\hat{\mathbf{y}}_i-\mathbf{y}_i\right\Vert^2$",
    "f_snap": r"$\mathbf{Y}=\left[\,\mathbf{y}_1-\bar{\mathbf{y}}\;\;\mathbf{y}_2-\bar{\mathbf{y}}\;\cdots\;\mathbf{y}_N-\bar{\mathbf{y}}\,\right]=\mathbf{U}\,\mathbf{\Sigma}\,\mathbf{V}^{\top}$",
    "f_rek": r"$\mathbf{y}(\mathbf{p})\approx\bar{\mathbf{y}}+\sum_{k=1}^{r}a_k(\mathbf{p})\,\boldsymbol{\varphi}_k\qquad a_k=\boldsymbol{\varphi}_k^{\top}(\mathbf{y}-\bar{\mathbf{y}})$",
    "f_energie": r"$E(r)=\dfrac{\sum_{k=1}^{r}\sigma_k^2}{\sum_{k}\sigma_k^2}$",
    "f_eb": r"$f_n=\dfrac{\lambda_n^2}{2\pi L^2}\sqrt{\dfrac{E\,I}{\rho A}}\qquad \lambda_1=1{,}875\;\;\lambda_2=4{,}694\;\;\lambda_3=7{,}855$",
    "f_eb_stat": r"$w(x)=\dfrac{F\,x^2\,(3L-x)}{6\,E\,I}\qquad I_z=\dfrac{b\,h^3}{12}$",
    "f_fehler": r"$\varepsilon_j=\dfrac{|\hat f_j-f_j^{\mathrm{FEM}}|}{f_j^{\mathrm{FEM}}}$",
    "f_feldfehler": r"$\varepsilon=\dfrac{\Vert\hat{\mathbf{u}}-\mathbf{u}^{\mathrm{FEM}}\Vert_W}{\Vert\mathbf{u}^{\mathrm{FEM}}\Vert_W}$",
    "f_fem": r"$\left(\mathbf{K}-\omega^2\mathbf{M}\right)\boldsymbol{\phi}=\mathbf{0}\qquad f=\dfrac{\omega}{2\pi}$",
}


def formeln():
    for name, tex in FORMELN.items():
        fig = plt.figure(figsize=(0.01, 0.01))
        fig.text(0, 0, tex, fontsize=26, color=INK)
        plt.savefig(OUT / f"{name}.png", transparent=True, bbox_inches="tight", pad_inches=0.05, dpi=250)
        plt.close(fig)


# ------------------------------------------------------- 3D-Balkenhilfe
def grid_index(coords):
    ix = np.rint(coords[:, 0] * 20).astype(int)
    iy = np.rint(coords[:, 1] * 4).astype(int)
    iz = np.rint(coords[:, 2] * 4).astype(int)
    G = -np.ones((21, 5, 5), int)
    G[ix, iy, iz] = np.arange(len(coords))
    assert (G >= 0).all()
    return G


def beam_faces(P, G):
    """Aussenflaechen des 21x5x5-Gitters als Vierecke + Index der Knoten."""
    quads = []
    for i in range(20):
        for j in range(4):
            for fixed in (0, 4):
                quads.append([G[i, j, fixed], G[i + 1, j, fixed], G[i + 1, j + 1, fixed], G[i, j + 1, fixed]])
                quads.append([G[i, fixed, j], G[i + 1, fixed, j], G[i + 1, fixed, j + 1], G[i, fixed, j + 1]])
    for j in range(4):
        for k in range(4):
            quads.append([G[20, j, k], G[20, j + 1, k], G[20, j + 1, k + 1], G[20, j, k + 1]])
    return np.array(quads)


def draw_beam(ax, X, U, scale, cvals=None, cmap="viridis", vmax=None, alpha=1.0, ghost=True):
    G = grid_index(X / X.max(axis=0))
    q = beam_faces(X, G)
    D = X + scale * U
    if ghost:
        verts0 = X[q]
        ax.add_collection3d(Poly3DCollection(verts0, facecolor="none", edgecolor="#c5cad1", linewidth=0.3))
    verts = D[q]
    if cvals is None:
        cvals = np.linalg.norm(U, axis=1)
    c = cvals[q].mean(axis=1)
    norm = plt.Normalize(0, vmax if vmax else c.max())
    pc = Poly3DCollection(verts, facecolor=plt.get_cmap(cmap)(norm(c)), edgecolor="#1b2430", linewidth=0.15, alpha=alpha)
    ax.add_collection3d(pc)
    allp = np.vstack([X, D])
    lo, hi = allp.min(axis=0), allp.max(axis=0)
    ctr, span = (lo + hi) / 2, (hi - lo).max() / 2
    ax.set_xlim(ctr[0] - span, ctr[0] + span)
    ax.set_ylim(ctr[1] - span * 0.45, ctr[1] + span * 0.45)
    ax.set_zlim(ctr[2] - span * 0.45, ctr[2] + span * 0.45)
    ax.set_box_aspect((1, 0.45, 0.45), zoom=1.35)
    ax.set_axis_off()
    # Einspannung
    y0, y1 = X[:, 1].min(), X[:, 1].max(); z0, z1 = X[:, 2].min(), X[:, 2].max()
    pad = 0.04 * span
    wall = [[(0, y0 - pad, z0 - pad), (0, y1 + pad, z0 - pad), (0, y1 + pad, z1 + pad), (0, y0 - pad, z1 + pad)]]
    ax.add_collection3d(Poly3DCollection(wall, facecolor="#9aa3ad", edgecolor="#5b6470", alpha=0.6))


def mode_type(U):
    """Grobe Modenklassifikation aus den Verschiebungsanteilen."""
    ux, uy, uz = (np.abs(U[:, k]).mean() for k in range(3))
    return ux, uy, uz


# --------------------------------------------------------------- Skizze
def skizze():
    L, b, h = 1.0, 0.16, 0.22
    xs = np.linspace(0, 1, 21); ys = np.linspace(0, 1, 5); zs = np.linspace(0, 1, 5)
    X = np.array([[x, y, z] for z in zs for y in ys for x in xs])
    P = X * [L, b, h]
    fig = plt.figure(figsize=(11, 7))
    ax = fig.add_axes([0.1, 0.1, 0.8, 0.8], projection="3d")
    draw_beam(ax, P, np.zeros_like(P), 0, cvals=np.zeros(len(P)) + 0.35, cmap="Blues", vmax=1, ghost=False)
    ax.view_init(elev=18, azim=-62)
    ax.set_xlim(-0.05, 1.15); ax.set_ylim(-0.4, 0.55); ax.set_zlim(-0.35, 0.6)
    ax.quiver(L, b / 2, h + 0.33, 0, 0, -0.28, color="#e34948", linewidth=2.5, arrow_length_ratio=0.25)
    ax.text(L + 0.02, b / 2, h + 0.36, r"$F_z$", fontsize=20, color="#e34948")
    ax.text(L / 2, -0.12, -0.06, r"$L$", fontsize=20, color=INK)
    ax.text(L + 0.05, b / 2, -0.07, r"$b$", fontsize=20, color=INK)
    ax.text(L + 0.01, b + 0.02, h / 2, r"$h$", fontsize=20, color=INK)
    ax.text(0.25, b, h + 0.12, r"$E,\ \nu,\ \rho$", fontsize=18, color=INK)
    save("balken_skizze", trim=True)


# ----------------------------------------------------------- MLP-Netz
def netz(ax, layers, labels_in, labels_out, colors, hidden_note):
    xs = np.linspace(0, 1, len(layers))
    pos = []
    for x, n in zip(xs, layers):
        ys = np.linspace(0.9, 0.1, n) if n > 1 else [0.5]
        pos.append([(x, y) for y in ys])
    for a, b in zip(pos, pos[1:]):
        for p in a:
            for q in b:
                ax.plot([p[0], q[0]], [p[1], q[1]], color="#b9c0c8", lw=0.5, zorder=1)
    for li, (lay, c) in enumerate(zip(pos, colors)):
        for p in lay:
            ax.scatter(*p, s=330, color=c, edgecolor="white", linewidth=1.5, zorder=3)
    for p, t in zip(pos[0], labels_in):
        ax.text(p[0] - 0.05, p[1], t, ha="right", va="center", fontsize=17, color=INK)
    for p, t in zip(pos[-1], labels_out):
        ax.text(p[0] + 0.05, p[1], t, ha="left", va="center", fontsize=17, color=INK)
    for x, t in hidden_note:
        ax.text(x, -0.02, t, ha="center", va="top", fontsize=13, color=MUTED)
    ax.set_xlim(-0.25, 1.22); ax.set_ylim(-0.12, 1.0); ax.axis("off")


def mlp_bild():
    fig, ax = plt.subplots(figsize=(10, 5.2))
    xs = np.linspace(0, 1, 5)
    netz(ax, [6, 9, 9, 9, 6],
         [r"$L$", r"$b$", r"$h$", r"$E$", r"$\nu$", r"$\rho$"],
         [rf"$f_{k}$" for k in range(1, 7)],
         ["#5b6470", MLP, MLP, MLP, "#1b2430"],
         [(xs[0], "Eingabe\n6 Parameter"), (xs[1], "tanh\n128"), (xs[2], "tanh\n128"), (xs[3], "tanh\n128"), (xs[4], "linear\n6 Frequenzen")])
    ax.grid(False)
    save("mlp_netz")


def podmlp_bild():
    fig, ax = plt.subplots(figsize=(13, 5.0))
    ax.grid(False); ax.axis("off"); ax.set_xlim(0, 13); ax.set_ylim(0, 5)
    # kleines Netz links
    sub = fig.add_axes([0.02, 0.08, 0.40, 0.84])
    xs = np.linspace(0, 1, 5)
    netz(sub, [6, 7, 7, 7, 5],
         [r"$L$", r"$b$", r"$h$", r"$E$", r"$\nu$", r"$\rho$"],
         [rf"$a_{k}$" for k in range(1, 6)],
         ["#5b6470", POD, POD, POD, "#1b2430"],
         [(xs[0], "6 Parameter"), (xs[1], "tanh 80"), (xs[2], "tanh 80"), (xs[3], "tanh 80"), (xs[4], "r POD-\nKoeffizienten")])
    sub.grid(False)
    # Rekonstruktion rechts
    box = FancyBboxPatch((6.3, 1.25), 2.6, 2.5, boxstyle="round,pad=0.1", fc="#fdf0ea", ec=POD, lw=1.8)
    ax.add_patch(box)
    ax.text(7.6, 3.15, "POD-Basis", ha="center", fontsize=17, color=INK, weight="bold")
    ax.text(7.6, 2.3, r"$\bar{\mathbf{y}}+\mathbf{\Phi}_r\,\mathbf{a}$", ha="center", fontsize=24, color=INK)
    ax.text(7.6, 1.55, "aus FEM-Training (SVD)", ha="center", fontsize=12, color=MUTED)
    ax.add_patch(FancyArrowPatch((5.55, 2.5), (6.2, 2.5), arrowstyle="-|>", mutation_scale=22, color=INK, lw=2))
    ax.add_patch(FancyArrowPatch((9.1, 2.5), (9.8, 2.5), arrowstyle="-|>", mutation_scale=22, color=INK, lw=2))
    ax.text(9.95, 3.0, "Statisch: 1575 Verschiebungen", fontsize=15, color=INK, va="center")
    ax.text(9.95, 2.0, r"Modal: $f_1,\dots,f_6$", fontsize=15, color=INK, va="center")
    save("podmlp_pipeline")


# --------------------------------------------------- Modal: Eigenformen
NAMEN = {}


def eigenformen(cid=910037):
    M = np.loadtxt(DATA / f"eigenformen_{cid}.csv", delimiter=",")
    f = col(read(DATA / f"eigenfrequenzen_{cid}.csv"), "fHz")
    p = np.loadtxt(DATA / f"parameter_{cid}.csv", delimiter=",")
    L, b, h = p[:3]
    X = M[:, :3] * [L, b, h]
    fig = plt.figure(figsize=(15, 7.6))
    labels = []
    for k in range(6):
        U = M[:, 3 + 3 * k: 6 + 3 * k]
        ux, uy, uz = mode_type(U)
        # Torsion: Querschnitt dreht -> uy wechselt Vorzeichen ueber z
        G = grid_index(M[:, :3])
        tip = G[20]
        tors = abs(U[tip[2, 0], 1] - U[tip[2, 4], 1]) > abs(U[tip[2, 0], 1] + U[tip[2, 4], 1])
        if ux > max(uy, uz):
            t = "Längsschwingung"
        elif min(uy, uz) > 0.3 * max(uy, uz):  # y und z gleichzeitig -> Querschnitt dreht
            t = "Torsion"
        else:
            # Ordnung = Anzahl Nulldurchgaenge der Mittelachse + 1
            comp = 1 if uy > uz else 2
            ax_line = np.array([U[G[i, 2, 2], comp] for i in range(21)])
            n = 1 + np.sum(np.diff(np.sign(ax_line[1:])) != 0)
            t = f"{n}. Biegung {'y' if comp == 1 else 'z'}"
        labels.append(t)
        ax = fig.add_subplot(2, 3, k + 1, projection="3d")
        s = 0.12 * L / np.abs(U).max()
        draw_beam(ax, X, U, s, cmap="viridis")
        ax.view_init(elev=22, azim=-58)
        ax.set_title(f"Mode {k + 1}:  {f[k]:.0f} Hz\n{t}", fontsize=16, color=INK, pad=-4)
    fig.subplots_adjust(wspace=0.0, hspace=0.05, left=0, right=1, top=0.95, bottom=0)
    save("eigenformen", trim=True)
    return labels


# ------------------------------------------------- Modal: Analytik/FEM
def analytik():
    S = read(VALID / "modal_all6_frequency_summary.csv")
    P = read(DATA / "modal_test_vorhersagen.csv")
    fig, axes = plt.subplots(1, 2, figsize=(13, 5.2), gridspec_kw={"width_ratios": [1, 1.25]})
    ax = axes[0]
    for m, mk in ((1, "o"), (2, "s")):
        r = [x for x in P if int(x["mode"]) == m]
        ax.scatter(col(r, "fem"), col(r, "analytic"), s=40, marker=mk, color=ANA if m == 1 else INK,
                   edgecolor="white", linewidth=0.8, label=f"Mode {m}", zorder=3)
    lim = [20, 200]
    ax.plot(lim, lim, color=MUTED, lw=1.2, ls="--", zorder=2)
    ax.set_xlim(lim); ax.set_ylim(lim)
    ax.set_xlabel("FEM-Frequenz [Hz]"); ax.set_ylabel("Euler-Bernoulli [Hz]")
    ax.set_title("Grundbiegemoden: Analytik ≈ FEM", fontsize=15, color=INK, loc="left")
    ax.legend(loc="upper left")
    ax = axes[1]
    rk = np.arange(1, 7); med = []; p95 = []
    for m in rk:
        r = [x for x in P if int(x["mode"]) == m]
        e = 100 * np.abs(col(r, "analytic") - col(r, "fem")) / col(r, "fem")
        med.append(np.median(e)); p95.append(np.percentile(e, 95))
    med, p95 = np.array(med), np.array(p95)
    ax.bar(rk - 0.2, med, 0.38, color=ANA, label="Median")
    ax.bar(rk + 0.2, p95, 0.38, color=INK, label="95. Perzentil")
    for x, v in zip(rk, med):
        ax.text(x - 0.2, v + 1, de(v, ".1f"), ha="center", fontsize=11, color=INK)
    ax.set_xticks(rk, [f"f{k}" for k in rk])
    ax.set_ylabel("Abweichung Analytik vs. FEM [%]")
    ax.set_xlabel("Frequenzrang (64 Testfälle)")
    ax.set_title("Höhere Moden: Balkentheorie versagt", fontsize=15, color=INK, loc="left")
    ax.legend(loc="upper left")
    fig.tight_layout()
    save("analytik_vs_fem")


# --------------------------------------------------- Modal: POD-Spektrum
def pod_spektrum():
    T = read(DATA / "modal_pod_spektrum.csv")
    r = col(T, "rank").astype(int)
    fig, axes = plt.subplots(1, 2, figsize=(13, 4.8))
    ax = axes[0]
    ax.bar(r, 100 * col(T, "cumEnergy"), color=POD, width=0.6)
    ax.set_ylim(95, 100.3); ax.set_xticks(r)
    ax.set_xlabel("POD-Rang r"); ax.set_ylabel("Energieanteil E(r) [%]")
    ax.set_title("97 % Energie schon mit r = 1 …", fontsize=15, loc="left", color=INK)
    ax = axes[1]
    pe = 100 * col(T, "testProjectionError")
    pe[pe <= 0] = 1e-12
    ax.semilogy(r, np.maximum(pe, 1e-4), "-o", color=POD, lw=2, ms=9)
    ax.axhline(0.1, color=MUTED, ls="--", lw=1)
    ax.text(1.05, 0.13, "0,1 %", color=MUTED, fontsize=12)
    for x, v in zip(r, pe):
        if x < 6:
            ax.annotate(de(v, ".2f") + " %", (x, v), textcoords="offset points",
                        xytext=(8, 6), fontsize=12, color=INK)
    ax.set_xticks(r); ax.set_xlabel("POD-Rang r"); ax.set_ylabel("Projektionsfehler Test [%]")
    ax.set_title("… aber erst r = 5 trifft die Frequenzen", fontsize=15, loc="left", color=INK)
    fig.tight_layout(); save("modal_pod_spektrum")


# ---------------------------------------------------- Modal: Paritaet
def paritaet():
    P = read(DATA / "modal_test_vorhersagen.csv")
    fig, axes = plt.subplots(2, 3, figsize=(15, 8.4))
    for m, ax in zip(range(1, 7), axes.flat):
        r = [x for x in P if int(x["mode"]) == m]
        fem = col(r, "fem")
        lo, hi = fem.min() * 0.9, fem.max() * 1.1
        ax.plot([lo, hi], [lo, hi], color=MUTED, lw=1.2, ls="--", zorder=1)
        if m <= 2:
            ax.scatter(fem, col(r, "analytic"), s=26, color=ANA, marker="^", label="Euler-Bernoulli", zorder=2)
        ax.scatter(fem, col(r, "mlpMean"), s=34, color=MLP, edgecolor="white", linewidth=0.6, label="MLP", zorder=3)
        ax.scatter(fem, col(r, "podMlpMean"), s=46, facecolor="none", edgecolor=POD, linewidth=1.6, marker="s",
                   label="POD-MLP", zorder=4)
        eM = 100 * np.mean(np.abs(col(r, "mlpMean") - fem) / fem)
        eP = 100 * np.mean(np.abs(col(r, "podMlpMean") - fem) / fem)
        ax.set_xlim(lo, hi); ax.set_ylim(lo, hi)
        ax.set_title(f"Mode {m}", fontsize=16, loc="left", color=INK)
        ax.text(0.97, 0.05, f"MLP {eM:.2f} %\nPOD-MLP {eP:.2f} %", transform=ax.transAxes, ha="right",
                va="bottom", fontsize=12, color=INK)
        if m in (1, 4): ax.set_ylabel("Vorhersage [Hz]")
        if m >= 4: ax.set_xlabel("FEM [Hz]")
    h, l = axes[0, 0].get_legend_handles_labels()
    fig.legend(h, l, loc="upper center", ncol=3, fontsize=14, bbox_to_anchor=(0.5, 1.02))
    fig.tight_layout(rect=(0, 0, 1, 0.96)); save("modal_paritaet")


def fehler_pro_mode():
    P = read(DATA / "modal_test_vorhersagen.csv")
    fig, ax = plt.subplots(figsize=(13, 5.2))
    w = 0.26
    for j, (key, c, lab) in enumerate((("analytic", ANA, "Euler-Bernoulli"), ("mlpMean", MLP, "MLP"),
                                        ("podMlpMean", POD, "POD-MLP"))):
        v = []
        for m in range(1, 7):
            r = [x for x in P if int(x["mode"]) == m]
            fem = col(r, "fem")
            v.append(100 * np.mean(np.abs(col(r, key) - fem) / fem))
        x = np.arange(1, 7) + (j - 1) * w
        ax.bar(x, v, w * 0.92, color=c, label=lab)
        for xi, vi in zip(x, v):
            ax.text(xi, vi * 1.12, de(vi, ".1f") if vi >= 1 else de(vi, ".2f"), ha="center", fontsize=10.5, color=INK)
    ax.set_yscale("log"); ax.set_ylim(0.05, 200); log_ticks(ax, [0.1, 1, 10, 100])
    ax.set_xticks(range(1, 7), [f"Mode {m}" for m in range(1, 7)])
    ax.set_ylabel("Mittlerer relativer Fehler [%]  (log)")
    ax.legend(loc="upper left", ncol=3)
    fig.tight_layout(); save("modal_fehler_pro_mode")


def lernkurve_modal():
    T = read(DATA / "modal_lernkurve.csv")
    Ns = sorted({int(float(r["N"])) for r in T})
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    for key, c, lab, mk in (("mlpMean", MLP, "MLP", "o"), ("podMean", POD, "POD-MLP", "s")):
        mean = [100 * np.mean([float(r[key]) for r in T if int(float(r["N"])) == n]) for n in Ns]
        lo = [100 * min(float(r[key]) for r in T if int(float(r["N"])) == n) for n in Ns]
        hi = [100 * max(float(r[key]) for r in T if int(float(r["N"])) == n) for n in Ns]
        ax.fill_between(Ns, lo, hi, color=c, alpha=0.15, lw=0)
        ax.plot(Ns, mean, "-" + mk, color=c, lw=2.2, ms=8, label=lab)
        ax.annotate(de(mean[-1], ".2f") + " %", (Ns[-1], mean[-1]), textcoords="offset points", xytext=(8, -4),
                    fontsize=12, color=INK)
    ax.set_xscale("log", base=2); ax.set_yscale("log")
    ax.set_xticks(Ns, [str(n) for n in Ns])
    ax.set_xlabel("Anzahl FEM-Trainingsfälle N"); ax.set_ylabel("Mittlerer Frequenzfehler [%]")
    log_ticks(ax, [1, 2, 5, 10, 20]); ax.legend()
    fig.tight_layout(); save("modal_lernkurve")


def rangstudie():
    T = read(DATA / "modal_rangstudie.csv")
    r = col(T, "rank").astype(int)
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    ax.plot(r, 100 * col(T, "projErr").clip(1e-5), ":o", color=MUTED, lw=1.8, ms=7, label="nur POD-Projektion")
    ax.fill_between(r, 100 * col(T, "minErr"), 100 * col(T, "maxErr"), color=POD, alpha=0.18, lw=0)
    ax.plot(r, 100 * col(T, "meanErr"), "-s", color=POD, lw=2.2, ms=8, label="POD-MLP gesamt")
    ax.set_yscale("log"); ax.set_xticks(r)
    log_ticks(ax, [0.001, 0.01, 0.1, 1, 10])
    ax.set_xlabel("POD-Rang r"); ax.set_ylabel("Mittlerer Frequenzfehler [%]")
    ax.legend()
    fig.tight_layout(); save("modal_rangstudie")


def loss():
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    for f, c, lab in (("modal_loss_mlp.csv", MLP, "MLP"), ("modal_loss_podmlp.csv", POD, "POD-MLP")):
        T = read(DATA / f)
        key = next(k for k in T[0] if "Loss" in k)
        it = col(T, "Iteration"); y = col(T, key)
        k = 25
        ys = np.convolve(y, np.ones(k) / k, mode="valid")
        ax.plot(it, y, color=c, alpha=0.18, lw=0.8)
        ax.plot(it[k - 1:], ys, color=c, lw=2.2, label=lab)
    ax.set_yscale("log"); ax.set_xlabel("Iteration (Adam, 200 Epochen)"); ax.set_ylabel("Trainingsverlust (MSE, normiert)")
    ax.legend(); fig.tight_layout(); save("modal_loss")


# ------------------------------------------------------------- Statisch
def statisch_beispiel():
    M = np.loadtxt(DATA / "statisch_beispielfeld.csv", delimiter=",")
    p = np.loadtxt(DATA / "statisch_beispielparameter.csv", delimiter=",")
    L, b, h, E, nu, F = p[1:7]
    xi = M[:, :3]; Ufem, Umlp, Upod = M[:, 3:6], M[:, 6:9], M[:, 9:12]
    G = grid_index(xi)
    axis = [G[i, 2, 2] for i in range(21)]
    x = xi[axis, 0] * L
    fig, ax = plt.subplots(figsize=(8.5, 5.2))
    xa = np.linspace(0, L, 200); I = b * h ** 3 / 12
    ax.plot(xa, 1e3 * F * xa ** 2 * (3 * L - xa) / (6 * E * I), color=ANA, lw=6, alpha=0.6, label="Euler-Bernoulli")
    ax.plot(x, 1e3 * Ufem[axis, 2], "o", color=FEM, ms=8, label="FEM", zorder=4)
    ax.plot(x, 1e3 * Umlp[axis, 2], "-", color=MLP, lw=2.2, label=f"MLP  ({de(100 * p[7], '.2f')} % Feldfehler)")
    ax.plot(x, 1e3 * Upod[axis, 2], "--", color=POD, lw=2.2, label=f"POD-MLP  ({de(100 * p[8], '.2f')} %)")
    ax.set_xlabel("x [m]"); ax.set_ylabel(r"Durchbiegung $u_z$ [mm]")
    ax.legend(loc="lower left")
    fig.tight_layout(); save("statisch_biegelinie")

    # 3D: FEM-Feld und Fehlerfeld POD-MLP
    X = xi * [L, b, h]
    s = 0.15 * L / np.abs(Ufem).max()
    fig = plt.figure(figsize=(8, 7.2))
    for k, (U, title, cv, cm) in enumerate((
            (Ufem, "FEM: Verschiebungsbetrag |u|", np.linalg.norm(Ufem, axis=1), "viridis"),
            (Upod, "POD-MLP: Fehler |û − u|", np.linalg.norm(Upod - Ufem, axis=1), "magma_r"))):
        ax = fig.add_subplot(2, 1, k + 1, projection="3d")
        draw_beam(ax, X, U, s, cvals=cv, cmap=cm, vmax=np.linalg.norm(Ufem, axis=1).max() if k == 0 else None)
        ax.view_init(elev=18, azim=-60)
        ax.set_title(title, fontsize=15, color=INK)
        sm = plt.cm.ScalarMappable(cmap=cm, norm=plt.Normalize(0, 1e3 * cv.max()))
        cb = fig.colorbar(sm, ax=ax, shrink=0.6, pad=-0.02); cb.set_label("mm", fontsize=12)
    fig.subplots_adjust(left=0, right=0.95, hspace=0.0, top=0.95, bottom=0.02)
    save("statisch_feld", trim=True)


def statisch_podmoden():
    M = np.loadtxt(DATA / "statisch_podmoden.csv", delimiter=",")
    xi = M[:, :3]; X = xi * [1.0, 0.12, 0.16]
    fig = plt.figure(figsize=(14, 4.4))
    titles = [r"Mittelwert $\bar{\mathbf{u}}$", r"POD-Mode $\boldsymbol{\varphi}_1$", r"POD-Mode $\boldsymbol{\varphi}_2$"]
    for k in range(3):
        U = M[:, 3 + 3 * k: 6 + 3 * k]
        ax = fig.add_subplot(1, 3, k + 1, projection="3d")
        draw_beam(ax, X, U, 0.2 / np.abs(U).max(), cmap="viridis")
        ax.view_init(elev=18, azim=-60)
        ax.set_title(titles[k], fontsize=18, color=INK)
    fig.subplots_adjust(left=0, right=1, wspace=0)
    save("statisch_podmoden", trim=True)


def statisch_ergebnisse():
    S = read(STAT / "pipeline_summary_corrected.csv")
    Ns = [48, 96, 192, 384, 768]
    fig, axes = plt.subplots(1, 2, figsize=(14, 5.0), gridspec_kw={"width_ratios": [1.3, 1]})
    ax = axes[0]
    for m, c, lab, mk in (("mlp", MLP, "MLP", "o"), ("pod_mlp", POD, "POD-MLP", "s")):
        v = [100 * float(next(r for r in S if r["role"] == "interpolation" and r["method"] == m and int(r["n"]) == n)["meanError"]) for n in Ns]
        ax.plot(Ns, v, "-" + mk, color=c, lw=2.2, ms=8, label=lab)
        ax.annotate(de(v[-1], ".1f") + " %", (Ns[-1], v[-1]), textcoords="offset points", xytext=(6, 6 if m == "pod_mlp" else -14),
                    fontsize=12, color=INK)
    ax.set_xscale("log", base=2); ax.set_yscale("log"); ax.set_xticks(Ns, [str(n) for n in Ns])
    ax.set_xlabel("Anzahl FEM-Trainingsfälle N"); ax.set_ylabel("Mittlerer Feldfehler [%]")
    log_ticks(ax, [2, 5, 10, 20, 50, 100])
    ax.set_title("Lernkurve (Interpolation)", fontsize=15, loc="left", color=INK); ax.legend()
    ax = axes[1]
    x = np.arange(2)
    for j, (m, c, lab) in enumerate((("mlp", MLP, "MLP"), ("pod_mlp", POD, "POD-MLP"))):
        v = [100 * float(next(r for r in S if r["role"] == role and r["method"] == m and r["n"] == "768")["meanError"])
             for role in ("interpolation", "extrapolation")]
        ax.bar(x + (j - 0.5) * 0.36, v, 0.33, color=c, label=lab)
        for xi, vi in zip(x + (j - 0.5) * 0.36, v):
            ax.text(xi, vi + 0.3, de(vi, ".1f"), ha="center", fontsize=12, color=INK)
    ax.set_xticks(x, ["Interpolation", "Extrapolation"]); ax.set_ylabel("Mittlerer Feldfehler [%]")
    ax.set_title("N = 768", fontsize=15, loc="left", color=INK); ax.legend()
    fig.tight_layout(); save("statisch_ergebnisse")


def statisch_genauigkeit():
    """Nur Interpolation/Extrapolation bei N = 768 (fuer die Kurzfassung)."""
    S = read(STAT / "pipeline_summary_corrected.csv")
    fig, ax = plt.subplots(figsize=(7.5, 5.5))
    x = np.arange(2)
    for j, (m, c, lab) in enumerate((("mlp", MLP, "MLP"), ("pod_mlp", POD, "POD-MLP"))):
        v = [100 * float(next(r for r in S if r["role"] == role and r["method"] == m and r["n"] == "768")["meanError"])
             for role in ("interpolation", "extrapolation")]
        ax.bar(x + (j - 0.5) * 0.36, v, 0.33, color=c, label=lab)
        for xi, vi in zip(x + (j - 0.5) * 0.36, v):
            ax.text(xi, vi + 0.3, de(vi, ".1f") + " %", ha="center", fontsize=13, color=INK)
    ax.set_xticks(x, ["Interpolation\n(im Trainingsbereich)", "Extrapolation\n(außerhalb)"])
    ax.set_ylabel("Mittlerer Feldfehler [%]"); ax.legend(loc="upper left")
    fig.tight_layout(); save("statisch_genauigkeit")


def main():
    formeln(); skizze(); mlp_bild(); podmlp_bild()
    labels = eigenformen(); print("Eigenformen:", labels)
    analytik(); pod_spektrum(); paritaet(); fehler_pro_mode(); lernkurve_modal(); rangstudie(); loss()
    statisch_beispiel(); statisch_podmoden(); statisch_ergebnisse(); statisch_genauigkeit()
    print("Abbildungen in", OUT)


if __name__ == "__main__":
    main()
