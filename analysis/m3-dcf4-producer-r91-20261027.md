# r91 new-pilot loading and DCF4 producer trace — 2026-10-27

## Result

The AOT build followed the screen-gated new-pilot route and reached the visible `NOW LOADING` screen. It remained there until its 900-second watchdog ended diagnostic PID `110276` at 09:51:53 CDT (process exit code 3; the external watchdog did not fire). No first mission frame was captured. No game, controller, guest-fence, or renderer behavior was changed.

This run separates the repeated loader scan from the historical Campaign-stage DCF4 wait: the loader scan repeatedly returned without changing its tracked pair, while DCF4 producer writes, flush returns, frame/counter/target values, callbacks, and NV2A ticks continued. Raster work was very expensive. This capture does **not** identify a named loader dependency or prove that raster cost is the cause of the loading stop.

## Run identity and trace audit

- Run: `m3-dcf4-producer-r91-20261027`, diagnostic PID `110276`, started 09:36:53 CDT.
- Diagnostic executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-all-waits-r89-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `D9647479FF7ACB95CC5113818A3AE8E73B77C78543D3261A3EA3CD493E528A81`.
- Matching PDB: SHA-256 `308D64C820CCE4D3055F920621B3A50D76F38283DCF91937479E1F639576F69D`.
- Generated-source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- The asynchronous relay drained and stopped with zero dropped stdout/stderr lines; `run-manifest.json` reports complete marker counts. The runtime watchdog recorded `no exit after 900s`; process exit code was 3. This was the diagnostic child only.
- Generic `RECOMP_TRACE_ENTER`, `RECOMP_TRACE_EXIT`, and `RECOMP_TRACE_ESP` are no-op macros in generated `recomp_types.h` (lines 396, 398, and 400). `RECOMP_TRACE_BUDGET=0` therefore did not enable generic function tracing. Feature-specific traces emitted records as shown below.
- Enabled: XID reports, edge/predicate, pilot-list row, load helper/pass, read, raster performance, DCF4 callback and producer markers, and bounded wait traces. `RECOMP_WAIT_TRACE_ALL_LIMIT=4096`; both DCE4 and DCF4 wait-entry logs reached 4,096, so later entries are not complete. `[SB-DMA-PUBLISH]` reached call n=100,000 (three records per call); later publish detail is absent. The DCF4 producer marker cap is 100,000 and was not reached.
- File lifecycle/open-path, file-I/O detail, file-copy, thread-start, and preload-worker traces were **disabled or unset**. `[SB-SNAPSHOT]`, `[SB-INPUT-DISPATCH]`, and `[MENU-DISPATCH]` each emitted zero records. Their absence is a coverage limitation, not evidence that those stages did not execute.

## Visible pilot-list input correlation

The periodic frame `frame.bmp00002.bmp` visibly shows the selected `LIST AS NEW` row. The following input and row state records are on the same guest tick:

1. At tick `360447468`, XID report byte 2 is `01`; `[XID-DMA0]` records the report delivered to buffer `0x01081763` / bus `0x81081763`.
2. At tick `360447531`, `[SB-EDGE-CONSUME]` records the guest input cell changing from `0x004B0160:0000` to `0x004AFC08:0001` (transition 6), with XID byte 2 still `01`.
3. At the same tick, the active pilot row updater at `0x000E18D8` takes branch `0x000E193B` for object `0x006B9E1C`, owner 8, selected row 0, table `0x002E5A88`, item `0x002E4C34`.
4. The XBE word at `0x002E4C34` points to `LIST AS NEW` text at `0x0026AF04`. `[PILOT-ROW-POST]` at `0x000E19CF` records action `0x83` and the item `+0x28` value changing from `0x3F800000` to `0`.
5. The next periodic image, `frame.bmp00003.bmp`, visibly shows the name-entry screen.

This ties the visible row to `sub_000E1820`/site `0x000E18D8` and its accepted branch for this run. `sub_000E0870` remains only a candidate for other dispatch paths; the runtime menu gate records `skip-subE0870`. The separate snapshot and menu-dispatch trace stages did not emit, so this is an XID/DMA-to-edge-to-row/state correlation, not proof of every internal snapshot step or an atomic framebuffer timestamp.

## NOW LOADING and loader state

The framebuffer shows `NOW LOADING` by 09:45:55 CDT and still shows it at the final saved frame at 09:51:26. The 222 mode-2 scans on TID `125956` entered `sub_000C3020` at `0x00102063`; the final input sample is pass n=222 at tick `361247562`. The observed returns use `0x000C32D6`, scan range `2..11`, last index 28, and result 0. Once initialized, the tracked pair remains `0x011E2E00/0`; source shows this is a resource/cache-pair scan return path, not a verified progress counter or direct load failure.

`[READ]` last records successful bytes at tick `360836765` (n=5616, token `0x48000069`, 18,432 bytes). The read trace has no resource path, and this run disabled file lifecycle and file-I/O detail, so it cannot correlate the handle to a cache/source filename, open failure, write completion, or outstanding request. The first stalled dependency is therefore **unidentified in r91**.

The older r69 run in [the investigation handoff](astra-pilot-loading-handoff.md) recorded a repeated missing cache open for `Z:\TEX00.BIN` with `STATUS_OBJECT_NAME_NOT_FOUND`, adjacent to unchanged mode-2 scans. That is a historical candidate only; r91 did not enable the path-correlated trace needed to confirm it. A later r78 controlled TEX00 cache copy did not advance loading, so TEX00 alone is not established as the current or sufficient cause.

Three thread-info minidumps were captured at 09:46:26, 09:47:07, and 09:51:33. The offline unwinder repeatedly reached only a few Windows frames plus an executable address before hitting an invalid/non-module stack value. It did not produce a validated guest loader call chain or identify a file request owner. These dumps cannot be used as proof of a blocked file operation.

## Graphics and synchronization evidence

- DCF4 producer trace emitted 7,635 marker writes, paired `pfb-flush-return` rows, and threshold records; DCF4 callbacks numbered 15,795. Callback records include arguments such as `0x03600021` and `0x00000005` and selected indices/targets. The final NV2A sample reports frame `0x1FCB`, counter `0x3DE03`, target `0x3DDFB`, semaphore `0x3DDF5`, and DCF4 `0`; callback/frame counters continued to advance. Since wait entries capped at 4,096, this excludes neither every transient wait nor every later wait, but the historical fixed DCF4 wait did not reproduce as a persistent stop during this loading run.
- Raster telemetry emitted 434 windows. A representative late window recorded 27 batches / 56 triangles, about 2,099 ms batch-wall time and 8,042 ms summed worker-active time across four workers. This confirms severe CPU raster cost. The trace did not provide reliable queued/in-flight batch IDs or sustained queue depth; no accumulating raster backlog or causal gate is established.
- DMA publish detail reached its 100,000-call cap before loading. Later marker samples and selected NV2A ticks show activity, but the capped producer log cannot provide continuous PUT/GET coverage for the entire loading interval.

## Next evidence needed

Keep the current AOT path and guest fences. The next isolated diagnostic should enable path-correlated file lifecycle and I/O completion/status traces plus worker-start/route tracing, with a bounded output cap and the existing 900-second watchdog. Correlate the first missing cache open or unfinished operation with loader pass/worker state and two timed thread snapshots. Do not seed a target or change cache, loading, synchronization, or raster behavior until one dependency is supported by those traces. Stop after the first verified mission frame.

Storage note: six byte-identical numbered framebuffer copies (`00019`, `00021`, `00023`, `00025`, `00027`, `00028`) were moved, not deleted, to `iso/local-analysis/obsolete-for-user-review/m3-dcf4-producer-r91-duplicate-frames/`. One copy of each hash remains with the run; the destination manifest lists the moved names and hashes.
