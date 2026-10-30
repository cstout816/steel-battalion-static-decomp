# Current storage and retention manifest — r418 — 2026-10-30

## Measurement basis

The latest full-tree scan is the r416 post-push inventory at `C:\Project\sb-inventory-postpush-r416-20261030.csv`: 78,157 ordinary files, 41,662,826,328 allocated bytes, 1,397,939,829,666 logical bytes, plus 165,381,632 allocated bytes for 13 separately measured Rust/Cargo executable reparse entries. Combined allocated baseline: 41,828,207,960 bytes / 38.956 GiB.

The r417/r418 run folders add 26 closed files: 10,355,026 logical bytes and 2,786,807 allocated bytes after compression. The new r418 report and cleanup manifest plus the updated status file increase the measured path total by 16,726 allocated/logical bytes over the post-push baseline and run folders. Current derived path-summed total: **41,831,011,493 allocated bytes / 38.958165 GiB** and **1,397,950,201,418 logical bytes / 1,301.943 GiB**, across 78,185 ordinary files plus 13 separately counted reparse entries. This total adds the full-scan baseline and exact measured file deltas; it is not a second full-tree inventory.

## Closed-run compression

| Evidence | Files | Logical bytes | Allocated before | Allocated after | Reclaimed |
| --- | ---: | ---: | ---: | ---: | ---: |
| r417 `m3-mode2-worker-branch-r417-20261030` + r418 `m3-mode2-worker-route-r418-20261030` | 26 | 10,355,026 | 3,619,748 | 2,786,807 | **832,941** |

NTFS compression is lossless. All 26 SHA-256 hashes matched before and after compression. Screenshots and the r418 minidump were retained. r418 dump SHA-256: `FB453806B307F8F1640DA71470CB5B41A32DCEEDA70245C1D861876F719E42EA`. Cumulative r416–r418 closed-evidence compression reclaimed **1,622,224 allocated bytes**. No file was deleted, moved, or deduplicated in this pass.

## Protected working set

- Original ISO, unique user files, dirty source checkouts, edited generated code, licenses, exact failure bundles, and the 64-MiB per-run diagnostic retention policy remain protected.
- Warm incremental build cache: **7,136,856,349 allocated bytes**.
- Canonical generated source: **155,890,474 bytes**.
- Existing r368 save root: **110,715,000 allocated / 5,422,148,542 logical bytes** across 36 files. It was reused without copying or hard-linking. `Cache/COPYCHECK.DAT` received a 05:46:14 CDT timestamp during r418 startup; its prior content hash was not captured. Preserve it with the rest of the save root.
- The exact r409 AOT executable/PDB/MAP bundle remains under `build-xpp-seeded/ProducerTrace-Candidates/m3-mode2-readiness-producer-consumer-r409-20261030/Release/`. Hashes: EXE `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A`, PDB `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17`, MAP `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`. It is required to interpret r415/r418 and remains protected.
- At final process inspection, another chat's read-only r414 minidump analysis was running as PID 191704. It references the r414 dump and the same r409 executable/map/symbol directory. It was left untouched. No Steel Battalion game executable remained active.

## Cleanup decisions and next storage action

No historical screenshot, save image, source checkout, generated file, cache, or symbol bundle was deleted. The r417/r418 files are closed, unique diagnostic evidence, so lossless compression was chosen. No exact duplicate removal was validated in this pass. Moving files within the same drive would not reclaim space.

The next full inventory should be taken only when a broad cleanup is planned. Preserve separate allocated and logical totals, reparse-entry counts, retained exact bundles, and the warm build cache. Keep one canonical generation and the existing per-run cap; do not rebuild or purge caches for this diagnosis.
