# r438–r440: mode-2 handoff, invalid device-handle retry, and storage

**Milestone:** 3 — boot and compatibility. **First mission frame verified: 0/1.**

## Test and run identity

The source project and AOT path were preserved. No generated game code, runtime source, kernel behavior, guest fence, controller mapping, or rasterizer was changed. r440 was a screen-gated new-pilot diagnostic using the existing save root. It began at `2026-10-30T18:39:46.9692620Z`; only its verified diagnostic executable (PID 36768) was stopped after the white frame persisted and the trace continued to repeat the same invalid lookup. No other game process was stopped.

Exact inputs:

- EXE: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r426-dcf4-heartbeat-cap-20261030/Release/your_game_recomp_producer_trace.exe`, SHA-256 `6E2494623A1048E35DE2C18C68513719DDEA0AF1532F80EB4E85E8DC5C803C45`.
- PDB: matching r426 file, SHA-256 `9B6466B280BB89AC626F75F71340E476B0030B430041D6B9FAC9AE510CE2714D`.
- MAP: matching r426 file, SHA-256 `D678DE9183B8DB733D3E52CB1887EF61DB9A0A44CCDDB9020CEF1724FC9BC40A`.
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0015.c` SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`.
- Save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; reused in place, never hard-linked or copied during this run.
- Run folder: `iso/local-analysis/logs/m3-mode2-handle-lookup-r440-20261030`.

The prior r438 run with per-open target tracing disabled is retained separately. r439 did not enable its intended keyboard-input option and did not pass the title; it was stopped before the next route. Neither run is treated as a control for the campaign blocker.

## What the evidence confirms

The screen-gated XInput route reached pilot creation and difficulty confirmation, then `NOW LOADING`, followed by a solid white 640×480 framebuffer (SHA-256 `BB134B2A2CF95E56D036855B53F8B2A782D3185BEE005782B0B4913961DDA9D2`). No mission scene was visible.

The mode-2 asset worker handled index `0x1E`: open returned 1, copy returned 1 for size 0, and readiness byte VA `0x00351F22` became 1. Guest objects `0x013BB000` and `0x019204A0` both reached status/exit 1, after 72 and 87 polls. The last recorded loader pass was n=25 at tick `25754171`: mode 2, range 2..11, last index 28, branch `scan`, result 0, pair `0x000ABA00/0`. `LOAD-STATE-CB` recorded 220 rows, ending at tick `25755734`; later helper callbacks continued through n=166 at tick `25762234`.

At ticks `25762421` and later, the guest device-table trace showed handle `0x3FFF` at device `0x0021B790`, table slot `0x0021BC28`, page `0x82A9B000`, entry `0x82A9BFF0`. The entry object word at `+0xC` was `0xFFFFFFFF` both after entry allocation and after publish returned 0. Caller `0x0001D992` repeatedly called `sub_0020EC00`; it returned `0x88760828` (`phase=lookup-invalid`). The sparse counter advanced through 65,536, 131,072, 196,608, 262,144, 327,680, 393,216 and 458,752 failures on TID 11964; suppressed records were counted and dropped records stayed 0.

Generated AOT source directly explains the retry: `sub_0001D980` pushes `0x3FFF`, calls `sub_0020EC00`, compares EAX to `0x88760828`, and jumps back to `loc_0001D981` on equality. Runtime evidence therefore establishes a persistent guest retry against an unbound table entry. It does **not** identify the expected producer for the object word or prove by itself that this loop is the sole cause of the absent mission frame.

### Loader, files, graphics and synchronization

- No missing-path record was emitted (`FILE-MISS-PATH=0`). File-target tracing was disabled. The read trace contains 230 sampled records and ends at sampled read n=10,000; it is not a complete per-file completion ledger. Lifecycle tracing logged 2,236 opens and 1,831 closes. The difference is not treated as 405 incomplete reads: the trace also opens long-lived voice/media assets, and handles are reused.
- The trace does not show an outstanding mode-2 worker object among the two tracked objects: both completed successfully. This narrows the candidate but does not prove that every later asset dependency completed.
- Final NV2A samples had DCF4=1; DMA ACK PUT/GET stayed at `0x390B4`; frame stayed `0x1126`; counter/target/fence stayed `0x1A615/0x1A5B1/0x1A613`. Raster batches/workers/pending were all 0. No raster backlog was demonstrated.
- The title DCF4 unsignaled wait, DirectSound invalid-list crash, historical loading plateaus, and current `0x3FFF` retry remain distinct events. r440 does not reproduce an unsignaled DCF4 wait or DirectSound list failure.

### Stack evidence limits

Two same-run snapshots are retained: `r440-live-plateau-snapshot.dmp` and `r440-final-live-snapshot.dmp`; each is about 1.1 MB and matches the r426 image/PDB/MAP. The final exact-bundle native unwind for TID 11964 reads 67 stack-memory ranges with zero failures, reaches the diagnostic helper/UCRT, then stops at non-module address `0x18C5A3F`. It does not unwind through the guest AOT call chain. The separate raw stack-address scan contains candidate guest addresses for `sub_0020EC00`, `sub_0001D980`, `sub_00045DF0`, `sub_000467A0`, and `sub_00192BD8`; these are not reported as valid unwind frames. The trace’s explicit guest caller and generated branch are the evidence for the retry.

## Bounded trace and retention

Run options included a 32,768-line asynchronous relay, 64 MiB run budget, 4-frame rolling framebuffer history, 300-second plateau thresholds, and a 360-second UI plateau threshold. The run was stopped by this diagnostic session after capturing the final dump; the runner manifest therefore reports no watchdog-triggered stop. At exit the runner measured 9,412,261 logical run bytes; its allocated-byte query was unavailable. The post-run whole-workspace inventory measured 3,453,174 allocated bytes in this r440 folder. The run manifest records no relay drops, no trace-limit hits, no framebuffer drops, and no storage-budget hit. Four of eight framebuffer captures remain; four older captures were evicted under the configured cap.

## Storage result

Allocated size and logical size were measured separately with `tools/Measure-WorkspaceInventory.ps1`; the inventory excludes 13 reparse entries. The completed post-compression scan contains 78,608 ordinary files:

| Measure | Current | Comparison |
|---|---:|---:|
| Allocated workspace space | 39,430,094,748 B (36.722 GiB) | +4,390,900 B vs r438 post-compression scan |
| Logical ordinary-file length | 1,398,720,013,505 B (1,302.660 GiB) | Sparse images account for much of the gap |
| r440 run folder | 3,453,174 B allocated | 9,412,261 B logical in runner summary |
| Warm incremental build tree | 7,354,916,122 B allocated | Preserved; no build/cache action |
| Reused save root | 952,907,214 B allocated | 5,422,137,294 B logical; preserved in place |
| All `iso/local-analysis/logs` | 3,199,168,557 B allocated | Sparse save images were not densified |

Closed r440 text, log, and JSON files were losslessly NTFS-compressed. Their hashes and lengths were verified unchanged. This reclaimed **6,958 allocated bytes**. No files were deleted or moved; the project’s net allocation still rose from the r438 inventory because the r440 evidence and other workspace changes were retained. The prior three-archive duplicate candidate totaling 976,265,216 allocated bytes remains documented in the r432 cleanup report; its prior exact-path removal was blocked, so this pass did not try another deletion route.

## Next discriminating test

Trace the expected writer for table entry `0x82A9BFF0+0xC` after the `sub_0020F260` create/publish sequence. Record bounded before/after entry words, guest PC/caller and thread identity for the first write or prove no writer executes. Correlate it with loader objects and the visible frame. Keep the game’s retry and all guest synchronization intact during the test. Only once the expected producer and its failure are identified should a minimal compatibility fix be considered. The milestone ends at the first visually verified mission frame.
