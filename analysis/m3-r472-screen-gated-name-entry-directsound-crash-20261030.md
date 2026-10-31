# r472 screen-gated pilot route and DirectSound crash — 2026-10-30

## Outcome

r472 establishes that the existing screen-gated title route works through the visible `LIST AS NEW` pilot row and into name entry on the current r461 AOT binary. It does **not** reach difficulty selection, visible `NOW LOADING`, or a mission frame. The run then reproduces the separate DirectSound deferred-list corruption crash. No loader conclusion or gameplay fix follows from this run.

## Run identity and retained inputs

- Run: `m3-title-screen-gated-route-r472-20261030`; PID 28876, stopped by its fatal-exception watchdog only after verifying the executable path. No other game process was running at the post-run process check.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-open-target-skip2048-r461-20261030/Release/your_game_recomp_producer_trace.exe`
- EXE SHA-256: `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`
- PDB SHA-256: `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`
- MAP SHA-256: `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0016.c` SHA-256 `C90C02FB56E17DC84AB97B10633BE0ED18BA63AE17C49B40B3C9CE92447777D8`.
- Save root: `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029` (same existing root; no copy or hard link).
- Full environment, flags, file hashes, and stop state: `iso/local-analysis/logs/m3-title-screen-gated-route-r472-20261030/run-manifest.json`. Producer tracing remained AOT; no guest code, import, fence, controller map, or rasterizer was altered.

## Screen-gated input and callback correlation

Inputs were appended one at a time to `pad-live.txt`, with each transition checked in the visible framebuffer:

1. `a:5000`: title prompt → `Unable to load Player Record` prompt.
2. `a:5000`: prompt → Campaign menu.
3. `ldown:500`: Campaign → Mission Log; `lup:500` returned to Campaign.
4. `a:5000`: opened the pilot menu; `LIST AS NEW` was visibly highlighted.
5. `a:5000`: opened the pilot name-entry screen.
6. `a:5000`: one character-selection pulse; the capture still showed name entry.

The input trace captured XID DMA byte 2 at guest buffer `0x01081763`; edge consumption at `0x000C8064` changed guest cell `0x004AFC08` from 0 to 1. At tick `49107328`, parent `0x000E07EC` consumed the predicate, and the pilot row updater at `0x000E18D8` selected branch `0x000E193B`. The selected item `0x002E4C34` resolved through menu resource slot to `LIST AS NEW` string VA `0x0026AF04`; row action `0x83` executed at `0x000E19CF`. This reproduces the previously established active generic row updater and confirms the visible pilot-list action in this exact run. It does not support treating `sub_000E0870` as the registered list callback.

## Crash evidence and limits

At tick `49110921`, the DS commit watch recorded an invalid node: argument `0x010810A4`, node `0`, predecessor `0x8038C098` with next/previous/owner all zero, while the list head still had nonzero links. The fatal AOT fault followed in `sub_0021ED29+0x88`, guest VA `0xFFFFFFF4` (read), native RIP `0x7FF62DAF5448`. The run's exact-bundle minidump was checked with `Walk-ProducerTraceMiniDump.ps1`: native TID 32040 unwinds through Windows exception machinery into EXE RVA `0x61A5448` (the generated faulting function), then stops at the synthetic guest address `0x21ED29`. The remaining guest stack addresses in the runtime exception record are guest-frame candidates, not an independently validated unwind. This validates the native location and guest fault site; it does not identify the earlier write/lifetime event that corrupted the list.

The failure occurred about 3.6 seconds after the name-entry input, while DCF4 callbacks and raster windows were still progressing. It is therefore recorded as the known DirectSound list-corruption family, not a DCF4 wait or loading plateau. `LOAD-STATE-CB=0`; there was no file-completion plateau or `NOW LOADING` screen. Do not change DirectSound list semantics based solely on this observation; locate the corrupting writer first.

## Trace/storage accounting

- Trace counts: 333 pilot-list callback rows, one pilot-row post-action, 14 guest edge-consume rows, 19 input-predicate rows, 3 menu-resource rows, 2 file-preload enter/return pairs, 21 file-copy enter/return rows, 235 file-open target begin/done rows, 3,061 DCF4 callback rows, 3,059 DCF4 gate rows, 5,136 raster-sync rows, and 50 raster-performance samples. No load-state callback, preload worker schedule, or file-I/O completion record was emitted. No listed per-probe cap/drop counter was hit; framebuffer history retained three lossless BMPs under a cap of four, with one sampling drop due to a frame changing during capture.
- r472 directory: 16 files, 9,829,996 logical bytes, 3,606,351 allocated bytes (3.44 MiB). This includes the fatal dump, exact run manifest, logs, input record, and three stage captures. Kept because the route and crash are unresolved evidence.
- Fresh read-only whole-workspace scan after r472: 79,375 files, 39,810,510,383 allocated bytes (37.076 GiB), 1,399,640,834,790 logical bytes (1,303.517 GiB), zero allocation query failures; reparse points skipped per the scanner policy. Allocated bytes remain separate from sparse logical lengths.
- No project files were deleted or moved. Actual storage reclaimed: **0 bytes**. The preceding cleanup manifest's rejection of closed-log replacement and 534 screenshot candidates remains in force; this report does not retry those actions. Warm incremental build caches were untouched.

## Next step

Do not launch another route run before reviewing the existing r153/r151/r150 exact-bundle evidence and the deeper r158/r463/r465 loader records already in the project. Keep the known DirectSound corruption separate. The loader's earliest supported path remains the r463/r465 false readiness / invalid `0x3FFF` candidate, not a proven missing file or completed `ObReferenceObjectByHandle` defect. A further experiment needs to distinguish that candidate with validated stacks, exact call/branch records, and bounded file-completion plus producer/consumer evidence. First mission frame remains 0/1.
