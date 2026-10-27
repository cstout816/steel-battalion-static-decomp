# r92 new-pilot loader file lifecycle — 2026-10-27

## Result

The ahead-of-time translated executable followed the authorized new-pilot route and reached the visible `NOW LOADING` screen. It stayed there through the final capture at 10:11:09 CDT. The exact-child 900-second watchdog ended diagnostic PID `116744` at 10:11:37 CDT (exit code 3; external watchdog false). No first mission frame was verified. Nothing in the game, controller mapping, guest fences, or rasterizer was changed.

The run freshly correlates the first repeated mode-2 loader miss with the cache path `Z:\TEX00.BIN`: the cache open returns `STATUS_OBJECT_NAME_NOT_FOUND`, the loader scan then returns 0 through `0x000C32D6` with its tracked pair unchanged, and the same miss recurs. The local source asset `D:\media\BIN\TEX00.BIN` was opened only for a metadata query and closed; no content read or copy for that asset is recorded. The evidence supports a missing cache dependency on this route. It does **not** establish why the cache entry was not produced, that TEX00 alone is sufficient to block mission entry, or that it is the only missing resource. The earlier r78 controlled cache copy did not advance loading, so this report does not recommend seeding TEX00 as a fix.

## Run identity and diagnostic configuration

- Run: `m3-loader-file-lifecycle-r92-20261027`, PID `116744`, started 09:56:37 CDT and ended at the 900-second runtime watchdog. It used the existing new-pilot save root `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save copy or ISO modification was made.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-all-waits-r89-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `D9647479FF7ACB95CC5113818A3AE8E73B77C78543D3261A3EA3CD493E528A81`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0004.c` contains `sub_000C2EB0` at line 48727 and the mode-2 scan at calls near lines 49108–49381.
- Generic `RECOMP_TRACE_ENTER`, `RECOMP_TRACE_EXIT`, and `RECOMP_TRACE_ESP` expand to no-ops in `gen/recomp_types.h` at lines 396, 398, and 400. `RECOMP_TRACE_BUDGET=0` did not turn on generic function tracing. Feature-specific traces did emit records, with complete marker counts in the run manifest.
- Effective path/lifecycle configuration: `RECOMP_FILE_LIFECYCLE_TRACE=1`, `RECOMP_FILE_FAIL_PATH_TRACE=1`, `RECOMP_FILE_CALLER_TRACE=1`, `RECOMP_FILE_IO_DETAIL_TRACE=1`, `RECOMP_FILE_COPY_TRACE=1`, `RECOMP_THREAD_START_TRACE=1`, `RECOMP_PRELOAD_WORKER_TRACE=1`; all-wait trace cap 4,096; runtime watchdog 900 seconds. DCF4 callback trace was enabled (`RECOMP_DCF4_CALLBACK_TRACE=1`); DCF4 producer-stage trace and high-volume DMA/PB-semaphore traces were unset. Raster performance ran with four workers.
- The bounded asynchronous relay ended with zero dropped stdout/stderr lines, a stopped writer, and complete marker counts. Manifest: `iso/local-analysis/logs/m3-loader-file-lifecycle-r92-20261027/run-manifest.json`.

## Visible route and one input-to-state correlation

The route was screen-gated through `LIST AS NEW`, name entry, the default birth date, `OK? YES`, mission selection `HAI SHI DAO 2080 [NORMAL]`, and `NOW LOADING`. For the `LIST AS NEW` A press at tick `361637156`:

1. XID/DMA report byte 2 was `01` in buffer `0x01081763` at tick `361637078`.
2. At tick `361637156`, the guest edge record changed cell `0x004AFC08` from 0 to 1 (`xid2=01`); the associated predicate at parent `0x000E18D8` returned 1.
3. The visible pilot-list updater at `0x000E18D8` selected branch `0x000E193B`, object `0x006B9E1C`, owner 8, row 0, item `0x002E4C34`. The adjacent `MENU-RESOURCE` record resolves that item to label VA `0x0026AF04`.
4. The post-row callback at `0x000E19CF` recorded action `0x83`; item field `+0x28` changed `0x3F800000 -> 0`. The next periodic frame shows name entry.

Counts were 27 XID/DMA reports, 21 edge-consume rows, 365 pilot-list callback rows, and one row-post record. `[SB-SNAPSHOT]`, `[SB-INPUT-DISPATCH]`, and `[MENU-DISPATCH]` emitted zero records; therefore the internal snapshot/dispatch substage is not directly observed. `sub_000E0870` remains a candidate, not the active callback proven by this visible row.

## Loader path evidence

- At tick `361941312`, guest call frame return `0x000C2E1A` opens `D:\media\BIN\TEX00.BIN` successfully (lifecycle row n=346). The matching host handle is `0xFA8`; the only correlated I/O is a successful 56-byte metadata query (`FILE-IO` n=4632, class `0x22`), followed by close. The token `0x48000085` is reused for later files, so the path and host handle—not token alone—identify this operation.
- The mode-2 loader starts at tick `361941671` on guest TID `125716`, through return `0x00102063`, mode 2, table `0x002602A8/0x0025E2D4`.
- At tick `361941796`, its first `Z:\TEX00.BIN` cache open fails with `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`). Guest caller `0x0018E758` returns to `0x000C2F3E -> 0x00102063`; the same pass exits through `0x000C32D6`, scan range 2..11, last index 28, result 0, pair `0x011E2E00/0`.
- In generated `sub_000C2EB0`, the paired-open branch calls the cache open at `0x000C2F3E`; an invalid first handle branches directly to `0x000C300D` and returns. That path does not proceed to the second open/copy logic in this helper. This matches the runtime trace but does not explain which earlier producer should have populated the cache.
- The identical cache miss repeats through pass 259, final observed tick `362432250`. Every recorded mode-2 pass entered/returned (259 each), with result 0 and the same pair. This scan result/pair are not independently verified load-progress fields.
- Across all 13,814 lifecycle open records, the only repeatedly failing game-media path is `Z:\TEX00.BIN` (259 failures). The other 25 failed paths are save/config names under `T:\` plus the separate pre-pilot `Z:\st00_0.rep` miss; no second media dependency surfaced in this run.
- The first `Z:\st00_0.rep` miss occurred earlier at tick `361534312`, before pilot creation, and maps to an empty save cache path. Keep this optional empty-save condition separate from the later TEX00 resource miss.
- Preload worker TID `126572`, entry `0x00017E40`, took `preload-mode0` at tick `361542734`. The run recorded 21 file-copy helper calls/returns and other successful writes (including STRM00); the trace stores guest pointers rather than a complete source/target path pair. None of those records ties a copy to TEX00. The early worker activity does not prove the TEX00 cache entry was produced.

## Rendering, waits, and thread snapshots

- The 429 raster performance records show high CPU raster cost. A late window at tick `362431750` reports 27 batches, 56 triangles, about 2,027.70 ms batch wall time, and 7,846.78 ms summed worker-active time across four workers. No queue-depth or in-flight batch identity proves an accumulating rendering backlog or its causal role in loading.
- DCF4 callback records continued (14,241 total), and reset/counter fields advanced. However, DCF4 wait-entry logging reached its 4,096 cap at tick `361814781`, before the mode-2 scan began. There were later sampled successful wait returns (105 total, last at tick `362361203`, status 0 and `guest_signal=1`), but these do not exhaustively rule out a later DCF4 wait. Producer-stage tracing and continuous DMA/PB-semaphore evidence were not enabled for r92. Do not merge the historical Campaign-stage DCF4 wait with this loading trace.
- Two dumps for guest main TID `125716` were captured at 10:05:43 and 10:07:09. The offline unwinder produced Windows frames then stopped at a non-module guest value (`0xDB8`); it did not validate a guest loader/file-wait stack. The current dump does not establish a blocked I/O request owner.
- The last BMP (`frame.bmp`, 10:11:09) visibly shows `NOW LOADING`. Captures were periodic, so a short-lived scene between capture intervals cannot be excluded; no captured in-mission frame or gameplay telemetry is present.

## Trace limits and next diagnostic

No code fix, indirect-target seed, cache copy, or architecture change is justified from this run. Keep AOT execution, controller mapping, guest fence behavior, and rasterizer baseline `1ea1871`. The next useful diagnostic is to trace cache population for the mode-2 resource set and correlate every source open, cache create/write, completion status, and file close to the same guest resource index; retain bounded wait logging but rotate/extend wait caps so they cover the loading interval. Capture the first mission frame if reached, and stop the diagnostic watchdog at the planned bound otherwise.

Storage: seven byte-identical numbered screenshots were moved—not deleted—to `iso/local-analysis/obsolete-for-user-review/m3-loader-file-lifecycle-r92-duplicate-frames/`; its `manifest.json` records names, sizes, and hashes. One copy per hash remains beside the run logs.
