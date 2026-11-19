# Abschlussprüfung und Abweichungen vom ursprünglichen Plan

Stand: 2026-11-11 nach Abschluss der separaten technischen Auswertekorrektur.

Der statische Vergleich der vier Familien wurde auf 128 Validierungs-, 256 Interpolations- und 128 Extrapolationsfällen durchgeführt. Die Testauswertung umfasst 288 erfolgreiche Lauf/Split-Kombinationen und 55.296 Fallzeilen; keine fehlgeschlagene Auswertung und kein undefinierter relativer Fehler wurden im Bericht gezählt. Eine Beurteilung der Genauigkeit und Kosten steht in supplementary_analysis/ANALYSE.md. Die ursprünglichen und die korrigierten Auswertungen und ihre Provenienz bleiben getrennt.

## Abweichungen und fehlende Messungen

- Der vor der Hauptstudie verbindlich festgelegte MLP-Suchraum verwendete Breiten 64/128 und Lernraten 0,0005/0,001. Der ursprüngliche Plan sah Breiten 32/64/80/128 bei Lernrate 0,001 vor. Damit fehlen die ursprünglich vorgesehenen Breiten 32 und 80; die zusätzlichen Lernratenversuche ersetzen sie nicht. Die Auswahl ist auf den tatsächlich durchsuchten Raum beschränkt. Nach Testeinsicht wurden keine weiteren Modelle für diese Studie ausgewählt.
- Ein belastbarer Break-even mit und ohne Suchkosten wurde nicht ausgewiesen, da kein zeitgleich kontrollierter FEM-Vergleich mit den Surrogatmessungen vorliegt. FEM-Solverzeiten, aktive Datenerzeugungszeiten und Suchzeiten sind separat dokumentiert. Spitzen-RAM wurde nicht gemessen.
- Für POD–GPR im Vollpool gibt es eine eindeutige Trainingsmenge. Die zwei zusätzlichen deterministischen Fits sind Zeitmessungen, keine Schätzung der Modell- oder Datenauswahlstreuung. Bei einem Lauf ist die Streuung in der korrigierten Zusammenfassung undefiniert.
- Der ursprüngliche Auswerter brach nach dem ersten Modell und nach dem ersten Testlabelzugriff durch Überschreiben einer Manifestvariablen ab. Die separat gehashte Korrektur entstand nach diesem Zugriff. Das Nachtragsprotokoll evaluation_repair_v1/PROTOKOLL_NACHTRAG.md beschreibt Umfang, Regressionstest und Provenienz; Modelle und Auswahl wurden nicht geändert. Die zwölf gemeinsamen numerischen Ergebnisgrößen der beiden zuerst ausgewerteten Splits stimmen mit dem ersten Versuch überein.
- Das Netzpilot umfasst zwölf Extrapolationsfälle auf drei Netzstufen und ist keine Garantie für Netzkonvergenz im gesamten Parameterraum. Referenzfelder sind FEM-Lösungen des gewählten Netzes; analytische Balkenlösungen dienen nur der Plausibilisierung.

Der ausgeführte Vergleich ist damit dokumentiert; die ursprünglich vorgesehenen MLP-Konfigurationen 32 und 80 und der vergleichbare Break-even bleiben unvollständig. Diese Einschränkungen sind bei einer wissenschaftlichen Verwendung ausdrücklich zu berücksichtigen.
