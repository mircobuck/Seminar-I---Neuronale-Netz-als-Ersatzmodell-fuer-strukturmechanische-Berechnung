"""Check report-defining values against the copied study tables."""
import csv, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(name):
    with (ROOT/'daten'/name).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
S=read('pipeline_summary_corrected.csv'); R=read('run_results.csv'); P=read('controlled_rank_n768.csv')
B=read('benchmark_summary.csv'); Q=read('break_even_scenarios.csv'); O=read('extrapolation_outliers_paired.csv')
expected={'mlp':(4.64,16.24),'rbf':(7.41,32.67),'pod_mlp':(4.78,13.74),'pod_gpr':(.55,3.85)}
for m,(a,b) in expected.items():
    for role,target in [('interpolation',a),('extrapolation',b)]:
        x=next(r for r in S if r['method']==m and r['role']==role and r['n']=='768')
        assert abs(100*float(x['meanError'])-target)<.0051
g=next(r for r in R if r['id'].replace('/','\\')=='runs\\n768_rep1_pod_gpr_seed42' and r['role']=='interpolation')
assert abs(float(g['fitSeconds'])-353.5687942)<1e-8
for k,err,t in [(2,.560,70.53),(15,.549,348.22)]:
    x=next(r for r in P if r['method']=='pod_gpr' and r['split']=='interpolation' and int(r['rank'])==k)
    assert abs(float(x['field_percent'])-err)<.0006 and abs(float(x['fit_standalone_s'])-t)<.006
assert abs(float(B[0]['femSingleMedian'])-2.189)<.0006
g=next(r for r in Q if r['method']=='pod_gpr'); assert (int(g['existing_fit_cases']),int(g['existing_fit_search_cases']))==(163,714)
assert len(O)==4 and {r['case_id'] for r in O}=={'830644'}
for m in ['mlp','rbf','pod_mlp']:
    assert float(next(r for r in O if r['method']==m)['predicted_tip_m'])>0
assert float(next(r for r in O if r['method']=='pod_gpr')['predicted_tip_m'])<0
assert len(list((ROOT/'abbildungen').glob('*.pdf')))==7
print('PASS: Vollpoolfehler, GPR-Hauptfit, Rangwerte, Benchmark, Break-even, Ausreißervorzeichen, sieben Vektorabbildungen')
