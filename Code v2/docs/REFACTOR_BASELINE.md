# Ausgangsstand vor der Umstrukturierung

Branch: github_dd_branch_new; Ausgangscommit c3809d4. Keine veraenderten versionierten Dateien. Keine AGENTS.md im Repository oder direkten Arbeitsordner gefunden. Der vom Nutzer gelieferte Thesis-Wegweiser gilt nicht fuer dieses FEM-Projekt.

Die zuvor unversionierte Ausarbeitung Masterseminar_Statischer_Vergleich bleibt inhaltlich unveraendert. Ihre Textquellen und kleinen CSV-Tabellen werden im Sicherungscommit aufgenommen; PDFs, Renderbilder und Buildprodukte bleiben an Ort und Stelle. REFACTOR_BASELINE.json erfasst alle zuvor unversionierten Dateien mit SHA-256 und Groesse, sowie ignorierte Code-v2-Dateien. Ignoriert sind dort Logs und Python-Bytecode, keine benoetigten MATLAB-Quellen. Andere ignorierte Dateien enthalten insbesondere die lokale Vortrags-Pythonumgebung. Bestehende Daten, Modelle und Studienartefakte sind bereits weitgehend versioniert und werden nicht erneut kopiert.

## Bestandsaufnahme und Entscheidung

- +surrogate: aktive gemeinsame Schnittstelle und vier Modelle; numerische Implementierungen erhalten.
- fem_core und loadFemDataset: aktive Physik bzw. Datenadapter; Formate erhalten.
- studies/static_gpr_v1: historischer kompletter Vergleich mit hart codierten Pfaden/Budget; Basis fuer den neuen, getrennten Ablauf unter workflows/static_comparison.
- evaluation_repair_v1: gepruefte Umbenennung von Last F zu forceZ; in aktive Auswertung uebernehmen, alte Artefakte unveraendert lassen.
- scripts/matlab/run_data_generation_v2: historischer gemischter statischer/modaler Datenrunner; statische neue Erzeugung verwendet denselben solve_case-Kern.
- main: bisher ohne Argument umfangreiche statische und modale FEM. Neuer sicherer Hinweis statt automatischem Start; alter Ablauf explizit erreichbar.
- examples: historische Studienbeispiele an Ort und Stelle erhalten, eindeutig kennzeichnen; zwei kurze aktive Beispiele ergaenzen.
- Netzarchitekturen: Wrapper fuer historische Beispiele. Testverfahren: separate Optimierer mit teils Validierungssteuerung; nicht mit den Adaptern gleichsetzen, nicht loeschen und nicht aktiv auf den Pfad nehmen.
- Tests: bestehende Vertrags-/Modell-/POD-/Auswertepruefungen erhalten; neue Regression fuer den aktiven Workflow.

MATLAB R2025b ist installiert. Daher keine R2026b-matlab.toml einfuehren; setupProject verwaltet einen expliziten, temporaeren Pfad.
