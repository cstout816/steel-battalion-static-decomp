# Steel Battalion AOT project — current status

**Current milestone:** Milestone 3, boot and compatibility. **First visually verified mission frame: 0/1.**

## Progress bars

```text
Decompilation / AOT execution   [##########----------] 50%  AOT route reaches NOW LOADING; no mission frame
Boot and campaign entry         [#######-------------] 35%  New-pilot route and Normal selection verified
Runtime compatibility          [######--------------] 30%  Kernel, input, audio, and graphics remain incomplete
Rendering and performance       [###-----------------] 15%  Loading transition measured; 60 FPS unverified
Controller compatibility       [#####---------------] 25%  XID input path verified; full controller unverified
Launcher and installation      [##------------------] 10%  Not the current milestone
Debugging and evidence          [#############-------] 65%  Bounded traces and matching r367 stack bundles retained
Storage control                 [##############------] 70%  5,021,696 bytes reclaimed in r394/r395 evidence cleanup
Overall project                 [#####---------------] 25%  Early compatibility work; campaign is not playable yet
```

Bars are rough engineering estimates. The current milestone acceptance check is one visually verified first mission frame.

## Current findings

- r396 (`m3-3fff-screen-gated-writer-r396-20261030`, PID 19912) used the exact r367 AOT EXE/PDB/MAP and the r368 save root. The route reached the new-pilot editor, default date, YES, `HAI SHI DAO 2080 [NORMAL]`, and a guest framebuffer showing `NOW LOADING`. The host window later showed black at 0.0 FPS; no first mission frame appeared.
- Screen-gated input from XID DMA at guest buffer `0x01081763` through the edge predicate at `0x000C8064`, pilot callback `0x000E18D8`, selected branch `0x000E193B`, and row action `0x000E19CF` is correlated in r396. `LIST AS NEW` was selected as owner 8; the action changed item `+0x28` from `0x3F800000` to zero.
- Loading mode 2 stopped at progress pair `0x000ABA00/0`. Sampled reads through read count 11,000 completed with matching byte counts and zero status. File lifecycle and per-handle read traces were disabled, so the first stalled file dependency is still unknown.
- The same loading run ended with thread 187972 waiting on guest event `0x0021DCF4`; the 180-second DCF4 watchdog stopped only PID 19912 after no wait return. The final synchronized trace had no DCF4 signal, no new raster batches, and static DMA PUT/GET. DCF4 is a separate observed wait; it is not yet proven to be the loader readiness cause.
- Matching-bundle StackWalk64 reached host `xbox_KeWaitForSingleObject` and stopped at synthetic address `0xF34`. Guest addresses found by raw stack scanning are candidates only, not validated unwinds. No missing guest import was seeded; no behavior fix was made.
- The r396 guest-write watch on `0x82A9BFFC` used host address `0x82AABFFC`, read zero when attached, and logged no write hit. This does not validate the prior `0xFFFFFFFF` table-entry candidate or its expected writer.
- r130 `ObReferenceObjectByHandle` and worker completion propagation remain current; do not repeat the old null-output diagnosis. Keep title DCF4, DirectSound-list corruption, rendering cost, and loading readiness distinct.
- r396 reused the writable r368 save root without cloning or hard-linking it. `UserData` remained empty; TitleData save files were retained. Partition-image timestamps changed at process start and `Cache\\COPYCHECK.DAT` changed during the run, so their contents are not claimed unchanged.
- No game build, runtime fix, controller-map change, guest-fence change, or rasterizer change was made. A tiny local trace-helper executable was built from `tools/GuestWriteBreakpoint.c`; the warm game build cache remains unchanged.

## Storage and next action

The final path-summed inventory after r396 and current status/report files is **41,534,686,538 allocated bytes (38.68 GiB)** and **1,397,141,523,641 logical bytes**, including the 13 separately measured executable reparse entries. The inventory counted 77,689 ordinary files; sparse logical lengths are not disk usage. The warm build cache remains 6,918,921,034 allocated bytes; the last incremental build measurement is about 9.1 seconds, and no game rebuild ran. No build ran in r396.

Verified r394/r395 closed-evidence cleanup reclaimed **5,021,696 allocated bytes**. The r396 audit found 22 historical cache files that match retained extracted media exactly (178,721,934 logical / 143,407,758 allocated bytes), but the automatic execution review rejected the removal command; none were removed. The r396 run retains four bounded, lossless screenshots and two small dumps; its 64 MiB budget was not triggered, no relay drops occurred, and no trace caps were hit. See [r394–r396 report](m3-r394-r396-loading-storage-followup-20261030.md), [r396 cache audit](r396-redundant-cache-audit-20261030.csv), and [r396 cleanup manifest](current-cleanup-manifest-r396-20261030.md).

**Next:** use the exact r367 bundle and existing save root for one focused follow-up with bounded per-handle file completion, loader state producer/consumer, and wait-state evidence. Keep the DCF4 event distinct from the mode-2 readiness pair. Do not seed, bypass, force, or patch a guest state without a source-and-runtime correlation. Stop at the first visually verified mission frame. Campaign completion and 60 FPS remain unverified.
