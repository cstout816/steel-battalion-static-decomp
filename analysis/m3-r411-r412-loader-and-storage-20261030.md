# r411–r412 loader diagnosis and storage update — 2026-10-30

## Result

Milestone 3 remains active; first visually verified mission frame is **0/1**. No runtime fix is supported by these runs. r411 reached the post-difficulty mode-2 plateau on a white framebuffer. r412 stopped earlier in a separate DirectSound voice-list access violation, before the mode-2 scheduler gate was reached. Neither run showed a mission frame or visually confirmed `NOW LOADING`.

The r411 4 MiB allocation is a reproduced event, but not an established loader cause. The bridge clamped its reservation to 2 MiB and returned success; generated guest code checks success and advances using the returned size. The worker later completed with status 1. This makes the clamp alone insufficient to explain the plateau.

## Exact run identities

| Run | Process and result | Binary and symbols | Save root |
|---|---|---|---|
| `m3-mode2-memory-reserve-followup-r411-20261030` | PID 186200; started 2026-10-30 09:15:04Z; own watchdog stopped it at 09:27:47Z after 240 seconds of unchanged mode-2/framebuffer state. | r409 candidate EXE SHA-256 `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A`; PDB `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17`; MAP `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`. | Existing `saves-m3-dsound-surface-isolated-r368-20261030`, reused in place. |
| `m3-mode2-scheduler-gate-followup-r412-20261030` | PID 189856; started 2026-10-30 09:31:39Z; crashed in DirectSound list traversal after pilot-list dispatch and before loading scheduler gate. | Same r409 EXE/PDB/MAP bundle and hashes as r411. | Same existing save root, reused in place. |

No project source or runtime behavior changed. The AOT path, guest fence behavior, controller mapping, and rasterizer from local XboxRecomp commit `1ea1871` were preserved. No other chat's process was stopped. At the process check after the runs, no `your_game_recomp` process was active; the separate PowerShell dump analysis owned by another chat was left alone.

## r411: loader plateau and limits

- Reached the new-pilot path through Normal difficulty, then mode-2 work. The framebuffer was solid white, not a verified loading label or mission image. Final frame hash: `BB134B2A2CF95E56D036855B53F8B2A782D3185BEE005782B0B4913961DDA9D2`.
- TID 189332 requested 4,194,304 bytes with 3,411,968 bytes remaining in the Xbox heap; the trace gives `used=47443968/50855936`. The bridge logged a 2,097,152-byte backing reservation and returned success at `0x03CBF000`; guest code uses the returned size. The corresponding worker completed with status 1 at tick 600730562. The heap event is real, but the trace does not establish a failed guest allocation or missing loader dependency.
- The mode-2 resource index `0x1E` ready byte was set to 1; the completion and branch telemetry advanced past its earlier readiness decision. The mode-2 output pair still stopped at `0x000ABA00/0`. Mode-2 callbacks remained in the same state.
- Sampled file reads completed with `got == want`; lifecycle counters were 2,135 opens / 1,732 closes and no `[FILE-FAIL]` record appeared. This sampling does not prove every dependency was read, closed, or consumed.
- DCF4 waits sampled in this run returned signaled; `WAIT-DCF4-CAP=0`. This is not evidence for the historical title DCF4 wait.
- Raster work continued (245 `[RASTER-PERF]` records; final sampled batch wall time about 1,168 ms with 836 batches). This indicates substantial rendering work in the sample window but does not establish it as the loader cause.
- The dump is `mode2-plateau-stall.dmp`, SHA-256 `36B5AAB626CD68703BACA03324F4B30EAC757985380B40A7A168201AE2601773`. Exact-symbol StackWalk produced only the main TID 184224 frame at EXE+`0x611AF7` (`sub_0001D980+0xB7`, generated `game_render`) before a non-module boundary. A separate raw stack scan is not an unwind. The dump does not validate a guest wait chain, expected producer, or last incomplete loader dependency.
- The offline dump parser enumerated 36 threads. Exact-bundle StackWalk64 showed the main thread's single valid frame above; the completed mode-2 worker TID 189332 was no longer present in the dump. Host graphics/audio worker snapshots included waits in D3D12/NVIDIA/XAudio paths, but no validated guest loader wait was recovered. This cannot distinguish a blocked loader from progress masked by rendering; the 240-second unchanged guest state remains the stronger plateau evidence.
- `PRELOAD-WORKER-SCHEDULE` and `LOAD-SCHED-GATE` both have count 0 in r411, so it cannot answer whether `sub_00017E80` schedules or skips the next work item.

## r412: separate DirectSound failure

r412 showed the title, accepted the new-pilot route, and dispatched pilot-list callback `caller=0x000E18D8` on object `0x006B9E1C`. It then faulted in `sub_0021ED29+0x88` (`recomp_0016.c:1717`) reading guest VA `0xFFFFFFF4`. The trace recorded an invalid voice-list node `0xFF000000`, then a null link; the voice chain ended at null. This is the DirectSound list-corruption family, not evidence about the post-difficulty loader plateau. The run's `[LOAD-SCHED-GATE]` count is 0 and its mode-2 helper/readiness counts are 0. Its requested scheduler experiment was therefore not reached. Its raw stack candidates are not validated unwinds, and no crash dump was captured.

## Testable next step

The first missing loader handoff remains the mode-2 scheduler decision after the ready worker completes. The next useful test is one bounded run with the existing `RECOMP_LOAD_SCHED_GATE_TRACE` enabled, but only if the run reaches that gate. Record the caller, predicate inputs, selected branch, enqueue result, worker object/status, and corresponding loader state at the same time. If DirectSound corruption recurs before the gate, preserve it as a separate run and obtain a writer watch/valid stack before changing list behavior. Do not force a signal, skip a guest check, select a preload mode, or alter fences. Do not repeat the allocation theory unless a trace shows the guest reservation was rejected or an actual consumer required the unallocated range.

## Storage and retention

The post-publication r412 inventory at `C:\Project\sb-inventory-current-r412-postpush-20261030.csv` counted 78,048 ordinary files: **41,653,173,364 allocated bytes** and **1,397,898,600,374 logical bytes**. Thirteen separately measured Rust/Cargo executable reparse entries add 165,381,632 allocated bytes; combined allocation is **41,818,554,996 bytes (38.947 GiB)**. The logical total is path-reported ordinary-file length; sparse partition images account for most of its difference from allocation.

The active build cache remains `build-xpp-seeded` at 7,136,856,349 allocated bytes (2,223 files). Canonical generated source is 155,890,474 allocated bytes; the r368 save root is 110,712,188 allocated / 5,422,145,730 logical bytes. No build cache, save, ISO, source checkout, or symbol bundle was removed. The closed r411/r412 run folders were losslessly NTFS-compressed after hashing: 37 files, 4,087,125 allocated bytes before and 3,247,595 after; hashes and lengths were unchanged, reclaiming **839,530 allocated bytes**. Their traces, frame captures, and r411 dump remain present.

An exact duplicate-archive removal was blocked by file-action review before execution. Deletion savings are **0 bytes**; no alternate deletion path was used. Three validated duplicate archive copies representing 976,265,216 allocated bytes remain candidates only if the action review permits removal. Inventory and compression details are in [the r412 cleanup manifest](current-cleanup-manifest-r412-20261030.md).
