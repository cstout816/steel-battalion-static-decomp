# Current cleanup manifest — r482 (2026-10-30)

## Measurement

Fresh read-only full-workspace scan after r482 and all current documents: 79,516 files; **39,826,663,835 bytes allocated (37.091 GiB)**; **1,399,680,036,456 logical bytes (1,303.554 GiB)**; 13 reparse entries skipped. C: free at the post-scan check: 45,498,454,016 bytes. The prior r472 baseline was 39,810,510,383 allocated bytes, so the current path-summed size is up 16,153,452 bytes. Logical sparse-file lengths are reported separately and do not represent disk use.

## Protected and new artifacts

The r476–r482 run trees together contain **78 files, 9,085,252 allocated bytes, and 18,846,421 logical bytes**. Per-run allocation from the same scan: r476 1,665,226; r477 31,775; r478 295,045; r479 1,315,106; r480 1,900,403; r481 1,980,882; r482 1,896,815 bytes.

Preserve the original ISO/assets, unique/mutable saves, dirty checkouts, manually edited generated files, licenses, canonical generated source, warm incremental build cache, and exact EXE/PDB/MAP bundles for unresolved dumps. r476–r482 all reused the same existing empty new-pilot save directory; no copy or writable hard link was created. No D: project tree was moved.

| Run | Identity and retained reason |
|---|---|
| r476 | Early title input and DirectSound trace |
| r477 | Startup control with MMIO watch |
| r478 | Startup control and exact native dump |
| r479 | Visible Campaign route and malformed DirectSound list at crash |
| r480 | First nine watched DirectSound link writes and title wait dump |
| r481 | No-edge title control, recurring DCF4 samples, matching dump |
| r482 | Verified XID/guest input route, DCF4 callback/queue/wait traces, DirectSound watch, black-stage dump |

The r482 callback stream had 325 callback rows, 323 gate rows, 434 outer-loop samples, 321 raster-sync samples, and 48 DMA publish rows. Callback and gate cap markers were zero. Its wait log recorded the first 16 plus sample 64 and matching return sample 64; it does not log every wait/return. Relay reported zero dropped stdout/stderr lines. The 60-second watchdog stack dump is a register/stack snapshot; only the separately captured minidump's native unwind is called an unwind.

## Cleanup outcome

- Actual allocated space reclaimed this pass: **0 bytes**.
- No image, save, ISO, build cache, source checkout, log, screenshot, or dump was deleted, moved, compressed, or compacted. Prior file deletion/log compression actions had been rejected and were not retried.
- Build cache unchanged; incremental build-efficiency impact: none. No build ran.
- Future cleanup must establish exact duplicate content, references, retention value, and allocation before action; sparse logical length is not disk use. Keep trace caps and failure-window capture bounded.