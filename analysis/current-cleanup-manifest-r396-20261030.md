# Current cleanup manifest — 2026-10-30, r396

## Measurement basis

The latest complete inventory is `C:\Project\sb-inventory-current-r393-20261030.csv`, reconciled against the post-r395 workspace deltas in `analysis/current-cleanup-manifest-r395-20261030.csv`. The r393 total was **41,527,779,219 allocated bytes** (38.67 GiB) and **1,397,127,080,506 logical bytes**, including 13 executable reparse entries measured separately. The post-r395 reconciled snapshot was **41,530,214,478 allocated / 1,397,129,405,249 logical bytes**.

Exact additions after that snapshot:

| Addition | Logical bytes | Allocated bytes | Handling |
|---|---:|---:|---|
| r396 diagnostic folder, 20 files | 12,011,389 | 4,488,397 | Retained; closed evidence compressed by the runner; dumps and four bounded screenshots preserved |
| `local-tools/GuestWriteBreakpoint.exe` | 166,912 | 166,912 | Retained local helper built from existing source |
| `analysis/r396-redundant-cache-audit-20261030.csv` | 7,911 | 7,911 | Retained audit of exact reproducible cache copies |

Final inventory after the r396 status/report files: **77,689 ordinary files, 41,369,304,906 allocated bytes, and 1,397,141,523,641 logical bytes**. The 13 skipped Rust toolchain executable reparse entries have zero logical length and **165,381,632 allocated bytes** measured at their paths. Comparable combined total: **41,534,686,538 allocated bytes (38.68 GiB)** and **1,397,141,523,641 logical bytes**. The inventory CSV and skipped-entry list are at `%TEMP%\sb-inventory-current-r396-final-20261030.csv` and its `.skipped.txt` companion. Logical bytes include sparse-file capacity and are not occupied disk.

## Verified savings and candidates

- Closed r394/r395 evidence compression and duplicate handling reclaimed **5,021,696 allocated bytes**. Per-file verification and the earlier baseline are recorded in `analysis/current-cleanup-manifest-r395-20261030.csv`.
- The final measured total is 4,472,060 allocated bytes above the post-r395 reconciled snapshot. This net inventory delta is not a cleanup saving; it is 191,160 bytes below the prior additive estimate because that estimate preceded the final path scan.
- r396 directory size at exit was reported by the runner as 12,002,591 logical bytes; the finalized folder measured 12,011,389 logical / 4,488,397 allocated bytes using `GetCompressedFileSizeW`. The r396 64 MiB budget did not trigger, no async-relay drops occurred, and no trace cap was hit. Frame history kept four lossless captures, evicted 26, dropped 2 while frames changed, and retained the final `NOW LOADING` image.
- `analysis/r396-redundant-cache-audit-20261030.csv` identifies 22 cache files in the closed r20261022/r20261023 runs with SHA-256 and length equal to retained extracted-media sources, one hard-link path per file. They represent **178,721,934 logical / 143,407,758 allocated bytes**. The automatic execution review rejected the removal command. **No files were removed and no savings are claimed for these candidates.** Partition images, TitleData saves, original ISO/media, generated source, and warm build cache remain untouched.
- The r396 guest framebuffer `frame.bmp` and `frame-history/capture-0030.bmp` are exact duplicates by SHA-256 `68F412055E78714112013C5936556AD6CCDA0BCBD235D6A9277C652827D0F08E`; `frame.bmp` occupies 16,384 allocated bytes. Both paths remain because the history path is recorded as the final capture and the configured dump path is recorded in the run environment/logs.

## Preserved working set

- Warm `local-tools/steel-battalion-game/build-xpp-seeded`: **6,918,921,034 allocated bytes**. Retained for incremental builds; no game rebuild ran and the last historical incremental build was about 9.1 seconds.
- Canonical generated AOT source and dirty source checkouts: preserved. No proprietary generated code was committed or changed.
- r368 save root `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`: reused without cloning or hard-linking. It was not altered after r396 exited. Partition image timestamps moved to process start and `Cache\\COPYCHECK.DAT` changed during the run; content hashes were not captured pre-run, so unchanged contents are not asserted.
- Exact r367 AOT EXE/PDB/MAP and the r396 loading/DCF4 dumps remain together in the run evidence. No original game file was changed.

## Next storage pass

The largest verified reproducible candidates are the 22 closed-run cache files in the CSV above. Removing them would reclaim up to their measured 143,407,758 allocated bytes while keeping source media and saves, but the automatic execution review denied the removal action in this session. No removal was performed and no corresponding saving is included in the total. The current cleanup manifest remains a measured inventory and audit trail; it does not treat denied operations as savings.
