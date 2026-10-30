# Current cleanup manifest — 2026-10-30 r373 update

## Authoritative current state — after r373

- Fresh scan: **77,346 files**, **41,463,405,666 bytes allocated (38.616 GiB)** and **1,396,848,441,688 bytes logical (about 1.270 TiB)**. The scan's 13 reparse-point toolchain executables were sized separately and included in allocated totals. Sparse-file logical length is not disk occupancy.
- Retained workset: warm `local-tools/steel-battalion-game/build-xpp-seeded` **6,918,921,034 allocated / 13,871,927,762 logical bytes** (2,213 files); canonical AOT source **155,887,568 bytes** (27 files); shared route saves **110,700,940 allocated / 5,422,134,482 logical bytes** (31 files); logs **2,982,438,620 allocated / 1,035,920,610,872 logical bytes** (20,626 files). Preserve the cache, saves, and exact r367 EXE/PDB/MAP bundle.
- The 378 validated staged duplicate/superseded files remain losslessly compressed, preserving hashes. The 34 closed r370/r371 files also remain losslessly compressed with hashes and logical lengths unchanged. Previously measured combined allocated-space reduction remains **763,160,973 bytes**; no files were deleted or moved.
- r372/r373 added **3,684,718 allocated bytes / 9,655,250 logical bytes** of bounded run evidence. Each run had a 64 MiB cap; neither reached the cap, neither dropped async relay lines, and no trace cap was reported. No hot compiler/Cargo cache was purged and no build ran.
- r373 supports a title-stage DCF4 callback/event handoff stall; loader traces are absent because the game never reached loading. First mission frame remains unverified. See `analysis/m3-r372-r373-title-dcf4-handoff-20261030.md`.


## Authoritative current state — after r371

- Current scan: 77,321 files; **41,459,710,307 bytes allocated (38.62 GiB)** and **1,396,838,775,797 bytes logical (about 1.27 TiB)**; zero allocation-query errors. Logical size is inflated by sparse-file length and should not be treated as disk occupancy.
- Retained working set: warm `local-tools/steel-battalion-game/build-xpp-seeded` **6,918,921,034 allocated / 13,871,927,762 logical bytes** (2,213 files); canonical AOT source `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen` **155,887,568 bytes** (27 files); shared route saves **110,700,940 allocated / 5,422,134,482 logical bytes** (31 files); logs **2,978,753,902 allocated / 1,035,910,955,622 logical bytes** (20,602 files). Preserve the warm incremental cache, exact r367 EXE/PDB/MAP bundle, and route saves.
- Verified lossless compression reclaimed **762,760,742 bytes** across 378 hash-validated duplicate/superseded files already staged in `C:\Project\SteelBattalion-Delete-Later-20261026`; closed r370/r371 evidence compression reclaimed **400,231 bytes** with all 34 hashes and logical lengths unchanged. Combined allocation reduction: **763,160,973 bytes**. The staged files remain in place; no deletion or move occurred. See `analysis/r370-r371-closed-evidence-compression-20261030.csv` and the linked r369–r371 report.
- No hot compiler/Cargo cache was cleared, and no build ran. Warm build efficiency is preserved; incremental-build time and any performance change were not measured this turn. Current free-space delta is not inferred from the workspace scan.
- Latest diagnostics stopped before loading. r371 crashed in the NVIDIA driver without faulting-thread exception context; first mission frame remains unverified. Analyze the existing r150/r151/r153 dumps with their exact bundle before another run.


## Authoritative current state — post-r356

- Fresh allocated/logical scan: `C:\Project\sb-inventory-current-r356-final-20261029.csv`; **76,979 files**, **40,882,496,274 bytes allocated (38.075 GiB)** and **1,385,482,136,285 bytes logical (1,290.331 GiB)**; 13 reparse paths skipped. Compared with post-r348, current allocated use is lower by **11,712,640,584 bytes (10.907 GiB)**. Compared with the post-r354 scan, retaining r355/r356 output and the r355 exact symbol bundle added a net **74,611,668 allocated bytes**.
- Current retained workset: warm `build-xpp-seeded` **6,773,655,696 allocated bytes (6.308 GiB) / 13,531,919,587 logical bytes** across 2,207 files; canonical generated AOT source **155,885,489 bytes / 27 files**; canonical route saves **952,898,778 allocated / 5,422,128,858 logical bytes / 29 files**; logs tree **2,934,461,077 allocated / 1,035,739,450,759 logical bytes / 20,394 files**. Preserve r342 and r355 EXE/PDB/MAP bundles for their distinct unresolved evidence.
- r355's warm side-by-side diagnostic build completed in **10.36 seconds**. No cache purge or default-bundle overwrite occurred. No subsequent runtime fix/build was made; build efficiency remains warm.
- Closed r355/r356 evidence was NTFS-compressed in place, with SHA-256 unchanged for **20/20 files**. Current combined run-folder use is **2,024,917 allocated bytes / 6,834,572 logical bytes**. No per-folder gross savings are claimed because a pre-compression cluster-allocation snapshot was not captured. Audits/findings are in `analysis/m3-r355-r356-loader-and-dsound-20261029.md`; exact binary hashes are recorded there.
- r355 reproduced an invalid DirectSound list node before an AV but lacks a matched dump and active-surface state. r356 never reached the Campaign/list state and produced no watch hits. Neither explains r354's loading plateau; no behavior fix is supported. First mission frame remains unverified.

The post-r354 measurements immediately below are now historical and retained for comparison.

## Authoritative current state — post-r354

- Fresh post-compression inventory: `C:\Project\sb-inventory-r354-postsavecompression-20261029.csv`; **76,944 files**, **40,807,884,606 bytes allocated (38.005 GiB)** and **1,385,305,361,547 bytes logical (1,290.166 GiB)**; 13 reparse entries skipped. Against the post-r348 baseline, actual allocated space is down **11,787,252,252 bytes**. Sparse files explain the large logical total; allocation is the disk-use measure.
- Current retained workset: warm `build-xpp-seeded` **6,701,008,794 allocated bytes (6.241 GiB)**; canonical generated AOT source **155,885,489 bytes / 27 files**; canonical route saves **952,898,778 allocated / 5,422,128,858 logical bytes / 29 files**; full `iso/local-analysis/logs` tree **2,932,436,160 allocated / 1,035,732,616,187 logical bytes**. The r342 EXE/PDB/MAP bundle remains in the warm tree for unresolved dumps.
- The previous Partition5 audit covered 16 hash-unique images. Fourteen inactive save-root images plus one historical run-save image were losslessly NTFS-compressed in place; all original hashes and 11,796,480,000 logical bytes were preserved. They now use 11,796,357,120 fewer allocated bytes. The canonical route save stayed uncompressed; no save was deleted or hard-linked. See `analysis/r354-save-image-compression-20261029.csv`. Closed r349–r354 logs plus pixel-verified BMP→PNG conversion reclaimed **5,723,425 bytes**; see `analysis/r349-r354-evidence-retention-20261029.csv`. Total gross allocated reclaimed this turn: **11,802,080,545 bytes**.
- All r349–r354 traces used the retained r342 EXE/PDB/MAP bundle. No build or benchmark ran; the build-cache footprint is unchanged and incremental build-time impact was not measured. Full loading findings are in `analysis/m3-r349-r354-loading-cause-and-storage-20261029.md`. First mission frame remains unverified.

Older r348 and earlier measurements follow for historical comparison.

## Prior state — post-r348

- Post-r348 inventory: `C:\Project\sb-inventory-final-r348-20261029.csv`; **76,851 files**, **52,595,136,858 bytes allocated (48.983 GiB)** and **1,385,292,627,353 bytes logical (1,290.154 GiB)**; 13 reparse entries skipped. Sparse saves explain much of the logical length; allocated bytes are the project footprint measure.
- Retained working set: warm `build-xpp-seeded` **6,701,008,794 allocated bytes (6.241 GiB)**; canonical generated AOT source **155,885,489 bytes / 27 files**; current route saves **952,898,778 allocated / 5,422,128,858 logical bytes / 29 files**; r338–r345 diagnostic folders **5,765,381 allocated / 18,769,867 logical bytes / 76 files**; r348 folder **868,857 allocated / 4,078,449 logical bytes / 12 files**. The r342 candidate EXE/PDB/MAP adds about **69.3 MiB allocated** inside the retained build tree.
- Closed r338–r343 run folders were NTFS-compressed; 56 hashes matched through an uncompress/recompress integrity cycle. Before/after inventory reports **2,032,049 allocated bytes reclaimed** in those paths. r344 and r345 evidence is also compressed; r345's 10 files reclaimed **3,994 allocated bytes**, with all hashes matched. No files were deleted or moved, and no sparse saves were copied or converted.
- Revalidated 40 historical `Cache\TEXOBJ.BIN` candidates against the retained extracted-media asset and current route cache: all 40 lengths and SHA-256 values matched, and each was in a closed historical run cache outside the current save root. Exact allocation was **1,396,080,640 bytes** before compression. The exact-path deletion command was blocked by automatic file-action review before execution. Reversible NTFS compression then preserved all 40 hashes but reclaimed **0 bytes**; all 40 files remain. Audit: `analysis/r346-texobj-duplicate-compression-20261029.csv`. No alternate deletion path was used.
- Revalidated 41 closed historical `Cache\MOTION.BIN` candidates against each other and the extracted-media asset: SHA-256 `05130BC706985EF7794CE06AC6792E507FE5F4D59350E5636819D9ED639EC8C4`, each length 39,424,000 bytes. Lossless NTFS compression preserved all files and reclaimed **945,311,744 allocated bytes**; audit `analysis/r347-motion-cache-compression-20261029.csv`. No current save or diagnostic bundle was changed.
- Closed r338–r343 run folders reclaimed **2,032,049 allocated bytes** through hash-verified compression; r344/r345 evidence reclaimed another **3,994 bytes**. Together with r347, measured compression savings are **947,347,787 bytes**. This is gross compression savings; the fresh inventory below is the actual net footprint.
- Compared with r337, workspace allocated space is now **868,724,519 bytes lower**. Measured gross compression savings were **947,347,787 bytes** from prior closed traces and r347 motion caches; the net figure includes later retained run evidence, exact bundles and reports. The compiler/Cargo cache was not cleared; the prior side-by-side build took about 10 seconds. r342's exact EXE/PDB/MAP remain for surface-trace follow-up, and r348's dump remains paired with those same hashes. The full run report is [r348 mode-2 plateau and storage](m3-r348-mode2-plateau-and-storage-20261029.md); the runtime surface follow-up is [r340–r348](m3-r340-r344-surface-and-storage-20261029.md). First mission frame remains unverified.
- r348 evidence was closed and compressed; post-compression SHA-256 values and allocated sizes are in `analysis/r348-evidence-retention-20261029.csv`. The pre-compression allocation baseline was not captured before the first audit script stopped, so no r348 compression savings are claimed. All 12 files remain.
- Project recovery patch `patches/preservation-project-current-20261029.patch` is based on `d314e3c7bce6d4121f15631634dce84fb81789c0` and excludes original/extracted game data, generated proprietary code and the self-referential preservation indexes. Current patch SHA-256 is in `analysis/source-preservation-manifest-20261029.md`.

Older r337 and earlier measurements below are historical and superseded by the post-r348 scan.

---

# Historical cleanup manifest — r337 final scan (2026-10-29)

## Authoritative current state

- Final inventory: `C:\Project\sb-inventory-current-r337-final-20261029.csv`; **76,986 files**, **53,463,861,377 bytes allocated (49.792 GiB)** and **1,385,102,464,443 bytes logical (1,289.977 GiB)**. Thirteen reparse entries were skipped. Sparse save/partition images account for much of the logical length; allocated bytes represent current disk use.
- Top-level allocation: `iso` **29.49 GiB**, `local-tools` **20.09 GiB**. This includes a new required side-by-side diagnostic bundle for the unresolved r336/r337 dumps. Against the r332 scan, allocation increased by **77,340,551 bytes**; the exact-bundle evidence and compiler output are being retained for open failures.
- Retained slices: warm `build-xpp-seeded` **6.17 GiB allocated / 12.29 GiB logical** (2,201 files); canonical generated AOT source **0.14 / 0.14 GiB** (27 files); route saves **0.89 / 5.05 GiB** (29 files); diagnostic logs **3.47 / 964.57 GiB** (20,212 files). The r336 incremental build took 9.1 seconds, near the previous 8.65-second r324 measurement. No hot compiler/Cargo cache was cleared.
- r334–r335 closed evidence was losslessly compressed, saving **842,384 bytes**; r336/r337 evidence and matching r336 EXE/PDB/MAP compression saved **1,785,849 bytes**. Every file hash matched before and after. Audits: `analysis/r334-r335-evidence-compression-20261029.csv` and `analysis/r336-r337-and-r336-bundle-compression-20261029.csv`. Total measured compression savings: **2,628,233 bytes**. No files were deleted or moved.
- The 40 historical `TEXOBJ.BIN` duplicates have exact SHA matches to the retained extracted source asset/current route cache and are listed in `analysis/cleanup-texobj-duplicate-deletion-r333-20261029.csv`. Automatic file-action review blocked deletion (“blocked by policy”) after the exact audit; no alternate deletion mechanism was used. They still use about **1.30 GiB allocated**. Actual deletion savings: **0 bytes**.
- Original ISO, unique saves, dirty source checkouts, manually edited generated AOT code, licenses, active game inputs and exact unresolved dump bundles remain preserved. No hot compiler/Cargo cache was purged. No writable saves were hard-linked, copied, or rewritten. Incremental isolated diagnostic build completed in **9.1 seconds**, close to the prior 8.65-second measurement at r324; no other performance build ran.
- See [r333–r337 DirectSound and storage follow-up](m3-r333-r337-directsound-storage-followup-20261029.md), the [project status index](../docs/PROJECT_STATUS.md), and inventory above. The r332 figures below are historical, not current.

---

# Historical cleanup manifest — r332 final scan (2026-10-29)

The historical r332 scan and details are retained below for comparison.

---

# Historical cleanup manifest — r314 final scan (2026-10-29)

## Authoritative current state

- Full inventory: `C:\Project\sb-inventory-current-20261029-r314.csv` and companion `.skipped.txt`; 76,590 files; **53,365,742,176 bytes allocated (49.701 GiB)** and **1,383,164,692,437 bytes logical (1,288.173 GiB)**. Thirteen Cargo-tool reparse entries were skipped. Top-level `iso`: 32,098,001,212 allocated / 1,087,430,178,536 logical bytes; `local-tools`: 21,042,237,451 / 295,481,736,027 bytes.
- The warm `local-tools/steel-battalion-game/build-xpp-seeded` tree is **6,096,736,049 allocated bytes across 2,171 files**. Keep its incremental compiler cache and all exact unresolved diagnostic bundles. r313's incremental build took 11.15 seconds. No build ran during r314; build-efficiency impact for this follow-up is unchanged.
- Save images in `iso/local-analysis/saves-*` and retained run `save/` folders account for **18,479,849,798 allocated bytes (17.211 GiB)** across 1,954 files, or **927,816,447,302 logical bytes (864.096 GiB)**. They are preserved. The existing Partition5 hash audit shows distinct content; a full all-partition duplicate/zero-content audit is still needed before any save cleanup. No save images were deleted, sparsified, or hard-linked.
- r314 folder `iso/local-analysis/logs/m3-low-ucrt-output-control-r314-20261029` was finalized by the runner after its child stopped. It used 6,951,054 logical bytes of a 64 MiB budget, with no budget trigger, trace-limit hits, or stdout/stderr relay drops; one capped watchdog snapshot was emitted, its drop count was zero, and the log writer stopped cleanly. The runner could not measure allocated bytes after the forced stop. The subsequent closed-evidence audit measured 14 files at 3,857,785 allocated bytes before NTFS compression and 1,390,317 after; **2,467,468 bytes reclaimed**, with all SHA-256 hashes unchanged. File-by-file results: `analysis/r314-evidence-compression-20261029.csv`.
- Combined measured closed-evidence compression for r310–r314 reclaimed **14,867,903 bytes** (12,400,435 from r310–r313 and 2,467,468 from r314). The inventory is path-summed allocation; no project file was deleted or moved. A separate inventory CSV in `C:\Project` was losslessly compressed with an unchanged SHA-256, saving 10,953,486 allocated bytes outside the workspace.
- Retained working set: original ISO and extracted assets, all unique save roots, dirty source checkouts, locally edited generated source and rollback copy, licenses, exact EXE/PDB/MAP bundles needed by unresolved dumps, and the warm build cache. No hard links or dense sparse-file copies were made. A read-only partition-hash attempt that included the live route-save root was stopped before output; it produced no valid audit and was not used to classify any saves. All unique saves remain untouched.
- The prior cache audit still confirms exact `Cache/TEXOBJ.BIN` duplicates, but a prior direct deletion request was blocked by automatic policy. No alternate deletion route was tried. No deletion savings are claimed.
- Latest runtime evidence and exact r314 run identity: [r310–r314 loader and storage follow-up](m3-r310-r314-loader-storage-followup-20261029.md). The first mission frame remains unverified. No behavior change was made.

Historical measurements and theories below are retained for provenance; they do not describe the current workspace size.

---

# Historical cleanup manifest — r304 final scan (2026-10-29)

## Authoritative current state

- Final inventory: `C:\Project\sb-inventory-r304-final-20261029.csv` plus `.skipped.txt`; 76,370 files; **53,542,409,989 bytes allocated (49.865 GiB)** versus **1,382,752,072,165 bytes logical (1,287.788 GiB)**. Thirteen Cargo-tool reparse paths were skipped; zero allocation-query errors. Sparse logical image capacity is not allocated disk use.
- Top-level allocation: `iso` 29.93 GiB allocated / 1,012.68 GiB logical; `local-tools` 19.73 GiB / 274.87 GiB. The original ISO allocates 7.29 GiB. The 1,559 partition images allocate 11.75 GiB while totaling about 1,234.25 GiB logical.
- Retained working set: original ISO, extracted media, unique/current saves, dirty source checkouts, manually edited generated source, licenses, exact unresolved dump/symbol bundles, and the warm build cache. The cache is 5,756,729,148 allocated bytes (2,165 files); current route save is 965,156,570 bytes allocated; generated source is 155,878,522 bytes.
- r304 diagnostic folder: 2,112,790 bytes allocated / 5,866,516 bytes logical. Its run budget was 64 MiB; output was 5,861,710 bytes, no cap/relay drops, and the writer drained cleanly. It reused the r293 EXE/PDB/MAP and existing save root.
- Losslessly NTFS-compressed 18 closed historical BMP/log files. Their hashes are unchanged; allocated bytes fell from 3,968,792 to 926,463 (3,042,329 bytes). Also compressed the superseded intermediate inventory `analysis/cleanup-inventory-final-20261029.csv`; its SHA-256 is unchanged and allocation fell from 14,686,797 to 3,760,128 bytes (10,926,669 bytes). **Measured project-footprint savings: 13,968,998 bytes (13.32 MiB).** Three retained `C:\Project` inventory CSVs were separately compressed with SHA-256 verification; their allocation fell from 44,061,801 to 11,280,384 bytes, freeing another 32,781,417 bytes outside the project. No files were deleted. r304's run and matching dump/symbols remain retained.
- Compared with the prior r293 full scan, path-summed allocation is 60,042,171 bytes higher after retaining the r300–r304 evidence, reports, and current inventory. Project compression gains are included in the final inventory. C: free space was 24,099,401,728 bytes after the external CSV compression; volume movement is not attributed solely to the project.
- The warm `build-xpp-seeded` cache was kept. No build was run, so build-efficiency impact was not measured; the last known incremental build was about 14.3 seconds. No save copy/hard link, dense sparse-image copy, or D: project move was made.
- Largest verified removable candidate remains 39 exact duplicate inactive `Cache/TEXOBJ.BIN` files (about 1.84 GiB allocated). Their hashes match the extracted canonical file. Direct deletion was previously rejected by automatic file-policy review; no alternate deletion route was used. They remain in the inventory and none of their bytes are credited as reclaimed.
- All 10,703 BMPs and 6,212 of 6,217 logs are already NTFS-compressed. Remaining five uncompressed logs total only 82,227 allocated bytes, so no material safe compression opportunity remains in screenshots/logs.
- Current boot/loading findings and exact run identity: `analysis/m3-r300-r304-loader-storage-followup-20261029.md`. First mission frame remains unverified; no runtime fix or rebuild is supported.

Historical scans and cleanup notes below are preserved for provenance; they do not describe current size.

---

# Historical cleanup manifest — r293 final scan (2026-10-29)

## Current storage state

- Final path-summed scan: 76,160 files; **53,482,367,818 bytes allocated (49.809 GiB)** and **1,382,607,845,745 bytes logical (1,287.654 GiB)**. Thirteen Cargo-tool reparse paths were skipped; no allocation-query failures. Inventory: `C:\Project\sb-inventory-current-20261029-r293-final2.csv` and `.skipped.txt`. Sparse logical lengths are reported separately from allocated bytes.
- Compared with the pre-compression r292 inventory (76,120 files; 58,678,792,393 allocated bytes), current path-summed allocation is lower by **5,196,424,576 bytes (4.838 GiB)** after retaining r293's new executable, symbols, dump, and reports. This is net workspace change, not gross compression savings. r293's 14 closed bundle/evidence files were compressed losslessly; all hashes matched and file allocation fell by **98,235,627 bytes**. File-by-file evidence: `analysis/r293-evidence-retention-20261029.csv`. r292's 164 candidate bundles remain hash-verified and compressed.
- C: free space at final scan was **25,047,556,096 bytes**. Volume free-space movement is not attributable solely to this project; the path inventory is the project measure.
- The entire `local-tools/steel-battalion-game/build-xpp-seeded` subtree currently measures **5,756,729,148 allocated bytes across 2,165 files**. The prior 10,615,458,949-byte figure predated compression of historical candidate bundles and is superseded by this exact current subtree measurement. No compiler/Cargo cache purge occurred. The r293 isolated build completed in about **14.3 seconds**; r292 completed in about 9 seconds.
- r293's 64 MiB run cap was not reached; relay drops were zero and the writer drained cleanly. The exact dump-matching EXE/PDB/MAP and unique evidence remain. No ISO, save, source, generated source, or build input was deleted or moved. No save copy or hard link was created.
- Actual deletion savings: **0 bytes**. Lossless compression is the source of reclaimed allocation. Preserve the current cache and unresolved r291–r293 bundles.

Historical scans and cleanup notes follow; they are superseded by this scan where they report current state.

---
Historical scans and cleanup notes follow. They are superseded by this scan where they report current state.

---
# Current cleanup manifest — current scan r290 (2026-10-29)

## Current review — r288–r290

- Full final r290 inventory: 76,074 files; **58,335,155,906 bytes allocated (54.329 GiB)** and **1,382,084,853,034 bytes logical (1.287 TiB)**. Thirteen reparse entries skipped; zero allocation-query failures. Inventory: `C:\Project\sb-inventory-current-20261029-r290-final2.csv` with companion `.skipped.txt`. C: free space was 29,214,064,640 bytes. These are path-summed allocation and logical lengths.
- Compared with post-r285, counted allocation increased 236,293,652 bytes; logical length increased 295,209,592 bytes. **Nothing was deleted or moved; actual savings: 0 bytes.** Keep ISO, current save in place, canonical and manually edited generated source, dirty source checkouts, licenses, warm cache, unresolved dumps, screenshots, and exact executable/PDB/MAP bundles.
- r288 evidence folder allocates 17,158,513 bytes; r289 2,083,422; r290 2,617,055. The required r289/r290 EXE/PDB/MAP bundle allocates 169,878,438 bytes. Closed run logs and BMP screenshots are already NTFS-compressed losslessly. The 64 MiB r290 run budget was not hit, there were no relay drops, no trace cap markers, and the writer stopped cleanly. No hard links or dense save copies were made.
- Warm `build-xpp-seeded` is 10,615,458,949 allocated bytes. Keep it for incremental builds; last measured incremental build remains 17.6s. Isolated r289 diagnostic build took about 7.5s. No cache purge occurred.
- Storage cleanup remains constrained by prior automatic rejection of deletion for verified duplicate artifacts; no alternate deletion route was used. No verified safe reclaim was completed during these runs.
- A 10,015-byte temporary pretty-print of the r290 run manifest remains at `analysis/r290-manifest-pretty.json`. The automatic review blocked the combined edit-and-remove command before it ran; its stated reason was only “blocked by policy.” It is included in the final inventory; no alternate removal path was attempted.
- Latest blocker evidence is [r288–r290 loader and storage follow-up](m3-r288-r290-loader-and-storage-followup-20261029.md): main TID 166796 loops on an invalid result for selector `0x3FFF`; expected entry producer remains unverified. Preserve r288 with r284 symbols and r289/r290 with r289 symbols. Do not delete an artifact while its matching dump remains unresolved.

Historical scans and cleanup notes follow; their measurements are not current.

## r284–r285 refresh

- Full pre-r285 scan: 75,958 files; **58,097,988,244 bytes allocated (54.108 GiB)** and **1,381,786,592,925 bytes logical (1.257 TiB)**. Thirteen reparse entries were skipped; no allocation-query failures. Inventory: `C:\Project\sb-inventory-current-20261029-pre-r285.csv`. These are path-summed allocated and logical lengths; they are not interchangeable.
- Final post-r285 scan: 75,973 files; **58,098,862,254 bytes allocated (54.109 GiB)** and **1,381,789,643,442 bytes logical (1.257 TiB)**. The same 13 reparse entries were skipped; no allocation-query failures. Inventory: `C:\Project\sb-inventory-current-20261029-r285-final2.csv`; C: free space was 29,805,793,280 bytes at that scan. Core protected set allocates 21,150,549,345 bytes; the exact symbol bundles and other dirty sources/dependencies add to that subtotal.
- r284 retained the exact EXE/PDB/MAP bundle with its watchdog dump. r285 reused that bundle and the route save, created no build copy or save clone, and used 3,059,658 logical evidence bytes. No process from another chat was interrupted.
- r284 and r285 evidence folders allocate 3,685,409 and 887,644 bytes respectively. The warm `build-xpp-seeded` tree now allocates 10,404,240,062 bytes, including the 169,873,538-byte r284 EXE/PDB/MAP bundle. Generated source allocates 155,877,317 bytes; the active route save allocates 965,156,570 bytes (5,422,128,858 logical). The last measured incremental build remains 17.6 seconds; no cache purge or rebuild occurred this pass.
- Refreshed `analysis/cache-reproducibility-audit-r285.csv`: 40 inactive historical `Cache/TEXOBJ.BIN` copies all hash to extracted source SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`. One reference copy remains. The other 39 account for 1,839,232,512 bytes of path-summed allocated space. Their direct deletion was rejected by automatic file-policy review before any file changed. No alternate removal route was used. **Actual savings: 0 bytes.**
- The runner now counts the dedicated loader-state callback log when building marker totals. Recounting r284's retained separate channel verified 281 rows; the old run manifest's stderr-only count of zero is incorrect for that channel. This is corrected in the r284–r285 report, not by rewriting the old run artifacts.
- r284/r285 analysis and the validated native unwind are recorded in `analysis/m3-r284-r285-loader-helper-and-callback-ab-20261029.md` and `analysis/r284-valid-native-unwind-20261029.txt`. No build cache, original game data, unique save, or unresolved binary/symbol bundle was deleted. **Actual allocated-space savings in this pass remain 0 bytes.**

## r282–r283 refresh

## r282–r283 refresh

- Post-documentation full scan: 75,939 files; **57,917,459,985 bytes allocated (53.940 GiB)** and **1,381,598,565,300 bytes logical (1.257 TiB)**. Thirteen reparse entries were skipped; no allocation-query failures were reported. Inventory: `C:\Project\sb-inventory-current-20261029-r283-final.csv`; skipped entries: matching `.skipped.txt`. C: free space at this scan was 29,961,854,976 bytes. These are separate path-summed allocation and logical length values.
- Closed r282 evidence folder: 1,413,222 allocated / 5,595,294 logical bytes. Closed r283 evidence folder: 3,641,608 allocated / 11,194,541 logical bytes. Together they use 5,054,830 allocated bytes and 16,789,835 logical bytes. The exact r275 EXE/PDB/MAP bundle was reused; no new binary bundle or save copy was created.
- The r283 framebuffer is SHA-256 identical to the retained r281 screenshot (`BB7D7A9B7BC93CBFB22CF0E65A7B59E70191831AC01E101315D2C4EE9E8D42F5`). The r283 copy uses 16,384 allocated bytes; r281 remains the canonical retained image and the new r282–r283 report points to it. A request to remove the r283 duplicate was rejected by automatic file-policy review before execution. Both copies remain intact; no alternate deletion route was used. **Actual savings this pass: 0 bytes.**
- The warm `build-xpp-seeded` cache remains 10,234,362,700 allocated bytes; its last measured incremental build remains 17.6 seconds. No build, cache purge, source change, or runtime fix occurred. No files were deleted or moved. Actual allocated-space savings are 0 bytes.
- Diagnosis is recorded in [r282–r283 loading and renderer evidence](m3-r282-r283-render-loader-evidence-20261029.md). First mission frame remains unverified. Historical r281 and earlier inventory notes follow.

## Prior current scan — r281

## Latest measurement and retained working set — r281

- Refreshed full scan after the r281 evidence and status edits: 75,894 enumerated files; **57,912,306,432 bytes allocated (53.935 GiB)** and **1,381,581,676,742 bytes logical (1.257 TiB)**. Thirteen Rust-tool reparse entries were skipped. Eight Cargo fingerprint files returned access denied to the allocation query, so their allocation is not included; treat the allocated total as a slight lower bound. The inventory is `C:\Project\sb-inventory-current-20261029-r281.csv`; exceptions are `C:\Project\sb-inventory-current-20261029-r281.csv.skipped.txt` plus the eight denied paths in the current scan record.
- Compared with the pre-documentation r281 scan, counted allocation increased by 5,631 bytes and logical length by 5,631 bytes, consistent with the small evidence/index updates. This is not storage reclaimed. **Actual savings this pass: 0 bytes.** Nothing was deleted or moved, and no same-drive relocation or dense sparse-file copy was made.
- The r281 route evidence and the matching EXE/PDB/MAP, generated-source hash, dump, screenshot and current save are retained. The save was reused in place, not hard-linked. No source or generated code was changed. The warm `build-xpp-seeded` cache remains at 10,234,362,700 allocated bytes; last measured incremental build time remains 17.6 seconds. No build or cache purge occurred.
- The first mission frame remains unverified. The next useful step is bounded rolling failure-window capture for mode-2 readiness, request completion, raster batch/worker join and final-window event progress; keep DCF4 producer tracing off unless an unmatched wait reproduces. See [r280–r281 loader evidence](m3-r280-r281-loader-evidence-20261029.md) and [current project status](../docs/PROJECT_STATUS.md).

Historical r279 and earlier inventory notes follow; do not treat their numbers as current.

## Latest full measurement — after r279

- 75,858 files; **57,909,501,166 allocated bytes (53.932 GiB)** and **1,381,573,405,315 logical bytes (1.257 TiB)**. Thirteen Rust-tool reparse entries skipped; zero allocation-query errors. C: free space was 30,279,049,216 bytes. These are path-summed allocation and logical-length measurements; sparse file logical length is not disk usage.
- Relative to the prior 75,801-file scan: +5,572,579 allocated bytes and +16,016,839 logical bytes. This is measured workspace growth, not reclaimed space; attribution is not exact. **Actual savings remain 0 bytes.** Between the pre-r279 and post-r279 scans, C: free space fell by 2,112,253,952 bytes while project allocation rose 711,132 bytes; that difference is outside the measured project workspace or volume accounting and is not attributed to project files.
- r276–r279 evidence directories allocate 4,419,110 bytes total and contain 14,863,370 logical bytes. The r278 470,463-byte crash dump remains paired with its exact AOT bundle. No run files were deleted or moved.
- Warm `build-xpp-seeded`: 10,234,362,700 allocated bytes (9.53 GiB). It remains the incremental build cache; no build or purge occurred. Its last measured incremental build time is 17.6 seconds.
- See [r276–r278 evidence](m3-r276-r278-audio-loader-triage-20261029.md) and [r279 watch result](m3-r279-dsound-watch-followup-20261029.md) for diagnosis and exact bundle identities.

## Fresh state — 2026-10-29 follow-up inventory

- Fresh scan: 75,801 files; **57,903,928,587 bytes allocated** (about 53.93 GiB) and **1,381,557,388,476 bytes logical** (about 1.257 TiB). Thirteen Rust-tool reparse entries were skipped. Figures are path-summed and separate actual allocation from sparse logical length. Compressed inventory: `local-analysis/project-review-inventory-20261029-r276.csv.gz`; skipped paths: `local-analysis/project-review-inventory-20261029-r276.skipped.txt`.
- Sparse partition images dominate apparent size: 1,559 files, 12,614,846,976 allocated bytes (11.75 GiB) versus 1,325,269,207,552 logical bytes (about 1.206 TiB). The original ISO allocates 7,825,162,240 bytes. Preserve both.
- The warm `build-xpp-seeded` tree uses 10,234,362,700 allocated bytes (9.53 GiB); canonical generated AOT source is 155,874,289 bytes; extracted game files are 1,800,113,156 bytes; route saves use 965,156,570 allocated bytes versus 5,422,128,858 logical. Build caches, source, generated code, original media, unique saves, and unresolved EXE/PDB/MAP bundles were not changed.
- Diagnostic log trees allocate 4,068,332,570 bytes under `iso/local-analysis/logs` and 7,782,904,682 bytes under the nested `local-tools/steel-battalion-game/iso/local-analysis/logs`; their logical totals are larger because save images inside those trees are sparse. Across the workspace, 10,661 BMPs allocate 1,152,147,184 bytes, 6,023 logs allocate 1,035,252,945 bytes, and 287 minidumps allocate 537,273,655 bytes. These are inventory totals, not deletion instructions.
- **No files were reclaimed.** A request to remove three unused installer archives was rejected by automatic file-policy review before execution. No alternate deletion route was used. The archives remain intact: `local-tools/reverse-engineering/ghidra.zip` (569,649,598 allocated bytes; SHA-256 `DDAC49F903DA9D5BAC833E5CC79395098B9C33CFD3279BE5F31BD00387D2D4DB`), `local-tools/ghidra-analysis/ghidra12.2.zip` (569,077,760 allocated bytes; SHA-256 `2C2CD776DB3C1F6A097BA418922378AC3649CADD5E844A6F5F088AE628A7BE67`), and `local-tools/analysis-deps/downloads/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip` (205,073,461 allocated bytes; SHA-256 `F9D6E191AB098C0D416E7D588A24420A8621CD2F4720DAB2459B8B7B2D2D8B4E`). Their combined potential allocation was 1,343,800,819 bytes, but actual savings are zero. The duplicate Ghidra tree and 40 identical cache copies also remain protected after their earlier policy rejections. C: had 41,418,702,848 free bytes at the inventory check.
- No game, XboxRecomp, or Ghidra process was active during the scan; no r154 process remained. No build, cache purge, save copy, or runtime launch occurred. The warm incremental build remains available; its last measured build time is 17.6 seconds, with no new comparison.

### Diagnostic retention policy check

- `Start-ProducerTrace.ps1` enforces a 64 MiB per-run logical-output ceiling and captures a dump before stopping only its verified child. Its asynchronous relay uses a bounded queue and records dropped lines; r275 reported zero relay drops.
- After the child exits, the runner applies NTFS compression to closed `.bmp` and `.log` files, preserving exact bytes and screenshots losslessly. Prior measurements found no meaningful allocated-space reduction, so this is not counted as reclaimed space.
- Startup-first limits still matter: default file reads keep the first 220 and every 1,000th completion; all-read mode keeps the first 30,000 and every 1,000th thereafter; successful open paths cap at 2,048; targeted opens cap at 2,048; some DCF4 traces are first-N. The per-run ceiling and relay counters do not guarantee failure-window coverage. Use the bounded paired-open and failed-path channels for loader diagnosis; leave DCF4 detail off unless that separate wait reproduces.

> **Latest current-state addendum (r274, 2026-10-29).** This supersedes the earlier r272b/r273 status at the top of this file; older inventory and cleanup notes below are historical.
>
> - Fresh inventory `C:\Project\sb-inventory-current-20261029-r274.csv`: 75,753 files, 57,713,820,652 allocated bytes (53.750 GiB), 1,381,321,287,103 logical bytes (1.256 TiB), 13 Rust-tool reparse entries skipped, no allocation errors. It queries allocated size separately from logical length; figures are path-summed and include sparse files. Skipped list: `C:\Project\sb-inventory-current-20261029-r274.csv.skipped.txt`. C: had 31,750,746,112 bytes free at the final inventory snapshot.
> - Relative to r272b baseline: +3,554,270 allocated and +6,368,886 logical bytes; no files reclaimed. Current inventory groups: `iso` 29.829 GiB; `local-tools` 23.738 GiB; `.git` 0.097 GiB. Retained large working set: warm `build-xpp-seeded` 9.373 GiB; canonical generated source 148.65 MiB; extracted game files 1.676 GiB; route saves 920.45 MiB; `iso/local-analysis/logs` 3.772 GiB and nested `local-tools/steel-battalion-game/iso/local-analysis/logs` 7.248 GiB allocated. r274 output: 1,870,309 allocated / 3,460,264 logical bytes.
> - r274 (`m3-dcf4-input-producer-r274-20261029`) ended by its own 120-second DCF4 no-return watchdog; PID 162384 only. No other XboxRecomp process was running in the post-stop check. Exact r272b EXE/PDB/MAP hashes and generated-source hash are retained in the r274 report/run manifest; no new binary bundle, save clone, build, cache purge, or source behavior change.
> - Validation: the active route save's `Partition5.img` is hash-distinct. Its earlier audited SHA-256 was `A71376DD11558D259DF11DCDA5F49A8B117DAB40C941741BC4FD782AC7CF3E96`; current SHA-256 is `8D239A830ED2AD7797E7721D8E708E7720C206F1F190A8EA3EFEFA8CBA3588EC`, last written 01:05:22 CDT about two seconds after r274 launch. The save is retained at its current state; the run manifest did not capture a pre-run save hash, so attribution is uncertain. The matched diagnostic EXE/PDB/MAP hashes were checked against the run manifest. Prior screenshot-reference audit still reports 1,246/1,247 candidates cited; the sole unreferenced row yields only 16,384 allocated bytes. The 40 byte-identical reproducible cache files were already rejected for removal. Neither set was retried; no safe materially sized, independently cleared artifact was identified.
> - Diagnostic policy remains 64 MiB logical/run; closed logs/BMPs are compressed by the runner with cap/drop accounting. r274 used 3,455,618 bytes, had zero relay drops and no trace caps. Lossless current/stage/failure frames, dump bundles, unique saves, dirty sources, generated code, and hot incremental cache remain preserved.
> - **Allocated-space savings this pass: 0 bytes.** Build efficiency unchanged. Do not claim same-drive moves as savings or logical sparse length as allocation.

> **Fresh review addendum — 2026-10-29.** Current inventory `C:\Project\sb-inventory-current-20261029-user-request.csv`: 75,763 files, 57,713,848,137 allocated bytes (53.750 GiB), 1,381,321,314,588 logical bytes (1.256 TiB), 13 Rust-tool reparse entries skipped, no allocation errors. C: free at scan: 31,724,093,440 bytes. This is path-summed and reports allocation separately from logical sparse length.
>
> The r150/r151/r153 exact-bundle offline unwinds were rerun and validated with zero memory-read failures. No game or recomp process was active. The r149 EXE/PDB/MAP bundle remains required for these unresolved dumps. No build or cache purge was made.
>
> Freshly rehashed all 40 `TEXOBJ.BIN` cache copies against extracted source SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`: 40 present, one unique hash, no mismatches, and zero candidates inside the active route-save root. They total 1,886,392,320 allocated/logical bytes; one canonical historical copy plus the extracted source are sufficient to reproduce them. The exact removal request was rejected by automatic review before execution; no files changed. Per policy, no alternate deletion mechanism was used. Audit rows: `analysis/cache-reproducibility-audit-current-20261029.csv`. **Actual allocated-space savings this review: 0 bytes.**
>
> The screenshot reference audit still offers only one uncited duplicate at 16 KiB allocated; all other reviewed candidates are cited and retained. Prior closed-log compression did not reduce allocated bytes. No other independently validated material deletion candidate was acted upon. Warm `build-xpp-seeded` and all exact EXE/PDB/MAP dump bundles remain protected.

> Current-state addendum. The following r272b measurements and decisions supersede the older r271 figures and action summary below. See [r272b loader-stage evidence and storage audit](m3-r272b-loader-wait-and-storage-20261029.md). A later full inventory will include this addendum and the active r273 run.

## Current measured baseline

- Full post-r272b scan: 75,715 files, 57,710,266,382 bytes allocated (53.74 GiB), and 1,381,314,918,217 bytes logical (about 1.26 TiB). The compressed inventory and skipped-path report are `C:\Project\sb-inventory-current-20261029-r272b.csv.gz` and `C:\Project\sb-inventory-current-20261029-r272b.csv.skipped.txt`. Thirteen Rust reparse entries were skipped; there were no scan errors.
- Large retained working sets: `build-xpp-seeded` 10,064,493,772 allocated bytes (9.37 GiB); canonical generated AOT tree 155,871,714 bytes; extracted game assets 1,800,113,156 bytes; active save root 965,156,570 bytes. These are protected inputs/caches, not cleanup candidates.
- All logs use 4,045,725,069 allocated bytes (3.77 GiB). Keep unresolved dumps and evidence with their exact EXE/PDB/MAP bundles. Old run directories are not safe to delete by date/name alone.
- **Space reclaimed in this pass: 0 bytes.** The attempted bulk removal was rejected by automatic review before any files changed; it was not retried through another route.

## Verified capture-duplicate audit

`C:\Project\sb-image-duplicate-validation-r272b.csv` contains same-directory SHA-256 comparisons of BMPs. The narrow set limited to closed diagnostic logs and explicitly named duplicate-frame folders has 1,247 candidate rows, 1,149,302,538 logical bytes, and 82,313,216 allocated bytes. Original extracted game media was excluded from the proposed set.

The follow-up reference audit `C:\Project\sb-image-candidate-reference-audit-r272b.csv` searched 193 Markdown/text/JSON/CSV files in `analysis`, `docs`, `iso/local-analysis/cleanup-review`, and `C:\Project\PROJECT_MEMORY.md`: 1,246 candidates are referenced. The only unreferenced same-directory duplicate would free 16,384 allocated bytes. No candidate was removed. Preserve the referenced captures; the tiny unreferenced item is not a meaningful reduction and no deletion was attempted after the review rejection.

## Diagnostic storage policy verified

`tools/Start-ProducerTrace.ps1` has an enforced 64 MiB per-run logical-output cap, captures a dump before stopping its verified child at the cap, and NTFS-compresses closed `.bmp` and `.log` evidence after the child exits. r272b used 28,352,138 logical bytes and did not reach the cap. Its `[DCF4-GATE]` first-N trace cap reached 2,048, so the overall run cap does not solve early-channel saturation; keep explicit cap/drop counters and use failure-window sampling for future traces. A prior compression trial of old logs measured no allocated-space reduction; this pass did not repeat it.

The current storage baseline excludes the new r272b report, this addendum, the updated status index, the r273 evidence still being written, and subsequent memory entries. Re-run the inventory after r273 reaches a terminal state; count only measured allocated-byte change as savings. The r273 process uses the existing r272b EXE/PDB/MAP and existing writable save root, so no additional binary bundle or save copy was created.

## Current protected r272b bundle

- EXE SHA-256 `5A2B79D56C29C84D1CC25B14AACC34D11E973E410E01E996BB774EBBDCEED8D9`.
- PDB SHA-256 `FADB4D97FE1DF21873986BCCA6523BC57D8E2E201B0071C321EB14E5568F9B49`.
- MAP SHA-256 `BB65AED7A698CD7E2071E19820BE69E51242B0F96334A01A8918EE940B6B20A1`.
- Run evidence: `iso/local-analysis/logs/m3-title-dcf4-failure-window-r272b-20261029/`.
- Generated `recomp_0015.c` SHA-256 `33981ED909571698B8E848E36E870EE90B2780B9F50E1F8A8BA9B2E4F62689EF`.

## Measured workspace

The refreshed inventory is `C:\Project\sb-inventory-current-20261029-r271.csv.gz`; its skipped-path list is `C:\Project\sb-inventory-current-20261029-r271.csv.skipped.txt`. It skipped 13 Rust tool reparse entries and reported no other scan errors.

- **Full post-r271 scan: 75,678 files; 57,530,257,315 bytes allocated (53.579227 GiB); 1,381,116,548,274 bytes logical (1,286.265020 GiB).** The 13 skipped entries are Rust tool reparse paths. After creating/updating the text status records, the current total was adjusted by remeasuring the four affected files: 75,680 files; 57,530,266,619 allocated bytes (53.579236 GiB); 1,381,116,557,578 logical bytes (1,286.265028 GiB). No other workspace paths changed between the scan and this adjustment.
- Compared with the full r270 scan: +172,298,361 allocated bytes and +174,741,326 logical bytes after the text-file adjustment. The main additions are the r271 bundle and evidence. Earlier r268 totals came from an incomplete scan and are not used as a clean baseline.
- r267 evidence folder was 4,838,539 logical bytes at exit; 64 MiB cap not hit, no trace-limit hits and no relay drops. Its lossless 640x480 BMP and matching dump remain.
- r268 run manifest reports `RunStorageBytesAtExit=61,823`; its current 11-file folder totals 65,998 logical bytes.
- r270 added a three-file EXE/PDB/MAP bundle using 169,852,207 allocated bytes. Its eleven-file run folder uses 2,240,529 allocated bytes and 4,137,314 logical bytes currently; the runner reported 4,129,411 logical bytes at exit, below its 64 MiB cap.
- r271 added a three-file EXE/PDB/MAP bundle using 169,853,890 allocated bytes. Its eleven-file run folder uses 2,422,431 allocated bytes and 4,865,396 logical bytes. The runner reported 4,856,964 bytes at stop, below its 64 MiB cap.

## Preserve

- Original ISO and extracted assets; all 16 unique full `Partition5.img` saves; dirty source checkouts; edited generated source; legal notices; the canonical generated tree; warm incremental CMake/Cargo caches.
- Exact binary/symbol bundles tied to unresolved dumps. r249 bundle: EXE `1CF805050BCF31C29575D3850C0C34F5346FCA358F5BC8E81AD8AC315E31FB98`, PDB `6FF161D1DFE60683B8AC9B9C5C32A193EC109311432B1CABFF2794B70BF6D057`, MAP `0D987E74FB4CCE6E0DEE10ABD1F4DF231C10C7D4A340FF514763091747FF9944`.
- r264 exact bundle and its dump: EXE `6C5E142CCDA79474D75787B32F927EA8C4BB439B983BC5284E2F79BC2027DD27`, PDB `E6638D46A269C740C46565FEB678853DB8C1A128C857CFEAFA51DEA62B8E3FA8`, MAP `889C4D9A4F262A3999A4DA30BA3388C7A524F2339E6D959F913E78A20334A8CE`. Retain together while its DCF4 finding remains open.
- r270 exact bundle and dump are also protected: EXE `A2562059D5B76FEE0F100F4AC86ADFF4B29F4760EFCA6A54330EB8AFA16B709A`, PDB `BF9C2C3454537803D04E52C4CF8C5807443BD58799EEBF3B7CBC4FBB396B0AC5`, MAP `A015790C97492C60D547C65F2A1EAD457C1AFB1413A322A63BE719E0CE9B93D2`.
- r271 exact bundle and dump are preserved while the title DCF4 handoff remains unresolved: EXE `4B4B4D1992EE121D174F3E5D9C42A60345731B1BD66CB7B775E372F8D7612BE4`, PDB `24B951DCE31F5CE2DA61BFF70CBFA7D14D865D208EBA0BB7F6768EB8040130FA`, MAP `D84AD7E0B146605F0F4888041AA302A18C8182FD85AEE4C6935F76FF590F9A10`.
- All full save partitions have distinct hashes and allocate 12,582,912,000 bytes in total; preserve. Never hard-link writable saves.

## Space reclaimed and candidates

- **This pass recovered 0 bytes.** No workspace files were removed, compressed in place, or relocated.
- Fourteen closed r259–r261 logs were previously marked NTFS-compressed; the measured allocated-byte reduction was zero. Do not repeat that operation without a new measured benefit.
- Eight verified zero-only save partitions were previously made sparse, recovering about 8.300 GiB; 12,101 exact duplicate screenshots were removed in an earlier authorized cleanup. Neither action was repeated.
- Forty identical `Cache/TEXOBJ.BIN` copies (~1.758 GiB allocated, SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`) remain untouched because a prior direct removal was rejected by automatic review. Do not route around that rejection. These are the largest identified duplicate candidates, but no space has been credited as reclaimed.
- No historical capture, save, source tree, cache, or old build was removed in this pass. Exact dump bundles remain protected. The r264 side-by-side bundle is required for r267/r269 dumps; r270 and r271 bundles remain paired with unresolved DCF4 dumps.

## Budget and next steps

- Diagnostic output remains capped at 64 MiB per run. r271 had complete marker counts and zero relay drops but hit the `[DCF4-OUTER-CAP] limit=2048` first-N trace cap before the final stall. The side-by-side build completed in about 30 seconds without purging the warm cache; no comparative build-time benchmark was recorded.
- Current blocker and diagnostic plan: [r271 title DCF4/outer-loop report](m3-r271-title-dcf4-outer-loop-20261029.md). No runtime behavior was changed; no first-mission frame was reached.

## Current attempted compression

The r267 closed-text archive-and-replace command was rejected by command policy before any files changed. A later request to archive/replace 20 historical `C:\Project` inventory CSVs was also rejected before any files changed; their raw files remain intact. No alternate deletion method was attempted. The 40 byte-identical texture-cache copies and all other previously identified candidates remain untouched. Space savings remain zero.

## r271 outcome and exact-workspace additions

The latest diagnostic establishes an unsignaled DCF4 wait at guest callsite `0x00211F3B`. Callback 453 / index 5 / target `0x0021701E` produced DCF4 set 127; callback 454 / index 1 / target `0x00216EC9` returned zero from the gate, and wait 128 has no return. Final raster queues were idle; this does not support a queued rendering backlog. The screen-gated input was sent only after guest callback progress had stopped and reached XID DMA without a later guest input predicate, so this run does not verify the new-pilot route. Details and exact bundle hashes: [r271 evidence report](m3-r271-title-dcf4-outer-loop-20261029.md).

The post-r271 scan was adjusted for the exact allocated/logical sizes of the four status/report text files changed after scanning; no other paths changed. Workspace allocation grew by 172,298,361 bytes (0.160466 GiB) from r270, mainly the diagnostic bundle and run evidence; this is retained evidence, not reclaimed space. No project files were removed or compressed. Build cache remains warm and incremental efficiency is unchanged.




### 2026-10-29 r275 post-run storage check

- r275 added one required side-by-side AOT EXE/PDB/MAP bundle and bounded run evidence. A fresh scan after the run measured 57,903,628,452 path-summed allocated bytes (about 53.93 GiB) and 1,381,557,088,341 logical bytes; the 01:29 inventory was 57,713,848,137 allocated and 1,381,321,314,588 logical. Delta: +189,780,315 allocated and +235,773,753 logical. Eight current allocation queries failed and 13 reparse points were skipped, so this is an approximate comparison. `frame.bmp`, logs and the 250,053-byte thread-metadata-only dump remain with r275. Its EXE/PDB/MAP remain necessary for exact evidence identity.
- The save root was reused without a hard link or dense copy. `Partition5.img` now hashes to `C4C72F67CCBA602E873D9C956DD70CF17123A973C282604B21DB56A1BC73A13D`, compared with prior retained `8D239A830ED2AD7797E7721D8E708E7720C206F1F190A8EA3EFEFA8CBA3588EC`. It was last written at process launch, before observed pilot inputs; cause of the change is uncertain. Current image retained.
- No files were removed. The earlier verified duplicate-cache removal was rejected before execution and was not retried. Reclaimed space remains 0 bytes. Warm incremental build retained; r275 build took 17.6 seconds. No cache purge or destructive cleanup.

## 2026-10-29 current refresh — r305–r309

Latest evidence and diagnosis: [r305–r309 loading/storage follow-up](m3-r305-r309-loader-contention-storage-20261029.md). Latest scan: `C:\Project\sb-inventory-current-20261029-final.csv` (76,453 files; 53,013,314,234 allocated bytes / 49.372 GiB; 1,382,783,304,537 logical bytes / 1,287.817 GiB; 13 Cargo reparse entries skipped; zero allocation-query failures). The largest logical/allocated mismatch remains sparse storage: 1,559 `.img` files consume 12,614,846,976 allocated bytes while representing 1,325,269,207,552 logical bytes. Original ISO allocation is 7.29 GiB. `iso` totals 32,090,235,306 allocated bytes; `local-tools` totals 20,702,226,668 bytes. The current route save root allocates 952,898,778 bytes; warm `build-xpp-seeded` remains 5,756,729,148 bytes.

### Verified space recovery

44 inactive `Cache\TEXOBJ.BIN` copies (47,159,808 bytes each) were SHA-256 checked before and after NTFS compression against canonical extracted `iso\local-analysis\game_files\Media\BIN\TEXOBJ.bin`, hash `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`. Candidate allocation fell from 2,075,031,552 to 1,535,688,704 bytes: **539,342,848 bytes (514.0 MiB)** recovered. Workspace allocation fell by **539,326,040 bytes net** between the pre-compression r309 inventory and the latest full inventory, including added project text. Contents and paths were retained. No deletion, relocation, or hard link was used. Read-performance effect is unmeasured.

The r308, r309, and final `C:\Project` inventory CSVs were separately losslessly compressed in place. Their allocated size fell from 44,102,952 to 11,288,576 bytes; all three hashes remained unchanged, saving **32,814,376 bytes** outside the workspace. Total measured disk recovery from the cache and inventory compression was **572,157,224 bytes (545.5 MiB)**.

### Protected and unresolved items

Preserve the original ISO and extracted media, all unique save partitions, the in-place route save, dirty source checkouts, manually edited generated source, licenses, the warm incremental build cache, and exact EXE/PDB/MAP bundles tied to unresolved dumps. r308/r309 used the same r293 bundle: EXE `34BC8D260EEED4B6E478A369F5E09F7C5364F5450DF2484248EED4260758FDEF`, PDB `47888B14279266AAF9AD8D64F18FC58EEAD3655482F507AEE7B6D87642DD6070`, MAP `52D507FED8336C51A5BCD3B1560F7DBF131E3E5ED9049956026A362BE476F745`. Their dumps remain paired with their run logs. The 64 MiB logical per-run cap had no hits or dropped relay lines in r308/r309. The r309 folder currently allocates 1,881,302 bytes.

The previous deletion attempt against duplicate TEXOBJ cache files was blocked by automatic file-policy review; it was not retried. Lossless compression reclaimed measured space while retaining every copy. No build ran; warm build cache and prior ~14.3-second incremental-build reference remain unchanged.

`tools\Start-ProducerTrace.ps1` now records pre/post allocated bytes for closed evidence compression and checks actual allocated size as well as logical length against the per-run budget. PowerShell parsing and the Win32 allocation helper comparison passed. Full runner integration is pending. No runtime fix is supported: r308’s shared `fprintf`/dispatch-gate interaction remains a leading hypothesis, and r309 did not reproduce the loading stage because its new-pilot route stopped at name entry. See the linked report for exact thread IDs, addresses, trace counts, and the next controlled input-to-loading reproduction.

## 2026-10-29 current refresh — r322–r329

Current loader and storage report: [r322–r329 follow-up](m3-r322-r329-loader-storage-followup-20261029.md). Full inventory: `C:\Project\sb-inventory-current-20261029-r329-final3.csv` — 76,870 files, **53,894,717,206 bytes allocated (50.193 GiB)**, **1,384,901,643,736 bytes logical (1,289.790 GiB)**, 13 reparse paths skipped. The logical total is dominated by sparse save/dump images.

Lossless NTFS compression of inactive `local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace-Candidates` reduced allocation from 5,655,499,291 to 4,779,202,012 bytes; logical bytes stayed 11,219,062,394 across 202 files. **Measured recovery: 876,297,279 bytes (835.7 MiB).** Net full-workspace allocation reduction after final report edits: 876,287,469 bytes. No files were deleted or relocated. Manifest audit SHA-256 matched 126 EXE/PDB/MAP files across 253 run manifests with zero mismatches; 74 files were not listed in those manifests (68 MAP, three EXE, three PDB) and remain retained. r326 EXE/PDB/MAP hashes were independently rechecked. The warm build tree remains 6.105 GiB allocated, including the compressed candidate subtree; the separate rollback tree is 0.955 GiB. Canonical generated AOT sources, original ISO, extracted assets, unique saves, and unresolved run bundles remain protected. No new build was run; r324's 8.65-second incremental build is the latest recorded reference.

Latest verified route remains r328 to `NOW LOADING`, followed by a black frame and mode-2 callback pair `0x000ABA00/0`; no asset dependency or behavioral defect is established. r329 stayed at the title invalid-player prompt and confirmed a distinct unsignaled DCF4 wait. Do not conflate these stages. The first mission frame remains unverified; no guest-behavior change was made.

## 2026-10-29 current refresh — r360–r363

See [r360–r363 title-route and storage review](m3-r360-r363-title-route-and-storage-20261029.md). r360 reached Normal difficulty but ended on white; r361–r363 stayed at the title route. r363 correlated the first A through XID and the guest edge at caller `0x000E081F`, advancing at `0x000E0840` to `0x0033331C`. Later XID pulses had no guest edge. Menu object `0x006B9E1C` repeatedly selected `skip-dispatch` with `global=0`, `state=0`; this is a candidate, not an established cause. Its 240-second watchdog captured dump `4B54742223E1D8EC53031552580387A1D89BA05F0E685F54A19FC37452DF959B` and stopped only diagnostic PID 177764. No loader callback or mission frame was observed. The exact r342 EXE/PDB/MAP bundle is retained.

Fresh scan `C:\Project\sb-inventory-current-20261029-r363.csv`: 77,064 files, **40,895,284,487 bytes allocated (38.087 GiB)**, **1,385,524,035,511 bytes logical (1,290.370 GiB)**, 13 Cargo reparse paths skipped. Warm `build-xpp-seeded` is 6,773,655,696 allocated bytes; logs 2,947,148,929 bytes; extracted media 1,800,138,464 bytes; route saves 952,898,778 bytes; canonical generated code 155,885,489 bytes. The r356 baseline was 40,882,496,274 allocated bytes, a +12,788,213-byte difference. No build cache or save was modified.

Closed r360–r363 evidence retains 49 hash-verified files, 35,829,245 logical bytes and 10,396,570 allocated bytes after compression. The pre-compression allocation query failed, so compression savings are unclaimed. The 40 historical TEXOBJ copies are byte-identical to extracted media and already compressed; a recheck reclaimed zero bytes.

The delete-later audit validated 271 same-run duplicate screenshots (249,768,234 allocated bytes), three exact duplicate tool archives (979,796,520 bytes), and 104 inactive old build outputs with no matching hash/path in 284 run manifests (862,520,020 bytes). The total validated set is 2,092,084,774 bytes allocated (1.948 GiB). Automatic file-action review rejected the removal command as “blocked by policy”; it failed before removing any candidate. No alternative deletion path was used. Workspace deletion savings remain **0 bytes**. Validation CSVs: `delete-later-duplicate-frame-validation-20261029.csv`, `delete-later-archive-validation-20261029.csv`, and `delete-later-obsolete-build-audit-20261029.csv`.

Lossless compression of the external final inventory CSV reclaimed **11,013,925 allocated bytes** on C: with unchanged SHA-256. This is outside the project workspace. The runner retains a distinct-screen ring capped at eight BMPs; its 64 MiB per-run stop threshold leaves a 16 MiB region for failure evidence including the terminal frame, with a 1 MiB final-frame allowance recorded in the manifest. Eviction/drop counts, nested evidence compression, and explicit conservative fallback/query-failure fields are recorded. PowerShell parsing passed; live runner/history behavior is unverified. No new build or gameplay test ran, and incremental build efficiency is unchanged/unmeasured.

## 2026-10-29 current refresh — r364–r367

See [r364–r367 save-path and storage report](m3-r364-r367-save-path-and-storage-20261029.md). The newest completed report before this refresh was r360–r363. r365/r366 reached the visible pilot-limit overlay. r366's empty UserData test still read `Partition1\TDATA` from extracted `game_files`; the nine 2,812-byte `user*.sav` files there were left untouched. r367 built a side-by-side AOT candidate with a temporary TDATA-to-TitleData rule and confirmed the new path, but crashed in the separate DirectSound invalid-list path before the pilot screen. No `NOW LOADING` or mission frame was reached. The rule remains uncommitted and diagnostic-only.

Current allocated inventory: 77,196 files, **41,332,845,295 bytes allocated (38.494 GiB)** and **1,391,343,582,521 bytes logical (1,295.790 GiB)**. Eight allocated-size queries failed on Cargo fingerprint/metadata files; no reparse directories were detected. Relative to the r363 inventory, allocation increased by **437,560,808 bytes** for retained runs, symbols, and the diagnostic save root. The warm build tree is 6,846,276,412 bytes (6.376 GiB); logs 2,961,013,714 bytes (2.758 GiB); extracted Media 1,793,425,624 bytes (1.670 GiB); original route save 952,898,778 bytes (0.887 GiB); canonical generated AOT source 155,887,568 bytes; r366 isolated save root 110,007,188 allocated / 5,421,425,882 logical bytes. r367's matching bundle allocates 72,642,560 bytes; its run evidence allocates 2,784,716 bytes.

Lossless NTFS compression of r366's closed isolated Cache preserved all 22 files and every SHA-256, reducing allocation from 178,019,034 to 109,873,556 bytes and recovering **68,145,478 bytes**. The audit `r366-empty-save-cache-exact-duplicates-20261029.csv` identifies 21 exact extracted-asset copies and the unique 76-byte `COPYCHECK.DAT`; nothing was removed. The broad verified 1.948 GiB deletion set remains because automatic file-action review rejected deletion as “blocked by policy.” A narrowly scoped removal of this r366 Cache was also rejected; no alternative deletion method was used. Workspace deletion savings are **0 bytes**.

The r367 incremental build took 9.6 seconds. Its run used the 64 MiB budget, retained three distinct frames, recorded one transient capture drop, hit no trace caps, and had no relay drops. Preserve its exact EXE/PDB/MAP with the crash log. No cache purge or save-image change occurred.

## 2026-10-30 current refresh — r364–r368

See [r364–r368 title-route and storage follow-up](m3-r364-r368-title-route-and-storage-20261030.md). The r368 surface-probe run reused the exact r367 EXE/PDB/MAP and enabled `RECOMP_DSOUND_SURFACE_TRACE=1`; it stayed at the title after two XID-delivered pulses and was stopped as this task's own diagnostic. It did not reach Campaign, so zero surface/list rows are not a negative test of the r340 corruption. No other game process was active or stopped.

Fresh Win32 allocated-size scan after compression: **77,240 files; 41,445,982,888 allocated bytes (38.600 GiB), 1,396,776,374,694 logical bytes (1,300.849 GiB)**; 8 small allocation queries failed, no reparse directories were found. This is **113,137,593 allocated bytes above the r367 inventory** and **550,698,401 bytes above r363**. The added r368 isolated save root is 110,007,188 allocated / 5,421,425,882 logical bytes; r368 logs use 2,442,927 allocated bytes. Both original-route and r366 save roots remain intact.

Current slices: `build-xpp-seeded` **6,918,920,350 bytes (6.445 GiB)**; logs **2,966,241,357 (2.763 GiB)**; extracted Media **1,793,425,624 (1.670 GiB)**; original route save **952,898,778 (0.887 GiB)**; canonical generated source **155,887,568 bytes**; r366 and r368 isolated save roots each **110,007,188 allocated / 5,421,425,882 logical bytes**. The current build-tree sum includes r367's three-file candidate bundle (72,642,560 allocated bytes), which was not included in the prior 6,846,276,412-byte slice; this corrects the warm-cache slice without a build or cache change.

r368 closed-run evidence compression recovered **4,910 bytes** with 12/12 lengths and hashes unchanged. Its inactive Cache had 22 files: 21 hashes matched the previously audited extracted-media assets, and unique 76-byte `COPYCHECK.DAT` was preserved. Lossless NTFS compression recovered another **68,145,478 bytes** with all 22 hashes unchanged. Total measured compression savings this pass: **68,150,388 bytes**. The workspace nevertheless grew by 113,137,593 bytes versus r367 because a separate sparse save root and new run/report evidence were retained. No file was deleted, no writable save was hard-linked, no build ran, and the warm compiler cache remains available. The prior 1.948 GiB deletion candidate is still blocked by automatic file-action review; no workaround was attempted.
