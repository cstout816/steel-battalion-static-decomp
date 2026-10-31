# Steel Battalion AOT — current status (r523 follow-up, 2026-10-31)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r519 reached `NOW LOADING`; r521 reached the new-pilot editor before a DirectSound list-walk crash; r522 did not reproduce the longer r519 input route and stopped at the title/player-record prompt. Treat r522 as an incomplete route replay, not evidence of a new source regression. The low/high allocator fix remains in source and its real thunk regression passes. The GET_REPORT address alias remains uncorrelated in-game. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` remain unchanged.

The r523 follow-up reran the warm five-mode regression suite: **42 checks passed, 0 failed, under 1 second; no rebuild**. Generated AOT confirms r495's `0x82A9BFF0` is the entry pointer from `sub_0020F1F0` for handle `0x3FFF`; that helper allocates only when its page-table slot is empty. The trace omits the slot's pre-call value and has no `[CONTIG-EX]` allocation result. It also has no `[PB-REPORT]` consumption record. Thus allocation-vs-reuse, packet consumption, report DMA descriptor, writeback target, and guest alias remain unverified. No runtime source change is supported. Focused candidate-history and nested-log measurements matched the r522 audit. The r522 run-folder query now measures 1,841,701 B versus 1,845,944 B previously reported; no files were changed, so the 4,243 B difference is unexplained and not counted as savings. PID 52452 was the user's Call of Duty HQ process; it was left untouched and no route was started.

Progress bars track evidence, not estimated completion:

| Field | Evidence bar | Verified state |
| --- | --- | --- |
| AOT executable | [##########] 1/1 | Exact r513 EXE/PDB/MAP bundle used for r519, r521, and r522. |
| Campaign | [--------------------] 0/1 | First mission frame not reached. |
| New-pilot route | [##########] 1/1 to name editor | r521 reached the visible name editor; pilot submission and mission loading were not reached. |
| Contiguous allocation | [##########] 1/1 regression | Actual ordinal-166 thunk test passes beyond 16 MiB with range, alignment, overlap, and graceful-failure checks. In-game caller provenance is absent. |
| GET_REPORT DMA | [##------------------] 1/5 | The real executor's low-offset writeback regression passes; r495's type-3 packet/context/alias was not observed in r521. |
| Loading dependency | [##------------------] 1/5 | r519 captured a mode-2 readiness plateau. r521 crashed before loader-helper entry; no dependency path was identified. |
| Rendering / pacing | [##------------------] 1/5 | r521 title/menu output varied around 8–23 FPS; no mission frame or gameplay pacing measurement. |
| Regressions | [##########] 5/5 | r523 rerun: all five warm modes passed, 42 checks, zero failures, under 1 second; no rebuild. |
| Storage | [#-------------------] 19,116 B prior savings | r523 refreshed candidate history 6,305,103,821 B, nested historical logs 4,821,252,507 B, full build tree 8,081,749,248 B, and `iso` 19,739,404,383 B. No artifact removed or recompressed; cumulative savings remain 19,116 B. |
| Stable 60 FPS | [--------------------] 0/1 | Not measured in a mission. |
| Whole campaign | [--------------------] 0/1 | Campaign completion unverified. |

## Current diagnosis

- The current ordinal-166 bridge routes ordinary bounded requests through `xbox_ContiguousAllocRange`. The real synthetic-XBE/thunk test passed after the arena advanced beyond 16 MiB, including bounds, alignment, overlap, and non-advancing failure checks. r521 emitted no `[CONTIG-EX]`; r495's page `0x82A9B000` is not proven to come from that constrained call.
- The executor regression passed a guest-shaped pushbuffer through `nv2a_pb_scan` and verified low-alias GET_REPORT completion plus guard words. It does not cover a populated nonzero report DMA descriptor. r521 emitted no `0x17CC`/`[PB-REPORT]`; the r495 parameter `0x03A9BFF0`, DMA context, executor target, and guest poll at `0x82A9BFFC` remain uncorrelated. No report-path change is supported.
- Loader helper `sub_000C2EB0` completed pass-through for resource index `0x1E`: final helper record `n=612` selected the paired-open comparison path, decision `6`, returned `1`, and recorded handles `0x48000081/82/81`. The ready callback set byte `0x00351F22` to `1`; its copy size was `0`. The next mode-2 scan (`n=34`, guest return `0x000C32D6`) returned `0`, `last_index=28`, progress `0x000ABA00/0`. Callback site `0x00102017` continued polling that unchanged pair through tick `109410828`.
- r521 reached the new-pilot name editor with visible AOT frames. Its `[XID0]` and `[XID-DMA0]` rows show button reports reached the guest USB path, but the build emitted zero pilot-list callback, input-dispatch/edge, loader-helper, device-entry, allocation, and GET_REPORT records. The full guest input-to-callback chain and target handoff therefore remain unverified.
- r521 crashed before pilot confirmation in `sub_0021ED29+0x88` (`recomp_0016.c:1717`), reading guest VA `0xFFFFFFF4` from `ESI=0xFFFFFFEC`; caller return was `0x0021FECA` and `EBX=0`. The DirectSound voice-list chain ended at NULL. This proves the immediate bad list node, not who wrote or cleared it. Keep this DirectSound failure distinct from the r519/r502 loading plateaus and r495/r501 report retry.
- DCF4 waits #5248, #5312, and #5376 all returned with signal `1`. Callback tracing continued through `n=11312`; DMA PUT/GET and NV2A ticks advanced in the final sampled interval. One heartbeat showed raster pending `3` with active workers, while the prior heartbeat showed pending `0`. This run does not establish a DCF4 wait as the loading cause or prove raster backlog caused the stall.
- r522 title input is correlated through `[XID0]`/`[XID-DMA0]`, guest edge consumption at `0x000C8064` (`button_cell=0x004AFC08`), and title route site `0x000E081F`, which returned 1 and branched to `0x001F2DD5`. The visible player-record prompt did not change, but this run used only five `a:600` pulses and one `right:200`; r519's longer screen-gated sequence continued through campaign, pilot creation, difficulty, and visible loading. Therefore r522 did not reproduce the proven r519 route and does not establish a new game-code blocker. Its main native unwind reaches `xbox_KeWaitForSingleObject+0x29` but cannot unwind into guest code; sampled DCE4 wait #576 returned successfully in 31 ms, and DCE4 producer signals continued. Do not equate the title prompt with r502's loader plateau or an unmatched DCF4 wait.

## r519 route preflight — 2026-10-31

The exact r513 EXE/PDB/MAP still match the recorded SHA-256 values; the existing `saves-m3-route-file-read-copy-20261023` root exists; and r519's 40-line `pad-live.txt` route is retained. `Start-ProducerTrace.ps1` still enables both `RECOMP_CONTIG_ALLOC_TRACE` and `RECOMP_PB_REPORT_TRACE` with the existing 64 MiB per-run budget. No build or route was started because Call of Duty HQ remains active. The next attempt can reuse these exact files and the full screen-gated sequence without a new candidate or save copy.

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

## Next action

Do not alter the report offset/type or guest synchronization. When the user is no longer running a game, replay r519's full screen-gated input sequence on the exact existing r513 EXE/PDB/MAP and reuse the same writable save root. r519 already reached visible `NOW LOADING`; r522's shortened sequence is not a replacement route. Capture the allocator page-table slot before the helper branch, ordinal-166 arguments/result, consumed report packet, packet-time descriptor, executor target/writeback and guest poll in one synchronized run. Continue from the loading screen and stop at the first visually verified mission frame. Do not build another candidate or copy the save root.

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


