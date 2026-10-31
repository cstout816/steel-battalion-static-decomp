# r525 DirectSound write watch and title stall — 2026-10-31

## Run identity and result

- Run: `m3-r525-dsound-writer-screen-gated-20261031`; diagnostic PID `51228`, started `2026-10-31T19:29:24Z`, stopped at `19:40:15Z` by the runner's UI no-progress watchdog. It captured `ui-plateau-stall.dmp` before stopping only that verified child. Call of Duty PID `52452` remained open and untouched.
- Exact AOT bundle: r513 EXE SHA-256 `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`; PDB `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`; MAP `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`. Dump SHA-256: `FE00D70A4D921A1C2A898DDE4D3FBEC9D0AC89E1720207EAA9AAF6E89EC51B42`.
- Reused `iso/local-analysis/saves-m3-route-file-read-copy-20261023` in place. No save copy, build, or source change. The six partition images remain; their timestamps were updated at process startup, and without pre-run hashes any content change is unverified.
- The 64 MiB logical evidence cap did not trigger. Async relay dropped 0 lines; trace limits hit: 0. Frame-history cap 4 saved 2 screens, with 0 evictions/drops. The run contains 4,593,020 logical bytes and **2,080,006 allocated file bytes** across 16 retained files. No storage was reclaimed. Build caches were untouched, so incremental-build efficiency is unchanged.

## Route and input evidence

The retained frames show the Steel Battalion title prompt and an `Unable to load Pi… / Press Main Weapon Button to continue` overlay; the final capture was a black transition frame. Five `a:600` pulses were appended to `pad-live.txt`. `[XID0]` and `[XID-DMA0]` each emitted 11 records; the trace counted 5 `[SB-EDGE-CONSUME]` events and 9 `[SB-INPUT-PRED]` records. One accepted title-route edge at guest tick `115005703` returned 1 at `0x000E081F` and recorded `[TITLE-ROUTE-ADVANCE] next=0x002EC12C`.

Later A reports reached the XID guest transfer but produced no further guest edge or visible transition. The framebuffer remained on the title/error sequence; no campaign menu, pilot list, name editor, or loader was verified. Thus this run did not reach the stage where r521/r524's invalid-list crash occurred. It emitted zero pilot-list callbacks, mode-2 readiness records, contiguous-allocation results, or GET_REPORT executor/report records. File-open target traces had 222 begin/done pairs and `[READ]` had 224 records, all before loader entry; they identify no loading dependency.

## DirectSound write watch

The existing watcher observed 12 writes to the three watched words at `0x8038C098` (next), `0x8038C09C` (previous), and `0x8038C08C` (owner), during startup ticks `114913125`–`114913218` on guest thread `31684`:

- The first records zero-initialized the fields. Their host instruction was outside the game image (`0x7FFEE05EE6C3`) or at r513 image RVAs inside `sub_002221E8` and `sub_0022005D`.
- Subsequent host addresses map to `sub_002200A2`, whose generated body inserts an audio object into an intrusive list. The observed values were sentinel/link values (`0x010810B4`, `0x803B0C10`, `0x8038C4E0`), not `0xFF000000`.
- Later `[DS-COMMIT-NODE]` records showed node `0x8038C098` with `next=0x8038C4E0` and `prev=0x803B0C10`, consistent with the valid startup insertion.

The watch captured valid construction/insertion, **not** the later corrupting write from r521/r524. Its coverage is limited to those three words and threads after they are armed. It does not establish the writer or cause of the prior `0xFF000000` values, and it supports no fix yet.

## Stalled thread snapshot and limits

The matched r513 dump contains 42 threads. Validated x64 unwinds for TIDs `31684` and `54564` reach `xbox_KeWaitForSingleObject` at image offsets `+0x64AC299` and `+0x64AC6C5`, then stop at non-module addresses (`0x1020` and `0x11E2EC4`). Neither unwind recovers a validated guest caller or wait object. The separate raw stack-address scan finds candidate guest frames, including title-route functions, but those are not validated unwinds and are not treated as proof.

The log contains alternating guest critical-section wait messages involving lock `0x0023FE18`; the dump does not validate a lock deadlock or its owner. DCF4 producer/wait callbacks are zero, while DCE4 signal records continue. This run does not establish a DCF4 wait as the title stall cause. Keep this title-stage wait separate from r519/r502 mode-2 loader plateaus, the r495/r501 GET_REPORT candidate, and the r521/r524 DirectSound invalid-list crash.

## Current blocker and next action

The first mission frame remains **0/1**. The screen-gated route stalled after one title-route advance; the invalid-list writer was not reached. Before another route, correlate the validated wait thread(s) with the guest title state and the `0x0023FE18` lock trace, distinguishing current ownership from historical alternating wait messages. Do not change input, synchronization, DirectSound, AOT execution, or rendering from this run alone. Continue with one candidate bundle and stop at the first visually verified mission frame.
