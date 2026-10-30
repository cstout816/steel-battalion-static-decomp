# Current cleanup manifest — r410, 2026-10-30

## Current measurement

Inventory: `C:\Project\sb-inventory-current-r410-final-20261030.csv` and `.skipped.txt`.

| Scope | Allocated bytes | Logical bytes |
|---|---:|---:|
| Workspace ordinary files | 41,649,335,590 | 1,397,880,810,882 |
| 13 Rust/Cargo reparse executable entries | 165,381,632 | 0 reported |
| **Combined** | **41,814,717,222 (38.94 GiB)** | **1,397,880,810,882** |

Sparse partition image logical length is not allocated disk use.

## This pass

| Action | Files | Allocated bytes recovered | Verification |
|---|---:|---:|---|
| Lossless NTFS compression of closed r410 logs, screenshots, and dump | 23 | 887,624 | All 23 SHA-256 hashes unchanged |
| Lossless NTFS compression of 13 older closed logs/dumps | 13 | 11,046,834 | All 13 SHA-256 hashes unchanged; report `r410-older-closed-evidence-compression-20261030.csv` |
| **Total** | **36** | **11,934,458** | No evidence content changed |
| Remove old tool archive duplicates | 0 | 0 | Review rejected removal before execution; sources remain |

The 64 MiB run storage cap, bounded asynchronous relay, eight retained screenshots, and cap/drop counters remain active. r410 used 13,392,989 logical bytes of run evidence, stayed under the cap, and had zero stdout/stderr relay drops. Its 128-entry thread-suspend trace did hit its cap; see the run's `trace-counts.txt`.

## Verified duplicate archives, retained in place

All current source and retained-copy hashes match the prior duplicate manifest. The three source files total 976,265,216 allocated bytes by the current NTFS-size query. The automatic file-action review rejected removing them before any file was changed.

| Source | Retained exact copy | SHA-256 | Allocated bytes |
|---|---|---|---:|
| `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives\ghidra_12.1.4_PUBLIC_20260921.zip` | `local-tools\reverse-engineering\ghidra.zip` | `DDAC49F903DA9D5BAC833E5CC79395098B9C33CFD3279BE5F31BD00387D2D4DB` | 569,032,704 |
| `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives\jdk21-duplicate-reverse-engineering.zip` | `local-tools\analysis-deps\downloads\OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip` | `F9D6E191AB098C0D416E7D588A24420A8621CD2F4720DAB2459B8B7B2D2D8B4E` | 203,616,256 |
| `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives\temurin21-duplicate-ghidra-analysis.zip` | Same retained JDK archive above | `F9D6E191AB098C0D416E7D588A24420A8621CD2F4720DAB2459B8B7B2D2D8B4E` | 203,616,256 |

Hash checks: `r410-archive-duplicate-current-hash-check-20261030.csv`. Bounded text reference scan: `r410-archive-duplicate-reference-check-20261030.csv`. A cleanup script and an old storage report mention the Ghidra archive name; the path named by the cleanup script is not present. No deletion workaround was attempted.

## Retained working set

| Path | Allocated | Logical | Reason |
|---|---:|---:|---|
| Warm `build-xpp-seeded` tree | 7,136,856,349 | 14,381,973,554 | Preserve incremental build efficiency and exact diagnostic bundles |
| Canonical generated AOT source | 155,890,474 | 155,890,474 | Unique generated source; keep proprietary material local |
| Existing r368 save root | 110,709,376 | 5,422,142,918 | Preserve sparse saves; re-used directly, never hard-linked |
| Extracted `game_files` | 1,800,138,464 | 1,808,250,705 | User game data; untouched |
| `iso/local-analysis/logs` | 3,076,745,350 | 1,036,314,234,953 | Historical diagnostic evidence, mostly sparse/compressed |

Keep the exact r409 EXE/PDB/MAP bundle with the unresolved r410 dump. Preserve original game files, unique saves, dirty source checkouts, and the warm build cache. No hot Cargo/compiler cache was purged.

The r406 scan measured 41,746,055,330 combined allocated bytes. The current scan is 68,661,892 bytes higher after retaining the new r409 bundle and r408–r410 evidence, status records, and manifests; the 11,934,458-byte evidence compression is included. The r409 trace build rebuilt two generated chunks and linked in about 40 seconds.
