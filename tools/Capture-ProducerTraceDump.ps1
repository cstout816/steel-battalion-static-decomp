[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2147483647)]
    [int]$ProcessId,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$fullPath = [IO.Path]::GetFullPath($OutputPath)
$parent = Split-Path -Parent $fullPath
if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
    throw "Output directory does not exist: $parent"
}
if (Test-Path -LiteralPath $fullPath) {
    throw "Refusing to overwrite an existing dump: $fullPath"
}

if (-not ('ProducerTraceDump' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class ProducerTraceDump {
    [Flags]
    public enum DumpType : uint {
        Normal = 0x00000000,
        WithProcessThreadData = 0x00000100,
        WithUnloadedModules = 0x00000020,
        WithThreadInfo = 0x00001000
    }
    [DllImport("Dbghelp.dll", SetLastError = true)]
    public static extern bool MiniDumpWriteDump(
        IntPtr process, uint processId, IntPtr file, DumpType dumpType,
        IntPtr exceptionParam, IntPtr userStreamParam, IntPtr callbackParam);
}
"@
}

$file = [IO.File]::Open($fullPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
try {
    $flags = [ProducerTraceDump+DumpType]::WithProcessThreadData -bor
             [ProducerTraceDump+DumpType]::WithUnloadedModules -bor
             [ProducerTraceDump+DumpType]::WithThreadInfo
    $ok = [ProducerTraceDump]::MiniDumpWriteDump(
        $process.Handle, [uint32]$ProcessId, $file.SafeFileHandle.DangerousGetHandle(),
        $flags, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero)
    if (-not $ok) {
        $code = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "MiniDumpWriteDump failed with Win32 error $code"
    }
}
finally {
    $file.Dispose()
}

Get-Item -LiteralPath $fullPath | Select-Object FullName, Length, LastWriteTime
