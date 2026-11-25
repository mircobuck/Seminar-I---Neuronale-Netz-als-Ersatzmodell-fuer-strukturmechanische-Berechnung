"""Neue Abbildungen fuer Vortrag v2 (Groesse = Groesse auf der Folie, daher lesbare Schrift).

Aufruf:  python vortragsbilder_v2.py   (vorher fem_nachrechnung.py)
"""
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle

from diagramme import ANA, DATA, FEM, INK, MLP, MUTED, POD, col, de, log_ticks, read, save

ROT = "#d03b3b"


def daten():
    """Je Testfall und Mode: FEM, Netze und richtig zugeordnete Analytik."""
    V = {(r["id"], r["mode"]): r for r in read(DATA / "modal_test_vorhersagen.csv")}
    out = []
    for r in read(DATA / "modal_moden_identifiziert.csv"):
        v = V[(r["id"], r["mode"])]
        out.append(dict(mode=int(r["mode"]), typ=r["typ"], fem=float(v["fem"]), eb=float(r["eulerBernoulli"]),
                        mlp=float(v["mlpMean"]), pod=float(v["podMlpMean"])))
    return out


def fehler(R, key, moden=range(1, 7)):
    return 100 * np.mean([abs(r[key] - r["fem"]) / r["fem"] for r in R if r["mode"] in moden])


def biegebalken():
    fig, ax = plt.subplots(figsize=(6.1, 2.75)); ax.set_axis_off(); ax.grid(False)
    L, h = 9.0, 0.9
    # Einspannung mit Schraffur
    ax.add_patch(Rectangle((-0.55, -1.15), 0.55, 2.3, fc="white", ec=MUTED, hatch="////", lw=0))
    ax.plot([0, 0], [-1.15, 1.15], color=INK, lw=2.4)
    # unverformter Balken
    ax.add_patch(Rectangle((0, -h / 2), L, h, fc="#a9cfe8", ec=INK, lw=1.5, zorder=3))
    ax.plot([-.2, L + .6], [0, 0], color=INK, lw=0.8, ls=(0, (9, 3, 2, 3)), zorder=4)
    # verformte Lage
    x = np.linspace(0, L, 80); w = -1.35 * x ** 2 * (3 * L - x) / (2 * L ** 3)
    dx = np.gradient(w, x); nx, ny = -dx / np.hypot(1, dx), 1 / np.hypot(1, dx)
    o = np.c_[x + nx * h / 2, w + ny * h / 2]; u = np.c_[x - nx * h / 2, w - ny * h / 2]
    ax.add_patch(Polygon(np.r_[o, u[::-1]], closed=True, fc="none", ec=MLP, lw=1.5, ls="--", zorder=2))
    ax.text(5.9, -1.85, "$w(x)$", color=MLP, fontsize=14, ha="center")
    # Kraft
    ax.annotate("", (L, h / 2 + .02), (L, h / 2 + 1.25), arrowprops=dict(arrowstyle="-|>", color=ROT, lw=2.4, mutation_scale=18), zorder=6)
    ax.text(L - .25, h / 2 + .8, "$F$", color=ROT, fontsize=17, ha="right")
    ax.text(L / 2, 0.75, r"$E,\ \nu,\ \rho$", fontsize=15, ha="center", color=INK)
    # Bemassung L
    y = -2.55
    ax.annotate("", (0, y), (L, y), arrowprops=dict(arrowstyle="<|-|>", color=MUTED, lw=1.1))
    for q in (0, L):
        ax.plot([q, q], [-1.2 if q == 0 else -1.9, y - .12], color=MUTED, lw=.8)
    ax.text(L / 2, y + .13, "$L$", fontsize=15, ha="center", color=INK)
    # Querschnitt
    X, B, Hq = 11.0, 1.15, 1.6
    ax.add_patch(Rectangle((X, -Hq / 2), B, Hq, fc="#a9cfe8", ec=INK, lw=1.5))
    ax.text(X + B / 2, Hq / 2 + .45, "Querschnitt", ha="center", fontsize=11, color=MUTED)
    ax.annotate("", (X, -1.25), (X + B, -1.25), arrowprops=dict(arrowstyle="<|-|>", color=MUTED, lw=1.1))
    ax.text(X + B / 2, -1.85, "$b$", ha="center", fontsize=15, color=INK)
    ax.annotate("", (X + B + .3, -Hq / 2), (X + B + .3, Hq / 2), arrowprops=dict(arrowstyle="<|-|>", color=MUTED, lw=1.1))
    ax.text(X + B + .5, 0, "$h$", va="center", fontsize=15, color=INK)
    ax.set_xlim(-.7, 13.1); ax.set_ylim(-2.9, 1.9)
    save("biegebalken")


def fehler_pro_mode(R):
    fig, ax = plt.subplots(figsize=(8.7, 4.5))
    S = (("eb", ANA, "Euler-Bernoulli"), ("mlp", MLP, "MLP"), ("pod", POD, "POD-MLP"))
    w = 0.27
    for j, (k, c, lab) in enumerate(S):
        v = [fehler(R, k, (m,)) for m in range(1, 7)]; x = np.arange(1, 7) + (j - 1) * w
        ax.bar(x, v, w * .9, color=c, label=lab, zorder=3)
        for a, b in zip(x, v):
            ax.text(a, b + .07, de(b, ".1f"), ha="center", fontsize=10, color=INK)
    ax.set_xticks(range(1, 7), [f"Mode {m}" for m in range(1, 7)]); ax.grid(axis="x", visible=False)
    ax.set_ylabel("Mittlerer rel. Fehler zur FEM [%]"); ax.set_ylim(0, 6.6)
    ax.legend(loc="upper left", ncol=3, fontsize=12, columnspacing=1.2, handlelength=1.3)
    fig.tight_layout(); save("modal_fehler_pro_mode_v2")


def paritaet(R, m):
    r = [q for q in R if q["mode"] == m]; f = np.array([q["fem"] for q in r])
    fig, ax = plt.subplots(figsize=(9.4, 4.9))
    lo, hi = f.min() * .9, f.max() * 1.08
    ax.plot([lo, hi], [lo, hi], color=MUTED, ls="--", lw=1.4, label="perfekt = FEM", zorder=1)
    for k, c, lab, kw in (("eb", "#6f7883", "Euler-Bernoulli", dict(marker="^", s=70, edgecolor="white", linewidth=.7, zorder=2)),
                          ("mlp", MLP, "MLP", dict(marker="o", s=44, edgecolor="white", linewidth=.6, zorder=3)),
                          ("pod", POD, "POD-MLP", dict(marker="s", s=78, facecolor="none", linewidth=1.7, zorder=4))):
        col_ = dict(edgecolor=c) if k == "pod" else dict(color=c)
        kw = {**kw, **col_}
        ax.scatter(f, [q[k] for q in r], label=f"{lab}  (Ø {de(fehler(R, k, (m,)), '.1f')} % Fehler)", **kw)
    ax.set_xlim(lo, hi); ax.set_ylim(lo, max(hi, max(q["eb"] for q in r) * 1.04))
    ax.set_xlabel("FEM-Frequenz [Hz]"); ax.set_ylabel("Vorhersage [Hz]"); ax.legend(loc="upper left", fontsize=13)
    fig.tight_layout(); save(f"modal_paritaet_mode{m}")


if __name__ == "__main__":
    R = daten(); biegebalken(); fehler_pro_mode(R)
    for m in (4, 5, 6): paritaet(R, m)
    for k in ("eb", "mlp", "pod"):
        print(k, "alle %.2f | 1-2 %.2f | 3-6 %.2f" % (fehler(R, k), fehler(R, k, (1, 2)), fehler(R, k, (3, 4, 5, 6))))
