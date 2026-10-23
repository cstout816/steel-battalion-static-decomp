param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,

    [Parameter(Mandatory = $true)]
    [string]$OutputCsv,

    [string]$GuestStderrLog,

    [ValidateRange(1, 60)]
    [int]$IntervalSeconds = 2,

    [ValidateRange(1, 86400)]
    [int]$DurationSeconds = 300
)

$ErrorActionPreference = 'Stop'
$logicalProcessors = [Environment]::ProcessorCount
$resolvedOutput = [IO.Path]::GetFullPath($OutputCsv)
$outputDirectory = [IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [IO.Directory]::Exists($outputDirectory)) {
    [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
}

$counterPath = '\GPU Engine(*)\Utilization Percentage'
$previousCpuSeconds = $null
$previousAt = $null
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$rows = [Collections.Generic.List[object]]::new()

while ($stopwatch.Elapsed.TotalSeconds -lt $DurationSeconds) {
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $process) {
        break
    }

    $sampleAt = [DateTimeOffset]::Now
    $cpuSeconds = [double]$process.CPU
    $cpuOneCorePct = $null
    $cpuMachinePct = $null
    if ($null -ne $previousCpuSeconds) {
        $elapsed = ($sampleAt - $previousAt).TotalSeconds
        if ($elapsed -gt 0) {
            $cpuOneCorePct = 100.0 * ($cpuSeconds - $previousCpuSeconds) / $elapsed
            $cpuMachinePct = $cpuOneCorePct / $logicalProcessors
        }
    }
    $previousCpuSeconds = $cpuSeconds
    $previousAt = $sampleAt

    $gpu3dPct = $null
    $gpuCopyPct = $null
    try {
        $counter = Get-Counter -Counter $counterPath -ErrorAction Stop
        $processSamples = @($counter.CounterSamples | Where-Object {
            $_.Path -match "(?i)pid_$ProcessId(?:_|\\)"
        })
        $gpu3d = @($processSamples | Where-Object { $_.InstanceName -match '(?i)engtype_3D' })
        $gpuCopy = @($processSamples | Where-Object { $_.InstanceName -match '(?i)engtype_Copy' })
        if ($gpu3d.Count -gt 0) {
            $gpu3dPct = [Math]::Round(($gpu3d | Measure-Object -Property CookedValue -Sum).Sum, 2)
        }
        if ($gpuCopy.Count -gt 0) {
            $gpuCopyPct = [Math]::Round(($gpuCopy | Measure-Object -Property CookedValue -Sum).Sum, 2)
        }
    } catch {
        # CPU and memory samples remain useful when GPU Engine counters are unavailable.
    }

    $guestFps = $null
    $guestFlips = $null
    if ($GuestStderrLog -and [IO.File]::Exists($GuestStderrLog)) {
        try {
            Get-Content -LiteralPath $GuestStderrLog -Tail 120 | ForEach-Object {
                if ($_ -match '^\[GPU\]\s+([0-9]+(?:\.[0-9]+)?)\s+fps\s+\(([0-9]+)\s+flips\)') {
                    $guestFps = [double]$Matches[1]
                    $guestFlips = [long]$Matches[2]
                }
            }
        } catch {
            # Keep host usage samples if the runtime log is temporarily unavailable.
        }
    }

    $rows.Add([pscustomobject]@{
        Timestamp = $sampleAt.ToString('o')
        ProcessId = $ProcessId
        ProcessCpuSeconds = [Math]::Round($cpuSeconds, 3)
        CpuPercentOfOneLogicalProcessor = if ($null -eq $cpuOneCorePct) { $null } else { [Math]::Round($cpuOneCorePct, 2) }
        CpuPercentOfMachine = if ($null -eq $cpuMachinePct) { $null } else { [Math]::Round($cpuMachinePct, 2) }
        Gpu3DPercent = $gpu3dPct
        GpuCopyPercent = $gpuCopyPct
        LatestGuestFpsSample = $guestFps
        LatestGuestFlipCount = $guestFlips
        WorkingSetMiB = [Math]::Round($process.WorkingSet64 / 1MB, 1)
    })

    Start-Sleep -Seconds $IntervalSeconds
}

$rows | Export-Csv -LiteralPath $resolvedOutput -NoTypeInformation -Encoding utf8
Write-Output "Saved $($rows.Count) samples to $resolvedOutput"
