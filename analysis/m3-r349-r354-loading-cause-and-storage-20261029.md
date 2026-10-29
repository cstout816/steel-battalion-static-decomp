# r349–r354 loading-stage and storage review — 2026-10-29

## Scope and safeguards

I read `analysis/project-review-and-luna-high-handoff-20261027.md` first and checked the repository for newer completed reports before beginning; r348 was the newest report at that point. The r349–r354 runs are now the current evidence. Before investigating r354, the process list contained no Steel Battalion/XboxRecomp diagnostic process. r354's process (PID 176300) had already been stopped after its own external dump was captured. No unrelated game process was stopped.

All six runs used the same r342 diagnostic bundle and the same generated-source directory and new-pilot save root. The bundle was verified from `run-manifest.json`:

| File | SHA-256 |
|---|---|
| `your_game_recomp_producer_trace.exe` | `727864FBDF2F3623D8BCEF7C9D8EB310E8F28CD4BC75BE340F875FDFCACED998` |
| `your_game_recomp_producer_trace.pdb` | `464EFC33C802737BCBA0C196798CA385B687789C8E421EFBD2E33FD098A20C8F` |
| `your_game_recomp_producer_trace.map` | `865A1CF63C77553A73404FE00E6CD35AA6E347119314E5C805101C5201BD7912` |

The corresponding bundle remains at `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-dsound-surface-target-r342-20261029/Release/`. Generated AOT source is `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; the run save root is `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. These paths and hashes are in each run manifest. No binary, generated game source, ISO, or save-image content was changed. NTFS compression changed only the on-disk representation of closed, inactive save images whose original hashes were already recorded. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` were preserved.

## Run outcomes

| Run | Route and result | Diagnostic value |
|---|---|---|
| r349 | Title prompt only; no mode-2 loader entry. Stopped by our child-only watchdog. | Candidate title DCF4 wait, not loading evidence. |
| r350 | Title prompt only; no mode-2 loader entry. Stopped by our child-only watchdog. | Second title-stage wait sample; the sampled waits were paired, so no missed producer is established. |
| r351 | Screen-gated new-pilot route reached visible `NOW LOADING`. | DCF4 callbacks continued; the final visible raster state had no pending batch at that sample. This run did not include file lifecycle detail. |
| r352 | Replay did not reach loading; NV2A stopped advancing at frame `0x268`. | Not comparable to the loading runs. |
| r353 | Title prompt only; never reached the pilot list or loading. | A valid title-stage DCF4 wait unwind, described below; separate from post-difficulty loading. |
| r354 | New-pilot route reached a visibly captured `NOW LOADING` screen, then failed to reach a mission frame. | File lifecycle/read, loader pass, raster/DMA/DCF4 and external minidump evidence captured together. |

The retained r354 frame is `iso/local-analysis/logs/m3-loading-handoff-snapshot-r354-20261029/frame.png`; it is a pixel-verified lossless PNG of the prior BMP. It shows the centered `NOW LOADING` graphic on black, not a mission frame.

## r354 trace findings

### Screen-gated route and loader progress

Run `m3-loading-handoff-snapshot-r354-20261029` started at 2026-10-29 17:45:54 local. PID 176300 used the r342 EXE/PDB/MAP above and reached title → invalid-record prompt → Campaign → `LIST AS NEW` → name `A` → date `01/01/2002` → YES → Normal → visible `NOW LOADING`.

The mode-2 loader callback on host TID 155416 completed 34 recorded passes from tick 562623937 to 562627218. Each output was `branch=scan`, range 2..11, `last_index=28`, `result=0`. The final output pair was `0x000ABA00/0`; this is an observed output value, not proof of readiness. The helper trace then reached index `0x1E` (`ret=0x000C32A1`, stage `0x000C300D`) and recorded decision 6 with comparison inputs `0:1` and `0:0x00F7FD78`. No later mode-2 pass, preload worker, preload entry, thread-start record, or load-state callback was captured. The absence of those records does not establish that the game expected one; the corresponding opt-in trace sources were disabled in this run.

### Files and completion

The run recorded 2,397 successful file opens, 2,304 closes, and 8,083 completed reads before trace output stopped at tick 562630484. The final opens were WAV assets such as `V0_07_11.WAV` and `V0_07_12.WAV`. Sampled reads returned `ios=0`, `nt=0`, and `guest=0`; the last records read WAV `RIFF`/`WAVE`/`fmt ` headers. There are 93 more opens than closes at the trace cutoff. Because logging stopped before the external dump at 17:50:50, that difference cannot be classified as a leak or a loader dependency; the cutoff may have interrupted normal close records. No failed read or missing-path record appeared in the captured stream.

The external minidump's validated unwind for TID 182444 reached `bridge_trace_output+0x37`; it did not unwind to a file-read API. Therefore the file reader's exact stopped state is not established by that thread's unwind. The trace files stopped updating at 17:48:17, while the dump was captured about 2m33s later. The configured 240-second in-process watchdog snapshot file was absent; the expected internal snapshot was not achieved.

### Rendering and synchronization

At tick 562630218, `RASTER-PERF` reported 1,158 batches, 298 parallel batches, four worker threads, 2,402 triangles, 66,450,612 bounding-box pixels, 33,232,444 pixel writes, 1,696.66 ms summed batch wall time, 6,219.95 ms summed worker-active time, 18.84 ms maximum batch wall time, and 67.43 ms maximum worker-active time. The corresponding last observed batch ID advanced to 237271. This is substantial CPU raster work on a mostly black loading frame and is a plausible contributor to low throughput; it does not prove that rasterization blocks loader readiness.

The r354 trace contains 9,548 `[RASTER-SYNC]` records. At the sampled times, the main thread's DCF4 `wait-after` records returned `0`, while worker/event-set records and DMA acknowledgements continued. The last visible DMA record advanced GET from `0x0005AD5C` to PUT `0x0005E098`; a subsequent sampled graphics line showed DCF4 signal state `0`. That is evidence of active graphics/event work, not proof that every wait in the process completed. The external dump was taken later than the last trace output, so the telemetry does not describe the exact dump instant.

The 47 `[NV2A-TICK]` lines include the latest signature at frame `0x00000B5E`, counter `0x0000F623`, target `0x0000F619`, fence `0x0000F615`, DCF4 `0`, and four raster workers. Batch/pending counters remained nonzero during several samples. No per-frame 60-FPS measurement or stable frame-time distribution was produced.

### Native stack validation

`analysis/r354-selected-native-unwinds-20261029.txt` uses `tools/Walk-ProducerTraceMiniDump.ps1` with the exact r342 image and PDB. It is a native unwind, distinct from the raw-address scan. The dump is `loading-stall-external.dmp`, captured from PID 176300's r342 image.

- TID 155416 unwinds through native wait/runtime frames to EXE RVA `0x4E94BCA`, which the exact map places inside `sub_00048B80` (guest input-predicate helper). The unwind has zero memory-read failures but stops at `ERROR_INVALID_ADDRESS` (487); it does not prove a DCF4 wait or identify a loader dependency.
- TIDs 172592, 173196, and 153948 reach `xf_rows+0x2E2` in the NV2A image and then stop at non-module address `0x10000`, with zero stack-memory read failures. This validates raster-transform worker frames, but not a full wait chain or the last producer/consumer handoff.
- TID 177936 reaches `guest_cpu_acquire+0x541`, then stops at non-module address `0x10264`. TID 182444 reaches `bridge_trace_output+0x37`. TID 25104 reaches `kernel_timer_thread+0xF2` before its unwind stops on an invalid address. These partial unwinds do not establish why the guest stopped progressing.

The older title-stage r353 snapshot is stronger for its own separate failure: TID 174372 unwinds through `xbox_KeWaitForSingleObject+0x29`; the matching wait-trace host handle `0xD24` maps to guest event `0x0021DCF4`, whose snapshot state is unsignaled. No owner was found. This must not be merged with the r354 post-difficulty loading evidence.

## Supported conclusion and next test

The first reproducible blocker is still **post-difficulty loading with no first mission frame**. r354 rejects the claim that its observed loading interval was simply an unmatched DCF4 wait: the recorded DCF4 wait/return pairs and DMA/raster activity continued. It also shows successful file operations and a completed series of mode-2 scan passes. However, it does **not** identify which loader dependency must complete next, and it does not prove rendering is the cause. DirectSound list corruption remains a separate historical crash family; this run did not capture that failure. The r130 `ObReferenceObjectByHandle` completion behavior is implemented and has not been tied to this plateau.

**Next hypothesis to test:** after the 34 successful mode-2 scans, the game is waiting on a loader/thread completion or asset setup step that is not visible in the existing run records; the expensive rendering may be concurrent load, not the missing producer. On the same new-pilot route and r342 bundle, enable only bounded thread-start/preload scheduling, load-object/read-completion counters with recent-window retention, and the existing NV2A/DCF4 signatures. Take a child-only external dump after an unchanged loading signature. The hypothesis is supported only if the completion/readiness token stays pending and its expected producer is absent or exits without publishing; it is rejected if the token completes while the screen remains stalled. Preserve the current save and do not apply a behavior fix until this correlation is made.

## Storage and build efficiency

Fresh post-compression whole-workspace scan: `C:\Project\sb-inventory-r354-postsavecompression-20261029.csv`, 76,944 files, **40,807,884,606 bytes allocated (38.005 GiB)** and **1,385,305,361,547 bytes logical (1,290.166 GiB)**; 13 reparse entries skipped. Compared with the post-r348 baseline of 52,595,136,858 bytes allocated, actual allocated use is down **11,787,252,252 bytes**. The run reports, hashes, and analysis remain retained.

The r349–r354 closed run logs were compressed only after SHA-256 round-trip verification; the r354 screenshot was converted to PNG and every pixel compared before replacing the BMP. That audit reclaimed **5,723,425 bytes**. The 15 closed, inactive 750 MiB Partition5 images in the previous hash audit were all unique; 14 inactive save-root images and one historical run-save image were NTFS-compressed in place with exact before/after hashes. Their full **11,796,480,000 logical bytes** are preserved, while **11,796,357,120 allocated bytes** were reclaimed. The canonical r354 route save remains uncompressed. Audit: `analysis/r354-save-image-compression-20261029.csv`; no saves were deleted or hard-linked. Total directly measured allocation reclaimed by this turn's compression is **11,802,080,545 bytes**. The retained `build-xpp-seeded` subtree remains **6,701,008,794 allocated bytes (6.241 GiB)**; canonical generated source is **155,885,489 bytes**; current route saves are **952,898,778 allocated bytes**. No build or benchmark ran; incremental build-time impact is unmeasured.

Each new run used the existing measured **64 MiB per-run evidence budget** and bounded asynchronous trace queue; r354 recorded zero relay drops. Limits reached: DCF4-GATE emitted its 2,048-row cap marker. Read capture was configured for the first 30,000 completions plus every 1,000th thereafter; this run logged 8,083. `DISPATCH-GATE` remained zero, and the in-process watchdog snapshot was missing. These limits and the 2m33s gap between final trace output and dump mean this evidence is useful but incomplete. Closed logs are now retained as verified `.gz`; retained screenshots use a lossless PNG when it allocates less.

No first mission frame was verified. AOT, graphics behavior, and game/save state were not modified.
