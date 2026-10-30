# Steel Battalion AOT loading evidence — r376–r378

## Current finding

Milestone 3 is still active; the first visually verified mission frame is **0/1**. No runtime behavior or generated game code changed. The current evidence does not support a loader fix yet.

r377 is the newest run that reached Normal difficulty. It created a mode-2 worker object and kept polling it as pending while the loader's result pair stayed zero. The last traced successful file read was `STRM07.WAV`; its read status was zero and its source handle closed successfully. This rules out that particular read as the observed missing completion, but does not rule out another unobserved dependency or readiness producer.

Three valid r377 native unwinds, from guest-main, the mode-2 worker, and a render-heavy thread, enter the same CRT `fprintf` wrapper at `EXE+0x543BBD`. That is a strong trace-output contention lead. It is not proof of a specific locked object, owner, or sole cause. The older r308 trace directly captured a dispatch-gate owner in its own run; that cannot be carried over as the owner in r377. r378 enabled bounded dispatch-gate tracing but ended at the title route before its delayed snapshot and before a long-hold record. There is still no current-run lock owner.

## Offline dump review before another run

The existing r150, r151, and r153 dumps were reviewed with their preserved r149 AOT bundle before starting r378. The matching bundle is:

- EXE SHA-256: `D503E6DA6325E9771364C9160F358A21550128B34AAC7B500A34C0EE0642A15C`
- PDB SHA-256: `1741EA1E29FEF3DF9E7AD5D30AF3E30BAECCCB0DFFB93C1649080095A2A94287`
- MAP SHA-256: `4AE43B0B58C029D290E9041297232C303E9EBF0E8FC04D54761EB5BBFE4A6A37`

The checked per-thread unwind output is in [the r150–r153 review](m3-dump-unwind-review-r150-r153-20261028.md). r150/r151 guest-main unwinds reach `xbox_KeWaitForSingleObject+0x29`; the validated guest wait comes from r151's event trace, wait #73 on event `0x0021DCF4`. The trace has no subsequent index-5 callback/`KeSetEvent` before stop. This is a title/menu wait. Their raster workers unwind to the normal `raster_worker+0x9F` wait; the next displayed address is pool data, not a return frame. r153's two guest CPU threads unwind to `guest_cpu_acquire+0xAD`; its dump does not preserve owner/queue state or a guest caller chain. Its DCF4 value was signaled during the separate post-difficulty graphics plateau.

These validated native unwinds are distinct from the saved raw stack-address scans. None establishes a common root across title DCF4, worker-pool waits, guest-CPU serialization, and the later loader plateau. The existing bridge implementation already handles `ObReferenceObjectByHandle` pending/completion status; no repeat of the old r130 diagnosis or import seeding is justified.

## Screen-correlated input path

The screen-gated r157 evidence remains the verified pilot-list chain. At the visible `LIST AS NEW` screen, object `0x006B9E1C` selected the row whose XBE string is `LIST AS NEW`. A separate A pulse produced XID byte 2 at guest buffer `0x01081763`; guest edge consumption at `0x000C8064` changed cell `0x004AFC08` from zero to one; parent row updater `0x000E18D8` returned true; branch `0x000E193B` selected action `0x83` at `0x000E19CF`; the item field changed and the next capture showed name entry. This confirms the active row updater for that screen and action. It does not establish `sub_000E0870` as the registered callback.

r378 is not a repeat of that pilot action. The current run started at the Dolby/title path. After screen-gated A inputs, XID and three guest edge-consume records appeared, but the final capture was black. The run had eight predicate samples, three edge-consume rows, five XID/XID-DMA samples, one mode-0 preload request, and no pilot-list callback, loader-state callback, or mode-2 request. It stopped before the 420-second one-shot snapshot. Thus r378 supplies no loading-stage or dispatch-owner evidence and is not presented as a reproduction of r377's loader plateau.

## r377 mode-2 evidence

Run: `m3-loader-evidence-r377-20261030`; diagnostic PID `182652` was verified against its executable and run directory before being stopped. No other game process was stopped. It used the r367 AOT bundle and generated directory `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`, with existing save root `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`.

- EXE SHA-256: `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`
- PDB SHA-256: `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`
- MAP SHA-256: `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`
- `RECOMP_FILE_IO_DETAIL_TRACE` was unset; lifecycle, file calls, reads, loader state/pairs, worker scheduling, thread objects, DMA/semaphore, NV2A, raster-performance, XID, and framebuffer tracing remained enabled. Asynchronous relay capacity was 32,768; run budget 64 MiB; frame-history cap 8; no relay drops or trace-cap markers.
- The visible route reached name `A`, date `01/01/2002`, confirmation, and Normal difficulty, then black. It did not visibly display `NOW LOADING` or a first mission frame.
- Mode 2 routed entry `0x00017E40`; guest thread object `0x013BB000`, host token `0xD74`, TID `174796`, remained pending. Main TID `177084` observed `STATUS_PENDING` (`0x103`). Loader-state callbacks stopped changing progress/status fields; the 16 output pairs remained zero.
- Read n=5034 at tick `576793046`, TID `174796`, handle `0xB04`, offset `3,080,192`, requested `65,536`, returned `63,314`; IOS, NT, and guest status were zero and `async=0`. Lifecycle records identify the active source as `game_files\media\bgm\STRM07.WAV`; the handle closed at tick `576793062`. It is a completed read, not an outstanding I/O wait.
- 30 file misses were logged, but no missing required asset was identified. Paired open-target records were 1,137 begins and 1,137 completions; statuses were successful.
- The earlier 180-second snapshot caught the separate title DCF4 wait before the screen-gated route. Later graphics telemetry showed NV2A progress and raster work, then a subsequent tick with no queued/pending raster jobs. It does not establish rendering backlog as the sole loading cause. DCF4 was signaled in the post-difficulty stage; no separate producer-stage DCF4 trace was enabled.
- The three validated native unwinds stop at non-module values after reaching `fprintf` (`EXE+0x543BBD`). They do not expose a matching native lock owner or guest loader call chain. Raw address scans are not used as unwinds.

The controlled r377 change disabled only file-I/O-detail tracing; the post-difficulty black stall still occurred. Therefore that channel alone is not necessary for the stall. The run still emitted many CRT-backed diagnostics, so shared output/lock contention remains possible but unresolved.

## r378 low-volume owner-trace attempt

Run: `m3-owner-loader-plateau-r378-20261030`, PID `49528`, started from the same r367 EXE/PDB/MAP and r368 save root. It used a 64 MiB evidence cap, asynchronous relay capacity 32,768, dispatch-gate tracing threshold 250 ms/cap 256, thread-object and lifecycle traces, loader pair/callback traces, DMA/semaphore/NV2A signatures, and thread-suspend diagnostics. High-volume file-read and wait-log output was disabled. No build or save copy was made.

The run reached the title's “Unable to load Player Record” screen, then black after the next A input. It did not reach the Campaign or pilot-list screen. It logged no pilot-list callback, loader-state callback, mode-2 request, or dispatch-gate long-hold record. The delayed 420-second snapshot was not reached. Relay drops were zero. I stopped only PID `49528` after verifying that its image path matched the r378 manifest; no unrelated game process was stopped. No dump or valid stack unwind was captured for this run.

The run’s `STRM07.WAV`-unrelated file misses are not evidence of a missing mission asset. Its mode-0 preload request and black title frame keep it in the title-routing failure family. Do not use r378 to reject or confirm r377's loader hypothesis.

## Storage and build efficiency

Fresh scan: `sb-inventory-current-r378-final3-20261030.csv` and its `.skipped.txt` companion, both stored outside the repository. The workspace has **77,488 files**, **41,317,624,956 bytes allocated**, and **1,396,926,759,702 bytes logical**. The 13 Cargo-tool reparse executables were measured separately at **165,381,632 allocated bytes**, giving **41,483,006,588 allocated bytes (38.634 GiB)** in total. Sparse-file logical lengths are reported separately and are not disk usage.

Current retained areas include the warm build tree at **6,918,921,034 allocated bytes**, canonical generated AOT source at **155,887,568 bytes**, and r368 save root at **110,700,940 allocated / 5,422,134,482 logical bytes**. The last measured warm incremental build remains about **9.1 seconds**; no build ran in r376–r378, so this pass has no measured build-efficiency impact.

Hash-verified in-place NTFS compression of closed r376–r377 evidence reclaimed **2,630,200 allocated bytes**. r378's closed logs and BMP were then compressed losslessly; all nine hashes matched, and the compressed folder now allocates **993,646 bytes**. The r378 pre-compression allocation baseline was not captured, so no exact r378 savings are claimed. The separate delete-later archive still contains **383 files**; its last measured size is **1,329,496,337 allocated / 2,092,257,079 logical bytes**. Exact file deletion remains blocked; no deletion attempt or alternate path was made. No ISO, source checkout, generated code, license, save image, active input, or unresolved EXE/PDB/MAP bundle was removed or moved.

## Next evidence and acceptance

Next run should reproduce the r377 post-difficulty route using the exact r367 bundle, then take its single owner/native-thread snapshot only after the mode-2 worker is created. Keep file reads to the exact worker's recent open/read completion window; capture the pending-to-completed thread-object transition and the mode-2 pair at the same timestamps. Preserve the r157 screen/input/callback sequence as the validated pilot-menu reference. Keep DCF4 title waits, DirectSound list corruption, raster cost, and loader readiness separate. Do not bypass guest checks, force a fence/signal/preload, or seed valid imports. Stop only after a visually verified first mission frame or a reproduced, evidenced blocker.

Progress: overall `██░░░░░░ 2/8`; decompilation `██░░ 2/4`; boot/compatibility `████░ 4/5`; rendering `██░░ 2/4`; controller `██░ 2/3`; audio/DSP `█░ 1/2`; first mission frame `░ 0/1`; stable 60 FPS `░ 0/1`.
