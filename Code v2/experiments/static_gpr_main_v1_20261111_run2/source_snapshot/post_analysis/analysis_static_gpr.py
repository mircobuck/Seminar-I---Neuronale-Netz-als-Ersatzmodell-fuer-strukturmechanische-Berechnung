"""Summarize a frozen static study without altering its original results."""
import csv
import hashlib
import json
import math
import re
import statistics
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path


def digest(path):
    hasher = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            hasher.update(block)
    return hasher.hexdigest()


def read_csv(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def number(value):
    try:
        result = float(value)
        return result if math.isfinite(result) else math.nan
    except (TypeError, ValueError):
        return math.nan


def average(values):
    finite = [x for x in values if math.isfinite(x)]
    return statistics.fmean(finite) if finite else math.nan


def fmt(value, scale=1, digits=2):
    return f'{value * scale:.{digits}f}' if math.isfinite(value) else 'nicht definiert'


def main(root):
    root = Path(root).resolve()
    manifest = root / 'freeze_manifest.csv'
    seal = root / 'freeze_manifest.sha256'
    if not manifest.is_file() or digest(manifest) != seal.read_text().strip():
        raise RuntimeError('Das Freeze-Manifest fehlt oder ist verändert.')
    for row in read_csv(manifest):
        path = Path(row['Path'])
        if not path.is_file() or digest(path) != row['SHA256']:
            raise RuntimeError(f'Eingefrorenes Artefakt verändert: {path}')
    frozen_paths = {str(Path(row['Path']).resolve()) for row in read_csv(manifest)}
    if str(Path(__file__).resolve()) not in frozen_paths:
        raise RuntimeError('Dieses Auswertungsskript ist nicht im Freeze enthalten.')

    inputs = ['pipeline_summary.csv', 'run_results.csv', 'case_results.csv',
              'search_costs.csv', 'reference_costs.csv', 'gpr_fit_timing_repeats.csv']
    input_hashes = {name: digest(root / name) for name in inputs}
    summaries = read_csv(root / 'pipeline_summary.csv')
    runs = read_csv(root / 'run_results.csv')
    cases = read_csv(root / 'case_results.csv')
    searches = read_csv(root / 'search_costs.csv')
    references = read_csv(root / 'reference_costs.csv')
    repeats = read_csv(root / 'gpr_fit_timing_repeats.csv')
    output = root / 'supplementary_analysis'
    output.mkdir(exist_ok=True)

    corrected = output / 'pipeline_summary_corrected.csv'
    with corrected.open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=summaries[0].keys())
        writer.writeheader()
        for row in summaries:
            row = dict(row)
            if number(row['count']) < 2:
                row['runStd'] = 'NaN'
            writer.writerow(row)

    grouped = defaultdict(list)
    for row in cases:
        if row['RunId'].replace('/', '\\').startswith('controlled\\'):
            grouped[(row['RunId'], row['Method'], row['Role'])].append(row)
    diagnostics = []
    for (run_id, method, role), observations in sorted(grouped.items()):
        projection, regression, reconstruction = [], [], []
        invalid = 0
        for row in observations:
            norm = number(row['ReferenceNorm'])
            if norm <= 0 or not math.isfinite(norm):
                invalid += 1
                continue
            p = number(row['ProjectionSquared'])
            r = number(row['RegressionSquared'])
            e = number(row['ReconstructionSquared'])
            if min(p, r, e) < 0 or not all(map(math.isfinite, (p, r, e))):
                invalid += 1
                continue
            projection.append(math.sqrt(p) / norm)
            regression.append(math.sqrt(r) / norm)
            reconstruction.append(math.sqrt(e) / norm)
        diagnostics.append(dict(RunId=run_id, Method=method, Role=role,
                                Cases=len(observations), Undefined=invalid,
                                MeanRelativeProjection=average(projection),
                                MeanRelativeRegression=average(regression),
                                MeanRelativeReconstruction=average(reconstruction),
                                InvalidDecomposition=sum(row['DecompositionValid'] not in ('1', 'true', 'True')
                                                         for row in observations)))
    diagnostic_file = output / 'controlled_pod_diagnostics.csv'
    fields = ['RunId', 'Method', 'Role', 'Cases', 'Undefined', 'MeanRelativeProjection',
              'MeanRelativeRegression', 'MeanRelativeReconstruction', 'InvalidDecomposition']
    with diagnostic_file.open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(diagnostics)

    methods = ('mlp', 'rbf', 'pod_mlp', 'pod_gpr')
    lookup = {(r['role'], r['method'], int(number(r['n']))): r for r in summaries}
    full = [r for r in runs if r['id'].replace('/', '\\').startswith('runs\\')
            and int(number(r['N'])) == 768 and r['role'] == 'interpolation'
            and r['status'] == 'ok']
    failures = [r for r in runs if r['status'] != 'ok']
    undefined = sum(int(number(r['undefined'])) for r in runs if math.isfinite(number(r['undefined'])))
    total_control_invalid = sum(r['InvalidDecomposition'] for r in diagnostics)
    lines = ['# Statischer Vier-Methoden-Vergleich', '',
             'Diese ergänzende Auswertung verwendet ausschließlich die nach dem geprüften Freeze '
             'erzeugten Ergebnistabellen. Interpolation und Extrapolation bleiben getrennt.', '',
             '## Vollpool: Fehler und Aufwand', '',
             '| Methode | Läufe | Interpolation Mittel / P95 / Maximum | Extrapolation Mittel / P95 / Maximum | Fit Median | Einzelfall Median | Batch 128 Median |',
             '|---|---:|---:|---:|---:|---:|---:|']
    for method in methods:
        inter = lookup.get(('interpolation', method, 768))
        extra = lookup.get(('extrapolation', method, 768))
        subset = [r for r in full if r['method'] == method]
        def errors(item):
            if not item:
                return 'fehlt'
            return ' / '.join(fmt(number(item[k]), 100) + ' %' for k in ('meanError', 'p95Error', 'maxObserved'))
        fit = statistics.median([number(r['fitSeconds']) for r in subset]) if subset else math.nan
        one = statistics.median([number(r['single']) for r in subset]) if subset else math.nan
        batch = statistics.median([number(r['batch']) for r in subset]) if subset else math.nan
        lines.append(f'| {method} | {len(subset)} | {errors(inter)} | {errors(extra)} | '
                     f'{fmt(fit)} s | {fmt(one, 1000)} ms | {fmt(batch, 1000)} ms |')
    lines += ['', 'Mittelwert und P95 werden je Lauf über Balkenfälle berechnet und anschließend '
              'über Läufe gemittelt. Maximum ist das größte tatsächlich beobachtete Fallmaximum. '
              'Bei 768 Fällen unterscheiden sich die neuronalen Läufe in der Initialisierung; '
              'POD–GPR hat eine Datenwahl und keine geschätzte Modellstreuung.', '',
              '## Datenmenge', '',
              '| Methode | N=48 | N=96 | N=192 | N=384 | N=768 |',
              '|---|---:|---:|---:|---:|---:|']
    for method in methods:
        values = []
        for n in (48, 96, 192, 384, 768):
            row = lookup.get(('interpolation', method, n))
            values.append(fmt(number(row['meanError']), 100) + ' %' if row else 'fehlt')
        lines.append('| ' + method + ' | ' + ' | '.join(values) + ' |')
    lines += ['', 'Die Tabelle zeigt den mittleren relativen Interpolationsfeldfehler; '
              'vollständige Streuungs- und Zeitangaben stehen in der korrigierten CSV.', '',
              '## Zusätzliche Auslenkungsfehler im Vollpool', '',
              '| Methode | Split | Mittlerer Betrag Spitzenfehler | Mittlerer Betrag Maximumfehler |',
              '|---|---|---:|---:|']
    for method in methods:
        for role in ('interpolation', 'extrapolation'):
            selected = [r for r in cases if r['Method'] == method and r['Role'] == role
                        and r['RunId'].replace('/', '\\').startswith('runs\\n768_')
                        and r['Status'] == 'ok']
            tip = average([number(r['AbsoluteTipError']) for r in selected])
            maximum = average([number(r['AbsoluteMaxMagnitudeError']) for r in selected])
            lines.append(f'| {method} | {role} | {fmt(tip, 1000, 4)} mm | '
                         f'{fmt(maximum, 1000, 4)} mm |')
    lines += ['', 'Die Spitze bezeichnet vorzeichenbehaftetes uz bei (1, 0.5, 0.5); '
              'das Maximum ist der Betrag über alle 525 Gitterpunkte.', '',
              '## Einfluss der Trainingsverteilung bei N=192', '',
              '| Methode | Verteilung | Split | Mittlerer relativer Feldfehler |',
              '|---|---|---|---:|']
    for row in runs:
        normalized = row['id'].replace('/', '\\')
        if normalized.startswith('distribution\\') and row['status'] == 'ok':
            kind = 'ungleichmäßig' if 'skew_' in normalized else 'raumfüllend'
            lines.append(f"| {row['method']} | {kind} | {row['role']} | "
                         f"{fmt(number(row['avg']), 100)} % |")
    lines += ['', 'Beide Auswahlen haben gleiche Fallzahl, gleiche äußere Grenzen und '
              'dieselben Auswertungsfälle. Es ist eine separate Einflussuntersuchung.', '',
              '## Kontrollierter POD-Vergleich', '',
              '| Methode | Rang | Split | Projektion | Koeffizientenregression | Rekonstruktion |',
              '|---|---:|---|---:|---:|---:|']
    for row in diagnostics:
        match = re.search(r'n768_rep1_rank(2|10|15)_(pod_mlp|pod_gpr)', row['RunId'])
        if match:
            lines.append(f"| {row['Method']} | {match.group(1)} | {row['Role']} | "
                         f"{fmt(row['MeanRelativeProjection'], 100)} % | "
                         f"{fmt(row['MeanRelativeRegression'], 100)} % | "
                         f"{fmt(row['MeanRelativeReconstruction'], 100)} % |")
    lines += ['', 'Die gewichtete quadratische Fehlerzerlegung gilt fallweise; die obigen '
              'Mittelwerte der Wurzeln sind nicht additiv. Ungültige Zerlegungsmarkierungen: '
              f'{total_control_invalid}. Details stehen in controlled_pod_diagnostics.csv.', '',
              '## Such- und Referenzkosten', '',
              '| Position | Zeit |', '|---|---:|']
    for row in searches:
        lines.append(f"| Suche {row['Method']} | {fmt(number(row['SearchSeconds']))} s |")
    for row in references:
        lines.append(f"| FEM {row['referenceRole']}: Solver / aktive Erzeugungszeit | "
                     f"{fmt(number(row['solverSeconds']))} / {fmt(number(row['activeWallSeconds']))} s |")
    times = [number(r['FitSeconds']) for r in repeats if r['Status'] == 'ok']
    base = [number(r['fitSeconds']) for r in full if r['method'] == 'pod_gpr']
    combined = [x for x in base + times if math.isfinite(x)]
    if combined:
        lines += ['', 'Deterministische Vollpool-GPR-Fit-Zeitmessungen: '
                  + ', '.join(fmt(x) + ' s' for x in combined)
                  + '. Diese Wiederholungen sind keine unabhängigen Datensätze.']
    lines += ['', '## Einordnung und Grenzen', '',
              f'- Fehlgeschlagene Lauf-/Split-Auswertungen: {len(failures)}; '
              f'undefinierte relative Fallfehler: {undefined}.',
              '- Die RBF-Variante verwendet feste Gauß-Zentren und Breiten; Ergebnisse '
              'gelten für diese Implementierung und diesen begrenzten Suchraum.',
              '- Die Testfälle werden über dieselben Modelle wiederholt vorhergesagt; '
              'Netz-Seeds sind keine zusätzlichen unabhängigen Balkenfälle.',
              '- Netzdiagnosen und eindimensionale Balkentheorien sind Plausibilitätsprüfungen, '
              'keine exakte Referenz aller 3D-Feldkomponenten.',
              '- Ein belastbarer Break-even und Spitzen-RAM wurden nicht gemessen; '
              'keine GPR-Unsicherheiten wurden als kalibrierte Fehlergrenzen ausgegeben.',
              '- Die ursprünglichen Tabellen bleiben erhalten; bei nur einem Lauf ist '
              'die Streuung in pipeline_summary_corrected.csv als undefiniert markiert.']
    valid = [(m, number(lookup[('interpolation', m, 768)]['meanError']))
             for m in methods if ('interpolation', m, 768) in lookup
             and number(lookup[('interpolation', m, 768)]['failed']) == 0
             and number(lookup[('interpolation', m, 768)]['count']) >= (1 if m == 'pod_gpr' else 3)
             and math.isfinite(number(lookup[('interpolation', m, 768)]['meanError']))]
    if valid:
        best = min(valid, key=lambda item: item[1])[0]
        lines += ['', f'Für einen genauigkeitsorientierten Ausgangspunkt auf der untersuchten '
                  f'Interpolationsverteilung ist {best} anhand des Vollpool-Mittelwerts '
                  'zuerst zu prüfen. Die Extrapolationsfehler, Streuung und Kosten in der '
                  'Tabelle bestimmen, ob diese Wahl für den konkreten Einsatz tragfähig ist.']
    report = output / 'ANALYSE.md'
    report.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    provenance = dict(created_utc=datetime.now(timezone.utc).isoformat(),
                      freeze_sha256=digest(manifest), script_sha256=digest(Path(__file__)),
                      input_sha256=input_hashes,
                      output_sha256={p.name: digest(p) for p in (corrected, diagnostic_file, report)})
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2), encoding='utf-8')
    print(f'Bericht geschrieben: {report}; fehlgeschlagene Auswertungen: {len(failures)}')


if __name__ == '__main__':
    main(sys.argv[1])
