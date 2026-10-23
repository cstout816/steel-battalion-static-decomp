param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,

    [Parameter(Mandatory = $true)]
    [string]$OutputCsv,

    [string]$GuestStderrLog,

    [ValidateRange(1, 60)]
    [int]$IntervalSeconds = 5,

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
$gpuCounterPaths = @()
$nextGpuDiscovery = [DateTimeOffset]::MinValue
$previousCpuSeconds = $null
$previousAt = $null
$guestLogOffset = 0L
$guestLogRemainder = ''
$latestGuestFps = $null
$latestGuestFlips = $null
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
    $counterSamples = @()
    try {
        $now = [DateTimeOffset]::Now
        if ($now -ge $nextGpuDiscovery) {
            # Enumerate all engines only at startup and occasionally thereafter.
            # Reuse exact per-process counter paths between discovery passes.
            $counter = Get-Counter -Counter $counterPath -ErrorAction Stop
            $counterSamples = @($counter.CounterSamples | Where-Object {
                $_.Path -match "(?i)pid_$ProcessId(?:_|\\)"
            })
            $gpuCounterPaths = @($counterSamples | Where-Object {
                $_.InstanceName -match '(?i)engtype_(3D|Copy)'
            } | Select-Object -ExpandProperty Path -Unique)
            $nextGpuDiscovery = $now.AddSeconds(30)
        } elseif ($gpuCounterPaths.Count -gt 0) {
            $counter = Get-Counter -Counter $gpuCounterPaths -ErrorAction Stop
            $counterSamples = @($counter.CounterSamples)
        }
        $gpu3d = @($counterSamples | Where-Object { $_.InstanceName -match '(?i)engtype_3D' })
        $gpuCopy = @($counterSamples | Where-Object { $_.InstanceName -match '(?i)engtype_Copy' })
        if ($gpu3d.Count -gt 0) {
            $gpu3dPct = [Math]::Round(($gpu3d | Measure-Object -Property CookedValue -Sum).Sum, 2)
        }
        if ($gpuCopy.Count -gt 0) {
            $gpuCopyPct = [Math]::Round(($gpuCopy | Measure-Object -Property CookedValue -Sum).Sum, 2)
        }
    } catch {
        # CPU and memory samples remain useful when GPU Engine counters are unavailable.
        $gpuCounterPaths = @()
        $nextGpuDiscovery = [DateTimeOffset]::Now.AddSeconds(30)
    }

    $guestFps = $latestGuestFps
    $guestFlips = $latestGuestFlips
    if ($GuestStderrLog -and [IO.File]::Exists($GuestStderrLog)) {
        $logStream = $null
        $logReader = $null
        try {
            $logStream = [IO.File]::Open(
                $GuestStderrLog,
                [IO.FileMode]::Open,
                [IO.FileAccess]::Read,
                [IO.FileShare]::ReadWrite
            )
            if ($logStream.Length -lt $guestLogOffset) {
                $guestLogOffset = 0L
                $guestLogRemainder = ''
            }
            [void]$logStream.Seek($guestLogOffset, [IO.SeekOrigin]::Begin)
            $logReader = [IO.StreamReader]::new(
                $logStream,
                [Text.Encoding]::UTF8,
                $true,
                4096,
                $true
            )
            $logChunk = $guestLogRemainder + $logReader.ReadToEnd()
            $guestLogOffset = $logStream.Position
            $lines = [regex]::Split($logChunk, "`r?`n")
            $completeLineCount = $lines.Count
            if (-not $logChunk.EndsWith("`n")) {
                $completeLineCount--
                $guestLogRemainder = $lines[$lines.Count - 1]
            } else {
                $guestLogRemainder = ''
            }
            for ($lineIndex = 0; $lineIndex -lt $completeLineCount; $lineIndex++) {
                if ($lines[$lineIndex] -match '^\[GPU\]\s+([0-9]+(?:\.[0-9]+)?)\s+fps\s+\(([0-9]+)\s+flips\)') {
                    $latestGuestFps = [double]$Matches[1]
                    $latestGuestFlips = [long]$Matches[2]
                }
            }
            $guestFps = $latestGuestFps
            $guestFlips = $latestGuestFlips
        } catch {
            # Keep host usage samples if the runtime log is temporarily unavailable.
        } finally {
            if ($logReader) { $logReader.Dispose() }
            if ($logStream) { $logStream.Dispose() }
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
