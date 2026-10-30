# Current cleanup and retention manifest — r401, 2026-10-30

## Measured size

Inventory and skipped-path list are stored outside the repository as `sb-inventory-current-r401-final3-20261030.csv` and `.skipped.txt`.

| Measurement | Bytes | GiB |
|---|---:|---:|
| Ordinary files, allocated | 41,498,777,888 | 38.65 |
| 13 executable reparse paths, allocated separately | 165,381,632 | 0.15 |
| **Combined allocated** | **41,664,159,520** | **38.803** |
| Ordinary files, logical lengths | 1,397,464,756,894 | 1,301.49 |

The logical total includes sparse files whose logical length is not allocated disk usage. Reparse paths were skipped by the main inventory and measured separately. No path was moved to another drive as a claimed space saving.

## Space reclaimed in this pass

Lossless NTFS compression only; hashes and logical lengths were verified unchanged.

| Closed artifacts | Allocated bytes saved | Handling |
|---|---:|---|
| Four misrouted r399 build outputs | 78,582,976 | Retained, compressed in `iso/local-analysis/delete-later/r399-relative-msbuild-output` |
| Closed r397, r398, r400, r401 evidence | 1,656,138 | Retained, compressed with run EXE/symbols, dumps, logs, and captures |
| **Total reclaimed** | **80,239,114** | No files deleted |

The r399 four-file group had 129,180,864 allocated bytes before compression and 50,597,888 after. The historical cache-copy deletion attempt was blocked by automatic execution review (“blocked by policy”); it did not execute. Its 22 source-matched candidates remain in place, and no deletion saving is counted.

## Retained working set

- Original ISO, extracted user game data, saves, and all unique partition-image data: retained.
- Canonical generated AOT source and hand-edited generated source: retained. No proprietary generated source was added to a patch or committed.
- Warm seeded build tree: **6,991,569,062 allocated bytes** (2,217 files; 14,041,952,252 logical bytes). Preserved for incremental build efficiency.
- r399 candidate run bundle: retained with exact matching EXE/PDB/MAP needed for r400/r401 diagnostics. Bundle hashes are in the run manifests and `m3-r400-r401-first-blocker-followup-20261030.md`.
- r400 crash dump and logs; r401 live snapshot, watch log, and traces: retained under their closed run folders.
- Dirty XboxRecomp source checkout and pre-existing edits: retained. The new APU invalid-voice bounds guard remains source-only change in the dirty checkout; AOT generated source was not regenerated.
- A compact runtime-source diff for `src/apu/apu_vp.c` and its base/hash information are retained in [r401 source preservation manifest](r401-source-preservation-manifest.md) and `preservation-apu-vp-r401.patch`. No proprietary generated game source is included.
- r397/r398/r400/r401 screenshot/evidence history: retained losslessly compressed. Existing screenshot and run-retention caps remain in force.
- Rust/Cargo caches, compiler caches, and sparse saves: not purged, copied, or compacted with dense copies.

## Storage-growth controls and observed impact

The producer-trace launcher continues to enforce a measured **64 MiB per-run diagnostic budget**, with a reserved failure-evidence portion, bounded asynchronous relay, cap/drop counters, and compression of closed logs. The r400 and r401 run folders remained well below the run budget; trace relay drops were zero. Existing first-N/sampled wait records did not reveal r401's later terminal wait state, so the next DCF4 or failure-window trace should preserve a bounded tail around an actual reproduced failure rather than raising global log limits.

The r399 candidate build took about 6.5 seconds and emitted no warnings. The warm build tree remains intact at 6.99 GB allocated. No fresh build was needed for r400/r401. Storage work did not alter AOT execution, guest fences, controller mapping, or rasterizer `1ea1871`.

## Disposition

No content was deleted or moved in this cleanup pass. Only verified closed artifacts were losslessly compressed in place. Preserve all entries above. The blocked duplicate deletion should not be retried through another shell or API; if it is needed later, use an approved cleanup path after an explicit review decision.
