# Current cleanup and retained-working-set manifest — r406

## Current measured size

The final full workspace inventory is stored outside the repository at `C:\Project\sb-inventory-current-r406-final-20261030.csv` with the `.skipped.txt` companion. The 77,892 ordinary-file rows exclude 13 reparse-point toolchain executables, which were measured separately with `GetCompressedFileSizeW`.

| Measurement | Bytes |
|---|---:|
| Ordinary files, allocated | 41,580,672,786 |
| 13 executable reparse entries, measured separately | 165,381,632 |
| Combined allocated | 41,746,054,418 (38.88 GiB) |
| Ordinary-file logical lengths | 1,397,678,345,439 |

Logical length is reported separately; sparse partition images are not fully allocated. The 13 skipped entries are Rust/Cargo toolchain executables, not game files.

## This pass's measured space recovery

| Action | Files | Allocated bytes saved | Verification |
|---|---:|---:|---|
| Lossless NTFS compression of closed r402–r405 evidence folders | 61 | 3,777,586 | SHA-256 unchanged for all files |
| Lossless compression of closed r406 live-loader dump | 1 | 815,168 | `979AD65B327F49A393462A7E1D2D0AD403F03CBEC43C955FD0360874750CEE46` unchanged |
| **Measured total** | **62** | **4,592,754** | No content changed |
| Deleted files | 0 | 0 | Duplicate deletion was rejected by automatic file-action review (“blocked by policy”); the command did not run |

The 269 old screenshot candidates in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-log-frames` remain. Earlier r375/r377 audits recorded matching hashes and retained copies. The new revalidation/deletion action did not execute, so this manifest does not claim a fresh current hash check or deletion savings. Same-drive quarantine is not counted as reclaimed capacity.

## Protected working set

| Path/category | Allocated | Logical | Handling |
|---|---:|---:|---|
| Original Xbox ISO and extracted user game data | Preserved | — | Untouched |
| Canonical generated AOT source | 155,887,568 | 155,887,568 | Preserved; no generated game source committed |
| Existing r368 save root | 110,706,488 | 5,422,140,030 | Reused directly; no copy or hard link |
| Warm `build-xpp-seeded` tree | 7,064,232,890 | 14,211,961,318 | Preserved for incremental builds; includes r406 candidate |
| r406 EXE/PDB/MAP bundle | 72,658,944 | 170,004,182 | Retained with the unresolved r406 dump |
| Dirty XboxRecomp checkout | Preserved | — | r406 diagnostic-only source delta documented by a compact patch/hash manifest |
| Unique saves, licenses, and exact symbol bundles for unresolved dumps | Preserved | — | Not purged or relinked |

The side-by-side r406 build took about 10 seconds. It emitted warnings at existing source locations outside the new heap-trace lines. No compiler/Cargo cache was purged and no sparse save was copied densely.

## Growth controls and remaining limits

The runner enforces a 64 MiB per-run budget, retains at most eight framebuffer history files, reserves failure evidence, reports cap/drop counters, and compresses closed `.bmp` and `.log` files. r406 used 14.9 MB logical run evidence, had zero async relay drops, and did not reach the storage budget. Its wait trace did hit `[WAIT-DCE4-CAP] seen=8192 limit=8192`; terminal event state is therefore unavailable. The live dump was compressed after closure because the runner's automatic compression measurement was unavailable (`-1` values).

The historical log tree contains 9,218 BMPs (983,547,904 allocated / 8,576,148,992 logical bytes), 6,063 logs (1,219,333,360 / 3,785,772,020), and 418 dumps (98,368,002 / 674,912,642). All BMP allocation and all but 8,964 bytes of log allocation are already NTFS-compressed. About 12,732,930 bytes across uncompressed dumps remain as retained failure evidence; no content-only space recovery is evident there without risking useful diagnostics. The validated duplicate-image set is still the main immediate recovery opportunity, but automatic review rejected deletion before execution. No alternate deletion route was used.

The post-status workspace is **38.88 GiB allocated** and **1,397,678,346,351 ordinary-file logical bytes** (plus 165,381,632 logical bytes for the separately measured toolchain executables). This pass measurably recovered **4,592,754 allocated bytes**, with no deletion savings. The warm build tree, generated source, unique save root, dirty source checkout, and exact unresolved-dump symbol bundles remain retained.

Post-status recount: `C:\Project\sb-inventory-current-r406-poststatus-20261030.csv` measured 77,892 ordinary files, 41,580,673,698 allocated bytes and 1,397,678,346,351 logical bytes. The 13 executable reparse entries add 165,381,632 allocated bytes, for **41,746,055,330 bytes combined (38.879 GiB)**. This supersedes the earlier count in this manifest.
