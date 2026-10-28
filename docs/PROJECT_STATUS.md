# Steel Battalion project status

**Current milestone:** Milestone 3 — boot and compatibility. The next gameplay acceptance point is one visually verified first-mission frame.

**Progress:** overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · loader diagnosis `██░░ 2/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

## Current verified state

- AOT remains the execution path. r221/r222 followed the new-pilot route through difficulty to the post-difficulty black frame; neither verified a first mission frame.
- Latest mode-2 evidence is r222: eight loader pass records stayed at mode 2, range 2–11, index 28, `branch=scan`, result 0, and a zero pair. File-miss records did not identify a failed mission-media dependency. A validated unwind places TID 144016 in `nv2a_pgraph_notify` waiting for guest PGRAPH acknowledgement; TIDs 147112, 33648, and 148244 wait in `guest_cpu_acquire`. The exact guest CPU owner and the guest caller/ISR needed to clear the pending notification were not captured. This is a supported synchronization lead, not a proven root cause.
- r222 DMA telemetry caught PUT=GET at `0x0000DA44` before NV2A progress counters stopped. This does not support a terminal DMA backlog. DCF4 was signaled, so keep the historical title DCF4 wait separate. Earlier raster load was expensive but does not explain the terminal wait from these samples.
- r220's DirectSound invalid-list access violation is separate. r221's watched list links had zero writes; that does not explain r220's crash. r210's divide-by-zero at guest PC `0x0001EEBE` remains a separate, earlier failure hypothesis, not the latest plateau.
- The r220–r222 loop-preemption hook did not demonstrate a handoff or improve progression and has been removed; re-adding its two lines in memory reproduces the experimental source hash exactly. Its EXE/PDB/MAP bundle is retained. The hook-free source differs from the r219 source manifest by an unrelated, unexplained 18-byte length difference; do not use it to recreate a supposed historical r219 binary until reconciled.
- The r150–r153 unwind review and r205–r210 arithmetic evidence remain available as separate failure families. Current `ObReferenceObjectByHandle` completion semantics still need guest-readiness verification; the old r130 null-output issue is not a current established blocker.
- No first mission frame, complete campaign, audio correctness, or stable 60 FPS has been verified. See [r220–r222 mode-2 evidence](../analysis/m3-mode2-guestcpu-pgraph-r220-r222-20261028.md).

## Storage and retained evidence

- Before cleanup, the 2026-10-28 inventory measured about 83.67 GiB allocated (logical sparse-file lengths about 1.27 TiB). After deleting only validated duplicate captures, a fresh pre-compression scan measured about 73.5 GiB allocated; logical lengths remained about 1.26 TiB because partition images are sparse.
- Actual C: free space increased by **11,194,912,768 bytes (10.43 GiB)** after removing 12,101 exact screenshot duplicates. The 124 images without a verified keeper remain preserved. Per-file evidence is under `iso/local-analysis/cleanup-review/` in `current-cleanup-actions-20261028.csv` and `current-duplicate-validation-20261028.csv`.
- Closed BMP and LOG compression is complete and verified: 16,184 selected files are losslessly compressed in place. Allocated space fell from about 9.12 to 1.089 GiB for BMPs and from 2.69 to 0.931 GiB for logs. Current post-cleanup footprint before r211 was 63.70 GiB allocated and 1.25 TiB logical; C: has 31.76 billion bytes free. See [storage evidence](../analysis/storage-cleanup-20261028.md).
- Fresh post-r222 inventory: **68,802,021,466 bytes allocated (64.08 GiB)** and **1,378,643,373,162 bytes logical (1.25 TiB)** across 75,550 files; 13 reparse paths were skipped. Current C: free space was **31,276,126,208 bytes** at inventory capture. The r220–r222 closed logs/frame and inventory CSV were losslessly NTFS-compressed with identical SHA-256; volume free space rose by **10,821,632 bytes** during that compression pass. No duplicate saves were deleted. Machine-local CSV, skipped-path list, and cleanup manifest are in `iso/local-analysis/cleanup-review/`; cumulative cleanup details are in [storage cleanup evidence](../analysis/storage-cleanup-20261028.md).
- Repeated 0.73 GiB partition images remain unverified: a full-image hash pass was stopped after about seven minutes and created no completed manifest. The two 569 MB Ghidra ZIPs were verified different by size and SHA-256. Do not remove save images based on names or size alone.
- The run launcher now enforces 512 MiB logical evidence per run, checks every 10 seconds, captures a dump on overrun, and stops only its verified child. It records relay drops and cap/drop rows, then compresses closed BMP/LOG evidence. A rolling per-category failure window remains unimplemented.
- Compressed storage manifests and skipped-entry records are kept under `iso/local-analysis/cleanup-review/`. The first fresh post-cleanup CSV gzip is `current-storage-manifest-postcleanup-20261028.csv.gz`.

## Next action

First restore the canonical build folder from the exact baseline bundle and reconcile the 18-byte generated-source hash mismatch before rebuilding. Then use the matching AOT/PDB/MAP to capture one bounded plateau failure window with simultaneous guest CPU owner/waiters/current guest PC-ESP and the terminal PGRAPH notification arguments/ack state. Test whether the owner is the thread expected to service the pending PGRAPH interrupt. Preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`; change behavior only after the owner/producer relation is supported. Keep the run evidence below a measured cap and stop only the diagnostic child started by this task. Stop after the first visually verified mission frame.

## Authoritative reports

- [r205–r210 loader evidence](../analysis/m3-loader-r205-r210-evidence-20261028.md)
- [r220–r222 mode-2/guest CPU/PGRAPH evidence](../analysis/m3-mode2-guestcpu-pgraph-r220-r222-20261028.md)
- [r150–r153 validated unwind review](../analysis/m3-dump-unwind-review-r150-r153-20261028.md)
- [2026-10-28 storage cleanup evidence](../analysis/storage-cleanup-20261028.md)
- Historical run-by-run tracker: [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)
