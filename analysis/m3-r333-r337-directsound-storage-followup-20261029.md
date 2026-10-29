# DirectSound write target and storage follow-up — r333–r337 (2026-10-29)

## Scope and protected state

The 2026-10-27 Luna/Astra handoff and newest available project report at the start of this pass were reviewed. At that time, r332 was the newest completed report and no game process was active. r333–r337 were launched only as this task's diagnostics; each was verified by PID and executable path before termination. No other game process was interrupted. The original ISO, active source checkouts, user saves, and canonical generated AOT source were not changed. No save was hard-linked, copied, or rewritten.

Milestone 3 remains active. No run reached or verified a mission frame. AOT execution, controller mapping, guest fences, and rasterizer baseline `1ea1871` remain in place. No guest behavior fix was made.

## Evidence by run

| Run | Exact executable and symbols | Observed result |
|---|---|---|
| r333 PID `175768`, `m3-dcf4-producer-r333-20261029` | r326 bundle; EXE `E7502F64808CFACEBAFDE44E17A913825CBA06619383C5217F9BF7B1C507B23B`; PDB `2CBB3AF641A4FC6B7C437BD32362823EFD6A33E8BFBAFEEAA7473C7A2DBF1B07`; MAP `6EC466A97F9EED2BFE580543AB6BA5FA4DFD931D50BFA0D02B1867014493D09F` | Reached the pilot-name editor after the empty-save route. DCF4 callbacks and event set/wait cycles continued. It crashed in the known DirectSound commit-list path at `sub_0021ED29+0x88`, guest fault `0xFFFFFFF4`; the final list node was invalid. No dump. This is separate from the historical r151 title DCF4 wait. |
| r334 PID `177536`, `m3-dsound-invalid-link-writewatch-r334-20261029` | Same r326 bundle above | Screenshot verifies Campaign menu. XID/DMA input and guest edge were consumed. At tick `554451156`, host TID `178296` wrote `0xFF000000` to guest `0x8038C08C`, `0x8038C098`, and `0x8038C09C`. Host RIP `0x7FF6FB25345C` resolves in `raster_batch_program`; disassembly places a pixel store at that instruction. About 0.4 s later the guest list walk saw `0xFF000080` links and faulted at `sub_0021ED29+0x88`, guest VA `0xFFFFFFF4`. This directly establishes that raster code wrote pixel values into the DirectSound list fields in this run. The exact render-target state and the later `FF000000→FF000080` change were not captured, so the full corruption chain and smallest safe fix remain unproven. Raster samples are expensive (up to 43 ms maximum batch in this run), but that does not establish the separate loader plateau cause. |
| r335 PID `174096`, `m3-raster-target-dsound-write-r335-20261029` | Same r326 bundle above | Saved frame is the title prompt, not a valid negative replay of r334's Campaign route. XID report byte 2 remained zero; no write or crash reproduced. DCF4/PB/DMA activity continued. A minidump was captured before this task's child was stopped. It was raw-scanned but not natively unwound; its caller chain is unestablished. |
| r336 PID `179316`, `m3-dsound-register-target-r336-20261029` | New side-by-side diagnostic bundle below | First A produced “Unable to load Player Record.” A second short A led to a black frame, but the input timing differed from r334. NV2A counters stopped at frame `0x126`, counter `0x509`, target `0x4FF`, fence `0x505`, with zero batches/pending work. This was not a comparable reproduction. A dump was captured. |
| r337 PID `31972`, `m3-dsound-register-target-r337-20261029` | Same new r336 bundle below | Repeated with A holds `500 ms` then `2,000 ms`. The second pulse appeared in XID/DMA (`report[2]=1`) but no corresponding guest edge was recorded. Framebuffer stayed black; telemetry stopped at frame `0xCE`, counter `0x377`, target `0x36D`, fence `0x373`, zero batches/pending work, and DCF4 zero. The watched fields had only nine valid initialization writes; no raster overwrite or DirectSound crash reproduced. A dump was captured before stopping this task's own child. |

The `PILOT-LIST-CB` at `0x000E18D8` is not needed to explain these title-stage outcomes and was not retested as a new hypothesis. r337 did not reach the pilot list. Do not conflate the r334 DirectSound corruption, the r335–r337 title/black transitions, the historical title DCF4 wait, or the post-difficulty loader plateau.

## Stack and wait validation

r335's minidump was raw-scanned only; no native unwind was run for that dump. For r336, DbgHelp was run on host TID `179348`; it unwound through `ntdll` and `KERNELBASE` to `your_game_recomp_producer_trace.exe+0x64A98F9`, then stopped at a non-module frame pointer (`0xDC0`). For r337, host TID `178216` reached the same game-image offset, then stopped at non-module frame pointer `0xDEC`. The raw stack scanner finds guest addresses such as `sub_00211E10+0xDD0` and `xbox_KeWaitForSingleObject`; these are address-looking stack words, not validated unwinds. Neither dump validates the raw guest chain. Treat the guest wait target, owning thread, expected producer, and last handoff as unresolved. r337's DCE4 wait/set records continue during the captured interval; DCF4 is zero. There is no evidence here for a persistent DCF4 wait or a raster backlog: the final telemetry has no batches or pending raster jobs.

Current `ObReferenceObjectByHandle` source behavior remains pending/completed as previously reviewed. These runs do not correlate its completion with loader readiness, so that relationship remains unverified rather than a renewed null-output diagnosis.

## Focused diagnostic change and build

Added trace-only register snapshots to `local-tools/steel-battalion-game/src/dsound_write_watch.c`: `RSI`, `R9`, `RBX`, `RDI`, `RCX`, and `R8` are now logged on each watched write, alongside the guest address/value and host RIP. This is intended to test whether the raster store's effective destination calculation overlaps the list. It changes no guest behavior and is opt-in. The compact reproducible patch is `patches/diagnostics/dsound-write-watch-registers-r336.patch`; reverse-apply validation passes against the edited source. The r337 watch records only the nine normal initialization stores; the new register fields and no-write result are in `iso/local-analysis/logs/m3-dsound-register-target-r337-20261029/dsound-write-watch.log`.

The isolated incremental candidate built successfully in 9.1 s; no existing candidate was replaced. Bundle: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-dsound-register-target-r336-20261029/Release/`.

- EXE SHA-256 `FB0A96509DF7310FBF5B5DD80AD2FAC6FA6C54DFA2D31EC7D2A627D59B46CC95`
- PDB SHA-256 `C7A0040729F95ED9EC980C8845B4A9A151CDD3B96F81B5ABAE1A88667063C3D5`
- MAP SHA-256 `36D9C1299372EB0475EFFF93BD4B3FC1F055038D199E5B8310EAA3DA734AF147`

No gameplay test passed. Both diagnostic runs stopped with black frames before the pilot list; r334 remains the latest direct crash reproduction. There were no dropped stdout/stderr lines in the r336/r337 run manifests. Both dumps, run logs, and exact symbols remain retained.

## Storage accounting

Fresh inventory `C:\Project\sb-inventory-current-r337-final-20261029.csv` reports **76,986 files**, **53,463,861,377 bytes allocated (49.792 GiB)**, and **1,385,102,464,443 bytes logical (1,289.977 GiB)**; 13 reparse entries were skipped. The allocated and logical totals are separate; sparse images explain much of the logical total. Top allocations are `iso` **29.49 GiB** and `local-tools` **20.09 GiB**.

Retained working-set slices: `build-xpp-seeded` **6.17 GiB allocated / 12.29 GiB logical** (2,201 files); canonical generated AOT source **0.14 / 0.14 GiB** (27 files); current route saves **0.89 / 5.05 GiB** (29 files); diagnostic logs **3.47 / 964.57 GiB** (20,212 files). Sparse file lengths account for most of the apparent log/save logical size. The r336 incremental build completed in 9.1 seconds, close to the existing 8.65-second r324 measurement; the hot build cache was not cleared.

Lossless compression retained the evidence and all hashes matched:

- r334+r335 evidence: **842,384 allocated bytes saved**; audit `analysis/r334-r335-evidence-compression-20261029.csv`.
- r336+r337 evidence and their matching r336 bundle: **1,785,849 allocated bytes saved**; audit `analysis/r336-r337-and-r336-bundle-compression-20261029.csv`.
- Combined compression saved **2,628,233 bytes**. No files were deleted or moved. The new candidate and traces increased total workspace allocation versus r332; this is the net cost of retaining the unresolved exact-bundle evidence, not a reduction in project footprint.

The 40 historical `TEXOBJ.BIN` copies were independently hash-validated in `analysis/cleanup-texobj-duplicate-deletion-r333-20261029.csv`; one canonical source and current route cache are retained. A direct deletion attempt was blocked by automatic file-action review with “blocked by policy,” even after validation-only evidence was prepared. No alternate deletion mechanism was used. Those copies therefore still occupy about **1.30 GiB allocated**; realized deletion savings are **0 bytes**.

## Next test

Before another run, correlate the exact pixel-store effective address and current color-surface base/format/clip state on the same event. Reproduce the r334 Campaign state with a verified visible frame before accepting a negative watch run. The current r337 no-write result does not reject the raster-overwrite hypothesis because it never reached the same screen. Do not change rendering or DirectSound behavior until one trace correlates the bad store, surface state, and list corruption. Then rerun the same route and stop at the first visually verified mission frame; report any remaining loader or campaign coverage as unverified.
