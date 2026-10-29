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
specifically needed. An external supervisor also terminates only the launched
diagnostic process at the configured watchdog limit, even if its internal
watchdog fails. A plateau watchdog also stops only that child after the
configured interval with no change in the mode-2 loader signature or captured
framebuffer; it verifies the live executable path before stopping.
The UI plateau watchdog also stops only that child when the captured UI and
live-input transcript remain unchanged, including stalls before loading; it
captures a thread snapshot before stopping the child.
When NV2A telemetry is enabled, a separate progress watchdog also stops only
that child if callback/frame/counter/target/fence values remain unchanged, even
when a loading animation keeps changing the framebuffer.
Fatal runtime exception records also stop only the verified diagnostic child;
the intentional 0x406D1388 thread-name exception is ignored. The supervisor
captures an external thread dump before stopping. In-process dumps are opt-in.
-Dcf4WaitHangSeconds adds a child-only stop when producer tracing records a
DCF4 wait with no matching return for the configured interval.
-EnableFileFailurePathTrace adds a low-volume sampled path
record for failed NtCreateFile calls, useful when lifecycle traces reach their cap.

.EXAMPLE
./tools/Start-ProducerTrace.ps1 -RunName m3-producer-trace-screen-gated-20261024 -AsyncTraceRelay
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$RunName,

    [ValidateRange(300, 43200)]
    [int]$WatchdogSeconds = 900,

# One in-process snapshot at this many seconds after launch. This is
# nonfatal and emits at most one small dedicated watchdog log; it may be set
# later than the plateau duration because the external plateau timer starts
# only after observed progress stops.
    [ValidateRange(0, 3600)]
    [int]$WatchdogSnapshotSeconds = 0,

    # Bound each run's retained evidence before it can consume the workspace.
    # On limit, preserve the current log window and capture a dump, then stop
    # only the executable launched by this script.
    [ValidateRange(64, 4096)]
    [int]$RunStorageBudgetMiB = 64,

    [ValidateRange(120, 3600)]
    [int]$PlateauSeconds = 300,

    [ValidateRange(120, 3600)]
    [int]$UiPlateauSeconds = 240,

    [ValidateRange(60, 3600)]
    [int]$Nv2aProgressPlateauSeconds = 240,

    [ValidateRange(1, 1800)]
    [int]$FramebufferDumpInterval = 1800,

    [ValidateRange(60, 1800)]
    [int]$Dcf4WaitHangSeconds = 120,

    [ValidateRange(4096, 32768)]
    [int]$WaitTraceAllLimit = 16384,

    [ValidateRange(256, 65536)]
    [int]$DmaAckTraceLimit = 4096,

    [ValidateRange(256, 65536)]
    [int]$PbSemaphoreTraceLimit = 2048,

    [string]$GuestWatchAddress,

    [string]$GuestWatchAddress2,

    [switch]$EnableDcf4ProducerTrace,

    [switch]$EnableDcf4StackTrace,

    [switch]$EnableRingPollTrace,

    [switch]$EnableDcf4GateTrace,

    [switch]$EnableDcf4CallbackTrace,

    [switch]$EnableDcf4QueueTrace,

    [switch]$EnableDispatchGateTrace,

    [switch]$EnableGuestDeviceEntryTrace,

    [switch]$EnableMemoryReserveTrace,

    [switch]$EnableAllFileReadTrace,

    [switch]$EnableNv2aIrqTrace,

    [switch]$EnableNv2aSignatureTrace,

    [switch]$EnableNv2aTimerTrace,

    [switch]$DisableRasterPerfTrace,

    [switch]$EnableDmaAckTrace,

    [switch]$EnableNv2aPushbufferTrace,

    [switch]$EnablePgraphNotifyTrace,

    [switch]$EnableKeyboardInput,

    [switch]$EnableHighVolumeSyncTrace,

    [switch]$EnablePbSemaphoreTrace,

    [switch]$EnableLoadStateCallbackTrace,

    [switch]$EnableLoadStackTrace,

    [switch]$EnableLoadHelperTrace,

    [switch]$EnableLoadPairOutputTrace,

    [switch]$EnablePreloadTex00GateTrace,

    [switch]$EnablePreloadWorkerScheduleTrace,

    [switch]$EnableSbCallbackTargetTrace,

    [switch]$EnableStreamTrace,

    [switch]$EnableFileLifecycleTrace,

    [switch]$EnableThreadObjectTrace,

    [switch]$EnableFileFailurePathTrace,

    [switch]$EnableFileStatusTrace,

    [switch]$EnableFileOpenPathTrace,

    [switch]$EnableFileOpenTargetTrace,

    [switch]$DisableWaitTraceLog,

    [switch]$DisableLoadPassTrace,

    [switch]$DisableFileReadTrace,

    [switch]$DisableHighVolumeMenuTrace,

    [switch]$LoadingFocus,

    [switch]$EnableFileCallerTrace,

    [switch]$EnableFileIoDetailTrace,

    [switch]$EnableFileCopyReadTrace,

    [string]$FileCopyReadTargetPath = 'D:\media\bgm\STRM00.WAV',

    [string[]]$FileReadTargetPaths = @(),

    [ValidateRange(64, 4096)]
    [int]$FileReadTargetLimit = 256,

    [switch]$EnableInProcessCrashDump,

    [switch]$EnableGpuDrawTrace,

    [switch]$EnableFileCopyTrace,

    [switch]$EnableThreadStartTrace,

    [switch]$EnablePreloadWorkerTrace,

    [switch]$EnablePreloadAssetTrace,

    [switch]$EnableGuestCpuTrace,

    [switch]$EnableThreadSuspendTrace,

    [switch]$EnableGuestCpuSnapshots,

    [switch]$EnableGuestDivideTrace,

    [switch]$EnableCriticalSectionTrace,

    [switch]$EnableDsoundWriteWatch,

    [switch]$EnableDsoundListTrace,

    [switch]$EnableDsoundSurfaceTrace,

    [switch]$EnableTextureSampleTrace,

    [switch]$EnableXbeSectionTrace,

    [switch]$EnableGuestFrameTrace,

    [switch]$EnableAllWaitTrace,

    [switch]$EnableMmioTrace,

    [switch]$EnablePacketTimingTrace,

    [switch]$EnableGuestWriteBreakpoint,

    [string]$GuestWriteBreakpointAddress = '0x00311CC8',

    [string]$GuestMemoryOffset = '0x10000',

    [switch]$AsyncTraceRelay,

    [switch]$DirectTraceOutput,

    [ValidateRange(256, 1048576)]
    [int]$AsyncTraceQueueCapacity = 32768,

    [string]$ExecutablePath,

    [string]$SaveDirectory = (Join-Path $PSScriptRoot '..\iso\local-analysis\saves-m3-route-file-read-copy-20261023')
)

$ErrorActionPreference = 'Stop'

if (-not ('ProducerTraceAllocatedBytes' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;

public static class ProducerTraceAllocatedBytes {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetCompressedFileSizeW(string path, out uint high);

    public static long ForFile(string path) {
        string full = Path.GetFullPath(path);
        string extended = full.StartsWith(@"\\?\", StringComparison.Ordinal)
            ? full
            : (full.StartsWith(@"\\", StringComparison.Ordinal)
                ? @"\\?\UNC\" + full.Substring(2)
                : @"\\?\" + full);
        uint high;
        uint low = GetCompressedFileSizeW(extended, out high);
        if (low == UInt32.MaxValue && Marshal.GetLastWin32Error() != 0)
            return -1;
        return ((long)high << 32) | low;
    }
}
"@
}

function Get-AllocatedBytesForFiles {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo[]]$Files)

    [long]$total = 0
    foreach ($file in $Files) {
        $allocated = [ProducerTraceAllocatedBytes]::ForFile($file.FullName)
        if ($allocated -lt 0) { return -1L }
        $total += $allocated
    }
    return $total
}

function Get-RunDirectoryAllocatedBytes {
    param([Parameter(Mandatory = $true)][string]$Path)

    $files = @(Get-ChildItem -LiteralPath $Path -File -Force -Recurse)
    return Get-AllocatedBytesForFiles -Files $files
}

if ($WatchdogSnapshotSeconds -gt 0 -and
        $WatchdogSnapshotSeconds -ge $WatchdogSeconds) {
    throw 'WatchdogSnapshotSeconds must be earlier than the external watchdog limit.'
}

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
    (Join-Path $projectRoot 'local-tools\xboxrecomp\src\kernel\kernel_bridge.c'),
    (Join-Path $projectRoot 'local-tools\xboxrecomp\src\kernel\kernel_thread.c'),
    (Join-Path $projectRoot 'local-tools\xboxrecomp\src\kernel\kernel_hal.c'),
    (Join-Path $projectRoot 'local-tools\steel-battalion-game\CMakeLists.txt')
)
$logRoot = Join-Path $projectRoot 'iso\local-analysis\logs'
$saveRoot = (Resolve-Path -LiteralPath $SaveDirectory -ErrorAction Stop).Path
$runDirectory = Join-Path $logRoot $RunName
$guestWriteBreakpointExe = Join-Path $projectRoot 'local-tools\GuestWriteBreakpoint.exe'

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
if ($EnableGuestWriteBreakpoint -and -not (Test-Path -LiteralPath $guestWriteBreakpointExe -PathType Leaf)) {
    throw "Guest hardware-breakpoint helper is missing: $guestWriteBreakpointExe"
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
    if ($EnableXbeSectionTrace -and $source -like '*xboxrecomp\src\kernel\kernel_bridge.c' -and
            (Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "XBE-section-trace executable is older than the kernel bridge ($source). Build it before launching."
    }
    if ($EnableAllWaitTrace -and $source -like '*xboxrecomp\src\kernel\kernel_bridge.c' -and
            (Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "All-wait-trace executable is older than the kernel bridge ($source). Build it before launching."
    }
    if ($EnableThreadObjectTrace -and $source -like '*xboxrecomp\src\kernel\kernel_bridge.c' -and
            (Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "Thread-object-trace executable is older than the kernel bridge ($source). Build it before launching."
    }
    if ($EnableThreadSuspendTrace -and
            ($source -like '*xboxrecomp\src\kernel\kernel_bridge.c' -or
             $source -like '*xboxrecomp\src\kernel\kernel_thread.c') -and
            (Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $source).LastWriteTimeUtc) {
        throw "Thread-suspend-trace executable is older than a kernel source ($source). Build it before launching."
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
$fileOpenTargetLog = Join-Path $runDirectory 'file-open-target.log'
$fileLifecycleLog = Join-Path $runDirectory 'file-lifecycle.log'
$fileReadLog = Join-Path $runDirectory 'file-read.log'
$fileCopyReadLog = Join-Path $runDirectory 'file-copy-read.log'
$fileReadTargetLog = Join-Path $runDirectory 'file-read-target.log'
$loadStateCallbackLog = Join-Path $runDirectory 'load-state-callback.log'
$dsoundWriteWatchLog = Join-Path $runDirectory 'dsound-write-watch.log'
$watchdogSnapshotLog = Join-Path $runDirectory 'watchdog-snapshot.log'
$threadSuspendLog = Join-Path $runDirectory 'thread-suspend.log'
$null = New-Item -ItemType File -Path $padLive

$settings = [ordered]@{
    RECOMP_AC97_READY = '1'
    RECOMP_APU_DSP_ACK = '0x803B8810'
    RECOMP_ASYNC_IO = '1'
    # Add complete bounded open/close records so READ tokens correlate with
    # resolved paths after the older sampled path traces reach their caps.
    # Lifecycle fprintf rows repeatedly held startup in NtCreateFile in r51/r52.
    # Keep the low-volume loader-pass and READ probes enabled by default; opt in
    # to all open/close records only when a run specifically needs path mapping.
    RECOMP_FILE_LIFECYCLE_TRACE = '0'
    RECOMP_FILE_LIFECYCLE_LOG = $fileLifecycleLog
    # Bounded read completion sampling is enough for routine loading diagnosis.
    # Trace rows use a dedicated Win32 append log to avoid CRT stderr locking.
    RECOMP_FILE_READ_TRACE = '1'
    RECOMP_FILE_READ_LOG = $fileReadLog
    RECOMP_DISPATCH_GATE = '1'
    RECOMP_DSOUND_COMMIT_TRACE = '1'
    RECOMP_DSOUND_NULL_TRACE = '1'
    RECOMP_FB_DUMP = $framePath
    RECOMP_FB_WINDOW = '1'
    RECOMP_FB_WINDOW_DUMP_EVERY = [string]$FramebufferDumpInterval
    RECOMP_GUEST_LOCK = '1'
    # Retain the bounded per-waiter ticket table for live read-only diagnosis.
    # The guest CPU snapshot itself remains one-shot and opt-in separately.
    RECOMP_GUEST_CPU_SNAPSHOT = '0'
    RECOMP_INPUT_DIAG = '1'
    RECOMP_LOAD_REPEAT_TRACE = '1'
    RECOMP_IRQ_SAFE_POINTS = '1'
    RECOMP_KERNEL_LOG_BUDGET = '0'
    RECOMP_LOAD_PASS_TRACE = '1'
    RECOMP_PAD_LIVE = $padLive
    RECOMP_PB_EXEC = '1'
    RECOMP_PB_REPORT_MS = '30000'
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
    RECOMP_WATCHDOG_SECS = [string]$(if ($WatchdogSnapshotSeconds -gt 0) { $WatchdogSnapshotSeconds } else { $WatchdogSeconds })
    RECOMP_XID_REPORT_TRACE = '1'
}

if ($WatchdogSnapshotSeconds -gt 0) {
    $settings.RECOMP_WATCHDOG_KEEP_RUNNING = '1'
    $settings.RECOMP_WATCHDOG_LOG = $watchdogSnapshotLog
    $settings.RECOMP_WATCHDOG_NATIVE_PC = '1'
    $settings.RECOMP_WATCHDOG_PGRAPH_SNAPSHOT = '1'
    $settings.RECOMP_GUEST_CPU_SNAPSHOT = '1'
    $settings.RECOMP_CS_SNAPSHOT = '1'
}

if ($EnableThreadSuspendTrace) {
    $settings.RECOMP_THREAD_SUSPEND_TRACE = '1'
    $settings.RECOMP_THREAD_SUSPEND_LOG = $threadSuspendLog
}

if ($EnableGuestCpuSnapshots) {
    $settings.RECOMP_GUEST_CPU_SNAPSHOT = '1'
}

if ($DisableRasterPerfTrace) {
    # Raster performance logging uses stderr on worker threads. Keep a clean
    # control run available to test whether concurrent trace output is stalling
    # the guest while retaining independent DMA/semaphore telemetry.
    $settings.Remove('RECOMP_RASTER_PERF_TRACE')
}

if ($DisableWaitTraceLog) {
    # Recent traces show DCF4 wait/set pairs, while the per-event file writer
    # adds substantial diagnostics traffic. Disable that channel unless an
    # unmatched wait has actually reproduced.
    $settings.Remove('RECOMP_WAIT_TRACE_LOG')
}

if ($DisableLoadPassTrace) {
    # Loader pass/stack rows use fprintf on the game thread and scale with
    # every paired-open scan. Keep state callbacks and separate file-open
    # records while suppressing this high-volume diagnostic channel.
    $settings.Remove('RECOMP_LOAD_PASS_TRACE')
}

if ($DisableFileReadTrace) {
    # Keep only the explicitly targeted copy-read completion probe when
    # requested; the general sampled read stream uses the shared CRT stderr.
    $settings.Remove('RECOMP_FILE_READ_TRACE')
}

if ($DisableHighVolumeMenuTrace) {
    # Keep XID/input and the active pilot-list callback traces while avoiding
    # per-frame title-route, title-object, and menu-dispatch fprintf traffic.
    $settings.Remove('RECOMP_TITLE_ROUTE_TRACE')
    $settings.Remove('RECOMP_TITLE_OBJECT_GATE_TRACE')
    $settings.Remove('RECOMP_MENU_DISPATCH_TRACE')
}

$loadingFocusTraceNames = @(
    'RECOMP_INPUT_DIAG',
    'RECOMP_LOAD_REPEAT_TRACE',
    'RECOMP_DSOUND_COMMIT_TRACE',
    'RECOMP_DSOUND_NULL_TRACE',
    'RECOMP_SB_PRED_TRACE',
    'RECOMP_SB_ROSTER_TRACE',
    'RECOMP_SB_INPUT_SNAPSHOT_TRACE',
    'RECOMP_TITLE_INPUT_TRACE',
    'RECOMP_TITLE_ROUTE_TRACE',
    'RECOMP_TITLE_OBJECT_GATE_TRACE',
    'RECOMP_MENU_STATE_TRACE',
    'RECOMP_MENU_DISPATCH_TRACE',
    'RECOMP_MENU_RESOURCE_TRACE',
    'RECOMP_MENU_CALLBACK_GATE_TRACE',
    'RECOMP_PILOT_LIST_TRACE'
)
if ($LoadingFocus) {
    foreach ($name in $loadingFocusTraceNames) {
        if ($name -eq 'RECOMP_LOAD_REPEAT_TRACE' -and $EnableLoadHelperTrace) {
            continue
        }
        $settings.Remove($name)
    }
}

if ($EnableLoadHelperTrace) {
    # The generated helper probe is bounded to 8192 branch/return rows and
    # records the paired-open selector, resource index, outputs, and stage.
    # Keep it available in LoadingFocus runs without re-enabling menu traces.
    $settings.RECOMP_LOAD_REPEAT_TRACE = '1'
}
$environmentSnapshot += 'RECOMP_CRASH_DUMP=<unset; fatal dumps are captured externally by the diagnostic supervisor>'
if ($EnableInProcessCrashDump) {
    $environmentSnapshot += "RECOMP_CRASH_DUMP=$crashPath; in-process crash dump explicitly enabled"
}
$environmentSnapshot += if ($FileReadTargetPaths.Count -gt 0) {
    "RECOMP_FILE_READ_TARGET_PATHS=$($FileReadTargetPaths -join ';'); targeted NtReadFile begin/completion records use Win32 append output; per-handle limit=$FileReadTargetLimit and excess-read cap rows are bounded"
} else {
    'RECOMP_FILE_READ_TARGET_PATHS=<unset; opt-in>'
}

if ($EnableDcf4ProducerTrace) {
    # The current executable contains bounded producer-stage instrumentation.
    # Enable it only for a run specifically investigating a reproduced DCF4 wait.
    $settings.RECOMP_SB_DCF4_PRODUCER_TRACE = '1'
}

if ($EnableDcf4StackTrace) {
    # Preserve the first 64 raw guest stack words for DCF4 waits. These are
    # address candidates only, not a validated guest unwind.
    $settings.RECOMP_DCF4_STACK_TRACE = '1'
}

if ($EnableRingPollTrace) {
    $settings.RECOMP_SB_RING_POLL_TRACE_FILE = Join-Path $runDirectory 'ring-poll.enable'
}

if ($EnableDcf4GateTrace) {
    # Capture the translated guest callback's caller gate with a fixed 2,048-row cap.
    $settings.RECOMP_SB_DCF4_GATE_TRACE = '1'
}

if ($EnableDcf4CallbackTrace) {
    $settings.RECOMP_DCF4_CALLBACK_TRACE = '1'
}

if ($EnableDcf4QueueTrace) {
    # The generated ring probe emits at most 1,024 sampled records, including
    # the helper's real work count and pre/post ring fields.
    $settings.RECOMP_SB_DCF4_QUEUE_TRACE = '1'
}

if ($EnableDispatchGateTrace) {
    # Runtime emits only long waits/holds and caps this channel independently.
    $settings.RECOMP_DISPATCH_GATE_TRACE = '1'
    $settings.RECOMP_DISPATCH_GATE_TRACE_LIMIT = '256'
    $settings.RECOMP_DISPATCH_GATE_TRACE_MIN_MS = '250'
}

if ($EnableGuestDeviceEntryTrace) {
    # Sample the 0x3FFF table-entry creation and retry paths; runtime output is capped at 256 rows.
    $settings.RECOMP_GUEST_DEVICE_ENTRY_TRACE = '1'
}

if ($EnableMemoryReserveTrace) {
    # Only failed or >=4 MiB reserve requests are recorded; runtime cap is 32.
    $settings.RECOMP_MEM_RESERVE_TRACE = '1'
}

if ($EnableAllFileReadTrace) {
    $settings.RECOMP_FILE_READ_TRACE_ALL = '1'
}

if ($EnableNv2aIrqTrace) {
    $settings.RECOMP_NV2A_IRQ_TRACE = '1'
}

if ($EnableNv2aSignatureTrace) {
    # Keep the low-volume vblank/frame/counter/target/fence signature required
    # by the stall watchdog, while suppressing per-write PGRAPH ACK rows.
    $settings.RECOMP_NV2A_IRQ_TRACE = '1'
    $settings.RECOMP_PGRAPH_ACK_TRACE = '0'
}

if ($EnableNv2aTimerTrace) {
    # Low-volume 1 Hz boundaries around vblank, IRQ polling, and DPC drain.
    # Pair with the IRQ trace to identify which producer stage stops advancing.
    $settings.RECOMP_NV2A_TIMER_TRACE = '1'
}

if ($EnableDmaAckTrace) {
    # Bounded host-side DMA PUT/GET snapshots around pushbuffer scans.
    $settings.RECOMP_DMA_ACK_TRACE = '1'
    $settings.RECOMP_DMA_ACK_TRACE_LIMIT = [string]$DmaAckTraceLimit
}

if ($EnableNv2aPushbufferTrace) {
    $settings.RECOMP_NV2A_TRACE = '1'
}

if ($EnablePgraphNotifyTrace) {
    # Existing bounded request/ack records expose a stuck synchronous PGRAPH
    # notification without enabling per-register ACK tracing.
    $settings.RECOMP_PB_NOTIFY_TRACE = '1'
}

if ($EnableKeyboardInput) {
    # The host keyboard overlay is opt-in so a real XInput pad remains the
    # default. It also lets screen-gated diagnostics navigate text entry.
    $settings.RECOMP_KEYBOARD = '1'
    $settings.RECOMP_KEY_TRACE = '1'
}

if ($EnableTextureSampleTrace) {
    # Log a bounded sample of decoded guest texture descriptors and mark
    # out-of-range base addresses before the renderer performs its read.
    $settings.RECOMP_TEX_SAMPLE_TRACE = '1'
}

if ($EnableHighVolumeSyncTrace) {
    # Detailed PB semaphore/sync records can emit tens of thousands of rows.
    # The default keeps periodic NV2A/DCF4 snapshots; opt in only for a run
    # that specifically needs per-store synchronization history.
    $settings.RECOMP_PB_SEMAPHORE_TRACE = '1'
    $settings.RECOMP_SYNC_TRACE = '1'
}

if ($EnablePbSemaphoreTrace) {
    # The runtime emits an initial semaphore sample and then sparse
    # time-based samples, without enabling the high-volume per-store SYNC trace.
    $settings.RECOMP_PB_SEMAPHORE_TRACE = '1'
    $settings.RECOMP_PB_SEMAPHORE_TRACE_LIMIT = [string]$PbSemaphoreTraceLimit
}

if ($EnableLoadStateCallbackTrace) {
    # Bounded before/after snapshots for indirect callbacks in sub_00101A60.
    # This helps distinguish loader-state callback progress from file or GPU waits.
    $settings.RECOMP_LOAD_STATE_CALLBACK_TRACE = '1'
    $settings.RECOMP_LOAD_STATE_CALLBACK_LOG = $loadStateCallbackLog
}

if ($EnableLoadStackTrace) {
    $settings.RECOMP_LOAD_STACK_TRACE = '1'
}

if ($EnableLoadPairOutputTrace) {
    # Capture the mode-2 helper's output pair and selected resource index at
    # the scan's final comparison, without changing the guest state update.
    $settings.RECOMP_LOAD_PAIR_OUTPUT_TRACE = '1'
}

if ($EnablePreloadTex00GateTrace) {
    # Observe the preload gate and special resource-index 0x1E call without
    # changing the guest branch or copy behavior.
    $settings.RECOMP_PRELOAD_TEX00_GATE_TRACE = '1'
}

if ($EnablePreloadWorkerScheduleTrace) {
    # Record requested modes, the mode-selection inputs, and the loader's
    # alternate scheduler gate without changing either guest branch.
    $settings.RECOMP_PRELOAD_WORKER_SCHEDULE_TRACE = '1'
    $settings.RECOMP_PRELOAD_MODE_REQUEST_TRACE = '1'
    $settings.RECOMP_LOAD_SCHED_GATE_TRACE = '1'
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

if ($EnableThreadObjectTrace) {
    # Thread-object logging is transition-only, samples a pending poll once
    # and then every 1,024 polls per handle, and has a 256-row process cap.
    $settings.RECOMP_THREAD_OBJECT_TRACE = '1'
}

if ($EnableFileFailurePathTrace) {
    # The kernel bridge samples failed-create paths (first 64, then every 4096)
    # independently of the bounded lifecycle open/close trace.
    $settings.RECOMP_FILE_FAIL_PATH_TRACE = '1'
}

if ($EnableFileStatusTrace) {
    # Include the NTSTATUS and Win32 error selected by NtCreateFile. This is
    # one line per open attempt and is opt-in for loader dependency diagnosis.
    $settings.RECOMP_FILE_TRACE = '1'
}

if ($EnableFileOpenPathTrace) {
    # Bounded successful open path records correlate read handles with files;
    # the runtime caps this trace at 2,048 rows.
    $settings.RECOMP_FILE_OPEN_PATH_TRACE = '1'
}

if ($EnableFileOpenTargetTrace) {
    # Trace entry/return around only the loader's paired-open NtCreateFile
    # caller. Records use a separate native append log to avoid contention on
    # the shared CRT stderr stream and are capped at 2048 attempts.
    $settings.RECOMP_FILE_OPEN_TARGET_TRACE = '1'
    $settings.RECOMP_FILE_OPEN_TARGET_LOG = $fileOpenTargetLog
}

if ($EnableFileCallerTrace) {
    $settings.RECOMP_FILE_CALLER_TRACE = '1'
}

if ($EnableFileIoDetailTrace) {
    # Bounded NtWriteFile/NtQueryInformationFile completions, correlated by
    # guest handle token with lifecycle open/close rows when those are enabled.
    $settings.RECOMP_FILE_IO_DETAIL_TRACE = '1'
}

if ($EnableFileCopyReadTrace) {
    # Trace selected source reads to a dedicated append file, avoiding shared
    # CRT stderr on the loader worker.
    $settings.RECOMP_FILE_COPY_READ_TRACE = '1'
    $settings.RECOMP_FILE_COPY_READ_LOG = $fileCopyReadLog
    $settings.RECOMP_FILE_COPY_READ_TARGET = $FileCopyReadTargetPath
}

if ($FileReadTargetPaths.Count -gt 0) {
    $settings.RECOMP_FILE_READ_TARGET_TRACE = '1'
    $settings.RECOMP_FILE_READ_TARGET_PATHS = $FileReadTargetPaths -join ';'
    $settings.RECOMP_FILE_READ_TARGET_LOG = $fileReadTargetLog
    $settings.RECOMP_FILE_READ_TARGET_LIMIT = [string]$FileReadTargetLimit
}

if ($EnableInProcessCrashDump) {
    $settings.RECOMP_CRASH_DUMP = $crashPath
}

if ($EnableGpuDrawTrace) {
    $settings.RECOMP_GPU_DRAW_TRACE = '1'
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

if ($EnablePreloadAssetTrace) {
    # Trace per-entry preload eligibility, metadata comparison, and copy result
    # in generated sub_00013D70 without changing its guest decisions.
    $settings.RECOMP_PRELOAD_ASSET_TRACE = '1'
}

if ($EnableGuestCpuTrace) {
    # Emit only guest CPU turns held for at least 5 ms. This can identify a
    # scheduler handoff cycle without logging every guest kernel call.
    $settings.RECOMP_GUEST_CPU_TRACE = '5'
}

if ($EnableGuestDivideTrace) {
    # The runtime and generated code emit a bounded guest IDIV operand record
    # at the two candidate divisions in sub_0001ED90.
    $settings.RECOMP_GUEST_DIV_TRACE = '1'
}

if ($EnableCriticalSectionTrace) {
    # Record the guest critical-section address and caller for bounded samples.
    $settings.RECOMP_CRITSEC_TRACE = '1'
}

if ($EnableDsoundWriteWatch) {
    $settings.RECOMP_DSOUND_WRITE_WATCH = '1'
    $settings.RECOMP_DSOUND_WRITE_WATCH_LOG = $dsoundWriteWatchLog
}

if ($EnableDsoundListTrace) {
    # Generated insert/unlink probes are capped and behavior-neutral. Use them
    # to capture list mutations before a later DirectSound invalid-node fault.
    $settings.RECOMP_DS_LIST_TRACE = '1'
}

if ($EnableDsoundSurfaceTrace) {
    # Correlate the known DirectSound list addresses with the active NV2A
    # surface state at the exact raster pixel store. The runtime caps this at
    # 16 matching writes and emits nothing unless an address overlaps.
    $settings.RECOMP_DSOUND_SURFACE_TRACE = '1'
}

if ($EnableXbeSectionTrace) {
    # Bounded per-call XeLoadSection/XeUnloadSection records. This identifies
    # the selected XBE section and refcount without enabling broad kernel logs.
    $settings.RECOMP_XBE_SECTION_TRACE = '1'
}

if ($EnableGuestFrameTrace) {
    # Guest EBP chains are high-volume around frequent event waits. The runtime
    # samples this trace and reports how many calls were suppressed.
    $settings.RECOMP_GUEST_FRAME_TRACE = '1'
}

if ($EnableAllWaitTrace) {
    # Separate bounded capture for ordinary guest waits; keeps the historical
    # 64-record default unchanged and records at most the selected cap.
    $settings.RECOMP_WAIT_TRACE_ALL_LIMIT = [string]$WaitTraceAllLimit
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

$environmentNames = @($settings.Keys) + @('RECOMP_WAIT_TRACE_LOG', 'RECOMP_LOAD_PASS_TRACE', 'RECOMP_FILE_READ_TRACE', 'RECOMP_FILE_READ_TARGET_TRACE', 'RECOMP_FILE_READ_TARGET_PATHS', 'RECOMP_FILE_READ_TARGET_LOG', 'RECOMP_FILE_READ_TARGET_LIMIT', 'RECOMP_FILE_COPY_READ_TRACE', 'RECOMP_FILE_COPY_READ_LOG', 'RECOMP_FILE_COPY_READ_TARGET', 'RECOMP_LOAD_STATE_CALLBACK_LOG', 'RECOMP_LOAD_STACK_TRACE', 'RECOMP_GPU_DRAW_TRACE', 'RECOMP_CRASH_DUMP', 'RECOMP_GUEST_FRAME_TRACE', 'RECOMP_WATCHDOG_KEEP_RUNNING', 'RECOMP_WATCHDOG_LOG', 'RECOMP_WATCHDOG_NATIVE_PC', 'RECOMP_WATCHDOG_PGRAPH_SNAPSHOT', 'RECOMP_GUEST_CPU_SNAPSHOT', 'RECOMP_THREAD_SUSPEND_TRACE', 'RECOMP_THREAD_SUSPEND_LOG', 'RECOMP_MEM_RESERVE_TRACE', 'RECOMP_SB_RING_POLL_TRACE', 'RECOMP_SB_RING_POLL_TRACE_FILE') + $loadingFocusTraceNames + 'RECOMP_PGRAPH_ACK_TRACE' + 'RECOMP_PB_NOTIFY_TRACE' + 'RECOMP_WATCH2' + 'RECOMP_FILE_READ_TRACE_ALL' + 'RECOMP_FILE_CALLER_TRACE' + 'RECOMP_FILE_IO_DETAIL_TRACE' + 'RECOMP_FILE_COPY_TRACE' + 'RECOMP_THREAD_START_TRACE' + 'RECOMP_PRELOAD_WORKER_TRACE' + 'RECOMP_PRELOAD_ASSET_TRACE' + 'RECOMP_MMIO_TRACE' + 'RECOMP_PAD_SCRIPT' + 'RECOMP_XBE_SECTION_TRACE' + 'RECOMP_WAIT_TRACE_ALL_LIMIT' + 'RECOMP_SB_DCF4_PRODUCER_TRACE' + 'RECOMP_DCF4_STACK_TRACE' + 'RECOMP_SB_DCF4_GATE_TRACE' + 'RECOMP_DCF4_CALLBACK_TRACE' + 'RECOMP_DISPATCH_GATE_TRACE' + 'RECOMP_DISPATCH_GATE_TRACE_LIMIT' + 'RECOMP_DISPATCH_GATE_TRACE_MIN_MS' + 'RECOMP_NV2A_IRQ_TRACE' + 'RECOMP_NV2A_TIMER_TRACE' + 'RECOMP_DMA_ACK_TRACE' + 'RECOMP_DMA_ACK_TRACE_LIMIT' + 'RECOMP_NV2A_TRACE' + 'RECOMP_SYNC_TRACE' + 'RECOMP_PB_SEMAPHORE_TRACE' + 'RECOMP_PB_SEMAPHORE_TRACE_LIMIT' + 'RECOMP_DS_LIST_TRACE' + 'RECOMP_KEYBOARD' + 'RECOMP_KEY_TRACE' + 'RECOMP_FILE_TRACE' + @(
    'RECOMP_FILE_FAIL_PATH_TRACE',
    'RECOMP_GUEST_DEVICE_ENTRY_TRACE',
    'RECOMP_FILE_OPEN_PATH_TRACE',
    'RECOMP_FILE_OPEN_TARGET_TRACE',
    'RECOMP_FILE_OPEN_TARGET_LOG',
    'RECOMP_FILE_LIFECYCLE_LOG',
    'RECOMP_FILE_READ_LOG',
    'RECOMP_LOAD_PAIR_OUTPUT_TRACE',
    'RECOMP_PRELOAD_TEX00_GATE_TRACE',
    'RECOMP_PRELOAD_WORKER_SCHEDULE_TRACE',
    'RECOMP_PRELOAD_MODE_REQUEST_TRACE',
    'RECOMP_LOAD_SCHED_GATE_TRACE'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

try {
    foreach ($name in $settings.Keys) {
        Set-Item -Path ("Env:{0}" -f $name) -Value $settings[$name]
    }
    if ($DisableWaitTraceLog) {
        Remove-Item Env:RECOMP_WAIT_TRACE_LOG -ErrorAction SilentlyContinue
    }
    if ($DisableLoadPassTrace) {
        Remove-Item Env:RECOMP_LOAD_PASS_TRACE -ErrorAction SilentlyContinue
    }
    if ($DisableFileReadTrace) {
        Remove-Item Env:RECOMP_FILE_READ_TRACE -ErrorAction SilentlyContinue
    }
    if ($LoadingFocus) {
        foreach ($name in $loadingFocusTraceNames) {
            if ($name -eq 'RECOMP_LOAD_REPEAT_TRACE' -and $EnableLoadHelperTrace) {
                continue
            }
            Remove-Item -Path ("Env:{0}" -f $name) -ErrorAction SilentlyContinue
        }
    }
    # Keep duplicate path-only probes off by default. The failure-only probe is
    # low-volume and can be enabled explicitly after lifecycle traces hit a cap.
    if (-not $EnableFileFailurePathTrace) {
        Remove-Item Env:RECOMP_FILE_FAIL_PATH_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileStatusTrace) {
        Remove-Item Env:RECOMP_FILE_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileOpenPathTrace) {
        Remove-Item Env:RECOMP_FILE_OPEN_PATH_TRACE -ErrorAction SilentlyContinue
    }
    Remove-Item Env:RECOMP_PAD_SCRIPT -ErrorAction SilentlyContinue
    Remove-Item Env:RECOMP_SB_RING_POLL_TRACE -ErrorAction SilentlyContinue
    if (-not $EnableRingPollTrace) {
        Remove-Item Env:RECOMP_SB_RING_POLL_TRACE_FILE -ErrorAction SilentlyContinue
    }
    if (-not $EnableGuestFrameTrace) {
        Remove-Item Env:RECOMP_GUEST_FRAME_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableDcf4CallbackTrace) {
        Remove-Item Env:RECOMP_DCF4_CALLBACK_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableDcf4StackTrace) {
        Remove-Item Env:RECOMP_DCF4_STACK_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableAllFileReadTrace) {
        Remove-Item Env:RECOMP_FILE_READ_TRACE_ALL -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileCallerTrace) {
        Remove-Item Env:RECOMP_FILE_CALLER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileIoDetailTrace) {
        Remove-Item Env:RECOMP_FILE_IO_DETAIL_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileCopyTrace) {
        Remove-Item Env:RECOMP_FILE_COPY_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileCopyReadTrace) {
        Remove-Item Env:RECOMP_FILE_COPY_READ_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_FILE_COPY_READ_LOG -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_FILE_COPY_READ_TARGET -ErrorAction SilentlyContinue
    }
    if ($FileReadTargetPaths.Count -eq 0) {
        Remove-Item Env:RECOMP_FILE_READ_TARGET_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_FILE_READ_TARGET_PATHS -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_FILE_READ_TARGET_LOG -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_FILE_READ_TARGET_LIMIT -ErrorAction SilentlyContinue
    }
    if (-not $EnableInProcessCrashDump) {
        Remove-Item Env:RECOMP_CRASH_DUMP -ErrorAction SilentlyContinue
    }
    if (-not $EnableLoadStateCallbackTrace) {
        Remove-Item Env:RECOMP_LOAD_STATE_CALLBACK_LOG -ErrorAction SilentlyContinue
    }
    if (-not $EnableLoadStackTrace) {
        Remove-Item Env:RECOMP_LOAD_STACK_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableGpuDrawTrace) {
        Remove-Item Env:RECOMP_GPU_DRAW_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableThreadStartTrace) {
        Remove-Item Env:RECOMP_THREAD_START_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableThreadSuspendTrace) {
        Remove-Item Env:RECOMP_THREAD_SUSPEND_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_THREAD_SUSPEND_LOG -ErrorAction SilentlyContinue
    }
    if (-not $EnablePreloadWorkerTrace) {
        Remove-Item Env:RECOMP_PRELOAD_WORKER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnablePreloadAssetTrace) {
        Remove-Item Env:RECOMP_PRELOAD_ASSET_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableMmioTrace) {
        Remove-Item Env:RECOMP_MMIO_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableXbeSectionTrace) {
        Remove-Item Env:RECOMP_XBE_SECTION_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableAllWaitTrace) {
        Remove-Item Env:RECOMP_WAIT_TRACE_ALL_LIMIT -ErrorAction SilentlyContinue
    }
    if (-not $EnableDcf4ProducerTrace) {
        Remove-Item Env:RECOMP_SB_DCF4_PRODUCER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableDispatchGateTrace) {
        Remove-Item Env:RECOMP_DISPATCH_GATE_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_DISPATCH_GATE_TRACE_LIMIT -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_DISPATCH_GATE_TRACE_MIN_MS -ErrorAction SilentlyContinue
    }
    if (-not $EnableGuestDeviceEntryTrace) {
        Remove-Item Env:RECOMP_GUEST_DEVICE_ENTRY_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableMemoryReserveTrace) {
        Remove-Item Env:RECOMP_MEM_RESERVE_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableDcf4GateTrace) {
        Remove-Item Env:RECOMP_SB_DCF4_GATE_TRACE -ErrorAction SilentlyContinue
    }
    if (-not ($EnableNv2aIrqTrace -or $EnableNv2aSignatureTrace)) {
        Remove-Item Env:RECOMP_NV2A_IRQ_TRACE -ErrorAction SilentlyContinue
    }
    if (-not ($EnableNv2aIrqTrace -or $EnableNv2aSignatureTrace)) {
        Remove-Item Env:RECOMP_PGRAPH_ACK_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableFileOpenTargetTrace) {
        Remove-Item Env:RECOMP_FILE_OPEN_TARGET_LOG -ErrorAction SilentlyContinue
    }
    if (-not $EnableNv2aTimerTrace) {
        Remove-Item Env:RECOMP_NV2A_TIMER_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableDmaAckTrace) {
        Remove-Item Env:RECOMP_DMA_ACK_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_DMA_ACK_TRACE_LIMIT -ErrorAction SilentlyContinue
    }
    if (-not $EnableNv2aPushbufferTrace) {
        Remove-Item Env:RECOMP_NV2A_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnablePgraphNotifyTrace) {
        Remove-Item Env:RECOMP_PB_NOTIFY_TRACE -ErrorAction SilentlyContinue
    }
    if (-not $EnableKeyboardInput) {
        Remove-Item Env:RECOMP_KEYBOARD -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_KEY_TRACE -ErrorAction SilentlyContinue
    }
    if (-not ($EnableHighVolumeSyncTrace -or $EnablePbSemaphoreTrace)) {
        Remove-Item Env:RECOMP_SYNC_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_PB_SEMAPHORE_TRACE -ErrorAction SilentlyContinue
        Remove-Item Env:RECOMP_PB_SEMAPHORE_TRACE_LIMIT -ErrorAction SilentlyContinue
    }
    if ([string]::IsNullOrWhiteSpace($GuestWatchAddress2)) {
        Remove-Item Env:RECOMP_WATCH2 -ErrorAction SilentlyContinue
    }

    $environmentSnapshot = @($settings.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value })
    foreach ($name in $loadingFocusTraceNames) {
        if ($name -eq 'RECOMP_LOAD_REPEAT_TRACE') {
            $effectiveValue = [Environment]::GetEnvironmentVariable($name, 'Process')
            $environmentSnapshot += "EFFECTIVE_ENV_$name=$(if ($null -eq $effectiveValue) { '<unset>' } else { $effectiveValue })"
        }
    }
    $environmentSnapshot += "EXECUTABLE_PATH=$traceExe"
    if ($DisableWaitTraceLog) {
        $environmentSnapshot += 'RECOMP_WAIT_TRACE_LOG=<disabled; no unmatched DCF4 wait reproduced>'
    }
    if ($DisableLoadPassTrace) {
        $environmentSnapshot += 'RECOMP_LOAD_PASS_TRACE=<disabled; use loader-state callbacks and separate file-open records>'
    }
    if ($DisableFileReadTrace) {
        $environmentSnapshot += 'RECOMP_FILE_READ_TRACE=<disabled; only explicitly targeted read completion traces may emit>'
    }
    if ($LoadingFocus) {
        $environmentSnapshot += 'LOADING_FOCUS=high-volume input/menu/DirectSound diagnostics disabled; controller profile and guest behavior unchanged'
    }
    $environmentSnapshot += "AUTO_PLATEAU_STOP=$PlateauSeconds seconds; requires unchanged mode-2 loader signature and framebuffer signature excluding the loading-indicator band"
    $environmentSnapshot += "AUTO_NV2A_PROGRESS_STOP=$Nv2aProgressPlateauSeconds seconds; requires NV2A IRQ signature rows; timer-boundary trace alone does not emit progress signatures"
    $environmentSnapshot += "FRAMEBUFFER_DUMP_INTERVAL=$FramebufferDumpInterval frames"
    $environmentSnapshot += 'RECOMP_PAD_SCRIPT=<unset; screen-gated live input only>'
    if (-not $EnableFileCallerTrace) {
        $environmentSnapshot += 'RECOMP_FILE_CALLER_TRACE=<unset; opt-in>'
    }
    if (-not $EnableFileIoDetailTrace) {
        $environmentSnapshot += 'RECOMP_FILE_IO_DETAIL_TRACE=<unset; opt-in>'
    }
    if (-not $EnableAllFileReadTrace) {
        $environmentSnapshot += 'RECOMP_FILE_READ_TRACE_ALL=<unset; first 220 and every 1000th read completion only>'
    }
    else {
        $environmentSnapshot += 'RECOMP_FILE_READ_TRACE_ALL=1; first 30,000 and every 1,000th read completion thereafter; count is reported in trace-counts.txt'
    }
    if (-not $EnableFileCopyTrace) {
        $environmentSnapshot += 'RECOMP_FILE_COPY_TRACE=<unset; opt-in>'
    }
    if ($EnableFileCopyReadTrace) {
        $environmentSnapshot += "RECOMP_FILE_COPY_READ_TARGET=$FileCopyReadTargetPath"
        $environmentSnapshot += "RECOMP_FILE_COPY_READ_LOG=$fileCopyReadLog; bounded copy-read rows use Win32 append output"
    }
    if ($EnableLoadStateCallbackTrace) {
        $environmentSnapshot += "RECOMP_LOAD_STATE_CALLBACK_LOG=$loadStateCallbackLog; loader-state rows use Win32 append output"
    }
    if (-not $EnableGpuDrawTrace) {
        $environmentSnapshot += 'RECOMP_GPU_DRAW_TRACE=<unset; periodic per-200-draw stderr output disabled>'
    }
    if (-not $EnableThreadStartTrace) {
        $environmentSnapshot += 'RECOMP_THREAD_START_TRACE=<unset; opt-in>'
    }
    if (-not $EnableThreadSuspendTrace) {
        $environmentSnapshot += 'RECOMP_THREAD_SUSPEND_TRACE=<unset; opt-in>'
    } else {
        $environmentSnapshot += "RECOMP_THREAD_SUSPEND_LOG=$threadSuspendLog; guest suspend/resume API events capped at 128 plus cap counters"
    }
    if (-not $EnablePreloadWorkerTrace) {
        $environmentSnapshot += 'RECOMP_PRELOAD_WORKER_TRACE=<unset; opt-in>'
    }
    if (-not $EnablePreloadAssetTrace) {
        $environmentSnapshot += 'RECOMP_PRELOAD_ASSET_TRACE=<unset; opt-in per-entry preload decisions>'
    }
    if ($EnableDsoundWriteWatch) {
        $environmentSnapshot += "RECOMP_DSOUND_WRITE_WATCH=1; log=$dsoundWriteWatchLog"
    }
    if (-not $EnableDsoundListTrace) {
        $environmentSnapshot += 'RECOMP_DS_LIST_TRACE=<unset; opt-in bounded list mutation records>'
    }
    if (-not $EnableDsoundSurfaceTrace) {
        $environmentSnapshot += 'RECOMP_DSOUND_SURFACE_TRACE=<unset; opt-in capped pixel/surface overlap records>'
    }
    if (-not $EnableMmioTrace) {
        $environmentSnapshot += 'RECOMP_MMIO_TRACE=<unset; opt-in>'
    }
    if (-not $EnableXbeSectionTrace) {
        $environmentSnapshot += 'RECOMP_XBE_SECTION_TRACE=<unset; opt-in>'
    }
    if (-not $EnableGuestFrameTrace) {
        $environmentSnapshot += 'RECOMP_GUEST_FRAME_TRACE=<unset; opt-in sampled stack frames>'
    }
    if (-not $EnableAllWaitTrace) {
        $environmentSnapshot += 'RECOMP_WAIT_TRACE_ALL_LIMIT=<unset; ordinary waits retain 64-record cap>'
    }
    if (-not $EnableDcf4ProducerTrace) {
        $environmentSnapshot += 'RECOMP_SB_DCF4_PRODUCER_TRACE=<unset; only enable for a reproduced DCF4 wait>'
    }
    if ($EnableDcf4StackTrace) {
        $environmentSnapshot += 'RECOMP_DCF4_STACK_TRACE=1; first 64 raw guest stack windows only (not an unwind)'
    }
    if ($EnableRingPollTrace) {
        $environmentSnapshot += "RECOMP_SB_RING_POLL_TRACE_FILE=$($settings.RECOMP_SB_RING_POLL_TRACE_FILE); create ring-poll.enable only after the loading screen turns black; records capped at 256, first 8 plus every 16777216th hit"
    } else {
        $environmentSnapshot += 'RECOMP_SB_RING_POLL_TRACE_FILE=<unset; opt-in bounded queue-cursor polling trace>'
    }
    if (-not $EnableDispatchGateTrace) {
        $environmentSnapshot += 'RECOMP_DISPATCH_GATE_TRACE=<unset; long dispatch-gate waits/holds are opt-in>'
    } else {
        $environmentSnapshot += 'RECOMP_DISPATCH_GATE_TRACE=1; cap=256; threshold=250ms'
    }
    if (-not $EnableGuestDeviceEntryTrace) {
        $environmentSnapshot += 'RECOMP_GUEST_DEVICE_ENTRY_TRACE=<unset; selector 0x3FFF table trace disabled>'
    } else {
        $environmentSnapshot += 'RECOMP_GUEST_DEVICE_ENTRY_TRACE=1; selector 0x3FFF only; sampled state changes; cap=256'
    }
    if (-not $EnableMemoryReserveTrace) {
        $environmentSnapshot += 'RECOMP_MEM_RESERVE_TRACE=<unset; large/failed reserve trace disabled>'
    } else {
        $environmentSnapshot += 'RECOMP_MEM_RESERVE_TRACE=1; failed or >=4 MiB requests only; cap=32'
    }
    if (-not $EnableDcf4GateTrace) {
        $environmentSnapshot += 'RECOMP_SB_DCF4_GATE_TRACE=<unset; bounded callback-gate trace disabled>'
    } else {
        $environmentSnapshot += 'RECOMP_SB_DCF4_GATE_TRACE=1; maximum 2,048 DCF4-GATE rows plus one cap marker'
    }
    if (-not $EnableDcf4CallbackTrace) {
        $environmentSnapshot += 'RECOMP_DCF4_CALLBACK_TRACE=<unset; callback detail is opt-in to avoid high-volume logging>'
    }
    if (-not ($EnableNv2aIrqTrace -or $EnableNv2aSignatureTrace)) {
        $environmentSnapshot += 'RECOMP_NV2A_IRQ_TRACE=<unset; per-interrupt detail is opt-in>'
    }
    if ($EnableNv2aSignatureTrace) {
        $environmentSnapshot += 'RECOMP_PGRAPH_ACK_TRACE=0; retains NV2A signatures without per-register ACK spam'
    }
    if (-not $EnableNv2aTimerTrace) {
        $environmentSnapshot += 'RECOMP_NV2A_TIMER_TRACE=<unset; opt-in 1 Hz vblank/IRQ/DPC boundaries>'
    }
    if ($DisableRasterPerfTrace) {
        $environmentSnapshot += 'RECOMP_RASTER_PERF_TRACE=<unset; worker timing disabled for low-output control run>'
    }
    if (-not $EnableDmaAckTrace) {
        $environmentSnapshot += 'RECOMP_DMA_ACK_TRACE=<unset; opt-in bounded DMA PUT/GET scan samples>'
    } else {
        $environmentSnapshot += "RECOMP_DMA_ACK_TRACE_LIMIT=$DmaAckTraceLimit; default cap 256 is raised for post-transition PUT/GET evidence"
    }
    if (-not $EnableNv2aPushbufferTrace) {
        $environmentSnapshot += 'RECOMP_NV2A_TRACE=<unset; per-PUT diagnostics are opt-in; PB execution remains enabled>'
    }
    if (-not $EnableHighVolumeSyncTrace) {
        $environmentSnapshot += 'RECOMP_SYNC_TRACE=<unset; opt-in high-volume>'
    }
    if (-not ($EnableHighVolumeSyncTrace -or $EnablePbSemaphoreTrace)) {
        $environmentSnapshot += 'RECOMP_PB_SEMAPHORE_TRACE=<unset; opt-in high-volume>'
    } else {
        $environmentSnapshot += "RECOMP_PB_SEMAPHORE_TRACE_LIMIT=$PbSemaphoreTraceLimit; default cap 256 is raised for post-transition semaphore evidence"
    }
    if ([string]::IsNullOrWhiteSpace($GuestWatchAddress2)) {
        $environmentSnapshot += 'RECOMP_WATCH2=<unset; opt-in second direct guest address>'
    }
    if (-not $EnableFileFailurePathTrace) {
        $environmentSnapshot += 'RECOMP_FILE_FAIL_PATH_TRACE=<unset; opt-in sampled failure paths>'
    }
    if (-not $EnableFileStatusTrace) {
        $environmentSnapshot += 'RECOMP_FILE_TRACE=<unset; per-open status and Win32 errors are opt-in>'
    }
    if (-not $EnableFileOpenPathTrace) {
        $environmentSnapshot += 'RECOMP_FILE_OPEN_PATH_TRACE=<unset; bounded successful paths are opt-in>'
    }
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

function Get-PlateauFramebufferHash {
    param([Parameter(Mandatory = $true)][string]$Path)

    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 54 -or $bytes[0] -ne 0x42 -or $bytes[1] -ne 0x4D) {
        throw "Framebuffer capture is not a complete BMP: $Path"
    }

    $width = [BitConverter]::ToInt32($bytes, 18)
    $height = [Math]::Abs([BitConverter]::ToInt32($bytes, 22))
    $bitsPerPixel = [BitConverter]::ToInt16($bytes, 28)
    if ($width -ne 640 -or $height -ne 480 -or $bitsPerPixel -ne 24) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
    }

    # The loading text and progress bar occupy this vertical band. Excluding
    # both prevents animation of the bar from resetting the plateau timer,
    # while the remaining screen still detects a mission frame or screen change.
    $stride = [int][Math]::Ceiling(($width * 3) / 4.0) * 4
    $stream = [IO.MemoryStream]::new()
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $stream.Write($bytes, 0, 54)
        for ($rawRow = 0; $rawRow -lt $height; $rawRow++) {
            $visibleY = $height - 1 - $rawRow
            if ($visibleY -ge 215 -and $visibleY -lt 295) { continue }
            $offset = 54 + $rawRow * $stride
            $stream.Write($bytes, $offset, $stride)
        }
        return ([BitConverter]::ToString($sha.ComputeHash($stream.ToArray()))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

$guestWriteBreakpoint = $null
if ($EnableGuestWriteBreakpoint) {
    $watchLog = Join-Path $runDirectory 'guest-write-breakpoint.log'
    $watchArguments = @(
        [string]$process.Id,
        $GuestWriteBreakpointAddress,
        $GuestMemoryOffset,
        ('"{0}"' -f $watchLog)
    )
    $guestWriteBreakpoint = Start-Process -FilePath $guestWriteBreakpointExe `
        -ArgumentList $watchArguments -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runDirectory 'guest-write-breakpoint.stdout.log') `
        -RedirectStandardError (Join-Path $runDirectory 'guest-write-breakpoint.stderr.log')
    $attachDeadline = [DateTime]::UtcNow.AddSeconds(10)
    $watchArmed = $false
    while ([DateTime]::UtcNow -lt $attachDeadline -and -not $guestWriteBreakpoint.HasExited) {
        if (Test-Path -LiteralPath $watchLog -PathType Leaf) {
            $watchArmed = Select-String -LiteralPath $watchLog -Pattern '^ARMED ' -Quiet
            if ($watchArmed) { break }
        }
        Start-Sleep -Milliseconds 100
        $guestWriteBreakpoint.Refresh()
    }
    if (-not $watchArmed) {
        Write-Warning "Hardware breakpoint did not arm within 10 seconds. See $watchLog; the game run will continue without it."
        if (-not $guestWriteBreakpoint.HasExited) {
            Stop-Process -Id $guestWriteBreakpoint.Id -Force -ErrorAction SilentlyContinue
        }
        $guestWriteBreakpoint = $null
    }
}

"Started ProducerTrace PID $($process.Id)"
"Run logs: $runDirectory"
"Existing saves: $saveRoot"
"Screen-gated input file (created empty): $padLive"
$externalWatchdogTriggered = $false
$plateauWatchdogTriggered = $false
$uiPlateauWatchdogTriggered = $false
$nv2aProgressWatchdogTriggered = $false
$crashExceptionWatchdogTriggered = $false
$crashExceptionRecordAtStop = $null
$dcf4WaitHangTriggered = $false
$dcf4WaitDumpPath = $null
$plateauSignatureAtStop = $null
$lastPlateauSignature = $null
$plateauStableSince = $null
$lastUiSignature = $null
$uiStableSince = $null
$lastNv2aProgressSignature = $null
$nv2aProgressStableSince = $null
$nv2aProgressSignatureAtStop = $null
$lastDcf4WaitSignature = $null
$dcf4WaitStableSince = $null
$runStorageBudgetBytes = [long]$RunStorageBudgetMiB * 1MB
$storageBudgetTriggered = $false
$storageBytesAtStop = 0L
$storageAllocatedBytesAtStop = -1L
$lastStorageCheck = [DateTime]::UtcNow
$watchdogTimer = [Diagnostics.Stopwatch]::StartNew()
while (-not $process.WaitForExit(10000)) {
    if ($watchdogTimer.Elapsed.TotalSeconds -ge $WatchdogSeconds) {
        $externalWatchdogTriggered = $true
        Write-Warning "External watchdog reached $WatchdogSeconds seconds; terminating diagnostic PID $($process.Id)."
        try { $process.Kill() }
        catch [InvalidOperationException] { }
        $process.WaitForExit()
        break
    }

    # Sum both logical length and actual allocated bytes at a low frequency.
    # The logical cap is conservative; the allocated-byte cap also protects
    # against unexpectedly dense evidence if a trace's own cap is ineffective.
    if (([DateTime]::UtcNow - $lastStorageCheck).TotalSeconds -ge 10) {
        $lastStorageCheck = [DateTime]::UtcNow
        $storageBytes = 0L
        $storageAllocatedBytes = -1L
        try {
            $storageBytes = [long]((Get-ChildItem -LiteralPath $runDirectory -File -Force -Recurse |
                Measure-Object -Property Length -Sum).Sum)
        }
        catch { Write-Warning "Could not measure current run storage: $($_.Exception.Message)" }
        try { $storageAllocatedBytes = Get-RunDirectoryAllocatedBytes -Path $runDirectory }
        catch { Write-Warning "Could not measure allocated run storage: $($_.Exception.Message)" }
        if ($storageBytes -ge $runStorageBudgetBytes -or
            $storageAllocatedBytes -ge $runStorageBudgetBytes) {
            $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
            $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
            if ($liveProcess -and $livePath -and [string]::Equals(
                    [IO.Path]::GetFullPath($livePath), [IO.Path]::GetFullPath($traceExe),
                    [StringComparison]::OrdinalIgnoreCase)) {
                $storageBudgetTriggered = $true
                $storageBytesAtStop = $storageBytes
                $storageAllocatedBytesAtStop = $storageAllocatedBytes
                $budgetDumpPath = Join-Path $runDirectory 'storage-budget-stall.dmp'
                $dumpStatus = 'capture failed'
                try {
                    $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                    if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                        $null = & $dumpScript -ProcessId $process.Id -OutputPath $budgetDumpPath
                        if ((Test-Path -LiteralPath $budgetDumpPath -PathType Leaf) -and
                                (Get-Item -LiteralPath $budgetDumpPath).Length -gt 0) {
                            $dumpStatus = 'captured'
                        }
                    }
                }
                catch { $dumpStatus = "capture failed: $($_.Exception.Message)" }
                @(
                    "Stopped diagnostic PID $($process.Id) at $([DateTime]::UtcNow.ToString('o')) after reaching the $RunStorageBudgetMiB MiB per-run evidence budget.",
                    "Measured logical evidence bytes: $storageBytes",
                    "Measured allocated evidence bytes: $storageAllocatedBytes",
                    "Verified executable: $livePath",
                    "External thread snapshot: $dumpStatus$(if ($dumpStatus -eq 'captured') { ' (' + $budgetDumpPath + ')' })"
                ) | Set-Content -LiteralPath (Join-Path $runDirectory 'storage-budget-stop.txt') -Encoding UTF8
                Write-Warning "Per-run storage budget reached; stopping only verified diagnostic PID $($process.Id)."
                $process.Kill()
                $process.WaitForExit()
                break
            }
            Write-Warning 'Run storage budget reached, but the live executable path did not verify as this run. Leaving the process untouched.'
        }
    }

    # A fatal guest exception can terminate a worker while the host process and
    # NV2A timer threads keep running. Detect the runtime's crash records and
    # stop only this verified child instead of waiting for a graphics plateau.
    # The runtime also logs the intentional 0x406D1388 thread-name exception;
    # only C000-status exceptions and the explicit access-violation marker count.
    $fatalCrashRecord = $null
    if (Test-Path -LiteralPath $stderrLog -PathType Leaf) {
        try {
            $fatalCrashRecord = Get-Content -LiteralPath $stderrLog -Tail 2000 -ErrorAction Stop |
                Where-Object {
                    $_ -match '\[CRASH\] Access violation' -or
                    $_ -match '\[CRASH-EXCEPTION\].*code=0xC000[0-9A-Fa-f]{4}'
                } |
                Select-Object -Last 1
        }
        catch { $fatalCrashRecord = $null }
    }
    if ($fatalCrashRecord) {
        $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
        if ($liveProcess -and $livePath -and
                [string]::Equals(
                    [IO.Path]::GetFullPath($livePath),
                    [IO.Path]::GetFullPath($traceExe),
                    [StringComparison]::OrdinalIgnoreCase)) {
            $crashExceptionWatchdogTriggered = $true
            $crashExceptionRecordAtStop = $fatalCrashRecord
            $exceptionDumpPath = Join-Path $runDirectory 'exception-stall.dmp'
            $dumpStatus = 'capture failed'
            try {
                $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                    $dumpJob = Start-Job -ScriptBlock {
                        param($ScriptPath, $TargetPid, $TargetPath)
                        & $ScriptPath -ProcessId $TargetPid -OutputPath $TargetPath | Out-Null
                    } -ArgumentList $dumpScript, $process.Id, $exceptionDumpPath
                    $dumpCompleted = Wait-Job -Job $dumpJob -Timeout 10
                    if ($dumpCompleted) {
                        Receive-Job -Job $dumpJob -ErrorAction Stop | Out-Null
                        if ((Test-Path -LiteralPath $exceptionDumpPath -PathType Leaf) -and
                                (Get-Item -LiteralPath $exceptionDumpPath).Length -gt 0) {
                            $dumpStatus = 'captured'
                        }
                    } else {
                        Stop-Job -Job $dumpJob -ErrorAction SilentlyContinue
                        $dumpStatus = 'capture timed out after 10 seconds'
                    }
                    Remove-Job -Job $dumpJob -Force -ErrorAction SilentlyContinue
                }
            }
            catch {
                $dumpStatus = "capture failed: $($_.Exception.Message)"
                $exceptionDumpPath = $null
            }
            @(
                "Stopped diagnostic PID $($process.Id) at $([DateTime]::UtcNow.ToString('o')) after a fatal runtime exception record.",
                "Verified executable: $livePath",
                "Exception record: $fatalCrashRecord",
                "External thread snapshot: $dumpStatus$(if ($exceptionDumpPath) { ' (' + $exceptionDumpPath + ')' })"
            ) | Set-Content -LiteralPath (Join-Path $runDirectory 'exception-stop.txt') -Encoding UTF8
            Write-Warning "Fatal runtime exception detected; stopping only verified diagnostic PID $($process.Id)."
            $process.Kill()
            $process.WaitForExit()
            break
        }
    }

    # Begin plateau detection only after the mode-2 loading scan is active and
    # a framebuffer capture exists. A stop requires both the loader's stable
    # branch/pair signature and the visible frame hash to remain unchanged.
    $latestPass = $null
    if (Test-Path -LiteralPath $stderrLog -PathType Leaf) {
        try {
            $latestPass = Get-Content -LiteralPath $stderrLog -Tail 2000 -ErrorAction Stop |
                Where-Object { $_ -match '\[LOAD-PASS-OUT\].*mode=0002.*branch=scan' } |
                Select-Object -Last 1
        }
        catch { $latestPass = $null }
    }
    $frameExists = Test-Path -LiteralPath $framePath -PathType Leaf
    if ($latestPass -and $frameExists) {
        $passMatch = [regex]::Match(
            $latestPass,
            'mode=(?<mode>[0-9A-F]+).*range=(?<range>[0-9]+\.\.[0-9]+).*last_index=(?<index>[0-9]+).*branch=(?<branch>[^ ]+).*result=(?<result>[0-9A-F]+).*pair=(?<pairA>[0-9A-F]+)/(?<pairB>[0-9A-F]+)')
        if ($passMatch.Success) {
            try {
                $frameHash = Get-PlateauFramebufferHash -Path $framePath
                # Exclude tick and pass number so a normal polling loop does
                # not look like forward loader progress on every iteration.
                $currentPlateauSignature = 'mode={0}|range={1}|index={2}|branch={3}|result={4}|pair={5}/{6}|frame={7}' -f @(
                    $passMatch.Groups['mode'].Value,
                    $passMatch.Groups['range'].Value,
                    $passMatch.Groups['index'].Value,
                    $passMatch.Groups['branch'].Value,
                    $passMatch.Groups['result'].Value,
                    $passMatch.Groups['pairA'].Value,
                    $passMatch.Groups['pairB'].Value,
                    $frameHash)
                $now = [DateTime]::UtcNow
                if ($currentPlateauSignature -ne $lastPlateauSignature) {
                    $lastPlateauSignature = $currentPlateauSignature
                    $plateauStableSince = $now
                }
                elseif ($null -ne $plateauStableSince -and
                        ($now - $plateauStableSince).TotalSeconds -ge $PlateauSeconds) {
                    $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                    $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
                    if ($liveProcess -and $livePath -and
                            [string]::Equals(
                                [IO.Path]::GetFullPath($livePath),
                                [IO.Path]::GetFullPath($traceExe),
                                [StringComparison]::OrdinalIgnoreCase)) {
                        $plateauWatchdogTriggered = $true
                        $plateauSignatureAtStop = $currentPlateauSignature
                        $plateauDumpPath = Join-Path $runDirectory 'mode2-plateau-stall.dmp'
                        $plateauDumpStatus = 'capture failed'
                        try {
                            $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                            if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                                $null = & $dumpScript -ProcessId $process.Id -OutputPath $plateauDumpPath
                                if ((Test-Path -LiteralPath $plateauDumpPath -PathType Leaf) -and
                                        (Get-Item -LiteralPath $plateauDumpPath).Length -gt 0) {
                                    $plateauDumpStatus = 'captured'
                                }
                            }
                        }
                        catch {
                            $plateauDumpStatus = "capture failed: $($_.Exception.Message)"
                            $plateauDumpPath = $null
                        }
                        $stopRecord = @(
                            "Stopped diagnostic PID $($process.Id) at $($now.ToString('o')) after $PlateauSeconds seconds with unchanged mode-2 loader state and framebuffer hash.",
                            "Verified executable: $livePath",
                            "Signature: $currentPlateauSignature",
                            "Thread snapshot: $plateauDumpStatus$(if ($plateauDumpPath) { ' (' + $plateauDumpPath + ')' })"
                        )
                        $stopRecord | Set-Content -LiteralPath (Join-Path $runDirectory 'plateau-stop.txt') -Encoding UTF8
                        Write-Warning "Plateau watchdog verified PID $($process.Id) belongs to this diagnostic run and is stopping it after $PlateauSeconds seconds without loader or framebuffer progress."
                        $process.Kill()
                        $process.WaitForExit()
                        break
                    }
                    else {
                        Write-Warning "Plateau detected, but the live process path did not verify as this run's executable. Leaving it untouched."
                        $plateauStableSince = $now
                    }
                }
            }
            catch { }
        }
        else {
            $lastPlateauSignature = $null
            $plateauStableSince = $null
        }
    }
    else {
        $lastPlateauSignature = $null
        $plateauStableSince = $null
    }

    # Catch screen/menu stalls before the mode-2 loader starts. Each accepted
    # live-input line changes the transcript length; each screen transition
    # changes the framebuffer signature. Only the child launched above can be
    # stopped, after its current executable path has been revalidated.
    if ($frameExists) {
        try {
            $uiFrameHash = Get-PlateauFramebufferHash -Path $framePath
            $padLength = (Get-Item -LiteralPath $padLive).Length
            $uiSignature = '{0}|input-bytes={1}' -f $uiFrameHash, $padLength
            $now = [DateTime]::UtcNow
            if ($uiSignature -ne $lastUiSignature) {
                $lastUiSignature = $uiSignature
                $uiStableSince = $now
            }
            elseif ($null -ne $uiStableSince -and
                    ($now - $uiStableSince).TotalSeconds -ge $UiPlateauSeconds) {
                $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
                if ($liveProcess -and $livePath -and
                        [string]::Equals(
                            [IO.Path]::GetFullPath($livePath),
                            [IO.Path]::GetFullPath($traceExe),
                            [StringComparison]::OrdinalIgnoreCase)) {
                    $uiPlateauWatchdogTriggered = $true
                    $uiPlateauDumpPath = Join-Path $runDirectory 'ui-plateau-stall.dmp'
                    $dumpStatus = 'capture failed'
                    try {
                        $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                        if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                            $null = & $dumpScript -ProcessId $process.Id -OutputPath $uiPlateauDumpPath
                            if (Test-Path -LiteralPath $uiPlateauDumpPath -PathType Leaf) {
                                $dumpStatus = 'captured'
                            }
                        }
                    }
                    catch {
                        $dumpStatus = "capture failed: $($_.Exception.Message)"
                        $uiPlateauDumpPath = $null
                    }
                    @(
                        "Stopped diagnostic PID $($process.Id) at $($now.ToString('o')) after $UiPlateauSeconds seconds without a framebuffer or live-input change.",
                        "Verified executable: $livePath",
                        "Signature: $uiSignature",
                        "Thread snapshot: $dumpStatus$(if ($uiPlateauDumpPath) { ' (' + $uiPlateauDumpPath + ')' })"
                    ) | Set-Content -LiteralPath (Join-Path $runDirectory 'ui-plateau-stop.txt') -Encoding UTF8
                    Write-Warning "UI plateau watchdog verified PID $($process.Id) belongs to this diagnostic run and is stopping it after $UiPlateauSeconds seconds without screen or input progress."
                    $process.Kill()
                    $process.WaitForExit()
                    break
                }
                else {
                    Write-Warning "UI plateau detected, but the live process path did not verify as this run's executable. Leaving it untouched."
                    $uiStableSince = $now
                }
            }
        }
        catch { }
    }
    else {
        $lastUiSignature = $null
        $uiStableSince = $null
    }

    # A changing loading animation can keep the framebuffer watchdog alive
    # even when the GPU callback/fence state has stopped. When NV2A telemetry
    # is enabled, stop this diagnostic child if the guest frame/counter state
    # remains unchanged for the configured interval. Callback count is included
    # so ordinary progress at a static menu does not look stalled.
    if (($EnableNv2aIrqTrace -or $EnableNv2aSignatureTrace) -and
            (Test-Path -LiteralPath $stderrLog -PathType Leaf)) {
        $latestNv2aProgress = $null
        try {
            $latestNv2aProgress = Get-Content -LiteralPath $stderrLog -Tail 2000 -ErrorAction Stop |
                Where-Object { $_ -match '\[NV2A-TICK\]' } |
                Select-Object -Last 1
        }
        catch { $latestNv2aProgress = $null }

        if ($latestNv2aProgress -and
                $latestNv2aProgress -match 'callbacks=(?<callbacks>[0-9]+).*frame=(?<frame>[0-9A-F]+) counter=(?<counter>[0-9A-F]+) target=(?<target>[0-9A-F]+) fence=(?<fence>[0-9A-F]+)') {
            $currentNv2aProgressSignature = 'callbacks={0}|frame={1}|counter={2}|target={3}|fence={4}' -f @(
                $Matches.callbacks, $Matches.frame, $Matches.counter, $Matches.target, $Matches.fence)
            $now = [DateTime]::UtcNow
            if ($currentNv2aProgressSignature -ne $lastNv2aProgressSignature) {
                $lastNv2aProgressSignature = $currentNv2aProgressSignature
                $nv2aProgressStableSince = $now
            }
            elseif ($null -ne $nv2aProgressStableSince -and
                    ($now - $nv2aProgressStableSince).TotalSeconds -ge $Nv2aProgressPlateauSeconds) {
                $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
                if ($liveProcess -and $livePath -and
                        [string]::Equals(
                            [IO.Path]::GetFullPath($livePath),
                            [IO.Path]::GetFullPath($traceExe),
                            [StringComparison]::OrdinalIgnoreCase)) {
                    $nv2aProgressWatchdogTriggered = $true
                    $nv2aProgressSignatureAtStop = $currentNv2aProgressSignature
                    $progressDumpPath = Join-Path $runDirectory 'nv2a-progress-stall.dmp'
                    $dumpStatus = 'capture failed'
                    try {
                        $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                        if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                            $null = & $dumpScript -ProcessId $process.Id -OutputPath $progressDumpPath
                            if (Test-Path -LiteralPath $progressDumpPath -PathType Leaf) {
                                $dumpStatus = 'captured'
                            }
                        }
                    }
                    catch {
                        $dumpStatus = "capture failed: $($_.Exception.Message)"
                        $progressDumpPath = $null
                    }
                    @(
                        "Stopped diagnostic PID $($process.Id) at $($now.ToString('o')) after $Nv2aProgressPlateauSeconds seconds without NV2A callback/frame/counter/fence progress.",
                        "Verified executable: $livePath",
                        "Last NV2A progress signature: $currentNv2aProgressSignature",
                        "Thread snapshot: $dumpStatus$(if ($progressDumpPath) { ' (' + $progressDumpPath + ')' })"
                    ) | Set-Content -LiteralPath (Join-Path $runDirectory 'nv2a-progress-stop.txt') -Encoding UTF8
                    Write-Warning "NV2A progress watchdog verified PID $($process.Id) belongs to this diagnostic run and is stopping it after $Nv2aProgressPlateauSeconds seconds without guest graphics progress."
                    $process.Kill()
                    $process.WaitForExit()
                    break
                }
                else {
                    Write-Warning 'NV2A progress stall detected, but the live process path did not verify as this run executable. Leaving it untouched.'
                    $nv2aProgressStableSince = $now
                }
            }
        }
        else {
            $lastNv2aProgressSignature = $null
            $nv2aProgressStableSince = $null
        }
    }

    # A DCF4 wait can remain blocked while periodic framebuffer captures or
    # unrelated trace activity continue. When producer tracing is enabled,
    # detect a wait-before record with no later wait-after and stop only this
    # verified diagnostic child after a bounded interval.
    if ($EnableDcf4ProducerTrace -and
            (Test-Path -LiteralPath $stderrLog -PathType Leaf)) {
        $lastDcf4Sync = $null
        try {
            $lastDcf4Sync = Get-Content -LiteralPath $stderrLog -Tail 5000 -ErrorAction Stop |
                Where-Object { $_ -match '\[RASTER-SYNC\].*stage=wait-(before|after).*object=0021DCF4' } |
                Select-Object -Last 1
        }
        catch { $lastDcf4Sync = $null }

        if ($lastDcf4Sync -and $lastDcf4Sync -match 'stage=wait-before') {
            $now = [DateTime]::UtcNow
            if ($lastDcf4Sync -ne $lastDcf4WaitSignature) {
                $lastDcf4WaitSignature = $lastDcf4Sync
                $dcf4WaitStableSince = $now
            }
            elseif ($null -ne $dcf4WaitStableSince -and
                    ($now - $dcf4WaitStableSince).TotalSeconds -ge $Dcf4WaitHangSeconds) {
                $liveProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                $livePath = if ($liveProcess) { $liveProcess.Path } else { $null }
                if ($liveProcess -and $livePath -and
                        [string]::Equals(
                            [IO.Path]::GetFullPath($livePath),
                            [IO.Path]::GetFullPath($traceExe),
                            [StringComparison]::OrdinalIgnoreCase)) {
                    $dcf4WaitHangTriggered = $true
                    $dcf4WaitDumpPath = Join-Path $runDirectory 'dcf4-stall.dmp'
                    $dumpStatus = 'capture failed'
                    try {
                        $dumpScript = Join-Path $PSScriptRoot 'Capture-ProducerTraceDump.ps1'
                        if (Test-Path -LiteralPath $dumpScript -PathType Leaf) {
                            $null = & $dumpScript -ProcessId $process.Id -OutputPath $dcf4WaitDumpPath
                            if (Test-Path -LiteralPath $dcf4WaitDumpPath -PathType Leaf) {
                                $dumpStatus = 'captured'
                            }
                        }
                    }
                    catch {
                        $dumpStatus = "capture failed: $($_.Exception.Message)"
                        $dcf4WaitDumpPath = $null
                    }
                    @(
                        "Stopped diagnostic PID $($process.Id) at $($now.ToString('o')) after $Dcf4WaitHangSeconds seconds without a DCF4 wait return.",
                        "Verified executable: $livePath",
                        "Last DCF4 synchronization record: $lastDcf4Sync",
                        "Thread snapshot: $dumpStatus$(if ($dcf4WaitDumpPath) { ' (' + $dcf4WaitDumpPath + ')' })"
                    ) | Set-Content -LiteralPath (Join-Path $runDirectory 'dcf4-wait-stop.txt') -Encoding UTF8
                    Write-Warning "DCF4 wait watchdog verified PID $($process.Id) belongs to this diagnostic run and is stopping it after $Dcf4WaitHangSeconds seconds without a wait return."
                    $process.Kill()
                    $process.WaitForExit()
                    break
                }
                else {
                    Write-Warning "DCF4 wait stall detected, but the live process path did not verify as this run's executable. Leaving it untouched."
                    $dcf4WaitStableSince = $now
                }
            }
        }
        else {
            $lastDcf4WaitSignature = $null
            $dcf4WaitStableSince = $null
        }
    }
}
$watchdogTimer.Stop()
if ($guestWriteBreakpoint) {
    try { $guestWriteBreakpoint.WaitForExit(5000) | Out-Null } catch { }
    if (-not $guestWriteBreakpoint.HasExited) {
        Stop-Process -Id $guestWriteBreakpoint.Id -Force -ErrorAction SilentlyContinue
    }
}
if ($useAsyncTraceRelay) {
    'Finalizing the asynchronous log relay after the diagnostic process exited.'
    $relayResult = [ProducerTraceAsyncRelay]::WaitForExit($process, 5000)
    "Diagnostic process exit code: $($relayResult.ExitCode)"
    "External watchdog terminated process: $externalWatchdogTriggered"
    "Dropped trace lines: stdout=$($relayResult.DroppedStdoutLines), stderr=$($relayResult.DroppedStderrLines)"
    "Log writer stopped: $($relayResult.WriterStopped)"
    if ($relayResult.WriterError) { "Log writer error: $($relayResult.WriterError)" }

    $traceMarkers = @(
        '[PILOT-LIST-CB]', '[PILOT-ROW-POST]', '[SB-SNAPSHOT]', '[LOAD-STATE-CB]',
        '[SB-INPUT-DISPATCH]', '[SB-INPUT-PRED]', '[SB-EDGE-CONSUME]',
        '[MENU-DISPATCH]', '[MENU-RESOURCE]', '[MENU-CALLBACK-GATE]',
        '[MENU-OBJECT-GATE]', '[TITLE-ROUTE-QUERY]', '[THREAD-START]',
        '[PRELOAD-WORKER-ROUTE]', '[FILE-PRELOAD-ENTER]',
        '[PRELOAD-MODE-REQUEST]', '[PRELOAD-WORKER-SCHEDULE]', '[LOAD-OBJECT-INIT]',
        '[LOAD-SCHED-GATE]',
        '[FILE-PRELOAD-RETURN]', '[FILE-COPY-ENTER]', '[FILE-COPY-RETURN]',
        '[FILE-IO]', '[FILE-CALL]', '[FILE-MISS-PATH]',
        '[FILE-LIFECYCLE-OPEN-CAPPED]', '[FILE-LIFECYCLE-OPEN]',
        '[FILE-LIFECYCLE-CLOSE]', '[FILE-OPEN-TARGET-BEGIN]',
        '[FILE-OPEN-TARGET-DONE]', '[FILE-READ-TARGET-BEGIN]',
        '[FILE-READ-TARGET-DONE]', '[LOAD-HELPER]', '[LOAD-HELPER-BRANCH]',
        '[READ]',
        '[LOAD-HELPER-RET]', '[LOAD-HELPER-CALLBACK]', '[LOAD-HELPER-STATE]',
        '[LOAD-STACK]', '[LOAD-RENDER]',
        '[LOAD-PASS-IN]', '[LOAD-PASS-OUT]', '[LOAD-REPEAT]',
        '[DCF4-CB]', '[DCF4-CB-CAP]', '[DCF4-GATE]', '[DCF4-GATE-CAP]',
        '[DCF4-RESET-CAP]', '[DCF4-OUTER]',
        '[DCF4-OUTER-POLL]', '[DCF4-OUTER-CAP]', '[DCF4-OUTER-POLL-CAP]',
        '[DISPATCH-GATE]', '[DISPATCH-GATE-CAP]',
        '[DEVICE-ENTRY]', '[DEVICE-ENTRY-CAP]', '[GUEST-STACK-RAW]',
        '[MEM-ALLOC]', '[MEM-ALLOC-CAP]',
        '[SB-DMA-PUBLISH]', '[SB-DMA-PUBLISH-CAP]', '[SB-DCF4-MARKER]',
        '[SB-DCF4-MARKER-CAP]', '[SB-PFB-POLL]', '[SB-PFB-POLL-CAP]',
        '[WAIT-DCF4-CAP]', '[WAIT-DCE4-CAP]', '[RASTER-SYNC]', '[SYNC-PBSEM]',
        '[DMA-ACK]', '[PB-SEM]', '[PB-SEM-METHOD]',
        '[NV2A-TICK]', '[RASTER-PERF]', '[PGRAPH-NOTIFY]', '[XID0]', '[XID-DMA0]'
    )
    $markerPattern = ($traceMarkers | Sort-Object Length -Descending |
        ForEach-Object { [regex]::Escape($_) }) -join '|'
    $markerRegex = [regex]::new(
        $markerPattern,
        [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $markerCounts = [ordered]@{}
    $traceLimitHitCount = 0
    $traceLimitHitRows = [System.Collections.Generic.List[string]]::new()
    foreach ($marker in $traceMarkers) { $markerCounts[$marker] = 0 }
    if ($relayResult.WriterStopped) {
        # Loader-state callbacks can write to their own bounded append-only
        # channel rather than stderr. Count that channel as well so
        # trace-counts.txt and MarkerCounts reflect records that were actually
        # emitted, even when the callback trace is disabled in another run.
        foreach ($traceFile in @(Get-ChildItem -LiteralPath $runDirectory -Filter '*.log' -File -Recurse -ErrorAction SilentlyContinue)) {
            $tracePath = $traceFile.FullName
            $reader = [IO.StreamReader]::new($tracePath)
            try {
                while ($null -ne ($line = $reader.ReadLine())) {
                    foreach ($match in $markerRegex.Matches($line)) {
                        $markerCounts[$match.Value]++
                    }
                    # Count explicit cap/overflow markers and nonzero drop
                    # counters only. Ordinary trace fields such as
                    # "dropped=0" are data, not evidence that a limit fired.
                    if ($line -match '^\[[A-Z0-9_-]*(?:CAP|CAPPED|OVERFLOW)\](?:\s|$)' -or
                        $line -match '(?i)\blimit reached\b|\boverflow\b|\bdropped=(?:[1-9][0-9]*)\b') {
                        $traceLimitHitCount++
                        if ($traceLimitHitRows.Count -lt 64) { $traceLimitHitRows.Add($line) }
                    }
                }
            }
            finally { $reader.Dispose() }
        }
    }
    $countsComplete = $relayResult.WriterStopped -and
        $relayResult.DroppedStderrLines -eq 0 -and
        [string]::IsNullOrEmpty($relayResult.WriterError)
    $storageBytesAtExit = 0L
    try {
        $storageBytesAtExit = [long]((Get-ChildItem -LiteralPath $runDirectory -File -Force -Recurse |
            Measure-Object -Property Length -Sum).Sum)
    }
    catch { Write-Warning "Could not measure final run storage: $($_.Exception.Message)" }
    $fileReadTargetSummary = [ordered]@{
        Limit = if ($FileReadTargetPaths.Count -gt 0) { $FileReadTargetLimit } else { $null }
        EnterCount = 0
        DoneCount = 0
        CapMarkerCount = 0
        CapRows = [System.Collections.Generic.List[string]]::new()
        HighestReadCountByPath = [ordered]@{}
    }
    if ($FileReadTargetPaths.Count -gt 0 -and (Test-Path -LiteralPath $fileReadTargetLog -PathType Leaf)) {
        foreach ($targetLine in [IO.File]::ReadLines($fileReadTargetLog)) {
            if ($targetLine -match '^\[FILE-READ-TARGET-ENTER\].*?\bn=(\d+).*?\bpath=(.*?)\s+offset_valid=') {
                $fileReadTargetSummary.EnterCount++
                $targetN = [int]$Matches[1]
                $targetPath = $Matches[2]
                if (-not $fileReadTargetSummary.HighestReadCountByPath.Contains($targetPath) -or
                    $targetN -gt $fileReadTargetSummary.HighestReadCountByPath[$targetPath]) {
                    $fileReadTargetSummary.HighestReadCountByPath[$targetPath] = $targetN
                }
            } elseif ($targetLine -match '^\[FILE-READ-TARGET-DONE\]') {
                $fileReadTargetSummary.DoneCount++
            } elseif ($targetLine -match '^\[FILE-READ-TARGET-CAP\]') {
                $fileReadTargetSummary.CapMarkerCount++
                if ($fileReadTargetSummary.CapRows.Count -lt 32) {
                    $fileReadTargetSummary.CapRows.Add($targetLine)
                }
            }
        }
    }
    $threadSuspendSummary = [ordered]@{
        Enabled = [bool]$EnableThreadSuspendTrace
        Cap = 128
        EventCount = 0
        CapMarkerCount = 0
        CapRows = [System.Collections.Generic.List[string]]::new()
    }
    if ($EnableThreadSuspendTrace -and (Test-Path -LiteralPath $threadSuspendLog -PathType Leaf)) {
        foreach ($suspendLine in [IO.File]::ReadLines($threadSuspendLog)) {
            if ($suspendLine -match '^\[THREAD-SUSPEND\]') {
                $threadSuspendSummary.EventCount++
            } elseif ($suspendLine -match '^\[THREAD-SUSPEND-CAP\]') {
                $threadSuspendSummary.CapMarkerCount++
                if ($threadSuspendSummary.CapRows.Count -lt 16) {
                    $threadSuspendSummary.CapRows.Add($suspendLine)
                }
            }
        }
    }
    $watchdogSnapshotPresent = Test-Path -LiteralPath $watchdogSnapshotLog -PathType Leaf
    $watchdogSnapshotBytes = if ($watchdogSnapshotPresent) {
        (Get-Item -LiteralPath $watchdogSnapshotLog).Length
    } else { 0L }
    $watchdogSnapshotEmitted = if ($watchdogSnapshotPresent) { 1 } else { 0 }
    $watchdogSnapshotMissing = $WatchdogSnapshotSeconds -gt 0 -and -not $watchdogSnapshotPresent
    $resultManifest = Get-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Raw |
        ConvertFrom-Json
    $resultManifest | Add-Member -NotePropertyName RunResult -NotePropertyValue ([ordered]@{
        ProcessExitCode = $relayResult.ExitCode
        ExternalWatchdogTriggered = $externalWatchdogTriggered
        PlateauWatchdogTriggered = $plateauWatchdogTriggered
        UiPlateauWatchdogTriggered = $uiPlateauWatchdogTriggered
        Dcf4WaitHangWatchdogTriggered = $dcf4WaitHangTriggered
        Nv2aProgressWatchdogTriggered = $nv2aProgressWatchdogTriggered
        CrashExceptionWatchdogTriggered = $crashExceptionWatchdogTriggered
        CrashExceptionRecordAtStop = $crashExceptionRecordAtStop
        Dcf4WaitDumpPath = $dcf4WaitDumpPath
        PlateauSeconds = $PlateauSeconds
        UiPlateauSeconds = $UiPlateauSeconds
        WatchdogSnapshotSeconds = $WatchdogSnapshotSeconds
        WatchdogSnapshotPresent = $watchdogSnapshotPresent
        WatchdogSnapshotEmitted = $watchdogSnapshotEmitted
        WatchdogSnapshotCap = 1
        WatchdogSnapshotDropped = 0
        WatchdogSnapshotMissingAtExit = $watchdogSnapshotMissing
        WatchdogSnapshotBytes = $watchdogSnapshotBytes
        Dcf4WaitHangSeconds = $Dcf4WaitHangSeconds
        Nv2aProgressPlateauSeconds = $Nv2aProgressPlateauSeconds
        Nv2aProgressSignatureAtStop = $nv2aProgressSignatureAtStop
        PlateauSignatureAtStop = $plateauSignatureAtStop
        DroppedStdoutLines = $relayResult.DroppedStdoutLines
        DroppedStderrLines = $relayResult.DroppedStderrLines
        LogWriterStopped = $relayResult.WriterStopped
        LogWriterError = $relayResult.WriterError
        NoRelayDrops = ($relayResult.DroppedStdoutLines -eq 0 -and
            $relayResult.DroppedStderrLines -eq 0)
        MarkerCountsComplete = $countsComplete
        MarkerCounts = $markerCounts
        RunStorageBudgetMiB = $RunStorageBudgetMiB
        RunStorageBudgetTriggered = $storageBudgetTriggered
        RunStorageBytesAtStop = $storageBytesAtStop
        RunStorageAllocatedBytesAtStop = $storageAllocatedBytesAtStop
        RunStorageBytesAtExit = $storageBytesAtExit
        RunStorageAllocatedBytesAtExit = -1L
        ClosedEvidenceAllocatedBytesBeforeCompression = -1L
        ClosedEvidenceAllocatedBytesAfterCompression = -1L
        ClosedEvidenceAllocatedBytesReclaimed = 0L
        TraceLimitHitCount = $traceLimitHitCount
        TraceLimitHitRows = @($traceLimitHitRows)
        FileReadTargetTrace = $fileReadTargetSummary
        ThreadSuspendTrace = $threadSuspendSummary
        GuestCpuSnapshotsEnabled = [bool]($settings.RECOMP_GUEST_CPU_SNAPSHOT -eq '1')
    }) -Force
    $resultManifest | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Encoding UTF8
    if ($relayResult.WriterStopped) {
        $markerCounts.GetEnumerator() | ForEach-Object {
            '{0} {1}' -f $_.Key, $_.Value
        } | Set-Content -LiteralPath (Join-Path $runDirectory 'trace-counts.txt') -Encoding UTF8
    }

    # Keep stage/failure captures and logs lossless; NTFS compression preserves
    # their names and bytes while reducing the retained footprint after writers
    # have stopped. Never compress writable saves or game assets here.
    $closedEvidence = @(Get-ChildItem -LiteralPath $runDirectory -File -Force |
        Where-Object { $_.Extension -in '.bmp', '.log' })
    $closedEvidenceAllocatedBytesBeforeCompression = Get-AllocatedBytesForFiles -Files $closedEvidence
    $closedEvidenceCompressionExitCode = 0
    if ($closedEvidence.Count -gt 0) {
        & compact.exe /C /I /Q @($closedEvidence | ForEach-Object { $_.FullName }) 2>$null | Out-Null
        $closedEvidenceCompressionExitCode = $LASTEXITCODE
    }
    $closedEvidenceAllocatedBytesAfterCompression = Get-AllocatedBytesForFiles -Files $closedEvidence
    $closedEvidenceAllocatedBytesReclaimed = if (
        $closedEvidenceAllocatedBytesBeforeCompression -ge 0 -and
        $closedEvidenceAllocatedBytesAfterCompression -ge 0) {
        [long]($closedEvidenceAllocatedBytesBeforeCompression - $closedEvidenceAllocatedBytesAfterCompression)
    } else { 0L }
    $storageAllocatedBytesAtExit = Get-RunDirectoryAllocatedBytes -Path $runDirectory
    $resultManifest.RunResult | Add-Member -NotePropertyName ClosedEvidenceCompressedFiles `
        -NotePropertyValue $(if ($closedEvidenceCompressionExitCode -eq 0) { $closedEvidence.Count } else { 0 }) -Force
    $resultManifest.RunResult | Add-Member -NotePropertyName ClosedEvidenceCompressionExitCode `
        -NotePropertyValue $closedEvidenceCompressionExitCode -Force
    $resultManifest.RunResult | Add-Member -NotePropertyName ClosedEvidenceAllocatedBytesBeforeCompression `
        -NotePropertyValue $closedEvidenceAllocatedBytesBeforeCompression -Force
    $resultManifest.RunResult | Add-Member -NotePropertyName ClosedEvidenceAllocatedBytesAfterCompression `
        -NotePropertyValue $closedEvidenceAllocatedBytesAfterCompression -Force
    $resultManifest.RunResult | Add-Member -NotePropertyName ClosedEvidenceAllocatedBytesReclaimed `
        -NotePropertyValue $closedEvidenceAllocatedBytesReclaimed -Force
    $resultManifest.RunResult | Add-Member -NotePropertyName RunStorageAllocatedBytesAtExit `
        -NotePropertyValue $storageAllocatedBytesAtExit -Force
    $resultManifest | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath (Join-Path $runDirectory 'run-manifest.json') -Encoding UTF8
}
