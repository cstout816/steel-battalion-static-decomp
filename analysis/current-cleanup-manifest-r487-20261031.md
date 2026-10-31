# Current cleanup manifest — r487 (2026-10-31)

## Fresh allocated and logical measurements

Read-only inventory after closing the diagnostic, compressing closed logs, and committing the r487 reports:

- 79,624 files; **39,839,312,579 allocated bytes (37.103 GiB)**.
- **1,399,720,949,217 logical bytes (1,303.592 GiB)**.
- 0 allocation-query failures; 13 reparse entries skipped.
- Top-level allocation: `local-tools` 20,107,703,406 bytes (18.727 GiB); `iso` 19,493,001,093 bytes (18.154 GiB); `.git` 107,135,439 bytes. All remaining roots, excluding those three, account for about 0.122 GiB.
- Inventory CSV: `C:\Project\sb-inventory-r487-postpush-20261031.csv` (outside the project; 15,285,063 logical bytes, 3,964,928 bytes stored after lossless NTFS compression). Earlier snapshots remain at `C:\Project\sb-inventory-r487-post-compression-20261031.csv` and `C:\Project\sb-inventory-r487-final-20261031.csv`.

The path scan uses `GetCompressedFileSizeW` for allocated size and ordinary file length for logical size. It is a path-summed measurement, not a volume-level deduplication claim. Of 1,571 `.img` files, 818,757,120 bytes (about 0.763 GiB) are allocated while 1,335,756,021,248 bytes (about 1,244.23 GiB) are logical sparse length. The original ISO is about 7.288 GiB allocated. The logical-size figure is not actual disk occupancy.

## Retained working set and safeguards

- Original ISO and extracted user game files: preserved; not modified.
- Saves: unique and route-specific saves, sparse partition images, and `saves-m3-known-save-copy-20261023` preserved. r487 reused its save root in place, without copying or hard-linking writable files.
- Sources and analysis: dirty source checkouts, manually edited generated source, licenses, Ghidra workspaces, and the Xbox ordinal/signature archive preserved.
- Build efficiency: canonical generated-source tree and warm incremental build cache preserved. The r461 AOT executable/PDB/MAP bundle remains for unresolved run evidence; r150/r151/r153 exact bundles remain as required by earlier unresolved dumps; `build-guestlock-s50-current` remains the rollback bundle.
- Process protection: no other Steel Battalion game process was found during the r487 launch; only our own PID 12800 diagnostic was stopped after its black screen and stationary telemetry. Game Input Windows services were left alone.
- Previous review established two byte-equivalent Ghidra 12.1.4 extracted trees, about 909,406,125 allocated bytes each. Their recursive removal was blocked by automatic file policy. This pass did not repeat that operation or use an alternate route. The two Ghidra ZIPs have different SHA-256 values and are not duplicates.

## Space reclaimed and retained size

- Lossless NTFS compression was applied to previously uncompressed closed `.log`, `.txt`, `.json`, `.bmp`, and `.png` files under `iso\local-analysis\logs`. Sparse `.img` files and build outputs were excluded. The path-summed `logs` subtree fell from 8,134,313,279 to 8,131,093,268 allocated bytes: **3,220,011 bytes (about 3.07 MiB) reclaimed**, after accounting for the newly retained r487 black-frame image.
- r487's completed evidence tree contains 18 files, 20,325,989 logical bytes, and 5,757,499 allocated bytes. Its four-frame lossless history and exact-bundle dump remain. Closed log and screenshot files are individually compressed; the logs directory itself is not marked compressed, so future files do not automatically inherit the setting.
- One unrelated 1,711,782-byte dump of the PowerShell shell was removed after confirming it was not a game-process dump. The correctly matched game dump was then captured and retained.
- Compared with the pre-r487 workspace scan (39,836,630,299 allocated bytes), the latest post-push workspace is **2,682,280 bytes larger net**. New r487 evidence and its report are retained; this net growth includes that evidence after the log compression. Do not report the 3,220,011-byte compression saving as a net project shrink.
- Warm compiler/Cargo caches and source outputs were not trimmed, so incremental build efficiency is unchanged. No build was run.
- Outside the workspace, a prior recursive `/C /S` pass losslessly compressed CSV/TXT artifacts under `C:\Project`; the current read-only `compact /Q /S C:\Project *.csv *.txt` inventory reports 823 matching files, 1,876,438,439 bytes of logical data, and 483,093,231 bytes stored. The current difference is 1,393,345,208 bytes versus dense logical lengths; this is not a before/after measurement of volume free space. Directories report that new files will not be compressed, so the pass did not set inherited compression for later files. The newly generated workspace inventory CSV was individually compressed. No project source, game assets, build outputs, or save images were included in this compression.

## Limits and future cleanup candidates

- No old build tree was deleted: required EXE/PDB/MAP bundles and the active canonical build/cache roles have not been reconciled file-by-file against every unresolved dump. Keep these measured as candidates until that reference audit is complete.
- The two Ghidra extracted trees remain because the prior recursive removal was policy-blocked. Do not bypass that block.
- The large extracted game media and original ISO are user-supplied copyrighted data; preserve them and do not commit them.
- The current aggregate diagnostic target remains 64 MiB per run, with explicit row caps, a 32,768-line asynchronous relay queue, four retained failure-window frames, and drop/cap counters. r487 produced about 20.3 MB logical evidence; the open-target trace hit its 2,048 cap once. Preserve cap markers and failure windows rather than extending first-N logs without bounds.

## Latest post-push storage delta

The post-push path inventory is **42,712 allocated bytes** larger than the prior exact scan (39,839,269,867 → 39,839,312,579), reflecting documentation and repository metadata additions. The workspace is **2,682,280 bytes net larger than the pre-r487 scan**. The measured 3,220,011-byte log compression remains a within-tree path-summed reduction, not the project-wide net. No old builds or warm caches were removed; build efficiency is preserved. Retained current diagnostic working set: r487's 18 evidence files (20,325,989 logical / 5,757,499 allocated bytes), exact r461 EXE/PDB/MAP, matching dump, and the existing save tree. The four-frame retained history ends before the final Rookie confirmation; the black-stall image and live `NOW LOADING` observation are documented.

## Repeatable accounting

`tools/Measure-WorkspaceInventory.ps1` generated the outside-workspace inventory CSVs cited above. Measurements distinguish sparse logical lengths from allocated bytes. Re-run after project changes; do not infer savings from filenames, old manifests, or same-drive moves. Never hard-link writable saves. Compress only closed trace/screenshot formats losslessly; do not compress or compact the ISO, sparse saves, canonical build cache, or active files.
