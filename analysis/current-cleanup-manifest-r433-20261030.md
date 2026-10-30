# Current cleanup and storage manifest — r433 — 2026-10-30

## Measurement

Fresh inventory: `C:\Project\sb-inventory-current-r433-20261030.csv` and `.skipped.txt`. It records ordinary-file allocation of 41,972,119,146 bytes and logical size of 1,398,626,450,106 bytes. Thirteen Rust toolchain reparse entries add 165,381,632 allocated bytes. Total current allocation is **42,137,500,778 bytes (39.2436 GiB)**.

The r433 run retained 18 files / 10,331,877 logical bytes / **2,708,360 allocated bytes**. The 4 retained BMP captures are lossless; their final black frame is `frame-history/capture-0006.bmp`. All closed logs remain bounded. Run-storage guard was 64 MiB and did not trigger. Frame history cap was 4 (6 captures saved, 2 evicted, 1 dropped while sampling); relay drop count was zero.

Compared with r432's inventory, net workspace allocation is +2,606,309 bytes. This is lower than the r433 run's allocated total because unrelated transient files disappeared between scans. No file deletion or compression was performed this pass; cleanup savings: **0 bytes**.

## Retained working set

| Area | Allocated | Logical | Decision |
|---|---:|---:|---|
| `local-tools/steel-battalion-game/build-xpp-seeded` | 7,354,916,122 | 14,892,036,516 | Keep warm for incremental builds |
| Canonical generated AOT source | 155,890,474 | 155,890,474 | Keep; r433 source hashes match run manifest |
| r368 route save root | 952,898,778 | 5,422,128,858 | Keep all 29 files; paths and lengths match r432 |
| `iso/local-analysis/logs` | 9,551,253,493 | 1,312,826,374,845 | Keep unresolved evidence; no blanket cleanup |
| r433 run folder | 2,708,360 | 10,331,877 | Keep report, compact dump, logs, route and final frame |

No build or cache purge ran. The incremental build working set and expected build efficiency are unchanged. Do not hardlink writable saves or densify sparse images.

## Deferred verified duplicates

Three duplicate tool ZIP candidates total 976,265,216 allocated bytes and remain pending. Their SHA-256 values and keeper paths are recorded in `current-cleanup-manifest-r432-20261030.md`. The exact-path removal attempt was blocked by policy; no files were removed and no alternate deletion method was used. Actual savings remain 0 bytes.

## Current diagnostic constraints

Keep the r426 EXE/PDB/MAP bundle with r432/r433 unresolved dumps. r433's watchdog owner snapshot was scheduled at 720 seconds but its own NV2A watchdog stopped the diagnostic at 600 seconds, explaining the absent watchdog snapshot. `[SB-SNAPSHOT]` is instead the guest controller-copy marker and was absent because `sub_00048890` did not execute. If repeating, schedule the owner snapshot before the progress-stop threshold. Preserve the save root, AOT inputs, source checkouts, licenses, and all exact dump/symbol bundles.
