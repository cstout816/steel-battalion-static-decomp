# Steel Battalion AOT — current status (r431, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r427 is the latest run to show `NOW LOADING`; it plateaued in the mode-2 scan. r430/r431 stopped in separate title transitions. No supported runtime fix yet.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact-bundle diagnosis retained
Boot and campaign entry         [########------------] 40%  Loading screen reached; mission not shown
Kernel/runtime compatibility   [######--------------] 30%  Loader handoff/owner still unknown
Graphics / rendering            [###-----------------] 15%  First mission framebuffer unverified
Controller compatibility       [#####---------------] 25%  Screen-gated XID/guest edge traced
Audio / DSP                     [###-----------------] 15%  Campaign audio unverified
Debugging and evidence          [##################--] 92%  r150–r153 reviewed; r427–r431 retained
Storage control                 [##################--] 94%  Fresh allocation scan; bounded run evidence
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Latest verified findings

- r427 visibly reached `NOW LOADING` through the new-pilot route. Mode-2 load-pass calls 6–15 returned 0; the last scan range was 2–11 with `last_index=28`. Terminal NV2A frame/counter/fence stopped at `0x117A/0x17591/0x1758F`; DCF4 was signaled and raster workers were idle. The first incomplete file or expected producer is not identified: r427 lacked file-lifecycle tracing, and sampled successful reads do not prove all requests completed.
- r427 TID 17312 reached native `xbox_DispatchGateEnter+0xE1`; TID 1736 reached `guest_cpu_acquire+0x6E`. Those StackWalks stopped at error 487. Raw guest address scans are not validated guest unwinds; ownership/lock cycle remains unproven.
- r430/r431 are title-stage cases, not loader runs. r431 logged one title route advance to `0x002B29B0`, then a black presentation; terminal frame/DMA/raster were stationary/idle. Last retained DCF4 wait at index 64 returned signaled; later wait rows were skipped by the 64-record trace policy, so no persistent terminal DCF4 wait is established.
- Current `ObReferenceObjectByHandle` resolves thread completion even when guest output pointer is null. r430/r431 did not reach loader completion; runtime semantics at that stage remain unverified.
- The identified pilot-list callback remains `sub_000E1820` at `0x000E18D8`; it did not execute in r430/r431. Do not reopen `sub_000E0870` as a candidate.
- Keep the post-difficulty loader plateau, title wait/transition, DirectSound corruption, and rendering cost separate. No behavior change, build, or regression run occurred. AOT, controller mapping, guest fences, and rasterizer `1ea1871` remain untouched.

## Storage

Latest full scan is recorded in `analysis/current-cleanup-manifest-r431-20261030.md` and compressed inventory `C:\Project\sb-inventory-current-r431-final-20261030.csv.gz`. Workspace footprint is about 39.2 GiB allocated; logical file length is about 1.27 TiB due sparse files. r430/r431 closed text compression reclaimed 816,717 allocated bytes after per-file hash/length verification. Their dumps, screenshots, and exact r426 symbols remain. The warm build cache was not purged and no build ran. Three verified duplicate ZIPs remain quarantined because the prior deletion attempt was rejected by automatic file-action review.

Detailed report: `analysis/m3-r427-r431-loader-and-storage-20261030.md`. Compression audit: `analysis/r430-r431-closed-evidence-compression-20261030.csv`.

## Next discriminating test

Repeat the r427 route/save root with file lifecycle and read-completion correlation, thread-object state, guest-CPU owner/wait snapshots, mode-2 helper records, and a non-stopping plateau dump. Identify one incomplete operation and its expected producer before changing behavior. Stop only at the first visually verified mission frame or preserve the exact plateau evidence.
