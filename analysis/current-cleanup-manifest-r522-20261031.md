# Current cleanup and protected-set manifest — r522, 2026-10-31

## Measurement method

Targeted `GetCompressedFileSizeW` allocated-byte measurements, path-summed; reparse entries excluded. Sparse logical lengths are reported separately. This is not a new whole-workspace inventory or a volume free-space delta.

| Tree | Files | Logical bytes | Allocated bytes |
| --- | ---: | ---: | ---: |
| `build-xpp-seeded/ProducerTrace-Candidates` | 270 | 14,789,346,013 | 6,305,103,821 |
| `local-tools/steel-battalion-game/iso/local-analysis/logs` | 3,402 | 276,258,442,058 | 4,821,252,507 |
| Original ISO | 1 | 7,825,162,240 | 7,825,162,240 |
| Extracted canonical game files | 1,244 | — | 1,800,138,464 |
| Unique writable route save root | 36 | — | 952,918,462 |
| Canonical generated `gen` | 27 | — | 155,904,048 |
| r513 exact EXE/PDB/MAP bundle | 3 | — | 72,765,440 |
| Warm memory-regression cache (`C:\Project`) | 578 | — | 56,094,774 |
| r522 run evidence | 12 | — | 1,845,944 |

The protected original-input/extracted-data/unique-save floor is **10,578,219,166 allocated bytes (9.852 GiB)**. This floor excludes dirty source checkouts, edited generated code, licenses, tools, build state, rollback patch, and exact symbols/dumps needed for unresolved failures. The last known warm `build-xpp-seeded` total was 7.524 GiB, including the 6.305 GB candidate history; do not add those overlapping figures. The warm regression cache was reused without rebuilding.

## Audit results and action

Candidate history has 87 EXEs, 87 PDBs, and 92 MAPs. All 266 non-JSON/TXT/log candidate binaries and symbols were SHA-256 hashed. No positive-size exact duplicate EXE/PDB/MAP was found; the only repeated hashes were five zero-byte MAP files. Preserve every nonempty EXE/PDB/MAP bundle until its corresponding dump/reference is retired.

The nested log allocation is distributed across many historical run directories. By extension, `.bin` files account for about 2.99 GiB allocated, `.wav` about 1.23 GiB, `.exe` about 0.13 GiB, and `.bmp` about 0.12 GiB. The 306 `.img` files have about 249 GiB of logical length but only about 0.01 GiB allocated; 255 are sparse. Do not densify or copy them. A prior exact-content/reference audit found repeated historical logs/cache files, including repeated save-cache `TEXOBJ.BIN` files. Their removal action is still subject to the recorded automatic-review rejection. No alternate deletion route was used.

No files were deleted, moved, recompressed, or copied this turn. **Allocated-space savings: 0 bytes.** r522 added **1,845,944 allocated bytes** of bounded evidence. No new build variant or full generated tree was created. Test time was under one second using the existing warm cache; build efficiency is unchanged. Prior verified compression savings remain 19,116 bytes cumulative from r519–r521.

## Preserved state

- Original ISO, canonical extracted files, all unique save roots, current generated source, dirty source checkouts, local-only source patch, licenses, warm incremental build state, and current rollback candidate.
- Exact r513 EXE/PDB/MAP bundle and symbol/dump sets required to interpret unresolved run failures.
- r522 `title-stall.dmp`, frame history, `stderr.log`, `wait-trace.log`, environment manifest, and input transcript.
- The save root used in r522 remains in its post-run state. The process touched `Partition0.img`–`Partition5.img` and wrote `Cache\COPYCHECK.DAT`; no full save copy or hard link was made.

## Next measured opportunity

The candidate history has no positive-size duplicate executable/symbol bundle to retire based on hashes alone. The historical-log tree's `.bin`/`.wav` allocated space is the next potential target, but each cache/save copy must be checked against its exact run and surviving references, and deletion remains prohibited by the recorded review result. Keep the sparse partition images, saves, compiler/Cargo caches, and unresolved symbol bundles intact. Avoid another full inventory until there is a real cleanup action to validate.
