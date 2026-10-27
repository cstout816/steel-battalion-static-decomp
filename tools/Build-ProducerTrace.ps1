[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$')]
    [string]$SideBySideName
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $projectRoot 'local-tools\steel-battalion-game\build-xpp-seeded'
$isSideBySide = -not [string]::IsNullOrWhiteSpace($SideBySideName)
if ($isSideBySide) {
    $traceDir = Join-Path $buildRoot (Join-Path 'ProducerTrace-Candidates' (Join-Path $SideBySideName 'Release'))
    $traceExe = Join-Path $traceDir 'your_game_recomp_producer_trace.exe'
    if (Test-Path -LiteralPath $traceDir) {
        throw "Side-by-side output already exists; choose a new name so prior candidates are preserved: $traceDir"
    }
}
else {
    $traceDir = Join-Path $buildRoot 'ProducerTrace\Release'
    $traceExe = Join-Path $traceDir 'your_game_recomp_producer_trace.exe'
}
$activeGames = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like 'your_game_recomp*'
})
$blockingGames = @($activeGames | Where-Object {
    if (-not $isSideBySide) { return $true }
    if ([string]::IsNullOrWhiteSpace($_.Path)) { return $true }
    [string]::Equals([IO.Path]::GetFullPath($_.Path), [IO.Path]::GetFullPath($traceExe), [StringComparison]::OrdinalIgnoreCase)
})
if ($blockingGames.Count -gt 0) {
    $ids = ($blockingGames | ForEach-Object { $_.Id }) -join ', '
    if ($isSideBySide) {
        throw "A game process is using the requested candidate output path (PID $ids); this script will not replace it."
    }
    throw "A game process is still open (PID $ids). Close it naturally before replacing the standard diagnostic executable; this script will not stop it. Use -SideBySideName to build an isolated candidate."
}

$projectFile = Join-Path $buildRoot 'your_game_recomp.vcxproj'
$kernelProject = Join-Path $buildRoot 'xboxrecomp\src\kernel\xbox_kernel.vcxproj'
$usbProject = Join-Path $buildRoot 'xboxrecomp\src\usb\xbox_usb.vcxproj'
$generatedSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0015.c'
$generatedInputSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0001.c'
$generatedMenuSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0004.c'
$generatedLoaderSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0005.c'
$generatedAudioSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0016.c'
$generatedFileCopySource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0008.c'
$generatedPreloadSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0000.c'
$kernelTraceSource = Join-Path $projectRoot 'local-tools\xboxrecomp\src\kernel\kernel_bridge.c'
$msbuild = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'
$stagedExe = Join-Path $traceDir 'your_game_recomp.exe'
$stagedPdb = Join-Path $buildRoot 'Release\your_game_recomp.pdb'
$tracePdb = Join-Path $traceDir 'your_game_recomp_producer_trace.pdb'
$archiveDir = 'C:\Project\SteelBattalion-Delete-Later-20261024\workspace\local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace\Release'

foreach ($path in @($projectFile, $kernelProject, $usbProject, $generatedSource, $generatedInputSource, $generatedMenuSource, $generatedLoaderSource, $generatedAudioSource, $generatedFileCopySource, $generatedPreloadSource, $kernelTraceSource, $msbuild)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required build input is missing: $path"
    }
}

$requiredLibraries = @(
    'xboxrecomp\src\audio\Release\xbox_dsound.lib',
    'xboxrecomp\src\usb\Release\xbox_usb.lib',
    'xboxrecomp\src\input\Release\xbox_input.lib',
    'xboxrecomp\src\apu\Release\xbox_apu.lib',
    'xboxrecomp\src\nv2a\Release\xbox_nv2a.lib',
    'xboxrecomp\src\video\Release\xbox_video.lib',
    'xboxrecomp\src\d3d\Release\xbox_d3d8.lib',
    'xboxrecomp\src\video\Release\xbox_vulkan_volk.lib',
    'dsp56300-cargo\x86_64-pc-windows-msvc\release\dsp56300_emu_ffi.lib'
)
foreach ($library in $requiredLibraries) {
    $path = Join-Path $buildRoot $library
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "A prebuilt dependency needed for the isolated link is missing: $path"
    }
}

$requiredTraceMarkers = @(
    'RECOMP_SB_DCF4_PRODUCER_TRACE',
    'sb_put_trace_count < 100000u',
    'dcf4_reset_trace_count < 100000u',
    'sb_marker_trace_count < 100000u',
    'n <= 100000u',
    '[SB-PFB-POLL]',
    'sb_pfb_poll_count < 2048u'
)
foreach ($marker in $requiredTraceMarkers) {
    $match = Select-String -LiteralPath $generatedSource -SimpleMatch $marker -Quiet
    if (-not $match) { throw "Generated source is missing expected trace instrumentation: $marker" }
}

foreach ($check in @(
    @{ Path = $generatedInputSource; Marker = '[SB-INPUT-DISPATCH]' },
    @{ Path = $generatedInputSource; Marker = '[SB-INPUT-TABLE]' },
    @{ Path = $generatedInputSource; Marker = '[SB-EDGE-CONSUME]' },
    @{ Path = $generatedInputSource; Marker = 'pred_c == 0x1Au' },
    @{ Path = $generatedInputSource; Marker = '[SB-SNAPSHOT]' },
    @{ Path = $generatedMenuSource; Marker = '[PILOT-LIST-CB]' },
    @{ Path = $generatedMenuSource; Marker = '[PILOT-ROW-POST]' },
    @{ Path = $generatedMenuSource; Marker = '[SB-ROSTER-BRANCH]' },
    @{ Path = $generatedMenuSource; Marker = '[SB-ROSTER-STATE]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-DISPATCH]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-RESOURCE]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-RESULT]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-ENTRY]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-EXIT]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-OBJECT-TIMER-GATE]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-OBJECT-INPUT]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-OBJECT-STATE]' },
    @{ Path = $generatedMenuSource; Marker = 'RECOMP_TITLE_OBJECT_GATE_TRACE' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-OBJECT-GATE]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-CALLBACK-GATE]' },
    @{ Path = $generatedMenuSource; Marker = 'RECOMP_MENU_CALLBACK_GATE_TRACE' },
    @{ Path = $generatedInputSource; Marker = 'button_cell=%08X:%04X' },
    @{ Path = $generatedInputSource; Marker = 'tick_ms=%llu tid=%u caller=%08X parent=%08X' },
    @{ Path = $generatedMenuSource; Marker = 'GetCurrentThreadId()' },
    @{ Path = $generatedInputSource; Marker = 'GetCurrentThreadId()' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-HELPER]' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-HELPER-BRANCH]' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-HELPER-RET]' },
    @{ Path = $generatedMenuSource; Marker = 'index=%08X path0=%08X path1=%08X' },
    @{ Path = $generatedMenuSource; Marker = 'open1=%08X open2=%08X open3=%08X stage=%08X' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-PASS-IN]' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-PASS-OUT]' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-STACK]' },
    @{ Path = $generatedLoaderSource; Marker = '[LOAD-STATE-CB]' },
    @{ Path = $generatedLoaderSource; Marker = 'RECOMP_LOAD_STATE_CALLBACK_TRACE' },
    @{ Path = $generatedLoaderSource; Marker = '0x00101E6Bu' },
    @{ Path = $generatedLoaderSource; Marker = '0x00101E8Bu' },
    @{ Path = $generatedLoaderSource; Marker = '0x00101F70u' },
    @{ Path = $generatedLoaderSource; Marker = '0x00101F90u' },
    @{ Path = $generatedLoaderSource; Marker = '0x00101FF6u' },
    @{ Path = $generatedLoaderSource; Marker = '0x00102017u' },
    @{ Path = $generatedLoaderSource; Marker = '0x0010203Au' },
    @{ Path = $generatedLoaderSource; Marker = '0x0010205Au' },
    @{ Path = $generatedLoaderSource; Marker = '0x0010206Bu' },
    @{ Path = $generatedLoaderSource; Marker = '0x0010208Au' },
    @{ Path = $generatedLoaderSource; Marker = '[LOAD-RENDER]' },
    @{ Path = $generatedFileCopySource; Marker = '[FILE-COPY-ENTER]' },
    @{ Path = $generatedFileCopySource; Marker = '[FILE-COPY-RETURN]' },
    @{ Path = $generatedFileCopySource; Marker = '[THREAD-START]' },
    @{ Path = $generatedPreloadSource; Marker = '[FILE-PRELOAD-ENTER]' },
    @{ Path = $generatedPreloadSource; Marker = '[PRELOAD-WORKER-ROUTE]' },
    @{ Path = $generatedPreloadSource; Marker = 'tex_index=%04X tex16_override=%08X' },
    @{ Path = $generatedPreloadSource; Marker = '[FILE-PRELOAD-RETURN]' },
    @{ Path = $generatedAudioSource; Marker = '[SB-STREAM-STATE]' },
    @{ Path = $generatedMenuSource; Marker = 'tick_ms=%llu tid=%u site=000E18D8' }
)) {
    if (-not (Select-String -LiteralPath $check.Path -SimpleMatch $check.Marker -Quiet)) {
        throw "Generated diagnostic source is missing expected instrumentation: $($check.Marker)"
    }
}

foreach ($marker in @(
    'RECOMP_FILE_LIFECYCLE_TRACE',
    '[FILE-LIFECYCLE-OPEN]',
    '[FILE-LIFECYCLE-CLOSE]',
    '[FILE-LIFECYCLE-OPEN-CAPPED]',
    'RECOMP_FILE_FAIL_PATH_TRACE',
    '[FILE-MISS-PATH]',
    'RECOMP_FILE_IO_DETAIL_TRACE',
    '[FILE-IO]'
)) {
    if (-not (Select-String -LiteralPath $kernelTraceSource -SimpleMatch $marker -Quiet)) {
        throw "Kernel bridge is missing required lifecycle trace instrumentation: $marker"
    }
}

foreach ($marker in @(
    'RECOMP_XBE_SECTION_TRACE',
    '[XBE-SECTION]',
    'XBE_SECTION_REFCOUNT_OFFSET',
    'refcount=%u->%u'
)) {
    if (-not (Select-String -LiteralPath $kernelTraceSource -SimpleMatch $marker -Quiet)) {
        throw "Kernel bridge is missing bounded XBE section tracing: $marker"
    }
}

New-Item -ItemType Directory -Path $traceDir -Force | Out-Null
$kernelOutDirArg = '/p:OutDir=' + (Join-Path $buildRoot 'xboxrecomp\src\kernel\Release') + '\'
& $msbuild $kernelProject '/nologo' '/m' '/t:Build' '/p:Configuration=Release' '/p:Platform=x64' '/p:BuildProjectReferences=false' $kernelOutDirArg '/v:minimal'
if ($LASTEXITCODE -ne 0) { throw "Kernel trace-library build failed with exit code $LASTEXITCODE" }
$usbOutDirArg = '/p:OutDir=' + (Join-Path $buildRoot 'xboxrecomp\src\usb\Release') + '\'
& $msbuild $usbProject '/nologo' '/m' '/t:Build' '/p:Configuration=Release' '/p:Platform=x64' '/p:BuildProjectReferences=false' $usbOutDirArg '/v:minimal'
if ($LASTEXITCODE -ne 0) { throw "USB trace-library build failed with exit code $LASTEXITCODE" }
$outDirArg = '/p:OutDir=' + $traceDir + '\'
# Some generated diagnostic chunks add bounded fprintf(stderr, ...) probes but
# do not carry the CRT declaration themselves. Force-include stdio so a fresh
# generated-source pass remains buildable without editing game semantics.
& $msbuild $projectFile '/nologo' '/m' '/t:Build' '/p:Configuration=Release' '/p:Platform=x64' '/p:BuildProjectReferences=false' '/p:ForcedIncludeFiles=stdio.h' $outDirArg '/v:minimal'
if ($LASTEXITCODE -ne 0) { throw "MSBuild failed with exit code $LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $stagedExe -PathType Leaf)) {
    throw "Build completed without producing the staged executable: $stagedExe"
}
if (-not (Test-Path -LiteralPath $stagedPdb -PathType Leaf)) {
    throw "Build completed without producing the matching diagnostic PDB: $stagedPdb"
}
if ((Get-Item -LiteralPath $stagedExe).Length -lt 10MB) {
    throw "Staged executable is unexpectedly small; existing trace executable was preserved."
}

if ($isSideBySide) {
    Move-Item -LiteralPath $stagedExe -Destination $traceExe
    Move-Item -LiteralPath $stagedPdb -Destination $tracePdb
    "Built isolated producer-trace candidate without replacing any existing executable: $traceExe"
    return
}

if (Test-Path -LiteralPath $traceExe) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $archivedExe = Join-Path $archiveDir "your_game_recomp_producer_trace-$stamp.exe"
    Move-Item -LiteralPath $traceExe -Destination $archivedExe
}
if (Test-Path -LiteralPath $tracePdb) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $archivedPdb = Join-Path $archiveDir "your_game_recomp_diag-$stamp.pdb"
    Move-Item -LiteralPath $tracePdb -Destination $archivedPdb
}
if (Test-Path -LiteralPath (Join-Path $traceDir 'your_game_recomp_producer_trace.pdb')) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $archivedPdb = Join-Path $archiveDir "your_game_recomp_producer_trace-old-$stamp.pdb"
    Move-Item -LiteralPath (Join-Path $traceDir 'your_game_recomp_producer_trace.pdb') -Destination $archivedPdb
}

Move-Item -LiteralPath $stagedExe -Destination $traceExe -Force
Move-Item -LiteralPath $stagedPdb -Destination $tracePdb -Force
"Built separate producer-trace executable: $traceExe"
