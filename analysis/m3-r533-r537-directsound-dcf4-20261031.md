# r533–r537 DirectSound crash and title DCF4 follow-up — 2026-10-31

## Result

Milestone 3 remains active; the first visually verified mission frame remains **0/1**. These five capped readings used the same r513 AOT executable and existing save root in place. No source behavior, generated game code, build cache, controller mapping, guest fence, or rasterizer was changed. The title screenshot remained the only retained frame in every run. Call of Duty PID 52452 was open and untouched in r533–r535; it was not running for r536–r537 and did not gate those readings.

The traces separate two observed failures:

1. **r533 reproduced the DirectSound null-node access violation after reaching the pilot-list callback.** Its source-correlated fault is consistent with the renderer/list corruption previously established in r340, but r533 did not capture the active color-surface state at the store. No fix is justified before matching that state.
2. **r534–r537 stopped earlier at a title-stage DCF4 wait.** Their exact-symbol unwinds reach the host wait bridge and stop at the event handle. In later heartbeats, raster work drained and DMA PUT equaled GET while DCF4 remained unsignaled. These runs did not reach the DirectSound failure point or loader stage.

## Exact bundle and route

- Runs: `m3-r533-semaphore-notify-screen-gated-20261031` (PID 57796), `m3-r534-dsound-list-writer-screen-gated-20261031` (PID 63408), `m3-r535-dsound-list-writer-gpu-ack-screen-gated-20261031` (PID 62972), `m3-r536-inprocess-fault-context-screen-gated-20261031` (PID 36272), and `m3-r537-surface-overlap-screen-gated-20261031` (PID 58864).
- All used r513 AOT EXE SHA-256 `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`, PDB `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`, and MAP `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- All used `saves-m3-route-file-read-copy-20261023` in place. No save copies or hard links were created. The title-prompt detector started the retained 40-step r519 input schedule. r533's replay ran 251.6 seconds and reached the callback described below; r534–r537 each stopped after about 142 seconds when a 120-second DCF4 wait watchdog fired.
- Each run stayed within the 64 MiB diagnostic budget, had zero stdout/stderr relay drops, and retained one frame-history image. Visual inspection shows the title screen prompt, not a pilot list, loading screen, or mission frame.

## r533: immediate DirectSound fault and completed graphics acknowledgements

At guest tick `118566421`, the screen-gated A edge reached pilot-list callback `0x000E18D8`, selected its input branch at `0x000E193B`, and produced `[PILOT-ROW-POST] action=83`. This is callback evidence only; the saved framebuffer remained the title prompt, so no visible pilot-list transition is claimed.

The DirectSound commit trace then found list argument `0x010810A4`, sentinel `0x010810B4`, and an invalid walk. Its predecessor `0x8038C098` had `next=prev=owner=0xFF000000`; subsequent current-node records were `0xFF000000` and `0`. The crash handler recorded guest `ESI=0xFFFFFFEC`, `EBX=0`, `EDI=0x010810A4`, and a read fault at guest VA `0xFFFFFFF4` (host fault address `0x10000FFF4`).

The matching generated code explains this immediate fault: `sub_0021FE7C` advances the per-object list and computes `EBX - 0x14` before calling `sub_0021ED29`; when the list cursor is zero, the callee's `[ESI+8]` access is exactly `0xFFFFFFF4`. The logged guest return-address chain includes `0x0021FECA` (the call to `sub_0021ED29`), `0x00220FAF` (the call from `sub_00220F9A`), and the downstream audio path. This is explicit guest stack data plus source correlation, **not** a validated host unwind. r533's external post-exception thread snapshot contains no exception-context stream and cannot identify the faulting native thread.

This matches the separate r340 writer finding: TID `177408` stored pixel value `0xFF000000` into all three fields of guest node `0x8038C098`, and the exact r336 image resolved the host RIP to `put_pixel+0x4AC`. r340's active NV2A color-surface state was not synchronized with that store. Therefore r340 establishes a pixel-store writer and r533 independently reproduces the invalid-list consumer, but the surface-to-guest-address relationship at the corrupting store remains unverified. The crash handler's device-level head at `0x01081014` is distinct from r533's per-object sentinel at `0x010810B4`.

The r533 graphics trace recorded 4,100 PGRAPH notifications, 281 DMA acknowledgements, and 294 pushbuffer semaphore releases. Representative records show notification pending bits cleared, DMA GET advanced to PUT, and semaphore value `0x0ADD` written at guest `0x80003000`. Its final heartbeat had DCF4 signaled, raster pending zero, and DMA PUT=GET=`0xB40C`. Thus a missing graphics acknowledgement or an outstanding DCF4 wait did not explain this run's DirectSound access violation.

## r534–r537: earlier title-stage DCF4 waits

All four runs stopped at the title route before pilot-list callbacks. Their valid same-host `StackWalk64` unwinds for the sampled waiter are in [selected native unwinds](r533-r537-selected-native-unwinds-20261031.txt):

- r534: TID `63676`, EXE `+0x64AC299` (`xbox_KeWaitForSingleObject`), then host event handle `0xF54`, zero stack-read failures.
- r535: TID `54552`, same wait bridge, then host event handle `0x1038`, zero read failures.
- r536: TID `51940`, same wait bridge, then host event handle `0xFA4`, zero read failures.
- r537: TID `60560`, same wait bridge, then host event handle `0xE7C`, zero read failures.

At each stop, DCF4 `0x0021DCF4` was unsignaled. r534's wait-before snapshot initially showed three pending batches; later heartbeats had no active/pending raster work and DMA PUT=GET=`0x53F4`. r535 stopped with pending zero, `waiting=0x07`, and PUT=GET=`0x4368`; it still recorded 634 PGRAPH notifications, 144 DMA acknowledgements, and 95 semaphore releases. r536 later showed all workers complete, no active/pending batches, and PUT=GET=`0x4564`. r537 initially showed three pending batches and later drained to zero; PUT=GET=`0x5E84`, with 676 PGRAPH notifications, 122 DMA acknowledgements, and 64 semaphore releases. These synchronized records distinguish the final wait from a continuing raster backlog; they do not identify which guest producer should signal DCF4.

r534 and r535 enabled the hardware DirectSound write watch. They saw 12 writes to the three watched fields, all matching valid initialization/link insertion, and no later `[DS-LINK-WRITE]`; they armed 48 and 50 threads respectively. Since both stopped before the later invalid walk, these are inconclusive about the corrupting store. r536/r537 did not use that watcher. r537 enabled the already-compiled `[DS-SURFACE-PIXEL]` overlap probe, but emitted no overlap row because it never reached the observed campaign/pilot failure point. Its zero rows are not evidence against r340.

`EnableInProcessCrashDump` was configured for r536/r537, but those runs ended on DCF4 watchdogs rather than an access violation. r533's older external snapshot is therefore still not a fault-time native context.

## Storage and build impact

Logical and allocated sizes were measured separately. After lossless in-place NTFS compression, every retained file's SHA-256 matched its pre-compression value.

| Runs | Files | Logical bytes | Allocated before | Allocated after | Reclaimed |
| --- | ---: | ---: | ---: | ---: | ---: |
| r533 | 15 | 8,095,094 | 4,285,321 | 2,780,783 | 1,504,538 |
| r534 | 16 | 4,088,325 | 2,675,489 | 1,170,882 | 1,504,607 |
| r535 | 16 | 4,504,196 | 3,015,707 | 1,269,208 | 1,746,499 |
| r536 | 15 | 4,265,884 | 2,736,581 | 1,224,145 | 1,512,436 |
| r537 | 15 | 4,196,201 | 2,699,180 | 1,203,650 | 1,495,530 |
| **Total** | **77** | **25,149,700** | **15,412,278** | **7,648,668** | **7,763,610** |

Including the previously measured r528–r532 evidence recovery, recent closed-run recovery is **11,018,981 allocated bytes**; r528–r537 now retain **13,098,998 allocated bytes**. This is a run-evidence slice, not a fresh whole-workspace total. No files were deleted, no saves or caches were copied or removed, and no build ran; incremental-build efficiency is unchanged. Per-file hashes and allocated-byte measurements are in [the compression audit](r533-r537-evidence-compression-20261031.csv).

## Next step

Compare r533's accepted input/callback and last DCF4 producer transition against r536's single accepted title edge and DCF4 wait. Reproduce a route that reaches the same list-consuming stage, then use the existing surface-overlap probe to capture the target at the `0x8038C098` pixel store. Do not patch renderer or DirectSound behavior from the current data. Preserve AOT, original guest checks and fences, controller mapping, and rasterizer `1ea1871`; stop at the first visually verified mission frame.
