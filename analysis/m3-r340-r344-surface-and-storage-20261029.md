# Steel Battalion AOT surface overlap and storage follow-up — r340–r344

## Scope and protected state

Reviewed `analysis/project-review-and-luna-high-handoff-20261027.md`, then the newer completed reports through r337 and the exact older r151/r153 evidence before r344. At initial inspection there was no game process running; the review-era r154 PID was no longer active. All later game PIDs in this report were diagnostics launched by this task. They were verified by executable path before stopping. No other chat's run, original ISO, save image, dirty source checkout, canonical generated source, license, or shared build input was interrupted or modified. No save was copied or hard-linked.

Milestone 3 remains active. AOT execution, controller mapping, guest fences, and rasterizer baseline `1ea1871` were kept. No guest behavior fix, forced event, preload change, or import seed was made. The first visually verified mission frame remains **0/1**.

## Earlier dump evidence checked before r344

- r151 used exact r149 EXE SHA-256 `D503E6DA6325E9771364C9160F358A21550128B34AAC7B500A34C0EE0642A15C`, PDB `1741EA1E29FEF3DF22182C934AF3E30BAECCCB0DFFB93C1649080095A2A94287`, and MAP `4AE43B0B58C029D290E9041297232C303E9EBF0E8FC04D54761EB5BBFE4A6A37`. Its TID `138096` native unwind validates the host wait bridge but stops at non-module `0x1010`; the synchronized guest trace identifies wait #73 on DCF4 from `sub_00211E10+0xDD2`. Callback #391 used index 1; no subsequent index-5 callback or `KeSetEvent` occurred. This is a title-stage missed-input/event-production failure, not a mission-loader diagnosis.
- r153 used exact r149 symbols and its user-authorized stop dump. The dump provides a point sample in `DspState::read_memory+0x82`, not a validated guest wait chain. Graphics callback/frame/counter/target/fence progress had stopped while host timer telemetry advanced; DCF4 and DMA acknowledgement traces had capped before terminal state. It cannot identify a loader dependency or establish that raster cost caused the plateau.
- These stages remain distinct from r340's Campaign-stage DirectSound-list crash. r130's null-output handle issue is already implemented; no repeated null-output fix was attempted.

## r340: confirmed pixel writes into DirectSound list fields

Run `m3-dsound-register-target-r340-20261029`; diagnostic PID `179820`; process ended naturally with access violation. It followed the visible Campaign route. The run used the exact r336 bundle:

- EXE SHA-256 `FB0A96509DF7310FBF5B5DD80AD2FAC6FA6C54DFA2D31EC7D2A627D59B46CC95`
- PDB SHA-256 `C7A0040729F95ED9EC980C8845B4A9A151CDD3B96F81B5ABAE1A88667063C3D5`
- MAP SHA-256 `36D9C1299372EB0475EFFF93BD4B3FC1F055038D199E5B8310EAA3DA734AF147`
- Dump SHA-256 `666707DD3DC2D2EAA5333ABD27BE21AA6885160E5EB22A4E8DFA9185EDD8C85D`; dump size 525,741 bytes.

At tick 556333750, TID `177408` stored `FF000000` at host addresses `8039C08C`, `8039C098`, and `8039C09C`, corresponding to guest addresses `8038C08C`, `8038C098`, and `8038C09C`. The register record has RSI/base `8039C000`, R9 indices `0x23`, `0x26`, `0x27`, and RBX pixel value `FF000000`; `base + index*4` matches each target. The host RIP `0x7FF63902352C` resolves in the exact image to `put_pixel+0x4AC`. The list walker then reported invalid node/predecessor values and faulted in `sub_0021ED29+0x88` at guest VA `FFFFFFF4`. This establishes the corrupting writer and the immediate list-fault chain for this run.

The active NV2A color-surface state at those exact stores was not recorded. Nearby draw summaries report a Vulkan presentation path, color offset `0x001B0000`, and a 640x480 clip; they are not synchronized with the store and do **not** establish which target supplied `s_surface`. A native unwind for TID `177408` reached the host wait path and stopped at non-module `0x194`; it does not validate the raw guest-address scan. TID `173024`'s unwind stopped inside VCRUNTIME and does not identify the pixel writer's guest caller. No source-level target-selection defect or safe behavior fix is established yet.

## Bounded diagnostic and follow-up runs

Added opt-in `[DS-SURFACE-PIXEL]` trace in `local-tools/xboxrecomp/src/kernel/nv2a_pb_exec.c`. It only records pixel destinations overlapping the three observed host addresses and logs color offset, resolved surface, pitch, format, clip, coordinates, pixel value, surface base, and raster mode; a strict cap limits it to 16 records. `tools/Start-ProducerTrace.ps1` now exposes `-EnableDsoundSurfaceTrace` and writes the effective setting to the environment snapshot. Patch snapshots are `patches/diagnostics/dsound-surface-overlap-r341.patch` and the current XboxRecomp source preservation patch. Generated game source is not included.

- The first build attempt failed because the diagnostic used a nonexistent surface-format member. That compiler error was corrected (`s_gpu.format`); no failed executable was launched. Successful side-by-side candidate r342 built on the warm cache in roughly 10 seconds. Its EXE SHA-256 is `727864FBDF2F3623D8BCEF7C9D8EB310E8F28CD4BC75BE340F875FDFCACED998`; matching PDB and MAP hashes are in the cleanup/run inventory.
- r342 reached a visually confirmed Campaign menu and `PILOT-LIST-CB` owner 1 at `0x000E18D8`, but the new surface-trace environment flag was absent. The DS write watch saw no watched-address write during its retained route window. It was manually stopped as this task's own PID `177684`. This is a bounded non-reproduction, not a rejection of r340.
- r343 enabled the surface-trace setting but stopped at the title's “Unable to load Player Record” prompt and then a black frame. NV2A telemetry flattened with DCF4 zero, zero raster batches/pending work, and no pilot-list callback. It was stopped as this task's own PID `179752`; no post-black input was sent. This run did not reach the Campaign test state.
- r344 used the same r342 binary with the new trace flag confirmed in `environment.txt`. A single screen-gated A reached the player-record warning; a second A led to a black frame. The saved framebuffer and telemetry show a title-stage freeze at frame `0x160`, counter `0x625`, target `0x61B`, fence `0x621`, DCF4 zero, and zero raster batches/workers/pending. There was no Campaign callback, DS list corruption, or surface-overlap record. It was stopped as this task's own PID `178480`. This is not a valid negative test of r340's Campaign crash.

r342/r343/r344 relay logs recorded no dropped lines and drained cleanly. The 64 MiB per-run evidence cap remained enabled. The r341 compile-failure log and candidate directory contain no executable and are not part of the active build.

## Storage and build efficiency

Fresh post-push allocated-versus-logical inventory: `C:\Project\sb-inventory-postpush-20261029.csv` (76,782 ordinary files; 13 reparse entries skipped; zero allocation query failures). Path-summed workspace total is **53,537,125,251 allocated bytes (49.860 GiB)** and **1,385,284,866,002 logical bytes (1,290.147 GiB)**. Logical size is dominated by sparse saves and is not the disk-use figure.

The closed r338–r343 run folders were losslessly NTFS-compressed; 56 file hashes matched before and after a compression/uncompression integrity cycle. Compared with the pre-compression per-file inventory, those folders reclaimed **2,032,049 allocated bytes**. r344's closed evidence is also compressed and recorded in `analysis/r344-evidence-compression-20261029.csv`. No files were deleted or moved. The overall footprint is about 69.9 MiB larger than the r337 inventory because the required r342 EXE/PDB/MAP candidate and additional traces were retained; workspace growth and compression savings are reported separately.

Retained working-set slices: warm `build-xpp-seeded` **6,701,008,794 allocated bytes (6.240 GiB)**; canonical generated AOT source **155,885,489 bytes**; current route save **952,898,778 allocated / 5,422,128,858 logical bytes**. The new r342 EXE/PDB/MAP bundle uses about 69.3 MiB allocated and is retained for the unresolved diagnostic. No hot compiler/Cargo cache was cleared; the successful isolated build took roughly 10 seconds. C: free space is a volume-wide figure and is not attributed to this project.

The exact current cleanup scan, compression audit, and source patches are indexed in `analysis/current-cleanup-manifest-20261029.md` and `analysis/source-preservation-manifest-20261029.md`. No verified duplicate was deleted because the available duplicate screenshot CSV has no removable-path rows; all unique evidence and source copies remain.

## Current conclusion and next discriminating test

The r340 DirectSound crash has a confirmed immediate mechanism: a `put_pixel` store wrote the pixel value into the three live list words. The missing causal field is the renderer's active surface state at that exact store. The bounded source probe now records precisely that state when the store recurs. The r342 route did not recur within its short campaign window and had the trace disabled; r343/r344 did not reach Campaign, so neither rejects the finding.

Before changing runtime behavior, reproduce the visible Campaign route with the surface trace enabled and capture a matching `[DS-SURFACE-PIXEL]` row. Correlate the resolved color target to the guest/host address mapping. Only then select the smallest supported repair. Keep the title DCF4 wait, this DirectSound crash, high raster cost, and post-difficulty loader plateau separate. No loader dependency has been identified in these runs. Continue with AOT, controller mapping, guest fences, and rasterizer `1ea1871`; stop at the first visually verified mission frame.

## Verification summary

- **Completed:** exact r340 corrupting stores and crash linkage; validated older r151 title-wait and r153 dump limitations; opt-in capped surface-state diagnostic; isolated successful build; current allocated/logical inventory; closed-log compression and SHA-256 integrity checks; no interference with other runs.
- **Verified:** r340 reaches Campaign and crashes after the pixel stores; r342 reaches Campaign without a same-window overwrite; r343/r344 do not reach Campaign; only r340 establishes the list overwrite.
- **Unverified:** active target at the offending store; safe runtime fix; first mission frame; loader dependency, mission performance, audio, controller operation in gameplay, and campaign completion.
- **Known issue:** title route can fall to a black frame after the player-record warning; this is separate from the r340 Campaign corruption.
- **Next:** repeat the Campaign route with `RECOMP_DSOUND_SURFACE_TRACE=1`, verify the surface-to-address relation, then implement only a supported fix and check progression past the prior blocker.
