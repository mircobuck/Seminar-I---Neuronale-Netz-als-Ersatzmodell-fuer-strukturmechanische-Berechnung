import csv, hashlib, json, math, statistics
from pathlib import Path
H=Path(__file__).resolve().parent
def read(name):
    with (H/name).open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))
meta=json.loads((H/'metadata.json').read_text(encoding='utf-8'))
assert abs(statistics.median([meta['main']['pod_gpr']['fitSeconds']]+meta['gprRepeats'])-337.1902846)<1e-8
rows=read('extrapolation_all_seed42.csv'); assert len(rows)==512 and len({x['case_id'] for x in rows})==128
for x in rows:
    assert math.isclose(float(x['absolute_field_m'])/float(x['reference_norm_m']),float(x['relative']),rel_tol=1e-12)
    assert .05<=float(x['distance_fraction'])<=.10
    assert math.isclose(float(x['fem_tip_m'])+float(x['tip_error_m']),float(x['predicted_tip_m']),abs_tol=1e-16)
groups=read('extrapolation_group_summary.csv'); assert len(groups)==48
for x in groups:
    matching=[r for r in rows if r['method']==x['method'] and r['group']==x['group']]
    assert len(matching)==int(x['cases']) in (10,11)
    assert math.isclose(statistics.fmean(float(r['relative']) for r in matching),float(x['mean_relative']),rel_tol=1e-14)
rank=read('controlled_rank_n768.csv'); assert len(rank)==12 and all(int(x['runs'])==1 for x in rank)
assert len(read('benchmark_fem_raw.csv'))==24 and len(read('benchmark_surrogate_raw.csv'))==1560
assert len(read('benchmark_cases.csv'))==12 and (H/'benchmark_complete.txt').is_file()
for x in read('break_even_scenarios.csv'):
    assert float(x['single_denominator_s'])>0 and float(x['batch12_denominator_s'])>0
    assert int(x['existing_fit_cases'])==math.ceil(float(x['fit_s'])/float(x['single_denominator_s']))
    assert int(x['batch_existing_fit_search_cases'])==12*math.ceil((float(x['fit_s'])+float(x['search_s']))/float(x['batch12_denominator_s']))
assert '337.1902846' in (H/'SEMINARBERICHT_v1.md').read_text(encoding='utf-8')
print('PASS: timing median, 512 cases, ratios, predictions, group sizes/means, 12 rank rows, 24 FEM and 1560 surrogate timings, break-even formulas')
files=sorted(p for p in H.iterdir() if p.is_file() and p.name not in {'manifest_sha256.csv','fem_partial.mat','surrogate_partial.mat'})
with (H/'manifest_sha256.csv').open('w',encoding='utf-8',newline='') as out:
    w=csv.writer(out);w.writerow(['file','sha256','bytes'])
    for p in files:w.writerow([p.name,hashlib.sha256(p.read_bytes()).hexdigest(),p.stat().st_size])
