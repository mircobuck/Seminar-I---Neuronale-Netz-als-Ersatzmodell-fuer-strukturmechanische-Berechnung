# Bereinigung und Wiederaufnahme am 12.11.2026

Vom Nutzer ausdruecklich beauftragt. Vor beiden Entfernungen wurden absolute Pfade und ReparsePoint-Attribute geprueft.

- Der saubere Worktree `../github_dd_branch_v2` wurde ausschliesslich mit `git worktree remove` ohne Force entfernt. Status einschliesslich unversionierter und ignorierter Dateien war leer. Branch `code-v2` bleibt bei `aca50b7d74e9d49b3e19fc074c88b9deb25feba6` erhalten. Gemeinsame Git-Objekte und Historie bleiben erhalten.
- `seminar_vortrag/.venv` wurde nach erfolgreichem `pip freeze --all` entfernt. Keine versionierten Dateien, kein laufender Python-Prozess dieser Umgebung. Vollstaendige Paketliste: `seminar_vortrag/requirements-environment-20261112.txt` (SHA256 `989facd95c6e78680dd8e309910f6832ce2c80055e488daa2a0c4056474c56cd`). Wiederherstellung im Seminarordner: `py -3.12 -m venv .venv`, danach `.venv\Scripts\python.exe -m pip install -r requirements-environment-20261112.txt`. Externe FFmpeg-/LaTeX-Voraussetzungen siehe Seminar-README.
- Wissenschaftliche Ergebnisse, Referenzen, Vortragscode, Videos und Literatur wurden nicht geloescht. Keine Git-Packdateien entfernt.

Freier Speicher vorher: 625508352 Bytes. Nachher: 2048761856 Bytes (1.908 GiB); Startschwelle 1.75 GiB erfuellt. Laufzeitreserve bleibt 512 MiB.

Vor Wiederaufnahme stimmen alle 72 Dateien des erfolgreichen Smoke-Quellmanifests per SHA256 mit dem aktuellen Inhalt ueberein. Keine fachliche Codeaenderung, deshalb keine vollstaendige Testwiederholung. Versuch 4 verwendet unveraenderte Fachkonfiguration und vorhandene FEM-Referenzen. Der Nutzer hat die vorherige Vertagung aufgehoben und den vollstaendigen Lauf beauftragt.
