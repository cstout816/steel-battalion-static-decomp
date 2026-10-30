# Steel Battalion AOT — current status (r440, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r440 completed the known new-pilot route through difficulty confirmation and `NOW LOADING`, then remained on a white framebuffer. The immediate guest-side retry is identified; its role in the missing mission transition and the missing handle-entry producer remain unresolved.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact r426 AOT and symbol bundle retained
Boot and campaign entry         [##########----------] 50%  New-pilot route reaches loading, no mission frame
Kernel/runtime compatibility   [########------------] 40%  0x3FFF object lookup remains invalid
Graphics / rendering            [###-----------------] 15%  White stage; raster queue empty
Controller compatibility       [######--------------] 30%  Screen-gated XInput route verified; full mapping untested
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 95%  r440 bounded traces and exact-bundle dumps retained
Storage control                 [##################--] 94%  36.722 GiB allocated; warm cache preserved
Overall project                 [#####---------------] 28%  First-mission acceptance remains 0/1
```

## Current finding

- r440 (`m3-mode2-handle-lookup-r440-20261030`, PID 36768; 2026-10-30 18:39:46–18:47:09 UTC) used the r426 AOT executable, PDB and MAP with the existing save root. It visually reached the new-pilot route and `NOW LOADING`; its final framebuffer is solid white.
- The mode-2 worker for index `0x1E` set ready byte VA `0x00351F22` to 1. Guest thread objects `0x013BB000` and `0x019204A0` each reached exit status 1 (success; 72 and 87 polls respectively). The last loader pass was mode 2, range 2..11, index 28, pair `0x000ABA00/0`, result 0. No missing-path marker was emitted; file-target tracing was disabled, so this does not prove all later file dependencies completed.
- Device handle `0x3FFF` repeatedly resolves to entry `0x82A9BFF0`, whose object word remains `0xFFFFFFFF`; lookup returns `0x88760828`. The generated guest at `sub_0001D980` branches back to retry that result. Runtime reports reached 458,752 failed lookups on TID 11964, with no trace drops. This confirms the hot retry and invalid entry, but not which guest path should populate it or whether it alone blocks the mission handoff.
- Final telemetry: DCF4 remained signaled, DMA PUT/GET stayed at `0x390B4`, NV2A frame/counter did not advance, and raster batches, workers and pending work were all zero. This is not a demonstrated raster backlog or title DCF4 wait. Keep it separate from DirectSound corruption and prior loading plateaus.
- The native unwind for TID 11964 reaches the diagnostic helper/UCRT and stops at a non-module address with zero stack-read failures. A raw stack-address scan suggests `sub_00192BD8` → `sub_000467A0` → `sub_00045DF0` → `sub_0001D980`, but that is not a validated guest unwind.

## Storage and next step

Fresh scan: **39,430,094,748 bytes allocated (36.722 GiB)** and **1,398,720,013,505 bytes logical (1,302.660 GiB)** across 78,608 ordinary files; 13 reparse entries were skipped. The r438 post-compression scan was 39,425,703,848 allocated, so current allocation is +4,390,900 bytes. r440 retains 3,453,174 allocated bytes of evidence. Lossless NTFS compression reclaimed 6,958 allocated bytes with all closed text/log/JSON hashes unchanged. Warm incremental build tree remains 7,354,916,122 allocated bytes; the save root remains 952,907,214 allocated bytes. No source or build changed.

Next: trace the first write (or missing write) to the `0x3FFF` entry object word after `sub_0020F260` creates/publishes it. Correlate writer guest PC, caller, thread status, loader progress and screenshot; make no guest-state or synchronization change until that producer path is established. Preserve AOT, controller mapping, guest fences, and rasterizer `1ea1871`. Stop at the first visually verified mission frame.

Full findings: [m3-r438-r440-invalid-device-handle-retry-and-storage-20261030.md](m3-r438-r440-invalid-device-handle-retry-and-storage-20261030.md). Cleanup inventory: [current-cleanup-manifest-r440-20261030.md](current-cleanup-manifest-r440-20261030.md).
