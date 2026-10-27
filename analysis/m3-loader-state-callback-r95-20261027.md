# r95 loader-state callback and plateau trace — 2026-10-27

## Result

The screen-gated new-pilot route reached the visible `NOW LOADING` screen, but no first-mission frame appeared. The five-minute plateau guard stopped only diagnostic PID 127580 after confirming its executable path and an unchanged loader/framebuffer signature. No runtime fix, cache copy, indirect-target seed, rebuild, or game-data change was made.

The strongest repeated dependency candidate is the missing cache-side `Z:\TEX00.BIN` operation at helper index `0x1E`. The source-side `D:\media\BIN\TEX00.BIN` exists and was opened for metadata, but no TEX00 content read or cache copy is logged. This confirms the repeated missing-cache operation and unchanged loader state; it does **not** prove TEX00 alone blocks mission entry or establish which producer should populate it. The earlier controlled cache-copy attempt in r78 did not advance loading, so this report does not recommend seeding the cache.

## Run identity and route

- Run: `m3-loader-state-callback-r95-20261027`.
- Diagnostic PID: `127580`; started 2026-10-27 11:07:54 CDT and stopped 11:20:58 CDT.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace/Release/your_game_recomp_producer_trace.exe`, SHA-256 `3C298BB7880DB89D11318D9C2CDC614F9136399AC2EE2F77020F6939DAAB58BF`.
- Generated sources: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Existing save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save copy or edit was made.
- The visible route was title → Campaign → `LIST AS NEW` → new-pilot name `AA` → birth date `01/01/2002` → `YES` → `HAI SHI DAO 2080 [NORMAL]` → `NOW LOADING`. The retained capture `frame.bmp00015.bmp` shows the loading screen at 11:16:01 CDT; the last full numbered capture `frame.bmp00024.bmp` at 11:20:53 CDT remains a black loading scene with its small progress marker. No mission scene is captured.
- The live input transcript is `pad-live.txt`. It contains the screen-gated `A` press that selected `LIST AS NEW`. At tick `365959937`, XID DMA reported byte 2 as `0x01` at guest buffer `0x01081763`. At tick `365959984`, guest edge consumption at `0x000C8064` copied `0x0001` into `0x004AFC08`; the predicate returned 1 at callers `0x000E07EC` and `0x000E18D8`. The active pilot-list callback at `0x000E18D8` selected branch `0x000E193B`, with `input=1`, `key=1`, `xid2=1`. In that same tick, action `0x83` at `0x000E19CF` changed row item `0x002E4C34+0x28` from `0x3F800000` to 0. The resource lookup identified label VA `0x0026AF04`, matching `LIST AS NEW`. This confirms the active callback through the visible new-pilot selection; `0x000E0870` was not the selected callback in this event. The run did not modify the controller mapping.

## Loader dependency evidence

- The first source TEX00 open was at tick `366269671`, TID `124276`, caller `0x0018E758`, and succeeded for `D:\media\BIN\TEX00.BIN`. The only associated content is a successful 56-byte metadata query (`FILE-IO`, information class `0x22`), followed by close; no TEX00 content read is recorded. The file exists in the extracted game-media directory.
- At tick `366270125`, on the same TID, `sub_000C2EB0` helper row n=18 returned to `0x000C32A1`, index `0x1E`, selector 0 (`paired-open-compare`). `NtCreateFile` for `Z:\TEX00.BIN` returned `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`). The helper recorded `open1=0xFFFFFFFF`, `open2=0`, `open3=0`, and exit stage `0x000C300D`; raw EAX was `0xFFFF0001` (low 16 bits 1). Source control flow at `0x000C2F3E` takes the failed-first-open edge directly to `0x000C300D`, so the second open is not attempted on this branch.
- This pair repeated 177 times on the loader thread. The other failed paths were empty save/config candidates and the separate pre-pilot `Z:\st00_0.rep` lookup; no second repeated media miss appears in the lifecycle-open records. The TEX00 source path does not show a paired media fallback during these index-`0x1E` helper calls.
- The traced `sub_00013D70` preload routine emitted 21 complete enter/probe/metadata/compare/copy-in/copy-out sequences, all ending with result 1. Its runtime index set was `0x00–0x0A`, `0x14–0x1B`, `0x36`, and `0x37`; it was never called with index `0x1E`. This shows the observed preload path did not populate the TEX00 cache entry in this run, but does not establish that this path is the only producer.
- The successful `FILE_OVERWRITE_IF` (`disposition=0x5`) cache opens correspond to 21 assets: ADVANCE, ATARI, BGM00/BGM01/BGM02, LSQ, MODEL, MOTION, RTN, SOUND, STRM00–STRM08, TEXMOVIE, and TEXOBJ. `Z:\TEX00.BIN` is absent from that create/replace set. `Z:\COPYCHECK.DAT` is a separate path-check file and is not a game asset.
- All 177 mode-2 passes returned normally through `0x000C32D6`, mode 2, scan range 2–11, last index 28, result 0. The tracked pair moved once from `0/0` to `0x011E2E00/0` by tick `366270265`, then stayed there through the final pass at tick `366593046`. The zero return is not itself an error.
- The loader thread's last logged content reads completed successfully at tick `366269640`; all logged read byte counts and statuses match. Subsequent file-I/O records are metadata queries. No pending loader read completion is visible in this trace.

## Callback state, stacks, and synchronization

`[LOAD-STATE-CB]` emitted 708 rows (below the 8,192 cap) across four traced sites in `sub_00101A60`:

| Guest site | Selected branch | Logged target | Rows |
|---|---|---:|---:|
| `0x0010203A` | `poll-b-ebp` | `0xFE000004` | 151 |
| `0x0010205A` | `post-pass-a-ebx` | `0xFE000000` | 151 |
| `0x0010206B` | `post-pass-b-ebp` | `0xFE000004` | 150 |
| `0x0010208A` | `end-cycle-ebx` | `0xFE000000` | 150 |

Each row carried `arg0=0x006B9E3C`, result 0, and unchanged before/after mode 0, phase 0, gates `1/1/0`, status words, and object word. After the initial pair update, 706 rows report `0x011E2E00/0` unchanged. The logged `0xFE...` values are outside the guest XBE code range and are not validated executable callback targets; no missing target was seeded or rebuilt from them.

A thread snapshot (`loading-thread-snapshot-1.dmp`, 1,014,553 bytes) was captured at 11:18:48 CDT with 37 threads. Guest `[LOAD-STACK]` samples belong to TID `124276` and show the loader helper path and its stack arguments. The dump's stack scan contains rendering-path candidate addresses, but it is not a complete native unwind and does not prove the loader is blocked in a render or file wait.

During the visible loading interval, raster windows continued: a late sample at tick `366592546` recorded 28 batches / 58 triangles, 2,065.62 ms batch wall time, and 8,095.64 ms summed active time across four workers; the previous window recorded 29 batches / 60 triangles, 2,149.32 ms wall and 8,420.31 ms summed active time. This is substantial CPU raster cost, but no queue-depth metric or causal gate links it to the loader state.

DCF4 callbacks and NV2A counters advanced through the end: 15,489 callback records; the final tick `366593937` reports frame `0x1F2B`, counter `0x34BF9`, target `0x34BEF`, fence `0x34BEB`, and DCF4 signal 0. However, the bounded DCF4 wait trace hit its 4,096-record cap at tick `366109000`, before mode-2 loading began. Therefore this run does not reproduce a separate terminal DCF4 wait, and later waits are not exhaustively excluded. DCF4 producer-stage tracing was not enabled.

## Automatic stop and trace limits

The plateau guard stopped PID 127580 at 11:20:58 CDT after 300 seconds with unchanged mode-2 scan result/pair and unchanged framebuffer hash outside the animated loading band. `plateau-stop.txt` records the verified executable path and signature. The external watchdog did not fire; process exit code `-1` reflects the intentional stop. The asynchronous trace relay stopped cleanly, dropped zero stdout/stderr lines, and reported complete marker counts. PID 127580 is absent; no other game process was targeted.

Trace counts include 9,550 lifecycle opens, 9,320 closes, 4,859 file-I/O detail rows, 5,411 completed `[READ]` rows, 3,186 helper branch/return rows, 177 loader pass returns, 708 callback-state rows, 369 raster windows, and 15,489 DCF4 callbacks. Lifecycle-open cap was not reached. `[FILE-MISS-PATH]` was disabled, so failure-path logging has no independent samples; lifecycle rows provide the repeated `TEX00.BIN` status and filename. The DCF4 wait cap was reached before loading. The native minidump's stack scan is not a verified unwind. The last numbered screen capture remains a loading scene; first-mission rendering, mission play, audio, controller hardware, full campaign, and 60-FPS performance remain unverified.

## Next step

Trace the producer that should populate the mode-2 cache entry at guest resource index `0x1E`, including guest resource ID, source read, destination write/copy completion, and the state update that follows. Preserve AOT execution, controller mapping, guest fences, and rasterizer baseline `1ea1871`. Keep loading, raster cost, and DCF4 synchronization as distinct hypotheses. No target seed or behavior fix is supported yet; stop a diagnostic automatically after the verified five-minute plateau, or immediately at a verified first mission frame.
