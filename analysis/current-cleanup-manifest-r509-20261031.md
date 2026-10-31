# Current cleanup and storage manifest — r509 (2026-10-31)

## Measurement

The final scan used `tools/Measure-WorkspaceInventory.ps1` and queried NTFS allocated size separately from file length. Result: **80,010 regular files; 40,025,676,898 allocated bytes (37.277 GiB); 1,402,623,196,602 logical bytes (1,306.295 GiB).** Thirteen Rust tool aliases are zero-length symbolic links to the same `rustup.exe`; the scan skipped those reparse points to avoid multiplying the target's allocation. The inventory and its skipped-entry list are at `C:\Project\sb-inventory-final-r509-20261031.csv` and `.skipped.txt`.

Relative to r505 (40,014,873,187 allocated; 1,402,584,774,300 logical), the workspace is up **10,803,711 allocated bytes (10.30 MiB)** and **38,422,302 logical bytes**. This reflects retained diagnostic/report additions; it does not represent deleted or moved data. Sparse save images explain much of the logical-versus-allocated difference.

## Closed diagnostic evidence

The r508 and r509 trees are closed and retained. Before compression they contained 28 files with 22,981,022 logical bytes and 9,259,636 allocated bytes. Lossless NTFS compression reduced allocation to 5,805,025 bytes, reclaiming **3,454,611 bytes**. Every SHA-256 remained unchanged. The per-file audit is `analysis/r508-r509-closed-evidence-compression-20261031.csv`.

| Retained component | Files | Allocated bytes | Logical bytes |
| --- | ---: | ---: | ---: |
| r508/r509 closed runs | 28 | 5,805,025 | 22,981,022 |
| Canonical generated source | 27 | 155,904,044 | 155,904,044 |
| Reused route save root | 36 | 952,918,462 | 5,422,148,542 |
| `build-xpp-seeded` | 2,257 | 7,863,535,031 | 16,082,205,888 |
| All `iso/local-analysis/logs` | 22,784 | 3,519,669,485 | 1,039,341,091,337 |

The save root was reused in place; no save image was copied, hard-linked, removed, or compressed. The canonical generated tree, active source checkouts, dirty source patches, exact EXE/PDB/MAP bundles, and hot build cache were preserved. r508/r509 use the exact r502 AOT bundle; its EXE/PDB/MAP hashes are recorded in `analysis/m3-r506-r509-stall-discrimination-20261031.md`.

## Storage-growth controls and build efficiency

Both runs had a 64 MiB storage budget, four-frame history, and asynchronous log relay capacity 32,768. Neither budget triggered; both report zero relay drops and zero trace cap hits. r508 retained 8 frames with cap 4, 4 evictions, and one sampling drop; r509 retained 2 frames with cap 4 and no drops. Screenshots remain lossless BMPs; closed logs and dumps are NTFS-compressed without content changes.

No build ran and no compiler/Cargo cache was purged. Last measured warm incremental build remains **8.2 seconds** from r502; this cleanup did not change it. A new build is not required for the next diagnostic because the needed traces are already in the r502 executable.

No files were deleted. No duplicate or reproducible artifact was removed because the current evidence did not justify removing a retained copy; the verified disk reduction came from compressing closed evidence. The inventory is a scan of the project tree; it does not count free space outside the project or allocations on other volumes.
