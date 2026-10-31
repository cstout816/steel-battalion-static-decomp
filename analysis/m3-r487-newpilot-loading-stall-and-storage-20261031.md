# r487 new-pilot loading stall and storage (2026-10-31)

## Outcome

Milestone 3 remains open. r487 reached the game's `NOW LOADING` screen through the authorized screen-gated new-pilot route, then remained black and unresponsive. No first mission frame was verified. The diagnostic used ahead-of-time recompiled guest code; it did not switch execution modes or alter guest synchronization, fences, input mapping, preload settings, or rasterizer `1ea1871`. No gameplay source change or build was made.

## Run and retained artifacts

- Run: `m3-newpilot-loader-ring-immediate-r487-20261031`; diagnostic PID 12800.
- Start: `2026-10-31T03:10:08.639Z`. At `03:14:54Z`, the last trace records still showed an incomplete loader pass, and a matched-bundle dump was captured. After the window stayed black and telemetry remained stationary, only this diagnostic process was stopped. It was not stopped by the external watchdog. The asynchronous relay finalized with exit `-1`, 0 stdout drops, 0 stderr drops, and the log writer stopped.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-open-target-skip2048-r461-20261030/Release/your_game_recomp_producer_trace.exe`, SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`.
- Matching PDB SHA-256 `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`; MAP SHA-256 `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`.
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0015.c` SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`.
- Dump: `iso/local-analysis/logs/m3-newpilot-loader-ring-immediate-r487-20261031/r487-loading-state-pid12800.dmp` (1,176,052 logical bytes). It was captured while PID 12800 was still alive. The accidentally captured PowerShell-shell dump was identified by PID mismatch and removed before the real game dump was taken.
- Retained screens: lossless `frame-history/capture-0004.bmp` through `capture-0007.bmp`; the final history frame shows the difficulty menu with Normal highlighted, before the screen-gated move to Rookie. `r487-black-stall.jpg` preserves the black frame. `NOW LOADING` was visually observed live, but the four-frame history did not capture that screen.
- Save root: `iso/local-analysis/saves-m3-known-save-copy-20261023`, reused in place. No save copy or hard link was made. Preserve this root and its current contents.

## Route verified

Inputs in `pad-live.txt` were screen-gated and checked against the visible UI. The run moved from the title/player-record overlay to Campaign, selected `LIST AS NEW`, entered pilot name `A` and date `01/01/2002`, confirmed the profile, selected Rookie, and reached `NOW LOADING`. The on-screen FPS varied between about 7 and 21 during setup/loading, but these debug-overlay readings are not a performance test.

## Loader evidence

The recurring post-difficulty loader pass is the earliest blocker supported by this run. It is not yet tied to a specific file or wait condition:

- Loader pass #36 entered at tick `56386937` and returned at `56387015` with mode 2, range 2–11, last index 28, result 0, and zero pair/old values.
- File-copy #39 entered on TID 35176 at tick `56386921` (`src=0x019A0F1C`, `dst=0x019A0E9C`) and returned success at `56387031`. The corresponding readiness-copy row is index `0x1E`, result 1, size 0.
- Pass #37 entered on TID 11460 at tick `56387031` (`ret=0x00102063`, mode 2, table `0x002602A8/0x0025E2D4`). Its final record is helper branch `ret=0x000C319A`, paired-open-compare, index `0x02`, paths `0x00F7FDF8/0x00F7FD78`. No `LOAD-PASS-OUT` followed it before traces stopped.
- The last asset-specific records include a failed cache-path open for `Z:\TEX00.BIN` (status `0xC0000001`, reported as Win32 `ERROR_SHARING_VIOLATION`) and a successful fallback open under `D:\media\BIN\TEX00.BIN`, mapped to the user's extracted game media. The fallback file is 702,976 bytes, and reads completed through offset 655,360 with a final 47,616-byte read. The asset was therefore found and read; the cache-path miss is not a supported root cause.
- The file-open-target trace reached its configured 2,048-attempt cap and emitted one cap marker. It cannot represent later target attempts. Separate lifecycle and read streams continued to report 2,419 opens, 2,347 closes, and 5,568 reads. These streams do not reveal an unfinished guest wait or a first missing loader dependency.
- No `LOAD-STACK`, `SB-SNAPSHOT`, or thread-object state records were emitted. A guest EIP/context for the stalled loader thread was not retained.
- `THREAD-OBJECT`, `THREAD-OBJECT-POLL`, and `THREAD-OBJECT-STATE` counters were 0. The existing r130 `ObReferenceObjectByHandle` implementation was not re-diagnosed; its guest completion-consumption semantics remain unverified.

## Synchronized graphics and event telemetry

- Ring polling was effective from process start: environment recorded `RECOMP_SB_RING_POLL_TRACE=1`, with first 8 samples and then one every 16,777,216 loop hits, cap 256. There were 59 samples; the last was sample 59 / hit `855,638,016`, tick `56380750`, guest function `0x00211E10`, loop `0x00211F10`, branch taken. There was no ring-poll cap marker.
- `RASTER-SYNC` emitted 14,976 rows. Its final recorded pair was at tick `56381437`; the `wait-after` result was 0 while that snapshot still showed one batch and three pending workers. Later NV2A telemetry at tick `56385625` reported zero batches/workers/pending, DCF4 signal 1, and frame `0x109D`.
- DMA ACK #255 at tick `56386781` ended with PUT=GET `0x00004018`. DCF4 callback #8014 at tick `56386984`, TID 38336, had event state 1; the gate record shows the state-change callback. No title-style DCF4 wait recurred in this run.
- The sequence supports that rendering work drained before the last loader entry and that DCF4 remained signaled. It does not prove why the final image went black or whether an untraced renderer condition also contributed. This post-difficulty stall is separate from the historical title-stage DCF4 wait.

## Native stack findings and limits

The exact r461 image and PDB/MAP were used with `Walk-ProducerTraceMiniDump.ps1`; this was genuine Windows x64 `StackWalk64` unwinding, not a scan for guest-looking values:

- TID 11460: partial native unwind through `ntdll` and `ucrtbase` to EXE+`0x64937A0`; it stopped at non-module address `0x18A7C6CEDB0`. Stack reads: 224, failures: 0.
- TID 35176: partial unwind through `ucrtbase` to EXE+`0x64937A0`; it stopped at non-module address `0x18A5201F7F0`. Reads: 329, failures: 0.
- TID 38336: partial unwind through `ntdll`/`ucrtbase` to EXE+`0x6498A92` and EXE+`0x6AC50E0`, then stopped with error 487. Reads: 554, failures: 0.
- TID 27492 had an exception marker `0xE06D7363` at tick `56387031`. Its partial unwind reached EXE+`0x544F5A`, nearest MAP symbol `_snprintf_s` in `dsound_write_watch.obj`. This is not evidence that the DirectSound list-corruption writer caused the loader stall.

These native stacks identify host-side contexts but do not provide a guest stack. The direct guest callsite, wait/poll state, and pending producer after pass #37 remain unknown. Do not infer those from raw stack addresses.

## Trace bounds and retained size

The bounded asynchronous relay queue capacity was 32,768 lines. The run's `trace-counts.txt` shows: 8,014 DCF4 callbacks, 8,012 DCF4 gate rows, 318 DMA publish rows, 256 DMA ACKs, 259 semaphore releases, 406 semaphore method rows, 76 NV2A ticks, 14,976 raster-sync rows, 649 loader-helper branches, 37 pass-in / 36 pass-out rows, 2,419 file opens, 2,347 closes, 5,568 reads, and 59 ring samples. DCF4/ring/raster/DMA/PB-semaphore and relay drop counters remained below cap; file-open-target reached its 2,048 cap once. Frame history cap was 4, with 3 evictions and 0 drops.

The retained run tree has 18 files, 20,325,989 logical bytes, and 5,757,499 allocated bytes after compression. The four lossless BMPs remain; closed logs were compressed losslessly. The per-run retention target remained bounded; no build cache was changed.

## Changes, checks, and next step

The only project-source change exercised was the existing `-EnableRingPollTraceImmediately` diagnostic switch in `tools/Start-ProducerTrace.ps1`. Its PowerShell parser check had 0 syntax errors, and r487 emitted ring samples immediately, confirming that the environment switch works. The AOT build was not rebuilt. No game fix or regression test was added because the file/cache hypothesis was not supported. The game diagnostic itself verified the route only through `NOW LOADING`; it did not verify a mission, audio, or campaign progress.

Next, use this exact dump and logs to correlate the guest loader state at pass #37/index `0x02` with per-index file completion and the last synchronized framebuffer/GPU event. If those retained records are insufficient, add a capped guest-state/pass-index trace and rerun the same route. Do not investigate DCF4 producers unless a separate DCF4 wait reproduces, and do not change guest checks, signals, fences, preload mode, controller mapping, AOT execution, or rasterizer `1ea1871` without evidence.
