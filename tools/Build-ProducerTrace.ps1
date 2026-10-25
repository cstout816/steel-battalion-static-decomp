[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$activeGames = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like 'your_game_recomp*'
})
if ($activeGames.Count -gt 0) {
    $ids = ($activeGames | ForEach-Object { $_.Id }) -join ', '
    throw "A game process is still open (PID $ids). Close it naturally before building; this script will not stop it."
}

$buildRoot = Join-Path $projectRoot 'local-tools\steel-battalion-game\build-xpp-seeded'
$projectFile = Join-Path $buildRoot 'your_game_recomp.vcxproj'
$usbProject = Join-Path $buildRoot 'xboxrecomp\src\usb\xbox_usb.vcxproj'
$generatedSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0015.c'
$generatedInputSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0001.c'
$generatedMenuSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0004.c'
$generatedLoaderSource = Join-Path $projectRoot 'iso\local-analysis\xboxrecomp-generated-xpp-untraced-current\gen\recomp_0005.c'
$msbuild = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe'
$traceDir = Join-Path $buildRoot 'ProducerTrace\Release'
$stagedExe = Join-Path $traceDir 'your_game_recomp_diag.exe'
$stagedPdb = Join-Path $buildRoot 'Release\your_game_recomp_diag.pdb'
$traceExe = Join-Path $traceDir 'your_game_recomp_producer_trace.exe'
$tracePdb = Join-Path $traceDir 'your_game_recomp_diag.pdb'
$archiveDir = 'C:\Project\SteelBattalion-Delete-Later-20261024\workspace\local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace\Release'

foreach ($path in @($projectFile, $usbProject, $generatedSource, $generatedInputSource, $generatedMenuSource, $generatedLoaderSource, $msbuild)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required build input is missing: $path"
    }
}

$requiredLibraries = @(
    'xboxrecomp\src\kernel\Release\xbox_kernel.lib',
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
    @{ Path = $generatedMenuSource; Marker = '[PILOT-LIST-CB]' },
    @{ Path = $generatedMenuSource; Marker = '[PILOT-ROW-POST]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-DISPATCH]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-RESOURCE]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-RESULT]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-ENTRY]' },
    @{ Path = $generatedMenuSource; Marker = '[TITLE-ROUTE-EXIT]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-OBJECT-GATE]' },
    @{ Path = $generatedMenuSource; Marker = '[MENU-CALLBACK-GATE]' },
    @{ Path = $generatedMenuSource; Marker = 'RECOMP_MENU_CALLBACK_GATE_TRACE' },
    @{ Path = $generatedInputSource; Marker = 'button_cell=%08X:%04X' },
    @{ Path = $generatedInputSource; Marker = 'tick_ms=%llu tid=%u caller=%08X parent=%08X' },
    @{ Path = $generatedMenuSource; Marker = 'GetCurrentThreadId()' },
    @{ Path = $generatedInputSource; Marker = 'GetCurrentThreadId()' },
    @{ Path = $generatedMenuSource; Marker = '[LOAD-HELPER]' },
    @{ Path = $generatedLoaderSource; Marker = '[LOAD-RENDER]' },
    @{ Path = $generatedMenuSource; Marker = 'tick_ms=%llu tid=%u site=000E18D8' }
)) {
    if (-not (Select-String -LiteralPath $check.Path -SimpleMatch $check.Marker -Quiet)) {
        throw "Generated diagnostic source is missing expected instrumentation: $($check.Marker)"
    }
}

New-Item -ItemType Directory -Path $traceDir -Force | Out-Null
$usbOutDirArg = '/p:OutDir=' + (Join-Path $buildRoot 'xboxrecomp\src\usb\Release') + '\'
& $msbuild $usbProject '/nologo' '/m' '/t:Build' '/p:Configuration=Release' '/p:Platform=x64' '/p:BuildProjectReferences=false' $usbOutDirArg '/v:minimal'
if ($LASTEXITCODE -ne 0) { throw "USB trace-library build failed with exit code $LASTEXITCODE" }
$outDirArg = '/p:OutDir=' + $traceDir + '\'
& $msbuild $projectFile '/nologo' '/m' '/t:Build' '/p:Configuration=Release' '/p:Platform=x64' '/p:BuildProjectReferences=false' $outDirArg '/v:minimal'
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
