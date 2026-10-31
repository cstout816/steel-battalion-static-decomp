# Steel Battalion AOT — current status (r480, 2026-10-30)

**Current milestone:** 3 — boot and compatibility. **First mission frame: 0/1, not verified.** AOT execution remains in place; no gameplay fix, generated-code change, or build was made this pass.

Read [r476–r480 findings and storage report](m3-r476-r480-title-dcf4-dsound-followup-20261030.md), [current cleanup manifest](current-cleanup-manifest-r480-20261030.md), and the [project review handoff](project-review-and-luna-high-handoff-20261027.md) before repeating a diagnostic. Latest result: r479 visibly reached Campaign then crashed while consuming a malformed DirectSound list; r480 captured only normal list initialization writes and a separate title-stage DCF4 wait. Neither established the corrupting writer or reached `NOW LOADING`.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT path retained; no ordinary emulation substitution
Boot and campaign entry         [##############------] 70%  Visible Campaign reached in r479; then DirectSound AV
Kernel/runtime compatibility   [########------------] 40%  Title DCF4 wait sampled; producer and r130 semantics unresolved
Graphics / rendering           [###-----------------] 15%  No mission frame; r480 had drained DMA and no PGRAPH pending
Controller compatibility       [##########----------] 50%  XID delivery and screen-gated title edge retained in r479/r480
Audio / DSP                     [###-----------------] 15%  DirectSound list failure at r479; audio playback unverified
Debugging and evidence          [###################-] 98%  Exact r461 symbols, r480 native dump, bounded run traces retained
Storage control                 [##################--] 95%  37.088 GiB allocated; 1,303.547 GiB logical; 0 bytes reclaimed
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Current blocker and next action

The most actionable blocker is the r479 DirectSound malformed-list consumption (`node=0xFF000000`, predecessor `0x8038C098`); its writer remains unknown. r480 watched the relevant three words but ended in an earlier DCF4 wait, after only nine valid initialization writes. Reproduce the r479 route with those watches still active, retain a crash dump, and identify the first invalid write before changing list behavior. Keep this separate from title DCF4, the post-difficulty loader plateau, and expensive raster work.

Review r150/r151/r153 dumps only with their exact matching binaries and symbols; distinguish valid unwinds from raw stack scans. Verify r130 `ObReferenceObjectByHandle` completion semantics. Investigate loader dependencies after a visible `NOW LOADING` state. Stop acceptance at the first visually verified mission frame.

## Storage / build status

Fresh scan: 79,479 files; 39,822,753,979 allocated bytes (37.088 GiB); 1,399,672,470,449 logical bytes (1,303.547 GiB); 13 reparse entries skipped. r476–r480 account for 5,207,555 allocated bytes (11,312,573 logical). No files were removed or compressed, so reclaimed space is 0; warm incremental build cache and build efficiency are unchanged. See the cleanup manifest for exact per-run paths and allocations.