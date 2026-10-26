"""Build a self-contained synthesis from saved results; never call FEM or fit."""
from pathlib import Path
import csv
import re
import shutil
import subprocess
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

here = Path(__file__).resolve().parent
exp = here.parent
fig = here / "figures"
fig.mkdir(exist_ok=True)
for name in ("validation_case_errors.pdf", "validation_coefficients.pdf", "projection_vs_prediction.pdf"):
    shutil.copyfile(exp / "hybrid_static_audit_v1" / name, fig / name)
for name in ("pod_compression.pdf", "field_cases.pdf"):
    shutil.copyfile(exp / "hybrid_controlled_fits_v1" / name, fig / name)

plt.rcParams.update({"font.size": 10, "figure.figsize": (7, 3.8)})
f, ax = plt.subplots(figsize=(8, 2.4))
ax.axis("off")
labels = ["Parameter\nund Splits", "FEM und\nReferenzfelder", "Training:\nPOD / Modell", "Gespeichertes\nModell", "Vorhersage\nund Metriken"]
for i, label in enumerate(labels):
    ax.text(.1 + i*.2, .5, label, ha="center", va="center", transform=ax.transAxes,
            bbox=dict(boxstyle="round,pad=.6", facecolor="#e8f2f3", edgecolor="#245660"))
    if i < 4:
        ax.annotate("", xy=(.18+i*.2,.5), xytext=(.16+i*.2,.5),
                    xycoords="axes fraction", arrowprops=dict(arrowstyle="->", color="#245660"))
f.savefig(fig / "architektur.pdf", bbox_inches="tight"); plt.close(f)

ns = [12,24,48,96,192,384]
series = {"POD-GPR":[60.652,23.247,4.656,3.497,1.144,.384],
          "POD-RBF":[23.258,26.307,18.409,13.374,3.636,5.459],
          "POD-MLP":[21.458,9.851,13.374,31.799,8.109,3.314],
          "DeepONet":[45.756,52.130,43.260,31.177,10.429,8.835]}
# The earlier report records 13.799 for POD-MLP at N=96.
series["POD-MLP"][3] = 13.799
f, ax = plt.subplots()
for name, values in series.items(): ax.plot(ns, values, marker="o", label=name)
ax.set_xscale("log", base=2); ax.set_yscale("log")
ax.set_xticks(ns, [str(n) for n in ns]); ax.set_xlabel("Trainingsfälle N")
ax.set_ylabel("Median-Feldfehler (%)"); ax.grid(True, which="both", alpha=.25); ax.legend(ncol=2)
f.tight_layout(); f.savefig(fig / "lernkurve.pdf"); plt.close(f)
f, ax = plt.subplots()
for name, x, y in [("POD-GPR",3.05,.384),("POD-RBF",.182,5.459),("POD-MLP",7.12,3.314),("POD-Galerkin",914.7,.057)]:
    ax.scatter(x,y,s=45); ax.annotate(name,(x,y),xytext=(5,5),textcoords="offset points")
ax.set_xscale("log"); ax.set_yscale("log"); ax.set_xlabel("Historische Median-Onlinezeit (ms)")
ax.set_ylabel("Historischer Median-Feldfehler (%)"); ax.grid(True,which="both",alpha=.25)
f.tight_layout(); f.savefig(fig / "kosten.pdf"); plt.close(f)
with (here / "modal_netzwerte.csv").open(encoding="utf-8") as stream:
    net = [[float(x) for x in row] for row in csv.reader(stream)]
f, ax = plt.subplots()
for row in net: ax.plot(range(1,7), [100*x for x in row[1:]], marker="o", label=f"Fall {int(row[0])}")
ax.set_xlabel("Zugeordnete Mode"); ax.set_ylabel("Frequenzänderung /3 zu /4 (%)")
ax.set_xticks(range(1,7)); ax.grid(alpha=.25); ax.legend(); f.tight_layout()
f.savefig(fig / "modal_netz.pdf"); plt.close(f)
with (here / "modal_fehlerwerte.csv").open(encoding="utf-8") as stream:
    data = [[float(x) for x in row] for row in csv.reader(stream)]
means = [100*sum(row[i] for row in data)/len(data) for i in range(6)]
f, ax = plt.subplots(); ax.bar(range(1,7),means,color="#347b82")
ax.set_xticks(range(1,7)); ax.set_xlabel("Sortierte Frequenz"); ax.set_ylabel("Mittlerer relativer Fehler (%)")
ax.grid(axis="y",alpha=.25); f.tight_layout(); f.savefig(fig / "modal_fehler.pdf"); plt.close(f)

# Markdown viewers generally display PNGs; LaTeX keeps the vector PDFs.
for pdf in fig.glob("*.pdf"):
    subprocess.run(["pdftoppm", "-f", "1", "-l", "1", "-r", "120",
                    "-singlefile", "-png", str(pdf), str(pdf.with_suffix(""))], check=True)

def escape(s):
    mapping = {"\\":r"\textbackslash{}", "&":r"\&", "%":r"\%", "$":r"\$", "#":r"\#",
               "_":r"\_\allowbreak{}", "{":r"\{", "}":r"\}", "~":r"\textasciitilde{}", "^":r"\textasciicircum{}"}
    return "".join(mapping.get(c,c) for c in s)

def inline(s):
    parts = re.split(r"(\$[^$]+\$)", s)
    return "".join(p if p.startswith("$") and p.endswith("$") else escape(p) for p in parts)

header = r"""\documentclass[11pt,a4paper]{article}
\usepackage[ngerman]{babel}
\usepackage{fontspec,amsmath,amssymb,graphicx,geometry,booktabs,longtable,array,float,hyperref}
\geometry{margin=25mm}
\setmainfont{Latin Modern Roman}
\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue}
\emergencystretch=3em
\sloppy
\setcounter{secnumdepth}{0}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0.5em}
\begin{document}
\tableofcontents
\newpage
"""
source = (here / "ausarbeitung.md").read_text(encoding="utf-8")
for superscript, ordinary in (("⁻¹⁶","-16"),("⁻¹⁵","-15"),("⁻¹⁴","-14")):
    source = source.replace("10"+superscript, "$10^{"+ordinary+"}$")
lines = source.splitlines()
out = [header]; i = 0
while i < len(lines):
    line = lines[i].strip()
    if not line: i += 1; continue
    if line.startswith("|"):
        rows = []
        while i < len(lines) and lines[i].strip().startswith("|"):
            cells = [x.strip() for x in lines[i].strip().strip("|").split("|")]
            if not all(re.fullmatch(r"[-: ]+",c or " ") for c in cells): rows.append(cells)
            i += 1
        n = len(rows[0]); width = .80/n
        spec = "".join(r">{\raggedright\arraybackslash}p{" + f"{width:.3f}" + r"\textwidth}" for _ in range(n))
        out.append(r"\begingroup\small\begin{longtable}{" + spec + "}\n" + r"\toprule")
        out.append(" & ".join(inline(c) for c in rows[0]) + r"\\ \midrule\endhead")
        out.extend(" & ".join(inline(c) for c in row) + r"\\" for row in rows[1:])
        out.append(r"\bottomrule\end{longtable}\endgroup")
        continue
    m = re.fullmatch(r"!\[(.*)\]\(([^)]+)\)", line)
    if m:
        out.append(r"\begin{figure}[H]\centering" + "\n" +
                   r"\includegraphics[width=.95\linewidth,height=.66\textheight,keepaspectratio]{" + m.group(2).replace(".png", ".pdf") + "}\n" +
                   r"\caption{" + inline(m.group(1)) + r"}\end{figure}")
    elif line.startswith("$$") and line.endswith("$$"):
        out.append(r"\[" + line[2:-2] + r"\]")
    elif line.startswith("# "): out.append(r"\section*{" + inline(line[2:]) + "}")
    elif line.startswith("## "): out.append(r"\section{" + inline(line[3:]) + "}")
    elif line.startswith("### "): out.append(r"\subsection{" + inline(line[4:]) + "}")
    else: out.append(inline(line) + "\n")
    i += 1
out.append(r"\end{document}")
(here / "ausarbeitung.tex").write_text("\n".join(out),encoding="utf-8")
