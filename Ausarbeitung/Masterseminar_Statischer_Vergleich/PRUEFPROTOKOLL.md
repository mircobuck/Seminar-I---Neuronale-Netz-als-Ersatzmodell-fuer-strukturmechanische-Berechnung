# Build- und Prüfprotokoll

Stand: 12. November 2026. Der Bericht wurde mit MiKTeX/pdfLaTeX und BibTeX erstellt. Die im README angegebene direkte Buildfolge wurde ausgeführt; die PDF hat 18 Seiten. Der letzte LaTeX-Lauf meldete keine undefinierten Referenzen, mehrfach definierten Ziele, fehlenden Zeichen oder überlaufenden horizontalen Boxen. Unkritische Underfull-Meldungen verbleiben.

Alle PDF-Seiten wurden mit `pdftoppm` gerendert und als Kontaktübersicht geprüft; Titelblatt, Inhaltsverzeichnis, Diagramm-/Tabellenseiten und Literaturverzeichnis wurden zusätzlich vergrößert betrachtet. Eine missverständliche Beschriftung im Ablaufdiagramm wurde korrigiert und das Dokument erneut gebaut und gerendert.

`python skripte/pruefen.py` prüfte die gerundeten Vollpoolfehler gegen die kopierte Zusammenfassung, die Fit-Zeit des GPR-Hauptmodells, Rangwerte, Benchmark- und Break-even-Zahlen sowie die Vorzeichen des auffälligen Extrapolationsfalls. Die GPR-Zeitwiederholungen und ihre Vergleichbarkeit sind zusätzlich in der wissenschaftlichen Ergänzung dokumentiert. Die sieben Vektorabbildungen wurden aus den kopierten Tabellen erzeugt und sind im Projekt enthalten.

## Vor Abgabe zu ergänzen oder zu klären

- Name der Verfasserin oder des Verfassers.
- Matrikelnummer.
- Studiengang.
- Tatsächlich zugewiesene Betreuung.
- Abgabedatum.
- Falls die Lehrveranstaltung weitere konkrete Format-, Umfangs- oder Zitierregeln vorgibt, diese gegen das Dokument prüfen. Eine eindeutig einschlägige öffentlich zugängliche THU-LaTeX-Vorlage wurde nicht verifiziert; siehe `THU_RECHERCHE.md`.

Diese fünf persönlichen Angaben stehen als sichtbare Platzhalter in `metadaten.tex`. Die Ansprechpartner in der Aufgabenbeschreibung wurden nicht als tatsächliche Betreuung ausgegeben. `latexmk` ist installiert, konnte aber mangels Perl-Skriptengine nicht ausgeführt werden; die direkte Buildfolge mit pdfLaTeX und BibTeX war erfolgreich.
