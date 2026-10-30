# Steel Battalion AOT — current status (r410, 2026-10-30)

**Milestone:** 3 — boot and compatibility. **First mission frame verified: 0/1.** The latest new-pilot run reached mode-2 loading after Normal, then held a white frame; it did not show a mission or visually confirm the `NOW LOADING` label.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT path retained
Boot and campaign entry         [########------------] 40%  New-pilot route reaches mode-2 loader
Kernel/runtime compatibility   [######--------------] 30%  Later loader handoff unresolved
Graphics / rendering            [###-----------------] 15%  Mission rendering and 60 FPS unverified
Controller compatibility       [#####---------------] 25%  Screen-gated XID route traced
Audio / DSP                     [###-----------------] 15%  Mission audio unverified
Debugging and evidence          [################----] 80%  r410 exact dump/bundle retained
Storage control                 [################----] 80%  11,934,458 bytes recovered this pass
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Current diagnosis

- r410 rejected the hypothesis that mode-2 resource `0x1E` remains unready. Its ready byte at `0x00351F22` changed `0 -> 1`; the helper decision changed `5 -> 6`; mode-2 pair advanced to `0x000ABA00/0`; and both relevant worker objects completed with status 1.
- The next loader state producer/consumer remains unidentified. After the readiness handoff, callbacks returned expected zero for imported lock routines while mode, phase, progress, status, and gate fields did not advance. Sampled file reads were successful; the trace does not prove complete file consumption.
- The exact r409-matched r410 dump's native unwind does not give a valid guest call chain. Resolved host frames are normal runtime workers, including sleeping raster workers. DCF4 waits returned signaled in r410; there was no persistent DCF4 hang. Keep title DCF4, DirectSound list corruption, renderer cost, and post-difficulty loading distinct.
- No runtime behavior changed. AOT, controller mapping, guest fences, and rasterizer `1ea1871` remain intact. r405's 4 MiB allocation failure did not recur. The current ObReferenceObjectByHandle completion implementation was not altered.

## Storage

Fresh scan: **41,814,717,222 allocated bytes (38.94 GiB)** combined; **1,397,880,810,882 ordinary-file logical bytes** plus reparse executable logical lengths reported as zero. Hash-verified lossless compression reclaimed **11,934,458 allocated bytes** across the current r410 evidence and 13 older closed diagnostic files. Warm `build-xpp-seeded` is **7,136,856,349 allocated bytes**; canonical generated source is **155,890,474**; r368 saves are **110,709,376 allocated / 5,422,142,918 logical bytes**. No cache or save data was deleted.

Three duplicate tool archives were rehashed against retained copies (976,265,216 allocated bytes in the old copy set), but file-action review rejected their removal before execution. No alternate deletion route was attempted. See the [r410 cleanup manifest](current-cleanup-manifest-r410-20261030.md).

## Next step

Add only bounded producer/consumer evidence after the `0x1E` ready handoff. Identify the exact mode-2 state input, its producer thread, and completion status before changing runtime behavior. Keep AOT and fences intact; stop at the first visually verified mission frame.

Detailed evidence: [r408–r410 report](m3-r408-r410-mode2-readiness-and-storage-20261030.md). Exact build and diagnostic source: [r410 preservation manifest](r410-source-preservation-manifest.md).
