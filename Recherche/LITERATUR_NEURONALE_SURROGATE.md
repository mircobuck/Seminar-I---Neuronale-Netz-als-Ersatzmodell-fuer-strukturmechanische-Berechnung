# Literatur zu neuronalen Ersatzmodellen

Stand: 26. Oktober 2026. Diese zehn Veröffentlichungen sind Referenzen für die Literaturrecherche und die Auswahl von Modellfamilien. Sie beschreiben nicht zehn voneinander unabhängige Verfahren. Die verlinkten Originalseiten enthalten, soweit verfügbar, den Volltext oder einen PDF-Link.

## Direkt relevant für den Balken

1. Paridie, A. M., Ene, N. M. & Mohamed, Y. S. (2022). *Using neural networks to predict the effect of the preload location on the natural frequencies of a cantilever beam.* Heliyon 8(11), e11242. https://doi.org/10.1016/j.heliyon.2022.e11242 — Vollständig verbundenes Netz für mehrere Eigenfrequenzen eines Kragträgers. Die Arbeit behandelt einen vorgespannten Balken und ist deshalb methodisch, nicht physikalisch identisch mit unserem ungelasteten Modalproblem. Freier Volltext: https://pmc.ncbi.nlm.nih.gov/articles/PMC9640955/ (CC BY). Ein lokaler PDF-Abruf war über den PMC-Endpunkt nicht möglich; die angegebene PDF-URL lieferte eine Download-Schutzseite statt eines PDFs.

2. Salvador, M., Dede', L. & Manzoni, A. (2021). *Non intrusive reduced order modeling of parametrized PDEs by kernel POD and neural networks.* https://arxiv.org/abs/2103.17152 — Reduzierter Feldraum und neuronale Vorhersage seiner Koeffizienten; methodische Referenz für das Balkenfeldmodell. [Lokale PDF](./02_Salvador_Dede_Manzoni_2021_Reduced_Basis_Neural_Coefficients.pdf).

3. Fresca, S. & Manzoni, A. (2022). *POD-DL-ROM: Enhancing deep learning-based reduced order models for nonlinear parametrized PDEs by proper orthogonal decomposition.* Computer Methods in Applied Mechanics and Engineering 388, 114181. https://doi.org/10.1016/j.cma.2021.114181 — Weiterentwicklung reduzierter neuronaler Modelle, vor allem für spätere nichtlineare Problemstellungen. Freie Vorabversion: https://arxiv.org/abs/2101.11845. [Lokale PDF](./03_Fresca_Manzoni_2022_Reduced_Deep_Models.pdf).

4. Lu, L., Jin, P., Pang, G., Zhang, Z. & Karniadakis, G. E. (2021). *Learning nonlinear operators via DeepONet based on the universal approximation theorem of operators.* Nature Machine Intelligence 3, 218–229. https://doi.org/10.1038/s42256-021-00302-5 — Tiefes Operatornetz für ortsabhängige Feldvorhersagen. Freie Vorabversion: https://arxiv.org/abs/1910.03193. [Lokale PDF](./04_Lu_2021_DeepONet.pdf).

## Erweiterungen und spätere komplexe Geometrien

5. Raissi, M., Perdikaris, P. & Karniadakis, G. E. (2019). *Physics-informed neural networks: A deep learning framework for solving forward and inverse problems involving nonlinear partial differential equations.* Journal of Computational Physics 378, 686–707. https://doi.org/10.1016/j.jcp.2018.10.045 — Grundlegung physik-informierter Netze; für eine spätere klar formulierte Physikverlustfunktion. Lokale PDF: frei verfügbare arXiv-Vorabversion, *Physics Informed Deep Learning (Part I)*: https://arxiv.org/abs/1711.10561. [Datei](./05_Raissi_Perdikaris_Karniadakis_2019_Physics_Informed_Neural_Networks.pdf).

6. Brivio, S., Fresca, S. & Manzoni, A. (2024). *PTPI-DL-ROMs: Pre-trained physics-informed deep learning-based reduced order models for nonlinear parametrized PDEs.* Computer Methods in Applied Mechanics and Engineering 432, 117404. https://doi.org/10.1016/j.cma.2024.117404 — Kombination von reduziertem Modell und Physikverlust, vor allem bei knapperen Daten und späterer Komplexität. Freie Vorabversion: https://arxiv.org/abs/2405.08558. [Lokale PDF](./06_Brivio_Fresca_Manzoni_2024_Physics_Informed_Reduced_Models.pdf).

7. Li, Z. et al. (2021). *Fourier Neural Operator for Parametric Partial Differential Equations.* International Conference on Learning Representations. https://arxiv.org/abs/2010.08895 — Fourier-basierter Operator auf geeigneten regelmäßigen Feldrepräsentationen; für spätere Probleme prüfen, nicht blind auf unstrukturierte Motornetze übertragen. [Lokale PDF](./07_Li_2021_Fourier_Neural_Operator.pdf).

8. Pfaff, T., Fortunato, M., Sanchez-Gonzalez, A. & Battaglia, P. W. (2021). *Learning Mesh-Based Simulation with Graph Networks.* International Conference on Learning Representations. https://arxiv.org/abs/2010.03409 — Graphnetz auf adaptiven, unstrukturierten Simulationsnetzen, einschließlich strukturmechanischer Beispiele. [Lokale PDF](./08_Pfaff_2021_Learning_Mesh_Based_Simulation.pdf).

9. Sanchez-Gonzalez, A. et al. (2020). *Learning to Simulate Complex Physics with Graph Networks.* Proceedings of Machine Learning Research 119, 8459–8468. https://proceedings.mlr.press/v119/sanchez-gonzalez20a.html — Grundlegender Graphnetz-Simulator für dynamische physikalische Systeme; besonders für spätere dynamische Erweiterungen relevant. [Lokale PDF](./09_Sanchez_Gonzalez_2020_Learned_Simulators.pdf).

10. Hu, H., Qi, L. & Chao, X. (2024). *Physics-informed Neural Networks (PINN) for computational solid mechanics: Numerical frameworks and applications.* Thin-Walled Structures 205(B), 112495. https://doi.org/10.1016/j.tws.2024.112495 — Übersichtsarbeit zur Strukturmechanik, keine zusätzliche Netzarchitektur. Der Verlagslink lieferte eine HTML-Seite; eine frei zugängliche PDF-Fassung war nicht auffindbar und wurde daher nicht lokal abgelegt.

## Einordnung für das Projekt

- Jetzt experimentell vergleichen: vollständig verbundenes Vorwärtsnetz für Skalare und Frequenzen; Hauptkomponentendarstellung mit neuronaler Koeffizientenvorhersage für Felder; physikalisches Balkenfeld plus gelerntes Restfeld; vorhandenes tiefes Operatornetz.
- Später anhand konkreter Anforderungen prüfen: physik-informierte Netze, Fourier-basierte Operatoren und Graphnetze. Die Wahl hängt unter anderem von Geometrie, Netzrepräsentation, Randbedingungen, Zielgrößen und verfügbarer Datenmenge ab.
- Die Eigenfrequenz-Arbeit unter Nummer 1 ersetzt die zuvor genannte Knieknorpel-Studie als deutlich näher liegende Referenz für den Kragträger.
