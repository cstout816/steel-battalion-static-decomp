# Steel Battalion AOT — current status (r441, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r441 followed the new-pilot route to the visible `NOW LOADING` screen. The final guest framebuffer was white, and the run stopped after 180 seconds with no NV2A frame/counter/fence progress. No mission scene was verified.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact r426 AOT and symbol bundle retained
Boot and campaign entry         [##########----------] 50%  New-pilot route reaches loading; no mission frame
Kernel/runtime compatibility   [########------------] 40%  0x3FFF object-entry poll identified; owner unresolved
Graphics / rendering            [###-----------------] 15%  White guest frame; zero queued raster work at stop
Controller compatibility       [######--------------] 30%  Screen-gated XInput route verified; full mapping untested
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 95%  Bounded r441 trace, writer watch, and exact-bundle dump
Storage control                 [##################--] 94%  36.724 GiB allocated; warm cache preserved
Overall project                 [#####---------------] 28%  First-mission acceptance remains 0/1
```

## Current finding

- r441 (`m3-loader-3fff-writer-r441-20261030`, PID 22740; `2026-10-30T18:54:21Z`–`19:04:21Z`) used the exact r426 AOT EXE/PDB/MAP and the existing save root. Its screen-gated route reached `NOW LOADING`; the final retained 640×480 guest framebuffer is solid white.
- The write watch captured a store of `0xFFFFFFFF` to guest `0x82A9BFFC` at tick `26823843`, TID 26752, native RIP `0x7FF71FCB657A`. It maps to `sub_0020F1F0` in the exact r426 image, guest `loc_0020F250`. The caller trace at that tick ties handle `0x3FFF` to the `sub_000151D0` table-initialization loop; `sub_0020F260` publishes the empty entry with the sentinel still present.
- AOT `sub_0001D980` repeatedly calls `sub_0020EC00(0x3FFF, ...)`, retrying `0x88760828` at guest PC `0x0020EC2B` / caller `0x0001D992`. Runtime samples reached 262,144 invalid lookups; the watch saw no later valid store during the 180-second stall. This establishes the immediate polling stall. The game operation that should bind the entry, whether that handle must be valid here, and whether it is the sole campaign blocker remain unresolved. No fix or guest-state change was made.
- The last mode-2 pass was n=30, tick `26811968`, range 2..11, index 28, result 0, pair `0x000ABA00/0`. Index `0x1E` readiness was set to 1; guest objects `0x013BB000` and `0x019204A0` completed with status 1 after 89 and 80 polls. File lifecycle logged 2,499 opens / 2,090 closes and no missing path, but per-target read completion was disabled. File completion for every dependency is unverified.
- At watchdog stop: DCF4 was signaled, DMA PUT/GET held at `0x1F014`, frame/counter/target/fence held at `0x7C3 / 0x90B9 / 0x9053 / 0x90B7`, and batches/workers/pending raster work were zero. This run did not reproduce an unsignaled DCF4 wait or raster backlog.
- Exact-bundle native unwind for TID 26752 reached the guest trace helper/UCRT with zero stack-read failures, then stopped outside a module; it did not validate the guest call stack. Runtime guest PCs and the generated AOT branch are the valid call-path evidence.

## Storage and next step

Current inventory: **39,432,518,326 bytes allocated (36.724 GiB)**; **1,398,728,252,909 bytes logical (1,302.667 GiB)**. Compared with r440, workspace allocation rose 2,423,578 bytes. r441 evidence uses 2,334,966 allocated bytes; its 64 MiB cap was not reached, 13 frame captures were made, nine evicted, and no trace lines or captures were dropped. Warm incremental build tree remains 7,354,916,122 allocated bytes. The reused save root is 952,910,026 allocated bytes. No build or cache purge ran.

No allocated space was reclaimed this turn. Three previously hash-verified duplicate archives totaling 976,265,216 allocated bytes remain in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`; the exact removal command was blocked by the local policy gate. Keeper copies remain verified and intact.

Next: identify the owner and expected producer for handle `0x3FFF` by tracing the AOT caller of `sub_0001D980` and the allocation/binding path that should publish its object pointer. Preserve guest checks, fences, AOT execution, controller mapping, and rasterizer `1ea1871`. Make no behavior change until the expected binding is established; stop the gameplay milestone at the first visually verified mission frame.

Full diagnostic: [m3-r441-handle-slot-writer-and-loader-stall-20261030.md](m3-r441-handle-slot-writer-and-loader-stall-20261030.md). Prior r438–r440 context: [m3-r438-r440-invalid-device-handle-retry-and-storage-20261030.md](m3-r438-r440-invalid-device-handle-retry-and-storage-20261030.md). Current cleanup record: [current-cleanup-manifest-r441-20261030.md](current-cleanup-manifest-r441-20261030.md).
