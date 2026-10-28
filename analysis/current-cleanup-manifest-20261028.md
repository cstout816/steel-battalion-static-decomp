# Current cleanup manifest — 2026-10-28

## Measurement

Final scan after writing this turn's evidence: **69,445,091,197 bytes allocated (64.675781 GiB)** and **1,379,346,370,436 bytes logical (1,284.616413 GiB)** across 74,960 files. Thirteen reparse paths were skipped. C: free space at scan time was **28,951,494,656 bytes (26.963 GiB)**. The detailed exact-path CSV is `C:\Project\steel-battalion-inventory-current-20261028.csv`; the scanner is `tools/Measure-WorkspaceInventory.ps1`.

Top allocated areas:

| Area | Allocated | Logical | Handling |
|---|---:|---:|---|
| `iso` | 42.27 GiB | 1,012.13 GiB | Original ISO, sparse image trees, saves, and run evidence; retain until each duplicate is content-validated. |
| `local-tools` | 22.24 GiB | 272.30 GiB | Dirty source checkouts, tool trees, caches, and exact dump bundles; retain working inputs and build efficiency. |

## Completed storage-safe actions

- Created the fresh inventory above. No original game file, save, source tree, build cache, EXE, PDB, or MAP was deleted or moved.
- Verified that `iso/local-analysis/logs` has 8,831 BMPs, 7.625 GiB logical and about 0.892 GiB allocated. A sample compression check saved zero bytes and the sample was returned to uncompressed state; blanket BMP compression was not applied.
- Verified the r232 EXE/PDB/MAP hashes listed in `m3-r234-guestcpu-suspend-report-20261028.md`; the exact bundle remains necessary for the unresolved r234 dump.
- A same-path duplicate Ghidra distribution was content-checked against the retained copy, including the differently nested extension directories. A deletion of `local-tools/analysis-deps/ghidra_12.1.4_PUBLIC` was rejected by the automatic deletion policy. No files were deleted, and the rejection was not bypassed. This duplicate is a documented candidate only; current verified reclaimed space from this pass is **0 bytes**.

## Preserve

- Original ISO and game assets; all unique or not-yet-hash-validated save images; dirty XboxRecomp and generated-source checkouts; licenses; canonical generation and incremental caches.
- The exact EXE/PDB/MAP bundles for unresolved dumps, including r149 and r232; r232 is currently linked to r234's native stack analysis.
- Closed run evidence, including sparse BMPs and dump/log bundles, until retention can be validated by references and content hashes. Do not replace sparse files with dense copies or hard-link writable saves.

## Candidates and current disposition

| Candidate | Evidence | Disposition |
|---|---|---|
| Duplicate Ghidra tree `local-tools/analysis-deps/ghidra_12.1.4_PUBLIC` | 5,264 files; matching retained Ghidra core and the extension files compare by SHA-256; no path references found in the prior audit. | Delete attempt blocked by policy. Preserved in place; do not retry through a different mechanism. |
| Closed historical screenshots | 8,831 sparse BMPs; 0.892 GiB allocated total. | Retain; compression test yielded no measurable savings. |
| Historical save images and partition trees | Paths/sizes alone do not establish duplicate identity; previous full-hash work did not complete. | Retain until a complete content-hash manifest proves redundant copies and save ownership. |
| Historical EXE/PDB/MAP bundles | Multiple bundles map to unresolved dumps and cannot be pruned by age/name. | Retain until dump-to-bundle references are reconciled. |

**Net reclaimed by this pass: 0 bytes.** Actual footprint did not grow materially; the dominant logical size is sparse-file length, while allocated size is about 64.7 GiB. Do not report logical-size reductions as freed disk space.
