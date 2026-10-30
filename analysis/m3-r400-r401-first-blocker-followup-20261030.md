# r400/r401 first-blocker follow-up — 2026-10-30

## Scope and safety

Checked completed reports before acting; r394–r396 was the latest report at the start of this pass. The two later closed diagnostic folders were r400 and r401. Process inspection found no active `your_game_recomp` or `GuestWriteBreakpoint` process before the final inventory. The two runs used the r368 writable save root directly; no save copy or hard link was made. No unrelated process was interrupted.

Both runs used the candidate bundle at `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-apu-invalid-voice-guard-r399-20261030/Release/` and generated source `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. The exact bundle is:

| File | SHA-256 |
|---|---|
| `your_game_recomp_producer_trace.exe` | `768EA2C6E1AA27D43743BC3CADDC4C3FD2E2FEA59209E60EE60862C1C6452D57` |
| `your_game_recomp_producer_trace.map` | `329CCF75CF42F09976AD1739DA1F48A7F08CD2967A344FD1B850939D86BDB5DA` |
| `your_game_recomp_producer_trace.pdb` | `F138844A899FCA2E105412FEA3E3F00EC2143C39D7CD668D40C28BE05D5F72E0` |

## r400: Campaign-list crash

Run `m3-apu-guard-loader-r400-20261030`, PID 188744, reached the Campaign menu via screen-gated input and crashed on the subsequent menu action. It did not reach pilot selection or loading. The APU invalid-voice guard did not emit in this run.

The log shows an earlier valid DirectSound node at `0x8038C098`, then a commit walk with an invalid predecessor whose `next` is `0xFF000000`, followed by a null node. The fault was an access violation reading host `0x10000FFF4`, translated guest VA `0xFFFFFFF4`, at host RIP `0x7FF6B8B04F08`. Faulting TID was 177512; the exception code was `C0000005`. The minidump SHA-256 is `651CB2FB6D289045C0EB28A9A071B8D94DBC8F2ED18F7593511C6849B84E0DC0`.

The exact bundle maps RIP to `sub_0021ED29+0x88`, generated source `recomp_0016.c:1717`. Caller guest address `0x0021FECA` computes `EBX-0x20` and calls the routine; exception registers contain `EBX=0`, `ESI=0xFFFFFFEC`, and `EDI=0x010810A4`. The callee reads `MEM32(ESI+8)`, producing the fault at `0xFFFFFFF4`. This supports the null list node as the immediate fault cause. It does not identify the writer that invalidated the list. The native unwind yielded the module fault frame only and stopped at a non-module address, so it is not a complete native/guest unwind.

## r401: writer watch did not reproduce

Run `m3-dsound-node-writer-r401-20261030`, PID 177292, armed a cross-thread hardware watch on guest `0x8038C098` (host `0x8039C098`). The helper recorded 51 matched/armed rows and no write hit. The game did not reach the same Campaign failure: after title input the window went black at 0 FPS. Therefore the absence of a hit cannot rule out a writer; the trigger state was not reproduced.

Snapshot `stall-snapshot-001.dmp` SHA-256: `7BAB409D34DC80DE3D9640C073A36E30AADB2FF174DFD32D22011AD229A1ED48`. TID 186840 unwound through `ntdll.dll+0x161DD4`, `KERNELBASE.dll+0x1BE9F`, game `+0x64A9A59`, and `xbox_KeWaitForSingleObject+0x29`, then stopped at synthetic boundary `0xED4`. This is a valid native unwind but does not reveal the guest wait object.

The captured DCF4 wait at tick `591919953` returned at `591919968`, 15 ms after a signal. No persistent DCF4 hang was reproduced. The wait log’s bounded sampling/cap did not establish the later terminal wait state. Accordingly, no DCF4 producer-stage investigation or synchronization change is justified by r401.

## Hypothesis and result

**Hypothesis:** the r400 crash is caused by a prior write corrupting the DirectSound list node at `0x8038C098`.

**Evidence that supports:** r400’s invalid list walk, null-node call, guest register state, and exact-bundle callee instruction line up with the AV.

**Evidence that would confirm the writer:** reproduce the same screen-gated Campaign action and capture a write-watch hit with guest address, old/new value, thread, and exact-bundle native RIP before the invalid walk.

**Result:** immediate fault is supported; corrupting write remains unknown. r401 does not confirm or reject the writer hypothesis because it failed to reach the same state. No DirectSound behavior fix was made. The separate r399 APU guard addresses the r398 invalid voice index only; it did not trigger in r400 and is not tied to this crash.

## Thread-object completion semantics (separate loader evidence)

The current `kernel_bridge.c` implementation was checked rather than repeating the older r130 null-output diagnosis. It initializes the guest thread object's `+0x120` status to `STATUS_PENDING`, polls the native handle with a zero-time `WaitForSingleObject`, and on `WAIT_OBJECT_0` copies `GetExitCodeThread` to the guest field. `ObReferenceObjectByHandle` writes the object address only when the caller's output pointer is non-null, then returns success if the handle resolves. This update is performed when the object lookup is called; it is not an asynchronous write at thread exit.

Existing r391 runtime evidence observed thread token `0x48000078`, guest object `0x019204A0`, and status transition `0x103` to exit code `1`; the worker logged `PsTerminateSystemThread(status=1)`. Thus pending-to-completed status propagation is verified for that worker. Exit status 1 is not itself a loader error, and this does not prove the separate mode-2 readiness condition accepted the completed worker. No code change was made for this path.

## Storage and build impact

The final inventory after the report/status artifacts counted 77,780 ordinary files, totaling 41,498,777,888 allocated bytes and 1,397,464,756,894 logical bytes. Thirteen skipped executable reparse paths were measured separately at 165,381,632 allocated bytes, giving **41,664,159,520 total allocated bytes (38.803 GiB)**. Sparse logical lengths are not disk use. Inventory files are stored outside the repository as `sb-inventory-current-r401-final3-20261030.csv` and `.skipped.txt`.

This pass reclaimed **80,239,114 allocated bytes** through lossless NTFS compression with content hashes preserved: 78,582,976 bytes in four misrouted r399 outputs retained under `iso/local-analysis/delete-later/r399-relative-msbuild-output`, and 1,656,138 bytes in closed r397/r398/r400/r401 evidence. No files were deleted. The 22 validated cache duplicates remain because the automatic execution review rejected the deletion command as **“blocked by policy”**; it did not run, so deletion savings are zero.

The warm seeded build cache remains at 6,991,569,062 allocated bytes. The isolated r399 candidate build took about 6.5 seconds with no compiler warnings. No additional game build was run for r400/r401. Original ISO/assets, unique saves, dirty source, edited generated code, licenses, exact executable/symbol bundles, and warm build inputs remain preserved. No dense copies of sparse save images were made.

## Status and next action

Neither run reached pilot selection, the loading screen, or a mission frame. First mission frame remains unverified (0/1); the earliest current blocker is intermittent invalid DirectSound list state at Campaign entry. The first loader dependency remains unknown because r400/r401 never reached loading. Audio, full controller behavior, campaign completion, and performance targets also remain unverified.

Before another diagnostic, inspect the existing r150/r151/r153 dumps with their exact matching executable and symbols. Then retry only the r400 screen-gated Campaign route with the write watch and bounded failure-window telemetry, and accept a writer conclusion only if the same failure state is reached. Keep title DCF4, this DirectSound fault, rendering cost, and post-difficulty loader plateaus separate. Preserve AOT, controller mapping, guest fences, and rasterizer `1ea1871`.
