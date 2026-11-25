"""Unabhaengige 3D-FEM-Nachrechnung der 64 modalen Testbalken + Balkentheorie.

Warum: Der Datensatz speichert nur Frequenzen. Um die Analytik fair zu pruefen,
muss bekannt sein, WELCHE Schwingung zu jeder Frequenz gehoert (Biegung y/z,
Torsion, Laengs). Dieses Skript rechnet jeden Testbalken neu (scikit-fem,
quadratische Hexaeder), kontrolliert die Frequenzen gegen die gespeicherten
MATLAB-Werte, bestimmt den Modentyp und vergleicht mit den analytischen Formeln.
Nebenbei wird gemessen, wie lange eine schlanke FEM auf diesem Rechner braucht.

Aufruf:  python fem_nachrechnung.py   (numpy, scipy, scikit-fem)
"""
import csv
import time
from pathlib import Path

import numpy as np
from scipy.linalg import eigh
from scipy.sparse import coo_matrix
from scipy.sparse.linalg import eigsh
from skfem import Basis, BilinearForm, ElementHex2, ElementVector, MeshHex, asm
from skfem.helpers import ddot, dot, sym_grad, trace

DATA = Path(__file__).resolve().parent.parent / "daten"
LAM = np.array([1.875104068711961, 4.694091132974175, 7.854757438237613, 10.995540734875467])


# ------------------------------------------------------------------ 3D-FEM
def element_matrix(form, m, e):
    B = Basis(m, ElementVector(ElementHex2()), intorder=4, elements=[e])
    d = B.element_dofs[:, 0]
    return asm(form, B).tocsr()[d][:, d].toarray()


def fem(L, b, h, E, nu, rho, k=6, teiler=3, pruefen=False):
    """Eigenfrequenzen, Zeiten (Netz, Assemblierung, Loesung) und Modentypen."""
    t0 = time.perf_counter()
    H = min(b, h) / teiler
    n = [max(2, int(np.ceil(v / H))) for v in (L, b, h)]
    m = MeshHex.init_tensor(np.linspace(0, L, n[0] + 1), np.linspace(-b / 2, b / 2, n[1] + 1),
                            np.linspace(-h / 2, h / 2, n[2] + 1))
    t1 = time.perf_counter()
    B = Basis(m, ElementVector(ElementHex2()), intorder=4)
    lam, mu = E * nu / (1 + nu) / (1 - 2 * nu), E / 2 / (1 + nu)

    @BilinearForm
    def stiff(u, v, w):
        return 2 * mu * ddot(sym_grad(u), sym_grad(v)) + lam * trace(sym_grad(u)) * trace(sym_grad(v))

    @BilinearForm
    def mass(u, v, w):
        return rho * dot(u, v)

    # Alle Quader-Elemente sind kongruent: Elementmatrix einmal, dann einsortieren.
    ke, me = (element_matrix(form, m, 0) for form in (stiff, mass))
    ed = B.element_dofs; nl, ne = ed.shape
    I, J = np.repeat(ed, nl, axis=0).ravel("F"), np.tile(ed, (nl, 1)).ravel("F")
    K, M = (coo_matrix((np.tile(e.ravel(), ne), (I, J)), shape=(B.N, B.N)).tocsr() for e in (ke, me))
    if pruefen:  # gegen vollstaendige Assemblierung und letztes Element kontrollieren
        assert abs(K - asm(stiff, B)).max() < 1e-9 * abs(K).max()
        assert abs(M - asm(mass, B)).max() < 1e-9 * abs(M).max()
    fix = B.get_dofs(lambda x: np.isclose(x[0], 0)).all()
    fr = np.setdiff1d(np.arange(B.N), fix)
    K, M = K[fr][:, fr].tocsc(), M[fr][:, fr].tocsc()
    t2 = time.perf_counter()
    w2, V = eigsh(K, k=k, M=M, sigma=0)
    t3 = time.perf_counter()
    f = np.sqrt(w2) / 2 / np.pi
    o = np.argsort(f); f, V = f[o], V[:, o]
    U = np.zeros((B.N, k)); U[fr] = V
    # Freiheitsgrade -> Koordinate und Richtung
    X = B.doflocs; comp = np.zeros(B.N, int)
    for grp in (B.nodal_dofs, B.edge_dofs, B.facet_dofs, B.interior_dofs):
        for r in range(grp.shape[0]):
            comp[grp[r]] = r % 3
    s = X[0] / L; nb = 24; bi = np.minimum(nb - 1, (s * nb).astype(int))

    def mittel(werte, maske):
        z = np.bincount(bi[maske], werte[maske], nb); c = np.bincount(bi[maske], minlength=nb)
        return z / np.maximum(c, 1)

    typen = []
    ip = (b * b + h * h) / 12
    for j in range(k):
        u = U[:, j]
        ax, uy, uz = (mittel(u, comp == c) for c in range(3))
        rot = (mittel(X[1] * u, comp == 2) - mittel(X[2] * u, comp == 1)) / ip
        en = [np.mean(uy ** 2), np.mean(uz ** 2), np.mean(rot ** 2) * ip, np.mean(ax ** 2)]
        i = int(np.argmax(en)); c = [uy, uz, rot, ax][i]
        c = c[np.abs(c) > 0.04 * np.abs(c).max()]
        typen.append(("yztx"[i], 1 + int(np.sum(np.diff(np.sign(c)) != 0)), en[i] / sum(en)))
    return f, typen, (t1 - t0, t2 - t1, t3 - t2), B.N


# ------------------------------------------------------------- Balkentheorie
def timoshenko(L, E, G, I, A, rho, nu, N=12):
    """Timoshenko-Kragtraeger, Ritz mit Legendre-Polynomen (spektral genau)."""
    from numpy.polynomial import legendre as le
    ka = 10 * (1 + nu) / (12 + 11 * nu)
    x, w = le.leggauss(40); s = (x + 1) / 2; W = np.diag(w / 2 * L)
    V, D = [], []
    for i in range(N):
        c = np.eye(N)[i]
        P, dP = le.legval(x, c), le.legval(x, le.legder(c)) if i else 0 * x
        V.append(s * P); D.append((P + 2 * s * dP) / L)
    V, D = np.array(V).T, np.array(D).T; O = np.zeros((N, N))
    K = np.block([[ka * G * A * D.T @ W @ D, -ka * G * A * D.T @ W @ V],
                  [-ka * G * A * V.T @ W @ D, E * I * D.T @ W @ D + ka * G * A * V.T @ W @ V]])
    M = np.block([[rho * A * V.T @ W @ V, O], [O, rho * I * V.T @ W @ V]])
    return np.sqrt(eigh(K, M, eigvals_only=True)[:4]) / 2 / np.pi


def torsion_J(b, h, n=60):
    """Saint-Venant-Torsionskonstante des Rechtecks (exakte Reihe)."""
    p, q = max(b, h), min(b, h)
    k = np.arange(1, 2 * n, 2)
    return p * q ** 3 * (1 / 3 - 64 / np.pi ** 5 * q / p * np.sum(np.tanh(k * np.pi * p / 2 / q) / k ** 5))


def analytik(L, b, h, E, nu, rho):
    A, G = b * h, E / 2 / (1 + nu)
    eb, ti = {}, {}
    for d, I in (("y", h * b ** 3 / 12), ("z", b * h ** 3 / 12)):
        for n, (a, c) in enumerate(zip(LAM ** 2 / 2 / np.pi / L ** 2 * np.sqrt(E * I / rho / A),
                                       timoshenko(L, E, G, I, A, rho, nu)), 1):
            eb[f"{d}{n}"], ti[f"{d}{n}"] = a, c
    J, Ip = torsion_J(b, h), A * (b * b + h * h) / 12
    for n in (1, 2):
        ti[f"t{n}"] = eb[f"t{n}"] = (2 * n - 1) / 4 / L * np.sqrt(G * J / rho / Ip)
        ti[f"x{n}"] = eb[f"x{n}"] = (2 * n - 1) / 4 / L * np.sqrt(E / rho)
    return eb, ti


def main():
    P = list(csv.DictReader(open(DATA / "modal_test_vorhersagen.csv", encoding="utf-8-sig")))
    par = list(csv.DictReader(open(DATA / "modal_test_parameter.csv", encoding="utf-8-sig")))
    fem(1, .08, .1, 2e11, .3, 7850, pruefen=True)  # Kontrolle der Assemblierung + Aufwaermen
    rows, zeiten = [], []
    for q in par:
        x = [float(q[k]) for k in ("L", "b", "h", "E", "nu", "rho")]
        soll = [float(r["fem"]) for r in sorted((r for r in P if r["id"] == q["id"]), key=lambda r: int(r["mode"]))]
        f, typ, t, N = fem(*x)
        eb, ti = analytik(*x)
        ebr, tir = sorted(eb.values())[:6], sorted(ti.values())[:6]
        zeiten.append([q["id"], *t, sum(t), N])
        for k in range(6):
            key = f"{typ[k][0]}{typ[k][1]}"
            rows.append([q["id"], k + 1, soll[k], f[k], typ[k][0], typ[k][1], round(typ[k][2], 4),
                         eb.get(key, ""), ti.get(key, ""), ebr[k], tir[k]])
    with open(DATA / "modal_moden_identifiziert.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["id", "mode", "femMatlab", "femNachrechnung", "typ", "ordnung", "anteil", "eulerBernoulli",
                    "timoshenko", "ebNachRang", "timoshenkoNachRang"]); w.writerows(rows)
    with open(DATA / "fem_nachrechnung_zeiten.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh); w.writerow(["id", "netz_s", "assemblierung_s", "loesung_s", "gesamt_s", "dof"])
        w.writerows(zeiten)
    print("Fertig:", len(par), "Faelle")


if __name__ == "__main__":
    main()
