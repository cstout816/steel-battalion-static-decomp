<#
.SYNOPSIS
Starts a separate current-source ProducerTrace run with screen-gated live input.

.DESCRIPTION
Refuses to start beside any your_game_recomp process, requires an existing save
directory, creates a fresh local log folder, and starts with an empty live-input
file. It does not copy save data or send input. Append input only after checking
the latest framebuffer and confirming the expected screen.

.EXAMPLE
./tools/Start-ProducerTrace.ps1 -RunName m3-producer-trace-screen-gated-20261024
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$RunName,

    [string]$SaveDirectory = (Join-Path $PSScriptRoot '..\iso\local-analysis\saves-m3-known-save-copy-20261023')
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$traceExe = Join-Path $projectRoot 'local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace\Release\your_game_recomp_producer_trace.exe'
$generatedSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0015.c'
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

foreach ($path in @($traceExe, $generatedSource, $saveRoot)) {
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
if ((Get-Item -LiteralPath $traceExe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $generatedSource).LastWriteTimeUtc) {
    throw 'ProducerTrace executable is older than the current generated source. Build it before launching.'
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
$null = New-Item -ItemType File -Path $padLive

$settings = [ordered]@{
    RECOMP_AC97_READY = '1'
    RECOMP_APU_DSP_ACK = '0x803B8810'
    RECOMP_ASYNC_IO = '1'
    RECOMP_CRASH_DUMP = $crashPath
    RECOMP_DCF4_CALLBACK_TRACE = '1'
    RECOMP_DCF4_STACK_TRACE = '1'
    RECOMP_DISPATCH_GATE = '1'
    RECOMP_DSOUND_COMMIT_TRACE = '1'
    RECOMP_DSOUND_NULL_TRACE = '1'
    RECOMP_FB_DUMP = $framePath
    RECOMP_FB_WINDOW = '1'
    RECOMP_FB_WINDOW_DUMP_EVERY = '1800'
    RECOMP_GUEST_LOCK = '1'
    RECOMP_INPUT_DIAG = '1'
    RECOMP_IRQ_SAFE_POINTS = '1'
    RECOMP_KERNEL_LOG_BUDGET = '0'
    RECOMP_NV2A_IRQ_TRACE = '1'
    RECOMP_PAD_LIVE = $padLive
    RECOMP_PB_EXEC = '1'
    RECOMP_PB_NOTIFY_TRACE = '1'
    RECOMP_PB_REPORT_MS = '30000'
    RECOMP_PB_SEMAPHORE_TRACE = '1'
    RECOMP_RASTER_PERF_TRACE = '1'
    RECOMP_RASTER_THREADS = '4'
    RECOMP_SAVE_DIR = $saveRoot
    RECOMP_SB_DCF4_PRODUCER_TRACE = '1'
    RECOMP_SYNC_TRACE = '1'
    RECOMP_TITLE_INPUT_TRACE = '1'
    RECOMP_TITLE_ROUTE_TRACE = '1'
    RECOMP_TITLE_KEVENTS = '1'
    RECOMP_MENU_STATE_TRACE = '1'
    RECOMP_USB = '1'
    RECOMP_USB_PROFILE = 'steel-battalion'
    RECOMP_USB_STATS = '1'
    RECOMP_VBLANK = '1'
    RECOMP_WAIT_TRACE_LOG = $waitTrace
    RECOMP_WATCH = '0x8038C098'
    RECOMP_WATCH_BLOCK = '1'
    RECOMP_WATCH_NATIVE_RIP = '1'
    RECOMP_WATCHDOG_SECS = '1800'
    RECOMP_XID_REPORT_TRACE = '1'
}

$environmentNames = @($settings.Keys) + 'RECOMP_PAD_SCRIPT'
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

try {
    foreach ($name in $settings.Keys) {
        Set-Item -Path ("Env:{0}" -f $name) -Value $settings[$name]
    }
    Remove-Item Env:RECOMP_PAD_SCRIPT -ErrorAction SilentlyContinue

    $environmentSnapshot = @($settings.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value })
    $environmentSnapshot += 'RECOMP_PAD_SCRIPT=<unset; screen-gated live input only>'
    $environmentSnapshot | Set-Content -LiteralPath (Join-Path $runDirectory 'environment.txt') -Encoding UTF8

    $process = Start-Process -FilePath $traceExe `
        -WorkingDirectory $projectRoot `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru `
        -WindowStyle Normal
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
