# r759 mode-2 pair-output diagnosis (2026-11-02)

## Run identity

- Run: `m3-r759-mode2-pair-output-20261102`
- PID: 89180; started 2026-11-02 15:55:08 UTC / 09:55:08 local. The run ended under its configured 900-second external watchdog (`ExternalWatchdogTriggered=true`, exit code -1). It was no longer active when checked; no other Steel Battalion process was active.
- AOT candidate: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r756-surface-reservation-20261102/Release/your_game_recomp_producer_trace.exe`, SHA-256 `03FC192D56C9CF4F33BD7B84A156FE706DB2CB18BD2556C912F284A96C594081`.
- Matching PDB: same release directory, SHA-256 `38F1798EC2CF497AF1DC083AC9D044E154C7FC143DDF78A0499C1B74A3A45C44`.
- Matching MAP: same release directory, SHA-256 `514D77579EA3C9FD9AB840940C4EA8AA179D574A730964372D8CAC3459A33D76`. The dump's executable base was `0x7FF6749E0000`.
- Generated source used by this build: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Save root reused without cloning: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. r759 did not delete or move save files. In r758, with the user's authorization, the game itself deleted the visibly blank DATA-000 record; the row was verified empty before creating pilot A.
- No build, source mutation, dependency change, or test was performed for r759. The existing candidate and its incremental build state were reused.

## Route and visible result

The screenshot-gated route reached the new-pilot name screen, accepted name `A`, confirmed date `01/01/2002`, and selected `HAI SHI DAO 2080 [NORMAL]`. Immediately after difficulty confirmation the live window showed a white frame, then black at 0 FPS. The final retained framebuffer is completely black, not a mission scene: [capture-0022.bmp](../iso/local-analysis/logs/m3-r759-mode2-pair-output-20261102/frame-history/capture-0022.bmp), SHA-256 `A6FF748A2C1B386844BF8AFD790540CF5F4642A1251D2958196F2B25AE413A12`. No first mission frame or guest progression beyond loading was verified.

## Mode-2 pair evidence

`stderr.log` recorded 46 mode-2 passes on TID 102640. At pass 46, `sub_000C3020` returned through the scan path at guest site `0x000C32D6`, range 2..11, `last_index=28`, `result=0`, with pair `0x000ABA00/0` equal to its prior pair. The trace is not evidence that result zero is an error; the translated source returns zero on this branch.

For resource `0x1E`, helper calls 39–46 returned raw EAX `1`. Output pairs were zero for calls 39–42; `0x011E2E00/0` at 43; zero at 44; then `0x000ABA00/0` at 45 and 46. Call 46's pair matched the globals. Source at `recomp_0004.c` shows the pass only updates the progress globals when the new pair differs; the unchanged pair at call 46 therefore causes no update.

The targeted helper evidence at tick 275501171 (TID 102640, helper n=828, return site `0x000C32A1`) recorded decision 6: the paired comparison passed, the follow-up path was reached, and the readiness byte at `object+0x351F04` matched 1. Three observed handle values were `0x48000081/0x48000082/0x48000081`; none equaled the guest invalid-handle sentinel `0xFFFFFFFF`. This establishes that the sampled resource readiness check passed. It does not establish that every later loading dependency completed.

The focused file-read trace recorded 1,441 completions across SOUND.BIN (147), TEXOBJ.BIN (720), and TEXMOVIE.BIN (287); it was not a complete trace of all files. The readiness consumer marker appeared once. No fix is supported by these observations: the unchanged pair explains why that pass made no further progress, but it does not identify why the overall game failed to reach the mission.

## Stalled-thread and synchronization evidence

A same-run minidump was captured at `mode2-pair-output-stall.dmp`, SHA-256 `72504B65584A3AEFC38D8AD05018C0B3668ED39B5DE44D91D8A6C982BC7D4FB4` (1,097,565 bytes). Its TID 102640 context has host RIP `0x7FF67AC33ADB`, resolving through the matching MAP to `sub_00245430+0x117B`. The separate native unwinder rejected the next frame because its frame pointer was invalid (`0x10288`); the raw stack-address scan is not a valid unwind and must not be treated as a caller chain. Guest CPU snapshots and thread-suspend tracing were disabled, so the exact guest instruction/state and loop condition are unavailable.

The run ended because of the external 900-second watchdog. Plateau, UI-plateau, DCF4-wait-hang, and NV2A-progress watchdog flags were false. Trace caps hit: NTWAIT (256), DCE4 waits (8192), DCF4 gate (16,384; 3 dropped), and heap OOM trace (8). DCF4 callbacks and raster telemetry were active, but the captured records do not correlate a final event producer/consumer handoff with the stalled thread. Do not merge this evidence with r531's unmatched title DCF4 wait, r524's DirectSound list corruption, or the prior loading slowdown.

## Storage and next diagnostic

The run directory retained 22 files: 35,534,078 logical bytes and 10,125,428 allocated bytes (Windows allocation query, 0 errors), within the 64 MiB cap. No project artifacts were reclaimed by this diagnostic; no duplicate binaries or save-image copies were created.

Next, use this exact bundle and retained dump/source to instrument the guest execution state of TID 102640 around `sub_00245430`, including guest EIP and only the relevant loop operands/branch, with bounded evidence. Correlate it with the loader's last mode-2 pass and the synchronized DCF4/raster state. Do not repeat the same route with unchanged instrumentation, infer the raw stack scan as an unwind, or change loading, rendering, or synchronization behavior before one cause is supported.
