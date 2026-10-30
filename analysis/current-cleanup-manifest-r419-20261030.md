# Current storage and retention manifest — r419 — 2026-10-30

## Measurement basis

The post-push full-tree scan after commit `f4adb08` measured 78,211 ordinary files at **41,667,841,635 allocated bytes / 1,397,954,975,965 logical bytes**. Thirteen separately counted reparse entries add 165,381,632 allocated bytes, for **41,833,223,267 allocated bytes (38.960225 GiB)** combined. The scan had zero unknown allocated sizes and skipped only those 13 reparse entries. This replaces the r418 derived estimate with a fresh measurement. The logical total is for ordinary files; sparse files explain the large gap from allocated space.

## Closed r419 evidence

| Files | Logical bytes | Allocated before compression | Allocated after | Reclaimed |
| ---: | ---: | ---: | ---: | ---: |
| 12 | 3,540,011 | 983,083 | 977,238 | **5,845** |

NTFS compression is lossless. The before/after length and SHA-256 checks matched for every file. The two retained framebuffer captures are `frame-history/capture-0001.bmp` (title/player-record warning) and `frame-history/capture-0002.bmp` (black terminal frame). The original log captures both the XID-to-guest edge and the DirectSound crash. No r419 minidump exists. Cumulative r416–r419 closed-evidence compression reclaimed **1,628,069 allocated bytes**.

## Protected working set

- Original ISO, unique saves, dirty source checkouts, edited generated source, licenses, exact failure bundles, and the r368 save root remain protected.
- Exact r409 EXE/PDB/MAP remain at `build-xpp-seeded/ProducerTrace-Candidates/m3-mode2-readiness-producer-consumer-r409-20261030/Release/`; hashes are recorded in [r419 report](m3-r419-input-and-dsound-crash-20261030.md).
- Warm incremental build cache remains 7,136,856,349 allocated bytes; canonical generated source was 155,890,474 bytes in the r416 measurement. No build or cache purge ran.
- r368 save root remains in place; it was reused, not copied or hard-linked.
- The other chat's read-only r414 dump analysis (PID 191704) was still active at final inspection and was left untouched. No game process remains active.
- The post-push inventory CSV and skipped-entry list were written under the system temporary directory, summarized, then removed. No workspace inventory artifact was added.

## Cleanup decisions

No project or save files were deleted, moved, or deduplicated. Only the closed r419 evidence was losslessly compressed. No historical executable, source tree, symbol bundle, build cache, or screenshot was removed. The build cache remains warm and unchanged. Current totals are derived from the full r416 scan plus verified additions and documentation deltas; take another full inventory before any broader cleanup.
