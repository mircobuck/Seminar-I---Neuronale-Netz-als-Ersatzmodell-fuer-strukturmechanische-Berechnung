$ErrorActionPreference = 'Stop'
$control = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlabExe = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$scriptPath = Join-Path $control 'run_both.m'
$matlabArg = "run('" + $scriptPath.Replace("'", "''") + "')"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class StudyPowerGuard {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint SetThreadExecutionState(uint flags);
}
"@
$flags = [uint32]2147483649
$previous = [StudyPowerGuard]::SetThreadExecutionState($flags)
if ($previous -eq 0) { throw 'Could not prevent idle sleep for the study process.' }
try {
    $process = Start-Process -FilePath $matlabExe -ArgumentList @('-batch', ('"' + $matlabArg + '"')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $control 'matlab.stdout.log') -RedirectStandardError (Join-Path $control 'matlab.stderr.log') -PassThru
    Set-Content -LiteralPath (Join-Path $control 'matlab.pid') -Value $process.Id
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 20
        $process.Refresh()
    }
    Set-Content -LiteralPath (Join-Path $control 'exit_code.txt') -Value $process.ExitCode
} catch {
    $_ | Out-String | Set-Content -LiteralPath (Join-Path $control 'launcher_failure.txt')
    throw
} finally {
    [void][StudyPowerGuard]::SetThreadExecutionState([uint32]2147483648)
}

