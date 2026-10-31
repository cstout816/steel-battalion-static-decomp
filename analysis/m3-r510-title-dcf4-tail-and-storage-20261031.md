# r510 diagnostic report — 2026-10-31

## Result

Milestone 3 remains active. The first visually verified mission frame is **0/1**. r510 reproduced the early title/player-record screen failure and its DCF4 wait; it did **not** reach Campaign, pilot selection, `NOW LOADING`, or the first mission. This run does not test the post-difficulty loader plateau from r508 and does not establish a cause for it.

AOT execution, controller mapping, guest fences, and rasterizer commit `1ea1871` were preserved. No guest/runtime behavior fix was made.

## Run identity and bounds

Run: `m3-dcf4-loader-tail-r510-20261031`, diagnostic PID 55628, stopped by its own 120-second DCF4 wait watchdog. The PID was verified as this run before it was stopped. No other game process was found or interrupted. The run reused the existing save directory in place; no save copy or hard link was created.

- EXE SHA-256: `3D50685C0D2DE93432088CB2F9B59196565F7CDF91E265F8BCD0A14FBB1DF778`
- PDB SHA-256: `2FEDDB85965E8A03060F19D880BD22B91EF96A92817C5B13AEDBAC32E72BF013`
- MAP SHA-256: `413358C4100865F2882F07CF94CF6363466DB7720FDB58CE70C9FDB832E62EFF`
- Modified generated source: `recomp_0015.c`, SHA-256 `D754590FB3CBF01482826FBDA1898B237AE00A4FDBF30C7BC6D919CEE921F797`; its only intended difference was a diagnostic DCF4 outer-record cap increase from 4,096 to 32,768.
- Run budget: 64 MiB; used 7,861,147 logical bytes. Trace-limit hits: 0. Relay/stdout/stderr drops: 0. Frame history: 3 captures, cap 4, no evictions or drops. The manifest's allocated-byte and compression fields were left `-1`; use the separate filesystem inventory for actual allocation.

Bundle paths are in `iso/local-analysis/logs/m3-dcf4-loader-tail-r510-20261031/run-manifest.json`.

## Screen-gated input and wait

The first A pulse reached XID at tick `101776109`. Guest edge handling at tick `101776187` used table `0x48DF8`, index 6, target `0x48CBB`, and changed guest cell `0x004AFC08` from `0000` to `0001`. The title route advanced to the player-record error overlay. The second A reached XID at tick `101811437` and was released at `101811937`, but no corresponding guest edge/route change was recorded; the main thread was already waiting.

At tick `101779843`, TID 52456 entered a wait on guest object `0x0021DCF4`, signal 0, type 0, reason 6, mode 1, caller hint `0x00211F3B`. There is no return record. The nearby callbacks were:

- Callback 944: arg `0x01080021`, selected index 5 → target `0x0021701E`; its validated bridge path called `KeSetEvent` at return site `0x0021702F`.
- Callback 945: arg `0x01080021`, selected index 1 → target `0x00216EC9`; gate output 0.
- Callback 946: arg `0x03600021`, selected index 1 → target `0x00216EC9`; gate `out100=0`.

After callback 946, no later index-5 producer/set was recorded. The expanded outer trace retained 473 rows with no cap hit. `sub_002173A0` continued to report `flags=01000000`, `called=4`, `r16be0=0`, aggregate 0, `loop=0`; this is observed state, not a proven cause.

The final screenshot (`frame-history/capture-0003.bmp`, SHA-256 `921121282F255E0DE3BA403AF608AE59291E3C6EFC45747AA62EBCDF613B4950`) visibly reads “Unable to load Player Record. Press MAIN WEAPON BUTTON to continue”. No loader callback/pass/preload/mode-2 event occurred. Title startup file activity (321 opens, 283 closes, 3,577 file-I/O rows, 224 read rows, 6 misses) cannot establish a mission dependency because the loader was never entered.

## Rendering and stacks

At wait entry there was one batch and three pending workers. Later synchronized NV2A telemetry had zero batches, workers, and pending work while timer telemetry continued; the terminal sample was tick `101903531`, frame `0x2AC`, counter `0xB8B`, target `0xB81`, fence `0xB87`, with PMC/PCRTC active. This rejects a continuing raster queue backlog at the terminal wait sample. Earlier title raster work was expensive (2,411 batches / 4,822 triangles in about two seconds; four workers and a maximum measured batch of about 43.91 ms), a distinct performance issue.

Using the exact r510 dump and executable symbols, TID 52456 has a valid *partial native* unwind through `xbox_KeWaitForSingleObject+0x29`, then stops at guest-looking address `0xEA4`. No guest caller chain is inferred. TID 54136 reaches `kernel_timer_thread+0xE2`. Raster worker threads are present but their existence does not explain the DCF4 wait.

The attempted fresh r150/r151/r153 rewalk is inconclusive: the host unwind stopped immediately because local Windows module metadata did not match those older dumps. Its output is not evidence of new unwinds. The archived `analysis/dump-unwind-review-r150-r151-r153-20261028.txt` remains the prior review; no new old-dump conclusion is claimed here. Exact historical EXE/PDB/MAP identities remain in their reports.

## Storage and build impact

The full post-run scan reports **40,101,794,669 allocated bytes (37.354 GiB)** versus **1,402,801,346,883 logical bytes (1.276 TiB)** across 80,049 regular files. Allocation was measured separately from logical length; sparse save images explain much of the gap. The save root, ISO, extracted assets, canonical generated tree, and warm build cache remain.

A validated 312-file exact-duplicate removal set totals 2,379,096,064 allocated bytes, but automatic action review rejected that removal. **Nothing was deleted; actual reclaimed space from removal is 0 bytes.** Lossless NTFS compression of 40 already duplicated TEXOBJ caches preserved every hash and changed their measured allocated total by **0 bytes**. Do not attempt a different deletion route. No hot compiler/Cargo cache was cleared.

The side-by-side incremental build completed successfully in about 14 seconds; it recompiled only generated `recomp_0015.c` and relinked. This trace-only change preserved the working cache. The older measured warm build was 8.2 seconds; there was no apples-to-apples timing comparison.

Detailed storage artifacts: `analysis/current-cleanup-manifest-r510-20261031.md`, `analysis/current-cleanup-validation-r510-20261031.csv`, and `analysis/r510-texobj-cache-compression-20261031.csv`. Whole-workspace inventories are outside the repository under `C:\Project`.

## Current disposition and next test

The earliest r510 blocker is a title-stage wait at guest DCF4 object `0x0021DCF4`, where a later producer/set did not appear after callback 946. Why callback production stopped, whether that is causal to the screen failure, and the actual guest caller state remain unknown. This is separate from r508's post-difficulty dispatch-gate wait, the historical DirectSound list corruption, and title raster cost.

Next test: first use exact matched r153/r151/r150 dumps and symbol bundles with a dump-compatible unwind environment, then reproduce the known new-pilot route with a failure-window tail and a real guest CPU snapshot at the first stopped wait. Keep loader file completion and dispatch-gate owner telemetry enabled only on a route that reaches `NOW LOADING`. Do not alter wait/signal behavior, guest checks, fences, preload policy, controller mapping, AOT execution, or rasterizer until one cause is supported. Stop acceptance at the first visually verified first-mission frame.
