# Current cleanup manifest — 2026-10-30, r393

## Measured footprint

- Fresh inventory: `C:\Project\sb-inventory-current-r393-20261030.csv` and `.skipped.txt`.
- Scanner covered 77,618 ordinary files. Sum: **41,362,397,587 allocated bytes**; **1,397,127,080,506 logical bytes**. It skipped 13 Rust executable reparse entries (no traversal through those entries); their separately measured allocation is 165,381,632 bytes. Path-summed working footprint including those entries: **41,527,779,219 allocated bytes / 38.67 GiB**. Logical size is sparse capacity and must not be treated as disk use.
- Prior r391 path-summed footprint: 41,523,774,808 allocated bytes. Net measured change: **+4,004,411 bytes**. No files were deleted or moved in r392/r393; net change is not attributed to a single artifact.
- r393 closed diagnostic tree: 14 files, 1,781,485 allocated bytes. r393 dump SHA-256: `AD792F7FDC7BBA9F70FBDEC68D93AA9CAF276AA4224028C7D595E6D903168EB5`.
- Canonical warm `build-xpp-seeded`: 6,918,921,034 allocated bytes / 13,871,927,762 logical bytes. Canonical generated-source tree: 155,887,568 allocated bytes. r368 isolated save root: 110,706,564 allocated bytes / 5,422,140,106 logical bytes. These are directory totals; do not add overlapping parent/child rows.

## Retain / protect

- Original ISO and all user game files.
- Unique writable saves and the isolated r368 route save data. Preserve the r367 run's pre/post hashes when comparing route state. No hard links for writable images.
- Current canonical generated source, dirty XboxRecomp and game-source checkouts, manually edited generated tracing code, license files, and the compact patch/source manifests that preserve unique changes. Do not commit generated proprietary game code.
- Warm incremental build/intermediate cache (6.92 GB allocated) and current rollback source/patch state. The last incremental build took about 9.1 seconds; no build was run for r393.
- Exact r367 EXE/PDB/MAP bundle needed for r382/r391/r392/r393 dumps. Preserve each bundle with its exact dump until unresolved failures no longer require it.
- Existing r150/r151/r153 evidence and each cited loader, DirectSound, or title-stage run. Keep title DCF4, DirectSound corruption, rendering cost, and the mode-2 loading plateau as separate cases.
- r392 and r393 traces/dumps until their updated reports are committed and references verified. r393 trace manifest shows zero relay drops, but a missing optional watchdog snapshot and sampled traces limit coverage.

## Safe space controls and verified savings

- Previous closed-evidence compression r386–r390 reclaimed **11,522,408 allocated bytes**; content hashes were stable. No additional bytes were reclaimed in r392/r393.
- Keep the existing bounded diagnostic run budget (64 MiB per run), zero-drop relay counters, trace-limit counters, and closed-log compression workflow. r393 stopped at the DCF4 watchdog before reaching the 64 MiB budget. Do not raise first-N trace caps; use bounded recent-context retention for the next failure window.
- Preserve screenshots losslessly and keep stage/failure captures plus their run identities. Validate pixel equality and reference updates before replacing a BMP with PNG. Do not remove duplicates based only on folder names or prior manifests.
- Keep one canonical generation and warm build cache. Revalidate duplicate and reproducible artifacts against current references before any retirement. Same-drive moves do not reclaim space; sparse images must not be copied densely.
- The rejected earlier automatic file-action review remains a constraint: no alternate deletion method was used. This manifest authorizes no broad deletion set.

## Deferred candidates

Historical captures, redundant review copies, old save-image sets, superseded diagnostic output trees, and duplicate texture caches remain candidates only where their hashes, references, save uniqueness, active-process ownership, and exact dump/symbol dependencies are revalidated. Continue with these high-allocation areas before purging build/Cargo caches. Record an actual before/after allocation and volume-free-space delta for each cleanup action.
