"""Verify protected prior experiments and archive the executed new source."""
from pathlib import Path
import hashlib,json,shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(8*1024*1024),b''): h.update(chunk)
    return h.hexdigest()
protected=json.loads((HERE/'protected_files.json').read_text(encoding='utf-8-sig'))
errors=[]
for item in protected:
    p=Path(item['path'])
    if not p.is_file() or digest(p).upper()!=item['sha256'].upper(): errors.append(str(p))
result={'protected_count':len(protected),'changed':errors,'status':'PASS' if not errors else 'FAIL'}
(HERE/'preservation_check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
assert not errors,errors
snapshot=HERE/'source_snapshot'; snapshot.mkdir(exist_ok=True)
files=['benchmark_deeponet_engine.m','run_deeponet_study.m','run_deeponet_logged.m','evaluate_deeponet_baselines.m',
       'export_deeponet_diagnostics.m','src/deeponet_forward.m',
       'src/deeponet_gradients.m','src/fit_deeponet.m','src/predict_deeponet.m',
       'tests/deeponetTest.m','config.m','src/reference_grid.m','src/field_error.m']
for relative in files:
    target=snapshot/relative; target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/relative,target)
manifest={str(p.relative_to(HERE)):digest(p) for p in HERE.rglob('*')
          if p.is_file() and p.name!='artifact_hashes.json' and '__pycache__' not in p.parts}
(HERE/'artifact_hashes.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(result))
