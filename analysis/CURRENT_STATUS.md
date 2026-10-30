# Steel Battalion AOT — current status (r412, 2026-10-30)

**Milestone:** 3 — boot and compatibility. **First visually verified mission frame: 0/1.** r411 reached the post-difficulty mode-2 plateau on a solid white framebuffer; r412 crashed earlier in DirectSound voice-list traversal before reaching the scheduler gate. Neither verified `NOW LOADING` or a mission frame.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT path retained
Boot and campaign entry         [########------------] 40%  Mode-2 loader reached on r411
Kernel/runtime compatibility   [######--------------] 30%  Next mode-2 handoff unresolved
Graphics / rendering            [###-----------------] 15%  White frame; mission render/60 FPS unverified
Controller compatibility       [#####---------------] 25%  New-pilot screen route observed
Audio / DSP                     [###-----------------] 15%  Mission audio unverified; separate DS list crash
Debugging and evidence          [#################---] 85%  r411 exact dump/bundle and r412 crash trace retained
Storage control                 [#################---] 85%  839,530 allocated bytes reclaimed this pass
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Current diagnosis

- r411 (`m3-mode2-memory-reserve-followup-r411-20261030`) reused exact r409 EXE/PDB/MAP and the existing r368 save directory. It reached mode-2 loading after Normal, then stayed on a white frame for the 240-second plateau window. No runtime behavior changed.
- The 4 MiB reserve request did recur. The bridge clamped backing to 2 MiB and returned success; generated guest code checks success and advances using the returned size. The relevant worker completed with status 1. This is not evidence that the clamp caused the plateau.
- Resource `0x1E` became ready and the worker completed, but the mode-2 pair remained `0x000ABA00/0`. Sampled file reads succeeded; complete dependency consumption is unverified. DCF4 waits returned signaled in r411.
- r411's exact-symbol unwind recovered only main TID 184224 at EXE+`0x611AF7` (`sub_0001D980+0xB7`, `game_render`) before an invalid non-module boundary. No validated guest wait chain or next producer was established. `PRELOAD-WORKER-SCHEDULE` and `LOAD-SCHED-GATE` were not reached in r411.
- r412 (`m3-mode2-scheduler-gate-followup-r412-20261030`) crashed at `sub_0021ED29+0x88` with invalid DirectSound list links and guest read VA `0xFFFFFFF4`. It stopped before mode-2; scheduler-gate count is 0. Treat this separately from the r411 loader plateau and historical title DCF4 wait.
- The r130 null-output `ObReferenceObjectByHandle` diagnosis is not being repeated; current completion behavior is observed separately. No evidence justifies forcing a signal, bypassing a guest check, changing preload mode, or altering fences.

## Storage

Post-publication inventory: 78,048 ordinary files, **41,653,173,364 allocated bytes** and **1,397,898,600,374 logical bytes**, plus 165,381,632 allocated bytes for 13 separately measured executable reparse entries. Combined allocated footprint: **41,818,554,996 bytes (38.947 GiB)**. Sparse images explain the logical/allocated gap. Closed r411/r412 evidence was compressed losslessly and hash-checked: **839,530 bytes reclaimed**. No files were deleted. The warm incremental build cache remains **7,136,856,349 allocated bytes**; no build ran. The duplicate archive deletion action was blocked by file-action review before execution, so its savings are zero.

Detailed findings: [r411–r412 report](m3-r411-r412-loader-and-storage-20261030.md). Current size and retention record: [r412 cleanup manifest](current-cleanup-manifest-r412-20261030.md). Latest completed pre-run review: [r408–r410 report](m3-r408-r410-mode2-readiness-and-storage-20261030.md).

## Next step

Use a bounded `RECOMP_LOAD_SCHED_GATE_TRACE` run only if the new-pilot path reaches that gate. Correlate predicate inputs, selected branch, enqueue result, worker completion, and loader state. If the separate DirectSound crash occurs first, capture the corrupting writer and valid stack before changing it. Stop at the first visually verified mission frame.
