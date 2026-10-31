# r522 allocator/report hypothesis, title wait, and storage audit — 2026-10-31

## Outcome

The existing low/high allocation fix remains supported by the real ordinal-166 bridge regression. All five warm memory-regression modes passed again: 42 checks, zero failures, under one second; no build or cache change. The r495 GET_REPORT alias is still **unverified in-game**: r522 never reached the pilot list or loader, and emitted no constrained-allocation or GET_REPORT rows. No report-path change is justified.

One screen-gated AOT run, r522, stopped at the title prompt “Unable to load Player Record / Press MAIN WEAPON BUTTON to continue.” It did not reach the first mission frame. Its dump puts the host main thread inside `xbox_KeWaitForSingleObject+0x29`, but the guest caller cannot be unwound from the captured host stack. The sampled DCE4 wait #576 returned success in 31 ms and the DCE4 producer continued signaling. This does not support calling the final title plateau an unmatched DCF4 wait.

No files were deleted, moved, compressed, or copied for storage cleanup. Current allocated measurements matched the last candidate-history and nested-log audits. Exact file hashing found no positive-size duplicate EXE/PDB/MAP files in candidate history; five repeated MAP hashes were empty maps. The duplicate-removal action remains restricted, so validated historical duplicates were retained.

## Regression and supported fix

The reused executable was `C:\Project\sb-r511-memory-test\Release\memory_regressions_test.exe` (timestamp 2026-10-31 11:54:53) against `local-tools/xboxrecomp/tools/conformance/test.xbe`. `ctest` is not available on PATH, so the five registered executable modes were invoked directly:

| Mode | Checks | Result |
| --- | ---: | --- |
| default | 4 | pass |
| heap-reclaim | 9 | pass |
| contig-range | 16 | pass |
| ext-vma | 12 | pass |
| ext-vma-128 | 1 | pass |

The `contig-range` mode advances the real contiguous allocator beyond 16 MiB, dispatches ordinal 166 through the synthetic XBE thunk, and checks inclusive bounds, 4 KiB/64 KiB alignment, non-overlap, and graceful failure without allocation-state advance. It then sends a guest-shaped two-method packet through `nv2a_pb_scan` and the real executor, checking the type-1 low-address writeback and guard words. This validates the current bridge fix and the existing low-address executor test; it does **not** prove the r495 runtime allocation provenance, type-3 report, descriptor, or high-page alias.

The supported allocator change already present in `kernel_bridge.c` routes ordinary bounded `MmAllocateContiguousMemoryEx` calls through `xbox_ContiguousAllocRange`. Its former implementation ignored the guest low/high limits, and the pre-fix thunk test reproduced an out-of-range result. This turn made no runtime-source edit and no rebuild. The targeted suite took under one second; warm incremental build state remains intact.

## r522 route identity and evidence

- Run: `m3-r522-contig-report-screen-gated-20261031`, 2026-10-31 13:52–13:54 CDT. PID 51572 was the only process stopped, after its own bounded dump was captured. No other Steel Battalion or build process was active at launch.
- AOT EXE SHA-256: `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`.
- Matching PDB SHA-256: `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`.
- Matching MAP SHA-256: `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- Screen evidence: `iso/local-analysis/logs/m3-r522-contig-report-screen-gated-20261031/frame-history/capture-0001.bmp`, SHA-256 `2EBBCA9C65AEE27015A1235813AD03AF1851C8DCF705251EA1670000581E0196`. It shows the title/player-record prompt, not gameplay.
- Dump: `title-stall.dmp`, 1,099,220 bytes, SHA-256 `A5B738DCE3520C34F72F5AA416D92175379D816BCDA6977179F82E20427EC30E`.
- Input transcript: five `a:600` entries and `right:200`. The first A report is observed in `[XID0]`/`[XID-DMA0]`; guest `sub_000C8064` consumes an edge into `0x004AFC08=1`, returns 1 to title route site `0x000E081F`, and takes its branch to `0x001F2DD5`. The screen did not leave the title prompt. Pilot-list, loader, device-entry, `[CONTIG-EX]`, and `[PB-REPORT]` counts are all zero.
- The title main thread is host TID 51576. Exact-bundle DbgHelp unwind reaches `your_game_recomp_producer_trace.exe+0x64AC299`, mapped to `xbox_KeWaitForSingleObject+0x29` at preferred address `0x1464AC270`; it stops at non-module address `0xD5C`. This is a valid native unwind only through the known host frames, not a guest call-chain unwind. Do not treat remaining stack words as guest frames.
- The last sampled DCE4 wait was #576 at tick `112712375`, guest caller hint `0x0020EC83`, and returned `STATUS_SUCCESS` at tick `112712406`. Later DCE4 set records continued on TID 51220; sampled DMA PUT/GET were equal. The dump was taken at 13:54:31 CDT. This rules out an *observed unmatched wait #576* but does not identify the wait current at dump time or explain why the title stayed on screen.
- The unique existing save root was reused in place. The route wrote `Cache\COPYCHECK.DAT` and touched partition images; no extra save copy or hard link was created. The post-run save tree is preserved.

## Storage audit and retained working set

Fresh sparse-aware allocated-byte measurements (reparse entries excluded):

| Tree | Files | Logical bytes | Allocated bytes |
| --- | ---: | ---: | ---: |
| `build-xpp-seeded/ProducerTrace-Candidates` | 270 | 14,789,346,013 | 6,305,103,821 |
| nested historical `iso/local-analysis/logs` | 3,402 | 276,258,442,058 | 4,821,252,507 |
| r522 closed evidence | 12 | — | 1,845,944 |

Candidate history contains 87 EXEs, 87 PDBs, and 92 MAPs; all 266 EXE/PDB/MAP files were hashed. No positive-size exact duplicate output was found; five repeated map hashes are empty files. Keep every nonempty bundle until its matching dump/reference has been retired. The nested logs are primarily 2.99 GiB allocated across `.bin` files and 1.23 GiB across `.wav` files; BMPs allocate about 0.12 GiB. There are 255 sparse `.img` files with 249 GiB logical length but only about 0.01 GiB allocated, so dense copying those would be harmful. Prior full-hash/reference audit identified repeated historical cache/log files, but removal is still blocked by the recorded deletion review; no alternate removal operation was attempted.

Re-measured protected input/save floor: original ISO 7,825,162,240 B; extracted canonical game data 1,800,138,464 B; unique writable save root 952,918,462 B; total **10,578,219,166 B (9.852 GiB allocated)**. The current generated `gen` tree adds 155,904,048 B, the r513 EXE/PDB/MAP bundle adds 72,765,440 B, and the warm regression cache at `C:\Project\sb-r511-memory-test` adds 56,094,774 B. Preserve these, the dirty source trees, the rollback patch, and additional exact symbols for unresolved failure families. These are component measurements, not a fresh whole-workspace total.

Actual storage recovered this turn: **0 bytes**. The new r522 evidence occupies 1,845,944 allocated bytes; no older artifact was retired. Build efficiency impact: none; tests used the existing warm cache and no compilation was run. The last known cumulative verified recovery remains 19,116 bytes from earlier r519–r521 closed-evidence compression.

## Next action

Do not patch report type/offset handling or guest synchronization from this run. The next useful step is to recover why the title/player-record route stopped after the accepted input branch, while preserving the original input and AOT path. Once that route reaches the known pilot/loading path, capture ordinal-166 caller/result, the consumed `0x17CC`/`0x17D0` packet, RAMHT report descriptor and bounds, executor target/writeback, and guest-polled address in one run. Keep r502's earlier mode-2 plateau, r495/r501 report retry, and the r521 DirectSound list crash separate. Stop at the first visually verified mission frame.
