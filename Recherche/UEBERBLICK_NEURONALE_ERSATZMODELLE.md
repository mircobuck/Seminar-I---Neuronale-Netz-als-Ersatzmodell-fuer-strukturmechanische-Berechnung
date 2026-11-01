# Neuronale Ersatzmodelle: Literaturueberblick

Stand: 27. Oktober 2026. Bezug: `Projektbeschreibung/CSE_Masterseminar1_Surrogate_Models.pdf`. Die Tabelle trennt **Modellfamilien** von **Trainings- und Datenauswahlverfahren**. Ein Paper kann mehrere Bausteine kombinieren; die Anzahl der Quellen ist daher nicht die Anzahl unabhaengiger Modelle.

## Abgedeckte Modellfamilien

| Modellfamilie | Abgedeckte Paper im Rechercheordner | Bezug zum Seminar |
| --- | --- | --- |
| Direktes Feedforward-Netz (MLP) | Paridie et al. (2022), in `LITERATUR_NEURONALE_SURROGATE.md` verlinkt; weitere Anwendungen und Uebersichten als PDF | Baseline fuer Balkenauslenkung an festen Positionen und Eigenfrequenzen. |
| Reduzierter Feldraum + neuronale Koeffizienten | Salvador et al. (2021); Fresca & Manzoni (2022) | Fuer Auslenkungsfelder mit vielen Ausgabepunkten; POD/kernel-POD und lernbare Koeffizienten. |
| Neuronale Operatoren | Lu et al. (2021), DeepONet; Li et al. (2021), Fourier Neural Operator | Vorhersage ganzer Felder. DeepONet ist naheliegender fuer beliebige Abfrageorte; FNO benoetigt eine geeignete regelmaessige Feldrepraesentation. |
| Physik-informierte Netze | Raissi et al. (2019); Brivio et al. (2024) | Differentialgleichung beziehungsweise reduzierte Physikbedingungen im Training. |
| FEM-informierte Netze | Le-Duc et al. (2023), Verlagslink unten; Meethal et al. (2023), lokales PDF | FEM-Residual bzw. schwache Form im Verlustterm; relevant fuer parametrische statische Strukturmechanik. |
| Graphbasierte Simulatoren | Pfaff et al. (2021); Sanchez-Gonzalez et al. (2020) | Fuer unstrukturierte Netze und spaetere dynamische/komplexere Geometrien. Fuer den ersten 1D-Balken zu aufwendig. |
| Multi-Fidelity-Netz | Meng & Karniadakis (2020), lokales PDF | Verknuepft viele guenstige mit wenigen hochwertigen Daten. Erst aussagekraeftig, wenn zwei Modelle mit unterschiedlicher Genauigkeit vorliegen. |

## Zusaetzlich abgedeckte Trainings- und Datenverfahren

| Verfahren | Paper | Sinnvolles Experiment |
| --- | --- | --- |
| Randbedingungen exakt durch den Ausgabeansatz erfuellen | Sukumar & Srivastava (2022), lokales PDF | Bei der Einspannung `w(0)=w'(0)=0` z. B. `w(x,p)=x^2 N(x,p)` gegen ein unbeschraenktes Netz vergleichen. Das ist eine PINN-/Netzvariante, keine eigene grosse Modellfamilie. |
| Adaptive Auswahl neuer Referenzrechnungen | Guo et al. (2024), lokaler offener XML-Volltext und PDF-Link unten | Fehler gegen Zahl der Referenzrechnungen bei adaptiver und vorher festgelegter Datenauswahl vergleichen. Die vollstaendige Methode des Papers mit hoher Ein- und Ausgabedimension ist fuer den einfachen Balken nicht erforderlich. |
| Multi-Fidelity-Training | Meng & Karniadakis (2020) | Erst bei sinnvoll voneinander abweichendem Balken- und aufwendigerem FEM-Modell testen. |

## Neu hinzugekommene Originalarbeiten und Zugriff

1. Le-Duc, T., Nguyen-Xuan, H. & Lee, J. (2023). *A finite-element-informed neural network for parametric simulation in structural mechanics.* Finite Elements in Analysis and Design 217, 103904. https://doi.org/10.1016/j.finel.2022.103904 — Das Verlags-PDF war beim Abruf mit HTTP 403 nicht verfuegbar; der verifizierte Verlagslink steht hier. Zur gleichen FEM-NN-Familie liegt zusaetzlich die frei verfuegbare Arbeit von Meethal et al. lokal vor.
2. Meethal, R. E. et al. (2023). *Finite Element Method-enhanced Neural Network for Forward and Inverse Problems.* Advanced Modeling and Simulation in Engineering Sciences 10, 6. https://doi.org/10.1186/s40323-023-00243-1 — [Lokales PDF der Vorabversion](./Meethal_et_al_2023_FEM_Enhanced_NN.pdf).
3. Sukumar, N. & Srivastava, A. (2022). *Exact imposition of boundary conditions with distance functions in physics-informed deep neural networks.* Computer Methods in Applied Mechanics and Engineering 389, 114333. https://doi.org/10.1016/j.cma.2021.114333 — [Lokales PDF](./Sukumar_Srivastava_2022_Exact_Boundary_Conditions.pdf).
4. Guo, Y., Nath, P., Mahadevan, S. & Witherell, P. (2024). *Active learning for adaptive surrogate model improvement in high-dimensional problems.* Structural and Multidisciplinary Optimization 67, 122. https://doi.org/10.1007/s00158-024-03816-9 — [Offizieller offener XML-Volltext](./Guo_et_al_2024_Active_Learning_Surrogate.xml), [Verlags-PDF](https://link.springer.com/content/pdf/10.1007/s00158-024-03816-9.pdf). Der automatisierte PDF-Abruf lieferte nur eine Schutzseite; diese wurde nicht als PDF abgelegt.
5. Meng, X. & Karniadakis, G. E. (2020). *A composite neural network that learns from multi-fidelity data: Application to function approximation and inverse PDE problems.* Journal of Computational Physics 401, 109020. https://doi.org/10.1016/j.jcp.2019.109020 — [Lokales PDF](./Meng_Karniadakis_2020_Multifidelity_NN.pdf).

## Empfehlung fuer die Untersuchungen

Fuer die erste Seminarphase: direktes MLP als Baseline, Feldvorhersage mit bestehendem DeepONet oder POD-NN, dazu FEM-informiertes Training und die exakt erfuellte Einspannung als gezielte Varianten. Die Dateneffizienz mit festen und adaptiv ergaenzten Trainingssaetzen pruefen. Multi-Fidelity, FNO und Graphnetze erst bei einem entsprechend komplexeren Referenzproblem experimentell verfolgen.

Die weiteren PDFs zu Topologieoptimierung und Uebersichten sind Kontextliteratur; sie werden hier nicht als zusaetzliche unabhaengige Modellfamilien gezaehlt.
