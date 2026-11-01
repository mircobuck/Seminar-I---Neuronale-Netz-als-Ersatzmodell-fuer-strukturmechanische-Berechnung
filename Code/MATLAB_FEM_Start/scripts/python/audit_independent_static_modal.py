"""Independently audit exported holdout case keys, metrics and ordering."""
import collections
import csv
import math
from pathlib import Path

root=Path(__file__).resolve().parents[2]
out=root/'experiments/active/independent_static_modal_20261029_v1'
def read(name):
    with (out/name).open(encoding='utf-8-sig',newline='') as f: return list(csv.DictReader(f))
s=read('static_case_metrics.csv'); m=read('modal_case_metrics.csv'); times=read('prediction_times.csv')
assert len(s)==640 and len(m)==3072 and len(times)==1152
for rows,keys in [(s,['Model','Seed','CaseID']),(m,['Model','Seed','CaseID','Frequency']),(times,['Task','Model','Seed','CaseID'])]:
    assert len({tuple(r[k] for k in keys) for r in rows})==len(rows)
for r in s:
    expected=float(r['Absolute_m'])/max(float(r['ReferenceNorm_m']),1e-14)
    assert math.isclose(float(r['Relative']),expected,rel_tol=1e-12,abs_tol=1e-15)
groups=collections.defaultdict(list)
for r in m:
    truth=float(r['TruthHz']); raw=float(r['RawHz']); ordered=float(r['SortedHz'])
    assert truth>0 and raw>0 and ordered>0
    for name,val in [('Raw',raw),('Sorted',ordered)]:
        absolute=abs(val-truth); relative=absolute/truth
        assert math.isclose(float(r['Absolute'+name+'Hz']),absolute,rel_tol=1e-12,abs_tol=1e-10)
        assert math.isclose(float(r['Relative'+name]),relative,rel_tol=1e-12,abs_tol=1e-14)
    groups[(r['Model'],r['Seed'],r['CaseID'])].append(r)
assert len(groups)==512
for rows in groups.values():
    rows.sort(key=lambda x:int(x['Frequency'])); assert len(rows)==6
    raw=[float(r['RawHz']) for r in rows]; ordered=[float(r['SortedHz']) for r in rows]
    assert ordered==sorted(raw)
    mask=''.join('1' if raw[i]>raw[i+1] else '0' for i in range(5))
    assert all(r['PairMask'].zfill(5)==mask and int(r['ViolationPairs'])==mask.count('1') for r in rows)
assert all(math.isfinite(float(r['MedianSeconds'])) and float(r['MedianSeconds'])>0 for r in times)
text=('# Unabhaengiger Exportaudit\n\n640 statische und 3.072 modale Fall-/Frequenzzeilen '
      'sowie 1.152 Timingzeilen sind vollstaendig und eindeutig. Relative und absolute '
      'Fehler wurden aus den gespeicherten Werten nachgerechnet; 512 modale Rohvektoren, '
      'Nachsortierung und Ordnungsverletzungen stimmen ueberein. Alle Timingmediane '
      'sind positiv und endlich. P95 ist im Bericht aus 128 Einzelwerten als '
      '122. sortierter Wert berechnet. Dieser Audit belegt keine FEM-Netzgenauigkeit.\n')
path=out/'EXPORT_AUDIT.md'
if path.exists(): assert path.read_text(encoding='utf8')==text
else: path.write_text(text,encoding='utf8')
print('Export audit passed:',len(s),'static;',len(m),'modal rows;',len(times),'timings')
