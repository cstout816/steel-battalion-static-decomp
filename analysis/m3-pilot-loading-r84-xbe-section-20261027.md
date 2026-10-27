# Producer trace r84: pilot-list input and first loading wait

**Run:** `m3-pilot-loading-r84-xbe-section-20261027`
**Run directory:** `iso/local-analysis/logs/m3-pilot-loading-r84-xbe-section-20261027`
**Diagnostic PID:** 124596 (`your_game_recomp_producer_trace.exe`), started 2026-10-27 07:46:05 local; stopped by the operator request after the last capture, not by watchdog. No other process was terminated.
**Executable:** `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r83-xbe-section-trace-20261027/Release/your_game_recomp_producer_trace.exe`
**SHA-256:** `14F962A5BC54AE7A21E671DA53FD4DC60680030AC731A451513F39A0E6FD24CB`
**AOT generated source:** `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
**Save root:** `iso/local-analysis/saves-m3-known-save-copy-20261023`
**Framebuffer stage at stop:** `NOW LOADING`; no first mission frame.
**Relay:** finalized cleanly; 0 stdout/stderr drops, no relay error. The manual stop returned process exit code -1. The retained final frame is `frame.bmp`.

## Verified pilot-list and input path

The run emitted 406 `[PILOT-LIST-CB]` rows and one `[PILOT-ROW-POST]`. The active per-frame pilot-list update is guest `0x000E18D8` in the current generated `recomp_0004.c` (around generated-source line 125739); it is reached through the menu object `0x006B9E1C`. Resource record at tick 353748328 maps row `0x002E4C34` to XBE string VA `0x0026AF04` (`LIST AS NEW`). This identifies the callback while the visible list owns that row; it does not turn the earlier `sub_000E0870` candidate into the handler.

A screen-gated press at tick 353820468 produced XID report byte 2 = `01` at callback buffer `0x01081763` (bus `0x81081763`). At tick 353820562, guest edge handling records `source=0x004B0160:0000`, copied cell `0x004AFC08:0001`, `xid2=01`, transition 6; the predicate returned 1 both at parent `0x000E07EC` and `0x000E18D8`. The pilot-list callback then returned its input branch at `0x000E193B` with owner 8 and selected row 0. Its continuation reached `0x000E19CF`, action `0x83`, row item `0x002E4C34` (`LIST AS NEW`), and changed item field `+0x28` from `0x3F800000` in the pre-action callback record to `0` in the post-action record. The matching XID release was delivered at tick 353821281. This is direct evidence of a screen-gated edge and selected pilot-list branch/state update. The separate `[SB-SNAPSHOT]` marker emitted zero rows, so the snapshot-copy stage is corroborated by the edge record's before/copy cells rather than a dedicated snapshot trace.

## Loading-stage evidence

At tick 354178687, `[LOAD-RENDER]` confirms the loading renderer ran. The final captured frame remains `NOW LOADING`. `LOAD-PASS` completed 103 recorded mode-2 scans, each returning 0; the last pair stayed `0x011E2E00/0`, and loader state callbacks showed mode/phase unchanged with gates `1/1/0`. They are observed poll/scan behavior, not proof that this is the loader's owning work item.

The active main-thread guest stack sample (`tid=124592`) includes return `0x000C320A`, then values including `0x002603AC`, `0x0025E2D4`, `0x002601AC`, and text `Z:\TEX00.BIN`; these are plausible loader/cached-file scan frames, not a validated complete call chain. Thread starts were logged for main `0x00192BD8`, workers `0x001ABA10`, `0x0010D100`, and preload worker `0x00017E40` (`mode=0`). Native thread stacks were not captured.

File lifecycle tracing recorded opens/closes, and `[FILE-IO]` records cover 2,799 writes, 1,877 set-info calls, and 285 queries. There are no file-read completion/IOSB records in this run despite read-trace environment flags being enabled. The 25 open misses include `user00.sav`, `user99.sav`, `config.sav`, and other save-slot files. The selected path was the explicitly authorized new-pilot route and the retained UserData is empty, so these misses are expected slot discovery at present; they do not establish a missing mission asset. The `XeLoadSection` observation at tick 354178750 loaded section `seg00` (`0x0001134C`, VA `0x009FB0A0`, size `0x9AC8`) with success and refcount `0->1`; it is not a supported failure cause.

Rendering and synchronization telemetry continued while the screen remained at loading. NV2A frame/counter/semaphore values advanced; DCF4 was often clear at sampled ticks, and each logged marker reached `written` and returned from PFB flush. Raster windows repeatedly measured 27 batches / 56 triangles, around 2.1–2.25 seconds batch wall time and 8.3–8.9 seconds summed worker-active time. These measurements support a severe raster workload and explain poor rendering throughput, but they do not show an increasing queued-batch count or identify a blocked loader dependency. This run does not reproduce the historical unsignaled DCF4 wait.

## Conclusion and limits

- **Verified:** AOT diagnostic build identity and generated-source directory; effective trace settings are retained in `environment.txt`; pilot-list callback `0x000E18D8`; one XID press/release through guest edge/predicate handling and the `LIST AS NEW` action/state mutation; `NOW LOADING` screen; successful `seg00` section load; continued graphics/DMA/semaphore activity; exact diagnostic PID stopped; clean relay with zero drops.
- **Not established:** first stalled loader dependency, whether a specific asset read remains outstanding, native thread wait/call stacks, first mission frame, audio correctness, or campaign progression.
- **Trace coverage limits:** snapshot marker count 0; no file-read completion records; only the main guest stack sampler emitted and it is a candidate frame scan; no native stacks; no supported causal tie from the high raster worker-active total to a growing queue or the loader stop. The manifest does not record the source XBE hash.
- **Decision:** no gameplay, AOT, input, guest-fence, DCF4, or rasterizer behavior change is supported by this evidence. Preserve rasterizer baseline `1ea1871`; do not patch. If diagnosis resumes, first add bounded completion/IOSB correlation and per-thread native plus validated guest-stack sampling to an isolated executable, then repeat the same new-pilot route with the external process watchdog enabled. Stop at the first mission frame.

## Automatic diagnostic stopping

`tools/Start-ProducerTrace.ps1` now has a 1,800-second watchdog that terminates only the diagnostic process it launched, then drains/finalizes logs. r84 ended earlier by explicit operator request; the watchdog did not trigger. Future producer-trace runs should keep this default and retain the per-run identity/manifest.
