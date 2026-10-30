# r417–r418 title wait reproduction and storage record — 2026-10-30

## Result

The current earliest repeatable blocker is still the title-stage DCF4 handoff, before pilot-list dispatch. r418 corroborates the same branch sequence already captured by r271/r274 and r416; it does not establish why the guest chooses the non-signaling branch. The post-difficulty mode-2 plateau is a separate later failure: r415 remains the latest run to reach it. No runtime code changed, no build ran, and no first mission frame was verified.

The project-review handoff and the newer r414–r416 report were read before this work. r271 and r274 were also consulted after discovering their more specific DCF4 evidence. The pilot-list handler remains identified at `sub_000E1820` / callsite `0x000E18D8`; it was not rediscovered or used to explain this title wait.

## Process and evidence protection

At diagnostic launch there was no running Steel Battalion recomp executable. The old r154 review run was not present as an active game process. I did not touch the original ISO, r368 save root, shared source, generated code, build cache, or any other chat's run. A separate read-only PowerShell analysis of the r414 dump (PID 191704, launched 2026-10-30 05:11 CDT) was still active at final inspection; it was left running. Its target is the r414 dump with the r409 executable/map and the associated symbol directory.

Only the diagnostic children I started were stopped. r417 PID 191588 was stopped after its two title presses left a black framebuffer; its complete closed logs were preserved. r418 PID 193128 was automatically stopped by its own 120-second DCF4-wait watchdog after capturing `dcf4-stall.dmp`. No unrelated game process was stopped.

## r417 — branch trace enabled, route incomplete

- Run: `m3-mode2-worker-branch-r417-20261030`, PID 191588, started 2026-10-30 10:42:27.562 UTC.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-mode2-readiness-producer-consumer-r409-20261030/Release/your_game_recomp_producer_trace.exe`.
- EXE/PDB/MAP SHA-256: `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A` / `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17` / `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`.
- Reused `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030` without copying or hard-linking it. Its 36 files still measure 5,422,148,542 logical bytes / 110,715,000 allocated bytes. `Cache/COPYCHECK.DAT` has a 10/30 05:46:14 CDT timestamp during r418 startup; its prior content hash was not recorded, so its contents are not claimed unchanged. The UserData save payloads were not touched intentionally.
- `PRELOAD-WORKER_TRACE` was effective: requested mode 0 at caller `0x000E0109` produced one schedule row and the worker entered `0x00017E40` with mode 0 / branch `preload-mode0` at tick 605489468. No mode-2 route was reached.
- After the visible title prompt, the two screen-gated A presses produced a visible “Unable to load Player Record” message and then a black framebuffer. Counts: one mode-0 worker route, zero pilot/menu callbacks, zero input predicate/snapshot/edge traces, and zero loader passes. This run does not establish a full input path or new-pilot progression.
- Only two `a:800` actions were sent. The run was stopped manually while correcting the action sequence; it was not a crash or loader result.

## r418 — confirmed title-stage DCF4 wait

- Run: `m3-mode2-worker-route-r418-20261030`, PID 193128, started 2026-10-30 10:46:02 UTC. The child-only wait watchdog stopped it at 10:49:18.566805 UTC, 120 seconds after its unmatched wait.
- It used the same exact r409 EXE/PDB/MAP hashes above and the same r368 save root. It kept AOT execution, the input mapping, guest fences, and rasterizer `1ea1871` unchanged.
- The title input file contains two `a:800` actions. XID and DMA traces each emitted five rows including initial state and the two press/release pairs. The first press displayed “Unable to load Player Record”; the later framebuffer was black. `-LoadingFocus` disabled guest input predicate/snapshot/menu diagnostics, so guest edge delivery, callback state mutation, and campaign progression are unverified.
- The last completed DCF4 handoff was callback #1467 at tick `605757375`: argument `0x00000005`, selected index 5, target `0x0021701E`; `set-DCF4[511]` recorded caller `0x0021702F`.
- At tick `605757421`, DCF4 reset #512 saw `old_signal=1`, then wait #512 began on guest event `0x0021DCF4` with `signal=0`, caller hint `0x00211F3B`, frame `0x3B7`, counter `0x1057`, target `0x104D`, and semaphore `0x104D`. The exact callsite is in `sub_00211E10`; its generated code performs an indirect callback at `0x00211F39` and repeats at `0x00211F3B` while its return is nonzero.
- Callback #1468 at the wait tick selected index 1 / target `0x00216EC9`; callback #1469 at tick `605757484` selected index 1 / target `0x00216EC9` again with argument `0x01080021`. No later index-5 callback, DCF4 set, or wait return was recorded before watchdog stop. Thus the observed cause of the main thread's block is an unsignaled DCF4 wait after the previous signal was consumed. The reason the guest does not select the signaling branch next remains unknown.
- Exact-bundle native unwind for main TID 190944 reaches `ntdll.dll+0x161DD4` -> `KERNELBASE.dll+0x1BE9F` -> executable `+0x64A9F89`, which the matching MAP resolves to `xbox_KeWaitForSingleObject+0x29`; unwind stops at non-module address `0xD9C`. This is a native unwind, not a guest-stack scan. The explicit wait trace provides guest event and caller; a complete guest-stack unwind was not captured.
- Timer/callback TID 186548 unwinds to `kernel_timer_thread+0xE2`. The apparent following executable address `+0x6AC30A0` is `g_dpc_queue` data and is rejected as a return frame. DCE4 signaling continued independently. TID 183976 unwinds to `xbox_KeWaitForSingleObject+0x455`, then stops at non-module `0x11E2EC4`; this trace does not identify that secondary wait's object.
- At the final synchronized DCF4 snapshot, raster state was `batches=1`, `workers=4`, `pending=3`, `start=07`, `wake=07`, `complete=00`. This is a wait-time snapshot, not evidence that raster work caused the wait. Earlier r271 terminal samples showed an idle raster pool and equal DMA PUT/GET, so the DCF4 cause is not attributed to raster backlog.
- Trace-count report: 1,469 DCF4 callbacks, 1,467 gate rows, 576 outer-loop rows, 2,045 raster-sync rows, 156 DMA-ACK rows, 92 PB semaphore rows, 26 raster-performance windows, five XID/DMA rows each. No DCF4 callback/gate cap, relay drop, or 64-MiB run-budget trigger was recorded. The DCF4-wait detail file is first-N capped; its final retained row is wait #512. The main terminal state is also supported by the watchdog dump and stop record.

## Existing-run comparison and loader status

- r271 (`analysis/m3-r271-title-dcf4-outer-20261029.md`) used its exact r271 bundle and captured the same post-reset missing index-5 signaling branch. Its final synchronized raster pool was idle and DMA GET equaled PUT. Its 2,048-row outer-loop trace hit its cap before the final failure window.
- r274 (`analysis/r274-valid-native-unwinds-20261029.txt`) validates exact-bundle native unwinds for the main DCF4 waiter and timer callback thread, and explicitly distinguishes the caller hint from a guest stack unwind.
- r150/r151 establish the same title wait with the exact r149 bundle; their raster-worker stacks are separate native unwinds. r153's only selected stack is a point-in-time `DspState::read_memory` RIP and must not be treated as an unwind.
- r415 remains the relevant loader run: it completed the mode-2 worker and resource `0x1E` readiness, then stopped at output pair `0x000ABA00/0`. The current thread-object bridge resolves a valid guest object and reports completion status 1, so the r130 null-output diagnosis is not repeated. Cache misses were followed by successful source-asset opens; no first missing file or expected consumer is established.
- Neither r417 nor r418 reached pilot-list dispatch, `NOW LOADING`, or a mission frame. They say nothing new about the post-difficulty loader dependency. Title DCF4, mode-2 loader plateau, DirectSound list corruption, and rendering cost remain distinct.

## Storage, builds, and next experiment

The two closed runs contained 26 files totaling 10,355,026 logical bytes and 3,619,748 allocated bytes before NTFS compression. Lossless NTFS compression reduced allocation to 2,786,807 bytes, reclaiming **832,941 allocated bytes**; SHA-256 matched for all 26 files. Screenshots and dumps remain available and unchanged. Combined with r416's earlier 789,283-byte reclaim, r416–r418 have reclaimed **1,622,224 allocated bytes** without deleting evidence.

The latest full inventory baseline was the r416 post-push scan: 41,828,207,960 allocated bytes / 1,397,939,829,666 logical bytes. Adding r417/r418 and the current report/index/manifest deltas gives a path-summed estimate of **41,831,011,493 allocated bytes / 38.958165 GiB** and **1,397,950,201,418 logical bytes** across 78,185 ordinary files plus 13 reparse entries. This is derived from the full baseline and measured deltas, not a second full-tree scan. The warm incremental build cache remains 7,136,856,349 allocated bytes; generated source remains 155,890,474 bytes; the r368 save root remains 110,715,000 allocated / 5,422,148,542 logical bytes. No build was run and no cache was purged.

Next, use the same r409 AOT bundle and r368 save root, with guest input/predicate/snapshot traces enabled (do not use `LoadingFocus`) and the bounded worker-route trace enabled. Follow the known-good new-pilot route screen by screen. Test the mode-race hypothesis only by comparing each schedule request with the mode actually read at `sub_00017E40`: a mode-2 request followed by a different worker branch confirms it; a mode-2 branch rejects it. If mode 2 ran, correlate completed/outstanding file operations, loader state/pair, worker status, validated stacks, and synchronized graphics/events. Do not change runtime behavior until one relation is supported by the traces.

**Unverified:** guest input edge-to-pilot-handler chain in r418; reason the title producer stops selecting index 5; first post-worker loader dependency/consumer; visible `NOW LOADING`; first mission frame; mission audio/controller behavior; campaign completion; stable 60 FPS.
