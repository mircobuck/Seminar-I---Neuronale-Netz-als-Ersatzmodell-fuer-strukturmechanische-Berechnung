"""Audit the completed known-reference repetition without fitting or selecting models."""
from pathlib import Path
import csv
import hashlib
import json
import math
import sys

HERE = Path(__file__).resolve().parent
OLD = HERE.parent / 'static_gpr_main_v1_20261111_run2'
ATOL = RTOL = 1e-12


def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def compare_table(filename, keys, fields):
    before, after = rows(OLD / filename), rows(HERE / filename)
    def key(row):
        return tuple(row[name].replace('\\', '/') for name in keys)
    indexed = {key(row): row for row in before}
    assert len(indexed) == len(before), f'Duplicate old keys: {filename}'
    assert len({key(row) for row in after}) == len(after), f'Duplicate new keys: {filename}'
    assert set(indexed) == {key(row) for row in after}, f'Changed identities: {filename}'
    result = []
    for field in fields:
        exact = different = outside = undefined = 0
        maximum = 0.0
        worst = None
        for row in after:
            a, b = float(row[field]), float(indexed[key(row)][field])
            if math.isnan(a) and math.isnan(b):
                undefined += 1
                continue
            if a == b:
                exact += 1
                continue
            different += 1
            delta = abs(a - b)
            if not (math.isfinite(a) and math.isfinite(b)) or delta > ATOL + RTOL * abs(b):
                outside += 1
            if delta > maximum:
                maximum, worst = delta, key(row)
        result.append(dict(Table=filename, Field=field, Rows=len(after), Exact=exact,
                           BothUndefined=undefined, Different=different, OutsideTolerance=outside,
                           MaxAbsoluteDifference=maximum, WorstKey=repr(worst)))
    return result


def main():
    assert (HERE / 'study.complete').is_file(), 'Study not complete'
    assert not (HERE / 'failure.txt').exists(), 'Batch reported a failure'
    assert 'Gleiche gewaehlte Konfigurationen: true' in (HERE / 'VERGLEICH.md').read_text(encoding='utf-8-sig'), 'Changed selection'
    assert all(row['Status'] == 'ok' for row in rows(HERE / 'gpr_fit_timing_repeats.csv'))
    checks = {}
    for name in ['source_manifest.csv', 'freeze_manifest.csv']:
        manifest = rows(HERE / name)
        mismatches = [row['Path'] for row in manifest
                      if digest(Path(row['Path'])) != row['SHA256'].lower()]
        assert not mismatches, f'{name}: {mismatches}'
        checks[name] = len(manifest)
    freeze = HERE / 'freeze_manifest.csv'
    assert digest(freeze) == (HERE / 'freeze_manifest.sha256').read_text().strip()
    for seal in HERE.rglob('*.sha256'):
        if seal.name == 'result.sha256':
            target = seal.with_name('result.mat')
        elif seal.name == 'pod.sha256':
            target = seal.with_name('pod.mat')
        elif seal.name == 'selections.sha256':
            target = seal.with_name('selections.mat')
        elif seal.name == 'candidate_design.sha256':
            target = seal.with_name('candidate_design.mat')
        elif seal.name == 'freeze_manifest.sha256':
            continue
        else:
            target = Path(str(seal)[:-7])
        assert target.is_file(), f'No sealed target: {seal}'
        assert digest(target) == seal.read_text().strip().lower(), f'Hash mismatch: {target}'
    runs = rows(HERE / 'run_results.csv')
    cases = rows(HERE / 'case_results.csv')
    search = rows(HERE / 'search_attempts.csv')
    assert len(runs) == 288 and len(cases) == 144 * (256 + 128)
    assert all(row['status'] == 'ok' and int(row['undefined']) == 0 for row in runs)
    assert all(row['Status'] == 'ok' for row in search + cases)
    fits = [p for p in HERE.rglob('result.mat') if (p.parent / 'result.sha256').exists()]
    assert len(fits) == 234, f'Expected 234 fits, got {len(fits)}'
    assert len(search) == 88, f'Expected 88 search fits, got {len(search)}'
    cost = rows(HERE / 'search_costs.csv')
    assert int(float(cost[-1]['Candidates'])) == 76
    differences = compare_table('run_results.csv', ['id', 'role'],
        ['avg', 'med', 'p95', 'worst', 'absolute', 'undefined'])
    differences += compare_table('case_results.csv', ['RunId', 'Role', 'CaseId'],
        ['Relative', 'Absolute', 'ReferenceNorm', 'TipError', 'MaxMagnitudeError',
         'FemTip', 'EulerBernoulliTip', 'TimoshenkoTip', 'ProjectionSquared',
         'RegressionSquared', 'ReconstructionSquared', 'DecompositionResidual',
         'DecompositionValid', 'AbsoluteTipError', 'AbsoluteMaxMagnitudeError'])
    with (HERE / 'numerical_comparison.csv').open('w', encoding='utf-8', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(differences[0]))
        writer.writeheader()
        writer.writerows(differences)
    summary = dict(manifestFiles=checks, sealedFits=len(fits), searchFits=len(search),
                   evaluations=len(runs), caseRows=len(cases), absoluteTolerance=ATOL,
                   relativeTolerance=RTOL,
                   outsideTolerance=sum(row['OutsideTolerance'] for row in differences),
                   note='Known references; timing columns deliberately excluded from equality checks.')
    (HERE / 'verification.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, indent=2))
    assert summary['outsideTolerance'] == 0, 'Investigate numerical differences; do not change selections'


if __name__ == '__main__':
    main()
