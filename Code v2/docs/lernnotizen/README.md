# Meine Lernnotizen zu Code v2

`mein_codeleitfaden.tex` ist ein einfaches LaTeX-Geruest zu `runStaticStudy` und zur FEM-Datenerzeugung, beginnend mit einem einzelnen Fall in `solve_case.m`.

Eigene Erklaerungen direkt unter den jeweiligen Ueberschriften schreiben. Die Kommentare im LaTeX-Quelltext dienen als Platzhalter. Unter `phase` lassen sich nach Bedarf einzelne Phasen mit `\subsubsection{...}` ergaenzen.

`mein_codeleitfaden.pdf` ist die kompilierte Vorschau. Nach Aenderungen aus diesem Ordner neu kompilieren:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error mein_codeleitfaden.tex
```
