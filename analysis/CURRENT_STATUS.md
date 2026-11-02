# Current checkpoint — r790–r792 mode-2 and loading follow-up (completed, 2026-11-02)

R792 reused the R791 AOT EXE/PDB/MAP bundle and the existing save root. It screen-gated 37 retained r781 route actions through pilot setup, Normal difficulty, and loading. This is not an exact replay of r519's executable/environment/40-action bundle. No saves were changed; no `user*.sav` file was created, and all slots remain open.

The resource `0x1E` readiness consumer first saw `0x00351F22=0`, then preload worker TID 105432 recorded asset `0x1E` and set the byte to `1` at tick 301076250. The subsequent mode-2 pass returned 0 with progress `0x000ABA00/0`. At the 900-second snapshot, mode `2`, progress `0xABA00/0`, and statuses `0/0` persisted through callback polling. The four sampled callback sites resolve to synthetic critical-section imports; their zero return is not a completion result. The later predicate and producer remain unknown.

R792 also recorded repeated guest heap OOM requests near the 50,855,936-byte heap ceiling and a 10,640-byte null-buffer `NtReadFile` access violation. The allocation callsite/branch and the file handle/path for the null read were not captured, so neither is established as the cause. Raster work was heavy, but DCF4 waits returned, DCF4 was signaled at the snapshot, PGRAPH pending was 0, and NV2A PUT equaled GET. The final framebuffer was blank/white at 0.0 FPS; no first mission frame was verified.

Only diagnostic PID 110640 was stopped after >900 seconds with no usable UI frame. A same-run 1,031,119-byte minidump and bounded watchdog snapshot are retained. R792 used 15,032,419 logical / **3,389,726 allocated bytes** and reused the R791 candidate bundle at **72,609,792 allocated bytes**. No bundle duplication, build-cache change, save change, or storage reclamation occurred. Details: [r790–r792 report](m3-r790-r792-mode2-and-loading-20261102.md).

| Area | Progress | Current evidence |
| --- | --- | --- |
| Pilot setup route | [##########] 1/1 | Normal and loading reached on R792's 37-action r781 route. |
| Resource `0x1E` | [##########] 1/1 | Ready flag set and observed. |
| Later mode-2 handoff | [####----------------] 2/5 | Progress remains `0xABA00/0`; completion predicate/producer unknown. |
| OOM and file error | [####----------------] 2/5 | Failures reproduced; causal caller and branch not established. |
| Rendering/synchronization | [######--------------] 3/5 | Expensive raster activity; sampled DCF4/PGRAPH/DMA state drained. |
| First mission frame | [--------------------] 0/1 | Not visually verified. |
| Storage/build | [##########] 1/1 | 3.39 MB R792 evidence; existing R791 bundle reused; no build/cache change. |

**Next:** statically correlate the recorded OOM and null-read requests to their callers and failure branches, then add only the missing bounded trace. If another route is required, use the original r519 executable/environment/input reference and the existing save root. Keep title DCF4, raster work, memory exhaustion, file errors, and the later mode-2 predicate separate.

---
# Current checkpoint — r789 new-pilot route restored; mode-2 readiness plateau (completed, 2026-11-02)

The R788 title error was traced to a blank `user99.sav`: R746 recorded a successful read, helper return 1 at `0x000DF7B4`, and error-selection branch `0x000DF7D0`. The current file's 2,792-byte pilot payload was verified all-zero and moved reversibly to `iso/local-analysis/save-rollback/r788-blank-user99-record-20261102/user99.sav` (SHA256 `01AC743B41D67BF08E771FB291455599E9CD2543D3DAAAC44C2F00B91FDB5F6C`). The other eight blank records remain in r761 rollback. No save was deleted; this same-drive move reclaimed 0 bytes.

R789 reused exact r775 AOT EXE/PDB/MAP and the same save root. With `user99.sav` moved out, the title error disappeared; the fresh-frame route entered Campaign, `LIST AS NEW`, name/date entry (`01/01/2002`), and Normal difficulty. All 37 known actions were accepted. After the final action, the screen went black. First mission frame remains **0/1**.

At tick `296563812`, loader TID `113092` sampled resource `0x1E` readiness byte `0x00351F22=0` (expected 1); helper decision was 5 and pass result 0 with pair `0/0`. At tick `296563937`, the second pass again returned decision 5, result 0, progress `0x001AD98E/0`. The consumer emitted once; all `MODE2-READY-ASSET-*` producer counters were zero. Preload metadata opened indices 2, 3, and 4 successfully, but those rows do not identify the ready-byte producer. Internal split entries at `0x13DD9`, `0x13DE7`, `0x13E78`, and `0x13ECE` bypass the outer producer trace, so the missing rows remain inconclusive. No readiness fix is supported.

DCF4 waits returned before the mode-2 plateau (last sampled wait #8832 returned status 0 at tick `296560062`); the R788 title-stage DCF4 wait remains separate. The R789 UI watchdog stopped only PID 111360 after 300 seconds without frame/input change and retained `ui-plateau-stall.dmp`. Exact-bundle native unwind of TID 113092 reaches UCRT `fprintf` / executable `+0x543BBD` then synthetic `0xE9C`; raw stack candidates do not establish a guest unwind or logger owner. Mode-2 wait versus CPU/logging contention is unresolved.

R789 retained 27 files, 34,236,013 logical bytes / **11,508,005 allocated bytes**, within the 64 MiB cap; relay drops were zero. Trace caps were reached for file-open, NT wait, DCF4 gate, DCE4 wait, and guest-frame traces; see [R789 report](m3-r789-open-slot-route-mode2-plateau-20261102.md). No build/cache/source/ISO change. Current active root has no `user*.sav`; nine validated blank save records are preserved in r761/r788 rollback folders.

| Area | Progress | Verified state |
| --- | --- | --- |
| Title route and slot access | [##########] 1/1 | Error removed with reversible blank-record move; Campaign and LIST AS NEW reached. |
| Pilot creation path | [##########] 4/5 | Name/date and Normal screens visible; no mission frame. |
| Mode-2 readiness | [######--------------] 3/5 | Resource `0x1E` remains not ready; split producer path uncorrelated. |
| First mission frame | [--------------------] 0/1 | Final frame black; not verified. |
| Storage/build | [##########] 1/1 | 11.51 MB allocated for R789; no code build/cache changes. |

Next: instrument only the internal split entries and byte-set/clear sites in the resource `0x1E` producer, build one isolated AOT diagnostic bundle, and replay the same fresh-frame route. Keep R788 title DCF4, R788 player-record error, and R789 mode-2 readiness distinct. Do not force readiness or event completion.

# Historical checkpoint — r788 title player-record error and DCF4 wait (completed, 2026-11-02)

R788 reused the exact r775 AOT EXE/PDB/MAP and existing save root; no build or source changed. Its initial frame gate sent zero input, then the fresh-frame continuation sent four of 37 recorded actions. The final retained frame visibly says **“Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.”** Campaign and mode 2 were not reached. Preload-asset instrumentation was not exercised; all mode-2 trace counts are zero. No input was sent after the frame gate expired.

DCF4 waits #1490–1495 returned successfully after method-5 callbacks selected `0x0021701E` and event-set telemetry. Wait #1496 began at tick `295348125`, TID `100856`, guest wait `0x00211F39`, event `0x0021DCF4`, descriptor `0x80083D70`, method `0x40100` / parameter 5, sequence `0x2297`; no return was recorded. Later callbacks with arguments `0x01080021` and `0x03600021` selected queue-update target `0x00216EC9`; the queue was empty at tick `295348531`. At tick `295349125`, DCF4 signal remained 0 with raster active/pending 0 and DMA PUT=GET=`0x6D28`. This confirms a separate title-stage wait after graphics work drained, but does not identify the missing publication predicate. Marker sampling is sparse (78 retained rows); an absent marker row is not proof that no write occurred. No fix is supported.

R788 retained 24 files, 17,530,294 logical bytes / **6,252,386 allocated bytes**, within 64 MiB. It reused the existing bundle, build cache, and saves; no save or source changes. Its DCF4 watchdog stopped only diagnostic PID 101328; no Steel Battalion process remains active. First mission frame remains **0/1**. Details: [R788 report](m3-r788-title-error-and-dcf4-wait-20261102.md).

R787 audit correction: its missing `MODE2-READY-ASSET-*` rows do **not** favor missing dispatch. Generated split entries at `0x13DD9`, `0x13DE7`, `0x13E78`, and `0x13ECE` may bypass the outer `sub_00013D70` trace marker. The producer remains uncorrelated; no mode-2 fix is supported.

| Area | Progress | Verified state |
| --- | --- | --- |
| Title/player-record route | [##------------------] 1/5 | Error frame retained; originating branch and operation unresolved. |
| Title DCF4 | [######--------------] 3/5 | Wait #1496 unsignaled after raster/DMA drain; producer predicate unresolved. |
| Mode-2 loader | [######--------------] 3/5 | R787 resource `0x1E` not ready; producer trace absence inconclusive due internal split entries. |
| First mission frame | [--------------------] 0/1 | Not verified. |
| Storage/build | [##########] 1/1 | R788 used 6.25 MB allocated; no build/cache/save changes. |

R746 already traced the R788 Player Record error to the successful read of a blank `user99.sav`, helper return 1 at `0x000DF7B4`, and branch `0x000DF7D0`. R789 moved that validated blank file reversibly and entered Campaign. Keep the R788 title DCF4 wait separate from the R789 mode-2 plateau.

# Historical checkpoint — r787 mode-2 readiness plateau (completed, 2026-11-02)

The exact r775 AOT bundle and existing save root were reused. A fresh-frame continuation delivered all 37 known route actions; the retained image `frame-history/capture-0043.bmp` visually verifies **Normal** difficulty. The next two captures were black, and no first-mission scene was verified. The diagnostic UI-plateau watchdog stopped only PID 111708 after 300 seconds without framebuffer/input progress and retained a matching dump. No Steel Battalion process is active.

R787 entered the mode-2 loader at guest tick 294424187. At helper 18 / resource `0x1E`, ready byte `0x00351F22` remained 0 while expected 1; the pass exited result 0 with progress pair `0x001AD98E/0`. Targeted startup STRM03 read completed all 4,522,030 bytes successfully. Static code identifies `sub_00013D70` as the candidate producer: it sets the byte at guest `0x00013E4A` only after asset copy. R787 traced the consumer but emitted no producer-entry/copy/set row. However, internal dispatch entries at `0x13DD9`, `0x13DE7`, `0x13E78`, and `0x13ECE` can bypass the outer trace marker, so the absent event is inconclusive; producer dispatch/timing and trace-output behavior remain unresolved. The dump snapshot has DCF4 signaled, PGRAPH drained, and NV2A PUT=GET. Its exact-bundle native TID 102492 unwind reaches UCRT `fprintf` / executable `+0x543BBD` and stops at synthetic address `0xD4C`; no validated guest call chain or logging-lock owner is established. Details: [r787 report](m3-r787-fresh-route-mode2-plateau-20261102.md).

Save status: the active root contains only `user99.sav`; eight verified empty pilot payload records remain recoverable in r761 rollback storage. **All eight slots are already open**, so no saves were deleted or moved. R787 retained 33,380,953 logical bytes / 11,073,252 allocated bytes; no build, source, cache, ISO, or save changed.

| Area | Progress | Verified state |
| --- | --- | --- |
| Known route | [##########] 5/5 | Normal difficulty visually verified after 37 fresh-frame-gated actions. |
| Mode-2 loader | [######--------------] 3/5 | Resource `0x1E` not ready; producer and later copy handoff unresolved. |
| First mission frame | [--------------------] 0/1 | Not verified. |
| Save slots | [##########] 8/8 | All eight pilot slots open; reversible blank records retained. |
| Storage/build | [##########] 1/1 | 33.38 MB logical / 11.07 MB allocated; no build/cache changes. |

Next: correlate the mode-2 producer for `0x00351F22` and distinguish runtime wait from trace-output contention using the retained R787 evidence before changing code.
# Current checkpoint — r783 title-stage DCF4 wait (completed, 2026-11-02)

r783 reused exact r775 AOT EXE/PDB/MAP and the existing save root, but diverged at the title: it returned to `Unable to load Player Record` and never reached Campaign or mode 2. Only two A inputs were sent while that screen was visible; none were sent after black. The watchdog stopped only diagnostic PID 111484 after 120 seconds without a DCF4 wait return and retained its matching dump. No Steel Battalion process remains active.

At guest wait site `0x00211F39`, TID 106748 waited on event `0x0021DCF4`. The final interval had raster pending/active zero and DMA PUT=GET=`0x7C5A8`. DCF4 sets continued through #638; marker #640 was followed at the same tick by a reset from signal 1, then a wait with signal 0. This correlation does not establish a faulty reset. The callback gate, callback arguments/branches, and runtime target at indirect call `0x00217029` were not enabled, so the missing publication cause remains unknown. r781's later mode-2 asset `0x08` copy-in stall and r782's startup route mismatch remain separate.

The root already has blank pilot slots: only `user99.sav` remains in its active title-data folder; verified empty `user00`–`user07` are in the reversible r761 rollback folder. No save operation was needed. r783 stayed under the 64 MiB evidence cap (about 6.68 MB logical retained); allocated bytes were unavailable. No build/source/cache change.

| Area | Progress | Verified state |
| --- | --- | --- |
| Title route repeatability | [####----------------] 2/5 | r781 reached Normal; r782/r783 diverged at title. |
| DCF4 after raster drain | [#####---------------] 2/5 | Unsignaled wait with raster/DMA drained; reset temporal correlation only. |
| Callback target/branch | [##------------------] 1/5 | Missing in r783 because target/gate/callback traces were unset. |
| Mode-2 STRM06 handoff | [####----------------] 2/5 | r781 asset 8 copy-in only; not reached in r782/r783. |
| First mission frame | [--------------------] 0/1 | Not verified. |
| Storage/build | [##########] 1/1 | Existing candidate reused; under 64 MiB cap; no cleanup/build. |

Details: [r783 report](m3-r783-dcf4-unmatched-publication-20261102.md). Next: one bounded r775 replay with the exact r519 screen-gated input order and DCF4 producer + gate + callback + `0x00217029` target traces enabled together. Verify screens before input; no input on black. No event or loader behavior changes until a violated contract is established.
# Current checkpoint — r782 title-route mismatch (completed, 2026-11-02)

r782 reused the exact r775 AOT executable/PDB/MAP and the same save root. It remained at the title Player Record error with repeated black transitions; Campaign and mode 2 were not reached. Its 240-second UI plateau watchdog stopped only PID 94444 and retained a matching dump. No diagnostic game process remains. `user99.sav` is unchanged; no save movement/deletion or build/cache change occurred.

Targeted reads during this title-stage run fully read `D:\media\bgm\STRM06.WAV` (55 reads, 3,575,674 bytes, all successful). This is startup activity and does not verify r781's later mode-2 asset `0x08` candidate. Wait logs contain DCF4 entries but incomplete sampled pairs (18 starts / 7 returns); DCF4 producer tracing was off. A proper main-thread unwind reaches `xbox_KeWaitForSingleObject+0x29` but cannot identify the guest event. DCE4 has sampled wait/return pairs and its producer signals continue; no DCF4 root cause is established.

The first mission frame remains **0/1**. r781 remains the latest successful new-pilot route through Normal difficulty. Its targeted STRM02 reads completed and asset `0x04` copied out; asset `0x08` is still the first mode-2 incomplete handoff candidate, with a correlated successful STRM06 open but no read/copy completion trace yet.

| Area | Progress | Verified state |
| --- | --- | --- |
| Screen-gated title route | [####----------------] 2/5 | r782 returned to title error; r781 reached Normal. |
| STRM02 source read | [##########] 1/1 | r781 read both full passes with successful final EOF reads; asset 4 copied out. |
| Mode-2 asset 8 / STRM06 | [####----------------] 2/5 | r781 asset 8 copy-in only; no copy-out. r782 only tested startup STRM06 reads. |
| DCF4 title wait | [###-----------------] 1/5 | r782 sampled starts/returns and main native wait; cause unproven. |
| First mission frame | [--------------------] 0/1 | Not verified. |
| Storage/build | [##########] 1/1 | r782 retained 3,909,104 logical bytes; allocated-byte total unavailable. No build/cache edits. |

Details: [r782 report](m3-r782-title-route-strm06-20261102.md). Prior mode-2 evidence: [r781 report](m3-r781-targeted-strm02-read-20261102.md). Next: one bounded replay using r781's screen-by-screen input order, with bounded DCF4 producer tracing if the black title transition recurs, plus targeted STRM06 read completion if mode 2 is reached. Preserve the exact bundle and save root; no runtime changes until a failing contract is supported.
# Current checkpoint — r781 targeted stream and next loader handoff (completed, 2026-11-02)

r781 used exact r775 EXE/PDB/MAP and the existing save root. The screen-gated new-pilot route visibly reached Campaign, LIST AS NEW, name/date entry, YES, and Normal. The retained final frame is black; no first mission scene was verified. Its own 240-second UI plateau watchdog stopped only PID 67904 and captured `ui-plateau-stall.dmp`. No diagnostic game process remains active.

Targeted `NtReadFile` tracing recorded two full reads of `D:\media\bgm\STRM02.WAV`, each 2,645,998 bytes with all statuses successful, and asset index `0x04` copy-out succeeded. This rejects a blocked STRM02 source read for this occurrence and does not reproduce r780's missing index 4 copy-out. The next loader pass entered asset index `0x08` with no copy-out; lifecycle rows show successful opens of `STRM06.WAV` cache and source. The mode-2 worker's validated unwind reaches `bridge_NtCreateFile+0x548`, but the stack and untargeted file reads do not identify the waited contract. Treat STRM06 as the next candidate, not a confirmed cause. Resource `0x1E` had one earlier not-ready sample; no DCF4 trace was enabled.

No build or generated source changed. `user99.sav` remains 2,812 bytes with its prior timestamp; the only newly observed save-root file is the zero-length cache `Cache\STRM06.WAV`. The run retained 12,876,813 logical bytes within the 64 MiB budget; allocated-byte reporting was unavailable. No cleanup or save movement was done.

| Area | Progress | Verified state |
| --- | --- | --- |
| New-pilot route | [##########] 1/1 | Reached Normal difficulty; final frame black. |
| STRM02 read/copy | [##########] 1/1 | Both 41-call read sequences returned the exact file length; index 4 copy-out succeeded. |
| Next mode-2 handoff | [####----------------] 2/5 | Index 8 copy-in and STRM06 source open recorded; completion/read status unknown. |
| First mission frame | [--------------------] 0/1 | Not verified. |
| Storage/build | [##########] 1/1 | 12,876,813 logical run bytes; no build/cache changes. |

Details and exact run identity: [r781 report](m3-r781-targeted-strm02-read-20261102.md). Next: one bounded exact-r775 replay with targeted reads for `D:\media\bgm\STRM06.WAV` and `Z:\STRM06.WAV`, matching mode-2 copy/readiness markers and a 64 MiB cap. Preserve AOT, guest fences, controller mapping, and rasterizer `1ea1871`; make no fix until the first incomplete operation is supported by trace evidence.
# Current checkpoint — r778 new-pilot route and post-loading stall (2026-11-02)

r778 used the exact r775 AOT executable with the existing save root and bounded DCF4 producer tracing. The screen-gated route reached the visible `NOW LOADING` screen, then a black frame. The run's watchdog stopped only PID 103708 after 240 seconds without a new frame or input and retained a matching-bundle minidump. The first mission scene remains **0/1**.

The mode-2 producer completed asset index `0x1E` and set guest readiness byte `0x00351F22=1`; the following helper decision was 6. The worker then started routine `0x00017E40` in mode 2. At stop, a proper unwind of worker TID 108508 reached `bridge_NtCreateFile+0x548`, but no path, caller, or return status was captured. Main TID 109192 unwound partially into `sub_00048B80+0x52A`, which contains the bounded input-table trace. These are candidates for the post-loading stall, not a confirmed cause.

Across the observed interval, DCF4 waits returned after raster synchronization event sets. The DCF4 trace filled its 4,096-row cap, so later waits are unobserved; r777's separate unmatched title-stage wait remains distinct. No runtime fix or tests are claimed.

| Area | Progress | Verified state |
| --- | --- | --- |
| Reversible pilot slots | [##########] 1/1 | Eight verified blank files remain in r761 rollback; active root still has `user99.sav`. |
| New-pilot screen route | [##########] 1/1 | Campaign, `LIST AS NEW`, name A, date, confirmation, Normal, and loading were visible. |
| Resource `0x1E` | [##########] 1/1 | Producer set ready byte `0x00351F22` to 1; subsequent helper decision 6 observed. |
| Post-loading dependency | [####----------------] 2/5 | Worker stopped in `NtCreateFile`; exact path/status missing. |
| First mission frame | [--------------------] 0/1 | Final live screen was black; mission scene not reached. |
| Storage/build | [##########] 1/1 | r778 used 4,622,624 allocated bytes; no build/cache changes or save moves/deletes. |

Details, exact hashes, the route, and unwind limitations: [r778 report](m3-r778-dcf4-loading-plateau-20261102.md). Next: replay once with bounded file-open path/caller/target and failure traces to identify the mode-2 worker's stalled dependency. Keep AOT, guest fences, controller mapping, and rasterizer `1ea1871` unchanged until the trace supports a cause.

# Current checkpoint — r767 DirectSound writer correlation (2026-11-02)

The r767 AOT diagnostic ended in an access violation, and no game process remains active. Its matching dump/MAP and write watcher identify the immediate cause: raster worker TID 108844 wrote `0xFF000000` over DirectSound list fields `0x8038C08C`, `0x8038C098`, and `0x8038C09C` at host RIP `image+0x64BAB87`, mapped to `put_pixel+0x647`. The corrupted next node was `0xFF000000`; `sub_0021ED29+0x88` then faulted reading `0xFFFFFFF4`.

This confirms the r767 DirectSound corruption is a raster write. It does not yet explain why the active surface aliases the live list allocation. The separate pixel probe was configured for row 476; at the logged 4096-byte pitch, the watched writes map to row 460 at x=35, 38, and 39. This reconciles the 64 KiB difference as 16 rows on the same active surface. The existing page reservation only protects future contiguous allocations and does not repair an already-live overlap. No behavior fix or test result is claimed. DCF4 waits returned and DMA publish continued in the captured interval; keep those observations separate.

| Area | Progress | Verified state |
| --- | --- | --- |
| DirectSound list overwrite | [##########] 1/1 | Exact watched writes map to `put_pixel`; crash follows in same run. |
| Surface/address contract | [####----------------] 2/5 | Live overlap and pixel coordinates verified; reservation/allocation order unresolved. |
| First mission frame | [--------------------] 0/1 | Final retained image is black. |
| Save slots | [##########] 1/1 | Eight blank pilot slots remain reversibly moved; active root has blank `user99.sav`. User authorizes further moves/deletion; none needed. |
| Storage/build | [##########] 1/1 | No files deleted or moved and no build/cache changed in this review. |

Details and exact hashes: [r767 writer correlation](m3-r767-dsound-writer-correlation-20261102.md). Next: correlate the exact raster store address with the live allocation range and surface-reservation timing before changing runtime behavior.
# Current checkpoint — r765 DCF4 publication after title input (2026-11-02)

r765 used one isolated AOT diagnostic candidate (`4A528AA0…F91ACB`), the existing save root, and the 64 MiB trace cap. The title showed `Unable to load Player Record`; a transient black transition followed the second screen-gated A input, so no more input was sent. The DCF4 wait watchdog stopped only PID 108640 after 120 seconds.

The final wait at guest `0x00211F21` on event `0x0021DCF4` (TID 105056) had device `0x0021B790`, callback/cursor zero, queue `0x4D9`, descriptor `0x80082FE0`, and signal zero. Earlier method-5 pushbuffer packets were consumed and acknowledged, and callback argument 5 selected `0x0021701E`; the final wait has no return. At the final heartbeat, raster active/pending were zero, DMA PUT=GET=`0x5FC8`, and DCF4 remained unsignaled. The conditional `0x00211EEE` ring callback path did not execute; that alone does not establish a defect. No fix is supported and the first mission frame remains **0/1**.

| Area | Progress | Verified state |
| --- | --- | --- |
| Free pilot slots | [##########] 1/1 | Eight blank records remain reversible in the r761 rollback folder. |
| Screen-gated route | [####----------------] 1/5 | Title error observed; Campaign and pilot-list screens not reached in r765. |
| DCF4 next publication | [######--------------] 3/5 | Prior method-5 completion verified; final wait remains unsignaled. |
| First mission frame | [--------------------] 0/1 | Not reached. |
| Storage/build | [##########] 1/1 | Run evidence 2,567,888 allocated bytes; candidate EXE/PDB/MAP bundle 75,308,752 allocated bytes; run stayed below cap. |

Details, hashes, traces, and limits: [r765 report](m3-r765-ring-publish-handoff-20261102.md). Next: identify the guest condition for the missing subsequent DCF4 publication and repair the screen route without sending input on a black frame.
# Current checkpoint — r763–r764 PGRAPH and DirectSound writer follow-up (2026-11-02)

r763 enabled bounded PGRAPH NOP/notification tracing on the exact r756 AOT bundle. PGRAPH method `0x0100` notifications reach the executor, the trapped method/data values reach the guest callback, and the guest acknowledges them. That run then hit the known DirectSound invalid-list read at `sub_0021ED29+0x88` (guest ESI `0xFFFFFFEC`, fault VA `0xFFFFFFF4`); the crash snapshot shows a null voice-list head. It did not identify the malformed writer.

r764 added the compiled DirectSound list watcher and reproduced a separate later DCF4 wait. At guest `sub_00211E10`, a marker descriptor at `0x80069B38` was written with method `0x40100`, parameter 5, flushed, and followed by ring-space result `0x2DA0` (threshold `0x2000`). TID 92672 then waited on DCF4. No subsequent PGRAPH notification carrying parameter 5 was recorded. Raster work drained by tick 278508906 (3177 batches, active/pending zero), DMA PUT=GET=`0x6C920`, PGRAPH interrupt zero, guest DCF4 unsignaled; the 120-second wait watchdog stopped only PID 96596. The DirectSound watch captured only normal initialization/link writes at its three watched words, so it does not rule out an unwatched corrupting write.

These traces narrow the DCF4 candidate to the handoff from the guest marker descriptor to an executed pushbuffer NOP; they do not yet prove where that handoff fails. Keep the r763 DirectSound crash, r764 DCF4 wait, r762 pilot-list stall, and r519 post-resource loading plateau distinct. The first mission frame remains **0/1**. No source fix, build, test, or save mutation occurred. r763/r764 retained 4,007,614 and 2,188,657 allocated bytes, respectively.

| Area | Progress | Verified state |
| --- | --- | --- |
| Free pilot slots | [##########] 1/1 | Eight confirmed empty records remain reversible in rollback. |
| PGRAPH NOP to guest callback | [##########] 1/1 | `0x0100` notification and acknowledgement observed in r763/r764. |
| DirectSound malformed writer | [######--------------] 3/5 | Invalid traversal reproduced; watched writes normal, cause still unknown. |
| DCF4 marker-to-pushbuffer handoff | [######--------------] 3/5 | Descriptor write and wait verified; matching method-5 execution missing in the captured window. |
| First mission frame | [--------------------] 0/1 | Not reached. |
| Storage/build | [##########] 1/1 | Reused same EXE/PDB/MAP; combined evidence allocations 6,196,271 bytes; no build/cache changes. |

Details, run identities, and evidence limits: [r763–r764 report](m3-r763-r764-notification-and-list-watch-20261102.md). Next: correlate `device+0x21AC/0x21B0` publish callback, exact descriptor/header addresses, DMA cursors, and the expected method-5 callback in one run. Preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`.
# Current checkpoint — r762 pilot-slot route and later DCF4 wait (2026-11-02)

The user authorized moving save files to free slots. I verified that the eight `user00.sav`–`user07.sav` pilot payloads in the active root were zero, then moved them into `iso/local-analysis/save-rollback/r761-empty-pilot-slots-20261102/TitleData/43430002/` with hashes recorded for restoration. The title record `user99.sav`, partition images, and caches were untouched. The same-drive move reclaimed 0 bytes; r762's 16-file run directory used 4,038,167 allocated bytes.

r762 (PID 99404, exact r756 AOT EXE/PDB/MAP) progressed through title and Campaign to visible `LIST AS NEW`. One input was correlated across XID report byte 2, guest DMA buffer, edge copy, positive predicate, pilot-row callback branch `0x000E193B`, and post-action 83. Selection then stopped drawing at 0 FPS before name entry. The dump confirms TID 101724 waiting in the native event wait; no valid guest unwind was captured.

At tick 277423796, DCF4 callback argument 5 selected publication branch `0x0021701E`; bridge set-DCF4 and the matching wait returned successfully. A new wait began at 277423812 with no later publication. Callback arguments `0x01080021` and `0x03600021` selected queue-update branch `0x00216EC9`; the bounded two-slot queue remained empty, raster pending/active were zero, and NV2A guest DCF4 signal stayed zero. This identifies the missing next publication but not the upstream guest condition. No fix is supported. Details and exact run/artifact identities: [r760–r762 report](m3-r760-r762-slot-and-dcf4-followup-20261102.md).

| Area | Progress | State |
| --- | --- | --- |
| Free pilot slots | [##########] 1/1 | Eight blank files moved reversibly; game did not recreate them. |
| Pilot-list input | [##########] 1/1 | XID-to-row-action chain verified. |
| DCF4 next producer | [######--------------] 3/5 | First handoff succeeds; later wait lacks a producer callback. |
| First mission frame | [--------------------] 0/1 | Not reached. |
| Build/storage | [##########] 1/1 | No build or cache change; run used 4,038,167 allocated bytes under 64 MiB. |

**Next:** inspect the r762 matching dump/source to identify the upstream condition that should enqueue the next DCF4 event. Avoid another unchanged route. Keep r760 DirectSound list corruption separate; r761's bounded watcher did not capture a malformed writer.
# Steel Battalion AOT — current status (updated through r759 evidence, 2026-11-02)


## Current checkpoint — r759 mode-2 pair-output trace (2026-11-02)

r759 reused the exact r756 AOT candidate, the existing save root, and no build or source changes. The screen-gated new-pilot route accepted name A, 01/01/2002, and Normal difficulty. After difficulty confirmation the live window went white, then black at 0 FPS. The final retained framebuffer is black; no mission scene or guest progression beyond loading was verified. The run stopped under the configured 900-second external watchdog; PID 89180 is no longer active.

The new trace showed resource 0x1E's sampled paired helper passing its comparison and readiness-byte check (ready=1). Pass 46 returned through `sub_000C32D6` with pair `0x000ABA00/0`, equal to the previous globals; the generated source returns zero on this scan path. This explains that pass's lack of a new progress update but does not identify the campaign blocker. TID 102640 was captured at host RIP `0x7FF67AC33ADB`, `sub_00245430+0x117B`; the native unwind rejected its next frame as invalid, so raw stack scans are not treated as a call chain. Guest CPU snapshots were disabled. No runtime fix is supported yet.

The final run directory is 35,534,078 logical bytes / 10,125,428 allocated bytes, within its 64 MiB cap. No build caches, save copies, or project files were removed. The r758 in-game deletion of the verified blank DATA-000 slot remains authorized; r759 made no save-file moves/deletions.

Details, exact hashes, trace caps, and evidence limitations: [r759 report](m3-r759-mode2-pair-output-20261102.md).

| Area | Progress | Verified state |
| --- | --- | --- |
| Repeatable new-pilot route | [##########] 1/1 | Name, birth date, and Normal difficulty were screen-verified. |
| Resource 0x1E readiness | [##########] 1/1 | Sampled paired comparison passed; ready byte was 1. |
| Mode-2 pair progression | [######--------------] 3/5 | Pass 46 returned with unchanged `0xABA00/0`; overall cause unresolved. |
| Stalled guest thread | [####----------------] 2/5 | Host RIP symbolized; proper unwind/guest registers unavailable. |
| First mission frame | [--------------------] 0/1 | Final retained image is black; not reached. |
| Runtime fix/tests | [##------------------] 1/5 | No causal defect established; no build or tests run. |
| Storage/build | [##########] 1/1 | Reused existing candidate; 10,125,428 allocated bytes in r759 run directory. |

**Next:** inspect the captured TID 102640 state and generated `sub_00245430` using bounded guest-PC/branch instrumentation. Correlate the actual stalled guest condition with the last loader pass and synchronized graphics/event telemetry before changing behavior. Preserve AOT, controller mapping, guest fences, and rasterizer `1ea1871`.

## Historical checkpoint — r756 active color-surface reservation (2026-11-02)

The r750/r754/r753 traces and source now support a specific cause for the pilot-list DirectSound corruption: an active color surface at `[0x001B0000,0x005B0000)` wrote pixel `(38,476)` to `0x0038C098`, inside the real contiguous allocation `[0x80388000,0x8038D000)` containing the DirectSound node. The allocator had no active-surface reservation. A page-granular exclusion is implemented in the NV2A surface path and both contiguous allocators; the source regression exercises the real pushbuffer parser and ordinal-166 bridge.

The focused regression and game runtime are unverified because MSBuild cannot find `Microsoft.Cpp.Default.props` in the installed VS tree. No executable was produced or route started. The save root already has a free slot: `user07.sav` remains intact in r748 rollback; no additional save was moved or deleted. Keep r753's DirectSound crash, r748's later `NOW LOADING` plateau, and r755's title stall distinct.

| Field | Progress | Verified state |
| --- | --- | --- |
| Free pilot slot | [##########] 1/1 | `user07.sav` remains safely in r748 rollback; active root slot is open. |
| Title to pilot list | [##########] 1/1 | r753 visually reached the pilot list before DirectSound list corruption. |
| DirectSound writer cause | [##########] 1/1 | Raster target address overlaps the allocated live list node; missing surface exclusion supported by traces and source. |
| Surface reservation fix | [######--------------] 3/5 | Added to NV2A and contiguous allocator paths; not yet built. |
| Focused regression | [##------------------] 1/5 | Harness updated; build blocked by missing Visual C++ project props. |
| Loader cause | [####----------------] 2/5 | r748 plateau remains unresolved; r753 did not reach loader. |
| Repeatable title-to-pilot route | [######--------------] 3/5 | r748 reached loading; r753 reached the pilot list; r755 stayed at title. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond loading. |
| Storage/build | [##########] 1/1 | No build/run artifacts created; caches unchanged. Last measured r754/r755 evidence: 2,220,913 allocated bytes; 30,692 bytes reclaimed. |

**Next:** restore/locate an installed C/C++ build toolchain, run the focused `contig-range` regression, then build one candidate and replay the exact r748 route using the existing open pilot slot. Preserve AOT, guest fences, controller mapping, and rasterizer `1ea1871`. Details: [r756 source/fix report](m3-r756-surface-reservation-fix-20261102.md), [r754–r755 traces](m3-r754-r755-dsound-allocation-overlap-20261102.md), [r753 crash](m3-r753-pilot-list-directsound-crash-20261102.md), and [r748 loading plateau](m3-r748-r513-open-slot-loading-freeze-20261102.md).

## Previous checkpoint — r754–r755 DirectSound allocation overlap (2026-11-02)

## Current checkpoint — r748 new-pilot route and mode-2 loading freeze (2026-11-02)

r748 reused the exact r513 AOT EXE/PDB/MAP and existing save root. The authorized blank-slot move freed `user07.sav` without cloning or clearing the save tree. The known 40-step route reached visible `LIST AS NEW`, name entry, birth date, and `NOW LOADING`. It stayed there; the first mission frame remains **0/1**. No new `user07.sav` was written.

Resource `0x1E` was observed not ready, then opened successfully and marked ready (`0x00351F22=1`; copy size 0). The following mode-2 pass returned 0 at progress `0x000ABA00/0`. Repeated callbacks at `0x00102017` remained in mode 2 with gates `1/1/0` and the same progress. Sampled reads succeeded through `n=8000`, but the paired-open trace hit its 2,048 cap and does not establish the next required dependency.

The diagnostic froze on `NOW LOADING`; only PID 101756 was stopped. Its last heartbeat had PGRAPH interrupt `0x00100000`, DMA PUT/GET `0x4313C/0x3B354`, and a just-issued raster batch with three workers pending. The DCF4 wait returned successfully before the frozen state. These graphics observations are not yet a loader root cause. A small dump placed loader TID 94636 and render TID 103248 in `ntdll.dll+0x16A054`, but no stack bytes were captured for them, so no caller or wait object is validated. Details, exact bundle hashes, selected dumps, and limitations: [r748 loading-freeze report](m3-r748-r513-open-slot-loading-freeze-20261102.md).

| Field | Progress | Verified state |
| --- | --- | --- |
| New-pilot route to loading | [##########] 1/1 | Screen-gated route reached visible `NOW LOADING`. |
| Loader dependency/producer | [####----------------] 2/5 | Resource `0x1E` became ready; progress then remained `0x000ABA00/0`; cause unknown. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond loading. |
| DCF4 handoff | [##########] 1/1 | r748's final recorded guest DCF4 wait returned; separate r747 later-wait cause remains unresolved. |
| Fixes/tests | [##------------------] 1/5 | No behavior change, build, or test; no cause established. |
| Storage/build | [##########] 1/1 | r748 evidence reduced from 17,173,795 to 5,395,382 allocated/stored bytes; caches unchanged. |

**Next:** do not repeat an unchanged route. If another route is needed, retain r513 and the same save root, start the paired-open trace after the first 2,048 attempts, add bounded completion tracing for the late `SOUND.BIN`, `TEXOBJ.BIN`, and `TEXMOVIE.BIN` handles, and use `Capture-ProducerTraceDump.ps1` on the flat mode-2 signature with a 180-second plateau threshold. Symbolize the main and render thread stacks and identify the producer/consumer contract before changing runtime behavior. Keep the first mission as the success gate; do not alter guest fences, AOT flow, controller mapping, or rasterizer `1ea1871`.

## Current checkpoint — r747 DCF4 event-cycle correlation (2026-11-02)

Read-only source correlation of r746 confirms the first DCF4 event handoff worked: `sub_00217130` reason 7 called `sub_00216EA0`; callback argument 5 selected branch `0x0021701E`, which published the event at `context+0x1A4 = 0x0021DCF4`. At tick 236574718, the matching wait returned success. A later wait began at 236574750; the next callback selected branch `0x00216EC9`, and no later DCF4 publication was recorded. The 121 sampled `sub_00216B10` queue calls include successful consumes earlier and end with both pointer slots zero, unchanged slot sequences, and result zero while the dispatcher polls. This confirms no queued callback at the later wait, but the upstream enqueue condition remains unknown. Final heartbeat n=155 also sampled `PGRAPH_INTR=0`, `active=0`, `pending=0`, and DMA PUT=GET=`0x6DD0`; no queued DMA work or unacknowledged PGRAPH interrupt was present in that snapshot. No fix or test is supported. Details: [r747 DCF4 correlation](m3-r747-dcf4-event-cycle-correlation-20261102.md).

| Field | Progress | Verified state |
| --- | --- | --- |
| First DCF4 set/consume pair | [##########] 1/1 | Callback branch 5 published; same-tick wait returned success. |
| Subsequent producer | [######--------------] 3/5 | New wait has no later branch-5 publication; queue empty. |
| First mission frame | [--------------------] 0/1 | Not reached. |
| Save route readiness | [####----------------] 2/5 | Eight blank pilot files; slot-freeing request rejected before execution. |
| Runtime fix/tests | [##------------------] 1/5 | No causal defect established; no tests run. |
| Storage/build | [##########] 1/1 | Read-only analysis; no build/cache or save changes. |

**Next:** continue the upstream producer-condition analysis from the exact callback/queue handoff if useful; do not repeat equivalent route attempts. First mission progression still needs an allowed way to free a blank slot or a valid existing pilot root. Do not bypass the rejected deletion.
## Current checkpoint — r741–r746 pilot-record and DCF4 follow-up (2026-11-02)

r746 showed that `T:\user99.sav` opens successfully but contains a blank record; `sub_0010ABD0` returned 1 at guest site `0x000DF7B4`, and caller branch `0x000DF7D0` selected `Unable to load Player Record`. Separately, r744 reached the Campaign full-roster warning. All eight `user00.sav`–`user07.sav` payloads in the selected r519 root are blank. The user authorized freeing one blank slot, but the workspace deletion control rejected the removal before it executed. The save root is unchanged; no workaround was attempted.

r746 also reproduced a distinct title-stage DCF4 wait after raster work drained (`pending=0`, `active=0`, PUT=GET=`0x6DD0`). Last observed publication was callback 758/branch 5 to `0x0021701E`; the wait on host handle `0xEEC` did not return. This does not explain the r519 loading plateau or r524 DirectSound corruption. No behavior fix or tests; first mission frame remains 0/1. Full run identity and limits: [r741–r746 report](m3-r741-r746-record-and-dcf4-followup-20261102.md).

| Field | Progress | Verified state |
| --- | --- | --- |
| Player-record operation | [##########] 1/1 | Successful open; blank `user99.sav`; result 1 selects title error. |
| Available pilot slot | [####----------------] 2/5 | Eight blank slot files; authorized removal was rejected before execution. |
| Title DCF4 handoff | [######--------------] 3/5 | Wait, final branch-5 publication and drained raster verified; producer cause unresolved. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond loading. |
| Tests/fix | [##------------------] 1/5 | No behavior change supported; no tests run. |
| Storage/build | [##------------------] 1/5 | r741–r746 retained: 223,349,751 allocated bytes; no reclamation; incremental cache kept. |

**Next:** continue only when a valid pilot root or permitted slot-freeing operation is available. Do not bypass the rejected deletion. Then use the exact r519 executable/environment/input sequence and verify every screen transition; preserve AOT, guest synchronization, controller mapping, and rasterizer `1ea1871`.
## Current checkpoint — r738–r740 DATA-000 rejection trace (2026-11-02)

r740 screen-gated the existing pilot-record route to `Unable to load DATA-000.` using the r739 AOT diagnostic candidate and the existing save root. `T:\user00.sav` completed a 2,792-byte read plus its 20-byte trailer with I/O, NT, and guest statuses all zero. `sub_0010AA90` returned zero with blank name/state/birth fields; branch `0x000D40D7` saw result 0 and unchanged error slot/state. The new `sub_000CF990` message-dispatch branch probe emitted no rows in the target call-site interval, so the exact overlay-selection branch remains unidentified. r738 separately reproduced the title-stage `Unable to load Player Record` after a complete successful `T:\user99.sav` read. Keep these errors separate.

No behavior change is supported. The current save root has no valid pilot or free slot, and no save was copied, cleared, or written. The diagnostic ended at the DATA-000 overlay; the first mission frame remains 0/1. No further unchanged route should be run. Details, bundle hashes, route, and evidence limitations: [r738–r740 report](m3-r740-data000-record-rejection-20261102.md).

| Area | Progress | Current evidence |
| --- | --- | --- |
| Pilot record read/result | [##########] 1/1 | Full file read succeeded; helper returned 0 and record fields were blank. |
| DATA-000 rejecting branch | [####----------------] 2/5 | `0x000D40D7` did not set the error state; message-dispatch probe had no rows. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond the rejection. |
| Route/save readiness | [####----------------] 2/5 | Existing route reaches rejection; selected save has no valid pilot or free slot. |
| Storage/build | [##########] 1/1 | r738–r740 retained artifacts added 75,179,397 allocated bytes (~71.7 MiB); no reclamation; r739 incremental build ~38 s, caches retained. |

**Next:** continue only when a valid pilot save is available or a non-mutating route exists. Trace the actual message selection call through the UI dispatch with a narrow marker; do not repeat the blank DATA-000 attempt or change saves. Maintain AOT and guest synchronization behavior.

## Historical checkpoint — r737 XBE tooling and Ghidra validation (2026-11-02)

The local XBE parser successfully read the extracted retail executable: title ID `0x43430002`, 78 sections, 123 kernel imports, entry point `0x00192C47`. The ordinal/signature support ZIP is present in `C:\Project\GhidraAnalysis\scripts`; its six code/data/license entries match repository copies by SHA-256. The prior read-only Ghidra check recorded 123/123 thunk labels; their build-4627 names are still provisional. Details: [r737 Milestone 1 validation](m1-r737-xbe-tooling-ghidra-20261102.md).

Architecture remains XboxRecomp AOT. Upstream licensing review excludes copying GPL Cxbx/xemu code; only the already-licensed XboxRecomp components are candidates for reuse. No canonical public source/license was found for XbeTripper or xberewrite. Git safety remains verified: 245 tracked paths, no prohibited game/generated files, ISO/XBE/save paths ignored, packed object store 97.45 MiB. No files were staged or published.

| Area | Progress | Current evidence |
| --- | --- | --- |
| XBE format parse | [##########] 1/1 | Local parser succeeded on the extracted executable: 78 sections, 123 imports, entry `0x00192C47`. |
| Ghidra ordinal support | [##########] 1/1 files | Archive present, six entries hash-match sources; label semantics remain provisional for build 4627. |
| AOT architecture/tool license review | [##########] 1/1 | XboxRecomp retained; Cxbx/xemu used only as read-only references; no GPL code copied. |
| First mission frame | [--------------------] 0/1 | Still not reached; save state documented in r736. |
| Git/storage | [##########] 1/1 | 245 tracked paths; zero prohibited matches; 97.45 MiB packed Git objects; no storage change. |

**Next:** preserve the existing AOT/runtime checkout and continue on the r736 pilot-record blocker; no emulator switch or XBE hook is supported. Do not publish until the repository content is curated and the project’s distribution gates are met.

## Previous checkpoint — r736 record validation and route readiness (2026-11-02)

## Current checkpoint — r736 record validation and route readiness (2026-11-02)

No route or build ran. A narrow audit of all 51 `saves-*` directories found six with game title data; all 48 pilot-slot payloads in those six are blank, and 45 roots contain no title data. No valid pilot or free slot is available without changing a save. The existing R519 route therefore cannot currently be repeated under the save-preservation instruction.

The r554 `DATA-000` read itself succeeded, and current generated source contains a bounded source probe for the downstream record-validation return and rejection branch. Its default diagnostic EXE predates the generated source and lacks the probe markers; preserve it and its symbols rather than overwrite the bundle. Details and exact addresses: [r736 record-validation readiness](m3-r736-record-validation-and-route-readiness-20261102.md). The r531 title-stage “Unable to load” and DCF4 wait remain distinct from the r554 blank-record rejection. First mission frame remains 0/1.

| Area | Progress | Current evidence |
| --- | --- | --- |
| R519 reference bundle and input route | [##########] 1/1 | Exact historical EXE/PDB/MAP and 40 screen-gated actions retained. |
| Current pilot-save state | [##########] 1/1 | Six active title-data roots checked; 48/48 pilot payloads blank; no free slots. |
| DATA-000 rejection branch | [####----------------] 2/4 | Source probe and candidate branch identified; runtime return/branch not yet captured. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond loading. |
| Storage/build | [##########] 1/1 | 0 bytes changed or reclaimed; no build/cache impact. |

**Next:** use one isolated build of the already-instrumented AOT source to trace the known blank DATA-000 attempt, preserving the old executable/symbol bundle. Continue to the mission only when a valid saved pilot or free slot is available without violating save preservation. Do not alter or delete saves.

## Previous checkpoint — r735 route/save preflight (2026-11-02)

## Current checkpoint — r735 route/save preflight (2026-11-02)

I checked the exact R519 bundle identity, environment, 40-action screen-gated input history, and the current contents of the existing saves before starting another route. No Steel Battalion process or game window was active. Across the six existing local-analysis save roots, all eight pilot-slot files exist and their 2,792-byte payloads are zero. The R623 `user06.sav` previously reported as pilot A is now blank as well. No valid saved pilot or free slot remains, so the R519 new-pilot route cannot currently be repeated without changing a save. No files were changed or copied and no route was launched.

The prior r554 run already verified that a full roster rejects `LIST AS NEW` and that empty DATA-000 is rejected. Do not repeat those equivalent screens. Details: [r735 save preflight](m3-r735-r519-route-save-preflight-20261102.md). The first mission frame remains 0/1. r734 diagnostic evidence remains at [r734 report](m3-r734-mode2-worker-handoff-20261102.md); its 271,444-byte storage reduction is the latest measured saving, and build efficiency is unchanged.

| Area | Progress | Current evidence |
| --- | --- | --- |
| R519 bundle/environment/input reference | [##########] 1/1 | Exact R513 bundle, environment, and 40 recorded inputs inspected. |
| Current pilot save state | [##########] 1/1 | Six existing roots checked; all eight slots are blank and present. |
| Repeatable route | [######--------------] 3/5 | Historical new-pilot route worked; current saves block it. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression past loading. |
| Storage/build | [##########] 1/1 | Latest actual savings: 271,444 allocated bytes from r734; no build/cache impact. |

**Next:** resume only with a valid user-supplied save root or authorization to free one blank pilot slot using the game's own delete flow. Preserve the current saves; do not run another route that is known to stop at the full-roster warning or invalid DATA-000 screen.

## Current checkpoint — r734 (2026-11-02)

r734 screen-gated the new-pilot route to `NOW LOADING` using the existing save root and R645 producer-trace executable. It did not use the exact R513 bundle from r519. The final retained frame is black; first mission remains 0/1. A mode-2 worker entered `sub_00034720`, one 4 MiB heap request failed, and the worker later exited with status 1. Since the worker wrapper's exit status does not identify which `sub_00034720` branch ran, success is unproven. Resource `0x1E` became ready and its consumer passed. The later callback remained mode 2 with `0xABA00/0` progress and `0/0` statuses.

An opened `D:\media\Movie\s00ev01j.bik` read was attempted with a null destination and returned `STATUS_ACCESS_VIOLATION`; this is a confirmed I/O error, but the external caller and effect on mission progression are not yet established. The live snapshot's top context maps to `sub_00245430`; deeper stack-scan entries are not validated unwinds. The trace resolves `FE000004/FE000000` as enter/leave critical-section imports, so their zero return is not a completion result. No DCF4 wait was reproduced, and the raster sample does not support blaming rendering.

The diagnostic was stopped only after its black frame and loader callbacks remained unchanged for several minutes. Its folder is retained at `iso/local-analysis/logs/m3-r734-r645-mode2-worker-handoff-20261102`. Lossless compression reclaimed 271,444 allocated bytes; hashes were unchanged. No build or cache was changed. Details: [r734 report](m3-r734-mode2-worker-handoff-20261102.md).

| Area | Progress | Current evidence |
| --- | --- | --- |
| Exact r519 route reference | [##########] 1/1 | Historical route reached `NOW LOADING`; exact R513 bundle/environment still need replay comparison. |
| First mission frame | [--------------------] 0/1 | No mission image or guest progression past loading. |
| Resource `0x1E` | [##########] 1/1 | Ready producer and passing consumer verified. |
| Mode-2 worker | [######--------------] 3/5 | Thread exit verified; success branch/completion predicate unknown. |
| BINK media read | [######--------------] 3/5 | Null-buffer access violation verified; causal role unknown. |
| Runtime context | [####----------------] 2/5 | Main context maps to `sub_00245430`; no valid full unwind. |
| Storage/build | [##########] 1/1 | 271,444 bytes reclaimed from r734; no build efficiency impact. |

**Next:** use r519's exact R513 bundle, environment, route inputs, and existing save root as the comparison baseline. Build one changed diagnostic candidate to report the `sub_00034720` failure/success branch and the BINK null-buffer caller/ownership; do not make a behavioral fix until that evidence supports one.

## Current checkpoint — r720–r722 (2026-11-01)

The first mission is still not reached. r720 reused the exact R513 executable from successful r519 and the existing R644 save root. It screen-gated through the title and campaign menus to LISTED PILOT; the selected DATA-000 fields were blank. It then faulted in the DirectSound list walker at guest VA `0xFFFFFFF4`. The crash is consistent with the previously documented null-node consumer. Retained r340 write-watch evidence identifies a `put_pixel+0x4AC` write of `0xFF000000` into the same list fields, but the active surface-to-guest mapping is still uncorrelated. No behavior fix is supported.

r721 and r722 reused the already-built R678 write-watch executable, matching symbols, and the same save root. Both stalled at the title player-record overlay before reaching the DirectSound list stage. r722 recorded 403 DCF4 callbacks, 34 marker rows, repeated branch-5 event publications, and a successful sampled DCF4 wait return. Its final native snapshot still shows the main thread in the wait bridge, but does not prove the historical persistent DCF4 producer stop. The R678 surface probe recorded no overlapping pixel write.

| Field | Progress | Verified state |
| --- | --- | --- |
| Exact R513 route to pilot list | [##########] 1/1 | R720 visibly reached LISTED PILOT; DATA-000 fields were blank. |
| First mission frame | [--------------------] 0/1 | No mission image and no verified guest progression beyond loading. |
| DirectSound list failure | [##########] 1/1 reproduced | R720 faulted at guest VA `0xFFFFFFF4`; R340 retained writer rows point to `put_pixel+0x4AC`. |
| Writer-to-surface mapping | [####----------------] 2/5 | Writer, pixel value, and target fields are known; active NV2A surface descriptor/pitch/alias remain uncorrelated. |
| Title DCF4 | [######--------------] 3/5 | R722 branch 1/5 callbacks and a sampled wait return were recorded; persistent wait cause remains unproven. |
| R513 loading route | [##########] 1/1 historical | R719 reached visible NOW LOADING on R513, then a white 640×480 frame; no mission verified. |
| Storage/build | [##########] 1/1 | Closed r720–r722 evidence compressed losslessly: 17,597,036 logical / 3,332,621 allocated bytes; 2,714,778 allocated bytes reclaimed. No build/cache changes. |

**Current save-state difference:** the reused R644 root now includes `user05.sav` and `user99.sav` (both 2,812 bytes; hashes recorded in the [r720–r722 report](m3-r720-r722-route-and-runtime-findings-20261101.md)). The targeted `user05.sav` reads completed with status 0, but its presence and successful read do not establish a valid pilot record. No save files were cloned or cleared.

**Next:** retain the exact R513 crash and r340 writer as the baseline. Correlate the first `put_pixel` store with the actual NV2A color surface and guest-memory alias before changing rendering or audio behavior. Keep title DCF4 separate; the r722 branch publications and sampled return do not support an event-semantic change. Stop only on a retained first-mission image corroborated by guest progression. Details: [r720–r722 report](m3-r720-r722-route-and-runtime-findings-20261101.md).

## Historical checkpoint — r671 (superseded by r720–r722)

r671 reused the exact R513 AOT bundle used by r519 and an existing save root in place. The manually screen-gated new-pilot route verified the name/date, Normal difficulty, and visible `NOW LOADING` transition. It did not reach gameplay. The generic 900-second watchdog ended the process with exit code 3; it was not a crash, DCF4 timeout, or storage cap.

The index `0x1E` loader consumer first saw ready byte `0x00351F22=0`; its producer then set the byte to 1, and the helper recorded decision 6 (readiness passed/follow-up reached). This resource is not the remaining observed predicate. A final sampled read completed `5112/5112` bytes, but targeted BIK reads were not configured. A 40.6-second `GUEST-CPU-ACQUIRE` row at caller `0x00223EC8` is not causal proof: no native minidump was captured, the indirect target at `0x0025D25C` is unresolved, and the guest CPU snapshot showed no owner or waiter.

| Field | Progress | Verified state |
| --- | --- | --- |
| R513 route | [##########] 1/1 | Pilot A, date 01/01/2002, Normal difficulty, and NOW LOADING visually verified. |
| First mission frame | [--------------------] 0/1 | No gameplay image or verified progression beyond loading. |
| Resource `0x1E` | [##########] 1/1 | Consumer saw not-ready; producer set ready; consumer passed the check. |
| Later loader handoff | [##------------------] 1/5 | Post-`0x1E` predicate/producer and targeted BIK completion remain unknown. |
| Lock/DCF4/raster | [####----------------] 2/5 | R671 DCF4 callbacks continued; lock row is only a lead; no mission-stage rendering evidence. |
| Storage/build | [##########] 1/1 | r671: 34,293,815 logical / 10,890,118 allocated bytes after lossless compression; 7,958 allocated bytes reclaimed. No build/cache change. |

**Next:** use the already-saved `user06.sav` from the r623 root with R513; capture bounded BINK object/wait/I/O and targeted `s00ev01j.bik` reads, plus a matched native dump if loading stalls. Details: [r671 report](m3-r671-r513-loading-watchdog-20261101.md).

## Historical checkpoint — r623 (superseded by r671)

r623 reused the exact r605 AOT bundle and the existing save root. The screen-gated route created pilot `A` with birth date `01/01/2002`, selected `HAI SHI DAO 2080 [NORMAL]`, and reached `NOW LOADING`. The save root now has `user06.sav` and an updated `user99.sav`; preserve both and use the saved pilot for the next route. The retained final framebuffer is black, not a mission scene.

The mode-2 worker thread transitioned to exit status `1` after 116 polls, and the resource `0x1E` ready flag was set and observed. Yet the final loader callback at site `0x00101F90` still returned zero with mode `2`, progress `0x000ABA00/0`, and statuses `0/0`. The target remains synthetic `0xFE000000`; its slot/API meaning and the remaining completion predicate are unknown.

At tick `164220531`, guest caller `0x0018E149` made five successful reads on the opened BIK handle, then attempted a 10,640-byte read with guest buffer zero and received `0xC0000005`. The bridge returned the documented access violation; the AOT caller's branch and whether it blocks mission entry are unverified. TID `52956` was in AOT code at dump time, but its unwind stopped at a non-module address. r623 disabled raster worker timing, so high CPU use cannot be assigned to rendering or loading.

| Field | Progress | Verified state |
| --- | --- | --- |
| AOT route | [##########] 1/1 | New pilot persisted; Normal difficulty and `NOW LOADING` visually verified. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond loading. |
| Mode-2 handoff | [######--------------] 3/5 | Worker exit and resource readiness verified; remaining callback predicate unknown. |
| BIK I/O | [####----------------] 2/5 | Five reads succeeded; later null-buffer request returned access violation; effect on progression unknown. |
| Rendering vs loader | [##------------------] 1/5 | Matched dump is in AOT code; raster timing disabled and guest unwind incomplete. |
| Storage/build | [##########] 1/1 | r623 was compressed losslessly: 11,235,935 logical / 1,403,486 allocated bytes, saving 883,477 bytes. No build or cache change. |

**Next:** use the saved `user06` pilot with the same bundle. Add bounded BINK object/wait/I/O traces and low-volume raster timing while retaining the mode-2 worker and target-read evidence. Stop at the first visually verified mission frame. Details: [r623 report](m3-r623-mode2-worker-and-bik-read-20261101.md).

## Current checkpoint — r622 (2026-11-01)

r622 reused the r605 AOT executable and the existing `saves-m3-first-level-route-20261023` save root in place. The screen-gated new-pilot route reached Difficulty Normal and a retained `NOW LOADING` frame. After 240 seconds without framebuffer/input change, the run stopped only its own PID `76412` and captured an exact-bundle dump. It did not reach the first mission frame.

At the final callback (`0x00102017`, tick `163423203`, TID `71352`), mode 2 remained active, result was zero, progress remained `0x000ABA00/0`, status was `0/0`, and the callback target was synthetic address `0xFE000000`. The range is registered as a synthetic thunk range; no unresolved-call record was found, but the slot/API meaning is not validated. Do not seed it. Resource `0x1E` became ready, was observed by a consumer, and is not proven to be the outstanding completion predicate.

The loading run recorded regular DCF4 callback and DMA publication activity, unlike r621's title-stage unmatched DCF4 wait. Successful file opens were observed after loading, but targeted read completion covered save files only; BIK-target reads were absent. Therefore a missing asset read is not established. Native unwinds for the loader thread and file/path worker reached the same `fprintf+0x3D` endpoint. That makes diagnostic-output contention a testable candidate, but no lock owner or guest causal callsite was established. The next experiment will reduce high-volume diagnostics and add the missing worker-schedule and targeted asset-read evidence.

| Field | Progress | Verified state |
| --- | --- | --- |
| AOT screen-gated route | [##########] 1/1 | New-pilot route reached Normal and retained `NOW LOADING`. |
| First mission frame | [--------------------] 0/1 | No mission scene or guest progression beyond the mode-2 plateau. |
| Mode-2 completion | [####----------------] 2/5 | Callback, progress and resource `0x1E` readiness observed; predicate and producer uncorrelated. |
| File completion | [##------------------] 1/5 | Named opens observed; loading-asset read completions not captured. |
| DCF4 loading path | [##########] 1/1 | Callback/marker/DMA activity continued; no title-style unmatched wait reproduced. |
| Diagnostic contention | [####----------------] 2/5 | Two native unwind endpoints reach `fprintf`; no lock owner or guest cause proved. |
| Storage/build | [##########] 1/1 | r622 evidence: 23,554,805 logical / 6,700,258 allocated bytes; no build/cache changes or cleanup savings. |

**Next:** one capped, low-output screen-gated route using the same bundle and save root; enable worker scheduling, worker-state, loader callback/helper and targeted asset-read completion traces. Stop at the first visually verified mission frame. Details: [r622 report](m3-r622-mode2-loader-plateau-and-output-contention-20261101.md).

## Current checkpoint — r621 (2026-11-01)

r621 used the prebuilt r605 AOT executable and the existing first-level save root in place. Four title-screen A pulses reached XID. The second pulse displayed `Unable to load Player Record`; later pulses did not clear it. This was not the full r519 route. The title callback/input trace was suppressed by `LoadingFocus`, so the operation and branch selecting the overlay remain unproven.

The wait trace identifies a title-stage DCF4 wait: producer caller `0x0021702F` last set event `0x0021DCF4` / host `0xE5C` at tick `162565328`; at `162565375`, TID `75216` reset the event and waited indefinitely from caller hint `0x00211F3B`. No later set or matching return was recorded before stop. A read-only native dump shows the thread in `xbox_KeWaitForSingleObject`; guest stack candidates are not validated unwinds. The DISPATCH gate and guest CPU were free, separating this from r620's gate-owner lead. Producer/callback branch tracing is still needed before any synchronization fix.

The save root has `user00`–`user05` and `user99`; `user06` and `user07` are absent. Those two missing slots are ordinary free-slot probes, not an established cause. `user99.sav` exists, but r621 captured no successful open/read or status for it. No save files were modified.

| Field | Progress | Verified state |
| --- | --- | --- |
| AOT title input | [##########] 1/1 | Four A pulses reached XID; error overlay was visually retained. |
| First mission frame | [--------------------] 0/1 | No route beyond title; no mission scene. |
| DCF4 handoff | [######--------------] 2/4 | Last producer set and unmatched wait identified; callback branch and resumed producer unknown. |
| Player-record rejection | [##------------------] 1/4 | Overlay and expected free-slot misses observed; rejecting operation/status unknown. |
| Storage/build | [##########] 1/1 | r621 evidence: 6,009,078 logical / 2,395,282 allocated bytes; no build or cache change. |

**Next experiment:** use the complete screen-gated new-pilot route with this same AOT bundle and save root. Enable bounded DCF4 producer/callback/gate/queue traces, title input/edge traces, per-open status, and targeted reads for save-record paths. Disable generic read sampling and use `DisableHighVolumeMenuTrace` rather than `LoadingFocus`. Preserve event semantics; do not patch until producer publication and callback branch agree. Full evidence and limitations: [r621 report](m3-r621-title-dcf4-wait-and-player-record-20261101.md).
## Historical checkpoint — r620 (superseded by r621)

r620 used a prebuilt r605 AOT bundle and `saves-m3-first-level-route-20261023` in place. It was r617-derived, not the exact r519 bundle/full route: the first 40 inputs followed r519, then 10 additional screen-gated inputs were needed for the observed name-entry state. It visually reached `HAI SHI DAO 2080 [NORMAL]` and `NOW LOADING`, then its UI watchdog stopped the run after 240 seconds without screen/input progress. No first mission frame was verified. The run generated no BINK wait or targeted BIK read records; the generic read trace hit its 10,000-sample ceiling. The 64 MiB budget was not reached and the async relay dropped no lines.

A final exact-bundle native dump shows threads waiting in `xbox_DispatchGateEnter` while the DISPATCH critical section records TID 55548 as owner; that thread unwinds to `guest_cpu_acquire`. Two snapshots show guest CPU `free=1`, `waiting=0`, `owner=0`. This is a synchronization candidate only: gate tracing and guest CPU snapshots were disabled, and the guest-side completion predicate/producer are not yet correlated. The 4 MiB allocation request was clamped to 2 MiB and the route continued; it is not established as the blocker. The prior DCF4 samples returned signaled.

| Field | Progress | Verified state |
| --- | --- | --- |
| AOT route through loading | [##########] 1/1 | Difficulty Normal and NOW LOADING visually retained. |
| First mission frame | [--------------------] 0/1 | No mission scene or progression past loading. |
| Loader handoff correlation | [##------------------] 1/4 | Native gate owner/waiters captured; guest predicate, producer, and consumer still uncorrelated. |
| BINK/file dependency | [##------------------] 1/4 | BINK tracing enabled but emitted zero rows; named open paths were not enabled. |
| Storage/build | [##########] 1/1 | r620 evidence: 11,893,635 logical / 3,604,537 allocated bytes; no build, cache change, or deletion. |

**Historical next experiment from r620:** superseded by the r621 title-stage DCF4 finding and the updated plan below.
## Historical checkpoint — r553/r554 (superseded by r620)

The exact r519 r513 AOT bundle was reused with the existing save root. The screen-gated route reached Campaign and the pilot list, but the current save state no longer supports the r519 new-pilot route: all eight pilot slot files (`user00.sav`–`user07.sav`) exist and their 2,792-byte record payloads are zero. `LIST AS NEW` reports the pilot limit; DATA-000 displays blank fields and fails to load. No save was changed or removed.

r554 traced the DATA-000 read to `T:\user00.sav`, guest caller `0x0018E149`, handle token `0x48000085`. Both the 2,792-byte payload and 20-byte trailer were fully read with host, NT, and guest status `0`. This rules out a file I/O failure. The precise guest validation return that selects the overlay is not yet traced, and no code fix is supported. The visible deletion option was not used.

| Field | Evidence bar | Verified state |
| --- | --- | --- |
| AOT reference bundle | [##########] 1/1 | Exact r519 EXE/PDB/MAP reused in r554. |
| Pilot-menu route | [##########] 1/1 | Campaign and listed-pilot screens reached; full-slot warning and blank DATA-000 error verified. |
| First mission frame | [--------------------] 0/1 | No mission scene; the current save root blocks the new-pilot route. |
| Save-read correlation | [##########] 1/1 | Full DATA-000 file reads succeed; payload is blank, so the exact guest validation branch remains to trace. |
| DCF4 during r554 route | [##########] 1/1 | DCF4 callbacks ran through menu transitions; no DCF4 cap was hit and this route did not reproduce the historical unmatched wait. |
| Storage/build | [##########] 1/1 | r553+r554 added 4,367,010 allocated bytes of bounded evidence; no build, deletion, or cache change. |

**Immediate blocker:** the retained root has no valid pilot record and all eight slots are occupied. Preserve it as requested. Resume the campaign route after a valid pilot record/free slot is available; then revisit r519's post-NOW-LOADING mode-2 plateau. Full run identity, evidence paths, and limitations: [r553–r554 diagnosis](m3-r553-r554-save-state-route-diagnosis-20261031.md).


**DCF4 correlation correction (r525):** Ordinary `wait-trace.log` includes sampled DCF4 events. `wait-DCF4[64]` (TID 31684, tick 115008921) used guest event `0x0021DCF4` / host handle `0x1020` and returned at tick 115008953. The matched dump's valid unwind for TID 31684 ends at the same non-module `0x1020`, and its register context has `RCX=0x1020`; an outstanding DCF4 host-event wait at dump time is strongly supported. See the corrected [r525 report](m3-r525-dsound-watch-title-stall-20261031.md).

**Latest verified route: r545.** Reused the exact r513 AOT bundle and existing save root. The screen-gated new-pilot path reached a retained, visually verified `NOW LOADING` frame, but not the first mission scene. The 4 MiB reserve request also appeared in r519; r519 logged a successful 2 MiB clamp, and r411 showed the worker later completed. This is not a supported cause of the loader stall. See [r545 loading handoff review](m3-r545-loader-handoff-review-20261031.md), [r519 report](m3-r519-loading-allocation-report-20261031.md), and [r411/r412 report](m3-r411-r412-loader-and-storage-20261030.md).

The next unresolved handoff is the mode-2 worker scheduler: `sub_00017E80` checks whether the existing worker object is still pending; its result gates a new `sub_0001DAA0` worker at `0x00101FBA`. Existing bounded environment traces cover the gate, worker start, object status, and resource `0x1E` readiness. At the last app inventory, another chat's r502 diagnostic remained open; no route was launched alongside it.

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r519 and r545 reached visible `NOW LOADING`; r545's retained frame verifies the screen. r533 independently reproduced the invalid DirectSound list consumer after a pilot-list callback; the corruption writer is known from r340, while the surface mapping at the store is not. r534–r538 captured title-stage DCF4 waits, with r538 correlating the final missing signal to an empty outer callback queue. r535 and r537 had PGRAPH/DMA/semaphore acknowledgements, and subsequent heartbeats showed drained raster/DMA while DCF4 remained clear. No run has verified a mission frame. Missing save/cache paths remain candidates, not a confirmed cause. The low/high allocator fix remains in source and its real thunk regression passes, but the GET_REPORT address alias remains uncorrelated in-game. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` remain unchanged.

The r523 follow-up reran the warm five-mode regression suite: **42 checks passed, 0 failed, under 1 second; no rebuild**. Generated AOT confirms r495's `0x82A9BFF0` is the entry pointer from `sub_0020F1F0` for handle `0x3FFF`; that helper allocates only when its page-table slot is empty. The trace omits the slot's pre-call value and has no `[CONTIG-EX]` allocation result. It also has no `[PB-REPORT]` consumption record. Thus allocation-vs-reuse, packet consumption, report DMA descriptor, writeback target, and guest alias remain unverified. No runtime source change is supported. Focused candidate-history and nested-log measurements matched the r522 audit. The r522 run-folder query now measures 1,841,701 B versus 1,845,944 B previously reported; no files were changed, so the 4,243 B difference is unexplained and not counted as savings. At that earlier r523 check, PID 52452 was the user's Call of Duty HQ process and no route was started; r524 later ran with that process still open by explicit authorization.

Progress bars track evidence, not estimated completion:

| Field | Evidence bar | Verified state |
| --- | --- | --- |
| AOT executable | [##########] 1/1 | Exact r513 EXE/PDB/MAP bundle reused through r554. |
| Campaign | [--------------------] 0/1 | First mission frame not reached. |
| New-pilot route | [##########] historical / blocked now | r519/r545 reached visible `NOW LOADING`; r554 verified the current save root blocks new-pilot selection before loading. |
| DirectSound writer | [##########----------] 2/4 | r340 confirmed `put_pixel+0x4AC` stores pixel value `0xFF000000` to list fields; r533 reproduced the null-node consumer. Active target mapping at the write remains unverified. |
| DCF4 title synchronization | [################----] 4/5 | r538 matched the final wait to `sub_00211E10` and host handle `0xE78`; the last branch-5 signal preceded the final wait, then the outer dispatcher continued with empty slots. The upstream work-item producer remains unresolved. |
| Contiguous allocation | [##########] 1/1 regression | Actual ordinal-166 thunk test passes beyond 16 MiB with range, alignment, overlap, and graceful-failure checks. In-game caller provenance is absent. |
| GET_REPORT DMA | [##------------------] 1/5 | The real executor's low-offset writeback regression passes; r495's type-3 packet/context/alias was not observed in r521, r524, or r525. |
| Loading dependency | [####----------------] 2/5 | r545 confirms visible loading. Prior r410/r411 ruled out an unready resource `0x1E` and the completed 4 MiB reserve as sole causes; the mode-2 scheduler gate is next. |
| Rendering / pacing | [##------------------] 1/5 | r521 title/menu output varied around 8–23 FPS; no mission frame or gameplay pacing measurement. |
| Regressions | [##########] 5/5 | r523 rerun: all five warm modes passed, 42 checks, zero failures, under 1 second; no rebuild. |
| Storage | [##########----------] 12,705,125 B measured savings | Closed r538 compression reclaimed 1,686,144 allocated B with all hashes preserved. Recent run-evidence recovery through r538 totals 12,705,125 B; r528–r538 retain 14,626,238 allocated B. No whole-workspace rescan or build-cache change. |
| Stable 60 FPS | [--------------------] 0/1 | Not measured in a mission. |
| Whole campaign | [--------------------] 0/1 | Campaign completion unverified. |

## Current diagnosis

- The current ordinal-166 bridge routes ordinary bounded requests through `xbox_ContiguousAllocRange`. The real synthetic-XBE/thunk test passed after the arena advanced beyond 16 MiB, including bounds, alignment, overlap, and non-advancing failure checks. r521 emitted no `[CONTIG-EX]`; r495's page `0x82A9B000` is not proven to come from that constrained call.
- The executor regression passed a guest-shaped pushbuffer through `nv2a_pb_scan` and verified low-alias GET_REPORT completion plus guard words. It does not cover a populated nonzero report DMA descriptor. r521 emitted no `0x17CC`/`[PB-REPORT]`; the r495 parameter `0x03A9BFF0`, DMA context, executor target, and guest poll at `0x82A9BFFC` remain uncorrelated. No report-path change is supported.
- Loader helper `sub_000C2EB0` completed pass-through for resource index `0x1E`: final helper record `n=612` selected the paired-open comparison path, decision `6`, returned `1`, and recorded handles `0x48000081/82/81`. The ready callback set byte `0x00351F22` to `1`; its copy size was `0`. The next mode-2 scan (`n=34`, guest return `0x000C32D6`) returned `0`, `last_index=28`, progress `0x000ABA00/0`. Callback site `0x00102017` continued polling that unchanged pair through tick `109410828`.
- r521 reached the new-pilot name editor with visible AOT frames. Its `[XID0]` and `[XID-DMA0]` rows show button reports reached the guest USB path, but the build emitted zero pilot-list callback, input-dispatch/edge, loader-helper, device-entry, allocation, and GET_REPORT records. The full guest input-to-callback chain and target handoff therefore remain unverified.
- r521 crashed before pilot confirmation in `sub_0021ED29+0x88` (`recomp_0016.c:1717`), reading guest VA `0xFFFFFFF4` from `ESI=0xFFFFFFEC`; caller return was `0x0021FECA` and `EBX=0`. The DirectSound voice-list chain ended at NULL. This proves the immediate bad list node, not who wrote or cleared it. Keep this DirectSound failure distinct from the r519/r502 loading plateaus and r495/r501 report retry.
- r524 independently reproduced the DirectSound invalid-list traversal. Later r340 evidence established the corrupting store: `put_pixel+0x4AC` wrote pixel value `0xFF000000` into list fields `0x8038C08C/98/9C`; r533 reproduced the downstream null-node read at guest VA `0xFFFFFFF4`. The synchronized NV2A surface at the store remains unverified, so no behavior fix is supported. The r534/r535 write-watch runs stopped earlier at title DCF4 and captured only valid initialization writes.
- DCF4 waits #5248, #5312, and #5376 all returned with signal `1`. Callback tracing continued through `n=11312`; DMA PUT/GET and NV2A ticks advanced in the final sampled interval. One heartbeat showed raster pending `3` with active workers, while the prior heartbeat showed pending `0`. This run does not establish a DCF4 wait as the loading cause or prove raster backlog caused the stall.
- r526/r527 separated ring-poll tracing overhead from the title DCF4 stall: the same title wait reproduced with ring-poll instrumentation disabled. r528 recorded the indirect target at `0x00217029` as `0xFE000108`, already mapped by the existing XBE import record to ordinal `0x91` / `KeSetEvent`; no thunk seeding is appropriate.
- r530's final synchronization sequence is specific: callback #336 (arg `5`, branch 5) called the valid DCF4 setter at tick `117079171`; TID `40152` then reset and began another wait at tick `117079203`. Callback #337 (arg `0x01080021`, branch 1, target `0x00216EC9`) followed at tick `117079468` with gate `out100=0`; no later branch-5 callback, DCF4 set, or wait return was recorded. The outer dispatcher continued with aggregate `0` and queue pointers `0`. Later heartbeat had raster `pending=0`, `active=0`, and DMA PUT=GET=`0x5E84`. This supports an outstanding DCF4 event wait after the render queue drained, not a rendering backlog.
- In r530 the title loop's last query was tick `117079203`, before the live `a:5000` report arrived at tick `117087578` and DMA wrote report byte 2=`1` to `0x81081763`; release at `117092578` restored it to `0`. This pulse reached guest DMA, but the thread was already in the wait, so it did not test a live title-handler edge.
- r531 screen-gated the first `a:5000` pulse at the visible title prompt. XID DMA wrote byte 2=`1` at tick `117562328`; edge consumption and predicate passed at `117562578`; title site `0x000E081F` returned 1 and the route advanced to `0x002DE366` at `117562593`. The next saved framebuffer visibly showed “Unable to load / Press MAIN WEAPON BUTTON to continue.” A second pulse reached XID DMA only after the main thread blocked and had no recorded guest consumer. This does not yet validate the new-pilot route or loader entry.
- r531 independently reproduces the DCF4 wait after callback #493 selected branch 5 and set guest event `0x0021DCF4` at tick `117568734`; TID 49456 entered `wait-before` at tick `117568765`. Callback #494 selected branch 1 at tick `117568781` with gate `out100=0`; no later set or wait return was recorded. The valid native unwind ends at host handle `0xEA0` with 69 successful reads and zero read failures. Later heartbeats show raster `pending=0`, `active=0`, and DMA PUT=GET=`0x5F1C`. Why branch-5 production ceases remains unresolved; no event behavior changed.
- r532 replayed all 40 retained r519 inputs relative to the detected title prompt. The first A caused no route transition; the second A at pad time 51,328 ms was accepted through guest edge consumer `0x000C8064`, title callback `0x000E081F`, and route advance to `0x002F812F` at tick `118033562`. TID 51900 entered the unmatched DCF4 wait at tick `118034281`; the matched unwind ends at host handle `0xE84` with 69 successful reads and zero read failures. Callback #351 selected branch 5 at tick `118034250`; #352 selected branch 1 at `118034296`, and no later setter or wait return was recorded. The outer callback thread continued with flags `0x01000000`, aggregate 0, and empty queue pointers. Later heartbeat: DCF4 signal 0, raster active/pending 0, DMA PUT=GET=`0x4E20`. File tracing recorded 222 opens and six missing paths (`st00_0.rep`, `config.sav`, `death00.sav`, `sasen00.sav`, `user06.sav`, `user07.sav`); `user99.sav` opened successfully. These are candidates only; no loader callback ran and no causal link is established.
- r529 exited before a title frame with RIP `0`, fault address `0`, and reported Xbox VA `0xFFFF0000`; it is not enough to attribute the fault to the DirectSound list. r530's list watch saw only valid initialization and sentinel insertion at `0x8038C098/09C/08C`, not `0xFF000000`.
- r522 title input is correlated through `[XID0]`/`[XID-DMA0]`, guest edge consumption at `0x000C8064` (`button_cell=0x004AFC08`), and title route site `0x000E081F`, which returned 1 and branched to `0x001F2DD5`. The visible player-record prompt did not change, but this run used only five `a:600` pulses and one `right:200`; r519's longer screen-gated sequence continued through campaign, pilot creation, difficulty, and visible loading. Therefore r522 did not reproduce the proven r519 route and does not establish a new game-code blocker. Its main native unwind reaches `xbox_KeWaitForSingleObject+0x29` but cannot unwind into guest code; sampled DCE4 wait #576 returned successfully in 31 ms, and DCE4 producer signals continued. Do not equate the title prompt with r502's loader plateau or an unmatched DCF4 wait.

## r533–r537 latest route diagnosis — 2026-10-31

r533–r537 used the exact r513 AOT bundle and the retained route timings. r533 accepted an edge at pilot callback `0x000E18D8`, then the DirectSound commit walker reached node `0`; `sub_0021FE7C` passed `0-0x14` to `sub_0021ED29`, whose dereference faulted at guest VA `0xFFFFFFF4`. The r340 report independently established a `put_pixel+0x4AC` store of `0xFF000000` into the same list fields. r533's graphics acknowledgements completed and DCF4 was signaled at its last heartbeat. The matched r340/r533 evidence supports an immediate renderer/list-corruption chain, but it does not identify the active NV2A surface mapping at the corrupting store.

r534–r537 all stopped earlier at title-stage DCF4 waits. Exact-symbol unwinds for TIDs 63676, 54552, 51940, and 60560 end at host event handles `0xF54`, `0x1038`, `0xFA4`, and `0xE7C`; each has zero stack-read failures. r535/r537 show PGRAPH, DMA and semaphore acknowledgements, then raster pending=0 and DMA PUT=GET while DCF4 remains unsignaled. The hardware DirectSound watch in r534/r535 recorded only 12 valid initialization writes and did not reach the later bad link. r537's surface-overlap trace emitted no row because the bad-link stage was not reached. The four early waits are separate from r533's DirectSound fault and r519's post-difficulty loader plateau.

Closed r533–r537 evidence used 25,149,700 logical bytes and 15,412,278 allocated bytes before compression; lossless NTFS compression reclaimed 7,763,610 allocated bytes with all hashes unchanged. They retain 7,648,668 allocated bytes. Recent measured recovery for r528–r537 is 11,018,981 bytes; this is not a whole-workspace rescan. No build, source edit, save copy, or cache purge occurred. Details: [r533–r537 report](m3-r533-r537-directsound-dcf4-20261031.md), [selected native unwinds](r533-r537-selected-native-unwinds-20261031.txt), and [compression audit](r533-r537-evidence-compression-20261031.csv).

## r538 ring-poll / DCF4 follow-up — 2026-10-31

r538 reused the exact r513 EXE/PDB/MAP and save root. The title screen was visually captured; six input edges were accepted, but no pilot-list callback or loading event followed. The last successful DCF4 wait-after was tick `120305015`, followed by wait-before at `120305031`, TID `13572`, caller hint `0x00211F3B` (`sub_00211E10`), host handle `0xE78`. The final branch-5 callback selected target `0x0021701E`; subsequent branch 1 selected `0x00216EC9`, then no further DCF4 set was recorded. The outer dispatcher remained active with sentinel work slots and zero aggregate; by tick `120432031`, raster was drained and DMA PUT=GET=`0x52B0`. This supports a producer-path stop with an unresolved missing work item. The ring trace emitted 256 samples at a 16,777,216 iteration stride and capped at 4,294,967,296 checks; its last sample predates the wait. No active surface or DirectSound list fault was captured. Closed-run lossless compression reclaimed 1,686,144 allocated bytes; hashes and lengths were unchanged. See [r538 report](m3-r538-title-dcf4-ring-20261031.md).
## r519 route preflight — 2026-10-31

The exact r513 EXE/PDB/MAP still match the recorded SHA-256 values; the existing `saves-m3-route-file-read-copy-20261023` root exists; and r519's 40-line `pad-live.txt` route is retained. `Start-ProducerTrace.ps1` still enables both `RECOMP_CONTIG_ALLOC_TRACE` and `RECOMP_PB_REPORT_TRACE` with the existing 64 MiB per-run budget. This older preflight retained the exact files and full screen-gated sequence for later runs. Current readings proceed independently of Call of Duty state.

For r519's separate mode-2 loading plateau, the retained run already has dense successful read completions and progress/helper records, but `RECOMP_FILE_OPEN_PATH_TRACE` and the loader paired-open target trace were unset. On the next route use `-EnableFileOpenPathTrace -EnableFileOpenTargetTrace -EnableFileFailurePathTrace`; these cap at 2,048 open paths, 2,048 paired-open attempts, and sampled failures, respectively. Keep file lifecycle logging off because previous runs showed it can slow file opens. This is a loader-only evidence addition; do not conflate it with the r495 report candidate.

## Exact r519 identity and retained evidence

- Run: `iso/local-analysis/logs/m3-r519-dcf4-producer-stages-20261031`; diagnostic PID `50584` was stopped only after its executable path was revalidated and CPU, trace sizes, and callbacks stayed unchanged across a sample.
- AOT EXE SHA-256: `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`.
- Matching PDB SHA-256: `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`.
- Matching MAP SHA-256: `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- Exact-bundle plateau dump SHA-256: `8ED42EFBBB9B90E8A39737566E717CD7AA9843A9F59F154FC0711DCE28A6D234`.
- Relay drops: 0. The 64 MiB budget did not trigger. One load-pair trace cap was reached (`512` emitted, `1` dropped). No framebuffer-history capture was saved by the run; the loading screen was visually verified from the live window.
- A later UI inventory found another chat's r502 window (`m3-device-entry-creator-poll-r502-20261031`, about 40 FPS / 2 draws). It was left untouched. No new route was started concurrently; the 13:16 whole-workspace scan may overlap that run's output.

Older exact-r149-bundle dumps were reviewed before drawing cross-run conclusions. r150/r151 are title-stage DCF4 observations; r153 is a post-difficulty graphics-progress plateau with DCF4 signaled and capped DMA-ack evidence. None identifies r519's loader dependency. Keep these, DirectSound corruption, r502's earlier mode-2 plateau, and r519 distinct.

## Historical next action from r523 (superseded by r621)

Capture the indirect callback target loaded through guest address `0x25D1EC` and the queue slot transition before the final branch-5 callback in `sub_00211E10`. Then replay a route that reaches the known pilot callback and only then enable the DirectSound surface-overlap probe for the `0x8038C098` store. Do not patch event, renderer, or DirectSound behavior from the current data. Preserve AOT, guest checks and fences, controller mapping, and rasterizer `1ea1871`; stop at the first visually verified mission frame. COD state does not gate the reading.

Details: [r520/r521 allocation and pilot crash report](m3-r520-r521-allocation-and-pilot-crash-20261031.md); [r519 loading and allocation/report report](m3-r519-loading-allocation-report-20261031.md); [r519 storage manifest](current-cleanup-manifest-r519-20261031.md); [r150/r151/r153 matched unwind review](m3-dump-unwind-review-r150-r153-20261028.md).

## Previous route coordination snapshot — 2026-10-31 13:20 CDT

`sky.list_windows()` returned the other chat's `m3-icall-seed-r494-20261031` window (id `9045230`, about 10 FPS / 29 draws). The app inventory also showed an r502 entry, but `get_window` rejected that stale window id; the current window list identified r494 at that time. No interaction or stop was performed. This 13:20 snapshot is superseded by the later r520/r521 checks below.

## Latest verified run and storage — 2026-10-31 13:43 CDT

The r521 route used the exact r513 EXE/PDB/MAP and existing save root, reached the name editor, then exited with access violation `0xC0000005` in the DirectSound list walk. No source fix or mission frame resulted. The warm five-mode regression binary passed all 42 checks; it was not rebuilt.

Candidate-history and nested-log allocated totals match their prior audits. The protected input/save floor is 10,578,219,166 allocated bytes. Lossless in-place compression of 27 closed r520/r521 evidence files reclaimed 13,325 allocated bytes, with all hashes unchanged. No builds, saves, caches, or historical duplicates were deleted. Current process check found no running ProducerTrace game.

The existing save root was used in place; `Partition0.img`–`Partition5.img` timestamps changed and `Cache\COPYCHECK.DAT` was written during r521. No save copy or hard link was made, and the save root remains intact in its post-run state.

## Latest verified run and storage — r522, 2026-10-31 13:54 CDT

r522 used the same exact r513 bundle and stopped at the title/player-record prompt after five A inputs and one right input. The trace verifies the first A press through XID delivery, the guest edge cell, and the title-route branch; the screen remained unchanged. Its captured native unwind reaches `xbox_KeWaitForSingleObject+0x29` but not a validated guest caller. Sampled DCE4 wait #576 returned success; no GET_REPORT or bounded allocation record occurred. The first mission frame remains unverified. The exact run and evidence are in [r522 report](m3-r522-report-allocator-route-and-storage-20261031.md).

Allocated space was remeasured for candidate history, nested historical logs, protected ISO/extracted data/save root, generated source, current r513 symbols, regression cache, and r522 evidence. The historical subtree totals match prior audits. Candidate EXE/PDB/MAP hashing found only empty MAP duplicates. No removal or compression occurred; r522 added 1,845,944 allocated bytes and build/cache efficiency was unchanged. The protected input/save floor is 10,578,219,166 bytes. See [r522 storage manifest](current-cleanup-manifest-r522-20261031.md).

The save root was reused in place. r522 touched the six partition images and wrote `Cache\COPYCHECK.DAT`; it remains intact and was not copied or hard-linked.

## r523 allocator/report and storage follow-up — 2026-10-31

No later completed report existed. A read-only process check found no Steel Battalion/build process and found user process PID 52452 (`cod.exe`); it was left untouched, and no route replay was started. The five warm regression modes were rerun successfully: default 4, heap-reclaim 9, contig-range 16, ext-vma 12, ext-vma-128 1 (42 total, zero failures, under one second). The run used the actual ordinal-166 thunk and existing low-page NV2A executor/report-writeback check; no source change or rebuild occurred. This test does not exercise a nonzero report DMA descriptor.

The r495 log's `create-entry-return` row proves the table entry address and later invalid lookup state, but does not prove which allocation produced the page. It contains no `[CONTIG-EX]` or `[PB-REPORT]` line. The packet, active report DMA descriptor, executor target, and CPU-polled alias remain uncorrelated; no report-contract fix is justified. Focused allocated-byte measurements match the r522 audit: candidate history 6,305,103,821 B; nested historical logs 4,821,252,507 B; full build tree 8,081,749,248 B; `iso` 19,739,404,383 B; warm route save root 952,918,462 B. No data was deleted, moved, compressed, or copied; savings are 0 B this turn and build efficiency is unchanged. Full details: [r523 follow-up](m3-r523-allocator-report-and-storage-followup-20261031.md).


## Repository safety and source preservation — 2026-10-31

The root Git audit found zero tracked ISO/XBE/assets/generated-game-code paths, and `.gitignore` excludes `iso/`, generated game code, and all of `local-tools/`. That last rule leaves XboxRecomp source changes outside the root repository. A fresh 696,130-byte patch now preserves 48 tracked runtime deltas against nested base `193e2995`; reverse-apply validation passed. Exact exclusions and untracked source hashes are in `analysis/xboxrecomp-source-preservation-manifest-20261031.md`. The patch and manifest remain local and uncommitted; forward apply and clean rebuild are unverified.

## Dependency license notes — 2026-10-31

The root `LICENSES/` now contains byte-identical XboxRecomp LGPL-2.1 text and NOTICE for the xemu-derived APU/NV2A components in the preservation patch. README distinguishes dependency notices from game files; full release-license review remains pending. Nothing was committed or published.


Nested checkout protection: the inner XboxRecomp `.gitignore` now hides local ISO/tools/build trees, generated shader outputs, dumps, screenshots, logs, and symbols; representative `git check-ignore` probes passed. The current source patch is 714,127 bytes and reverse-applies cleanly; it remains local and uncommitted.
