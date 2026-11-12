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
    if relative.startswith(("+surrogate/", "fem_core/")) or relative == "loadFemDataset.m":
        return "Fachlicher Kern"
    if relative.startswith("tests/"):
        return "Tests"
    if relative.startswith("workflows/") or relative in ("setupProject.m", "runStaticStudy.m", "docs/count_code.py"):
        return "Studiensteuerung und Verwaltung"
    if relative in ("examples/trainStaticModelExample.m", "examples/showStaticResultsExample.m"):
        return "Studiensteuerung und Verwaltung"
    return "Historische Programme"


rows = []
for path in sorted(ROOT.rglob("*")):
    if path.suffix not in (".m", ".py"):
        continue
    relative = path.relative_to(ROOT)
    if any(part in ("experiments", ".agents", ".codex", "__pycache__") for part in relative.parts):
        continue
    rows.append((category(path), relative.as_posix(), lines_of_code(path)))
with (ROOT / "docs/CODEZAEHLUNG.csv").open("w", newline="", encoding="utf-8") as stream:
    writer = csv.writer(stream)
    writer.writerow(("Kategorie", "Datei", "Codezeilen"))
    writer.writerows(rows)
totals = {}
for group, _, count in rows:
    totals[group] = totals.get(group, 0) + count
report = ["# Codezaehlung", "", "Nichtleere physische Codezeilen ohne reine Kommentarzeilen; MATLAB-Blockkommentare und Python-Docstrings ausgeschlossen.",
          "Keine erzeugten Artefakte, eingefrorenen Quellkopien, Agenten- oder Skilldateien. MATLAB und Python; keine JSON-/CSV-Konfigurationen.",
          "Historische Skripte innerhalb von experiments sind Artefaktbestandteile und nicht Teil dieser Quellcodezaehlung.", "",
          "| Kategorie | Codezeilen |", "|---|---:|"]
report.extend(f"| {group} | {count} |" for group, count in totals.items())
report += ["", "Dateiweise Zuordnung: CODEZAEHLUNG.csv. Reproduzierbar mit `python docs/count_code.py`."]
(ROOT / "docs/CODEZAEHLUNG.md").write_text("\n".join(report) + "\n", encoding="utf-8")
print(totals)
