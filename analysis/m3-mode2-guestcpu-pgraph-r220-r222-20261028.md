# Mode-2 loading and guest CPU/PGRAPH evidence — r220–r222

## Result

No first mission frame was verified. The new-pilot route reached the post-difficulty black frame in r221 and r222, then plateaued in mode 2 with unchanged loader signature `range=2..11`, `index=28`, `branch=scan`, `result=0`, and `pair=00000000/00000000`. The evidence supports a PGRAPH notification wait and multiple guest CPU waiters at the plateau. It does not identify the exact guest CPU owner, guest caller that left the PGRAPH request unmatched, or a missing mission-media dependency. No functional fix is justified yet.

## Run and binary identity

All three runs below were launched by this task, used the screen-gated new-pilot route, and used save root `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. No other-chat process was stopped.

| Run | Run directory / outcome | AOT executable SHA-256 |
|---|---|---|
| r220 `m3-guestcpu-preempt-r220-20261028` | Reached Campaign, then exited with a native access violation before the pilot route | `3D0C5701D0260953C26A0956C865B2A955ED676DEAD85312EC6C35A581D4ED47` |
| r221 `m3-dsound-list-writewatch-r221-20261028` | Reached the post-difficulty black frame; plateau watchdog stopped only its own PID 147640 after 240 s | Same |
| r222 `m3-guestcpu-cycle-r222-20261028` | Reached the post-difficulty black frame; plateau watchdog stopped only its own PID 148276 after 240 s | Same |

Exact r220–r222 executable, PDB, and MAP bundle is retained at `local-tools/steel-battalion-game/build-xpp-seeded/diagnostic-bundles/r220-r222-guestcpu-preempt/`:

- EXE `3D0C5701D0260953C26A0956C865B2A955ED676DEAD85312EC6C35A581D4ED47`
- PDB `D08363A7B27DF90F3EBCC8CF9343943E83328BAD629F1A38A660D4B3D66FA85E`
- MAP `960E4E0FA7FB6DCB450610329B5281E398C4B603EA4408A8C700CDA5A004C2E5`

The exact r214/r218/r219 baseline bundle is now the canonical `local-tools/steel-battalion-game/build-xpp-seeded/Release/` bundle: EXE `86155CE5ED72ACB0C5E33366A51F6528EE46E3AAFA7E23D44D8E64B30299E089`, PDB `6DDF3659C4FA50251115F7C5C2483A29B2918E31B783D0490EB77C92F7A3EB4C`, MAP `C8F59599E630EC58B630B19D512551D705BD07601DAC26D186F9D8A584E34592`. The files were moved from the candidate folder after matching SHA-256 against the canonical copies; no baseline bytes were discarded. The r150–r153 dump bundle is separately preserved as documented in the prior unwind report.

The generated-source hook experiment was removed. The current source has no `xbox_GuestCpuPreempt` declaration or call, and inserting those two lines back into an in-memory copy reproduces the exact r220–r222 source SHA-256 `5761C8A783C34CD5D8429241166292D37C4B9B637BD6923B76C94E1E4C96EE86` and length 2,220,749. The current hook-free source SHA-256 is `A9633ADB53429483EAEDC768F0A5E3DF2EE47474DEBCA2FD905459A3852F4365`, length 2,220,651. It differs from the r219 manifest baseline `AC13517F2EDCB8FE10001B7F74DF72718038F4ECBA4AF77B935FA2864B1D4DC7` (2,220,633 bytes) by an unexplained 18-byte length difference that is separate from the tested two-line hook. The compact source-delta manifest is `analysis/patches/r220-guestcpu-preempt-experiment.patch`. Do not call the current source byte-identical to r219 or rebuild a supposed r219 binary from it until the 18-byte discrepancy is reconciled.

## Verified observations

- **r220 DirectSound failure is separate.** The process read guest address `0xFFFFFFF4` at native `RIP=0x7FF6F5425AC8`; EAX/ESI were `0xFFFFFFEC`. The observed voice-list head was null. This matches the distinct invalid-list failure family, not evidence about the mode-2 plateau.
- **r221 watched no DirectSound list writes.** Its watch covered next `0x8038C098`, previous `0x8038C09C`, and owner `0x8038C08C`; it recorded zero writes. This does not establish the cause of r220's crash. The run emitted one mode-2 `LOAD-PASS-OUT` with result 0 and no later pass.
- **r222 loader state stopped advancing.** Eight `LOAD-PASS-OUT` records all reported mode 2, range 2–11, last index 28, `branch=scan`, result 0, and zero pair. The state progress/status/gates stayed zero/unchanged. There were 33 file-miss path records, mostly expected empty-save/cache paths; no exact failed mission-media dependency was demonstrated.
- **PGRAPH has a real waiting thread.** In `mode2-live.dmp` and `mode2-plateau-stall.dmp`, TID 144016 has a validated native unwind to `nv2a_core.c:643`, waiting while `NV_PGRAPH_INTR_ERROR` remains set inside `nv2a_pgraph_notify`. The intended producer is guest PGRAPH ISR work that clears the pending error and broadcasts `interrupt_cond`. The trace was sampled first-2048/then-every-256, so the terminal unmatched notification's full argument pair was omitted. The dump does not restore its guest caller frame.
- **Guest CPU acquisition waiters are real.** In the same dumps, TIDs 147112 (main/loader), 33648, and 148244 unwind to `kernel_guest_cpu.c:258`, `guest_cpu_acquire`'s condition-variable wait. r221 also had TIDs 146440 and 140284 waiting in host/guest synchronization code; its ownership at stop was not captured. Raw guest addresses after a native unwind boundary are not treated as validated frames.
- **The exact owner/cycle is unknown.** The watchdog did not reach its configured 900 s; the 240 s plateau watchdog stopped the child. Therefore no terminal `[WATCHDOG] guest CPU ... owner=... waiters=...` record exists. The dump identifies waiters, not the active owner or the guest thread/callback needed to clear the PGRAPH request.
- **The final sample does not show a raster backlog.** DMA ACK telemetry reached PUT=GET=`0x0000DA44` at tick `448684734`; an earlier sampled PGRAPH notify was entered at tick `448675765` and acknowledged at `448675781`. NV2A progress counters then stopped changing around tick `448689609`, while the host timer records continued. DCF4 remained signaled (`1`). Raster work earlier in the run was substantial, but these samples do not support a terminal DMA rendering backlog, nor do they prove the pending PGRAPH request was the unique root cause.
- **The preemption hook did not demonstrate a fix.** It added `xbox_GuestCpuPreempt(0x00211F10)` on a guest loop back edge. r220 failed in the separate DirectSound path; r221/r222 still plateaued. No first mission frame or logged handoff at that back edge was observed. The hook has been removed.

## Trace limits and next test

r222 used bounded asynchronous tracing with queue capacity 32,768, 512 MiB logical run budget, 6,069,890 bytes recorded run storage, zero relay drops, and zero trace-cap hits. PGRAPH records were intentionally sampled and do not include the terminal unmatched notification. The full save-partition SHA-256 attempt was stopped after about seven minutes because it was imposing avoidable disk I/O; it produced no completed duplicate manifest and changed no save files.

Next use the exact baseline executable and symbols for the corresponding dump, after reconciling the generated-source discrepancy. Add a narrowly bounded failure-time snapshot at the 240 s plateau: guest CPU owner TID, waiter count/tickets, current guest PC/ESP per guest thread, and the last PGRAPH notification's subchannel/method/data plus enter/ack state. Ensure a fixed record cap and explicit emitted/dropped counters, retaining the tail around the plateau. One hypothesis to test is that the guest CPU owner is the thread expected to service the pending PGRAPH interrupt; confirm or reject that with simultaneous owner and ISR-dispatch evidence. Do not alter fences, force a signal, preload mode, seed imports, change controller mapping, or change rasterization while this is unresolved.

The current data distinguishes the title DCF4 wait, r220 DirectSound list failure, expensive earlier raster work, and this post-difficulty mode-2 plateau. It does not yet prove the first stalled loader dependency. Stop after the first visually verified mission frame; that milestone remains unverified.
