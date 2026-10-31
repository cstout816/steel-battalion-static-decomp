# r461–r465 loader evidence, A/B result, and storage review

**State:** Milestone 3 remains open. No first mission frame has been visually verified. No gameplay or generated-code fix was made. AOT execution, the controller mapping, guest fence handling, and rasterizer baseline `1ea1871` were preserved.

## Starting report, current processes, and run protection

The requested handoff, `analysis\project-review-and-luna-high-handoff-20261027.md`, and the latest completed report available at the start, `analysis\m3-r455-r459-loader-route-and-storage-20261030.md`, were reviewed. Later raw scan notes existed, but no later consolidated report superseded them. The r154 diagnostics identified in the handoff were treated as historical. Before each diagnostic, active game processes and run manifests were checked. The r461–r465 runs used isolated log directories and exact executable/symbol bundles. At completion there was no `your_game_recomp_producer_trace.exe` process. r465's own NV2A progress watchdog stopped PID 20580 after a 240-second unchanged signature; no other game's process was stopped.

## Run identities and evidence

### r461 instrumentation build

The isolated build `local-tools\steel-battalion-game\build-xpp-seeded\ProducerTrace-Candidates\m3-open-target-skip2048-r461-20261030\Release\your_game_recomp_producer_trace.exe` added a bounded `FILE_OPEN_TARGET_SKIP/LIMIT` control so tracing could skip startup opens before recording relevant targets. This changed instrumentation only. Its exact bundle:

- EXE SHA-256: `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`
- PDB SHA-256: `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`
- Matching MAP: alongside the same Release output.

The same EXE/PDB/MAP was used in r463–r465. Do not confuse this diagnostic build with canonical retail-game or release builds.

### r462 separate title-stage failure

r462 remained at a title stage and did not reproduce the DCF4 wait or loader. It is not part of the r465 loader conclusion.

### r463 — file-read trace enabled

Run directory: `iso\local-analysis\logs\m3-loader-file-open-only-r463-20261030`. Screen-gated new-pilot route reached the white post-mode2 stage. The file-read log contains 10,546 records. A synchronous 178,176-byte read from token `0x48000080` at guest caller `0x0018E104` completed with IOS/NT success, while the guest status field was `0x103` and async=1; the bridge implementation synchronously completes the host read, updates the guest I/O status, signals the event, then returns guest `STATUS_PENDING`. This row documents successful I/O completion, not a stuck host file read.

Five repeated fixed-size reads on token `0x48000087` returned `STATUS_END_OF_FILE` (`0xC0000011`) at tick 42849234. Open-target records at that tick identify sequential opens of `D:\media\wep\wepdat.wdt`, `D:\media\lid\sp00.lid`, and `D:\media\wep\weplight.lid`; the same token is reused for multiple assets, and the trace does not preserve an unambiguous per-read file identity. Subsequent successful reads and asset activity follow. Therefore these EOF results are not established as the loader blocker.

Mode-2 asset `0x1E` became ready; guest object `0x019204A0` completed status 1 after 450 polls; the last recorded mode-2 progress pair was `0x000ABA00/0`, with 740 load-state callbacks. The DCF4 signature was signaled, DMA PUT matched GET, and raster batches/workers were zero. Rendering backlog is not supported for this stalled stage.

The r463 main thread was observed in native `VirtualQuery` from `recomp_trace_guest_device_entry`; a different thread was in the trace helper's UCRT `getenv` path. The helper does table probing via `VirtualQuery`, so this run has an instrumentation-overhead confound. It does not establish the owner or existence of an environment lock deadlock.

### r464 — black-stage trace stall

r464 had full file-read tracing but no guest-device-entry trace. It became black/unresponsive. Exact-bundle dump `black-stage-stall.dmp` has a valid native unwind for TID 37036 through `ntdll`, `ucrtbase`, and `bridge_create_file_impl+0x200` (EXE RVA `0x64937A0`), with 224 reads and zero read failures. TID 20252 unwound through UCRT to `bridge_trace_output+0x37` (RVA `0x6496037`). Disassembly places `+0x37` after the `getenv` call and before formatting. This is strong evidence of a trace-path/UCRT environment interaction in that particular instrumentation-heavy run, but no lock owner was identified. r464's DCF4 was signaled and raster queue/workers were zero; do not merge this black-stage confound with the post-loader white plateau.

### r465 — A/B with file-read trace disabled

Run directory: `iso\local-analysis\logs\m3-loader-no-file-read-r465-20261030`. PID 20580 used the same r461 EXE/PDB/MAP and new-pilot route, with `RECOMP_FILE_READ_TRACE` disabled and guest-device-entry tracing unset. File-open/path, loader, readiness, DMA/PB semaphore, NV2A, and XID tracing remained active. It reused the existing empty save root `iso\local-analysis\saves-m3-newpilot-empty-r366-20261029`; no save copy was made.

The route reached the white post-difficulty screen, with `FPS: 0.0`, two draws. Helper object `0x1E` completed status/exit 1 after 42 polls at tick 43751453; last mode-2 progress remained `0x000ABA00/0`; 136 load-state callbacks were recorded. Objects `0x013BA000`, `0x013BB000`, and `0x019204A0` all completed with status 1. Twenty-nine missing-file probes were recorded for empty save slots and cache paths such as `STRM07/08.WAV`, `ATARI.BIN`, `MODEL.BIN`, `MOTION.BIN`, `LSQ.BIN`, `SOUND.BIN`, `TEXOBJ.BIN`, and `TEXMOVIE.BIN`. These are followed by source-media fallback opens and/or cache creation; no one missing path has been shown to be an unrecoverable dependency.

At the stable plateau, DCF4 was signaled; DMA PUT=GET `0x6259C`; DCF4 wait/callback and raster batch/worker/pending counts were zero; frame/counter/target/fence were stable at `0xBEB / 0x1167F / 0x1161B / 0x1167D`. IRQ/timer activity continued. There is no rendering queue backlog in this signature. It is not the earlier title DCF4 wait.

The final dump's actual TID 34344 PC is EXE+`0x611BE2`, resolving in the exact MAP to `sub_0001D980+0xA2`. The native unwinder stops at the synthetic guest boundary; there is no validated guest caller chain. Separate raw stack scans in `analysis\m3-r465-*-raw-stack-scan-20261030.txt` are labeled only as raw candidate addresses and must not be cited as genuine unwinds. An earlier r465 capture placed TID 34344 in `sub_0020EC00+0x71`; a later capture placed it at `recomp_trace_guest_device_entry+0x49`. Guest-device tracing was disabled, but first-call environment gating in that helper still executes. This could be a trace confound and needs a no-helper branch trace.

Generated `recomp_0000.c` places `sub_0001D980` at about line 63242. It calls `sub_0020EC00(0x3FFF, ...)`; when return EAX equals `0x88760828`, it branches back to retry at guest `loc_0001D981`, otherwise it advances state fields at `0x311CCC`, `0x311CD0`, and `0x357498`. The r465 actual PC makes this a current candidate, but the run did not record the call's return value or selected branch, and did not identify the expected valid-entry producer. Historical r441 independently observed repeated invalid lookup and no valid write during that distinct run. Neither proves this same branch caused r465's plateau or that the entry should be seeded. No import was seeded and no fix was made.

## `ObReferenceObjectByHandle` completion semantics

The current `bridge_ObReferenceObjectByHandle` calls `bridge_thread_object_for_handle` regardless of whether its optional guest output pointer is null. The helper uses `WaitForSingleObject(handle, 0)`: while active it returns the guest object and records `STATUS_PENDING`; after completion it copies `GetExitCodeThread` into the guest object's status field. `ObReferenceObjectByHandle` returns success for a resolved guest object, not the thread's completion code. Current readiness traces observed objects completing with status 1 (`0x019204A0` included). This contradicts repeating the old r130 null-output diagnosis as the current loader explanation. It does not prove every kernel/thread semantic is correct, but this object completed in r465.

## Diagnostic retention and storage

Final full scan: 79,188 ordinary files; 39,797,143,008 bytes allocated (37.064 GiB); 1,399,608,365,762 bytes logical (1,303.487 GiB); 13 reparse entries skipped; no allocation query failures. C: free space at scan: 45,684,715,520 bytes. Allocated space is the relevant storage number; sparse partition images account for much of the logical amount.

- `iso`: 19,453,233,869 allocated; `local-tools`: 20,107,686,879; `.git`: 106,040,804; `analysis`: 48,444,969; `tools`: 65,769,788.
- Warm `build-xpp-seeded`: 7,645,523,420 allocated / 15,572,112,736 logical. Retained to preserve fast incremental builds and exact rollback/debug symbols.
- Canonical generated source: 155,892,249 bytes; current game-derived/manual state kept out of Git and protected.
- r465 diagnostic directory: 4,133,273 allocated / 9,692,234 logical. One final screenshot `frame-history\capture-0006.bmp` is lossless; four of six sampled frames retained, two evicted, one sample dropped because the framebuffer changed while sampling; no relay drops. The 64 MiB run cap, 16 MiB failure reserve, and four-image cap remained enforced.
- The 750 MiB allocated `saves-m3-route-file-read-copy-20261023\Partition5.img` is a sparse, unique file among reviewed variants. Its hash differs from `route-file-read-copy2`, `known-save-copy`, and `campaign-perf`; preserve it.
- A fresh SHA-256 scan of 11,604 BMP/PNG/JPEG files found 4,820 duplicate paths across 859 groups (321,641,280 allocated bytes). Restricting to same-folder duplicates under closed logs and protecting filenames found in 1,679 reports/capture metadata files yielded 534 candidate screenshot copies totaling 14,139,101 allocated bytes. Exact path/hash/keeper records are in `analysis\duplicate-log-images-reference-audit-r465-20261030.csv`; full hashes are in `analysis\image-content-hashes-r465-20261030.csv`. The local automatic file-action review rejected the bulk duplicate-image removal as blocked by policy; no files were deleted and no alternate route was attempted. Actual space reclaimed: **0 bytes**.

Current dirty source preservation snapshots:

- Root repo HEAD `41a61e8176491499e85a0d1dd5dbc01e7a258dbb`; patch `analysis\source-preservation-root-r465-20261030.patch`, 109,675 bytes, SHA-256 `375DEA26EEF107C859C9AE0511BF24FC4933189239B730EC0A00071A07F48865`; reverse-apply check passed.
- Nested XboxRecomp HEAD `193e2995ffaec871bb3be43a43bd66aa5fccfeb1`; patch `analysis\source-preservation-xboxrecomp-r465-20261030.patch`, 674,245 bytes, SHA-256 `41B597212464915F0104AA3683838A85E546D532F7A17E6454C4648667A2F678`; reverse-apply check passed.
- 17 untracked source/documentation files (744,554 bytes) remain in place with path and SHA-256 listed in `analysis\source-preservation-untracked-r465-20261030.csv`. No ignored game-derived AOT code, game assets, saves, ISO, or XBE are in these snapshots.

Patches contain source/config/docs and staged source additions, not proprietary generated game code, XBE, ISO, extracted assets, or save images. No commit or push was made.

## Testable next hypothesis

**Hypothesis:** the r465 plateau thread is repeatedly taking the `0x88760828` retry edge in `sub_0001D980`, waiting for a table entry whose producer did not publish a valid value.

**Confirm:** in a matched new-pilot run, a low-overhead trace at the callsite records repeated handle `0x3FFF`, returned `0x88760828`, and the retry branch while the exact table slot remains invalid; a synchronized producer/slot watch shows no valid publication before the same loader plateau.

**Reject:** the result/branch differs, the function advances, the table entry is valid, or another worker/dependency visibly owns the last incomplete handoff.

The trace should be a bounded direct counter/ring buffer with first/last plus periodic samples and a separate drop count. Avoid per-call `getenv`, formatting, `VirtualQuery`, or synchronous file I/O. Validate all indirect targets statically before rebuilding; do not seed imports/handles, bypass checks, force events/fences, enable preload shortcuts, or modify gameplay. Preserve exact EXE/PDB/MAP and failure-window capture. After one supported cause, make only its smallest fix and verify the route advances beyond the previous stage. Stop at the first visually verified mission frame.

## Status links

- Current concise index: `analysis\CURRENT_STATUS.md`
- Current cleanup manifest: `analysis\current-cleanup-manifest-r465-20261030.md`
- Exact r465 run manifest: `iso\local-analysis\logs\m3-loader-no-file-read-r465-20261030\run-manifest.json`
