# r466 title-route stop and loader-path status — 2026-10-30

## Result

Milestone 3 remains open. No game-behavior change was made; no first-mission frame was verified. The run stopped at the title prompt and did not enter the pilot list or loading stage, so it provides no new evidence about the r463/r465 post-difficulty loader plateau. Preserve the title-stage finding as a separate case.

## Exact run and retained evidence

- Run: `m3-loader-51e078-writer-r466-20261030`
- Diagnostic PID: `37468`; the run's own UI-progress watchdog stopped it after 240 seconds without framebuffer/input progress. No other process was stopped. No game or GuestWriteBreakpoint process remains active.
- AOT EXE: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-open-target-skip2048-r461-20261030/Release/your_game_recomp_producer_trace.exe`, SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`.
- Matching PDB SHA-256: `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`.
- Matching MAP SHA-256: `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`.
- Generated AOT source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; exact per-file hashes are retained in `run-manifest.json`.
- Save root: `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`. It was reused; no copy or hard link was made.
- Evidence directory: `iso/local-analysis/logs/m3-loader-51e078-writer-r466-20261030`.

The environment enabled `RECOMP_SB_DEVICE_PATH_TRACE=1` (cap 128), `RECOMP_MODE2_READINESS_TRACE=1` (asset/consumer caps 32/64), `RECOMP_LOAD_STATE_CALLBACK_TRACE=1`, `RECOMP_THREAD_OBJECT_TRACE=1`, USB/XID reporting, raster timing, and low-volume loading focus. File-read tracing and the guest-device-entry helper were off. The run budget was 64 MiB with a 16 MiB failure reserve, four-history-frame cap, bounded async relay (32,768 lines), and zero relay drops. Actual trace counters: 9 `[XID0]`, 9 `[XID-DMA0]`, 28 `[RASTER-PERF]`, 3 `[THREAD-OBJECT]`, 2 `[THREAD-OBJECT-POLL]`; zero pilot-list callbacks, input-dispatch/snapshot/edge callbacks, device-path rows, load-state callbacks, or mode-2 readiness callbacks. A input pulses reached XID reports, but this run does not trace the input beyond USB delivery.

## Title-stage snapshot and DCF4 distinction

The retained lossless frame shows the title screen with `Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.` The UI watchdog captured `ui-plateau-stall.dmp` for TID `13932`.

The exact-bundle native unwind is:

```text
#00 ntdll.dll+0x166464
#02 KERNELBASE.dll+0x1427F
#03 your_game_recomp_producer_trace.exe+0x64AA6E9 = xbox_KeWaitForSingleObject+0x29
Stop: non-module address 0xDA8
```

The unwind validates the host wait wrapper only. The saved-stack address scan contains guest-looking values such as `sub_00211E10+0xDD0`, but these are not validated unwind frames. `wait-trace.log` sampled 24 DCF4 waits, 13 returns, and 524 sets; the most recent sampled wait #512 returned after set #512. The trace does not record every wait, and DCF4 callback details were disabled, so the final wait/producer state is unknown. This is not evidence that DCF4 caused the title prompt to stop advancing.

The first automatic hardware-watch attach failed with `ReadProcessMemory` error 299 at host address `0x52E078`. A later memory query found the page committed/readable. A separately logged late attach then armed the watch on existing and new threads with initial value `MEM32(0x51E078)=0`; it recorded no writes before process exit. Since the watch attached after the title route had started, it cannot exclude an earlier write. This run never reached the `0x451C5` branch and does not identify the global's expected producer.

The save-root inventory changed only by a 76-byte `Cache/COPYCHECK.DAT` written during startup; partition-image timestamps were touched at process start, and no `TitleData` save changed. Since pre-run image hashes were not captured, preserve all partition images as touched state.

## Loader evidence that remains current

The r463 and r465 runs remain the relevant loader-stage evidence. In both, generated `sub_000450C0` reached guest `0x451C5` with `MEM32(0x51E078)==0` and selected `skip-45287`, bypassing the `sub_0001D810` call at `0x45287`. r463 then recorded repeated `lookup-invalid` for handle `0x3FFF` at guest PC `0x0020EC2B`, caller `0x0001D992`, result `0x88760828`, with the table entry field still `0xFFFFFFFF`. r465's final PC mapped to the retry loop `sub_0001D980+0xA2`. Together these support the observed branch-to-invalid-poll path, but the intended owner/producer for `0x51E078` and the correct initialization condition remain unresolved. No code was seeded, bypassed, or changed.

The r150/r151/r153 dumps were reviewed before this diagnostic using their exact r149 EXE/PDB/MAP bundle. Those title DCF4, raster-worker, guest-CPU queue, and DSP observations remain separate; raw saved-address scans are not guest unwinds. The r130 null-output `ObReferenceObjectByHandle` theory remains superseded by the current implementation and r465 completed worker status.

## Storage and protection

The r466 run directory contains 18 files, 4,212,101 logical bytes and 1,994,082 allocated bytes (1.90 MiB). Its trace/frame caps were not reached. No builds, cache purges, source edits, screenshot conversions, save copies, deletions, or moves were made.

The post-run workspace scan found 79,220 files, 1,399,613,305,721 logical bytes (1,303.491 GiB), and 39,799,862,841 measured allocated bytes (37.067 GiB), with eight small Cargo fingerprint allocation queries failing; allocated total excludes those eight unknown allocations. C: had 46,022,909,952 bytes free at scan time. The earlier automatic review rejection of 534 duplicate screenshot deletion candidates remains in force; none were retried or removed. The r154 report/log folder, its r149 EXE/PDB/MAP and save root remain present. No direct Steel Battalion project directory was found at D:\, so no unrelated D: content was moved.

## Next discriminating step

Use the r463/r465 loader route and exact r461 bundle only after a screen-confirmed route reaches the pilot list. Keep the hardware watch active before sending input by waiting for the guest target page to become readable, and trace the expected producer for `0x51E078` without changing guest behavior. Keep input/edge callbacks enabled so one input can be followed past XID delivery. Separate title DCF4, DirectSound, raster cost, and loader evidence. Stop at the first visually verified first-mission frame; no gameplay fix is justified yet.
