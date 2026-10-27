# Steel Battalion r81 new-pilot diagnostic checkpoint — 2026-10-27

## Run identity

- Run: `m3-loader-r81-lifecycle-dcf4-20261027`
- PID: `110280`, started 07:07:42 CDT; process exited on access violation at 07:10:14 CDT.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r79-load-state-callbacks-20261026/Release/your_game_recomp_producer_trace.exe`
- SHA-256: `1E4912C18306EA8F105C7DB656F140473750ED945CAFCFC6A19A368FDEE21541`
- Generated AOT source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
- Save root reused without copying: `iso/local-analysis/saves-m3-known-save-copy-20261023`
- Run artifacts: `iso/local-analysis/logs/m3-loader-r81-lifecycle-dcf4-20261027/`
- Process exit: `0xC0000005` (`-1073741819`); asynchronous relay completed, zero dropped trace lines.
- Crash dump SHA-256: `4933114B68FC7A3856857930E4912A6A39D96A09846A265776FEF4BCEF71FBFE`.

## Route and result

Screen captures confirm title → Campaign → pilot list with `LIST AS NEW` → name editor, where `A` was entered. The next screen was not captured before the executable crashed. It did not reach birth-date confirmation, `NOW LOADING`, or a mission frame. Inputs were appended individually to `pad-live.txt` after framebuffer inspection; the file has four `a:800` pulses followed by `ldown:500`.

This run is a distinct early audio crash. Do not blend it with r80's later NOW LOADING stall. The authorized stop of r80 PID117004 was completed before r81; no unrelated process was stopped. PID110280 then exited itself with a crash.

## Verified crash trace

The crash record reports host RIP `0x7FF7C3D63AC8`, read fault at host address `0x10000FFF4`, corresponding guest VA `0xFFFFFFF4`; guest `EAX=0xFFFFFFEC`, `EBX=0`, `EDI=0x010810A4`. The guest stack's innermost return addresses are `0x0021FECA`, `0x00220FAF`, and `0x0010DB19`.

AOT source maps `0x0021FECA` inside `sub_0021FE7C` (game audio). This routine walks the DirectSound object's deferred-settings list and calls `sub_0021ED29` on each node. Immediately before the crash, `[DS-COMMIT-INVALID-NODE]` rows for argument `0x010810A4` report the list sentinel `0x010810B4`, head-next `0x803DCD78`, predecessor `0x8038C098`, predecessor-next/prev `0xFF000000`, then an invalid node `0x00000000`. The guest stack and register values match the subsequent `EBX-20` calculation (`0xFFFFFFEC`) and faulting read at `0xFFFFFFF4`. The crash is therefore supported as traversal of a malformed guest DirectSound deferred-settings list. What first corrupted or failed to initialize that list is still unknown; no audio or guest-state fix was made.

Other DirectSound state in the crash report: device object `0x01081004`; voice-list head `0x01081014` terminates at NULL; sound object global at `0x006C02B8` points to `0x006C1E80`. This snapshot does not prove that the backend's host voice list caused the guest deferred-settings list corruption.

## Trace coverage

`environment.txt` confirms DCF4 producer and callback tracing, file lifecycle, file-I/O detail, failed-open path, thread-start, preload-worker, load-state callback, callback-target, and four-worker raster probes. Counts in `trace-counts.txt`:

- File lifecycle: 322 opens, 266 closes; 3,823 `[FILE-IO]`; 24 failed-path samples; lifecycle open cap not reached.
- Thread start/preload: 4 `[THREAD-START]`, 1 `[PRELOAD-WORKER-ROUTE]`.
- DCF4/sync: 3,284 callbacks, 16,993 PB semaphore rows, 48,048 DMA publish rows; wait-trace reached 1,419 waits with repeated paired `set-DCF4` signals and resets during this run.
- Menu/input: 9 XID and 9 XID-DMA rows; 10 edge consumes; pilot-list callback count 296. `[SB-SNAPSHOT]` and `[SB-INPUT-DISPATCH]` remained 0.
- Loader pass: 0 rows because the new-pilot route never reached NOW LOADING.

## Progress and next action

- Overall milestones: **[██░░░░░░] 2/8 complete (25%); milestone 3 active**
- Title-to-NOW-LOADING route: **[███████] 7/7 transitions verified in earlier r80; r81 ended before it**
- First mission framebuffer: **[░░░░░░░░] 0/1**
- First stalled loader dependency: **[░░░░░░░░] 0/1**
- r81 new-pilot input/callback chain: **[███░░] 3/5; name editor reached, intermediate snapshot/dispatch missing**

Next diagnosis should determine which guest audio operation inserted or invalidated the deferred-settings list entry before `sub_0021FE7C` traversed it. Instrument list insertion/removal and the call chain around `sub_0021FE7C`/`sub_0021ED29`; preserve AOT behavior, guest fences, controller mapping, and rasterizer `1ea1871`. Keep this audio crash separate from the r80 loading stall. Use bounded runs and stop a diagnostic automatically if it crashes or no longer produces useful state progression; never terminate a normal game process.
