# r433 black transition, thread evidence, and storage — 2026-10-30

## Result

Milestone 3 remains active; the first visually verified mission frame is still **0/1**. Diagnostic run `m3-known-route-owner-snapshot-r433-20261030` used PID 24672 and the exact r426 AOT bundle. It followed the authorized new-pilot route using the existing r368 save root. After Normal was confirmed, the display went black; the final lossless capture is `iso/local-analysis/logs/m3-known-route-owner-snapshot-r433-20261030/frame-history/capture-0006.bmp` (SHA-256 `A6FF748A2C1B386844BF8AFD790540CF5F4642A1251D2958196F2B25AE413A12`). The screenshot was inspected and is black. Unlike r432, r433 did **not** visually establish the `NOW LOADING` caption. No mission, campaign audio, or gameplay was verified.

The run used EXE SHA-256 `6E2494623A1048E35DE2C18C68513719DDEA0AF1532F80EB4E85E8DC5C803C45`, PDB `9B6466B280BB89AC626F75F71340E476B0030B430041D6B9FAC9AE510CE2714D`, and MAP `D678DE9183B8DB733D3E52CB1887EF61DB9A0A44CCDDB9020CEF1724FC9BC40A`. Generated input `recomp_0015.c` matches SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`; other manifest-checked generated inputs were unchanged. No build, runtime fix, source edit, fence change, input remap, or rasterizer change was made.

## Route, loader, and renderer evidence

The screen-gated input reached the new-pilot route. Trace totals include 37 pilot-list callbacks, 31 input predicates, 25 edge-consume events, 46 load-state callback records, 12 load-pass entries / 11 returns, 985 file opens / 926 closes, and 5,075 successful read records. The last observed read at tick `20691531` completed with `ios=nt=guest=0`; the last lifecycle closes occurred at tick `20691515`. No incomplete read or first missing mission dependency was identified. There were 32 failed path probes, with no correlation establishing a blocking dependency.

The loading-state trace briefly entered mode 2, then changed to mode 1 with zero progress; it produced only 12 load passes and stopped advancing by the terminal interval. This differs from r432's persistent mode-2 `0xABA00/0` plateau. Do not merge these into a single loader explanation.

NV2A frame/counter/fence advanced through frame `0xDA8`, counter `0x177BF`, target `0x177B9`, fence `0x177BD`. DCF4 was signaled at the terminal sample, with zero raster batches, workers, and pending jobs. After the last graphics callback, the progress signature stayed unchanged for 600 seconds. The run's own NV2A progress watchdog stopped only PID 24672; it did not stop another process. This establishes no active rendering backlog at the terminal sample, but it does not identify the guest-side handoff that stopped progression.

## Thread evidence and trace limitations

MiniDump StackWalk used the exact r426 image/PDB and produced partial native unwinds only; no complete validated guest caller chain was obtained:

- Main TID 13072 reaches `EXE+0x6495A0D`, near `deliver_one_apc`, then stops at non-module address `0x22200000000`.
- Worker TID 27064 reaches `EXE+0x6487EBF`, near the `NtDuplicateObject` bridge, then stops at guest address `0x0018E758`.
- TID 3504 reaches `EXE+0x64C9A9F`, near audio-code `fe_method`, then stops at a non-module address.
- TID 20296's walk ends with error 487; its last address is not accepted as a caller.
- TID 23876 raised MSVC C++ exception code `0xE06D7363`; its partial unwind reaches `EXE+0x544F5A`, mapped near `_snprintf_s+0xA` in `dsound_write_watch`. This is a separate diagnostic/audio-watch observation, not proof of the historical DirectSound list corruption or the loading cause.

Critical-section tracing observed TIDs 13072 and 3504 taking turns waiting on/acquiring guest lock `0x0023FE18`; one observed holder site was `0x0021E7DD`. The trace did not capture a terminal owner/waiter cycle and does not prove the lock is causal. Treat the APC/worker completion path and the critical-section handoff as candidates only.

The missing owner snapshot has a diagnosed **harness timing gap**, not a game diagnosis: `RECOMP_WATCHDOG_SECS=720` and the snapshot was configured for 720 seconds, but the separate NV2A progress watchdog stopped the run at 600 seconds. Thus `watchdog-snapshot.log` was never produced. Also, `[SB-SNAPSHOT]` is the generated controller-copy trace in guest routine `sub_00048890`; its zero count means that routine did not run in this route and is unrelated to the watchdog's guest-CPU/critical-section owner snapshot. The trace flags were set, but the scheduled owner snapshot could not fire before the earlier stop.

### Next discriminating check

Repeat the same route with the one-shot watchdog owner/critical-section snapshot scheduled before the NV2A stop (for example 480 seconds versus the existing 600-second NV2A threshold). Keep the same exact AOT/symbol bundle, save root, guest lock, fences, controller mapping, and rasterizer. The test should correlate owner/waiters, guest lock and call sites, thread completion, loader state, file completions, and NV2A state in that one snapshot. Do not patch behavior unless this synchronized evidence establishes a cause. Keep historical title DCF4 waits, DirectSound list corruption, render cost, and the r432 mode-2 plateau separate.

## Storage and efficiency

Fresh allocated/logical scan: `C:\Project\sb-inventory-current-r433-20261030.csv` (13 reparse tool entries listed in the skipped file). It measured **42,137,500,778 allocated bytes (39.2436 GiB)** including the 165,381,632-byte reparse entries, and **1,398,626,450,106 logical bytes** across ordinary files. The r433 run folder contains 18 files, 10,331,877 logical / **2,708,360 allocated bytes**. Net workspace allocation change against r432 inventory is +2,606,309 bytes; this is lower than r433's retained run allocation because some unrelated transient files disappeared between scans.

The r368 save root remains exactly 29 files and 5,422,128,858 logical / 952,898,778 allocated bytes, with paths and lengths matching r432. It was reused without a copy or hardlink. The warm `build-xpp-seeded` tree remains 7,354,916,122 allocated bytes; no build cache was removed, so incremental-build efficiency is unchanged. The logs tree is now 9,551,253,493 allocated bytes. No deletion or compression ran this pass; cleanup savings this pass are **0 bytes**. The three verified duplicate ZIP candidates remain undeleted because the previous exact-path removal was blocked by policy; do not try an alternate deletion method.
