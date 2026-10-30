# Current cleanup manifest — r440 (2026-10-30)

## Measured workspace

Inventory command: `tools/Measure-WorkspaceInventory.ps1`. It records NTFS allocated bytes and logical file length separately; reparse entries are skipped and listed in the companion `.skipped.txt` file. The post-compression inventory is `C:\Project\sb-inventory-current-r440-postcompress-20261030.csv` (outside the repository).

- Ordinary files: 78,608.
- Allocated: **39,430,094,748 bytes (36.722 GiB)**.
- Logical: **1,398,720,013,505 bytes (1,302.660 GiB)**.
- Reparse entries skipped: 13.
- Difference from the r438 post-compression inventory: +4,390,900 allocated bytes.
- Run r440 added 3,453,174 allocated bytes after closed-log compression. Its small 64 MiB budget was not hit.

The large logical/allocated gap is primarily sparse save-image and analysis-image data. Do not copy sparse images densely. The warm `build-xpp-seeded` tree is 7,354,916,122 allocated bytes; preserve its incremental cache. The reused new-pilot save root is 952,907,214 allocated / 5,422,137,294 logical bytes; preserve it as a unique save root and never hard-link writable saves. The logs tree is 3,199,168,557 allocated bytes; closed logs, screenshots, dumps and the exact binary/symbol bundles needed to interpret them remain useful diagnostic evidence.

## Completed storage action

After verifying that r440's executable had stopped, NTFS lossless compression was applied to its ten closed `.log`, `.txt`, and `.json` files. Lengths and SHA-256 hashes remained unchanged. The pre-compression r440 allocation was 3,460,132 bytes; the post-compression allocation is 3,453,174 bytes. **Actual space reclaimed: 6,958 allocated bytes.** No images, dumps, saves, source, assets, licenses, build outputs, or caches were modified.

## Retain

- Original ISO, extracted game assets, and all unique save roots.
- Current generated-source tree and dirty source checkouts.
- Warm `build-xpp-seeded` cache.
- Exact r426 EXE/PDB/MAP bundle used by r440 and r432–r440 evidence.
- Exact older symbol bundles referenced by unresolved dumps, including the r149 bundle for r150/r151/r153 review.
- Lossless stage/failure screenshots, dumps, logs, and their run manifests.
- Licenses, dependency source, Ghidra data and ordinal/signature resources.

## Deferred candidates and exclusions

- Three hash-verified duplicate tool-archive candidates totaling 976,265,216 allocated bytes are described with keeper hashes and reference review in the r432 cleanup manifest. Their prior exact-path removal was blocked. No alternate deletion method was attempted in this pass.
- Historical build directories were not removed: exact dump-to-symbol requirements and references have not been audited as a complete set, and current source/build state is dirty.
- Old screenshots, save images, assets and diagnostic captures were not deleted. Directory names alone are insufficient to establish redundancy. The r440 run retained four recent framebuffer captures and two small symbol-matched dumps.
- No build or hot compiler/Cargo cache was purged. No files were moved to another drive.

## Next storage review

Before deleting any candidate, verify its full hash against a retained copy, count hard links, search source/scripts/reports/manifests for references, determine whether it belongs to an unresolved dump bundle, and record both allocated and logical size. Preserve reproducible inputs and the warm incremental cache. Add measured budget/cap checks before enabling any longer trace.
