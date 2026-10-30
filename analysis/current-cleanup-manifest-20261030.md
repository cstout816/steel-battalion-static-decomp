# Current cleanup and storage manifest — 2026-10-30

## Current allocated size

Workspace inventory: **77,402 ordinary files**, **41,312,184,180 bytes allocated** and **1,396,896,367,723 bytes logical**. Thirteen Rust-toolchain reparse entries were excluded from the CSV walk and separately measured at **165,381,632 allocated bytes**. Combined workspace size is **41,477,565,812 bytes allocated (38.629 GiB)** and **1,396,896,367,723 logical bytes (about 1,300.961 GiB)**. The inventory reported no allocation-query failures. Logical sparse-file lengths are not disk usage.

The latest CSV and skipped-path list are kept locally outside the repository. The path-level scan covers the working tree; it does not include the separate delete-later archive below.

| Working-set area | Allocated | Logical |
| --- | ---: | ---: |
| `local-tools` | 19.50 GiB | 277.41 GiB |
| `iso` | 18.76 GiB | 1,023.32 GiB |
| Warm `build-xpp-seeded` cache | 6,918,921,034 B | 13,871,927,762 B |
| Canonical generated AOT source | 155,887,568 B | 155,887,568 B |
| r368 route saves | 110,700,940 B | 5,422,134,482 B |
| Logs | 2,996,373,183 B | 1,035,968,311,324 B |

The 13 reparse entries are Rust-toolchain executables; they were measured separately and included in the combined allocated total. The workspace grew about 14.1 MB in allocated space versus the prior r373 scan; no build cache purge or file deletion occurred during r375.

## r375 evidence

`m3-surface-overlap-route-r375-20261030` is closed and consumes **9,128,795 allocated / 31,287,784 logical bytes**. It was already NTFS-compressed; a before/after hash check on all 19 files showed **0 bytes** reclaimed and 0 mismatches. The run is retained because it preserves the new-pilot route, bounded DirectSound write/surface traces, and post-difficulty loading plateau evidence.

## Verified duplicate candidates

The separate `C:\Project\SteelBattalion-Delete-Later-20261026` archive uses **1,329,496,337 allocated / 2,092,257,079 logical bytes**. The hash audit verified all 274 listed duplicate candidates against retained same-run screenshots or identical tool archives: **983,048,192 allocated bytes** are duplicates. Two screenshot filenames also appear in reports for different runs and remain in the archive conservatively. The 104 inactive diagnostic build artifacts remain untouched because their exact unresolved dump/symbol references have not been cleared.

Automatic file-action review rejected the exact-path delete operation before any file was removed. Therefore realized space savings from deletion are **0 bytes**. No alternate deletion method was used. Full local path/hash checks: `r375-duplicate-delete-validation-20261030.csv`; conservative basename-reference scan: `r375-duplicate-reference-scan-20261030.csv`.

## Build efficiency and protected items

The warm build cache, canonical generated AOT source, dirty source checkouts, ISO, user saves, licenses, and r367 EXE/PDB/MAP bundle were preserved. No build ran; build efficiency is unchanged, with the last measured warm incremental build at about 9.1 seconds. No hard-linked or dense copies of save images were created.

Latest runtime/storage evidence: [r374–r375 follow-up](m3-r374-r375-loading-and-storage-20261030.md). First mission frame remains unverified.
