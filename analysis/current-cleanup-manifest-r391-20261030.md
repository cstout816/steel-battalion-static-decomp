# Current cleanup manifest — r391, 2026-10-30

## Current footprint

Fresh `tools/Measure-WorkspaceInventory.ps1` scan: **77,572 ordinary files**, **41,358,393,176 allocated bytes**, **1,397,117,750,835 logical bytes**, zero allocation query errors. Thirteen Rust tool reparse executables add **165,381,632 allocated bytes**. Combined path-summed retained working set: **41,523,774,808 bytes / 38.67 GiB**. Logical size is larger because the save images and other sparse files contain large unallocated ranges.

Inventory outputs are outside the workspace: `C:\Project\sb-inventory-current-r391-postpush-20261030.csv` and `.skipped.txt`.

| Retained working area | Allocated | Logical |
| --- | ---: | ---: |
| Warm `build-xpp-seeded` | 6,918,921,034 B | 13,871,927,762 B |
| Canonical generated AOT source | 155,887,568 B | 155,887,568 B |
| r368 save root as used in r391 | 166,480,594 B | 5,422,134,482 B |
| `iso/local-analysis/logs` | 3,043,619,235 B | 1,036,190,731,492 B |
| r391 run folder | 7,036,441 B | 23,924,439 B |

The top-level allocation is dominated by `local-tools` (19.50 GiB) and `iso` (18.80 GiB). Preserve the original ISO, extracted media, dirty source checkouts, manually edited generated code, licenses, warm cache, rollback build, unique saves, and exact EXE/PDB/MAP bundles for unresolved dumps. The r391 Partition5 hash remains `D03911131ECB5DFABE16F33175FFC098F0ACAA57B105454149EB1AB084280183`; no save hard links were created.

## Verified reclaim and candidates

- r386–r390 in-place closed-evidence compression reclaimed **11,522,408 allocated bytes**, with all before/after hashes unchanged.
- r391 closure check compressed 15 closed `.log` and `.bmp` files; hashes were unchanged and allocation did not decrease (0 bytes reclaimed).
- No deletion or cross-volume move occurred. Do not route around the previous automatic review rejection for deleting duplicated cache files.
- Forty closed historical `Cache/TEXOBJ.BIN` copies were rehashed against retained extracted media: all are 47,159,808 bytes, SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`, path-summed allocation 1,396,080,640 bytes. Keep pending safe cleanup authorization/review; earlier direct deletion was rejected. NTFS compression is not a useful alternative for these copies.
- r391 run storage stayed below the 64 MiB cap; relay drops 0; trace-limit hits 0. Frame history cap=8, saved=25, retained=8, evicted=17, dropped=1. Preserve all current stage/failure captures and exact unresolved dump bundles.

The current total is **27,672,977 bytes above r385**; this is a net inventory difference and is not attributed to one run. Warm incremental build cache remains 6,918,921,034 bytes; last measured incremental build about 9.1 seconds; no build ran during this review.