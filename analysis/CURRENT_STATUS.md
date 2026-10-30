# Steel Battalion AOT — current status (r416, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r415 reached the same post-difficulty mode-2 plateau as r414 after the new-pilot route. r416 reproduced a separate title-stage DCF4 wait before pilot-list dispatch. No runtime fix or mission progression has been verified.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution and exact-bundle diagnosis retained
Boot and campaign entry         [########------------] 40%  New-pilot route reaches mode 2; loader plateaus
Kernel/runtime compatibility   [######--------------] 30%  Post-worker loader handoff unresolved
Graphics / rendering            [###-----------------] 15%  White/title frames only; mission render unverified
Controller compatibility       [#####---------------] 25%  Screen-gated input route retained
Audio / DSP                     [###-----------------] 15%  Mission audio unverified; separate DS list issue
Debugging and evidence          [#################---] 85%  r414–r416 exact binaries, dumps and traces retained
Storage control                 [##################--] 90%  Allocated/logical inventory refreshed; r416 compressed
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Current diagnosis

- r414 full-read tracing and r415 sampled tracing reached the same mode-2 plateau. r415 rejects full-read trace volume alone as the cause. Its mode-2 worker completed, resource `0x1E` became ready, sampled reads succeeded, and the output pair stopped at `0x000ABA00/0`. The first stalled loader dependency and expected consumer remain unidentified.
- r416 is a distinct title-stage DCF4 stall. Exact-bundle unwind places main TID 188104 at `xbox_KeWaitForSingleObject+0x29`; raster workers are idle after the transient queue drained. The callback producer continued, but callback #512 selected index 1 / `0x00216EC9`, not a DCF4-setting branch, and no later DCF4 callback/set or wait return was recorded. This does not explain the mode-2 plateau.
- r415’s terminal DCF4 sample cannot be paired with the last wait using row sequence numbers; it does not prove a DCF4 stall there.
- DirectSound list corruption, title DCF4, possible rendering cost, and the post-difficulty loader plateau remain separate. No behavior change is supported. AOT, controller mapping, guest fences, and rasterizer `1ea1871` are preserved.

## Storage

Fresh inventory: [r416 workspace inventory](C:\Project\sb-inventory-final-r416-20261030.csv). It measured 78,142 ordinary files at 41,662,809,860 allocated bytes and 1,397,939,813,198 logical bytes; 13 Rust/Cargo executable reparse entries add 165,381,632 allocated bytes. Combined allocation is 41,828,191,492 bytes (38.956 GiB). The warm incremental build cache remains 7,136,856,349 allocated bytes; canonical generated source is 155,890,474 bytes; r368 saves are 110,715,000 allocated / 5,422,148,542 logical bytes. Sparse saves account for the large logical-versus-allocated gap. r416 closed-evidence compression reclaimed 789,283 allocated bytes with SHA-256 hashes unchanged; no files were deleted. No build ran, preserving the warm build cache.

Detailed findings: [r414–r416 report](m3-r414-r416-loading-and-title-wait-20261030.md). Storage record: [r416 cleanup manifest](current-cleanup-manifest-r416-20261030.md).

## Next step

Use the same r409 AOT/symbol bundle and r368 save root to capture the mode-2 terminal state with bounded file-path completion/outstanding-operation data, valid loader stacks, worker status, and synchronized graphics/event state. Confirm or reject a missing post-worker loader-state handoff before changing runtime behavior. Stop at the first visually verified mission frame.
