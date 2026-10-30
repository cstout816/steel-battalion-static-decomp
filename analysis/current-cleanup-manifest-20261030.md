# Current cleanup and storage manifest — 2026-10-30 (r378)

## Current workspace size

Fresh full inventory: `sb-inventory-current-r378-final3-20261030.csv` and its `.skipped.txt` companion, stored outside the repository. The scan contains **77,488 ordinary files**, **41,317,624,956 allocated bytes**, and **1,396,926,759,702 logical bytes**. Thirteen Rust-toolchain reparse executables were excluded from the file walk and separately queried: **165,381,632 allocated bytes**. Combined working-set allocation is therefore **41,483,006,588 bytes (38.634 GiB)**. Logical sparse-file lengths are shown separately and do not represent disk usage. The scan reported no inaccessible ordinary-file allocation queries.

| Retained area | Allocated | Logical |
| --- | ---: | ---: |
| `local-tools` | about 19.50 GiB | about 277.41 GiB |
| `iso` | about 18.76 GiB | about 1,023.32 GiB |
| Warm `build-xpp-seeded` tree | 6,918,921,034 B | 13,871,927,762 B |
| Canonical generated AOT source | 155,887,568 B | 155,887,568 B |
| r368 route saves | 110,700,940 B | 5,422,134,482 B |
| `iso/local-analysis/logs` | 3,001,566,173 B | 1,035,998,455,517 B |

The warm incremental build remains at its last measured duration of about **9.1 seconds**. No build ran in r376–r378, and the warm cache was not purged, so no build-efficiency regression was measured.

## Evidence retention and realized space savings

Closed r376–r377 `.bmp`, `.log`, and `.dmp` files were NTFS-compressed in place. Before/after hashes matched for all 35 files, and allocated use decreased from 6,764,601 to 4,134,401 bytes: **2,630,200 bytes actually reclaimed**. Audit: `analysis/r376-r377-closed-evidence-compression-20261030.csv`.

Closed r378 evidence was compressed in place after the diagnostic exited. All nine `.bmp`/`.log` hash checks matched; its final allocated use is **993,646 bytes** for **4,301,017 logical bytes**. The pre-compression allocation was not recorded, so no exact r378 savings are claimed. No file was deleted or moved. No save was hard-linked or copied. No hot compiler/Cargo cache or canonical generated source was changed.

The bounded r378 run ended with 13 files in its run folder, no relay drops, 3 retained frame-history images, and an actual run directory allocation of 993,646 bytes after compression. Its run cap was 64 MiB; the cap did not trigger.

## Delete-later archive and protected material

The external delete-later archive remains at **383 files**. Its last measured size is **1,329,496,337 allocated / 2,092,257,079 logical bytes**. It contains historical duplicate captures, duplicate tool archives, and old diagnostic build material. Prior audits validated same-run screenshot duplicates and hashes, but exact deletion was rejected by file-action review; no workaround or alternate deletion was used. Realized deletion savings remain **0 bytes**. NTFS compression of the already-compressed duplicate BMPs reclaimed **0 bytes**.

Preserve the 104 older diagnostic build bundles until every unresolved dump reference is audited. Keep the r367/r149 exact EXE/PDB/MAP bundles, rollback bundle, canonical incremental build cache, source checkouts, manually edited generated-code source, licenses, original ISO/game files, and unique save data. Directory names and older cleanup manifests alone do not prove a file is redundant.

## Current diagnostics and next storage-aware step

The current run report is [r376–r378 loading evidence](m3-r376-r378-loading-evidence-20261030.md). r377's last traced `STRM07.WAV` read completed successfully; its mode-2 worker remained pending with a zero loader output pair, but the missing readiness producer is not identified. r378 ended at a black title frame before its delayed owner snapshot. No runtime fix or new build is justified from those traces.

Keep one canonical generation and the existing warm build cache. Continue per-run 64 MiB caps, eight-frame history, closed-log compression, and explicit trace/drop counters. For the next replay, capture only the loader worker's recent file-completion window, pending-to-completed thread transition, loader pair, and a snapshot taken after mode 2 begins. This keeps evidence useful without restoring high-volume startup logging.
