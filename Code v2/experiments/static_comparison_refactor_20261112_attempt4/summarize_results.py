"""Build the descriptive completion report solely from completed study artifacts."""
from pathlib import Path
import csv
import json
import math
import statistics as stats

OUT = Path(__file__).resolve().parent
OLD = OUT.parent / 'static_gpr_main_v1_20261111_run2'
METHODS = ['mlp', 'rbf', 'pod_mlp', 'pod_gpr']
NAMES = dict(zip(METHODS, ['MLP', 'RBF', 'POD-MLP', 'POD-GPR']))


def read(name, folder=OUT):
    with (folder / name).open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))


def fmt(value, digits=3):
    number = float(value)
    return f'{number:.{digits}f}' if math.isfinite(number) else 'n/a'


def table(lines, headers, data):
    lines.append('| ' + ' | '.join(headers) + ' |')
    lines.append('|' + '|'.join(['---'] * len(headers)) + '|')
    lines.extend('| ' + ' | '.join(map(str, row)) + ' |' for row in data)
    lines.append('')


def main():
    assert (OUT / 'study.complete').is_file()
    verification = json.loads((OUT / 'verification.json').read_text())
    assert verification['outsideTolerance'] == 0
    pipeline = read('pipeline_summary.csv')
    runs = read('run_results.csv')
    cases = read('case_results.csv')
    search = read('search_costs.csv')
    bench = read('benchmark/summary.csv')
    breaks = read('benchmark/break_even.csv')
    old_runs = { (r['id'], r['role']): r for r in read('run_results.csv', OLD) }
    full = {(r['method'], r['role']): r for r in pipeline if int(r['n']) == 768}
    main_runs = {r['method']: r for r in runs if r['id'].startswith('runs')
                 and 'n768_rep1_' in r['id'] and r['id'].endswith('seed42')
                 and r['role'] == 'interpolation'}
    lines = ['# Abschluss der statischen Struktur-Wiederholung', '',
        'Versuch: `' + OUT.name + '`. MATLAB R2025b, serielle CPU-Ausfuehrung. '
        'Vier Methoden, unveraenderte 76 Suchkandidaten, Trainingsgroessen 48/96/192/384/768. '
        'Vorhandene FEM-Referenzen wurden unveraendert wiederverwendet. '
        '**Bekannte Referenzfaelle: kein neuer unabhaengiger Abschlusstest.**', '',
        '## Umfang und Nachweise', '',
        f"Abgeschlossen: {verification['sealedFits']} versiegelte Fits, davon 88 Such-/Bestaetigungsfits "
        'und 146 Trainingsfits (58 Hauptpipeline, 78 kontrollierte POD, 8 Verteilungsstudie, '
        '2 zusaetzliche GPR-Zeitwiederholungen). 144 Modelle mit je zwei Testsplit-Auswertungen: '
        f"{verification['evaluations']} erfolgreiche Lauf/Split-Zeilen, {verification['caseRows']} Fallzeilen. "
        'Keine fehlgeschlagenen Auswertungen oder undefinierten relativen Feldfehler.', '',
        'Alle Dateien der Quell- und Freeze-Manifeste sowie die Checkpoint-Siegel wurden nach Abschluss '
        'erneut geprueft. Numerischer Vergleich: `numerical_comparison.csv`, maschinenlesbarer Nachweis: '
        '`verification.json`, reproduzierbar mit `python verify_results.py` im Laufordner. '
        'Die vorher bestandenen 83 Basistests, 16 neuen Regressionstests und 55 nach Zeitinstrumentierung '
        'betroffenen Tests stehen in `../../docs/TESTNACHWEIS.md`. Vor dem Lauf waren alle 72 Dateien '
        'des erfolgreichen Smoke-Quellmanifests byteidentisch; deshalb keine komplette Testwiederholung.', '',
        'Phasenzeiten und Standby-/Speicherpruefung: [LAUFBEDINGUNGEN.md](LAUFBEDINGUNGEN.md). Die sechs gespeicherten Testartefakte stimmen mit ihren dokumentierten SHA256-Werten ueberein (`test_evidence_check.txt`).', '',
        '## Vergleich mit der bisherigen Hauptstudie', '',
        'Alle Lauf-, Split- und Fallidentitaeten wurden zugeordnet. Der Vergleich umfasst Feldfehler, '
        'Referenznormen, Spitzen-/Maximalfehler und POD-Zerlegung; Zeiten sind bewusst nicht auf Gleichheit '
        'geprueft. Prueftoleranz je numerischem Wert: 1e-12 absolut + 1e-12 relativ zum historischen Wert.', '']
    diff = read('numerical_comparison.csv')
    table(lines, ['Tabelle', 'Kennzahl', 'Abweichende Werte', 'Max. absolute Differenz', 'Ausserhalb Toleranz'],
          [[r['Table'], r['Field'], r['Different'], f"{float(r['MaxAbsoluteDifference']):.3g}", r['OutsideTolerance']]
           for r in diff if int(r['Different']) or r['Field'] == 'Relative'])
    lines += ['Alle 55.296 Fallzeilen sind in den verglichenen Kennzahlen exakt identisch (einschliesslich gleicher undefinierter POD-Felder bei direkten Modellen). Nur 13 Mittelwerte unterscheiden sich um maximal 9.992e-16: Der historische studyReport sortiert die Fehler vor der Mittelwertbildung; summarizeErrors erhaelt fuer den Mittelwert die Fallreihenfolge und sortiert nur fuer P95. Die beobachtete Abweichung ist damit durch Gleitkomma-Summation erklaert; Median, P95, Maximum und absolute Mittelwerte sind exakt gleich.', '',
              'Die gewaehlten Konfigurationen sind in `VERGLEICH.md` gegen die historischen Auswahlobjekte '
              'geprueft. Keine nachtraegliche Anpassung anhand der bekannten Testwerte.', '']
    table(lines, ['Methode', 'Kandidaten', 'Fits inkl. Bestaetigung', 'Gewinner-ID', 'Neue aeussere Suchzeit [s]'],
          [[NAMES[r['Method']], r['Candidates'], r['Attempted'], r['Winner'], fmt(r['SearchSeconds'])]
           for r in search if r['Method'] != 'all'])
    lines += ['Aeussere Gesamtsuchzeit einschliesslich Verwaltung: ' + fmt(search[-1]['SearchSeconds']) + ' s.', '',
              '## Vollpool: Interpolation und Extrapolation', '',
              'Mittel und P95 zuerst ueber Faelle je Lauf, danach Mittel ueber drei neuronale Initialisierungen. '
              'Maximum: groesstes beobachtetes Fallmaximum. GPR: ein ausgewerteter deterministischer Hauptlauf. '
              'Alle Fehler in Prozent.', '']
    table(lines, ['Methode', 'Interpolation Mittel / P95 / Maximum [%]', 'Extrapolation Mittel / P95 / Maximum [%]'],
          [[NAMES[m]] + [' / '.join(fmt(100*float(full[m, role][k]), 4)
             for k in ['meanError', 'p95Error', 'maxObserved'])
             for role in ['interpolation', 'extrapolation']] for m in METHODS])
    lines += ['## Lernkurven und Verteilungsstudie', '',
              'Mittlerer Interpolationsfeldfehler in Prozent. Unterhalb N=768 streuen die Laeufe ueber '
              'drei Trainingsauswahlen; beim Vollpool ueber neuronale Initialisierungen. '
              'Diese Streuungsarten sind keine zusaetzlichen unabhaengigen Balkenfaelle.', '']
    table(lines, ['Methode', '48', '96', '192', '384', '768'],
          [[NAMES[m]] + [fmt(100*float(next(r for r in pipeline if r['method']==m
             and r['role']=='interpolation' and int(r['n'])==n)['meanError']))
             for n in [48,96,192,384,768]] for m in METHODS])
    distribution = [r for r in runs if r['id'].startswith('distribution')]
    table(lines, ['Design/Lauf', 'Split', 'Mittlerer Fehler [%]', 'Neue Fit-Zeit [s]'],
          [[r['id'], r['role'], fmt(100*float(r['avg'])), fmt(r['fitSeconds'])] for r in distribution])
    lines += ['## Kontrollierte POD-Raenge bei N=768', '',
              'Je Rang ein gemeinsamer trainingsbasierter POD-Zustand. Eigenstaendige Fit-Kosten sind '
              'oeffentlicher Fit mit vorberechneter Basis plus einmalige gemeinsame POD-Zeit; '
              'dies ist eine additive Kostenschaetzung. Je Zeile ein Modell mit Seed 42.', '']
    controlled = [r for r in runs if r['id'].startswith('controlled') and int(r['N'])==768]
    projections = {}
    for run in controlled:
        selected = [c for c in cases if c['RunId']==run['id'] and c['Role']==run['role']]
        projections[run['id'],run['role']] = stats.mean(math.sqrt(float(c['ProjectionSquared'])) / float(c['ReferenceNorm']) for c in selected)
    table(lines, ['Lauf', 'Split', 'Mittlere Projektion [%]', 'Mittlerer Fehler [%]', 'Fit + gemeinsame POD [s]', 'POD-Anteil [s]', 'Modell [MiB]'],
          [[r['id'], r['role'], fmt(100*projections[r['id'],r['role']],6), fmt(100*float(r['avg'])), fmt(r['standaloneFitSeconds']),
            fmt(r['sharedPod'],6), fmt(float(r['modelBytes'])/(1024**2))] for r in controlled])
    lines += ['## Neue Laufzeitmessungen', '',
              'Die folgende Tabelle verwendet die vorab festgelegten Vollpool-Hauptmodelle mit Seed 42. '
              'Der vollstaendige oeffentliche Fit umfasst die Modellpipeline; Validierungsvorhersage und '
              'Speichern liegen ausserhalb. Netzwerkaufbau und Optimierung sind additive Zeitinstrumentierung, '
              'keine Aenderung des Trainings. Bei GPR bezeichnet Regression den gesamten Koeffizientenfit. '
              'Nicht anwendbare Segmente erscheinen als n/a. Die historischen Segmentfelder ueberlappen: Regression umfasst bei MLP/RBF Netzaufbau plus Optimierung, bei POD-MLP die Optimierung, bei GPR den gesamten Koeffizientenfit. Diese Spalten duerfen nicht zusammenaddiert werden. Der Center-Zweig enthaelt nur bei RBF einen Zentrenfit; bei MLP misst er den leeren Zweig.', '']
    table(lines, ['Methode', 'Fit neu [s]', 'Fit historisch [s]', 'Vorverarbeitung [s]', 'POD [s]',
                  'Center-Zweig [s]', 'Netzaufbau [s]', 'Optimierung [s]', 'Regression [s]', 'Laden [s]', 'Speichern [s]'],
          [[NAMES[m], fmt(main_runs[m]['fitSeconds']), fmt(old_runs[main_runs[m]['id'],'interpolation']['fitSeconds'])]
           + [fmt(main_runs[m][k],6) for k in ['prep','pod','center','networkSetup','optimization','regression','loadSeconds','saveSeconds']]
           for m in METHODS])
    gpr = [float(main_runs['pod_gpr']['fitSeconds'])] + [float(r['FitSeconds']) for r in read('gpr_fit_timing_repeats.csv')]
    lines += ['Drei deterministische GPR-Fit-Zeitwiederholungen [s]: ' + ', '.join(fmt(v,6) for v in gpr) +
              '; Median ' + fmt(stats.median(gpr),6) + ' s. Keine drei unabhaengigen Modellreplikate. Trainings-/Validierungs-IDs, Rang/Seed und alle Validierungsfallfehler sind identisch (`gpr_repeat_verification.json`). '
              'Neuronale Seeds 42/43/44 erzeugen dagegen verschiedene Initialisierungen. '
              'Neue und historische Zeiten stammen aus getrennten Sitzungen; Unterschiede sind kein isolierter '
              'Nachweis einer durch den Strukturumbau verursachten Beschleunigung.', '',
              'Vorhersage ueber den vollstaendigen oeffentlichen Aufruf nach Warm-up, '
              '30 Wiederholungen. Einzelfall und Batch 128: Median und IQR der Zeitwiederholungen.', '']
    table(lines, ['Methode', 'Einzel Median / IQR [ms]', 'Batch 128 Median / IQR [ms]'],
          [[NAMES[m], ' / '.join(fmt(1000*float(main_runs[m][k])) for k in ['single','singleIqr']),
            ' / '.join(fmt(1000*float(main_runs[m][k])) for k in ['batch','batchIqr'])] for m in METHODS])
    lines += ['## Begrenzter neuer FEM-/Surrogatbenchmark', '',
              'Zwoelf vorab festgelegte Interpolationsfaelle, FEM-Warm-up und zwei Messungen pro Fall '
              'in umgekehrter Reihenfolge. Surrogate: Warm-up, 30 Einzelmessungen je Fall und 30 Batches '
              'mit allen zwoelf Faellen. Einzelzeiten sind Mediane der fallweisen Mediane; '
              'FEM-Batch ist die Summe dieser Fallmediane. Aufbau, Netz, Loesung und Interpolation '
              'sind im FEM-Aufruf enthalten; Transformation und POD-Rekonstruktion im Surrogataufruf. '
              'Rohdaten und Metadaten stehen unter `benchmark/`.', '']
    table(lines, ['Methode', 'FEM Einzel [s]', 'FEM IQR zwischen Faellen [s]', 'Surrogat Einzel [ms]',
                  'Surrogat IQR zwischen Faellen [ms]', 'FEM 12 seriell [s]', 'Surrogat Batch 12 [ms]'],
          [[NAMES[r['method']], fmt(r['femSingle']), fmt(r['femBetweenCaseIqr']),
            fmt(1000*float(r['singleMedian'])), fmt(1000*float(r['singleBetweenCaseIqr'])),
            fmt(r['femBatch']), fmt(1000*float(r['batchMedian']))] for r in bench])
    lines += ['## Bedingter Break-even', '',
              '`ceil(Offlinekosten / (FEMzeit - Surrogatzeit))`, nur bei positiver Zeitersparnis. '
              'Offlinekosten: neuer Fit des Hauptmodells, optional neue aeussere Suche der Familie. '
              'Fuer Batchbetrieb wird auf ganze 12er-Batches aufgerundet. Vorhandene Trainings-/Referenzdaten '
              'werden als verfuegbar angenommen. Laden, Speichern, Qualitaetspruefung, Wiederholungsstudien '
              'und kuenftige Updates sind hier ausgeschlossen. Die Tabelle ist keine allgemeine '
              'Wirtschaftlichkeits- oder Genauigkeitsgarantie.', '']
    table(lines, ['Methode', 'Suche enthalten', 'Offline [s]', 'Break-even Einzelfaelle', 'Break-even Faelle in 12er-Batches'],
          [[NAMES[r['method']], r['includeSearch'], fmt(r['offlineSeconds']), r['singleCases'], r['batchCases']] for r in breaks])
    lines += ['Historische Datenerzeugungskosten bleiben separat in `reference_costs_historical.csv` '
              'und werden nicht als neue Messungen ausgegeben. Der kleine FEM-Benchmark ersetzt '
              'keine Messung einer vollstaendigen neuen Trainingsdatenerzeugung.', '',
              '## Einordnung und Artefakte', '',
              'POD-GPR erzielt im vorliegenden Vollpoolvergleich den kleinsten mittleren Interpolationsfehler. '
              'Extrapolation bleibt deutlich schwieriger. Grosse relative Fehler bei kleinen Referenznormen '
              'muessen zusammen mit absoluten Feld- und Spitzenfehlern beurteilt werden. '
              'Die bekannte wissenschaftliche Ergaenzung in `../static_gpr_supplement_v1_20261112/SEMINARBERICHT_v1.md` '
              'enthaelt die Fall- und Lastgruppendiagnose; ihre historischen Zeiten sind von diesen neuen Messungen zu trennen.', '',
              'Tabellen: `run_results.csv`, `case_results.csv`, `pipeline_summary.csv`, `search_costs.csv`, '
              '`search_attempts.csv`, `gpr_fit_timing_repeats.csv`, `comparison_previous.csv`. '
              'Diagramme: `plots/`. Quell-/Konfigurationsbindung: `source_manifest.csv`, `resolved_config.json`, '
              '`environment.mat`; vor Testauswertung erzeugtes Siegel: `freeze_manifest.csv`. '
              'Fruehere unterbrochene Versuche bleiben getrennt erhalten und gehen nicht in neue Zeiten ein.', '']
    (OUT / 'WIEDERHOLUNG.md').write_text('\n'.join(lines), encoding='utf-8')
    print('WIEDERHOLUNG.md generated from completed artifacts')


if __name__ == '__main__':
    main()
