"""Count nonblank, noncomment physical MATLAB/Python lines by responsibility."""
from pathlib import Path
import ast
import csv
import io
import tokenize

ROOT = Path(__file__).resolve().parents[1]


def lines_of_code(path):
    text = path.read_text(encoding="utf-8-sig")
    if path.suffix == ".py":
        documentation = set()
        tree = ast.parse(text)
        for node in ast.walk(tree):
            if isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                if node.body and isinstance(node.body[0], ast.Expr):
                    value = node.body[0].value
                    if isinstance(value, ast.Constant) and isinstance(value.value, str):
                        documentation.update(range(value.lineno, value.end_lineno + 1))
        code = set()
        excluded = {tokenize.COMMENT, tokenize.NL, tokenize.NEWLINE, tokenize.INDENT,
                    tokenize.DEDENT, tokenize.ENDMARKER, tokenize.ENCODING}
        for token in tokenize.generate_tokens(io.StringIO(text).readline):
            if token.type not in excluded:
                code.update(range(token.start[0], token.end[0] + 1))
        return len(code - documentation)
    count = 0
    block = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "%{":
            block = True
        elif stripped == "%}":
            block = False
        elif stripped and not block and not stripped.startswith("%"):
            count += 1
    return count


def category(path):
    relative = path.relative_to(ROOT).as_posix()
    name = path.stem
    if relative.startswith("fem_core/") or name in ("createDesign", "generate", "recordGeneration"):
        return "1 FEM und Datenerzeugung"
    if relative.startswith("tests/"):
        return "7 Automatisierte Tests"
    if relative.startswith("examples/"):
        return "6 Aktuelle Beispiele"
    if name in ("fit", "fitModel", "fitNeural", "fitPod", "rbfFeatures"):
        return "2 Modellaufbau und Training"
    if name in ("candidates", "tuning", "training", "trainingBlocks", "distribution",
                "subset", "recordSearch", "nestedTrainingSubsets", "assertDisjointParameters"):
        return "3 Trainingsauswahl und Suchsteuerung"
    if name in ("predict", "predictModel", "predictNeural", "evaluatePrediction", "podDiagnostics",
                "summarizeErrors", "evaluation", "observeModel", "timePrediction", "benchmark",
                "report", "comparePrevious", "studyPlots"):
        return "4 Vorhersage, Auswertung und Benchmark"
    return "5 Datenvertraege, Einstieg und Laufverwaltung"


rows = []
for path in sorted(ROOT.rglob("*")):
    if path.suffix not in (".m", ".py"):
        continue
    relative = path.relative_to(ROOT)
    if any(part in (".agents", ".codex", "__pycache__") for part in relative.parts):
        continue
    assert relative.parts[0] not in ("experiments", "studies", "scripts", "Netzarchitekturen", "Testverfahren"), path
    rows.append((category(path), relative.as_posix(), lines_of_code(path)))
with (ROOT / "docs/CODEZAEHLUNG.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream)
    writer.writerow(("Kategorie", "Datei", "Codezeilen"))
    writer.writerows(rows)
totals = {}
for group, _, count in rows:
    totals[group] = totals.get(group, 0) + count
functional = sum(count for group, count in totals.items() if not group.startswith("7 "))
report = ["# Codezaehlung", "", "Nichtleere physische Codezeilen ohne reine Kommentarzeilen; MATLAB-Blockkommentare und Python-Docstrings ausgeschlossen.",
          "MATLAB und Python einschliesslich dieses reproduzierbaren Zaehlwerkzeugs. Keine Agenten-/Skilldateien oder Konfigurationen.",
          "Historische Programme und Quellkopien sind tatsaechlich entfernt; ihr Vorkommen wuerde die Zaehlausfuehrung abbrechen.", "",
          "| Kategorie | Dateien | Codezeilen |", "|---|---:|---:|"]
report.extend(f"| {group} | {sum(row[0] == group for row in rows)} | {count} |" for group, count in sorted(totals.items()))
report += ["", f"Funktion und Verwaltung: **{functional}** Codezeilen; Tests separat: **{totals['7 Automatisierte Tests']}**.",
           "Ausgangsbestand: 17.544 Codezeilen in 380 Programmdateien, davon 1.092 Testzeilen und 8.099 Zeilen historischer Quellkopien.",
           "Der Richtwert 2.356 bezeichnete eine Auswahl aktueller Funktionen, nicht den gesamten alten Bestand. Entfernte modale/alte Optimiererzweige und die schlankere FEM-Konfiguration reduzieren diesen Kern; das Zaehlwerkzeug wird nun ausdruecklich mitgezaehlt. Kategorien folgen der Hauptverantwortung einer Datei.",
           "Nicht-Code-Artefakte stehen separat in CLEANUP_NONCODE_INVENTORY.csv; die 7.312 vorhandenen wissenschaftlichen Dateien sind mit Hashes in CLEANUP_PRESERVED_BASELINE.csv gesichert.",
           "Dateiweise Zuordnung: CODEZAEHLUNG.csv. Reproduzierbar mit `python docs/count_code.py`."]
(ROOT / "docs/CODEZAEHLUNG.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print(totals)
