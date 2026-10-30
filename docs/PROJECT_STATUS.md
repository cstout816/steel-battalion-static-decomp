# Steel Battalion project status

## Current index — r391, 2026-10-30

**Milestone 3 remains active. First visually verified mission frame: 0/1.** r391 reached the new-pilot route through Normal difficulty, then stopped at a solid white framebuffer. It did not verify a visible `NOW LOADING` label or mission frame. Mode-2 loader scans stopped at pair `0x000ABA00/0`; file samples succeeded; one worker completed with status 1; DCF4 was signaled and raster workers drained. The first missing dependency and expected readiness producer remain unknown. See the [r386–r391 loader and storage review](../analysis/m3-r386-r391-loader-and-storage-review-20261030.md).

| Area | Verified state | Next evidence |
| --- | --- | --- |
| AOT/XBE | Exact r367 EXE/PDB/MAP bundle retained; AOT path unchanged. | Keep the same image and symbols. |
| Loader/readiness | r391 helper index `0x1E` reached decision 6; mode-2 pair stopped at `0xABA00/0`; worker pending-to-exit status propagated. | Trace the specific readiness producer and consumer with a bounded state probe. |
| Stacks | Main TID 177520 unwound to `sub_0020EC00+0xCD` only; no validated guest caller chain. | Capture a valid guest PC/stack or producer-consumer state at the plateau. |
| Files/audio | 2,599 lifecycle opens, 2,185 closes; sampled reads succeeded; no missing dependency established. | Name a dependency only from correlated completion/status evidence. |
| Rendering/synchronization | White framebuffer; terminal DCF4=1, batches/workers/pending=0. | Keep separate from r387 title DCF4 and earlier renderer cost. |
| Controller/campaign | New-pilot route reached Normal; no mission frame or campaign progression. | Stop at the first visually verified mission frame. |

**Testable hypothesis:** after worker `0x00034720` completes, a separate loader readiness producer fails to update the state consumed after helper index `0x1E`. Confirm only if a bounded trace shows no producer update while that consumer continues polling; reject if the expected state was updated or accepted. No code behavior fix is supported yet.

**Storage:** fresh scan measured **41,523,983,574 bytes allocated (38.67 GiB)** including 13 separately measured Rust reparse executables; logical total **1,397,117,959,601 bytes**. This is 27,881,743 bytes above r385, a net difference not attributed to one run. Closed r386–r390 compression reclaimed **11,522,408 bytes** with hashes preserved; r391 compression saved 0; no files were deleted or moved. Warm build cache remains 6,918,921,034 bytes, canonical generated source 155,887,568, saves 166,480,594 allocated, and logs 3,043,619,235 allocated. Last measured incremental build: about 9.1 seconds; no build ran. See the [r391 cleanup manifest](../analysis/current-cleanup-manifest-r391-20261030.md).

Overall `██░░░░░░ 2/8` · decompilation `██░░ 2/4` · boot/compatibility `████░ 4/5` · earliest blocker diagnosis `████░ 4/5` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

**Current milestone:** 3 — boot and compatibility. **Next acceptance point:** first visually verified mission frame.
## Previous verified state — r349–r354

## Prior verified state — r340–r348

**Milestone 3 remains active.** First visually verified mission frame: **0/1**.

Overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · earliest blocker diagnosis `███░ 3/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

r340 directly captured the renderer's `put_pixel` store writing `FF000000` into guest DirectSound list fields `8038C08C`, `8038C098`, and `8038C09C`; the list walk then crashed at `sub_0021ED29+0x88`. The bad store's active color-surface state is still missing, so no behavior fix is justified. r348 used the 16-record opt-in overlap trace, reached the new-pilot name/date/Normal route, and recorded no watched list write. Its final frame remained at difficulty; 19 mode-2 readiness scans returned result zero and the child-only NV2A watchdog stopped it after graphics progress halted. The 4 MiB reserve fallback to 2 MiB succeeded and is not a proven cause. Keep title DCF4 waits, the r340 audio-list crash, raster cost, and post-difficulty loading plateaus separate.

Earlier r151 evidence still identifies a title DCF4 wait with no subsequent index-5 callback/`KeSetEvent`; r153's dump is only a DSP point sample and does not identify the frozen guest owner. The r130 null-output handle behavior is already implemented; its completion semantics remain uncorrelated with loader readiness. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` are unchanged.

Current storage is **48.983 GiB allocated** and **1,290.154 GiB logical**; the [current cleanup manifest](../analysis/current-cleanup-manifest-20261029.md) has exact totals and the inventory path. r347 losslessly compressed 41 historical `Cache\MOTION.BIN` copies after all hashes matched the retained extracted-media asset; allocation fell by **945,311,744 bytes** with 41/41 post-checks passing. Earlier closed-evidence compression reclaimed 2,036,043 bytes. The 40 duplicate `TEXOBJ.BIN` copies remain because automatic file-action review blocked deletion and compression saved no space. No hot compiler/Cargo cache or unique save was changed. See the [r340–r348 report](../analysis/m3-r340-r344-surface-and-storage-20261029.md), [r348 run report](../analysis/m3-r348-mode2-plateau-and-storage-20261029.md), and [r347 compression audit](../analysis/r347-motion-cache-compression-20261029.csv).

**Current milestone:** 3 — boot and compatibility.
**Next acceptance point:** first visually verified mission frame.

## Progress

Overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · earliest blocker diagnosis `███░ 3/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

## Historical DirectSound evidence — r333–r337

See the [r333–r337 DirectSound and storage follow-up](../analysis/m3-r333-r337-directsound-storage-followup-20261029.md). r334 remains the strongest writer-correlated Campaign failure: host TID `178296` wrote `0xFF000000` into guest list fields `0x8038C08C`, `0x8038C098`, and `0x8038C09C`; its host RIP resolves inside `raster_batch_program` at a pixel store, followed by an invalid-list crash at guest VA `0xFFFFFFF4`. This does not establish the active color-surface state, and r355's later invalid-node event has no matched writer evidence. No behavior fix is supported.

r337 added an opt-in register snapshot to the three address watchpoints (reproducible patch: `patches/diagnostics/dsound-write-watch-registers-r336.patch`) and used the same r336 EXE/PDB/MAP bundle. The run remained at a black title-stage frame; XID/DMA saw the second A pulse, but no guest edge followed. NV2A telemetry froze at frame `0xCE`, counter `0x377`, target `0x36D`, fence `0x373`, with zero raster batches/pending jobs. The watched fields showed nine initialization writes and no corruption. Thus r337 does not reject the r334 raster hypothesis because it did not reach Campaign. r335–r337 dumps contain raw guest-address candidates, but valid native unwinds stop at the game-image boundary; none verifies the guest wait call chain or owner. DCF4 was zero in r336/r337. Keep title black-frame behavior, DCF4 waits, DirectSound corruption, render cost, and loading plateaus separate.

r336's 500/500 ms input replay was not comparable to r334. r337 repeated 500/2,000 ms pulses, but still did not reach Campaign. Do not send further input against a black frame. The latest visually verified loading transition remains r328; first mission frame remains 0/1. `ObReferenceObjectByHandle` pending/completion behavior is implemented, but completion has not been tied to loader readiness. AOT, controller mapping, guest fences, and rasterizer `1ea1871` are unchanged.

## Historical storage snapshot — r337

Fresh inventory `C:\Project\sb-inventory-current-r337-final-20261029.csv`: **76,986 files**, **53,463,861,377 bytes allocated (49.792 GiB)** and **1,385,102,464,443 bytes logical (1,289.977 GiB)**; 13 reparse entries skipped. `iso` uses 29.49 GiB allocated; `local-tools` 20.09 GiB. The old r332 measurement was 49.720 GiB allocated; r336's required diagnostic EXE/PDB/MAP and evidence account for the net growth. r334–r335 compression saved 842,384 bytes; r336–r337 plus exact bundle compression saved 1,785,849 bytes, all SHA-256 verified. No files were deleted or moved. The 40 exact duplicate TEXOBJ copies remain because automatic file-action review blocked deletion; their verified path-summed allocation is about 1.30 GiB. No hot cache was purged. The isolated incremental trace build completed in 9.1 seconds; latest gameplay milestone remains unverified.

## Prior inventory — r329

The [r322–r329 follow-up](../analysis/m3-r322-r329-loader-storage-followup-20261029.md) records the final scan at **53,894,717,206 bytes allocated (50.193 GiB)** and **1,384,901,643,736 bytes logical (1,289.790 GiB)** across 76,870 files; 13 reparse paths were skipped. Sparse save/dump images dominate the logical total. Lossless NTFS compression on the inactive diagnostic-bundle tree reclaimed **876,297,279 allocated bytes (835.7 MiB)**; all 202 files remain. A manifest audit verified 126 EXE/PDB/MAP hashes without mismatch; 74 unlisted files were retained, with the current r326 bundle independently rehashed. No files were deleted or moved. The warm build cache, rollback build, generated AOT source, ISO, extracted media, unique saves, and unresolved dump bundles remain protected. No new build ran; the latest recorded incremental build remains 8.65 seconds from r324.
## Prior evidence — r291–r292

See the [r291–r292 storage and loading review](../analysis/m3-r291-r292-storage-rendering-review-20261029.md).
Current workspace inventory: 53,408,221,807 allocated bytes (49.740 GiB), 1,382,434,492,076 logical bytes, 76,124 files; 13 Cargo-tool reparse paths skipped. Lossless compression reduced path-summed allocation by 5,270,570,586 bytes since the pre-compression scan with every bundle hash preserved. No deletion occurred. The full `build-xpp-seeded` subtree currently measures 5.76 GB allocated after lossless candidate compression; r293 incremental build took about 14.3 seconds and r292 about 9 seconds. No cache purge occurred. See `analysis/current-cleanup-manifest-20261029.md` and `analysis/candidate-bundle-compression-r292-20261029.csv`. The new-pilot route reached the loading transition in r292, then showed a black COMPLETE screen at 0 FPS / 38 draws. The first mission frame remains unverified.

r292 recorded a 32,301,056-byte guest reserve succeeding, followed by a 4 MiB request clamped to 2 MiB and returned as success. Later sampled reads succeeded; this does not establish the clamp as the cause. The 480-second snapshot has valid native unwinds to the guest DCF4 wait, xf_rows transform path, and framebuffer thread. DCF4 waits continue to receive matching sets. Raster samples remain heavy, with roughly 36 batches / 72 triangles in three seconds and 11–12 seconds of aggregate raster-active time across four workers. That supports rendering backlog as a material factor, but does not identify a missing loader dependency or prove the renderer is the sole blocker.

The loader callback emitted only six mode-2 scan passes with zero entry pairs; sampled file tracing stopped at n=10,000 and file paths were not enabled. The allocator worker was absent from the final dump. Next diagnostic: bounded recent-window file-open/completion correlation plus thread-object pending-to-completion status transitions. No runtime fix is supported yet. Keep this separate from r290's selector 0x3FFF retry, r151 title DCF4 wait, and DirectSound list corruption.

## Previous evidence — r284–r285

See the [r284–r285 loader helper and callback A/B report](../analysis/m3-r284-r285-loader-helper-and-callback-ab-20261029.md). r284 used the new-pilot route through Normal difficulty, then stalled at black; it did not visually verify `NOW LOADING` or a mission frame. Its eight mode-2 passes repeatedly reached helper index `0x1E`, decision `5` at `0x000C300D`, where the guest byte check is `MEM8(eax + 0x351F04) != 1`. The helper returns `1` unconditionally on that path, so that return value does not prove readiness. The output pair remained `0/0` at the final scan.

r284's valid native unwind for guest-main host TID `139032` reaches `trace_load_state_callback+0x102` through UCRT, with no memory-read failures but stopping at a non-module address. Its separate callback log contains 281 rows. This makes callback file I/O a candidate, not a proven cause. r285 disabled only that trace but stalled at title/black before loader entry: XID received one A pulse, but no matching guest edge or route advance was recorded. The A/B is inconclusive and does not support a behavior fix. The runner's final marker scan now includes the dedicated callback file; a focused recount verified 281 retained r284 rows.

The [prior r282–r283 report](../analysis/m3-r282-r283-render-loader-evidence-20261029.md) remains valid for its own runs: r283 reached visible `NOW LOADING`, and its expensive raster workload did not establish a loader cause. The unmatched final WAV open is still a watchdog-cutoff artifact. DMA/PBSEM, historical title DCF4 waits, and DirectSound list corruption remain separate. No runtime fix or rebuild is supported.

## Historical diagnosis retained

The [r276–r278 triage](../analysis/m3-r276-r278-audio-loader-triage-20261029.md) still documents the separate DirectSound crash: r278 validates cursor `0xFFFFFFEC` reaching `sub_0021ED29` and faulting at guest VA `0xFFFFFFF4` (`EXE+0x61A3E78`, `sub_0021ED29+0x88`); the earlier corrupting write remains unknown. r277’s black post-difficulty plateau, the title DCF4 wait, rendering cost, and the current r281 loading plateau are distinct evidence. Do not merge them or infer a common cause.

The r130 null-output `ObReferenceObjectByHandle` defect is implemented in current source. Valid thread handles map to guest objects; active threads expose `STATUS_PENDING`; completed Win32 threads update guest status from their exit code. r136 observed a pending guest thread object and worker scheduling. Completion advancing this game’s readiness path remains unverified; do not repeat the old diagnosis without correlated evidence.

The r284–r285 and r288–r290 next-step notes are historical. The selector `0x3FFF` retry remains a separate r290 candidate; the current next diagnostic is bounded file-open/completion correlation plus thread-object completion tracing for the r292 mode-2 stage.

## Storage and source recovery

The latest full scan before closed-bundle compression measured 76,120 files, 58,678,792,393 bytes allocated (54.649 GiB), and 1,382,433,587,670 logical bytes (1,287.492 GiB); 13 Cargo-tool reparse paths were skipped. After compression, 164 closed diagnostic EXE/PDB/MAP files have matching before/after SHA-256 values. Path-summed allocated bytes fell by 5,271,474,992 bytes across the two compression passes; no file was deleted and no build cache was changed. A final post-documentation inventory is recorded in the current cleanup manifest.

The warm `build-xpp-seeded` cache remains at its last measured 10,615,458,949 allocated bytes. r292's incremental isolated build completed in about nine seconds. See the [current cleanup manifest](../analysis/current-cleanup-manifest-20261029.md), [r291–r292 report](../analysis/m3-r291-r292-storage-rendering-review-20261029.md), and [source preservation manifest](../analysis/source-preservation-manifest-20261029.md).

Dirty checkout recovery: [source preservation manifest](../analysis/source-preservation-manifest-20261029.md). It records project and XboxRecomp patch hashes/base commits plus the 27-file generated-source manifest; generated game code stays out of Git. The warm build remains available; the last measured incremental build took 17.6 seconds.

## Milestone 1 tool verification

The 371-row Xbox kernel ordinal-reference set and Java Ghidra scripts are verified in the local Ghidra scripts folder and packaged in `C:\Project\GhidraAnalysis\scripts\XboxKernelOrdinals-GhidraSupport-20261029.zip`. Use the Ghidra 12.1.4 install with the XBE extension; the local 12.2 install lacks it. Exact-name XbeTripper/xberewrite sources remain unverified. Cxbx XBE inspection is useful for read-only metadata/integrity checks, not for validating the AOT runtime. The active XboxRecomp AOT architecture is unchanged; no XBE hooks or edits were made.
**Still unverified:** the first mission frame, the expected writer for selector `0x3FFF`, audio playback correctness, controller behavior beyond menu navigation, 60 FPS, mission completion, and campaign progression.
