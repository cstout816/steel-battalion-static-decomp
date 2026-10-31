# Current cleanup manifest — 2026-10-30 (r472)

## Current allocated and logical storage

- Fresh read-only whole-workspace scan after r472: 79,375 files; **39,810,510,383 allocated bytes (37.076 GiB)**; **1,399,640,834,790 logical bytes (1,303.517 GiB)**; zero allocation-query failures. The scan skips reparse points according to the existing scanner policy.
- This is a path-summed allocation measure; logical sparse-file lengths are reported separately and are not disk consumption.
- r472 run tree: 16 files; 9,829,996 logical bytes; **3,606,351 allocated bytes (3.44 MiB)**. Retained as unique screen-route, callback, invalid DirectSound node, exact-bundle dump, and failure-window evidence.
- No files were deleted or moved. **Actual storage reclaimed: 0 bytes.** The whole-workspace result is the retained working-set size after this run.

## Process and working-set protection

- r472 PID 28876 was the diagnostic process started for this run. Its fatal-exception watchdog verified its executable path and stopped only that process at `2026-10-31T01:12:44.689Z`.
- The post-run process query found no `your_game_recomp`, `xboxrecomp`, or `ProducerTrace` process. No other game or chat's process was interrupted.
- r472 reused the existing empty-pilot save root; it created no save copy and did not hard-link writable save files.
- Exact EXE/PDB/MAP and generated-source hashes, plus run environment and trace flags, are retained in `iso/local-analysis/logs/m3-title-screen-gated-route-r472-20261030/run-manifest.json`.

## Retention and cleanup decisions

- Preserve r472's `exception-stall.dmp`, `stderr.log`, `wait-trace.log`, `file-open-target.log`, `file-lifecycle.log`, `file-read.log`, `run-manifest.json`, `trace-counts.txt`, `pad-live.txt`, `frame.bmp`, and the three lossless `frame-history` captures. Together these establish the visible input route and the separate DirectSound crash; none is a verified duplicate.
- Preserve the original ISO, unique/mutable saves, dirty source checkouts, manually edited generated code, licenses, warm incremental build cache, and exact symbols for unresolved reports.
- Do not retry the earlier rejected closed-log compression/replacement or 534 screenshot-deletion actions through another path. Do not remove or compact files merely because their directory names appear historical. No further cleanup candidate was validated in this pass.
- Diagnostic retention remains capped: r472 configured a 64 MiB trace budget and four-frame history. The actual run tree used 3.44 MiB allocated. Trace counters report 3 saved captures, one capture skipped because the frame changed during sampling, and zero listed per-probe cap hits. Build cache was not touched; build-efficiency impact is unchanged.

## Next storage action

Keep this measurement as the current baseline. Any future removal must be a new, non-rejected candidate with current path, allocated bytes, retained-copy hash, reference scan, and reproducibility evidence recorded before action. Do not count same-drive moves as reclaimed space or copy sparse assets densely.
