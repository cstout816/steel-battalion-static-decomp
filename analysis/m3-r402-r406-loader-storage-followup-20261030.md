# r402–r406 loader and storage follow-up — 2026-10-30

## Result

Milestone 3 remains active. **First visually verified mission frame: 0/1.** r405 and r406 both followed the new-pilot path through Normal difficulty and entered mode-2 loader work, but neither produced a visually verified mission frame. The current loader blocker is still not identified.

No process from another run was stopped. The only game process during r406 was PID `189400`, launched from the r406 candidate by this run. Its plateau watchdog verified the PID and stopped it after 240 seconds without loader or framebuffer progress. The run used the existing r368 save directory; it did not copy, link, or alter save images.

## Runs and exact bundles

| Run | Outcome |
|---|---|
| r402 | DCF4 waits returned after matching signals; no persistent DCF4 hang. Input reached XID but did not traverse the title route. |
| r403 | Screen-gated route reached Campaign, then reproduced the r400 DirectSound invalid-list access violation at guest VA `0xFFFFFFF4`. It did not reach loading. |
| r404 | Stayed on a black title frame; input did not establish the Campaign route. Its capped wait trace cannot establish a later terminal DCF4 state. |
| r405 | Reached Normal, then black/0 FPS. At the mode-2 stage, `LOAD-PASS-OUT` ended at pair `0x000ABA00/0`; a 4 MiB heap allocation failed with about 3.41 MiB remaining. The caller and its role in loader readiness were not captured. |
| r406 | Reached the pilot editor and Normal, then black/0 FPS with mode-2 loader activity. The r405 heap failure did not reproduce. |

r405 and r406 used AOT execution, the same generated-source directory, and the existing save root `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`. r406 used a side-by-side runtime build; the r399 bundle was retained unchanged.

| r406 file | SHA-256 |
|---|---|
| EXE | `6D87E65A216FDE3E75FD2EE9F7BF1D8386FDD6C3F97B6888EF7FC27E2306A4FD` |
| PDB | `DA36A3AA1050FE44AAC9C8C9C54AE53F2BC927C2F4044E939865218CD0F88466` |
| MAP | `550D98A548E2C6C60A2282AB2573DFE0C2E9E91E4E39EF6D4557FD4B0E1B0FB8` |
| Live loader snapshot | `979AD65B327F49A393462A7E1D2D0AD403F03CBEC43C955FD0360874750CEE46` |

The matching r406 EXE/PDB/MAP are in `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-heap-oom-context-r406-20261030/Release/`. The dump is in `iso/local-analysis/logs/m3-heap-oom-context-r406-20261030/loader-stall-r406-live.dmp`.

## r406 route and loader evidence

Screen-gated input reached the visible pilot list, name `A`, default birth date `01/01/2002`, and Normal difficulty. At the pilot-list action, XID delivery reached the guest edge table at `0x000C8064`, the row updater at `0x000E18D8`, branch `0x000E193B`, and row action `0x83` at `0x000E19CF`. This is consistent with the previously verified r157 route.

The frame turned black after Normal. The run did not show a visible `NOW LOADING` label or a mission frame. Nine mode-2 load-pass scans were recorded. Progress briefly changed to `0x0045002E` and `0x002657E6`, then returned to `0/0`; the last scan at tick `595458468` reported `result=0`, range `2..11`, and helper index `0x1E`, branch `paired-open-compare`, decision `5`. No later loader pass was recorded before the 240-second watchdog stop.

The previous mode-2 worker object `0x013BA000` / token `0x48000078` transitioned from pending status `0x103` to exit status `1`. A subsequent thread creation reused token `0x48000078` for object `0x013BB000`; its status remained pending at the last poll. This matches the current bridge's pending/completion handling and does not repeat the r130 null-output diagnosis. It does not establish why the loader did not advance.

The file traces recorded 909 open calls and 861 closes. Sampled read records through n=5,000 had zero IOS/NT/guest error status and `async=0`; the file-miss trace recorded zero misses. These records do not identify a pending file request. `STRM07.WAV` and `TEX00.BIN` were opened successfully in the trace and are not identified as causes. The last `FILE-CALL` output is truncated mid-line, so the final operation cannot be established from that record.

## Heap hypothesis and thread evidence

**Test:** determine whether r405's 4 MiB allocation failure is reproducible at the r406 post-Normal loader stage, and capture its guest caller if it occurs. r406 added a failure-only `[HEAP-OOM-TRACE]` record with a cap of eight samples. It includes host thread ID, requested size/alignment, heap boundary, guest ESP/EBP, and six guest stack words.

**Result:** no heap exhaustion or `[HEAP-OOM-TRACE]` occurred in r406. This rejects neither heap pressure in r405 nor the loader's response to a failed allocation; it shows that r405's OOM is not a stable explanation for r406's earlier plateau. No heap limit was raised and no preload mode was forced.

The exact-bundle r406 dump produced these partial native unwinds, with zero stack-read failures:

- TID `163264` unwound through `ucrtbase` to EXE+`0x543BBD`, mapped to `fprintf+0x3D`, then stopped at synthetic address `0xFCC`.
- TID `185984`, whose guest frame pointer was in the `0x019A0FF0` worker stack slice, also unwound to EXE+`0x543BBD` / `fprintf+0x3D`; it did not expose a guest file-wait stack.
- TID `188596` unwound through `KERNELBASE` to EXE+`0x64A8C98`, mapped to `xbox_KeDelayExecutionThread+0xD8`, then stopped at non-module address `0x1273F78`. The wait target is not preserved.

The two `fprintf` stacks and truncated final line make synchronous diagnostic-output contention a candidate for this run's trace stop. They do not establish the guest loader's failure cause or a CRT lock owner. No game behavior was changed based on this candidate.

## Graphics/event separation and limits

The run retained 227 raster-performance samples, but DMA acknowledgement, PB semaphore, and terminal raster-queue state were not enabled. The wait trace hit `[WAIT-DCE4-CAP] seen=8192 limit=8192`; therefore its final wait state is unknown. The DCF4 hang watchdog did not fire. No separate persistent DCF4 wait was reproduced during the mode-2 plateau, so no DCF4 producer investigation or synchronization change is justified. These observations do not establish rendering backlog as the cause.

Keep the following separate:

- r150/r151 title DCF4 wait;
- r153 guest graphics plateau;
- r400/r403 DirectSound invalid-list crash;
- r405's single 4 MiB allocation failure;
- r406's post-Normal mode-2 plateau and trace-output stall candidate.

## Storage and build impact

The r406 inventory at `C:\Project\sb-inventory-current-r406-20261030.csv` counted 77,888 ordinary files: **41,581,472,450 allocated bytes** and **1,397,678,329,935 logical bytes**. Thirteen Rust-toolchain executable reparse entries add **165,381,632 allocated bytes**. Together that scan measured **41,746,854,082 allocated bytes (38.88 GiB)**; logical size is not disk use because the partition images are sparse. After the scan, lossless compression of the closed r406 dump reduced its allocated size from 1,032,256 to 217,088 bytes, saving **815,168 bytes** with the SHA-256 unchanged. The final post-report inventory supersedes this pre-report number.

Hash-verified lossless compression of the closed r402–r405 folders saved **3,777,586 allocated bytes** across 61 files. Including the r406 dump, the measured savings in this pass are **4,592,754 bytes**. No file was deleted or moved. Automatic file-action review rejected the attempted removal of the 269 old duplicate screenshot files as “blocked by policy”; the deletion command did not run, so deletion savings are **zero**. Earlier r375/r377 audits recorded exact retained copies, but this pass did not complete a new hash check after the action was rejected.

The warm `build-xpp-seeded` tree now allocates **7,064,232,890 bytes**; it was not purged. The new r406 three-file bundle uses 72,658,944 allocated bytes (170,004,182 logical). The canonical generated source uses 155,887,568 bytes; the existing r368 save root uses 110,706,488 allocated / 5,422,140,030 logical bytes. The side-by-side build completed in about 10 seconds. It emitted existing warnings in `xbox_memory_layout.c` outside the added heap trace lines. Incremental-build impact is small and measured; no full build cache was cleared.

The compact source delta and hashes are in [the r406 source-preservation manifest](r406-source-preservation-manifest.md) and [patch](preservation-heap-oom-trace-r406.patch). The patch changes runtime diagnostics only and includes no generated game source.

## Next discriminating step

Use the r406 bundle and existing save root. Keep the new failure-only heap record. Add the missing mode-2 thread-start identity and bounded terminal loader handoff fields; capture the expected producer, its last completion, and the consumer predicate at the same plateau timestamp. Reduce synchronous high-volume output before drawing conclusions from another thread stopped in `fprintf`. Keep DMA/PB semaphore tracing off unless a separate graphics wait is observed. Do not raise heap size, bypass guest checks, force signals/preloads, seed imports, or alter guest fences. Change gameplay/runtime behavior only after the producer/consumer trace confirms one cause. Stop at the first visually verified mission frame.
