# Current cleanup manifest — 2026-10-30 (r471)

This is a local measurement and retention record. No files were deleted or moved in this pass.

## Measured storage

- Latest full workspace inventory is still r466: 79,220 files; 39,799,862,841 allocated bytes (37.067 GiB); 1,399,613,305,721 logical bytes (1,303.491 GiB). Eight small Cargo allocation queries failed, so those allocations are omitted.
- r469 evidence: 1,586,019 allocated bytes (measured in its prior manifest).
- r470: 4,719,183 logical bytes; 2,162,462 allocated bytes; 18 files.
- r471: 5,188,091 logical bytes; 2,361,921 allocated bytes; 20 files.
- r470+r471: 9,907,274 logical bytes and 4,524,383 allocated bytes. Sparse/logical length is not counted as allocation.
- Approximate working set based on the r466 full scan plus r469–r471 evidence: 39,805,973,243 allocated bytes (37.072 GiB). This is an estimate, not a new full scan.
- Space reclaimed in this pass: **0 bytes**. Build cache and save files were not changed.

## Protected inputs and evidence

Keep both closed run trees: `iso/local-analysis/logs/m3-title-route-replay-r470-20261030` and `iso/local-analysis/logs/m3-title-dcf4-producer-followup-r471-20261030`. They retain the title/black frame captures, exact-bundle dumps and unwinds, input/title callback traces, DCF4 callback argument/target records, sampled waits, event/raster/DMA telemetry, manifests, and final counters. r471 uses the exact r461 AOT EXE/PDB/MAP hashes listed in its run manifest and the canonical generated source. Both runs reused `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`; no save copy or hard link was created.

Protect the ISO/game files, unique/dirty saves, dirty source checkouts, manually edited generated source, license files, the warm incremental build tree, and exact executable/symbol bundles required for unresolved dumps. Do not infer that sparse assets consume their logical lengths in allocated space. No D: project directory was found in the prior scan.

## Retention and cleanup actions

- r470/r471 each used a 64 MiB diagnostic budget and bounded frame-history cap of four. r471's asynchronous relay queue held 32,768 lines; stdout/stderr drops and trace-limit hits were zero. It retained two lossless screenshots and one minidump. The current 16-entry DCF4 wait sample is bounded; retain it with producer and callback traces.
- A proposed lossless gzip-and-replace action for closed r470/r471 `.log` files was rejected by automatic file-action review. No raw trace was removed, replaced, or compressed. Do not work around that rejection through another deletion path.
- The earlier review rejection of 534 screenshot deletion candidates remains in force. Do not retry those exact deletions.
- Do not prune Cargo/compiler caches: preserving warm incremental build efficiency takes priority until a validated candidate and safe approval clear that action. No AOT build ran; build-efficiency impact is unchanged.

## Next storage action

Use a fresh allocated/logical inventory only when a cleanup decision is ready. For each proposed artifact, validate its hash against a retained copy, search source/config/report references, verify reproducibility or uniqueness, and measure allocated bytes before acting. Preserve evidence for unresolved failures and never densify sparse files or hard-link writable saves.
