# Current cleanup manifest — r480 (2026-10-30)

## Inventory

Fresh scan using `tools/Measure-WorkspaceInventory.ps1`, writing the full path inventory outside the project:

- 79,479 files; 39,822,753,979 bytes allocated (37.088 GiB).
- 1,399,672,470,449 logical bytes (1,303.547 GiB). This is not disk consumption; many files are sparse.
- 13 reparse entries skipped; no allocation-query failure was reported.
- C: free at scan: 45,559,189,504 bytes.
- Previous r472 baseline: 39,810,510,383 bytes allocated. Current path-summed allocation is up 12,243,595 bytes since that baseline; this is growth, not savings.

## New run trees

| Run | Files | Allocated | Logical | Decision |
|---|---:|---:|---:|---|
| r476 `m3-dsound-writer-early-title-input-r476-20261030` | 14 | 1,665,226 B | 3,377,679 B | Retain: route and failure evidence |
| r477 `m3-dcf4-title-advance-writer-trace-r477-20261030` | 7 | 31,775 B | 43,102 B | Retain: startup control attempt |
| r478 `m3-dcf4-title-advance-writer-trace-r478-20261030` | 8 | 295,045 B | 305,342 B | Retain: matching native dump and startup control |
| r479 `m3-dcf4-title-advance-writer-trace-r479-20261030` | 10 | 1,315,106 B | 4,021,497 B | Retain: visible route, invalid list at crash, bounded trace |
| r480 `m3-dsound-link-first-writer-r480-20261030` | 13 | 1,900,403 B | 3,564,953 B | Retain: exact-bundle dump and first nine watched link writes |

The run-tree allocated totals are from `GetCompressedFileSizeW`; logical values come from file lengths. No dense copy was made of a sparse file. r480's exact EXE/PDB/MAP bundle and generated-source hash are in its run manifest.

## Protected working set

Preserve the original ISO and assets; unique and mutable saves; dirty source checkouts; manually edited generated code; license material; the canonical generated source; warm incremental build cache; and exact executable/PDB/MAP bundles needed by unresolved dumps. r480 reused the existing empty-save directory and created no save-image copy. No hard links were created for writable save data. No D: project tree was moved in this pass.

## Cleanup outcome

- Actual allocated space reclaimed: **0 bytes**.
- No verified new duplicate or reproducible inactive artifact was removed in this pass. The r476–r480 evidence is not duplicate content merely because runs share the same executable.
- Prior screenshot deletion and closed-log compression/remplacement attempts were rejected. They were not retried. Historical candidate lists and directory names alone are not proof that evidence can be discarded.
- Warm build cache untouched; build-efficiency impact: **none**.
- A full exact-path duplicate/reference audit is still needed before another cleanup operation. Keep future diagnostic captures bounded and preserve failure-window records; measure per-run allocation before and after each run.