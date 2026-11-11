param([Parameter(Mandatory=$true)][string]$OutputDir)
$ErrorActionPreference = 'Stop'
$runs = Import-Csv -LiteralPath (Join-Path $OutputDir 'run_metrics.csv')
$cases = Import-Csv -LiteralPath (Join-Path $OutputDir 'case_errors.csv')
$summary = Import-Csv -LiteralPath (Join-Path $OutputDir 'configuration_summary.csv')
$runLookup = @{}
foreach ($run in $runs) { $runLookup[$run.RunId] = $run }
$verifiedRuns = 0
$verifiedCases = 0
foreach ($group in ($cases | Group-Object RunId)) {
    $run = $runLookup[$group.Name]
    if ($null -eq $run) { throw "Missing run $($group.Name)" }
    $relativeValues = [Collections.Generic.List[double]]::new()
    foreach ($case in $group.Group) {
        $referenceNorm = [double]$case.ReferenceNormM
        $errorValue = [double]$case.RelativeError
        if ($referenceNorm -gt 0) {
            $expected = [double]$case.AbsoluteErrorM / $referenceNorm
            if ([math]::Abs($expected-$errorValue) -gt 1e-10*[math]::Max(1,[math]::Abs($expected))) {
                throw "Case normalization mismatch: run $($run.RunId), case $($case.CaseId)"
            }
            $relativeValues.Add($errorValue)
        } elseif (-not [double]::IsNaN($errorValue)) {
            throw "Zero reference not marked NaN: $($case.CaseId)"
        }
        $verifiedCases++
    }
    [double[]]$values = $relativeValues.ToArray()
    [Array]::Sort($values)
    $count = $values.Length
    if ($count -ne [int]$run.DefinedCount -or $group.Count-$count -ne [int]$run.UndefinedCount) {
        throw "Defined/undefined counts differ: run $($run.RunId)"
    }
    if ($count -gt 0) {
        $median = $values[[int][math]::Floor($count/2)]
        if ($count%2 -eq 0) { $median = ($values[$count/2-1]+$values[$count/2])/2 }
        $expectedStats = @{
            MedianPercent = 100*$median
            MeanPercent = 100*(($values | Measure-Object -Average).Average)
            P95Percent = 100*$values[[int][math]::Ceiling(0.95*$count)-1]
            MaximumPercent = 100*$values[-1]
        }
        foreach ($field in $expectedStats.Keys) {
            $expected = $expectedStats[$field]
            if ([math]::Abs($expected-[double]$run.$field) -gt 1e-9*[math]::Max(1,[math]::Abs($expected))) {
                throw "Statistic mismatch: run $($run.RunId), $field"
            }
        }
    }
    $verifiedRuns++
}
if ($verifiedRuns -ne $runs.Count) { throw 'Some run rows have no case errors.' }
$keys = @('Study','Dataset','LossMode','Width','HiddenLayers','TrainingCases','Optimizer','LearningRate','Rank')
$summaryLookup = @{}
foreach ($row in $summary) {
    $key = ($keys | ForEach-Object { $row.$_ }) -join '|'
    $summaryLookup[$key] = $row
}
$verifiedConfigurations = 0
foreach ($group in ($runs | Group-Object -Property $keys)) {
    $first = $group.Group[0]
    $key = ($keys | ForEach-Object { $first.$_ }) -join '|'
    $row = $summaryLookup[$key]
    if ($null -eq $row -or $group.Count -ne 3 -or [int]$row.SeedCount -ne 3) {
        throw "Missing three-seed configuration: $key"
    }
    foreach ($field in @('MedianPercent','MeanPercent','P95Percent','MaximumPercent')) {
        $expected = ($group.Group | ForEach-Object { [double]$_.$field } | Measure-Object -Average).Average
        if ([math]::Abs($expected-[double]$row.$field) -gt 1e-9*[math]::Max(1,[math]::Abs($expected))) {
            throw "Seed aggregation mismatch: $key, $field"
        }
    }
    $expectedMaximum = ($group.Group | ForEach-Object { [double]$_.MaximumPercent } | Measure-Object -Maximum).Maximum
    if ([math]::Abs($expectedMaximum-[double]$row.WorstObservedMaximumPercent) -gt 1e-9) {
        throw "Worst maximum mismatch: $key"
    }
    $verifiedConfigurations++
}
if ($verifiedConfigurations -ne $summary.Count) { throw 'Some summary rows have no runs.' }
$message = "PASS: independently verified $verifiedCases case normalizations, all four statistics for $verifiedRuns runs, and seed aggregation for $verifiedConfigurations configurations."
Set-Content -LiteralPath (Join-Path $OutputDir 'INDEPENDENT_CSV_VERIFICATION.txt') -Encoding utf8 -Value $message
Write-Output $message
