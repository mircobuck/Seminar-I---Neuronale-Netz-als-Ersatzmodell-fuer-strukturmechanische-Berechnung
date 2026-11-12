"""Post-hoc descriptive analysis; never changes the frozen study."""
import csv, hashlib, json, math, statistics
from collections import defaultdict
from pathlib import Path

HERE=Path(__file__).resolve().parent
MAIN=HERE.parent/'static_gpr_main_v1_20261111_run2'
def read(p):
    with p.open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))
def write(p,rows):
    with p.open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def number(x):
    try: return float(x)
    except (ValueError,TypeError): return math.nan
def mean(xs): return statistics.fmean(xs)
def mid(xs): return statistics.median(xs)
def corr(x,y):
    a=mean(x); b=mean(y); s=sum((z-a)**2 for z in x)*sum((z-b)**2 for z in y)
    return sum((z-a)*(w-b) for z,w in zip(x,y))/math.sqrt(s) if s else math.nan

inputs=['run_results.csv','case_results.csv','candidate_design.csv',
        'supplementary_analysis/controlled_pod_diagnostics.csv','gpr_fit_timing_repeats.csv',
        'freeze_manifest.csv','selections.mat']
runs=read(MAIN/inputs[0]); cases=read(MAIN/inputs[1]); design={r['id']:r for r in read(MAIN/inputs[2])}
refs={r['id']:r for r in read(HERE/'extrapolation_references.csv')}
diag={r['RunId'].replace('/','\\')+'|'+r['Role']:r for r in read(MAIN/inputs[3])}
names=['L_m','b_m','h_m','E_Pa','nu','Fz_N']; lo=[.6,.06,.08,70e9,.25,-1000]; hi=[1.2,.1,.14,210e9,.35,-100]

controlled=[]
for r in runs:
    rid=r['id'].replace('/','\\')
    if not rid.startswith('controlled\\n768_rep1_'): continue
    d=diag[rid+'|'+r['role']]
    rank=int(rid.split('_rank')[1].split('_')[0])
    controlled.append(dict(method=r['method'],rank=rank,split=r['role'],runs=1,
        projection_percent=100*number(d['MeanRelativeProjection']),field_percent=100*number(r['avg']),
        fit_standalone_s=number(r['standaloneFitSeconds']),shared_pod_s=number(r['sharedPod']),
        prediction_single_ms=1000*number(r['single']),prediction_iqr_ms=1000*number(r['singleIqr']),
        prediction_batch128_ms=1000*number(r['batch']),model_bytes=int(number(r['modelBytes']))))
controlled.sort(key=lambda r:(r['split'],r['method'],r['rank']))
assert len(controlled)==12
write(HERE/'controlled_rank_n768.csv',controlled)

# Seed 42 is one prespecified model per family, so paired case-level comparisons are valid.
selected=[]; global_cases=[]
for c in cases:
    rid=c['RunId'].replace('/','\\'); m=c['Method']
    if c['Role']!='extrapolation' or not rid.startswith(f'runs\\n768_rep1_{m}_seed'): continue
    d=design[c['CaseId']]; g=int(d['group']); q=(g-1)//2; side='lower' if g%2 else 'upper'
    value=number(d[names[q]]); delta=(lo[q]-value if side=='lower' else value-hi[q])/(hi[q]-lo[q])
    assert .05-1e-10<=delta<=.1+1e-10
    row=dict(case_id=c['CaseId'],method=m,run_id=rid,group=g,parameter=names[q],side=side,
        distance_fraction=delta,reference_norm_m=number(c['ReferenceNorm']),absolute_field_m=number(c['Absolute']),
        relative=number(c['Relative']),tip_error_m=number(c['TipError']),maximum_error_m=number(c['MaxMagnitudeError']),
        fem_tip_m=number(refs[c['CaseId']]['femTip_m']),fem_maximum_m=number(refs[c['CaseId']]['femMaximum_m']))
    assert abs(row['fem_tip_m']-number(c['FemTip']))<1e-14
    row['predicted_tip_m']=row['fem_tip_m']+row['tip_error_m']
    row['predicted_maximum_m']=row['fem_maximum_m']+row['maximum_error_m']
    row.update({name:number(d[name]) for name in names}); global_cases.append(row)
    if rid==f'runs\\n768_rep1_{m}_seed42': selected.append(row)
assert len(selected)==512 and len({r['case_id'] for r in selected})==128
write(HERE/'extrapolation_all_seed42.csv',selected)
peak={m:max((r for r in global_cases if r['method']==m),key=lambda r:r['relative'])['case_id']
      for m in ['mlp','rbf','pod_mlp','pod_gpr']}
ids=set(peak.values()); paired=[r for r in selected if r['case_id'] in ids]
paired.sort(key=lambda r:(int(r['case_id']),r['method'])); write(HERE/'extrapolation_outliers_paired.csv',paired)
global_peak=[max((r for r in global_cases if r['method']==m),key=lambda r:r['relative'])
             for m in ['mlp','rbf','pod_mlp','pod_gpr']]
write(HERE/'extrapolation_global_peaks.csv',global_peak)
groups=[]
for m in ['mlp','rbf','pod_mlp','pod_gpr']:
    for g in range(1,13):
        a=[r for r in selected if r['method']==m and r['group']==g]; assert a
        groups.append(dict(method=m,group=g,parameter=a[0]['parameter'],side=a[0]['side'],cases=len(a),
            mean_relative=mean([r['relative'] for r in a]),median_relative=mid([r['relative'] for r in a]),
            max_relative=max(r['relative'] for r in a),mean_absolute_field_m=mean([r['absolute_field_m'] for r in a]),
            median_reference_norm_m=mid([r['reference_norm_m'] for r in a])))
write(HERE/'extrapolation_group_summary.csv',groups)
stats=[]
for m in ['mlp','rbf','pod_mlp','pod_gpr']:
    a=[r for r in selected if r['method']==m]; sortedrel=sorted(a,key=lambda r:r['relative'],reverse=True); top=sortedrel[:13]
    stats.append(dict(method=m,n=len(a),pearson_relative_reference=corr([r['relative'] for r in a],[r['reference_norm_m'] for r in a]),
        median_norm_all=mid([r['reference_norm_m'] for r in a]),median_norm_top13=mid([r['reference_norm_m'] for r in top]),
        median_absolute_all=mid([r['absolute_field_m'] for r in a]),median_absolute_top13=mid([r['absolute_field_m'] for r in top]),
        top_groups=';'.join(f'{g}:{sum(r["group"]==g for r in top)}' for g in range(1,13) if any(r['group']==g for r in top))))
write(HERE/'extrapolation_diagnostic_summary.csv',stats)
provenance={'inputs_sha256':{p:sha(MAIN/p) for p in inputs},'reference_export_sha256':sha(HERE/'extrapolation_references.csv'), 'analysis_script_sha256':sha(Path(__file__)),
            'outlier_rule':'union of per-method maximum relative-error test cases across full-pool runs; paired comparison uses fixed seed 42',
            'caveat':'Post-hoc descriptive diagnosis; not model selection; no causal conclusion.'}
(HERE/'analysis_provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
print('written: controlled ranks, 512 paired extrapolation rows, groups, diagnosis and provenance')
