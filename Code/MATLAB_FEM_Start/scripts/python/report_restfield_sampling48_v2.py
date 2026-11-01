"""Build the sampling comparison report from the audited MATLAB exports."""
from __future__ import annotations

import csv
import hashlib
import json
import math
from pathlib import Path
import statistics

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "experiments/active/restfield_sampling48_20261028_v1"
CFG = ROOT / "configs/restfield_sampling48_20261028_v1.json"


def read_csv(name):
    with (OUT / name).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def number(row, name):
    return float(row[name])


def put_text(path, content):
    content = content.encode("utf-8")
    if path.exists():
        if path.read_bytes() != content:
            raise RuntimeError(f"Refusing to overwrite {path}")
    else:
        with path.open("xb") as stream:
            stream.write(content)


def main():
    if not (OUT / "audit_passed.mat").is_file():
        raise RuntimeError("MATLAB audit must pass before creating a report")
    config = json.loads(CFG.read_text(encoding="utf-8"))
    summary = read_csv("summary.csv")
    cases = read_csv("case_metrics.csv")
    attempts = read_csv("attempt_ledger.csv")
    fem = read_csv("fem_ledger.csv")
    historical = read_csv("historical_n48_summary.csv")
    assert len(summary) == 24 and len(cases) == 24 * 128
    assert sum(r["Status"] == "completed" for r in fem) == 288
    for row in summary:
        group = sorted(
            float(r["Relative"])
            for r in cases
            if (r["Design"], r["Model"], r["Seed"])
            == (row["Design"], row["Model"], row["Seed"])
        )
        assert len(group) == 128
        assert math.isclose(group[121], number(row, "P95Relative"), abs_tol=1e-12)

    strategies = {}
    design_stats = {}
    for strategy in ("uniform", "lhs"):
        names = [n for n, s in zip(config["designNames"], config["strategies"]) if s == strategy]
        models = [r for r in summary if r["Strategy"] == strategy and r["Model"] == "mlp"]
        gprs = [r for r in summary if r["Strategy"] == strategy and r["Model"] == "gpr"]
        all_seeds_pass = 0
        for name in names:
            mlps = sorted((r for r in models if r["Design"] == name), key=lambda r: int(r["Seed"]))
            assert len(mlps) == 3
            p95s = [number(r, "P95Relative") for r in mlps]
            design_stats[name] = (statistics.mean(p95s), statistics.stdev(p95s), min(p95s), max(p95s))
            all_seeds_pass += all(x <= config["targetP95"] for x in p95s)
        strategies[strategy] = {
            "names": names,
            "model_success": sum(number(r, "P95Relative") <= config["targetP95"] for r in models),
            "design_success": all_seeds_pass,
            "gpr_success": sum(number(r, "P95Relative") <= config["targetP95"] for r in gprs),
            "design_means": [design_stats[n][0] for n in names],
            "design_worst": [design_stats[n][3] for n in names],
            "gpr_p95": [number(r, "P95Relative") for r in gprs],
        }

    fig, axes = plt.subplots(1, 3, figsize=(16, 5), layout="constrained")
    names = config["designNames"]
    for i, name in enumerate(names):
        mlps = sorted((r for r in summary if r["Design"] == name and r["Model"] == "mlp"), key=lambda r: int(r["Seed"]))
        gpr = next(r for r in summary if r["Design"] == name and r["Model"] == "gpr")
        for j, r in enumerate(mlps):
            axes[0].scatter(i + (j - 1) * .12, 100 * number(r, "P95Relative"), marker="o", color=f"C{j}", label=f"MLP seed {r['Seed']}" if i == 0 else None)
            axes[2].scatter(i + (j - 1) * .12, number(r, "TrainingSeconds"), marker="o", color=f"C{j}")
        axes[0].scatter(i, 100 * number(gpr, "P95Relative"), marker="x", color="black", label="GPR" if i == 0 else None)
        axes[2].scatter(i, number(gpr, "TrainingSeconds"), marker="x", color="black")
        # Per-case mean over seeds is used only for a compact view of case dispersion.
        grouped = {}
        for r in cases:
            if r["Design"] == name and r["Model"] == "mlp":
                grouped.setdefault(r["CaseID"], []).append(float(r["Relative"]) * 100)
        assert len(grouped) == 128 and all(len(x) == 3 for x in grouped.values())
        axes[1].boxplot([[statistics.mean(x) for x in grouped.values()]], positions=[i], widths=.6, showfliers=True)
    axes[0].axhline(1, color="black", linestyle="--", label="Target 1%")
    for ax in axes:
        ax.set_xticks(range(6), names, rotation=35, ha="right")
        ax.axvline(2.5, color="grey", linestyle=":")
        ax.grid(axis="y", alpha=.25)
    axes[0].set(title="P95 by design and model seed", ylabel="Relative weighted field error (%)")
    axes[0].legend(fontsize=8)
    axes[1].set(title="Case dispersion: MLP mean across seeds", ylabel="Relative weighted field error (%)")
    axes[2].set(title="Fit time", ylabel="Seconds")
    image = OUT / "sampling_comparison.png"
    if not image.exists():
        fig.savefig(image, dpi=180)
    plt.close(fig)

    def fmt(values):
        return f"{100*min(values):.3f}–{100*max(values):.3f} %; SD {100*statistics.stdev(values):.3f} Prozentpunkte"

    lines = [
        "# Abschlussbericht: Einfluss der Trainingsdatenverteilung bei 48 Faellen",
        "", "Stand: 29.10.2026. Die 128 verwendeten Faelle sind Entwicklungsvalidierung, kein unabhaengiger Abschlusstest.",
        "", "## Zielerfuellung und Vergleich", "",
        "| Strategie | MLP-Laeufe mit P95 <= 1 % | Designs: alle drei Seeds <= 1 % | GPR-Designs <= 1 % |",
        "|---|---:|---:|---:|",
    ]
    for s in ("uniform", "lhs"):
        x = strategies[s]
        lines.append(f"| {s} | {x['model_success']}/9 | {x['design_success']}/3 | {x['gpr_success']}/3 |")
    all_pass = sum(x["model_success"] for x in strategies.values())
    design_pass = sum(x["design_success"] for x in strategies.values())
    uniform = strategies["uniform"]
    lhs = strategies["lhs"]
    if max(lhs["design_worst"]) < min(uniform["design_worst"]):
        comparison = "Bei den jeweils schlechtesten MLP-Seeds liegen alle drei LHS-Designs unter allen drei Zufallsdesigns; dies ist ein konsistenter Vorteil in dieser kleinen Stichprobe."
    elif max(uniform["design_worst"]) < min(lhs["design_worst"]):
        comparison = "Bei den jeweils schlechtesten MLP-Seeds liegen alle drei Zufallsdesigns unter allen drei LHS-Designs; ein Vorteil fuer LHS zeigt sich hier nicht."
    else:
        comparison = "Die Bereiche der jeweils schlechtesten MLP-Seed-P95 ueberlappen; ein konsistenter Vorteil von LHS ist damit anhand dieser sechs Designs nicht belegt."
    lines += [
        "", f"Insgesamt erreichen {all_pass} von 18 MLP-Fits das Ziel; bei {design_pass} von sechs Designs erreichen alle drei Seeds das Ziel.",
        "", comparison,
        "", "Die drei Seeds desselben Designs sind wiederholte Modellinitialisierungen, keine unabhaengigen Trainingsdesigns. Der Vergleich umfasst nur drei unabhaengig erzeugte Designs je Strategie; die Werte erlauben keine belastbare allgemeine Ueberlegenheits- oder Zuverlaessigkeitsbehauptung.",
        "", "## Design- und Seedstreuung", "",
        "| Strategie | MLP: Designmittel der drei Seed-P95 | MLP: jeweils schlechtester Seed-P95 | GPR-P95 |",
        "|---|---|---|---|",
    ]
    for s in ("uniform", "lhs"):
        x = strategies[s]
        lines.append(f"| {s} | {fmt(x['design_means'])} | {fmt(x['design_worst'])} | {fmt(x['gpr_p95'])} |")
    lines += ["", "Spannweite und Stichproben-SD beziehen sich auf je drei Designs; SD in Prozentpunkten. Innerhalb jedes Designs:", "", "| Design | Mittel P95 % | Seed-SD Prozentpunkte | Min P95 % | Max P95 % |", "|---|---:|---:|---:|---:|"]
    for name in names:
        avg, sd, low, high = design_stats[name]
        lines.append(f"| {name} | {100*avg:.4f} | {100*sd:.4f} | {100*low:.4f} | {100*high:.4f} |")

    lines += ["", "## Vollstaendige Ergebnisse", "", "Relative Fehler und Projektion in Prozent; absolute gewichtete Vektorfeld-RMS-Werte in Metern. P95 ist nearest-rank, der 122. von 128 sortierten Faellen.", "", "| Design | Modell | Seed | POD-Rang | Mittel % | Median % | P95 % | Max % | Abs. Mittel m | Abs. Median m | Abs. P95 m | Abs. Max m | Projektion Mittel % | Projektion P95 % | Fit s | Iterationen | Abbruchgrund |", "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|"]
    for r in summary:
        f = lambda col: number(r, col)
        lines.append(f"| {r['Design']} | {r['Model']} | {r['Seed']} | {r['PODRank']} | {100*f('MeanRelative'):.4f} | {100*f('MedianRelative'):.4f} | {100*f('P95Relative'):.4f} | {100*f('MaxRelative'):.4f} | {f('MeanAbsolute_m'):.3g} | {f('MedianAbsolute_m'):.3g} | {f('P95Absolute_m'):.3g} | {f('MaxAbsolute_m'):.3g} | {100*f('MeanProjectionRelative'):.5f} | {100*f('P95ProjectionRelative'):.5f} | {f('TrainingSeconds'):.2f} | {r['Iterations']} | {r['StopReason']} |")

    old_mlp = [r for r in historical if r["Model"] == "mlp"]
    old_gpr = next(r for r in historical if r["Model"] == "gpr")
    oldp = ", ".join(f"Seed {r['Seed']}: {100*float(r['P95']):.3f} %" for r in old_mlp)
    fail_count = sum(r["Status"] != "completed" for r in attempts)
    fem_fail = sum(r["Status"] != "completed" for r in fem)
    lbfgs = [r for r in summary if r["Model"] == "mlp"]
    line_search = sum("Suitable learning rate not found" in r["StopReason"] for r in lbfgs)
    lines += [
        "", "## Historische 48-Fall-Stichprobe und Einordnung", "",
        f"Die historische Stichprobe erzielte {oldp}; GPR: {100*float(old_gpr['P95']):.3f} %. Sie ist gesonderte Vergleichsevidenz und wurde nicht als zusaetzliche Designwiederholung gezaehlt. Die fruehere Aussage '48 Trainingsfaelle reichen' galt fuer dieses eine Design und diese Entwicklungsvalidierung. Die neuen Zielzaehlungen zeigen, wie diese Aussage fuer die hier untersuchten Designs einzuordnen ist; eine Garantie fuer beliebige Designs oder einen spaeteren Test folgt daraus nicht.",
        "", "## Technik, Aufwand und Grenzen", "",
        "Alle sechs vorab gespeicherten Designs bestehen aus 48 vorab zugeordneten Faellen; Sampling und Vergleich erfolgen ohne FEM- oder Fehler-getriebene Auswahl. Die 128 zuvor erzeugten Entwicklungsreferenzen wurden unveraendert und pruefsummengesichert uebernommen. Die gleichen Validierungsfaelle wurden fuer alle Modelle verwendet.",
        "", "Je Design wurden Mittelwert, gewichtete POD und beide Skalierungen ausschliesslich aus 48 Trainingsfaellen bestimmt. MLP und GPR teilen dieselbe Darstellung. Der Pilot pruefte Designreproduktion, Fallzuordnung, Split-Trennung, gemeinsame Skalierung, Rekonstruktion, Metriken, gleiche Initialgewichte und Wiederaufnahme. Bei der Auswertung wurden Rekonstruktion und Fallmetriken erneut berechnet. Alle MATLAB-MAT-Artefakte besitzen SHA-256-Siegel.",
        "", f"FEM: {sum(float(r['Seconds']) for r in fem if r['Status']=='completed'):.2f} s fuer 288 erfolgreiche Faelle; {fem_fail} fehlgeschlagene oder unterbrochene Versuche. Kampagnen-Fitzeit: MLP {sum(number(r,'TrainingSeconds') for r in lbfgs):.2f} s, GPR {sum(number(r,'TrainingSeconds') for r in summary if r['Model']=='gpr'):.2f} s. Das sind gemessene Fit-/Solverzeiten ohne gesamte Vor- und Nachverarbeitung und ohne Pilotfits.",
        "", f"Im Modell-Ledger stehen {fail_count} fehlgeschlagene oder unterbrochene Versuche; {line_search} der 18 MLP-Kampagnenlaeufe endeten mit 'Suitable learning rate not found'. Ein auswertbarer Modellstand ist kein Konvergenznachweis. Weitere Abbruchgruende stehen einzeln in der Ergebnistabelle.",
        "", "Die Fallstreuung ist in den Fallmetriken, Quantilen und der Grafik dokumentiert; die Grafik mittelt dort zur Darstellung pro Fall ueber Seeds und zaehlt diese nicht als neue Faelle. FEM- und MLP-Zeiten sind maschinenabhaengig. Die Validierung wurde bereits bei der vorigen Datenbedarfsauswahl genutzt und jetzt erneut zur Entwicklungsentscheidung verwendet.",
        "", "## Dateien und Reproduktion", "",
        "`summary.csv`, `case_metrics.csv`, `design_summary.csv`, `strategy_summary.csv`, `target_counts.csv`, `design_target_counts.csv`, `attempt_ledger.csv`, `fem_ledger.csv`, `training_history.csv`, `sampling_comparison.png`, `source_checksums.csv`, `SHA256SUMS.csv`, `SHA256SUMS_v2.csv` und versiegelte MAT-Artefakte liegen im Studienordner. Der Originalcode und die Umgebung sind im Manifest erfasst.",
        "", "Im Projektordner in MATLAB R2025b:", "", "```matlab", "openProject('blank_project.prj')", "run_restfield_sampling48('prepare')", "run_restfield_sampling48('pilot')", "run_restfield_sampling48('data')", "run_restfield_sampling48('campaign')", "run_restfield_sampling48('evaluate')", "```", "", "Anschliessend im Projektordner: `python scripts/python/report_restfield_sampling48_v2.py`. Wiederaufnahmen pruefen bestehende Artefakte und erzeugen fuer fehlgeschlagene oder unterbrochene Versuche neue nummerierte Versuche; Konflikte fuehren zum Abbruch.", "",
    ]
    put_text(OUT / "FINAL_REPORT_v2.md", "\n".join(lines))
    files = [CFG, ROOT / "scripts/matlab/run_restfield_sampling48.m", ROOT / "scripts/python/report_restfield_sampling48.py", Path(__file__).resolve()]
    files += sorted(p for p in OUT.rglob("*") if p.is_file() and p.name != "SHA256SUMS_v2.csv")
    import io
    buffer = io.StringIO(newline="")
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerow(["path", "sha256"])
    for path in files:
        writer.writerow([str(path.relative_to(ROOT)).replace("\\", "/"), hashlib.sha256(path.read_bytes()).hexdigest()])
    put_text(OUT / "SHA256SUMS_v2.csv", buffer.getvalue())
    print(f"Report verified: {len(summary)} runs, {len(cases)} case rows; output {OUT}")


if __name__ == "__main__":
    main()
