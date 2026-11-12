# LaTeX-Bericht zum statischen Methodenvergleich

`main.tex` ist der Einstieg; persönliche Angaben stehen zentral in `metadaten.tex`. Die vorhandene PDF ist mit MiKTeX und pdfLaTeX erzeugt. Relative Projektpfade erlauben den Build aus einer Kopie dieses Verzeichnisses.

## Build

Im Projektordner in einem Terminal nacheinander ausführen:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error main.tex
bibtex main
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
```

In VS Code `main.tex` mit LaTeX Workshop öffnen. `latexmk` benötigt zusätzlich eine funktionsfähige Perl-Installation; bei der Erstellung war Perl nicht verfügbar. Die obige direkte Buildfolge benötigt `latexmk` nicht. Keine globalen VS-Code-Einstellungen wurden geändert.

Die Vektordiagramme sind bereits in `abbildungen/` enthalten. Bei Bedarf können sie mit Python, NumPy und Matplotlib aus den kopierten Tabellen neu erstellt werden: `python skripte/diagramme.py`. Dies trainiert keine Modelle.

Vor Abgabe die Angaben in `metadaten.tex` ausfüllen und die konkreten formalen Anforderungen der Lehrveranstaltung beziehungsweise Betreuung prüfen. `THU_RECHERCHE.md` dokumentiert die gefundenen offiziellen Hinweise und den Geltungsbereich.
