# r97–r99 TEX00 producer-gate and worker-schedule trace — 2026-10-27

## Result

The screen-gated new-pilot route reached `NOW LOADING` in r97 and r99. Neither run captured a first-mission frame. The exact-process plateau guard stopped each only after five minutes of unchanged mode-2 loader state and framebuffer signature. r98 crashed before loading at an access violation in the already observed DirectSound invalid-node path; it is a separate failure and is not merged into the loading diagnosis.

The traces establish the first observed missing cache-side loader dependency: `Z:\TEX00.BIN` at helper index `0x1E`. Its open returns `STATUS_OBJECT_NAME_NOT_FOUND`, while the helper output pair remains `0x011E2E00/0`. They also establish that the only worker scheduled during the complete r99 route was mode 0. The corresponding preload routine completed its ordinary asset copies, then took the `0x000140E9` return branch with `ebx=0`; it never called its special index-`0x1E` copy path. This is a concrete producer-path lead, but the trace does not yet prove that this absent mode-1 preload request is the condition that blocks mission entry. No fix or cache seed is supported yet.

## Run identities

| Run | PID | AOT executable SHA-256 | Outcome |
|---|---:|---|---|
| `m3-preload-gate-r97-20261027` | `129984` | `BD69C7D49192D642BEE22F878135580620350468FCED9D2DB73CF2DE51FD5753` | `NOW LOADING`; plateau stop after 300 seconds; no mission frame |
| `m3-preload-schedule-r98-20261027` | `129264` | `6982A44B684CD268E0369E85FBDC2CD4C962642DFA5D0FAA787E5D549E9B4634` | Crash before loading; access violation after invalid DirectSound list nodes |
| `m3-preload-schedule-r99-20261027` | `125712` | same r98 executable hash | `NOW LOADING`; plateau stop after 300 seconds; no mission frame |

All used generated sources under `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen` and the existing save root `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. No save, cache, ISO, or game asset was modified. The only game process stopped by the harness was the exact verified diagnostic PID in r97 and r99. Their manifests confirm plateau watchdog true, external watchdog false, zero relay drops, and complete marker counts. r98 exited itself with `0xC0000005`; no process was terminated by the harness for that run.

## Preload path observed in r97 and r99

- Both complete routes had one `PsCreateSystemThreadEx` record targeting `0x00017E40` for the preload worker. The one `[PRELOAD-WORKER-ROUTE]` record showed mode 0, branch `preload-mode0`.
- r97 gate record at tick `368419625`, TID `124412`: site `0x000140E9`, `ebx=0`, `esi=0x1C`, `edi=0x0B`, texture index `0x10`, override 0, selected branch `return`. No `[PRELOAD-TEX00-CALL]` record was emitted.
- Source control flow in `sub_00017E40` calls `sub_00013F00(0)` for worker mode 0. Worker mode 1 would call `sub_00013F00(2)`; that call sets `ebx=2` and can continue through the special callsite `0x00014150`, which computes index `SMEM16(0x3B90E0)+0x1E` and invokes `sub_00013D70`.
- r99's bounded scheduler marker, placed at `sub_0001DAA0`, emitted exactly one request in the full route: tick `369539281`, caller `0x000E0109`, requested mode 0, old mode 0, routine `0x00017E40`. It was followed by that single mode-0 worker. No later mode-1 request, worker launch, or special index-`0x1E` call appeared through the full 300-second loading plateau.
- The observed mode-0 worker completed 17 ordinary asset copy calls (indices `0x02–0x0A` and `0x14–0x1B`), then returned 0. The 21 total copy calls in the complete startup trace also include indices `0x00`, `0x01`, `0x36`, and `0x37` from other preload paths. This trace shows what this worker did; it does not establish that mode 1 must run for every mission.

## Loading lookup and state

r99 entered `NOW LOADING` at approximately 12:18:25 CDT. On the loader thread TID `108740`:

- Source-side `D:\media\BIN\TEX00.BIN` opened successfully at tick `370017546`; observed use was metadata-only, not a content read or copy.
- Cache-side `Z:\TEX00.BIN` returned `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`) at tick `370018062`, caller `0x0018E758`.
- At return site `0x000C32A1`, helper index `0x1E` returned EAX `0xFFFF0001`, output pair `0x011E2E00/0`. On the first call, global pair was `0/0`; the caller copied the returned pair into globals `0x0066A508/0x0066A50C`. Later calls retained that pair.
- All 179 loader passes returned through `0x000C32D6`, range `2..11`, last index 28, result 0, pair `0x011E2E00/0`. Loader-state callback mode/phase and gates remained unchanged in the sampled records. This confirms a repeatable miss and unchanged scan state, but not the meaning of the pair or the exact state transition awaited by the game.
- r99 emitted 5,067 file-I/O detail rows, 9,654 lifecycle opens, 9,422 closes, 16,520 DCF4 callbacks, and 389 raster windows. The final raster window recorded 27 batches / 56 triangles, 1,994.53 ms batch wall time, and 7,800.63 ms aggregate active time across four workers. No queue-depth or transition record links raster cost to the loader state. r99 did not enable the high-volume wait trace; it makes no new claim about DCF4 wait completion.

The final r97 and r99 captures have SHA-256 `1213608B7E68E282C2415F13947777CCE3104467B580EFB0550679860080BC4F`. Both are loading screens. First-mission rendering, audio playback, mission controls, and campaign progression remain unverified.

## Separate r98 crash

r98 reached the pilot-name screen but did not reach the date, mission selection, or loading. It logged `DS-COMMIT-INVALID-NODE` for guest list node `0xFF000000`, then `0x00000000`, with predecessor `0x8038C098`; the crash was a host access violation at RIP `0x7FF6B87F46A8`, faulting guest VA `0xFFFFFFF4`. The retained dump is `iso/local-analysis/logs/m3-preload-schedule-r98-20261027/crash.dmp` (392,517 bytes). This is evidence of a separate audio/list corruption crash. No DirectSound fix was attempted and it is not evidence of the cause of the loading plateau.

## Trace limits and next step

The new `[PRELOAD-TEX00-GATE]`, `[PRELOAD-TEX00-CALL]`, and `[PRELOAD-WORKER-SCHEDULE]` markers each have a 512-record bound. They emitted one gate, zero special calls, and one schedule event in r97/r99. The `[LOAD-PAIR-OUTPUT]` trace has an 8,192-record source cap and emitted fewer than that. r99's marker-count sidecar is complete and its relay dropped zero lines.

The strongest supported candidate is a missing cache-side TEX00 dependency with no mode-1 preload worker scheduled in the observed route. What remains unverified is whether the mode-1 worker is required for this mission, which caller state should request it, and whether the missing cache entry alone blocks the loader. Next, trace the guest writer and callsite conditions that compute `requested_mode` at `0x000E0109`, plus the other scheduler callsites (including `0x00101FC0`) and the loader's awaited state. Do not force a worker mode, seed TEX00, patch the game, or alter guest fences until a causal transition is captured. Preserve AOT execution and rasterizer baseline `1ea1871`; keep the DirectSound crash, loader miss, expensive raster windows, and DCF4 synchronization distinct.

## Workspace cleanup

After r99 stopped, the completed r96, r97, and r98 isolated diagnostic build directories were moved (not deleted) from local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/ to C:\Project\SteelBattalion-Delete-Later\m3-diagnostic-builds-r96-r98-20261027. Together they contained 509,937,943 bytes. Run logs, crash dump, source patches, and reports remain available. Future diagnostic runs will automatically stop the exact launched process after a verified five-minute unchanged plateau, while leaving unrelated and user game processes untouched.
