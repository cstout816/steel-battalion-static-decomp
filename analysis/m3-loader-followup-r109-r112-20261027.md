# Steel Battalion AOT loader follow-up — r109–r112 (2026-10-27)

## Result

The screen-gated new-pilot route reached a captured `NOW LOADING` frame in r111. The first repeatable blocked transition is still the loader scheduler gate, not a demonstrated file-read wait or DCF4 deadlock: guest site `0x00101FC0` repeatedly requests mode 1, receives helper result 0, skips the scheduler, and leaves active mode 0, load index 1, and stage 0. The recurring mode-2 scan returns 0 with progress pair `0x011E2E00/0` unchanged. No first mission frame was reached. Separately, r107 recorded `sub_00191451` receiving a null object through the global `0x00311CC8` after an earlier mode-0 initialization; the intervening clear is still unobserved. Do not treat these cross-run records as one synchronized event or a proven upstream cause.

The cache miss for `Z:\TEX00.BIN` is a concrete candidate, but the trace does not connect it to the mode-1 gate. The source-side `D:\media\BIN\TEX00.BIN` open succeeds, the cache-side open fails, and the guest scan repeats. The 21 observed copy callbacks had already completed successfully before this source probe; no later copy completion appears. This alone does not prove the scheduler requires that cache entry.

## Run identity and setup

| Run | PID | Result |
| --- | ---: | --- |
| `m3-screen-gated-write-watch-r109-20261027` | 131056 | Helper attached at startup; stayed at Dolby splash; exact-child UI watchdog stopped after 300 seconds with no framebuffer/input change. |
| `m3-screen-gated-write-watch-r110-20261027` | 131776 | Same startup stall and exact-child UI watchdog stop. |
| `m3-screen-gated-loader-r111-20261027` | 129804 | No helper at startup; screen-gated route reached `NOW LOADING`; loader plateau watchdog stopped it after 300 seconds with no loader/frame progress. |
| `m3-delayed-write-watch-r112-20261027` | 125376 | No helper; reached the Campaign screen, then crashed before the pilot list with an access violation in the DirectSound voice-list path. |

All runs used the same AOT executable, SHA-256 `20FD6B08C769CC529E6F5F47E7128D92FDE5BC31427B767E6834C01FADDA1345`, and generated source directory `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. The matching PDB SHA-256 is `18C54073CB87BE0C5D21C8A2B4871F1B3A9A04D4458C2931B1B50520D797537F`. The save root was `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save copy was made. AOT code, controller mapping, guest fences, renderer, and rasterizer were not changed. Generic `RECOMP_TRACE_ENTER/EXIT/ESP` macros remain no-ops; these findings come from dedicated compiled trace sites. No indirect target was seeded.

The two startup-helper runs and the successful no-helper r111 run make helper attachment a possible contributor to the Dolby-splash stalls, but do not establish causality. Both r109 and r110 recorded only the initial `0x00311CC8: 0 -> 0x48000078` write before their splash stall. r112 also ran without the helper and crashed on a separate route before loading. A delayed write-watch attach was not reached in r112.

## Screen-gated input correlation in r111

The route transcript is in `iso/local-analysis/logs/m3-screen-gated-loader-r111-20261027/pad-live.txt`. The visible title prompt was followed by Campaign, the pilot list with `LIST AS NEW` highlighted, name/date entry, date confirmation, Normal difficulty, and `NOW LOADING`.

At tick `378256437`, XID report byte 2 changed to `0x01` at guest buffer `0x01081763` / bus address `0x81081763`. At tick `378256531`, guest edge handling at `0x000C8064` copied `0x0001` into `0x004AFC08`; the predicate at parent `0x000E18D8` returned 1. The active row callback `sub_000E1820` at `0x000E18D8` selected branch `0x000E193B` with `xid2=1` and `button_cell=1`. Its resource lookup resolves slot `0x002E4C34` to `LIST AS NEW` at VA `0x0026AF04`. At tick `378300906`, row action `0x83` at `0x000E19CF` changed `0x002E4C34+0x28` from `0x3F800000` to 0. This correlates the visible action through input delivery, edge handling, callback branch, and row state change. Candidate `sub_000E0870` remains unselected by this event.

## Loader, files, and progress

In r111, 170 `[LOAD-SCHED-GATE]` rows requested mode 1 at `0x00101FC0`; the last observed rows still report `helper_result=0`, `decision=skip`, `active_mode=0`, `load_index=1`, `load_stage=0`, `object=0x2B`. The repeated mode-2 scan at `sub_000C3020` returns through `0x000C32D6` with range 2..11, last index 28, branch `scan`, result 0, pair `0x011E2E00/0`. State callbacks at `0x0010203A`, `0x0010205A`, `0x0010206B`, and `0x0010208A` preserve the unchanged mode/progress/status/object fields.

The load stack sample exposes guest site `0x000C319A`, the `D:\media\bin\` / `Z:\` path formatting frames, and a cache filename such as `Z:\STRM07.WAV`. This is a snapshot of the active resource scan, not evidence of a permanently blocked host read. The bridge returned completed reads synchronously; guest `STATUS_PENDING` in older traces represented that compatibility contract.

During the observed loading interval, the read count stayed at 5,894, and all 21 `[FILE-COPY-RETURN]` records had result 1 and ended before the loader-mode-1 requests. Metadata queries and opens continued, but no new file-copy completion or content read appeared. `D:\media\BIN\TEX00.BIN` opened successfully at tick `378755062`; `Z:\TEX00.BIN` then failed with `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`) from tick `378755546` onward. This cache miss is not yet causally linked to the scheduler gate.

## Graphics and event synchronization

Graphics/event work advanced during the loader stall. NV2A frame, counter, target, and fence values increased. Sampled DMA PUT and GET matched. DCF4 callbacks continued and exposed their argument/selected-target pairs: `0x5 -> 0x0021701E` (9,614), `0x01080021 -> 0x00216EC9` (5,037), `0x03600021 -> 0x00216EC9` (5,037), `0x9 -> 0x0021707C` (6), and `0x28 -> 0x00217053` (1). DCF4 event state toggled; no persistent unsignaled DCF4 wait was established, so producer-stage tracing was not enabled. Keep this separate from the loader gate.

The 432 raster windows in r111 show a recurring loading workload near 27 batches / 56 triangles, roughly 2.0 seconds batch wall time and 7.8–8.0 seconds summed worker-active time over four workers. This verifies very expensive CPU raster work, not a growing queue and not a cause of helper result 0.

## Trace limits and caveats

- r111 asynchronous relay dropped zero lines and reported complete marker counts.
- `[FILE-CALL]` reached its 6,000-record limit; `[FILE-MISS-PATH]` reached 64. Later per-call/path failures are therefore not exhaustive.
- `[PILOT-LIST-CB]` and `[MENU-OBJECT-GATE]` each reached 512. The one positive input/row-action sequence is present before the cap, but later menu rows are incomplete.
- `[FILE-IO]` emitted 5,335 of its 8,192-record budget; open/close counts were 9,186/8,963, below their 50,000 limits. Loader callback/gate/pass rows remained below their 2,048/8,192 limits.
- r111's `NOW LOADING` framebuffer remained unchanged through the 300-second loader plateau. No first mission frame, gameplay, campaign progression, in-mission audio, save/load, or 60-FPS result is verified.
- r112 is a separate failure: native RIP `0x7FF759144D18`, read fault at `0x10000FFF4` (guest VA `0xFFFFFFF4`), with guest stack through `0x0021FECA`, `0x00220FAF`, and `0x0010DB19`; its DirectSound voice-list chain ended at null. It did not reach the loader and does not explain r111.

## Disposition and next step

No behavior fix, hook, seed, renderer change, or save edit is justified. The supported finding is the mode-1 scheduler skip with an unavailable/null helper object; the upstream operation and any relationship to the `TEX00.BIN` cache miss remain candidates. Next, trace the object/global lifecycle around the mode-0 initialization and mode-1 callback with a low-overhead delayed write watch or equivalent trace-only instrumentation, attaching only after startup. Then repeat the same screen-gated route and stop at the first verified mission frame. Keep the r112 DirectSound crash separate.

**Progress:** overall `2/8`; XBE/decompilation `2/4`; boot/compatibility `4/5`; loader dependency tracing `2/4`; startup rendering `2/4`; controller `2/3`; audio/DSP `1/2`; first mission framebuffer `0/1`; stable 60-FPS gameplay `0/1`.
