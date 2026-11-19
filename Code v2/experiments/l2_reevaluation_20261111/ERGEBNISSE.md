# L2-Neuauswertung der POD-MLP-Studien

Stand: 11-Nov-2026 10:23:47.

Gespeicherte Modelle wurden geladen und ihre Vorhersagen neu berechnet. Kein neues Training, keine FEM und kein Zugriff auf produktive Testlabels.

Je Balkenfall: e = sqrt(sum(w .* (u_pred-u_ref).^2)) / sqrt(sum(w .* u_ref.^2)). Danach Median, arithmetischer Mittelwert, Nearest-Rank-P95 und Maximum ueber die Faelle. Alle relativen Kennzahlen in Prozent. Null-Referenzen bleiben NaN; Anzahl wird ausgewiesen.

Hauptvergleich: 128 bereits verwendete Validierungsfaelle. Architektur/Loss zusaetzlich auf den urspruenglichen 12 Faellen. Bei 12 Faellen ist Nearest-Rank-P95 das Maximum.

Konfigurationstabellen zeigen das arithmetische Mittel jeder Kennzahl ueber drei Seeds. MaximumPercent ist daher der Mittelwert der drei Fallmaxima; WorstObservedMaximumPercent ist das groesste beobachtete Maximum. Seeds sind keine neuen Balkenfaelle.

Rangfolge: aufsteigender mittlerer relativer L2-Fehler. Die Kennzahlen koennen unterschiedliche Rangfolgen ergeben. Diese erneute Validierung ist explorativ, kein neuer unabhaengiger Test.

## architecture_loss: 768 Trainingsfaelle, 128 Validierungsfaelle

| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median % | Mittelwert % | P95 % | Maximum % | Groesstes Maximum % |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| weighted_field_mse | 64 | 3 | adam | 0.001 | 10 | 2.3359 | 4.0421 | 12.2747 | 38.1670 | 53.9738 |
| weighted_field_mse | 128 | 2 | adam | 0.001 | 10 | 1.9671 | 4.2966 | 16.0589 | 42.5898 | 62.0300 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 10 | 1.8708 | 4.3869 | 19.4405 | 47.6690 | 72.7877 |
| weighted_field_mse | 64 | 4 | adam | 0.001 | 10 | 2.9402 | 5.2836 | 19.1526 | 54.4003 | 76.1335 |
| weighted_field_mse | 128 | 4 | adam | 0.001 | 10 | 3.2348 | 5.3204 | 18.8174 | 34.8522 | 42.7299 |
| weighted_field_mse | 128 | 3 | adam | 0.001 | 10 | 3.6281 | 6.5135 | 23.1226 | 41.3114 | 54.6950 |
| weighted_field_mse | 128 | 5 | adam | 0.001 | 10 | 2.8649 | 6.6146 | 24.9656 | 54.6706 | 78.9289 |
| weighted_field_mse | 64 | 5 | adam | 0.001 | 10 | 4.3087 | 6.6552 | 20.7276 | 46.6436 | 80.5369 |
| per_coefficient_mse | 128 | 4 | adam | 0.001 | 10 | 7.2245 | 11.7347 | 40.5065 | 81.9521 | 95.8000 |
| per_coefficient_mse | 128 | 3 | adam | 0.001 | 10 | 9.1197 | 14.0222 | 41.6281 | 102.0622 | 133.9959 |
| per_coefficient_mse | 128 | 5 | adam | 0.001 | 10 | 8.3790 | 14.2084 | 48.1473 | 178.1149 | 358.4985 |
| weighted_field_mse | 128 | 1 | adam | 0.001 | 10 | 7.0023 | 14.9848 | 50.9376 | 179.2187 | 271.7732 |
| weighted_field_mse | 64 | 1 | adam | 0.001 | 10 | 6.1065 | 15.0828 | 57.8211 | 211.5446 | 237.0554 |
| per_coefficient_mse | 64 | 4 | adam | 0.001 | 10 | 9.7356 | 15.4131 | 50.3649 | 125.3970 | 179.3040 |
| per_coefficient_mse | 64 | 3 | adam | 0.001 | 10 | 9.2479 | 16.1942 | 54.1680 | 169.8555 | 223.0272 |
| per_coefficient_mse | 64 | 5 | adam | 0.001 | 10 | 8.9782 | 17.2745 | 65.7709 | 202.5041 | 226.3025 |
| per_coefficient_mse | 128 | 2 | adam | 0.001 | 10 | 7.5396 | 17.4075 | 70.8861 | 207.8098 | 275.1100 |
| per_coefficient_mse | 64 | 2 | adam | 0.001 | 10 | 9.5766 | 18.6027 | 66.6964 | 206.7628 | 293.7166 |
| per_coefficient_mse | 128 | 1 | adam | 0.001 | 10 | 11.0011 | 31.9158 | 144.5228 | 505.2304 | 594.8326 |
| per_coefficient_mse | 64 | 1 | adam | 0.001 | 10 | 14.5602 | 42.0242 | 159.7818 | 686.6419 | 1046.3808 |

## learning_rate: 768 Trainingsfaelle, 128 Validierungsfaelle

| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median % | Mittelwert % | P95 % | Maximum % | Groesstes Maximum % |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| weighted_field_mse | 128 | 2 | adam | 0.001 | 10 | 1.9671 | 4.2966 | 16.0589 | 42.5898 | 62.0300 |
| weighted_field_mse | 128 | 2 | adam | 0.003 | 10 | 3.2132 | 6.7022 | 27.9260 | 55.0297 | 69.3717 |
| weighted_field_mse | 128 | 2 | adam | 0.0003 | 10 | 2.8613 | 7.1122 | 30.0804 | 99.2858 | 144.8423 |
| weighted_field_mse | 128 | 1 | adam | 0.01 | 10 | 5.1007 | 9.2512 | 29.5663 | 62.5500 | 70.6660 |
| weighted_field_mse | 128 | 1 | adam | 0.003 | 10 | 4.5349 | 10.5196 | 42.6244 | 129.1694 | 136.9560 |
| weighted_field_mse | 128 | 2 | adam | 0.01 | 10 | 5.7361 | 11.5032 | 36.8458 | 112.5455 | 166.7197 |
| weighted_field_mse | 128 | 1 | adam | 0.001 | 10 | 7.0023 | 14.9848 | 50.9376 | 179.2187 | 271.7732 |
| weighted_field_mse | 128 | 2 | adam | 0.0001 | 10 | 9.2591 | 23.0450 | 88.1657 | 395.2536 | 467.7766 |
| weighted_field_mse | 128 | 1 | adam | 0.0003 | 10 | 19.6164 | 52.7351 | 252.5943 | 718.5481 | 786.0071 |
| weighted_field_mse | 128 | 1 | adam | 0.0001 | 10 | 35.5207 | 133.7332 | 650.8178 | 2378.1529 | 2398.9373 |

## optimizer: 768 Trainingsfaelle, 128 Validierungsfaelle

| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median % | Mittelwert % | P95 % | Maximum % | Groesstes Maximum % |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| weighted_field_mse | 128 | 2 | adam | 0.001 | 10 | 1.9671 | 4.2966 | 16.0589 | 42.5898 | 62.0300 |
| weighted_field_mse | 128 | 1 | adam | 0.001 | 10 | 7.0023 | 14.9848 | 50.9376 | 179.2187 | 271.7732 |
| weighted_field_mse | 128 | 1 | rmsprop | 0.001 | 10 | 9.0601 | 18.3333 | 72.3162 | 169.1717 | 267.0747 |
| weighted_field_mse | 128 | 2 | rmsprop | 0.001 | 10 | 10.9009 | 21.0598 | 68.0910 | 176.1936 | 237.8851 |
| weighted_field_mse | 128 | 2 | sgdm | 0.001 | 10 | 13.9514 | 35.2741 | 147.8809 | 452.2425 | 505.1663 |
| weighted_field_mse | 128 | 1 | sgdm | 0.001 | 10 | 31.8968 | 120.0450 | 582.9000 | 2067.3182 | 2198.8743 |

## pod_rank: 768 Trainingsfaelle, 128 Validierungsfaelle

| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median % | Mittelwert % | P95 % | Maximum % | Groesstes Maximum % |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| weighted_field_mse | 64 | 2 | adam | 0.001 | 15 | 1.4211 | 2.9240 | 11.6783 | 28.2394 | 34.2209 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 2 | 1.7900 | 3.6689 | 14.6556 | 31.4954 | 44.4352 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 20 | 1.8340 | 3.8113 | 15.3292 | 35.4119 | 46.7030 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 8 | 1.7795 | 4.0933 | 16.8111 | 46.9509 | 48.9999 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 6 | 2.1887 | 4.1664 | 17.4709 | 37.6768 | 58.5863 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 10 | 1.8708 | 4.3869 | 19.4405 | 47.6690 | 72.7877 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 1 | 2.9352 | 7.1643 | 28.0501 | 97.3561 | 199.4699 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 4 | 2.3567 | 7.1715 | 29.6011 | 74.1981 | 141.3944 |

## width: 768 Trainingsfaelle, 128 Validierungsfaelle

| Loss | Breite | Schichten | Optimierer | Lernrate | POD-Rang | Median % | Mittelwert % | P95 % | Maximum % | Groesstes Maximum % |
|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|
| weighted_field_mse | 80 | 2 | adam | 0.001 | 10 | 1.8735 | 3.7112 | 15.2508 | 35.1418 | 54.7969 |
| weighted_field_mse | 32 | 2 | adam | 0.001 | 10 | 2.0488 | 3.9191 | 14.6847 | 35.4061 | 60.7238 |
| weighted_field_mse | 40 | 2 | adam | 0.001 | 10 | 1.6808 | 4.0443 | 17.7714 | 43.4786 | 66.9441 |
| weighted_field_mse | 128 | 2 | adam | 0.001 | 10 | 1.9671 | 4.2966 | 16.0589 | 42.5898 | 62.0300 |
| weighted_field_mse | 64 | 2 | adam | 0.001 | 10 | 1.8708 | 4.3869 | 19.4405 | 47.6690 | 72.7877 |
| weighted_field_mse | 20 | 2 | adam | 0.001 | 10 | 2.5584 | 4.6690 | 17.5295 | 46.5934 | 69.9306 |
| weighted_field_mse | 100 | 2 | adam | 0.001 | 10 | 2.1316 | 4.6837 | 18.4938 | 50.7923 | 67.8500 |
| weighted_field_mse | 16 | 2 | adam | 0.001 | 10 | 3.4246 | 6.1921 | 19.7419 | 70.8218 | 111.7821 |

## Umfang und Grenzen

936 Auswertelaeufe, 71088 Fallvorhersagen, 312 Konfiguration/Datensatz-Gruppen.

Die Architektur/Loss-Studie umfasst Breiten 64/128, Schichten 1 bis 5, Trainingsgroessen 12/24/48/96/192/384/768, zwei Losses und Seeds 42/43/44. Optimierer und Lernrate wurden bei Breite 128 und 1/2 Schichten untersucht; die Breitenstudie bei zwei Schichten, die Rangstudie bei Breite 64 und zwei Schichten. Es handelt sich nicht um ein vollstaendiges gemeinsames Hyperparametergitter.

PredictionSeconds ist eine einfache Diagnosemessung einschliesslich Wrapper und Rekonstruktion, kein auf Wiederholungen beruhender Laufzeitbenchmark.

Vollstaendige Ergebnisse: run_metrics.csv (je Seed), configuration_summary.csv (je Konfiguration), case_errors.csv (je Fall), model_plan.csv und reference_manifest.csv (Dateien und SHA-256). Originalergebnisse bleiben erhalten.

Die neu berechneten Fallfehler wurden gegen die archivierten Fallfehler geprueft:

- architecture_loss: 420 Laeufe, groesste absolute Differenz 4.55e-13.
- optimizer: 18 Laeufe, groesste absolute Differenz 4.62e-14.
- learning_rate: 30 Laeufe, groesste absolute Differenz 3.55e-14.
- width: 24 Laeufe, groesste absolute Differenz 2e-15.
- pod_rank: 24 Laeufe, groesste absolute Differenz 4.88e-15.
