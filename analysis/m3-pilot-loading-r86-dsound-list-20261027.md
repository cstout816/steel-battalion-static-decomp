# r86 new-pilot loading trace — 2026-10-27

## Result

The screen-gated new-pilot route reached the visible `NOW LOADING` screen, but r86 did not reach a first-mission frame. Its final captures remained on the loading screen. The runtime watchdog ended the diagnostic at 1,800 seconds with exit code 3; the external process supervisor did not terminate it. No other game process was stopped.

No first missing file or other loader dependency is established by this run. There is no supported behavior fix yet. Keep the first-mission-frame milestone open.

## Run identity and trace setup

- Run: `m3-pilot-loading-r86-dsound-list-20261027`, PID 123352, started 2026-10-27 08:12:42 CDT.
- Diagnostic executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r83-xbe-section-trace-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `14F962A5BC54AE7A21E671DA53FD4DC60680030AC731A451513F39A0E6FD24CB`.
- Matching map/PDB and selected generated-source hashes are in `iso/local-analysis/logs/m3-pilot-loading-r86-dsound-list-20261027/run-manifest.json`.
- Generated AOT source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Reused save root `iso/local-analysis/saves-m3-known-save-copy-20261023`; no save copy or save edits.
- Effective trace flags and unset options are preserved in `environment.txt`. The run enabled XBE section, file lifecycle/read/failure-path, thread-start, preload-worker, loader-state, DCF4 callback, raster, and bounded DirectSound-list probes. High-volume sync/semaphore and DCF4 producer-stage traces were unset. The generic `RECOMP_TRACE_ENTER/EXIT/ESP` macros are no-ops in the active `recomp_types.h`.
- The run emitted 31,671 lifecycle opens and 31,616 closes (the source cap is 50,000 each), 6,036 read completions (below the 30,000 read cap), 23,028 DCF4 callbacks (below 100,000), and 49 DirectSound list insertions plus 20 unlinks (below the 160-per-operation cap). No invalid DirectSound node was logged. The `LOAD-HELPER-BRANCH` records reached their 8,192-row cap; that trace is incomplete after the cap. `LOAD-PASS` emitted 580 rows against an 8,192 cap. No asynchronous relay lines were dropped.

## Route and executable behavior

Screen captures and `pad-live.txt` verify title prompt → campaign → pilot list → `LIST AS NEW` → name `A` → birth date `01/01/2002` → `YES` → Normal difficulty → `NOW LOADING`. The active row updater is the previously correlated `sub_000E1820`; r86 logs its selection/action path. The first visible loading capture is `frame.bmp00021.bmp` (08:23:50 CDT); the last retained capture is in the same run directory and remains `NOW LOADING`.

One XBE section load is logged: `seg00`, section record `0x0001134C`, name VA `0x000116C9`, guest VA `0x009FB0A0`, size `0x00009AC8`, refcount `0 -> 1`, result `0`. This verifies a successful section load but does not identify the missing loader dependency.

The preload worker entry `sub_00017E40` ran once at tick 355307906 on TID 124276 with mode 0 (`preload-mode0`, texture index `0x10`). Four thread-start records were emitted. No `FILE-PRELOAD` or `FILE-COPY` entry/return records appeared. This is a coverage observation, not proof that a worker is missing or required.

## Loader and file evidence

- The first mode-2 loader pass begins at tick 355952859. Through process exit, `LOAD-PASS` emitted 581 entries and 580 returns. The return at guest `sub_000C32D6` repeatedly reports the unchanged pair `0x011E2E00 / 0`; generated code explicitly sets EAX to zero at that return, so `result=0` is not evidence of an error. The related scan traverses range 2–11 through index 28.
- Loader-state callbacks preserve mode/phase `0/0`, gates `1/1/0`, and the same pair. `LOAD-REPEAT` emitted zero records. The instrumented loader helpers returned `EAX=1` for the observed calls.
- All 6,036 `[READ]` rows completed. The last read was tick 355935390 on token `0x48000069`, mapped by lifecycle open n=102 to `Z:\bgm02.wav`; it requested and received 18,432 bytes with IOSB/native/guest status zero. Token `0x48000066` maps to `Z:\ADVANCE.BIN`; its 827 reads completed through offset 3,577,344, with the final 10,240-byte read at tick 355931500. The HLE returns guest `STATUS_PENDING` for some reads while completing them synchronously and writing the IOSB/event before returning.
- No read completion was logged after tick 355935390. During loading, paired opens of cache/media files such as `TEX00.BIN` and `TEXOBJ.BIN` succeeded; the checked files exist in both locations and have matching sizes. There were 25 failed path probes, all for absent TDATA save files, including the expected empty-slot `user00.sav` probe on the new-pilot route. They do not identify a failed mission asset.
- The progress fields and repeated scan state stay unchanged, but the scan callbacks continue. The traces do not expose a pending `NtReadFile`, failed asset open, or specific missing filename. The first stalled dependency remains unknown.

## Thread, event, and rendering telemetry

`loading-snapshot-1.dmp` was captured at 08:24:25 CDT (1,188,218 bytes). TID 121692's stack scan contains `xbox_KeWaitForSingleObject`, `bridge_KeWaitForSingleObject`, and guest `sub_00211E10+0xDD2`; the generated function is in the guest render path and its wait is associated with DCF4. The native unwinder only advanced through the native wait stubs, so deeper guest frames are stack-scan matches, not a complete native unwind. The wait log's DCF4 wait section reached its 4,096-record cap before the loading interval. Consequently it does not establish a persistent loading-stage DCF4 wait.

DCF4 callbacks and NV2A frame/counter/fence values continued to advance after the snapshot. At tick 356984500, callbacks were 22,916 and frame/counter/target/fence were `0x2DA5 / 0x591EB / 0x591E3 / 0x591DD`; neighboring DMA samples had PUT equal to GET. The final log recorded 23,028 DCF4 callbacks. No producer-stage marker records exist because the producer trace was intentionally left off; no supported cause warrants changing guest synchronization.

Raster windows repeatedly contained 27 batches / 56 triangles, approximately 2.0–2.2 seconds batch wall time and 7.8–8.5 seconds summed worker-active time, across four workers. This supports severe CPU raster cost. It does not show a growing queue or prove that raster work is the loader dependency. The equal DMA pointers and advancing event/frame counters distinguish this run from a confirmed stuck pushbuffer or persistent event wait.

## Watchdog and limitations

At 08:42:42 CDT the runtime logged `[WATCHDOG] no exit after 1800s; guest esp=0x00F7FC30` and exited with code 3. The wrapper records `ExternalWatchdogTriggered=false`, zero dropped lines, and a stopped log writer. The screen never reached a mission frame. `LOAD-HELPER-BRANCH` hit its 8,192-row cap; `LOAD-STACK` is sampled rather than a native call stack; the wait log capped its DCF4 wait records; DCF4 producer stages and high-volume semaphore telemetry were not enabled. These limits prevent naming a first blocked resource or proving whether the slow scan, render work, or another loader condition controls the loading screen.

## Next step

Keep the AOT executable, Steel Battalion input mapping, guest fences, and rasterizer revision `1ea1871`. Use one diagnostic that captures the loader's file-mapping/copy completion path and another loading-time stack after the wait-record cap, while retaining the per-process timeout. Enable DCF4 producer stages only if a sustained DCF4 wait is reproduced. Do not make a runtime behavior change until a specific cause is correlated. Stop after a first mission frame is visibly verified; otherwise report the unresolved dependency and exact run identity.
