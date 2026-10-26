from pathlib import Path
import csv, statistics, math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

p=Path(__file__).resolve().parent
def read(name):
    with (p/name).open(encoding="utf-8",newline="") as f: return list(csv.DictReader(f))
rows=read("case_metrics.csv"); summary=read("summary.csv"); paired=read("paired.csv")
assert len(rows)==192 and len(paired)==64
delta=[float(r["hybridMinusBeamPctPoints"]) for r in paired]
better=sum(x< -1e-10 for x in delta); worse=sum(x>1e-10 for x in delta); equal=64-better-worse
direct=sum(float(r["hybridMinusDirectPctPoints"]) < -1e-10 for r in paired)
models=["Balkenfeld","Direkt normiert","Hybrid normiert"]
lines=["# Unabhängige Bestätigungsstudie: statische Verschiebungsfelder","",
"## Fragestellung und Protokoll","",
"Die drei eingefrorenen Verfahren wurden auf 64 neuen Parameterfällen innerhalb des dokumentierten Balkenparameterraums verglichen. Das vorab gespeicherte Protokoll legte Sampling, Modelle und Metriken fest. Die neuen Fälle sind nach dieser Auswertung verbrauchte Testfälle. Die Entwicklung der Modelle erfolgte mit Trainings-IDs 1–12 und 25–30 sowie Entwicklungs-IDs 31–36. Ein Nachtraining fand nicht statt.","",
"Latin-Hypercube-Sampling mit Seed 20261026 erzeugte IDs 100001–100064. Die historische Prüfung erfasste 1384 verfügbare CSV-Designzeilen; gleiche normierte Geometrie und Poissonzahl innerhalb 1e-10 wurden als äquivalent behandelt, unabhängig von E und F. Der kleinste beobachtete normierte maximale Abstand zu historischen Kombinationen beträgt 0,03685. Eine Garantie für nicht verfügbare historische Designs besteht nicht.","",
"Die Referenz ist ein einseitig eingespannter linear-elastischer Quader mit gleichmäßiger Stirnlast, quadratischen Tetraedern, Hmax=min(b,h)/3 und 21×5×5-Abfragegitter. Je Fall wurde eine FEM-Datei gespeichert. Die Vorhersagefunktion erhielt Modell, Parameter und Gitter, keine FEM-Zielfelder. Feldfehler verwenden gewichtete RMS-Norm; relative Komponenten- und Spitzenfehler sind bei Referenznorm ≤1e-14 m ungültig.","",
"## Hauptergebnisse","",
"| Modell | N | Mittel % | Median % | 95%-Quantil % | Maximum % |","|---|---:|---:|---:|---:|---:|"]
for i,s in enumerate(summary):
 lines.append("| {} | {} | {:.4f} | {:.4f} | {:.4f} | {:.4f} |".format(models[i],s["N"],*[float(s[k]) for k in ("meanPct","medianPct","p95Pct","maxPct")]))
lines += ["",f"Der Hybrid war gegenüber dem Balkenfeld in {better} Fällen besser und in {worse} Fällen schlechter; {equal} Fälle lagen innerhalb der Gleichheitstoleranz von 1e-10 Prozentpunkten. Die paarweisen Differenzen Hybrid minus Balken lagen zwischen {min(delta):.4f} und {max(delta):.4f} Prozentpunkten. Gegenüber dem direkten Modell war der Hybrid in {direct} von 64 Fällen besser.","",
"Die drei Verschlechterungen betreffen Fälle 100001, 100047 und 100055 mit 0,2801, 0,0707 und 0,0423 Prozentpunkten. Die Ergebnisse sprechen für eine breit beobachtete Verbesserung des eingefrorenen Hybridmodells in diesem Test, lassen aber einzelne Verschlechterungen zu. Die direkte normierte Variante zeigt einen deutlich höheren Mittelwert und ein ausgeprägtes Maximum. Die Entscheidung ist nicht nachträglich für diese Testfälle geändert worden.","",
"![Fallweise Fehler.](fallfehler.png)","",
"## Komponenten, Rand und Projektion","",
"Die Tabelle case_metrics.csv enthält pro Modell und Fall die absoluten gewichteten Komponenten-RMS in Metern, relative Komponentenfehler, absolute und relative Spitzenfehler sowie rohe und nachbearbeitete Einspannfehler und Größe der Korrektur. Nicht verfügbare relative Werte werden als NaN geführt. Die paarweisen Werte und diagnostischen POD-Projektionsfehler stehen in paired.csv. Die Projektion nutzt die FEM-Referenz erst nach Speicherung aller Vorhersagen und ist keine Vorhersage.",""]
for i,name in enumerate(models,1):
 subset=[r for r in rows if int(r["model"])==i]
 inv=sum(not math.isfinite(float(r["uyPct"])) for r in subset)
 av=[statistics.mean(float(r[x]) for r in subset) for x in ("uxAbsM","uyAbsM","uzAbsM","tipAbsM")]
 lines.append(f"- {name}: mittlerer absoluter RMS ux/uy/uz = {av[0]:.3g} / {av[1]:.3g} / {av[2]:.3g} m; mittlerer absoluter Spitzenfehler {av[3]:.3g} m; ungültige uy-Relativwerte {inv}.")
lines += ["","![Fehler gegen Trainingsabstand und Elastizitätsmodul.](diagnostic.png)","","![FEM, Hybrid und Differenz für den schlechtesten Hybridfall, in Mikrometern.](field_worst.png)","","## Laufzeiten und Grenzen","",
"Die Datei timing.mat enthält fünf Wiederholungen nach Warm-up für Einzel- und 64er-Batchvorhersagen mit getrennten internen Kosten. Die FEM-Zeit in evaluation.mat umfasst Netzgenerierung, Lösung und Interpolation. Eine zusätzliche wiederholte Messung an Fall 100001 trennt diese Anteile. Frühere Trainingskosten gehören zur Offlinephase.",""]
with (p/"timing.csv").open() as f: timing=[[float(x) for x in r] for r in csv.reader(f)]
with (p/"fem_timing.csv").open() as f: fem=[[float(x) for x in r] for r in csv.reader(f)]
avg=[statistics.mean(row[j] for row in fem) for j in range(4)]
for row in timing:
 lines.append("- {}: {} Fälle, mittlere Gesamtzeit {:.3f} ms, davon Physik {:.3f}, Regression {:.3f}, Rekonstruktion {:.3f} und Nachbearbeitung {:.3f} ms.".format(models[int(row[0])-1],1 if row[1]==1 else 64,row[7]*1000,row[2]*1000,row[4]*1000,row[5]*1000,row[6]*1000))
lines += ["",f"FEM Fall 100001: mittlerer Netzaufbau {avg[0]:.3f} s, Lösung {avg[1]:.3f} s, Interpolation {avg[2]:.3f} s, Gesamt {avg[3]:.3f} s (fünf Wiederholungen nach Warm-up). Die FEM-Gesamtzeit enthält die Problemdefinition; die Vorhersagezeiten enthalten Validierung und Randnachbearbeitung. Ein Zeitverhältnis bezieht sich nur auf diese erfassten Ausgaben und diesen Fall.","",
"Der beobachtete maximale Fehler ist keine garantierte Fehlerschranke. Die Schlussfolgerungen betreffen den untersuchten Parameterbereich, die hier festgelegte Lastform und das konkrete raumfüllende Design. 64 Parameterfälle sind keine Zufallsstichprobe, die automatisch eine populationsweite Garantie liefert. Die Modelle wurden vor und nach der Studie per Hash überprüft.","",
"## Reproduktion und Quellen","",
"Die Artefakte design.mat, fem_*.mat, predictions.mat, evaluation.mat und timing.mat dokumentieren Daten, Modelloutputs und Auswertung. PROTOKOLL.md und hashes_before.csv enthalten die vorher festgelegten Regeln und Hashes; hashes_after.csv belegt die anschließende Prüfung. run_static_confirmation.m, evaluate_static_confirmation.m und time_static_confirmation.m sind die Einstiegspunkte. Dieser Berichtsgenerator liest nur gespeicherte CSV-Dateien und trainiert keine Modelle.",""]
(p/"BERICHT.md").write_text("\n".join(lines),encoding="utf-8")
f,ax=plt.subplots(figsize=(9,4))
for i,name in enumerate(models,1):
 vals=[float(r["fieldPct"]) for r in rows if int(r["model"])==i]
 ax.plot(range(1,65),vals,marker=".",label=name,linewidth=.8)
ax.set_yscale("log");ax.set_xlabel("Neuer Fall (laufende Nummer)");ax.set_ylabel("Relativer Feldfehler (%)")
ax.grid(alpha=.25);ax.legend();f.tight_layout();f.savefig(p/"fallfehler.pdf");f.savefig(p/"fallfehler.png",dpi=150);plt.close(f)
def esc(s):
 for a,b in [("\\",r"\textbackslash{}"),("&",r"\&"),("%",r"\%"),("_",r"\_"),("#",r"\#")]:s=s.replace(a,b)
 return s.replace("≤",r"$\leq$")
out=[r"\documentclass[11pt,a4paper]{article}",r"\usepackage[ngerman]{babel}",r"\usepackage{fontspec,amsmath,graphicx,geometry,booktabs,longtable,array,hyperref}",r"\geometry{margin=25mm}",r"\setlength{\parindent}{0pt}\setlength{\parskip}{5pt}\emergencystretch=3em",r"\begin{document}",r"\tableofcontents\newpage"]
i=0
while i<len(lines):
 line=lines[i]
 if line.startswith("|"):
  table=[]
  while i<len(lines) and lines[i].startswith("|"):
   c=[v.strip() for v in lines[i].strip("|").split("|")]
   if not all(set(v)<=set("-: ") for v in c):table.append(c)
   i+=1
  out.append(r"\begin{longtable}{lrrrrr}\toprule")
  for n,row in enumerate(table):out.append(" & ".join(esc(x) for x in row)+r"\\"+(r"\midrule\endhead" if n==0 else ""))
  out.append(r"\bottomrule\end{longtable}");continue
 if line.startswith("# "):out.append(r"\section*{"+esc(line[2:])+"}")
 elif line.startswith("## "):
  out.append(r"\section{"+esc(line[3:])+"}")
  if line=="## Hauptergebnisse":out.append(r"$e=\|u-\hat u\|_W/\|u\|_W$, \quad $s=(F/-500\,\mathrm{N})(10^{11}\,\mathrm{Pa}/E)$, \quad $\hat u_\mathrm{hybrid}=u_\mathrm{beam}+s(\bar\Delta+\Phi\hat a)$.")
 elif line.startswith("!["):
  caption=line[2:line.index("]")]; path=line[line.index("(")+1:line.rindex(")")]
  out.append(r"\begin{figure}[htbp]\centering\includegraphics[width=\linewidth]{"+path+r"}\caption{"+esc(caption)+r"}\end{figure}")
 elif line:out.append(esc(line)+"\n")
 i+=1
out.append(r"\end{document}");(p/"BERICHT.tex").write_text("\n".join(out),encoding="utf-8")
