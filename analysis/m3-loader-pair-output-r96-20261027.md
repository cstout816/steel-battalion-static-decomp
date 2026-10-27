# r96 mode-2 loader output-pair trace — 2026-10-27

## Result

The screen-gated new-pilot route reached the visible `NOW LOADING` screen, but no first-mission frame appeared. The automatic plateau guard stopped only diagnostic PID `128652` at 11:47:20 CDT after 300 seconds with the same mode-2 loader signature and framebuffer hash. No behavior fix, cache seed, target seed, controller mapping change, guest-fence change, or rasterizer change was made.

The new callsite trace shows the index-`0x1E` helper returning raw `0xFFFF0001` while its output pair is `0x011E2E00/0`. On the first call, the global pair was `0/0`; the caller then copied the returned pair into the global pair. Subsequent calls returned the same pair and left that global state unchanged. This confirms the repeated `Z:\TEX00.BIN` cache miss is correlated with a nonzero output pair; it does not establish that the miss blocks mission entry or identify the intended producer.

## Run identity and observed route

- Run: `m3-loader-pair-output-r96-20261027`; PID `128652`.
- Started at 11:31:15 CDT; plateau stop at 11:47:20 CDT. `run-manifest.json` records process exit `-1`, plateau watchdog true, external watchdog false, and 300 seconds.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-pair-output-r96-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `4B197507F967F945F77DFFCCAF8280388275A68C44D75AA6C93BCFE7440AA6B1`.
- Generated sources: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Existing save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save or cache edits were made.
- The screen-gated route traversed title, Campaign, `LIST AS NEW`, name entry, birth date `01/01/2002`, `OK? YES`, and `HAI SHI DAO 2080 [NORMAL]`. The entered pilot name was `A.`. The capture `frame.bmp` at 11:47:18 shows `NOW LOADING`; its SHA-256 is `1213608B7E68E282C2415F13947777CCE3104467B580EFB0550679860080BC4F`. No saved capture shows a mission frame.
- The exact-process guard record is `plateau-stop.txt`; its signature is `mode=0002|range=2..11|index=28|branch=scan|result=0|pair=011E2E00/00000000|frame=0B9BDD4ACC7C2541572CD8316E3325076B7FF459D8AE15F02BD74DE5B969CE2D`.

## Screen-gated input and active list callback

The r96 trace records a positive guest edge at tick `367388906`, TID `128468`: `XID byte2=01` was copied from `0x004B0160` to guest edge cell `0x004AFC08`, and predicate `(1,6,9)` returned 1 under parent `0x000E18D8`. The same tick, the visible list row callback at site `0x000E18D8` took branch `0x000E193B`, with `key=1`, `xid2=01`, selected row 0, and resource label VA `0x0026AF04` (`LIST AS NEW`). This ties the screen-gated action to the actual pilot-list callback; it does not make `sub_000E0870` the active row callback.

The following name-entry action at tick `367429062` similarly produced XID report byte 2=`01`, DMA delivery to `0x01081763` / bus `0x81081763`, and guest edge cell `0x004AFC08:0001`. A positive predicate under `0x000E07EC` and the row updater was recorded. The route then advanced through name and date screens. No unobserved indirect target was seeded or rebuilt.

## Loader helper and output pair

At source label `loc_000C327C`, generated source computes the helper index as `SMEM16(0x3B90E0) + 0x1E`; the dynamic selector was 0 in the trace, and the observed index was `0x1E`. The trace is at return site `0x000C32A1` after helper `sub_000C2EB0`:

- First relevant call: tick `367853125`, TID `128468`, helper return `0x000C32A1`, `EAX=0xFFFF0001`, index `0x1E`, selector 0, output pair `0x011E2E00/0`, global pair `0/0`.
- The caller then wrote that pair into global `0x0066A508/0x0066A50C` before continuing through `0x000C32D6`.
- Next call: tick `367853406`, same thread and same index; `EAX=0xFFFF0001`, output and global pair both `0x011E2E00/0`.
- There were 173 `[LOAD-PAIR-OUTPUT]` records through the final pass at tick `368174718`. Each index-`0x1E` call returned raw `0xFFFF0001` and the same output pair. The local counter remained far below the source cap of 8,192.
- At tick `367852593`, the source-side `D:\media\BIN\TEX00.BIN` opened successfully for metadata. At tick `367853125`, the corresponding cache-side `Z:\TEX00.BIN` open returned `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`); helper stage was `0x000C300D`, `open1=0xFFFFFFFF`, and `open2/open3=0`.
- All 173 mode-2 pass returns continued through `0x000C32D6` with range `2..11`, last index 28, result 0, and pair `0x011E2E00/0`. The loader state callbacks retained mode/phase `0/0`, gates `1/1/0`, and status `0/0`.

This trace rules out the narrower claim that this cache miss leaves the output pair empty or zeros the tracked global pair. It does not prove the pair is valid for mission loading, that TEX00 is the only blocked dependency, or that populating the cache is sufficient. The earlier controlled cache-copy run did not advance the game, so do not seed this asset based on the miss alone.

## Completion, rendering, and trace limitations

- 5,829 `[READ]` records were emitted; the last observed content read completed 18,432 bytes with success at tick `367856781`. Later loader activity continued as metadata opens/queries. This does not prove every possible async request had completed.
- Raster samples remained expensive. The final window at tick `368175906` recorded 27 batches / 56 triangles, 2,051.32 ms batch wall time, and 7,977.41 ms aggregate active time across four raster workers. No queue-depth or state-transition evidence ties this cost causally to the loading state.
- DCF4 callback/NV2A activity continued through the final trace. The wait log reached its separate 4,096 DCF4-entry cap; DCE4 wait logging also reached its 8,192-entry source cap. The configurable other-wait limit was 16,384 and emitted 15,391 such rows. Thus later wait behavior is not exhaustively excluded. No separate terminal DCF4 wait was used to justify producer-stage instrumentation, which remained disabled.
- `trace-counts.txt` records 173 loader pass in/out rows, 692 loader-state callbacks, 3,114 helper branch/return records, 21,597 DCF4 callbacks, 462 raster windows, and 41 XID reports / DMA deliveries. The pilot-list trace reached its 512-row cap. The marker-count sidecar is complete; the relay dropped zero stdout/stderr lines and shut down cleanly.
- The trace-only `[LOAD-PAIR-OUTPUT]` source marker has an 8,192-row cap. `RECOMP_LOAD_PAIR_OUTPUT_TRACE=1` is recorded in `environment.txt`. No DCF4 producer-stage marker was enabled.
- The final framebuffer remains `NOW LOADING`; mission rendering, gameplay, audio, full campaign, and 60-FPS mission performance remain unverified.

## Next step

Continue tracing the producer and consumer for resource index `0x1E`: correlate the resource-table ID, source read, cache destination write/copy completion, and any state update that follows. Keep the cache miss, raster cost, and DCF4 synchronization as separate candidates. Preserve AOT execution, controller mapping, guest fences, and rasterizer baseline `1ea1871`. Stop automatically after a verified five-minute plateau or immediately after a captured first mission frame. Do not seed or patch without evidence for a causal state transition.
