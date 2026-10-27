/*
 * Attach to an existing diagnostic game process and report writes to one
 * guest DWORD using the processor's hardware data breakpoints. This avoids
 * PAGE_GUARD and does not patch guest code or alter guest state.
 *
 * Usage: GuestWriteBreakpoint.exe <pid> <guest-va> <memory-offset> <log-path>
 * Build from an x64 Visual Studio developer prompt with the Windows SDK.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

static FILE *g_log;
static DWORD g_pid;
static uintptr_t g_watch_address;
static DWORD g_last_value;
static unsigned g_watch_slot = 4;

static void log_line(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    vfprintf(g_log, format, args);
    fputc('\n', g_log);
    fflush(g_log);
    va_end(args);
}

static int read_dword(HANDLE process, uintptr_t address, DWORD *value)
{
    SIZE_T got = 0;
    return ReadProcessMemory(process, (LPCVOID)address, value, sizeof(*value), &got)
        && got == sizeof(*value);
}

static int arm_thread(HANDLE thread, DWORD tid)
{
    CONTEXT context;
    DWORD64 *dr[4];
    DWORD64 enables;
    unsigned slot = g_watch_slot == 4 ? 0 : g_watch_slot;

    ZeroMemory(&context, sizeof(context));
    context.ContextFlags = CONTEXT_DEBUG_REGISTERS;
    if (!GetThreadContext(thread, &context)) {
        log_line("ARM-FAILED tid=%lu step=GetThreadContext error=%lu", tid, GetLastError());
        return 0;
    }

    dr[0] = &context.Dr0;
    dr[1] = &context.Dr1;
    dr[2] = &context.Dr2;
    dr[3] = &context.Dr3;
    enables = context.Dr7;
    if ((enables & ((DWORD64)3 << (slot * 2))) != 0) {
        log_line("ARM-FAILED tid=%lu reason=no-free-debug-register", tid);
        return 0;
    }

    *dr[slot] = (DWORD64)g_watch_address;
    context.Dr6 = 0;
    context.Dr7 &= ~((DWORD64)0xF << (16 + slot * 4));
    context.Dr7 |= (DWORD64)1 << (slot * 2);             /* local enable */
    context.Dr7 |= (DWORD64)1 << (16 + slot * 4);        /* break on writes */
    context.Dr7 |= (DWORD64)3 << (18 + slot * 4);        /* DWORD length */
    context.ContextFlags = CONTEXT_DEBUG_REGISTERS;
    if (!SetThreadContext(thread, &context)) {
        log_line("ARM-FAILED tid=%lu step=SetThreadContext error=%lu", tid, GetLastError());
        return 0;
    }

    g_watch_slot = slot;
    log_line("ARMED tid=%lu slot=%u address=%p", tid, slot, (void *)g_watch_address);
    return 1;
}

static void close_debug_file(HANDLE file)
{
    if (file && file != INVALID_HANDLE_VALUE)
        CloseHandle(file);
}

int wmain(int argc, wchar_t **argv)
{
    DEBUG_EVENT event;
    HANDLE process = NULL;
    DWORD last_error = 0;
    uintptr_t guest_va;
    uintptr_t memory_offset;
    DWORD initial_value;
    int attached = 0;

    if (argc != 5) {
        fwprintf(stderr, L"Usage: GuestWriteBreakpoint.exe <pid> <guest-va> <memory-offset> <log-path>\n");
        return 2;
    }

    g_pid = wcstoul(argv[1], NULL, 0);
    guest_va = (uintptr_t)_wcstoui64(argv[2], NULL, 0);
    memory_offset = (uintptr_t)_wcstoui64(argv[3], NULL, 0);
    g_watch_address = guest_va + memory_offset;
    g_log = _wfopen(argv[4], L"wb");
    if (!g_log) {
        fwprintf(stderr, L"Could not open trace log.\n");
        return 3;
    }

    process = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, g_pid);
    if (!process) {
        log_line("ATTACH-FAILED step=OpenProcess pid=%lu error=%lu", g_pid, GetLastError());
        fclose(g_log);
        return 4;
    }
    if (!read_dword(process, g_watch_address, &initial_value)) {
        log_line("ATTACH-FAILED step=ReadProcessMemory address=%p error=%lu",
                 (void *)g_watch_address, GetLastError());
        CloseHandle(process);
        fclose(g_log);
        return 5;
    }
    g_last_value = initial_value;
    log_line("ATTACH pid=%lu guest_va=%08llX memory_offset=%p host_va=%p initial=%08lX",
             g_pid, (unsigned long long)guest_va, (void *)memory_offset,
             (void *)g_watch_address, g_last_value);

    if (!DebugActiveProcess(g_pid)) {
        log_line("ATTACH-FAILED step=DebugActiveProcess error=%lu", GetLastError());
        CloseHandle(process);
        fclose(g_log);
        return 6;
    }
    attached = 1;
    DebugSetProcessKillOnExit(FALSE);

    for (;;) {
        if (!WaitForDebugEvent(&event, INFINITE)) {
            last_error = GetLastError();
            log_line("DEBUG-FAILED step=WaitForDebugEvent error=%lu", last_error);
            break;
        }

        switch (event.dwDebugEventCode) {
        case CREATE_PROCESS_DEBUG_EVENT:
            if (arm_thread(event.u.CreateProcessInfo.hThread, event.dwThreadId)) {
                /* Read the current value after the create event is stopped. */
                read_dword(process, g_watch_address, &g_last_value);
            }
            if (event.u.CreateProcessInfo.hThread)
                CloseHandle(event.u.CreateProcessInfo.hThread);
            if (event.u.CreateProcessInfo.hProcess)
                CloseHandle(event.u.CreateProcessInfo.hProcess);
            close_debug_file(event.u.CreateProcessInfo.hFile);
            break;

        case CREATE_THREAD_DEBUG_EVENT:
            arm_thread(event.u.CreateThread.hThread, event.dwThreadId);
            if (event.u.CreateThread.hThread)
                CloseHandle(event.u.CreateThread.hThread);
            break;

        case EXCEPTION_DEBUG_EVENT:
            if (event.u.Exception.ExceptionRecord.ExceptionCode == EXCEPTION_SINGLE_STEP
                && g_watch_slot < 4) {
                CONTEXT context;
                DWORD64 dr6;
                DWORD current_value;
                HANDLE thread;
                ZeroMemory(&context, sizeof(context));
                context.ContextFlags = CONTEXT_DEBUG_REGISTERS | CONTEXT_CONTROL;
                thread = OpenThread(THREAD_GET_CONTEXT | THREAD_SET_CONTEXT,
                                    FALSE, event.dwThreadId);
                if (thread && GetThreadContext(thread, &context)) {
                    dr6 = context.Dr6;
                    if ((dr6 & ((DWORD64)1 << g_watch_slot)) != 0) {
                        if (read_dword(process, g_watch_address, &current_value)) {
                            log_line("WRITE tick=%llu tid=%lu old=%08lX new=%08lX native_rip=%016llX",
                                     GetTickCount64(), event.dwThreadId, g_last_value,
                                     current_value,
                                     (unsigned long long)context.Rip);
                            g_last_value = current_value;
                        } else {
                            log_line("WRITE-READ-FAILED tid=%lu error=%lu",
                                     event.dwThreadId, GetLastError());
                        }
                        context.Dr6 = 0;
                        context.ContextFlags = CONTEXT_DEBUG_REGISTERS;
                        if (!SetThreadContext(thread, &context))
                            log_line("CLEAR-DR6-FAILED tid=%lu error=%lu",
                                     event.dwThreadId, GetLastError());
                        CloseHandle(thread);
                        ContinueDebugEvent(event.dwProcessId, event.dwThreadId, DBG_CONTINUE);
                        continue;
                    }
                }
                if (thread)
                    CloseHandle(thread);
            }
            ContinueDebugEvent(event.dwProcessId, event.dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
            continue;

        case EXIT_PROCESS_DEBUG_EVENT:
            log_line("EXIT pid=%lu code=%lu", event.dwProcessId,
                     event.u.ExitProcess.dwExitCode);
            ContinueDebugEvent(event.dwProcessId, event.dwThreadId, DBG_CONTINUE);
            goto done;

        case LOAD_DLL_DEBUG_EVENT:
            close_debug_file(event.u.LoadDll.hFile);
            break;
        case EXIT_THREAD_DEBUG_EVENT:
        case UNLOAD_DLL_DEBUG_EVENT:
        case OUTPUT_DEBUG_STRING_EVENT:
        case RIP_EVENT:
        default:
            break;
        }
        ContinueDebugEvent(event.dwProcessId, event.dwThreadId, DBG_CONTINUE);
    }

done:
    if (attached)
        DebugActiveProcessStop(g_pid);
    if (process)
        CloseHandle(process);
    if (g_log)
        fclose(g_log);
    return last_error ? 7 : 0;
}
