# Current storage and retention manifest — r419 — 2026-10-30

## Measurement basis

The latest full-tree scan remains the r416 post-push inventory: 41,828,207,960 allocated bytes / 1,397,939,829,666 logical bytes, including 13 separately measured reparse entries. The r417/r418 report's derived current total was 41,831,011,493 allocated bytes / 1,397,950,201,418 logical bytes. r419 adds 12 closed retained files: **977,238 allocated / 3,540,011 logical bytes** after lossless compression. The r419 report and manifest add 10,530 allocated/logical bytes; the status index grew by 1,135 bytes. Current derived path-summed total is **41,832,000,396 allocated bytes (38.959086 GiB)** and **1,397,953,753,094 logical bytes**, across 78,199 ordinary files plus the 13 reparse entries. This updates the r416 full-scan baseline by verified file deltas; it is not a fresh full-tree scan.

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

## Cleanup decisions

No project or save files were deleted, moved, or deduplicated. Only the closed r419 evidence was losslessly compressed. No historical executable, source tree, symbol bundle, build cache, or screenshot was removed. The build cache remains warm and unchanged. Current totals are derived from the full r416 scan plus verified additions and documentation deltas; take another full inventory before any broader cleanup.
