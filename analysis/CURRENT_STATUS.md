# Steel Battalion AOT — current status (r433, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r433's exact final screenshot is black; it does not establish `NOW LOADING` or a mission. r432 separately reached visible `NOW LOADING`. No gameplay fix is supported by current traces.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact AOT/symbol bundle retained
Boot and campaign entry         [########------------] 40%  New-pilot route reaches black transition
Kernel/runtime compatibility   [######--------------] 30%  Owner snapshot timing corrected for next run
Graphics / rendering            [###-----------------] 15%  First mission framebuffer unverified
Controller compatibility       [#####---------------] 25%  Screen-gated XID/guest edge path remains traced
Audio / DSP                     [###-----------------] 15%  Campaign audio unverified
Debugging and evidence          [##################--] 94%  r432/r433 exact bundles and bounded evidence retained
Storage control                 [##################--] 94%  39.24 GiB allocated; cleanup removal blocked
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Current findings

- r433 used exact r426 EXE/PDB/MAP and reused the unchanged 29-file r368 save root. After Normal confirmation its final captured frame is black; `NOW LOADING` and a mission frame were not visually verified in this run. The prior r432 loading-screen result is separate evidence, not progress claimed for r433.
- r433 recorded 5,075 successful reads, 985 opens / 926 closes and no proven incomplete read or first missing asset. The loader changed from mode 2 to mode 1 with zero progress, then stopped advancing. Do not merge it with r432's mode-2 plateau.
- At the terminal r433 sample DCF4 was signaled and raster batches/workers/pending were zero; NV2A frame `0xDA8` stopped progressing for 600 seconds. No rendering backlog was demonstrated. Native dumps provide partial stacks only. Main TID 13072 near `deliver_one_apc`, worker TID 27064 near the duplicate-object bridge, and critical-section contention at guest lock `0x23FE18` are candidates, not a proven cause. Exception `0xE06D7363` near `_snprintf_s` in the DirectSound watch is kept distinct from the historical DirectSound list corruption.
- r433's guest-owner watchdog snapshot was scheduled at 720s while its separate NV2A watchdog stopped the run at 600s. The missing `watchdog-snapshot.log` is explained by this ordering. `[SB-SNAPSHOT]` is the controller-copy trace in guest `sub_00048890`, not the guest-owner snapshot; that routine did not run on this route. Next repeat should schedule the single owner/critical-section snapshot before the NV2A stop threshold and change no gameplay behavior absent confirming evidence.
- r150/r151/r153 were reviewed against their exact r149 bundle before new runs. They provide only partial native unwinds and no validated guest caller chain. r130's current null-output `ObReferenceObjectByHandle` completion behavior remains the implementation to verify; it is not re-diagnosed here.

## Storage

Fresh allocated inventory: **42,137,500,778 bytes (39.2436 GiB)** including 13 reparse tool entries; ordinary files total 41,972,119,146 allocated / 1,398,626,450,106 logical bytes. Net allocation change since r432 inventory: +2,606,309 bytes. The r433 folder adds 2,708,360 allocated bytes; the reused save root is unchanged at 952,898,778 allocated / 5,422,128,858 logical bytes. Warm build tree remains 7,354,916,122 allocated bytes; no build or cache purge ran. Cleanup savings this pass: 0 bytes. The earlier exact deletion attempt for three hash-verified duplicate ZIPs was blocked by policy; no alternate removal path was tried.

Full report: `analysis/m3-r433-black-transition-and-watchdog-20261030.md`. Cleanup inventory: `analysis/current-cleanup-manifest-r433-20261030.md`. Fresh path inventory: `C:\Project\sb-inventory-current-r433-20261030.csv`.

## Next discriminating test

Repeat the same known new-pilot route with r426 and the existing save root. Schedule a single guest CPU/critical-section watchdog snapshot at 480 seconds, before the 600-second NV2A progress stop. Correlate its owner/waiters and call sites with thread completion, loader state, file completions, and NV2A state. Stop on the first visually verified mission frame or retain the bounded failure window. Preserve AOT, controller mapping, guest fences, and rasterizer `1ea1871`.

**Storage note (2026-10-30):** exact-path deletion of the three duplicate ZIP candidates was rejected by automatic file-action review as blocked by policy; no candidates were removed. Do not try another deletion mechanism. Their combined 976,265,216 allocated bytes remain deferred candidates, with hashes and keepers in the r432 cleanup manifest.
