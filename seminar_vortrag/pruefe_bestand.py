"""Compare repository files against the recorded pre-implementation snapshot."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
project = root / 'seminar_vortrag'
before = json.loads((project / 'bestand_vorher.json').read_text(encoding='utf-8'))
after = {}
for path in root.rglob('*'):
    relative = path.relative_to(root)
    if '.git' in relative.parts or 'seminar_vortrag' in relative.parts or not path.is_file():
        continue
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024), b''):
            digest.update(block)
    after[relative.as_posix()] = digest.hexdigest()
report = {'vorher': len(before), 'nachher': len(after),
          'neu': sorted(after.keys() - before.keys()),
          'entfernt': sorted(before.keys() - after.keys()),
          'geaendert': sorted(k for k in before.keys() & after.keys() if before[k] != after[k])}
(project / 'bestand_nachher.json').write_text(json.dumps(after, indent=2, ensure_ascii=False), encoding='utf-8')
(project / 'pruefung_bestand.json').write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps(report, indent=2, ensure_ascii=False))
if report['neu'] or report['entfernt'] or report['geaendert']:
    raise SystemExit(1)
