# Current storage and retention manifest — r421 — 2026-10-30

## Current measurement basis

The last complete workspace inventory is the r419 post-push scan: **41,833,223,267 allocated bytes** including 13 separately counted reparse entries, and **1,397,954,975,965 logical bytes** across ordinary files. The r420 and r421 closed-run directories have since been measured separately with `GetCompressedFileSizeW`, which reports allocated bytes independently of logical length. Adding those two measured directories gives a derived pre-documentation estimate of **41,836,726,142 allocated bytes** and **1,397,968,658,785 ordinary-file logical bytes**. This is a derived update, not a new full-tree rescan.

## New closed-run evidence

| Run | Files | Logical bytes | Allocated before compression | Allocated after | Reclaimed |
| --- | ---: | ---: | ---: | ---: | ---: |
| r420 `m3-dsound-link-writer-r420-20261030` | 13 | 4,499,730 | 2,027,411 | 1,150,966 | **876,445** |
| r421 `m3-campaign-branch-and-list-watch-r421-20261030` | 18 | 9,183,090 | 4,406,325 | 2,351,909 | **2,054,416** |
| **Total** | 31 | 13,682,820 | 6,433,736 | 3,502,875 | **2,930,861** |

Both runs were closed before NTFS compression. Every file length and SHA-256 hash was checked before and after; all 31 files matched. Compression is lossless. r421's 64 MiB diagnostic storage budget did not trigger; it retained five captures within an eight-image history, with zero evictions and zero dropped frames. Trace caps and relay-drop counters were zero. The run manifest reports `RunStorageAllocatedBytesAtExit=-1`, so allocated size above is the direct post-close measurement, not the runtime estimate.

Combined with r416–r419's previously verified 1,628,069 bytes saved, r416–r421 closed-evidence compression has reclaimed **4,558,930 allocated bytes**. No source, generated code, save, ISO, symbol bundle, or build cache was deleted or moved in this update.

## Retained working set

- Original ISO and unique save data remain protected. r420/r421 reused the existing r368 save root without copying or hard-linking it.
- The exact r409 EXE/PDB/MAP bundle remains required by unresolved r419/r420/r421 traces and is retained with each run manifest.
- Warm incremental build cache remains **7,136,856,349 allocated bytes**. No build ran and the cache was not purged, preserving incremental-build efficiency.
- Canonical generated source, dirty source checkouts, manually edited generated files, licenses, and the original ISO remain untouched.
- Other chats' read-only dump-analysis processes were left untouched. The only stopped game process was r421 diagnostic PID 9324, stopped by its configured watchdog after 120 seconds without a DCF4 wait return.

## Cleanup decision and next audit

This update reclaimed allocated space by losslessly compressing closed evidence. It also revalidated three quarantined ZIP copies in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`: each candidate SHA-256 matches a retained copy in the project; `fsutil hardlink list` showed one path per file; the current source/config reference scan found only historical audit notes. Together they account for **976,265,216 allocated bytes** (569,032,704 + 203,616,256 + 203,616,256) that could be reclaimed without losing unique contents. Current hashes and paths are in [the r421 archive revalidation CSV](r421-archive-duplicate-revalidation-20261030.csv).

Deletion was attempted only after the user explicitly asked to reclaim verified duplicates. The automatic file-action review rejected that exact deletion command as “blocked by policy”; no files were removed, and a read-only recheck confirmed all three candidate and keeper hashes still match. This 976 MB remains in the current derived footprint. No alternate deletion route was used. The title-stage DCF4 hang also stopped r420/r421 before the DirectSound failure or later loader stage. Keep historical builds, captures, saves, exact symbol bundles, and the hot compiler cache until a fresh inventory and reference/reproducibility audit supports any further action.

The workspace total remains derived from the r419 full scan plus the measured r420/r421 run folders and current docs. Use the next complete tree scan to refresh it.

Detailed runtime findings: [r420–r421 title wait report](m3-r420-r421-title-dcf4-and-storage-20261030.md). Current index: [CURRENT_STATUS.md](CURRENT_STATUS.md).
