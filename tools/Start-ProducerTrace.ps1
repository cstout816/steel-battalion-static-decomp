<#
.SYNOPSIS
Starts a separate current-source ProducerTrace run with screen-gated live input.

.DESCRIPTION
Refuses to start beside any your_game_recomp process, requires an existing save
directory, creates a fresh local log folder, and starts with an empty live-input
file. It does not copy save data or send input. Append input only after checking
the latest framebuffer and confirming the expected screen. Child output is
drained through a bounded asynchronous queue by default; any dropped lines are
reported after exit. Use -DirectTraceOutput only when direct file output is
specifically needed. -EnableFileFailurePathTrace adds a low-volume sampled path
record for failed NtCreateFile calls, useful when lifecycle traces reach their cap.

.EXAMPLE
./tools/Start-ProducerTrace.ps1 -RunName m3-producer-trace-screen-gated-20261024 -AsyncTraceRelay
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$RunName,

    [ValidateRange(1800, 43200)]
    [int]$WatchdogSeconds = 1800,

    [string]$GuestWatchAddress,

    [string]$GuestWatchAddress2,

    [switch]$EnableDcf4ProducerTrace,

    [switch]$EnableLoadStateCallbackTrace,

    [switch]$EnableSbCallbackTargetTrace,

    [switch]$EnableStreamTrace,

    [switch]$EnableFileLifecycleTrace,

    [switch]$EnableFileFailurePathTrace,

    [switch]$EnableFileCallerTrace,

    [switch]$EnableFileIoDetailTrace,

    [switch]$EnableFileCopyTrace,

    [switch]$EnableThreadStartTrace,

    [switch]$EnablePreloadWorkerTrace,

    [switch]$EnableDsoundWriteWatch,

    [switch]$EnableMmioTrace,

    [switch]$EnablePacketTimingTrace,

    [switch]$AsyncTraceRelay,

    [switch]$DirectTraceOutput,

    [ValidateRange(256, 1048576)]
    [int]$AsyncTraceQueueCapacity = 32768,

    [string]$ExecutablePath,

    [string]$SaveDirectory = (Join-Path $PSScriptRoot '..\iso\local-analysis\saves-m3-route-file-read-copy-20261023')
)

$ErrorActionPreference = 'Stop'

if ($AsyncTraceRelay -and $DirectTraceOutput) {
    throw 'Choose either the default asynchronous trace relay or -DirectTraceOutput, not both.'
}
$useAsyncTraceRelay = -not $DirectTraceOutput

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$defaultTraceExe = Join-Path $projectRoot 'local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace\Release\your_game_recomp_producer_trace.exe'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $traceExe = $defaultTraceExe
}
else {
    $requestedExe = if ([IO.Path]::IsPathRooted($ExecutablePath)) { $ExecutablePath } else { Join-Path $projectRoot $ExecutablePath }
    $traceExe = [IO.Path]::GetFullPath($requestedExe)
    $projectPrefix = $projectRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $traceExe.StartsWith($projectPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "ExecutablePath must stay inside the project workspace: $traceExe"
    }
}
$generatedSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0015.c'
$generatedDiagnosticSources = @(
    $generatedSource,
    # This header decides whether generic function trace hooks are compiled
    # in or reduced to no-ops; include it in freshness and provenance checks.
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_types.h'),
    # Input snapshots and dispatch instrumentation live in this chunk. Include
    # it in the freshness gate so a trace executable cannot silently omit them.
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0001.c'),
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0004.c'),
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0008.c'),
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0000.c'),
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0005.c'),
    (Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0016.c')
)
$diagnosticSupportSources = @(
    (Join-Path $projectRoot 'local-tools\steel-battalion-game\src\main.c'),
    (Join-Path $projectRoot 'local-tools\steel-battalion-game\src\dsound_write_watch.c'),
    (Join-Path $projectRoot 'local-tools\steel-battalion-game\CMakeLists.txt')
)
$logRoot = Join-Path $projectRoot 'iso\local-analysis\logs'
$saveRoot = (Resolve-Path -LiteralPath $SaveDirectory -ErrorAction Stop).Path
$runDirectory = Join-Path $logRoot $RunName

$activeGames = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like 'your_game_recomp*'
})
if ($activeGames.Count -gt 0) {
    $ids = ($activeGames | ForEach-Object { $_.Id }) -join ', '
    throw "A game process is still open (PID $ids). Close it naturally before starting ProducerTrace; this script will not stop it."
}

foreach ($path in (@($traceExe) + $generatedDiagnosticSources + @($saveRoot))) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required ProducerTrace input is missing: $path"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $saveRoot 'UserData') -PathType Container)) {
    throw "The selected save directory has no UserData folder: $saveRoot"
}
if ((Get-Item -LiteralPath $traceExe).Length -lt 10MB) {
    throw "ProducerTrace executable is unexpectedly small: $traceExe"
}
foreach ($source in $generatedDiagnosticSources) {
    if ((Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "ProducerTrace executable is older than an instrumented generated source ($source). Build it before launching."
    }
}
foreach ($source in $diagnosticSupportSources) {
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Required diagnostic support source is missing: $source"
    }
    if ($EnableDsoundWriteWatch -and
            (Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "Write-watch executable is older than its diagnostic support source ($source). Build it before launching."
    }
}
if (Test-Path -LiteralPath $runDirectory) {
    throw "Run directory already exists; choose a new name so earlier logs are preserved: $runDirectory"
}

$null = New-Item -ItemType Directory -Path $runDirectory
$padLive = Join-Path $runDirectory 'pad-live.txt'
$stdoutLog = Join-Path $runDirectory 'stdout.log'
$stderrLog = Join-Path $runDirectory 'stderr.log'
$framePath = Join-Path $runDirectory 'frame.bmp'
$crashPath = Join-Path $runDirectory 'crash.dmp'
$waitTrace = Join-Path $runDirectory 'wait-trace.log'
$dsoundWriteWatchLog = Join-Path $runDirectory 'dsound-write-watch.log'
$null = New-Item -ItemType File -Path $padLive

$settings = [ordered]@{
    RECOMP_AC97_READY = '1'
    RECOMP_APU_DSP_ACK = '0x803B8810'
    RECOMP_ASYNC_IO = '1'
    RECOMP_CRASH_DUMP = $crashPath
    RECOMP_DCF4_CALLBACK_TRACE = '1'
    # Add complete bounded open/close records so READ tokens correlate with
    # resolved paths after the older sampled path traces reach their caps.
    # Lifecycle fprintf rows repeatedly held startup in NtCreateFile in r51/r52.
    # Keep the low-volume loader-pass and READ probes enabled by default; opt in
    # to all open/close records only when a run specifically needs path mapping.
    RECOMP_FILE_LIFECYCLE_TRACE = '0'
    # r47 emitted only 7,471 reads, below the dense trace cap. Keep all read
    # completion fields to match token/offset/status with lifecycle events.
    RECOMP_FILE_READ_TRACE = '1'
    RECOMP_FILE_READ_TRACE_ALL = '1'
    RECOMP_DISPATCH_GATE = '1'
    RECOMP_DSOUND_COMMIT_TRACE = '1'
    RECOMP_DSOUND_NULL_TRACE = '1'
    RECOMP_FB_DUMP = $framePath
    RECOMP_FB_WINDOW = '1'
    RECOMP_FB_WINDOW_DUMP_EVERY = '1800'
    RECOMP_GUEST_LOCK = '1'
    RECOMP_INPUT_DIAG = '1'
    RECOMP_LOAD_REPEAT_TRACE = '1'
    RECOMP_IRQ_SAFE_POINTS = '1'
    RECOMP_KERNEL_LOG_BUDGET = '0'
    RECOMP_LOAD_PASS_TRACE = '1'
    RECOMP_NV2A_IRQ_TRACE = '1'
    RECOMP_PAD_LIVE = $padLive
    RECOMP_PB_EXEC = '1'
    RECOMP_PB_REPORT_MS = '30000'
    RECOMP_PB_SEMAPHORE_TRACE = '1'
    RECOMP_RASTER_PERF_TRACE = '1'
    RECOMP_RASTER_THREADS = '4'
    RECOMP_SAVE_DIR = $saveRoot
    RECOMP_SB_PRED_TRACE = '1'
    RECOMP_SB_ROSTER_TRACE = '1'
    RECOMP_SB_INPUT_SNAPSHOT_TRACE = '1'
    # The current generated gen/recomp_types.h compiles generic function trace
    # macros to no-ops. Keep this at zero as a guard if a trace-enabled header
    # is substituted; the named XID/menu/file/loader/GPU probes are gated below.
    RECOMP_TRACE_BUDGET = '0'
    RECOMP_SYNC_TRACE = '1'
    RECOMP_TITLE_INPUT_TRACE = '1'
    RECOMP_TITLE_ROUTE_TRACE = '1'
    RECOMP_TITLE_OBJECT_GATE_TRACE = '1'
    RECOMP_TITLE_KEVENTS = '1'
    RECOMP_MENU_STATE_TRACE = '1'
    RECOMP_MENU_DISPATCH_TRACE = '1'
    RECOMP_MENU_RESOURCE_TRACE = '1'
    RECOMP_MENU_CALLBACK_GATE_TRACE = '1'
    RECOMP_PILOT_LIST_TRACE = '1'
    RECOMP_USB = '1'
    RECOMP_USB_PROFILE = 'steel-battalion'
    RECOMP_USB_STATS = '1'
    RECOMP_VBLANK = '1'
    RECOMP_WAIT_TRACE_LOG = $waitTrace
    RECOMP_WATCHDOG_SECS = [string]$WatchdogSeconds
    RECOMP_XID_REPORT_TRACE = '1'
}

if ($EnableDcf4ProducerTrace) {
    # The current executable contains bounded producer-stage instrumentation.
    # Enable it only for a run specifically investigating a reproduced DCF4 wait.
    $settings.RECOMP_SB_DCF4_PRODUCER_TRACE = '1'
}

if ($EnableLoadStateCallbackTrace) {
    # Bounded before/after snapshots for indirect callbacks in sub_00101A60.
    # This helps distinguish loader-state callback progress from file or GPU waits.
    $settings.RECOMP_LOAD_STATE_CALLBACK_TRACE = '1'
}

if ($EnableSbCallbackTargetTrace) {
    # Record the indirect target used by the Steel Battalion DCF4 callback
    # without changing the target or its dispatch behavior.
    $settings.RECOMP_SB_CALLBACK_TARGET_TRACE = '1'
}

if ($EnableStreamTrace) {
    # Bounded entry snapshots around the generated DirectSound stream callback;
    # this logs guest state and the indirect target slot without changing it.
    $settings.RECOMP_SB_STREAM_TRACE = '1'
}

if ($EnableFileLifecycleTrace) {
    $settings.RECOMP_FILE_LIFECYCLE_TRACE = '1'
}

if ($EnableFileFailurePathTrace) {
    # The kernel bridge samples failed-create paths (first 64, then every 4096)
    # independently of the bounded lifecycle open/close trace.
    $settings.RECOMP_FILE_FAIL_PATH_TRACE = '1'
}

if ($EnableFileCallerTrace) {
    $settings.RECOMP_FILE_CALLER_TRACE = '1'
}

if ($EnableFileIoDetailTrace) {
    # Bounded NtWriteFile/NtQueryInformationFile completions, correlated by
    # guest handle token with lifecycle open/close rows when those are enabled.
    $settings.RECOMP_FILE_IO_DETAIL_TRACE = '1'
}

if ($EnableFileCopyTrace) {
    $settings.RECOMP_FILE_COPY_TRACE = '1'
}

if ($EnableThreadStartTrace) {
    $settings.RECOMP_THREAD_START_TRACE = '1'
}

if ($EnablePreloadWorkerTrace) {
    $settings.RECOMP_PRELOAD_WORKER_TRACE = '1'
}

if ($EnableDsoundWriteWatch) {
    $settings.RECOMP_DSOUND_WRITE_WATCH = '1'
    $settings.RECOMP_DSOUND_WRITE_WATCH_LOG = $dsoundWriteWatchLog
}

if ($EnableMmioTrace) {
    $settings.RECOMP_MMIO_TRACE = '1'
}

if ($EnablePacketTimingTrace) {
    # Packet decoding and method timing are high-volume; opt in for runs that
    # need to separate GPU backlog from loading or synchronization stalls.
    $settings.RECOMP_PB_PACKET_TRACE = '1'
    $settings.RECOMP_PB_TIMING = '1'
}

if (-not [string]::IsNullOrWhiteSpace($GuestWatchAddress)) {
    $settings.RECOMP_WATCH = $GuestWatchAddress
    $settings.RECOMP_WATCH_BLOCK = '1'
    $settings.RECOMP_WATCH_NATIVE_RIP = '1'
}
if (-not [string]::IsNullOrWhiteSpace($GuestWatchAddress2)) {
    # Optional second direct guest VA. Useful when a dynamic pointer-chain watch
    # tracks a list head while a second watch follows a previously observed node.
    $settings.RECOMP_WATCH2 = $GuestWatchAddress2
}

$environmentNames = @($settings.Keys) + 'RECOMP_WATCH2' + 'RECOMP_FILE_CALLER_TRACE' + 'RECOMP_FILE_IO_DETAIL_TRACE' + 'RECOMP_FILE_COPY_TRACE' + 'RECOMP_THREAD_START_TRACE' + 'RECOMP_PRELOAD_WORKER_TRACE' + 'RECOMP_MMIO_TRACE' + 'RECOMP_PAD_SCRIPT' + @(
    'RECOMP_FILE_FAIL_PATH_TRACE',
    'RECOMP_FILE_OPEN_PATH_TRACE'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

try {
    foreach ($name in $settings.Keys) {
        Set-Item -Path ("Env:{0}" -f $name) -Value $settings[$name]
    }
    # Keep duplicate path-only probes off by default. The failure-only probe is
    # low-volume and can be enabled explicitly after lifecycle traces hit a cap.
    if (-not $EnableFileFailurePathTrace) {
        Remove-Item Env:RECOMP_FILE_FAIL_PATH_TRACE -ErrorAction SilentlyContinue
    }
    Remove-Item Env:RECOMP_FILE_OPEN_PATH_TRACE -ErrorAction SilentlyContinue
    Remove-Item Env:RECOMP_PAD_SCRIPT -ErrorAction SilentlyContinue
    if (-not $EnableFileCallerTrace) {
        Remove-Item Env:RECOMP_FILE_CALLER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileIoDetailTrace) {
        Remove-Item Env:RECOMP_FILE_IO_DETAIL_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileCopyTrace) {
        Remove-Item Env:RECOMP_FILE_COPY_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableThreadStartTrace) {
        Remove-Item Env:RECOMP_THREAD_START_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnablePreloadWorkerTrace) {
        Remove-Item Env:RECOMP_PRELOAD_WORKER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableMmioTrace) {
        Remove-Item Env:RECOMP_MMIO_TRACE -ErrorAction SilentlyContinue
    }
    if ([string]::IsNullOrWhiteSpace($GuestWatchAddress2)) {
        Remove-Item Env:RECOMP_WATCH2 -ErrorAction SilentlyContinue
    }

    $environmentSnapshot = @($settings.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value })
    $environmentSnapshot += "EXECUTABLE_PATH=$traceExe"
    $environmentSnapshot += 'RECOMP_PAD_SCRIPT=<unset; screen-gated live input only>'
    if (-not $EnableFileCallerTrace) {
        $environmentSnapshot += 'RECOMP_FILE_CALLER_TRACE=<unset; opt-in>'
    }
    if (-not $EnableFileIoDetailTrace) {
        $environmentSnapshot += 'RECOMP_FILE_IO_DETAIL_TRACE=<unset; opt-in>'
    }
    if (-not $EnableFileCopyTrace) {
        $environmentSnapshot += 'RECOMP_FILE_COPY_TRACE=<unset; opt-in>'
    }
    if (-not $EnableThreadStartTrace) {
        $environmentSnapshot += 'RECOMP_THREAD_START_TRACE=<unset; opt-in>'
    }
    if (-not $EnablePreloadWorkerTrace) {
        $environmentSnapshot += 'RECOMP_PRELOAD_WORKER_TRACE=<unset; opt-in>'
    }
    if ($EnableDsoundWriteWatch) {
        $environmentSnapshot += "RECOMP_DSOUND_WRITE_WATCH=1; log=$dsoundWriteWatchLog"
    }
    if (-not $EnableMmioTrace) {
        $environmentSnapshot += 'RECOMP_MMIO_TRACE=<unset; opt-in>'
    }
    if ([string]::IsNullOrWhiteSpace($GuestWatchAddress2)) {
        $environmentSnapshot += 'RECOMP_WATCH2=<unset; opt-in second direct guest address>'
    }
    if (-not $EnableFileFailurePathTrace) {
        $environmentSnapshot += 'RECOMP_FILE_FAIL_PATH_TRACE=<unset; opt-in sampled failure paths>'
    }
    $environmentSnapshot += 'RECOMP_FILE_OPEN_PATH_TRACE=<unset; lifecycle traces cover opens>'
    if ($useAsyncTraceRelay) {
        $environmentSnapshot += "TRACE_OUTPUT_MODE=bounded asynchronous relay; queue capacity $AsyncTraceQueueCapacity lines; overflow drops recorded"
    }
    else {
        $environmentSnapshot += 'TRACE_OUTPUT_MODE=direct redirected files'
    }
    $environmentSnapshot | Set-Content -LiteralPath (Join-Path $runDirectory 'environment.txt') -Encoding UTF8

    # Preserve the exact executable, matching symbols, and generated AOT probe
    # inputs used for this run. Environment/path-only notes were insufficient
    # to identify the historical r69/r72 diagnostic images after replacement.
    $pdbPaths = @(Get-ChildItem -LiteralPath (Split-Path -Parent $traceExe) -File -Filter '*.pdb' |
        Select-Object -ExpandProperty FullName)
    $provenancePaths = @($traceExe) + $pdbPaths + $generatedDiagnosticSources + $diagnosticSupportSources
    $provenanceFiles = @(
        foreach ($path in ($provenancePaths | Select-Object -Unique)) {
            $file = Get-Item -LiteralPath $path
            $digest = Get-FileHash -LiteralPath $path -Algorithm SHA256
            [ordered]@{
                Path = $file.FullName
                Length = $file.Length
                LastWriteTimeUtc = $file.LastWriteTimeUtc.ToString('o')
                SHA256 = $digest.Hash
            }
        }
    )
    $runManifest = [ordered]@{
        SchemaVersion = 1
        RunName = $RunName
        CapturedAtUtc = [DateTime]::UtcNow.ToString('o')
        RunDirectory = $runDirectory
        ExecutablePath = $traceExe
        GeneratedSourceDirectory = Split-Path -Parent $generatedSource
        SaveDirectory = $saveRoot
        TraceOutputMode = if ($useAsyncTraceRelay) { 'bounded-asynchronous-relay' } else { 'direct-files' }
        AsyncTraceQueueCapacity = if ($useAsyncTraceRelay) { $AsyncTraceQueueCapacity } else { $null }
        Files = $provenanceFiles
    }
    $runManifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Encoding UTF8

    if ($useAsyncTraceRelay) {
        $relaySource = Join-Path $PSScriptRoot 'ProducerTraceAsyncRelay.cs'
        if (-not (Test-Path -LiteralPath $relaySource -PathType Leaf)) {
            throw "Asynchronous trace relay source is missing: $relaySource"
        }
        Add-Type -Path $relaySource
        $process = [ProducerTraceAsyncRelay]::Start(
            $traceExe, $projectRoot, $stdoutLog, $stderrLog, $AsyncTraceQueueCapacity)
    }
    else {
        $process = Start-Process -FilePath $traceExe `
            -WorkingDirectory $projectRoot `
            -RedirectStandardOutput $stdoutLog `
            -RedirectStandardError $stderrLog `
            -PassThru `
            -WindowStyle Normal
    }
}
finally {
    foreach ($name in $environmentNames) {
        $oldValue = $previousEnvironment[$name]
        if ($null -eq $oldValue) {
            Remove-Item -Path ("Env:{0}" -f $name) -ErrorAction SilentlyContinue
        }
        else {
            Set-Item -Path ("Env:{0}" -f $name) -Value $oldValue
        }
    }
}

"Started ProducerTrace PID $($process.Id)"
"Run logs: $runDirectory"
"Existing saves: $saveRoot"
"Screen-gated input file (created empty): $padLive"
if ($useAsyncTraceRelay) {
    'Waiting for the diagnostic game process to exit so the asynchronous log relay can finalize its files.'
    $relayResult = [ProducerTraceAsyncRelay]::WaitForExit($process, 5000)
    "Diagnostic process exit code: $($relayResult.ExitCode)"
    "Dropped trace lines: stdout=$($relayResult.DroppedStdoutLines), stderr=$($relayResult.DroppedStderrLines)"
    "Log writer stopped: $($relayResult.WriterStopped)"
    if ($relayResult.WriterError) { "Log writer error: $($relayResult.WriterError)" }

    $traceMarkers = @(
        '[PILOT-LIST-CB]', '[PILOT-ROW-POST]', '[SB-SNAPSHOT]', '[LOAD-STATE-CB]',
        '[SB-INPUT-DISPATCH]', '[SB-INPUT-PRED]', '[SB-EDGE-CONSUME]',
        '[MENU-DISPATCH]', '[MENU-RESOURCE]', '[MENU-CALLBACK-GATE]',
        '[MENU-OBJECT-GATE]', '[TITLE-ROUTE-QUERY]', '[THREAD-START]',
        '[PRELOAD-WORKER-ROUTE]', '[FILE-PRELOAD-ENTER]',
        '[FILE-PRELOAD-RETURN]', '[FILE-COPY-ENTER]', '[FILE-COPY-RETURN]',
        '[FILE-IO]', '[FILE-CALL]', '[FILE-MISS-PATH]',
        '[FILE-LIFECYCLE-OPEN-CAPPED]', '[FILE-LIFECYCLE-OPEN]',
        '[FILE-LIFECYCLE-CLOSE]', '[LOAD-HELPER]', '[LOAD-HELPER-BRANCH]',
        '[LOAD-HELPER-RET]', '[LOAD-STACK]', '[LOAD-RENDER]',
        '[LOAD-PASS-IN]', '[LOAD-PASS-OUT]', '[LOAD-REPEAT]',
        '[DCF4-CB]', '[SB-DMA-PUBLISH]', '[SB-PFB-POLL]', '[SYNC-PBSEM]',
        '[NV2A-TICK]', '[RASTER-PERF]', '[XID0]', '[XID-DMA0]'
    )
    $markerPattern = ($traceMarkers | Sort-Object Length -Descending |
        ForEach-Object { [regex]::Escape($_) }) -join '|'
    $markerRegex = [regex]::new(
        $markerPattern,
        [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $markerCounts = [ordered]@{}
    foreach ($marker in $traceMarkers) { $markerCounts[$marker] = 0 }
    if ($relayResult.WriterStopped) {
        $reader = [IO.StreamReader]::new($stderrLog)
        try {
            while ($null -ne ($line = $reader.ReadLine())) {
                foreach ($match in $markerRegex.Matches($line)) {
                    $markerCounts[$match.Value]++
                }
            }
        }
        finally { $reader.Dispose() }
    }
    $countsComplete = $relayResult.WriterStopped -and
        $relayResult.DroppedStderrLines -eq 0 -and
        [string]::IsNullOrEmpty($relayResult.WriterError)
    $resultManifest = Get-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Raw |
        ConvertFrom-Json
    $resultManifest | Add-Member -NotePropertyName RunResult -NotePropertyValue ([ordered]@{
        ProcessExitCode = $relayResult.ExitCode
        DroppedStdoutLines = $relayResult.DroppedStdoutLines
        DroppedStderrLines = $relayResult.DroppedStderrLines
        LogWriterStopped = $relayResult.WriterStopped
        LogWriterError = $relayResult.WriterError
        NoRelayDrops = ($relayResult.DroppedStdoutLines -eq 0 -and
            $relayResult.DroppedStderrLines -eq 0)
        MarkerCountsComplete = $countsComplete
        MarkerCounts = $markerCounts
    }) -Force
    $resultManifest | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Encoding UTF8
    if ($relayResult.WriterStopped) {
        $markerCounts.GetEnumerator() | ForEach-Object {
            '{0} {1}' -f $_.Key, $_.Value
        } | Set-Content -LiteralPath (Join-Path $runDirectory 'trace-counts.txt') -Encoding UTF8
    }
}
