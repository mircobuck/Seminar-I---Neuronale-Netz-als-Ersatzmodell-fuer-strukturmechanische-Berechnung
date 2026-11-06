# Training eines MLP – Manim-Seminaranimation

Eine eigenständige, stumme Manim-Community-Animation mit dunklem Hintergrund. Ein dimensionsloses Beispiel zeigt ein Netz `6 → 8 → 6 → 4 → 1`: Forward Pass, quadratischer Fehler, Backpropagation und Training. Das ist ein didaktisches Einzelbeispiel, keine FEM-Berechnung und kein Nachweis der Generalisierung.

## Voraussetzungen und Installation

Python 3.12, FFmpeg, LaTeX (einschließlich der von Manim benötigten Pakete) und `dvisvgm` müssen installiert und im PATH verfügbar sein. MiKTeX sollte bereits alle Pakete enthalten; automatische Installation fehlender LaTeX-Pakete bitte ausschalten. Unter Windows PowerShell im Ordner `seminar_vortrag`:

```powershell
py -3.12 -m venv .venv
$env:TEMP = (Join-Path (Get-Location) '.tmp')
$env:TMP = $env:TEMP
$env:PIP_CACHE_DIR = (Join-Path (Get-Location) '.pip-cache')
New-Item -ItemType Directory -Force .tmp | Out-Null
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Unter Linux/macOS statt `.venv\Scripts\python.exe` den Interpreter `.venv/bin/python` verwenden. Das Teilprojekt kann in ein anderes Repository kopiert und dort mit einer neu erstellten virtuellen Umgebung installiert werden.

## Rendern und Prüfen

```powershell
.\.venv\Scripts\python.exe -m unittest -v test_training
.\.venv\Scripts\python.exe render.py --quality preview
.\.venv\Scripts\python.exe render.py --quality final
```

Die Vorschau steht unter `media/preview/mlp_training.mp4`, der finale Film unter `media/final/mlp_training.mp4`. Das Skript verwendet Cairo und speichert Medien und temporäre Dateien lokal. Die Voreinstellungen sind 854 × 480 bei 15 fps beziehungsweise 1920 × 1080 bei 30 fps. Das erstmalige Rendern benötigt wegen der Formeln etwas Zeit.

Wenn der Windows-Starter der virtuellen Umgebung in einer eingeschränkten Ausführungsumgebung den Basisinterpreter nicht findet, lassen sich die lokal installierten Pakete auch mit dem Python-3.12-Basisinterpreter aufrufen:

```powershell
$env:PYTHONPATH = (Join-Path (Get-Location) '.venv\Lib\site-packages')
$basePython = py -3.12 -c 'import sys; print(sys.executable)'
& $basePython -m unittest -v test_training
& $basePython render.py --quality preview
```

## Konfiguration und Interpretation

In `config.py` stehen Eingaben, Zielwert, drei Hidden-Layer-Größen, Aktivierungsfunktion (`tanh`, `sigmoid`, `relu`), Lernrate, Epochen, Farben, Wiedergabegeschwindigkeit und Ausgabeauflösung. `speed > 1` beschleunigt die Animation. Die Hidden Layers dürfen jeweils 1 bis 12 Neuronen enthalten. Eingaben und Ausgabe sind bewusst dimensionslos.

`training.py` implementiert einen vorzeichenbehafteten MLP mit linearer Ausgabe und analytischer Backpropagation. Die Beispiele verwenden einen festen Seed und ein einzelnes Datenpaar. Bei einem Loss-Anstieg wird die Lernrate für den betreffenden Schritt halbiert; der verwendete Wert steht im jeweiligen Snapshot. Deshalb ist die sinkende Kurve das Ergebnis der dargestellten Optimierung, keine erfundene Kurve.

`scene.py` zeigt Gewichtsvorzeichen in Blau/Rot, Stärke über Linienbreite und Deckkraft, Aktivierungen in Gelb beziehungsweise Rot für negative Werte und Rückwärtssignale in Orange. Die Rückwärtssignale stehen für die Größe der berechneten Gradienten. `test_training.py` vergleicht analytische Gradienten mit finiten Differenzen und prüft deterministisches Training. `render.py` ist der portable Einstiegspunkt.
