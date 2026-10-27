# r82 DirectSound list watch and new-pilot route

## Run identity and stop

- Run: `m3-dsound-list-watch-r82-20261027`
- Diagnostic PID: `122896` (confirmed executable `your_game_recomp_producer_trace.exe`)
- Image: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r79-load-state-callbacks-20261026/Release/your_game_recomp_producer_trace.exe`
- Image SHA-256: `1E4912C18306EA8F105C7DB656F140473750ED945CAFCFC6A19A368FDEE21541`
- Start: 2026-10-27 07:17:08 CDT; stopped at the user's explicit request at about 07:27 CDT. PID 122896 was force-terminated and verified absent. No other game process was targeted.
- Run directory: `iso/local-analysis/logs/m3-dsound-list-watch-r82-20261027/`
- Existing shared save directory was used; no save copy or cleanup was performed.

## Verified screen and input

Screen-gated live input traversed the title, Campaign, `LIST AS NEW`, name entry, and birth-date editor. The name `A` was entered. Four `ldown:500` inputs moved the name cursor to `COMPLETE`; an `a:800` completed the name. Three `lright:500` inputs moved through the date fields. The final captured framebuffer, `frame.bmp` (SHA-256 `7F6152B67C492283CF891F5551CD3E442811767DF8B3E867BBB16691F9CBCCEF`), visibly remains on the new-pilot birth-date screen with `COMPLETE` highlighted. No `NOW LOADING` screen or mission frame was reached in this run.

The last sampled pilot-list callback at tick `352070812` records `input=1`, `branch=000E193B`, `key=00000001`, `xid2=01`, and `button_cell=0001`. This is consistent with the most recent input arriving at the callback; the captured frame does not establish that the birth-date action completed.

## Diagnostic observations

The dynamic watch `[[0x006C02B8]]+0x8` resolved to the observed guest list sentinel `0x010810B4`; `RECOMP_WATCH2=0x8038C098` was also enabled. Earlier in the run, sentinel/list writes included guest return addresses `0x00221D5B` (`sub_00221C8F`), `0x00221E1E` (`sub_00221DBC`), and `0x00221E94` (`sub_00221E73`), in the game's audio setup path. The watched tail pointer changed repeatedly during normal initialization. These records do not identify the writer of the r81 corrupt node and do not support a fix.

No `[CRASH]` or `[DS-COMMIT-INVALID-NODE]` record was found. The r82 log files were preserved and the asynchronous relay finalized without drops: `stderr.log` 97,767,340 bytes, `wait-trace.log` 3,528,533 bytes, `LogWriterStopped=true`, and `MarkerCountsComplete=true`. Manifest counts include 333 pilot-list callback rows, 22 input predicates, 12 edge consumes, 5,037 file-I/O records, 322 lifecycle opens / 266 closes, 13,849 DCF4 callbacks, 300,000 DMA publish records (trace cap), 115,986 PB semaphore records, 187 NV2A ticks, and 269 raster-performance records. Process exit code `-1` reflects forced termination. Periodic framebuffer captures and the finalized `trace-counts.txt` remain alongside the logs.

## Future diagnostic watchdog

`tools/Start-ProducerTrace.ps1` now supervises the exact diagnostic process it launches. It polls for exit and force-terminates only that child at the configured watchdog limit (default 1,800 seconds), even if the runtime's internal watchdog fails; it then finalizes the bounded log relay and records whether its external watchdog fired. This does not target other `your_game_recomp` processes and does not affect normal gameplay. PowerShell syntax parsing reported zero errors after the change; the external timeout path has not yet been exercised with a fresh run.

## Status

- The original AOT path, guest fence behavior, controller mapping, and rasterizer remain unchanged.
- The new-pilot route and callback input are partially observed; date completion, loading, and first mission frame remain unverified.
- Root cause for the earlier r81 audio-list corruption and the r80 loading stall remains unknown.
- Next: launch a bounded diagnostic only when needed, continue screen-gated input from the birth-date page, and stop at the first mission frame. Avoid fixes until a cause is supported by synchronized evidence.
