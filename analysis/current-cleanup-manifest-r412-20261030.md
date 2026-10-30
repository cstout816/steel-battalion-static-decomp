# Current storage and cleanup manifest — r412 — 2026-10-30

## Current measurement

Source: `C:\Project\sb-inventory-current-r412-postpush-20261030.csv`, generated from the workspace with `tools/Measure-WorkspaceInventory.ps1` after the report commit and push.

| Measure | Result |
|---|---:|
| Ordinary files | 78,048 |
| Allocated bytes (ordinary files) | 41,653,173,364 |
| Logical bytes (ordinary files) | 1,397,898,600,374 |
| Reparse executable entries | 13; separately measured 165,381,632 allocated bytes |
| Combined allocated footprint | 41,818,554,996 bytes / 38.947 GiB |
| Logical ordinary-file length | 1,397,898,600,374 bytes / 1,301.895 GiB |

Logical length must not be interpreted as actual disk consumption. The workspace contains sparse save/partition images; never replace them with dense copies. The ordinary-file inventory uses `GetCompressedFileSizeW` to report allocated bytes, and the 13 Rust/Cargo executable reparse entries are listed separately in the CSV's `.skipped.txt` companion.

## Reclaimed and retained

- r411/r412 closed diagnostics were losslessly NTFS-compressed after inventory and SHA-256 validation. 37 files used 4,087,125 allocated bytes before and 3,247,595 after. **Verified reclaim: 839,530 allocated bytes.** Hashes and logical lengths were unchanged.
- Reused build cache: `local-tools/steel-battalion-game/build-xpp-seeded`, 7,136,856,349 allocated bytes. Retained for incremental build efficiency; no build was run during this pass.
- Canonical generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current`, 155,890,474 allocated bytes. Preserved.
- r368 save root: `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`, 110,712,188 allocated / 5,422,145,730 logical bytes. Reused in place; no copy or hard link created.
- Original game files, ISO, unique save data, dirty source/generated changes, exact EXE/PDB/MAP bundles, current build cache, and failure evidence were preserved.

## Candidates and blocked action

Three old archive copies were byte/hash-validated against retained copies. Their measured allocation is 569,032,704 + 203,616,256 + 203,616,256 = **976,265,216 bytes**. The exact removal action was rejected by file-action review before execution. No files were deleted, and no alternate deletion method was tried. The files remain in place and must remain accounted for in the footprint until a permitted cleanup action succeeds.

No other large artifact is classified as safe to remove by this manifest. Older cleanup CSVs, directory names, and duplicate claims do not establish current deletion eligibility.
