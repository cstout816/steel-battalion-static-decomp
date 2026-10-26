# Offline x64 unwind for same-host minidumps captured with Capture-ProducerTraceDump.ps1.
# It reads the saved thread stack and uses local module images at the captured bases.
# Frames outside the dump's module ranges are rejected; this is not a cross-machine unwinder.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string]$DumpPath,
    [Parameter(Mandatory = $true)] [string]$ImagePath,
    [Parameter(Mandatory = $true)] [int]$ThreadId,
    [string]$SymbolPath
)

$ErrorActionPreference = 'Stop'
$dump = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $DumpPath).Path)
$image = (Resolve-Path -LiteralPath $ImagePath).Path

if (-not ('ProducerTraceStackWalk' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class ProducerTraceStackWalk {
    [StructLayout(LayoutKind.Sequential)] public struct ADDRESS64 {
        public ulong Offset; public ushort Segment; public int Mode;
    }
    [StructLayout(LayoutKind.Sequential)] public struct KDHELP64 {
        public ulong Thread;
        public uint ThCallbackStack, ThCallbackBStore, NextCallback, FramePointer;
        public ulong KiCallUserMode, KeUserCallbackDispatcher, SystemRangeStart;
        public ulong KiUserExceptionDispatcher, StackBase, StackLimit;
        public uint BuildVersion, RetpolineStubFunctionTableSize;
        public ulong RetpolineStubFunctionTable;
        public uint RetpolineStubOffset, RetpolineStubSize;
        public ulong Reserved00, Reserved01;
    }
    [StructLayout(LayoutKind.Sequential)] public struct STACKFRAME64 {
        public ADDRESS64 AddrPC, AddrReturn, AddrFrame, AddrStack, AddrBStore;
        public IntPtr FuncTableEntry;
        public ulong Param0, Param1, Param2, Param3;
        public int Far, Virtual;
        public ulong Reserved0, Reserved1, Reserved2;
        public KDHELP64 KdHelp;
    }
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] public delegate bool ReadMemoryProc(
        IntPtr process, ulong address, IntPtr buffer, uint size, out uint read);
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] public delegate IntPtr FunctionTableProc(
        IntPtr process, ulong address);
    [UnmanagedFunctionPointer(CallingConvention.Winapi)] public delegate ulong ModuleBaseProc(
        IntPtr process, ulong address);

    [DllImport("dbghelp.dll", EntryPoint="SymInitializeW", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool SymInitialize(IntPtr process, string path, bool invade);
    [DllImport("dbghelp.dll", EntryPoint="SymSetOptions", SetLastError=true)]
    public static extern uint SymSetOptions(uint options);
    [DllImport("dbghelp.dll", EntryPoint="SymCleanup", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SymCleanup(IntPtr process);
    [DllImport("dbghelp.dll", EntryPoint="SymLoadModuleExW", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern ulong SymLoadModuleEx(IntPtr process, IntPtr file, string image, string module,
        ulong baseAddress, uint size, IntPtr data, uint flags);
    [DllImport("dbghelp.dll", EntryPoint="SymFunctionTableAccess64", SetLastError=true)]
    public static extern IntPtr SymFunctionTableAccess64(IntPtr process, ulong address);
    [DllImport("dbghelp.dll", EntryPoint="SymGetModuleBase64", SetLastError=true)]
    public static extern ulong SymGetModuleBase64(IntPtr process, ulong address);
    [DllImport("kernel32.dll", EntryPoint="ReadProcessMemory", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ReadProcessMemory(IntPtr process, ulong address, IntPtr buffer,
        uint size, out uint read);
    [DllImport("dbghelp.dll", EntryPoint="StackWalk64", SetLastError=true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool StackWalk64(uint machine, IntPtr process, IntPtr thread,
        ref STACKFRAME64 frame, IntPtr context, ReadMemoryProc readMemory,
        FunctionTableProc functionTable, ModuleBaseProc moduleBase, IntPtr translate);

    public static ulong StackStart;
    public static byte[] StackData;
    public static int ReadCalls, ReadFailures, FunctionCalls, ModuleCalls;
    public static ulong LastReadAddress;
    public static uint LastReadSize;
    public static ReadMemoryProc ReadRoutine = ReadCurrentMemory;
    public static FunctionTableProc FunctionRoutine = GetFunctionTable;
    public static ModuleBaseProc ModuleRoutine = GetModuleBase;

    public static bool ReadCurrentMemory(IntPtr process, ulong address, IntPtr buffer,
        uint size, out uint read) {
        ReadCalls++;
        LastReadAddress = address; LastReadSize = size;
        bool ok = ReadStack(StackStart, StackData, address, buffer, size, out read);
        if (!ok) ok = ReadProcessMemory(new IntPtr(-1), address, buffer, size, out read);
        if (!ok) ReadFailures++;
        return ok;
    }
    public static IntPtr GetFunctionTable(IntPtr process, ulong address) {
        FunctionCalls++;
        return SymFunctionTableAccess64(process, address);
    }
    public static ulong GetModuleBase(IntPtr process, ulong address) {
        ModuleCalls++;
        return SymGetModuleBase64(process, address);
    }

    public static bool ReadStack(ulong start, byte[] stack, ulong address, IntPtr buffer,
        uint size, out uint read) {
        read = 0;
        if (address < start || address + size < address || address + size > start + (ulong)stack.Length)
            return false;
        int offset = checked((int)(address - start));
        Marshal.Copy(stack, offset, buffer, checked((int)size));
        read = size;
        return true;
    }
}
"@
}

function Read-U32([int]$offset) { [BitConverter]::ToUInt32($dump, $offset) }
function Read-U64([int]$offset) { [BitConverter]::ToUInt64($dump, $offset) }
function Read-MiniDumpString([uint32]$rva) {
    $length = Read-U32 ([int]$rva)
    if ($length -gt 32768 -or ($rva + 4 + $length) -gt $dump.Length) { return '' }
    [Text.Encoding]::Unicode.GetString($dump, [int]$rva + 4, [int]$length)
}

$streamCount = Read-U32 8
$directoryRva = Read-U32 12
$streams = @{}
for ($i = 0; $i -lt $streamCount; $i++) {
    $offset = [int]$directoryRva + 12 * $i
    $streams[(Read-U32 $offset)] = [pscustomobject]@{ Size=(Read-U32 ($offset+4)); Rva=(Read-U32 ($offset+8)) }
}
if (-not $streams.ContainsKey([uint32]3) -or -not $streams.ContainsKey([uint32]4)) {
    throw 'Dump must contain thread and module list streams.'
}

$process = [IntPtr](-1)
$null = [ProducerTraceStackWalk]::SymSetOptions(0x00000002 -bor 0x00000004 -bor 0x00000010)
if (-not [ProducerTraceStackWalk]::SymInitialize($process, $SymbolPath, $false)) {
    $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "SymInitialize failed: $errorCode"
}

$moduleStream = $streams[[uint32]4]
$moduleCount = Read-U32 ([int]$moduleStream.Rva)
$loadedModules = @()
$dumpModules = [System.Collections.Generic.List[object]]::new()
for ($i = 0; $i -lt $moduleCount; $i++) {
    $offset = [int]$moduleStream.Rva + 4 + 108 * $i
    $baseAddress = Read-U64 $offset
    $size = Read-U32 ($offset+8)
    $path = Read-MiniDumpString (Read-U32 ($offset+20))
    $dumpModules.Add([pscustomobject]@{ Base=$baseAddress; Size=$size; Path=$path; Name=[IO.Path]::GetFileName($path) })
    if ($path -match 'your_game_recomp_producer_trace\.exe$') { $path = $image }
    if ($path -and (Test-Path -LiteralPath $path)) {
        $loadedBase = [ProducerTraceStackWalk]::SymLoadModuleEx($process, [IntPtr]::Zero, $path,
            [IO.Path]::GetFileName($path), $baseAddress, $size, [IntPtr]::Zero, 0)
        $loadedModules += [pscustomobject]@{ Path=$path; ExpectedBase=('0x{0:X}' -f $baseAddress); LoadedBase=('0x{0:X}' -f $loadedBase) }
    }
}
"Loaded module images: $($loadedModules.Count)"
$loadedModules | Where-Object { $_.Path -like '*ntdll.dll' -or $_.Path -eq $image } | Format-Table -AutoSize

$threadStream = $streams[[uint32]3]
$threadCount = Read-U32 ([int]$threadStream.Rva)
$thread = $null
for ($i = 0; $i -lt $threadCount; $i++) {
    $offset = [int]$threadStream.Rva + 4 + 48 * $i
    if ((Read-U32 $offset) -eq $ThreadId) {
        $thread = [pscustomobject]@{
            StackStart=(Read-U64 ($offset+24)); StackSize=(Read-U32 ($offset+32)); StackRva=(Read-U32 ($offset+36));
            ContextSize=(Read-U32 ($offset+40)); ContextRva=(Read-U32 ($offset+44))
        }
        break
    }
}
if (-not $thread) { throw "Thread $ThreadId is not present in the dump." }
if ($thread.ContextSize -lt 256 -or ($thread.ContextRva + $thread.ContextSize) -gt $dump.Length -or
    ($thread.StackRva + $thread.StackSize) -gt $dump.Length) { throw 'Thread context or stack data is truncated.' }

$context = [Runtime.InteropServices.Marshal]::AllocHGlobal([int]$thread.ContextSize)
try {
    $contextBytes = New-Object byte[] ([int]$thread.ContextSize)
    [Array]::Copy($dump, [int]$thread.ContextRva, $contextBytes, 0, $contextBytes.Length)
    [Runtime.InteropServices.Marshal]::Copy($contextBytes, 0, $context, $contextBytes.Length)
    $stackBytes = New-Object byte[] ([int]$thread.StackSize)
    [Array]::Copy($dump, [int]$thread.StackRva, $stackBytes, 0, $stackBytes.Length)
    [ProducerTraceStackWalk]::StackStart = $thread.StackStart
    [ProducerTraceStackWalk]::StackData = $stackBytes

    $frame = New-Object ProducerTraceStackWalk+STACKFRAME64
    $pc = New-Object ProducerTraceStackWalk+ADDRESS64
    $pc.Offset = [BitConverter]::ToUInt64($contextBytes, 248); $pc.Mode = 3
    $stack = New-Object ProducerTraceStackWalk+ADDRESS64
    $stack.Offset = [BitConverter]::ToUInt64($contextBytes, 152); $stack.Mode = 3
    $fp = New-Object ProducerTraceStackWalk+ADDRESS64
    $fp.Offset = [BitConverter]::ToUInt64($contextBytes, 160); $fp.Mode = 3
    $frame.AddrPC = $pc
    $frame.AddrStack = $stack
    $frame.AddrFrame = $fp
    "Dump=$DumpPath TID=$ThreadId StackStart=0x{0:X} StackBytes={1}" -f $thread.StackStart,$thread.StackSize
    $lastPc = [ulong]0
    for ($i = 0; $i -lt 64; $i++) {
        $pcAddress = [ulong]$frame.AddrPC.Offset
        if ($pcAddress -ne $lastPc) {
            $module = $dumpModules | Where-Object { $pcAddress -ge $_.Base -and $pcAddress -lt ($_.Base + $_.Size) } | Select-Object -First 1
            if (-not $module) {
                if ($pcAddress) { "Stop: unwind reached non-module address 0x{0:X}." -f $pcAddress }
                break
            }
            $moduleOffset = $pcAddress - [ulong]$module.Base
            "#{0:D2} {1}+0x{2:X} SP=0x{3:X} FP=0x{4:X}" -f $i,$module.Name,$moduleOffset,$frame.AddrStack.Offset,$frame.AddrFrame.Offset
            $lastPc = $pcAddress
        }
        $ok = [ProducerTraceStackWalk]::StackWalk64(0x8664, $process, [IntPtr]::Zero,
            [ref]$frame, $context, [ProducerTraceStackWalk]::ReadRoutine,
            [ProducerTraceStackWalk]::FunctionRoutine, [ProducerTraceStackWalk]::ModuleRoutine, [IntPtr]::Zero)
        if (-not $ok -or $frame.AddrPC.Offset -eq 0) {
            "StackWalk stopped (ok=$ok, lastError=$([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
            break
        }
    }
    "Callbacks: reads=$([ProducerTraceStackWalk]::ReadCalls) readFailures=$([ProducerTraceStackWalk]::ReadFailures) functionTables=$([ProducerTraceStackWalk]::FunctionCalls) modules=$([ProducerTraceStackWalk]::ModuleCalls) lastRead=0x$('{0:X}' -f [ProducerTraceStackWalk]::LastReadAddress)+$([ProducerTraceStackWalk]::LastReadSize)"
} finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($context)
    $null = [ProducerTraceStackWalk]::SymCleanup($process)
}
