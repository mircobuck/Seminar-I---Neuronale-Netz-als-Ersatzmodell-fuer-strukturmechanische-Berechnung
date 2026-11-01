# Arbeitsstand: Samplingvergleich bei 48 Trainingsfaellen

Stand: 29.10.2026. Studie abgeschlossen, Entwicklungsvalidierung.

Alle sechs Designs wurden vor den FEM-Berechnungen gespeichert und gegen
bekannte IDs und Parameterkombinationen geprueft. Alle 288 Trainingsreferenzen,
18 MLP-Fits und sechs GPR-Fits liegen vor. Keine FEM- oder Modell-Exceptions;
neun MLP-Fits endeten mit nicht gefundener Schrittweite. Pilot, anschliessender
Rekonstruktionsaudit, unabhaengige P95-Nachrechnung, wiederholter Aufruf und
`run_checks(false)` bestanden. Ein erneuter Kampagnenaufruf hat bestehende
Artefakte erhalten. `FINAL_REPORT_v2.md` enthaelt Ergebnisse und Reproduktion.
Die erste Berichtsrevision und deren Pruefsummen bleiben erhalten; Version 2
beruecksichtigt die nachtraeglich angelegte Arbeitsstanddatei bei der
Pruefsummenliste und ist erneut aufrufbar, ohne sie zu ueberschreiben.

Die P95-Zielerfuellung haengt sichtbar von Design und Seed ab: neun von 18
MLP-Laeufen, eines von sechs Designs fuer alle Seeds, vier von sechs GPR-Fits.
Die Stichprobe ist zu klein fuer allgemeine Ueberlegenheitsaussagen. Die
unabhaengige Abschlussvalidierung bleibt einem spaeteren Auftrag vorbehalten.
