# r467 deferred-commit write-watch regression — 2026-10-30

## Purpose

The r466 watcher could not attach when `ReadProcessMemory` returned Win32 error 299 for the watched address. That prevented observing a later write to the candidate guest global `0x51E078` from process startup. r467 changed only the diagnostic helper: the watcher now logs an unreadable initial value, arms the hardware data breakpoint, and waits for the first readable value/write.

## Exact regression

- Helper: `local-tools/GuestWriteBreakpoint.exe`
- Helper SHA-256: `CA249953AEA927C6808B5AE8147BADC5198AD6B66031E83E4B6259037B219F54`
- Test target source: `tools/tests/GuestWriteBreakpointDeferredCommitTest.c`
- Test target executable: `C:\Project\sb-write-watch-regression-r467\GuestWriteBreakpointDeferredCommitTest.exe` (141,312 bytes)
- Target PID: `21252`
- Reserved page: `0x0000022C3DB60000`; committed after attach.
- Regression log folder: `C:\Project\sb-write-watch-regression-r467`

Observed sequence: target announced the reserved page; watcher logged `initial=unreadable error=299; arming address watch`, then `ARMED`; after the target committed and wrote `0xA55AA55A`, watcher recorded the write and native RIP `0x00007FF79E0F1187`. The later zero write occurred during page release. Both processes exited cleanly. This verifies only the helper's deferred-commit path; no XboxRecomp process was involved.

## Limits and next use

The helper change does not modify the game, generated AOT code, controller mapping, guest synchronization, or rasterizer. The next diagnostic should use the exact r461 executable/PDB/MAP and existing save root, keep XID-to-edge and menu/pilot traces enabled, and apply input only after inspecting each captured framebuffer. It must correlate any `0x51E078` store with the already observed `sub_000450C0` branch and subsequent `0x3FFF` lookup before considering a gameplay fix.
