# r88 pilot-list and loading trace — 2026-10-27

## Run identity and stop

- Run `m3-pilot-loading-r88-dcf4-producer-20261027`, diagnostic PID `124692`.
- Started 08:53:47 CDT and stopped at the user's request at about 09:15:28 CDT. Only PID 124692 was terminated. The supervisor finalized with exit code `-1`, no watchdog termination, zero dropped stdout/stderr lines, and a stopped writer.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r83-xbe-section-trace-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `14F962A5BC54AE7A21E671DA53FD4DC60680030AC731A451513F39A0E6FD24CB`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; existing save root reused without copying or editing: `iso/local-analysis/saves-m3-known-save-copy-20261023`.
- No source, executable, controller mapping, guest fence, rasterizer, or gameplay behavior was changed. AOT execution and rasterizer `1ea1871` were preserved.

## Trace configuration, limits, and emitted records

The run manifest hashes the executable, PDB, generated sources, and runtime source files. `environment.txt` confirms XID/input, pilot-list/menu, file read/lifecycle/failure/I/O detail, load-pass/state callback, thread-start/preload-worker, XBE section, DCF4 callback/producer, NV2A, and raster traces were enabled. `RECOMP_SB_DCF4_PRODUCER_TRACE=1`; high-volume `RECOMP_SYNC_TRACE`, `RECOMP_PB_SEMAPHORE_TRACE`, and scripted pad input were unset. The async relay queue capacity was 32,768 lines; zero lines were dropped. The runtime watchdog was 1,800 seconds; this run ended earlier by user request.

The final marker counts include 35 XID and 35 XID-DMA rows, 29 input predicates, 18 edge-consume rows, 368 pilot-list callbacks, one pilot-row post, 419 load-pass inputs and outputs, 1,676 load-state callbacks, 22,972 lifecycle opens, 22,919 closes, 5,205 file-I/O rows, 25 failed paths, 15,129 DCF4 callbacks, 300,000 DMA-publish marker rows, 433 NV2A ticks, and 621 raster windows. No trace cap was reported as reached. The dedicated `[SB-SNAPSHOT]`, `[SB-INPUT-DISPATCH]`, `[MENU-DISPATCH]`, `[FILE-CALL]`, `[FILE-PRELOAD]`, `[FILE-COPY]`, `[SB-PFB-POLL]`, and `[SYNC-PBSEM]` records were absent; their absence does not show those stages executed.

## Screen-gated pilot route

Captured route: title → campaign → pilot list showing `LIST AS NEW` → name `A` → date `01/01/2002` → `YES` → Normal difficulty → visible `NOW LOADING`.

The active pilot-list callback is correlated with the visible row and input. XID/DMA, guest edge/predicate, and menu-resource traces emitted; `[MENU-RESOURCE]` identifies text VA `0x0026AF04`; `[PILOT-LIST-CB]` emitted 368 records and `[PILOT-ROW-POST]` one. Handler `0x000E18D8` selected branch `0x000E193B`; row object `0x002E4C34`, field `+0x28`, changed from `0x3F800000` to zero at `0x000E19CF`. This confirms the runtime callback for the displayed `LIST AS NEW` item. It does not support treating `sub_000E0870` as the handler.

## Loading evidence and cause status

The final captured framebuffer still shows `NOW LOADING`; there is no verified first-mission frame. The mode-2 scan at `0x000C3020` reached pass 419 and returned through `0x000C32D6` (`range=2..11`, `last_index=28`, `result=0`). The tracked state pair remained `0x011E2E00/0`; mode/phase stayed `0/0` and gates `1/1/0`. The zero is the observed scan return, not proof of an error. XBE section `seg00` had loaded successfully at `0x0001134C`.

There are 5,515 completed `[READ]` records; the last is tick `358234796`, token `0x48000069`, cached `Z:\\bgm02.wav`, 18,432 bytes, successful native/IOSB and guest status. No read completion follows while the repeated loading scan continues. The 25 failed paths are empty-slot TDATA save probes on the authorized new-pilot route. Paired cache/media asset opens and file queries observed in the trace succeed. No pending host read or failed mission asset is demonstrated; a missing loader job/state transition remains possible but unidentified.

Two snapshots capture TID `123112` with stack-scan matches through `xbox_KeWaitForSingleObject` → `bridge_KeWaitForSingleObject` → guest `sub_00211E10+0xDD2` → `sub_0019196F` → `sub_0020E520` → `sub_00101A60+0x17B4`. These are not complete native unwinds. Sampled DCE4 waits return status 0 with `guest_signal=1`; DCF4 callbacks and NV2A frame/counter/target/fence values progress. The captured stack therefore does not establish a persistent unsignaled DCF4 wait.

Across 335 post-load DCF4 queue samples, occupancy ranges 0–15, averages 7.74/15, and reaches capacity in 24 samples; it returns to lower values, with no sustained monotonic backlog shown. Raster windows commonly process 27 batches / 56 triangles in about 2.0–2.2 seconds wall time and 7.8–8.7 seconds summed worker-active time across four workers. This supports severe CPU raster cost, but not a causal link to the loader. DMA-publish marker volume reached 300,000; it does not provide complete direct PUT/GET correlation for every loading interval. High-volume semaphore tracing was disabled. No rendering, synchronization, file, or guest behavior fix is supported by these traces.

## Conclusion and next step

Verified: AOT launch, screen-gated new-pilot flow, active `LIST AS NEW` callback and row-state mutation, entry into `NOW LOADING`, successful observed file completions, advancing DCF4/NV2A telemetry, and severe raster cost. Unverified: first mission frame, first blocked loader dependency, audible audio, campaign progression, and whether raster work delays mission loading. The diagnostic stopped at the user's request; the first mission target remains open.

Next, prepare a bounded trace correlating the loader state-pair producer and work-item/event completion with per-thread waits. Keep the same route and AOT execution, sample DMA detail at synchronized intervals, preserve guest fences/controller behavior/rasterizer `1ea1871`, and stop automatically at the diagnostic timeout or after the first verified mission frame. Do not alter behavior until one cause is supported by traces.
