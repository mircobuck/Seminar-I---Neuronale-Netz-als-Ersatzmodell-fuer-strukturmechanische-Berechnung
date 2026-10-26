from pathlib import Path

root = Path(__file__).resolve().parent
old = root / "experiments/architecture_phase1_v1/wissenschaftlicher_versuchsbericht.tex"
out = root / "experiments/hybrid_controlled_fits_v1/gesamtbericht.tex"
text = old.read_text(encoding="utf-8")
section = r"""
\section{Kontrollierte statische GPR-Nachuntersuchung vom 26. Oktober 2026}
Das vorab festgelegte Protokoll verwendet nur Training 1--12 und 25--30 sowie interne Validierung 31--36. Die früher betrachteten Testfälle wurden für die neuen Fits nicht geladen. Die ursprüngliche Auswahl und eingefrorenen Modelle bleiben unverändert. Die ursprüngliche Auswahl wählte das Balkenfeld; die nachfolgende Normierung ist eine neue Entwicklungsvariante.

Die manuelle Rückskalierung und Auswertung der gespeicherten Gaußprozesse reproduziert die ursprünglichen Funktionen bis auf Rundung. Die Kernelkorrelationen aus \texttt{analysis.mat} sind wegen eines korrigierten Auswertungsfehlers ungültig; maßgeblich ist \texttt{analysis\_v2.mat}. Die genaue Ursache der Generalisierung bleibt offen.

Kontrollwiederholung und drei Startwerte je Gruppe wurden auf gleichem POD-Rang und Squared-Exponential-Kernel durchgeführt. Pro Gruppe wählt die Trainings-Log-Likelihood; die Validierungszahlen sind Entwicklungswerte. MATLAB hob den Startwert für lernbares Sigma automatisch an und gab dabei Warnungen aus. Die Änderung von F/E verwendet ausschließlich bekannte Eingaben:
\[
s(\mu)=\frac{F}{-500\,\mathrm N}\frac{10^{11}\,\mathrm{Pa}}{E},
\quad U_{\mathrm{norm}}=U/s,\quad \widehat U=s\widehat U_{\mathrm{norm}}.
\]
Sie ist für den vorliegenden Bereich mit $F<0$ und $E>0$ definiert und benötigt lineare Elastizität bei gleicher Lastform.
\begin{center}\begin{tabular}{lrr}\toprule
Modell / Variante & Validierung & Projektion\\\midrule
Balken & 0,5215\,\% & --\\
Direkt Kontrolle & 113,834\,\% & 0,0654\,\%\\
Direkt feste Starts & 113,835\,\% & 0,0654\,\%\\
Direkt lernbares Sigma & 113,808\,\% & 0,0654\,\%\\
Direkt F/E-normalisiert & 10,687\,\% & 0,0488\,\%\\
Hybrid Kontrolle & 0,8544\,\% & 0,01185\,\%\\
Hybrid feste Starts & 0,8544\,\% & 0,01185\,\%\\
Hybrid lernbares Sigma & 0,8544\,\% & 0,01185\,\%\\
Hybrid F/E-normalisiert & 0,1289\,\% & 0,00443\,\%\\
\bottomrule\end{tabular}\end{center}
Die Normierung verändert zusätzlich die trainierte POD-Basis. Ihre Verbesserung auf der wiederholt verwendeten Entwicklungsvalidierung beweist weder eine einzelne Ursache noch unabhängige Generalisierung. Für eine Bestätigung sind neue unabhängige Parameterfälle erforderlich. 
\begin{figure}[htbp]\centering
\includegraphics[width=.88\linewidth]{validation_candidates.pdf}
\caption{Mittlerer Feldfehler pro vorab definiertem Kandidaten auf der internen Validierung.}
\end{figure}
\begin{figure}[htbp]\centering
\includegraphics[width=.75\linewidth]{pod_compression.pdf}
\caption{Projektionsfehler auf gleicher absoluter physikalischer Skala.}
\end{figure}
\begin{figure}[htbp]\centering
\includegraphics[width=.98\linewidth]{field_cases.pdf}
\caption{Normiertes hybrides Modell: FEM, Vorhersage und Differenz auf der Ebene $\eta=0{,}5$ für drei Validierungsfälle.}
\end{figure}
Kontrollwiederholung und erneutes Laden beider normalisierten Modelle reproduzierten die geprüften gespeicherten Felder exakt. Veränderte Koordinaten, ungültiges Schema, $F=0$ und $E=0$ wurden von der neuen Online-Schnittstelle abgewiesen. Eine gezielte Unterbrechung und Wiederaufnahme zweier Kontrollfits gelang; Integrität und Herkunft fremder Checkpoints werden nicht geprüft. Die frühere Modalstudie ist lediglich ein kleiner Integrationslauf.

\begin{figure}[htbp]\centering
\includegraphics[width=.85\linewidth]{validation_coefficients.pdf}
\caption{Historische Koeffizientendiagnose der internen Validierung; keine neuen normalisierten Fits.}
\end{figure}

Auf AMD Ryzen 5 4500U mit MATLAB R2025b Update 1 betrug die mittlere Gesamtzeit nach einem Warm-up und fünf Wiederholungen bei sechs Fällen etwa 4,8 ms direkt und 4,7 ms hybrid. Für das Hybridmodell entfielen etwa 1,0 ms auf das Balkenfeld, 2,6 ms auf die Regression, 0,4 ms auf die Rekonstruktion und 0,2 ms auf Nachbearbeitung; die direkte Berechnung auf dem Referenzgitter benötigt keine zusätzliche Übertragung. Die Gesamtzeit enthält außerdem Eingabeprüfungen. Dies sind Momentaufnahmen mit Messrauschen. Einzelwerte und die vollständige technische Abnahmematrix stehen in \texttt{acceptance.mat} und \texttt{ABNAHME.md}.

\textbf{Literatur.} C. E. Rasmussen und C. K. I. Williams, \emph{Gaussian Processes for Machine Learning}, MIT Press, 2006, \url{https://gaussianprocess.org/gpml/}; L. Sirovich, Turbulence and the dynamics of coherent structures I, \emph{Quarterly of Applied Mathematics} 45 (1987), 561--571, \url{https://doi.org/10.1090/QAM/910462}.

{\small\sloppy Reproduktion ohne erneutes Training: \texttt{summarize\_controlled\_gpr} und \texttt{plot\_controlled\_fields}; diese Funktionen lesen gespeicherte Modelle und Referenzfelder.\par}
"""
text = text.replace(r"\section*{Reproduzierbarkeit und Quellen}", section + "\n" + r"\section*{Reproduzierbarkeit und Quellen}")
out.write_text(text, encoding="utf-8")
