# Current cleanup and storage manifest — r431 — 2026-10-30

## Measurement basis

Final full scan after the r431 report and status-index updates: 78,410 ordinary files, 1,398,556,822,470 logical bytes and 41,919,136,250 allocated bytes. Thirteen separately measured Rust toolchain reparse entries add 165,381,632 allocated bytes. Total path-summed allocated footprint: 42,084,517,882 bytes (39.194 GiB). The scan excluded no ordinary files and had no allocation query failures. Sparse logical file sizes must not be used as disk usage.

Compressed inventory and verification record: `C:\Project\sb-inventory-current-r431-final-20261030.csv.gz`; decompression hash/length were checked. It is stored outside the workspace.

## Verified cleanup this turn

| Scope | Files | Allocated before | Allocated after | Reclaimed |
| --- | ---: | ---: | ---: | ---: |
| Closed r430/r431 text records, gzip with SHA-256 and length verification | 19 | 987,726 | 171,009 | **816,717 bytes** |

Exact per-file values are in `r430-r431-closed-evidence-compression-20261030.csv`. Original logs were removed only after gzip decompression matched each original hash and length. Dumps and screenshots remain. No ISO, save, source, generated code, license, symbol, or build artifact was removed.

The current footprint is 4,743,467 allocated bytes above the prior full inventory (42,079,774,415 bytes). That increase is retained r430/r431 evidence and small report artifacts; the 816,717-byte saving is already reflected in the new full scan. The inventory snapshot predates this status/manifest update by a small amount.

## Protected working set

- Original ISO, game files, unique/mutable saves, and all dirty XboxRecomp changes remain intact.
- Exact r426 EXE/PDB/MAP bundle remains protected for r430/r431 dumps; r409 symbols remain protected for earlier unresolved dumps.
- `build-xpp-seeded`: 7,354,916,122 allocated bytes (14,892,036,516 logical); retained for incremental builds.
- `iso/local-analysis/logs`: 3,113,447,292 allocated bytes; includes sparse save images and historical evidence, so not a text-log-only cleanup target.
- Extracted game files: 1,800,138,464 allocated bytes; canonical generated source: 155,890,474 allocated bytes.
- r368 save root: 5,422,148,542 logical bytes but 110,715,000 allocated bytes. It was reused without copying or hard-linking; `UserData` remained empty after r431. The run updated `Cache/COPYCHECK.DAT` (76 bytes), which remains preserved.
- The warm compiler/build cache was not purged; no build ran, so build efficiency is unchanged.

## Deferred candidates and retention

Three duplicate ZIPs previously hash-verified against retained copies account for 976,265,216 allocated bytes, but an earlier deletion attempt was rejected by automatic file-action review. They remain in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`; no alternate deletion path was used. Keep the current exact executable/symbol bundles until associated unresolved dumps are resolved.

r430/r431 text files are retained losslessly as `.gz`; their per-file mapping and source hashes are in the compression CSV. Each run also retains its dump, frame, limited failure-history captures, manifest, and compressed trace records. Both run budgets were 64 MiB; neither hit its storage budget, trace cap, or relay-drop limit. New closed-run captures remain bounded by the runner's four-image history.

## Next storage check

Rerun the full allocated/logical inventory after the status documents are finalized. Continue prioritizing verified old capture duplication and reproducible inactive output bundles before compiler caches. Do not count moving files to another C: folder as reclaimed capacity.
