# Current cleanup and storage manifest — r441 — 2026-10-30

## Measurement

The latest full workspace inventory measured **39,432,518,326 allocated bytes (36.724 GiB)** and **1,398,728,252,909 logical bytes (1,302.667 GiB)** across 78,644 ordinary files; 13 reparse entries were skipped. Allocated size is measured separately from logical length because sparse files account for much of the difference. Compared with the r440 scan, workspace allocation increased by 2,423,578 bytes.

The scan CSV was written under `%TEMP%\steel-battalion-r441-inventory.csv`, outside the repository. No inventory CSV was added to the project.

## Retained working set

| Area | Allocated | Logical | Handling |
|---|---:|---:|---|
| `local-tools/steel-battalion-game/build-xpp-seeded` | 7,354,916,122 B | 14,892,036,516 B | Preserved warm incremental build tree; no build or cache purge |
| `iso/local-analysis/saves-m3-route-file-read-copy-20261023` | 952,910,026 B | 5,422,140,106 B | Preserved and reused in place; no copy or hard link |
| `iso/local-analysis/logs/m3-loader-3fff-writer-r441-20261030` | 2,334,966 B | 8,150,792 B | Retained evidence; budget 64 MiB, no budget hit |
| Exact r426 EXE/PDB/MAP bundle | Per run manifest | Per run manifest | Preserved for r441 and unresolved stack/address evidence |

r441 retained four recent framebuffer captures. Thirteen were captured and nine evicted; trace-line and capture drop counts were zero. Its run storage cap was not reached. The run stopped after the 180-second NV2A progress plateau and preserved the same-run dump. No original game files, unique saves, dirty source, generated source, licenses, active build inputs, or rollback/symbol bundles were removed or moved.

## Verified duplicate archives outside the workspace

The following candidates are in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`, outside the scanned project workspace. Current SHA-256 checks matched their retained keeper copies; the dependency/reference review found no runtime/code/config references. Ghidra filename mentions are limited to historical cleanup documentation and the cleanup-manifest generator.

| Candidate | Retained keeper | Verified SHA-256 | Logical bytes | Allocated bytes |
|---|---|---|---:|---:|
| `ghidra_12.1.4_PUBLIC_20260921.zip` | `local-tools/reverse-engineering/ghidra.zip` | `DDAC49F903DA9D5BAC833E5CC79395098B9C33CFD3279BE5F31BD00387D2D4DB` | 569,649,598 | 569,032,704 |
| `jdk21-duplicate-reverse-engineering.zip` | `local-tools/analysis-deps/downloads/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip` | `F9D6E191AB098C0D416E7D588A24420A8621CD2F4720DAB2459B8B7B2D2D8B4E` | 205,073,461 | 203,616,256 |
| `temurin21-duplicate-ghidra-analysis.zip` | Same OpenJDK21 keeper | `F9D6E191AB098C0D416E7D588A24420A8621CD2F4720DAB2459B8B7B2D2D8B4E` | 205,073,461 | 203,616,256 |
| **Total** |  |  | **979,796,520** | **976,265,216** |

The exact-path removal command was rejected by the local policy gate before it ran. **None of the three candidates were deleted; allocated-space savings from archive removal are zero.** No alternate deletion mechanism was attempted. The duplicate files remain available in the delete-later folder, and the keepers remain intact.

## Actual space change and next storage action

No allocated bytes were reclaimed this turn. The workspace rose by 2,423,578 allocated bytes compared with r440; r441's own folder accounts for 2,334,966 allocated bytes. The route save root rose 2,812 allocated bytes from r440 and was preserved. The measured warm build tree is unchanged, so build-efficiency impact is zero.

Next storage action: resolve the local policy block before attempting any deletion. Retain the exact paths and keeper hashes above; do not retry removal through a different mechanism without a policy-approved path. Continue to avoid dense copies of sparse images and do not purge the build cache while its current source/build relationship remains useful.

Full diagnostic details: [m3-r441-handle-slot-writer-and-loader-stall-20261030.md](m3-r441-handle-slot-writer-and-loader-stall-20261030.md).
