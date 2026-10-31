# Allocator/report hypothesis and storage follow-up — 2026-10-31

## Scope and process check

Read the October 31 project review, `analysis/CURRENT_STATUS.md`, and completed reports through r522. No later completed report was present. At the process check, no Steel Battalion runtime, build, compiler, or regression process was active. PID 52452 was the user's Call of Duty HQ process; it was left untouched. No route replay was launched, no shared source/build/save/log was changed, and no candidate bundle was created.

## Allocation and GET_REPORT evidence

The current `bridge_MmAllocateContiguousMemoryEx` passes size, alignment, low, and high bounds to `xbox_ContiguousAllocRange` (`local-tools/xboxrecomp/src/kernel/kernel_bridge.c:1007-1048`). The current harness exercises ordinal 166 after the arena passes 16 MiB and checks inclusive bounds, alignment, non-overlap, tracked size, and failure without allocator advancement. No allocator source change was justified by this follow-up.

The retained r495 rows in `iso/local-analysis/logs/m3-icall-seed-r495-20261031/stderr.log` establish `create-entry-return` for handle `0x3FFF`: page `0x82A9B000`, entry `0x82A9BFF0`, initial words `0/0/0/FFFFFFFF`; later `lookup-invalid` polls target `0x82A9BFF0` and return `0x88760828`. They do not record an `[CONTIG-EX]` allocation result, so the page's provenance remains unproven.

Static guest behavior still predicts packet value `0x03A9BFF0` and CPU poll address `0x82A9BFFC`. The r495 log contains no `[PB-REPORT]` record and no synchronized report-context/writeback record. Thus neither packet consumption nor active RAMHT descriptor, resolved target, and polled alias are correlated. Current `nv2a_pb_exec.c` stores the report context handle at SET_CONTEXT_DMA_REPORT, but GET_REPORT writes through `dma_resolve(offset)`; its descriptor lookup is diagnostic only. The xemu hardware reference maps the report DMA object before applying the 24-bit offset, which confirms the contract to test, but does not establish Steel Battalion's live descriptor or validate its encoded type `3`. Do not mask away the type, force completion, or change guest synchronization on this evidence.

## Regression result

Reused the warm `C:\Project\sb-r511-memory-test\Release\memory_regressions_test.exe` and synthetic XBE, with no build. All five modes passed:

| Mode | Checks | Result |
| --- | ---: | --- |
| default | 4 | pass |
| heap-reclaim | 9 | pass |
| contig-range | 16 | pass |
| ext-vma | 12 | pass |
| ext-vma-128 | 1 | pass |

Total: **42 checks, 0 failures, under 1 second**. `contig-range` exercises the actual ordinal-166 thunk and submits a two-method packet through the actual NV2A parser/executor, checking low-page report writeback and guard words. It does not populate a nonzero report DMA descriptor or prove the r495 type-3 context. No source change, candidate rebuild, or report-contract fix was made.

## Refreshed storage measurements

Allocated bytes were queried separately from logical lengths using the Windows allocated-size API. The large target-tree totals agree with the prior r522 audit. The r522 run-folder query now returns 1,841,701 bytes, 4,243 fewer than its earlier 1,845,944-byte report; no file was changed in this follow-up, so that difference is unexplained and is not counted as savings.

| Path | Files | Logical bytes | Allocated bytes |
| --- | ---: | ---: | ---: |
| `build-xpp-seeded/ProducerTrace-Candidates` | 270 | 14,789,346,013 | 6,305,103,821 |
| Nested historical `iso/local-analysis/logs` | 3,402 | 276,258,442,058 | 4,821,252,507 |
| `iso/local-analysis/logs/m3-r522-contig-report-screen-gated-20261031` | 12 | 3,754,450 | 1,841,701 |
| Canonical generated `gen` | 27 | 155,904,048 | 155,904,048 |
| Full `build-xpp-seeded` | 2,266 | 16,592,348,351 | 8,081,749,248 |
| Canonical writable route save root | 36 | 5,422,148,542 | 952,918,462 |
| `iso` | 28,826 | 1,102,410,939,544 | 19,739,404,383 |
| `local-tools/xboxrecomp` | 3,845 | 127,707,519 | 127,697,387 |

The full build-tree figure includes candidate history and must not be added to it. The ISO figure includes nested and protected data and is not a separate savings opportunity. The save root remains intact. No complete whole-workspace inventory was generated; the previous whole-project reference is 37.26 GiB allocated. No files were deleted, moved, recompressed, or copied, so verified storage savings are **0 bytes**. No hot compiler/Cargo cache was touched; build efficiency is unchanged.

## Progress and next action

No route was run while Call of Duty HQ was active. First-mission-frame evidence remains **0/1**. r522's title/player-record route did not reach the prioritized allocation/report path; r495 remains the only retained evidence for the later `0x3FFF` lookup retry. When a route can run without interrupting the active game, use the existing r513 bundle and save root, correlate allocator caller/result, consumed packet, packet-time report descriptor, executor write, and guest poll in one run, and stop at the first visually verified mission frame. Keep this separate from r502's mode-2 plateau, r521's DirectSound crash, and title DCF4 waits.
