# Steel Battalion AOT — current status (r419, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r419 verified one XID-to-guest input edge and then crashed during a DirectSound voice-list walk. This is distinct from r418's title-stage DCF4 wait and r415's later mode-2 loader plateau. No runtime fix or mission progression has been verified.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution and exact-bundle diagnosis retained
Boot and campaign entry         [########------------] 40%  New-pilot route reaches mode 2; loader plateaus
Kernel/runtime compatibility   [######--------------] 30%  Post-worker loader handoff unresolved
Graphics / rendering            [###-----------------] 15%  White/title frames only; mission render unverified
Controller compatibility       [#####---------------] 25%  Screen-gated input route retained
Audio / DSP                     [###-----------------] 15%  Mission audio unverified; separate DS list issue
Debugging and evidence          [#################---] 86%  r150–r153 and r271–r418 bundles/traces retained
Storage control                 [##################--] 91%  Closed r417–r419 evidence compressed and hash-verified
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Current diagnosis

- r419's exact AOT trace recorded XID report byte 2, the same byte copied through guest DMA, edge consumption into `0x004AFC08`, and a true input predicate. A subsequent `MENU-RESOURCE` row referenced string VA `0x0026AF04` (“LIST AS NEW”), but r419 recorded no pilot-list callback, guest snapshot, or input-dispatch row. The visible initial title and player-record warning are retained; the final captured frame is black.
- r419's terminal failure is the DirectSound list path: the traced predecessor `0x8038C098` had a null next/prev/owner, then the list traversal reached node 0 and the guest helper faulted reading `0xFFFFFFF4` in `sub_0021ED29+0x88`. This proves the proximate bad-list walk, not who introduced the null link. Guest stack values are raw stack candidates, and native stack values are not a validated unwind; r419 captured no minidump. No code fix is justified yet.
- r419 recorded one requested mode-0 worker and a mode-0 branch at `sub_00017E40`; it did not reach mode 2 or loader passes. This does not test the mode-2 race that remains relevant to r415.
- r414 full-read tracing and r415 sampled tracing reached the same mode-2 plateau. r415 rejects full-read trace volume alone as the cause. Its mode-2 worker completed, resource `0x1E` became ready, sampled reads succeeded, and the output pair stopped at `0x000ABA00/0`. The first stalled loader dependency and expected consumer remain unidentified.
- r418 again stopped at title-stage DCF4 before pilot-list dispatch. Main TID 190944 unwound to `xbox_KeWaitForSingleObject+0x29`; explicit guest wait records identify event `0x0021DCF4` at caller hint `0x00211F3B`. The last signaling callback was #1467 (index 5 / target `0x0021701E`, `KeSetEvent` caller `0x0021702F`); after reset/wait #512, callbacks #1468 and #1469 selected index 1 / target `0x00216EC9`. No next index-5 callback or wait return was recorded. r271/r274 already document the same missing post-reset signaling handoff, so r418 corroborates it without establishing why guest state stops selecting the signaling branch.
- r418's last raster snapshot had one batch, four workers and three pending, but it was a transient wait-time sample. Earlier r271 terminal telemetry had an idle raster pool and equal DMA PUT/GET; the evidence does not establish raster backlog as the DCF4 cause. DCE4/timer activity continued separately. Keep this title wait distinct from r415's post-difficulty mode-2 plateau and the DirectSound list failure.
- The r130 ObReferenceObjectByHandle null-output issue is not the current mode-2 blocker. Current XboxRecomp source resolves the thread handle to a guest object and copies the completed host exit status into object `+0x120`; r415 recorded a valid object, callback success, and completed status 1 before the loader plateau. The generated helper compares that status with `STATUS_PENDING` (`0x103`) and proceeds. The separate ignored game-project bridge copy is stale and is not the linked runtime implementation.
- r418 did not trace a full XID-to-guest input edge: it logged XID delivery for two A presses, but `-LoadingFocus` disabled guest input/predicate/snapshot/menu traces. The first press displayed “Unable to load Player Record”; the second was followed by a black framebuffer. Do not claim a new-pilot transition or pilot callback from this run.
- r415’s terminal DCF4 sample cannot be paired with the last wait using row sequence numbers; it does not prove a DCF4 stall there.
- DirectSound list corruption, title DCF4, possible rendering cost, and the post-difficulty loader plateau remain separate. No behavior change is supported. AOT, controller mapping, guest fences, and rasterizer `1ea1871` are preserved.

## Storage

The r416 post-push full inventory measured 41,828,207,960 allocated bytes and 1,397,939,829,666 logical bytes, including the 13 separately measured reparse entries. The current derived total is **41,832,000,396 allocated bytes (38.959086 GiB)** and **1,397,953,753,094 logical bytes**, across 78,199 ordinary files plus 13 reparse entries. r419 added 977,238 allocated / 3,540,011 logical bytes in closed evidence; lossless compression reclaimed 5,845 allocated bytes with every file hash unchanged. Cumulative r416–r419 compression reclaimed 1,628,069 allocated bytes. This remains a path-summed update from the full baseline, not a new full-tree scan. The warm incremental build cache remains 7,136,856,349 allocated bytes; canonical generated source is 155,890,474 bytes; r368 saves remain 110,715,000 allocated / 5,422,148,542 logical bytes. Sparse saves account for the large logical-versus-allocated gap. No file was deleted or moved; no build ran, preserving the warm cache.

Detailed findings: [r419 input and DirectSound crash](m3-r419-input-and-dsound-crash-20261030.md), [r417–r418 title wait](m3-r417-r418-title-wait-and-storage-20261030.md), [r414–r416 loader and title wait](m3-r414-r416-loading-and-title-wait-20261030.md), [r271 title wait](m3-r271-title-dcf4-outer-20261029.md), and [r274 native unwinds](r274-valid-native-unwinds-20261029.txt). Storage record: [r419 cleanup manifest](current-cleanup-manifest-r419-20261030.md).

## Next step

Use the exact r409 AOT/symbol bundle and existing r368 save root. Investigate the r419 DirectSound list corruption with a bounded trace of the exact operation that first leaves the list predecessor's next link null. Capture an exact crash-time minidump and validate native unwind if needed; distinguish real unwind frames from raw guest/native stack scans. Do not add a sentinel bypass or repair until the corrupting operation is identified. On a route that reaches the later mode-2 path, compare the requested mode with the actual worker-entry branch and correlate bounded file completion, loader progress, object status, valid stacks, and synchronized graphics/event state. Preserve AOT, controller mapping, guest fences and rasterizer `1ea1871`. Stop at the first visually verified mission frame.
