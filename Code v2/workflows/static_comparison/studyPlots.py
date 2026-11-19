"""Render static study figures from already frozen evaluation tables."""
import csv
import math
import os
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

out = sys.argv[1]
with open(os.path.join(out, "run_results.csv"), encoding="utf-8-sig", newline="") as stream:
    rows = list(csv.DictReader(stream))
plotdir = os.path.join(out, "plots")
os.makedirs(plotdir, exist_ok=True)
colors = {"mlp": "#4477aa", "rbf": "#cc6677", "pod_mlp": "#228833", "pod_gpr": "#aa7733"}

def number(row, key):
    try:
        return float(row[key])
    except (ValueError, KeyError):
        return math.nan

def scatter(data, xkey, ykey, xlabel, ylabel, name, transform=None):
    fig, ax = plt.subplots(figsize=(7, 4.5), layout="constrained")
    for method, color in colors.items():
        points = []
        for row in data:
            if row["method"] != method:
                continue
            x = transform(row) if transform else number(row, xkey)
            y = number(row, ykey)
            if math.isfinite(x) and math.isfinite(y):
                points.append((x, y))
        if points:
            ax.scatter(*zip(*points), s=35, alpha=.8, color=color, label=method)
    ax.set(xlabel=xlabel, ylabel=ylabel)
    ax.grid(alpha=.25)
    ax.legend(frameon=False)
    fig.savefig(os.path.join(plotdir, name), dpi=180)
    plt.close(fig)

for role in ("interpolation", "extrapolation"):
    valid = [r for r in rows if r["role"] == role and r["status"] == "ok"]
    main = [r for r in valid if r["id"].replace("/", "\\").startswith("runs\\")]
    if not main:
        continue
    scatter(main,"N","avg","Training cases","Mean weighted relative field error",role+"_error_vs_data.png")
    scatter(main,"N","fitSeconds","Training cases","Full fit time [s]",role+"_train_vs_data.png")
    scatter(main,"fitSeconds","avg","Full fit time [s]","Mean weighted relative field error",role+"_error_vs_train.png")
    scatter(main,"single","avg","Full single-case prediction time [s]","Mean weighted relative field error",role+"_error_vs_prediction.png")
    distribution = [r for r in valid if r["id"].replace("/", "\\").startswith("distribution\\")]
    if distribution:
        scatter(distribution,None,"avg","Distribution: 0 space filling, 1 skewed","Mean weighted relative field error",role+"_distribution.png",lambda r: float("skew" in r["id"]))
