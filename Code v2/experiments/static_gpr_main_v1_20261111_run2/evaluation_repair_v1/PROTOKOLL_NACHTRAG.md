# Technische Korrektur der Testauswertung nach dem Freeze

Der ursprüngliche Freeze wurde vor dem ersten Testlabelzugriff erstellt und
geprüft. Die erste Testauswertung verarbeitete ein eingefrorenes Modell auf
beiden Testsplits und brach danach ab: Die Variable `F` für den Manifestinhalt
wurde durch die Last `Fz` überschrieben. Die begonnenen Ausgabedateien unter
`evaluation/` bleiben unverändert erhalten; ihre Fehlerwerte wurden nicht zur
Modellwahl oder Anpassung verwendet.

Die hier separat gespeicherte Korrektur entstand nach dem ursprünglichen Freeze.
Sie benennt die Lastvariable um und schreibt die vollständige erneute Auswertung
nach `evaluation_repaired/`. Die Berichtskopie liest ausschließlich diese neue
Ablage. Modelle, Trainingsfälle, Modellkonfigurationen, Testreferenzen,
Auswahlregel und Kennzahlen bleiben unverändert. Es werden keine Konfigurationen
oder Seeds anhand der Testwerte nachträglich gewählt.

Die Diffs zeigen alle Änderungen gegenüber dem eingefrorenen Auswertecode.
Ein synthetischer Regressionstest mit zwei eingefrorenen Modellen prüft den
Übergang zum zweiten Modell, die Sperre für nicht eingefrorene Modelle, beide
Testsplits und die Berichtserzeugung. Der Test bestand. Das Reparaturmanifest
bindet die Korrekturdateien, den Test und den ursprünglichen Freeze per SHA-256.
Der Runner prüft beide Manifeste vor und nach der erneuten Auswertung. Diese
separate Nachtragsprovenienz ist keine Behauptung, die reparierte Datei sei vor
dem ersten Testlabelzugriff Bestandteil des ursprünglichen Freeze gewesen.
