# r468 screen-gated title input and separate DirectSound crash — 2026-10-30

## Run identity and preservation

- Run: `m3-input-writer-r468-20261030`; diagnostic PID `29340`.
- Exact AOT executable: r461 `your_game_recomp_producer_trace.exe`, SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`.
- Matching PDB: SHA-256 `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`.
- Matching MAP: SHA-256 `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`.
- Generated-source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; source hashes were recorded in the run manifest.
- Reused save root: `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`; no copy or hard link was made.
- Retained run: `iso/local-analysis/logs/m3-input-writer-r468-20261030`; final lossless capture is `frame.bmp`.
- Run exited with `0xC0000005` after 96 seconds. It was the run launched by this diagnostic only; no other game process was present or stopped.

## Screen-gated input path

The r468 run did not use `-LoadingFocus`. XID, guest input-predicate/edge, title-route, menu-object, and pilot-callback probes were active from launch. `pad-live.txt` began empty. Each of four `a:800` pulses was appended after observing the current screen; the screenshots showed (1) title `PRESS MAIN WEAPON BUTTON`, (2) `Unable to load Player Record` prompt, (3) that prompt cleared, and (4) Campaign menu selected. A fifth `lright:500` line was appended only after the process had already exited and therefore was not delivered. The final retained framebuffer shows the Campaign menu, not a pilot list or loader screen.

One press/release is correlated through the guest input path: XID report byte 2 changed to `01` at tick `46625312` and back to `00` at `46626125`; the guest predicate at parent `0x000E081F` returned 1, and edge-consumer transition 2 at tick `46625500` recorded source `0x004B0160=0`, copy `0x004AFC08=1`, and `xid2=01`. The corresponding title route advanced through the `0x000E081F`/`0x000E0840` path. Subsequent A pulses likewise reached the guest edge machinery.

The current-source pilot row updater is already identified as `sub_000E1820`; the `0x000E18D8` call return selects its input branch at `0x000E193B`, and the `LIST AS NEW` row action is `0x83` at `0x000E19CF`. The r468 `[PILOT-LIST-CB]` hook emitted 47 rows at `0x000E18D8`, but every sampled row took the zero-input branch `0x000E18DC`. Fields stayed `selected=0`, `input=0`, owner object `0x006B9E1C` with owner value/type 1; `MENU-RESOURCE` did not resolve the `LIST AS NEW` label, and `[PILOT-ROW-POST]` remained zero. The visible screen was Campaign, so r468 did not enter the known `0x000E193B`/`0x83` path. Do not rediscover the handler, and do not claim `sub_000E0870` was active; it remains an uncorrelated higher-level dispatcher candidate.

The first-pulse edge and route records prove delivery and consumption. The later Campaign-screen A pulse was consumed under parent `0x000E290B`, while the row updater continued through its zero-input branch. It did not match the known-good row-select correlation from r69, where a sustained button state led from XID byte 2=`01` through edge transition, predicate result 1, branch `0x000E193B`, the `LIST AS NEW` label at `0x0026AF04`, and action `0x83` at `0x000E19CF`. r468 therefore fails to reproduce the known-good callback branch; the resulting state change is only the prompt/menu transition, not a selected-row action.

## Exit cause, kept separate from loading

Near exit, the audio trace recorded two `[DS-COMMIT-INVALID-NODE]` rows for argument `0x010810A4`, sentinel `0x010810B4`, first node `0xFF000000` then `0x00000000`, with corrupt predecessor/head links. The crash reporter recorded an access violation reading guest VA `0xFFFFFFF4`, with `EAX=ESI=0xFFFFFFEC`, `EDI=0x010810A4`, at guest `sub_0021ED29+0x88` (`recomp_0016.c:1717`). The separately logged DirectSound voice chain terminated at NULL. This is consistent with the already tracked DirectSound list-corruption failure and explains this run's exit; it does not identify a loader dependency or establish that the screen-gated input caused the corruption.

This run did not produce a minidump or validated native unwind. The guest PC/source mapping is a crash reporter record, not a debugger unwind. Keep the corrupted-list source and exact ownership chain as a separate unresolved issue.

## Trace and storage accounting

Run manifest counters: 9 `[XID0]`, 9 `[XID-DMA0]`, 9 `[SB-EDGE-CONSUME]`, 13 `[SB-INPUT-PRED]`, 47 `[PILOT-LIST-CB]`, 1 `[MENU-RESOURCE]`, 210 `[MENU-OBJECT-GATE]`, 383 `[TITLE-ROUTE-QUERY]`, 328 file-lifecycle opens, 281 closes, 229 completed file-open-target pairs, 15 file-miss path rows, and 33 raster timing rows. No trace cap was hit, no async rows were dropped, and the 64 MiB run budget did not trigger. The `0x51E078` write watch armed at process start with initial value zero, stayed armed across new threads, and recorded no writes before the crash.

The run retained 15 files with 3,749,282 logical bytes and 684,744 allocated bytes (0.653 MiB), measured after closed `.bmp`/`.log` NTFS compression. The entire working set remains the latest r466 measurement: 37.067 GiB allocated, with eight small Cargo allocation-query failures; r467/r468 reclaimed no existing bytes. The build cache remained warm and no game build occurred. No deletion or cleanup was attempted.

## Next discriminating step

Do not repeat the same title menu route with the same 96-second crash exposure unless the purpose is specifically DirectSound. First inspect the earlier exact-bundle r153/r151/r150 dumps and r468's crash record together, but keep title DCF4, the DirectSound list, render cost, and post-difficulty loader separate. For the loader hypothesis, reproduce a visible pilot list and `NOW LOADING` with input/menu probes active, then use file-completion, thread stacks, progress fields, and synchronized graphics/event telemetry. Do not seed `0x51E078`, bypass guest checks/fences, force preload, or change the rasterizer. Stop at the first visually verified first-mission frame.
