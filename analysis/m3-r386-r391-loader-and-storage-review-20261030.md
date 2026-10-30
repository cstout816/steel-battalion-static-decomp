# r386–r391 loader investigation and storage review — 2026-10-30

## Outcome

Milestone 3 remains active. **First visually verified mission frame: 0/1.** r391 completed the screen-gated new-pilot route through Normal difficulty, then the framebuffer became solid white and stopped changing. It did not show a mission frame or visible `NOW LOADING` label. No runtime behavior was changed, no build ran, and no target/import was seeded.

## Protected runs and exact image

- At inspection, no `your_game_recomp` / ProducerTrace process was running. No process from another run was stopped.
- Run: `m3-loader-target-trace-off-matched-r391-20261030`; diagnostic PID 187156; exit code 3 after the runner's 400-second limit. Async relay dropped 0 lines; the 64 MiB budget was not reached.
- Executable/PDB/MAP are the r367 bundle under `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-tdataroot-isolation-r367-20261029/Release/`: EXE SHA-256 `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`; PDB `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`; MAP `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`.
- Generated-source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Save root: `iso/local-analysis/saves-m3-known-save-copy-20261023`. Current `Partition5.img` SHA-256 is `D03911131ECB5DFABE16F33175FFC098F0ACAA57B105454149EB1AB084280183`, matching r391's recorded pre-run value. Other partition hashes are in the retained run records and current save root; no hard links were created.
- Dump: `iso/local-analysis/logs/m3-loader-target-trace-off-matched-r391-20261030/loader-plateau.dmp`, SHA-256 `68D75FC07ABBACDE0D6A510364275EF21600806A725ADA52D6A09046C68603B3`.

r391 is a close trace-off comparison with r389, not a strict single-variable A/B: target-open tracing and r389-only snapshot/watchdog options differed. r389 stopped inside `bridge_trace_file_open_target` before the actual open call on a pending `Z:\STRM00.WAV` record. With target-open tracing absent, r391 recorded 2,599 lifecycle opens, 2,185 closes, and 230 retained read rows; sampled read statuses were successful. It passed that earlier trace-hook blockage candidate, then stopped later. This does not prove the hook was the sole cause of r389's delay or that `STRM00.WAV` is defective.

## Route and earliest current loader blocker

The input log confirms screen-gated A transitions through the new-pilot flow; the last recorded guest edge was transition 18, parent `0x000E331A`. The run reached Normal difficulty. At the mode-2 stage, 32 load-pass scans covered range 2–11. The final scan returned `result=0`, `ret=0x000C32D6`, and stable output/global pair `0x000ABA00/0`. Loader state callbacks stopped at n=328; the final callback preserved mode 2, phase 0, gate `1/1/0`, progress `0x000ABA00/0`, status `0/0`, object `0`.

The mode-2 worker route called guest `0x00034720`. Thread token `0x48000078`, guest object `0x019204A0`, transitioned from `STATUS_PENDING (0x103)` to completed exit status `1`; the runtime logged `PsTerminateSystemThread: status=1`. Source in `kernel_bridge.c` polls the native thread with a zero-time wait, then copies `GetExitCodeThread` into the guest thread object's `+0x120` field. This verifies pending-to-completed propagation for this worker. Exit code 1 is not evidence of a loader error, nor does completion prove the loader's separate readiness gate was satisfied. The old r130 null-output diagnosis is not repeated.

Helper index `0x1E` reached decision 6 after its readiness-byte comparison and emitted progress `0x000ABA00`; the log does not identify a missing file. No sampled file-read status failed. Exact dependency or expected producer remains unknown.

## Stacks and synchronized graphics evidence

The exact r367 EXE/PDB unwind was repeated for selected r391 threads. All reported stack-memory reads succeeded. Main guest thread TID 177520 unwound only to the AOT host frame `EXE+0x615419D` (map candidate `sub_0020EC00+0xCD`) and then stopped at non-module address `0x1026C`, `lastError=487`. This is **not** a validated guest caller chain. `sub_0020EC00` is a candidate only; a separate raw stack-address scan is not an unwind.

TID 185856 reached `xbox_NtWaitForMultipleObjectsEx+0x45`, then stopped at non-module `0x11E2EC4`. TID 181856 reached `dsp_dma_control_write+0x1D5`, then stopped on data address `0x41200000`; this point sample does not establish a loader dependency. Timer, framebuffer, OHCI, and raster worker threads showed their expected host wait locations. The mode-2 worker was absent from the terminal dump because it had completed.

The last mode-2 scan was followed by a DCF4 wait that returned status 0. Later synchronized NV2A samples held DCF4 at 1 with batches 0, workers 0, pending 0, and unchanged frame/counter/target/fence. This excludes an active raster backlog at the terminal sample; it does not explain why the loader pair stopped. Keep this separate from r387's title DCF4 wait, the historical DirectSound-list corruption, and r150's measured rendering cost.

The retained `frame.bmp` was visually inspected: a solid white 640×480 framebuffer. Frame history reports cap 8, saved 25, retained 8, evicted 17, dropped 1. The one dropped history capture and the first-N trace caps limit temporal coverage; the run manifest reports no relay drops or trace-limit hits. `stderr.log` is about 12 MB; complete logs and dump are retained.

## Older dumps checked before another run

- r150 and r151 use the r149 AOT image (EXE SHA-256 `D503E6DA6325E9771364C9160F358A21550128B34AAC7B500A34C0EE0642A15C`; matching PDB SHA-256 `1741EA1E29FEF3DF22182C934AF3E30BAECCCB0DFFB93C1649080095A2A94287`). Their exact-run StackWalk records show the title guest main thread in `xbox_KeWaitForSingleObject` / `sub_00211E10+0xDD2`; r151 documents an unsignaled DCF4 wait after reset. Those runs never entered the loader.
- r153's same-image dump has only a point-in-time DSP instruction pointer for TID 133264 and native wait-wrapper frames for selected guest CPU threads. It does not identify the guest owner or a loader dependency. Its DMA acknowledgement trace capped before terminal PUT/GET was known.
- Existing exact-run evidence is summarized in `analysis/m3-title-input-hold-r151-report-20261027.md`, `analysis/m3-raster-workerpool-r150-report-20261027.md`, `analysis/m3-dcf4-dmaack-r153-report-20261028.md`, and `analysis/r150-r153-selected-valid-unwinds-20261029.txt`.

## One testable hypothesis and next action

**Hypothesis:** a post-worker readiness handoff is missing after helper index `0x1E` publishes `0x000ABA00`; worker completion alone does not satisfy the mode-2 state transition.

**Confirm:** a narrowly bounded trace of the exact readiness consumer's source object/byte, its producer writes, and pair/status changes shows no producer update after the completed `0x00034720` worker while the consumer continues polling.

**Reject:** the expected state is updated and accepted, or the wait belongs to another thread/path. No behavior fix is justified until this relation is proven. The next capture should include a valid guest stack/current guest PC or targeted producer/consumer state at the plateau; do not enable broad per-call file or graphics logging. Keep AOT execution, guest fences, controller mapping, and rasterizer `1ea1871` unchanged.

## Storage and build impact

Fresh inventory: 77,580 ordinary files, **41,358,601,942 allocated bytes** and **1,397,117,959,601 logical bytes**. Thirteen Cargo tool reparse executables measure another 165,381,632 allocated bytes, for a path-summed retained working set of **41,523,983,574 bytes (38.67 GiB)**. Sparse logical lengths are not allocated usage. The current total is 27,881,743 allocated bytes above r385; this net change is not attributed to a single run.

The r386–r390 closed-evidence compression pass reclaimed **11,522,408 allocated bytes** with SHA-256 checks unchanged. A closure pass over 15 r391 `.log`/`.bmp` files changed no hashes and reclaimed 0 bytes. No files were deleted or moved. A prior automatic file-action review rejected a deletion attempt against verified duplicate cache files; no alternate deletion method was used. Forty closed `TEXOBJ.BIN` caches were revalidated as byte-identical to retained extracted media (1,396,080,640 bytes allocated) but remain untouched.

Warm incremental build tree: 6,918,921,034 allocated bytes; canonical generated source: 155,887,568; current r368 save root: 166,480,594 allocated / 5,422,134,482 logical; logs: 3,043,619,235 allocated / 1,036,190,731,492 logical. Last measured incremental build was about 9.1 seconds. No build or test ran, so build efficiency is unchanged and the new trace run had no build impact.

Inventory CSV and skipped-path list: `C:\Project\sb-inventory-current-r391-20261030.csv` and `.skipped.txt`.