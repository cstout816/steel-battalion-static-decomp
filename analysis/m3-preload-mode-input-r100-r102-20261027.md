# r100–r102 preload-mode input trace and DirectSound retries — 2026-10-27

## Result

The new bounded trace compiled and ran in an isolated AOT executable. Across r100–r102, the caller at `0x000E0109` requested preload mode `0`; its decoded control word, previously stored mode, and stage value were all zero. The existing mode scheduler created its mode-0 worker. No `[LOAD-SCHED-GATE]` event at `0x00101FC0` was emitted, so that alternate loader gate was not entered in these runs.

r100 and r101 both reached the new-pilot flow and then crashed in the DirectSound deferred-list commit path before `NOW LOADING`. They share the prior failure signature: a null node `0` with predecessor `0x8038C098`, followed by a guest access violation at `0xFFFFFFF4` (`0xC0000005`). r101 also fully correlates the screen-gated input with XID delivery, guest edge cell, visible pilot callback, selected branch, and row state write. r102 enabled the existing DSound write watcher and list trace; the watcher armed 54 observed thread IDs but recorded zero writes to its three watched link/owner words. r102 was stopped manually after it remained in pilot-name entry without reaching the loader. That negative watch result is limited to those addresses and the watcher’s observed thread coverage.

No behavior fix was made. These runs do not establish a loading-stage cause and do not alter the previous r97/r99 finding that a mode-1 producer path is a candidate rather than a proven gate.

## Executable and trace setup

- Candidate: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-mode-state-r100-20261027/Release/your_game_recomp_producer_trace.exe`
- SHA-256: `B1FD7121E4442587A7485F9B23251C08B9C1E06F077275406A19C925A39FE68E`
- Generated AOT source used at runtime: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen/`
- New opt-in records: `[PRELOAD-MODE-REQUEST]` (512-record cap) at the two generated `0x000E0109` calls; `[LOAD-SCHED-GATE]` (2,048-record cap) at the `0x00101FC0` decision. The existing `[PRELOAD-WORKER-SCHEDULE]` remains capped at 512.
- The new records are trace-only. Guest register flow, branch decisions, input mapping, fences, and rasterizer `1ea1871` are unchanged.
- r100/r101 had zero relay drops and complete marker counts. Their marker traces contain one mode request and one worker schedule each, with no load scheduler gate. r102 also had zero relay drops; it contains one mode request and one worker schedule, no load scheduler gate, and no `[DS-WRITE]` record. The write watch was source-capped at 20,000 events and emitted 54 `[DS-WATCH-ARM]` rows; the cap was not reached.

## Run evidence

| Run | PID | Result |
|---|---:|---|
| `m3-mode-state-r100-20261027` | 129780 | Exit `0xC0000005`; new-pilot transition, then DirectSound invalid-node crash; no loading |
| `m3-mode-state-r101-20261027` | 119832 | Exit `0xC0000005`; visible pilot-name page reached, then same DirectSound invalid-node crash; no loading |
| `m3-dsound-watch-r102-20261027` | 129780 | Stopped by the harness after a long pilot-name-page trace; exit `-1`; no loading, no guest list-link writes observed |

### Mode request

The first request in all three runs was at caller `0x000E0109`, requested mode `0`, control `0`, active mode `0`, stage `0`. The source computes this request from a control word before storing it at `0x00687490`. The trace records the computed mode and related values but does not prove which title-menu action should set the control bit for a mode-1 request.

### r101 screen-gated input

At tick `370984812`, TID `122528`, the XID report delivered button byte 2=`01` to guest buffer `0x01081763`. The edge-consume record at `0x000C8064` copied `0001` to `0x004AFC08`; the visible pilot callback `0x000E18D8` selected branch `0x000E193B` with `input=1`, `owner=8`, row item `0x002E4C34`. Post-row action `0x83` at `0x000E19CF` changed field `+0x28` from `0x3F800000` to 0. The next saved framebuffer shows the pilot-name page. This matches the previously correlated `LIST AS NEW` callback and excludes `sub_000E0870` for that input event.

### DirectSound crash and watch coverage

In r100 and r101 the invalid-node marker identifies list argument `0x010810A4`, null node `0`, predecessor `0x8038C098`, and the invalid guest dereference at `0xFFFFFFF4`. This is consistent with a DirectSound list-link failure but does not identify the earlier writer that produced the invalid node. The saved dumps are `iso/local-analysis/logs/m3-mode-state-r100-20261027/crash.dmp` and `iso/local-analysis/logs/m3-mode-state-r101-20261027/crash.dmp`.

r102’s watcher started at guest words `0x8038C098` (next), `0x8038C09C` (previous), and `0x8038C08C` (owner), translated to host addresses `0x8039C098`, `0x8039C09C`, and `0x8039C08C`. It logged 54 thread-arm records and zero writes. It was manually stopped by the harness after the pilot-name screen remained unchanged and no loading pass or scheduler-gate event appeared. It was not stopped by the five-minute loading-plateau detector or 15-minute hard timeout. The watched fields and observed threads do not cover every possible guest object or writer.

## Limitations and next step

These runs did not reach `NOW LOADING`; the alternate scheduler gate therefore remains unevaluated. r102’s added watcher does not explain the DirectSound invalid node. Keep that crash separate from the TEX00 cache miss, rasterizer cost, and historical DCF4 wait. Next, trace the actual DirectSound invalid-node source and the complete guest object/link write path only if needed to make the new-pilot route reliable; then resume the loader mode-request and `0x00101FC0` gate capture through `NOW LOADING`. Do not force mode 1, seed TEX00, or patch game behavior without a causal state transition.

Progress remains: overall `██░░░░░░ 2/8`; XBE/decompilation `██░░ 2/4`; boot/compatibility `████░ 4/5`; loader dependency tracing `██░░ 2/4`; rendering `██░░ 2/4`; controller `██░ 2/3`; audio/DSP `█░ 1/2`; first mission framebuffer `░ 0/1`; stable 60-FPS mission performance `░ 0/1`.
