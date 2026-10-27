# Milestone 3 diagnostic r89: bounded ordinary waits and crash — 2026-10-27

## Run identity and result

- Run: `m3-pilot-loading-r89-all-waits-20261027`, diagnostic PID `126676`.
- Started 2026-10-27 09:25:28 CDT. Process exited naturally at 09:27:48 CDT with Windows status `0xC0000005` (access violation); the 900-second watchdog did not fire.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-all-waits-r89-20261027/Release/your_game_recomp_producer_trace.exe`, SHA-256 `D9647479FF7ACB95CC5113818A3AE8E73B77C78543D3261A3EA3CD493E528A81`.
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. Save root reused: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save copy was made.
- Effective extra wait setting: `RECOMP_WAIT_TRACE_ALL_LIMIT=4096`; the original ordinary-wait cap otherwise remains 64. DCF4/DCE4 retain their independent caps. The asynchronous relay dropped zero lines and stopped cleanly.
- Ignored local run evidence: `iso/local-analysis/logs/m3-pilot-loading-r89-all-waits-20261027/` (`stderr.log` 4,089,328 bytes, `wait-trace.log` 1,068,159 bytes, `crash.dmp` 378,973 bytes).

## Screen-gated input and where the run stopped

The captured framebuffer showed the title screen, then the Campaign menu and the pilot menu with `LIST AS NEW`. The live `a:800` input at 09:27:36 CDT was delivered through XID; the guest menu callback at `0x000E18D8` selected branch `0x000E193B`. Resource VA `0x0026AF04` identified `LIST AS NEW`, and row `0x002E4C34` changed field `+0x28` from `0x3F800000` to zero at site `0x000E19CF` (action `0x83`). This confirms the new-pilot selection transition.

The run did not reach the name/date/difficulty stages, `NOW LOADING`, or a mission framebuffer. The last saved framebuffer is mostly black and is not evidence of a first mission frame. Therefore r89 identifies no loader dependency.

## Wait and rendering evidence

The additional all-wait capture emitted one ordinary wait: guest event `0x00F7FED0`, type 1, caller hint `0x0025A31F`, host state `WAIT_TIMEOUT` (`0x102`) at the pre-wait sample. No later ordinary guest wait was observed before the crash. This shows the earlier 64-record ordinary-wait cap did not conceal a second wait during this title/pilot-menu portion; it says nothing about a loader wait that this run never reached.

DCF4 continued to make progress during the run: 3,180 callback records, 1,371 waits, 1,364 sets, 1,371 resets, and 23 sampled return rows. DCE4 had 36 waits and 35 sampled returns. The final NV2A tick recorded frame `0x70A`, counter `0x4949`, target `0x4923`, and fence `0x4947`. This is progressing synchronization telemetry, not evidence of a DCF4 stall. The ordinary-wait addition did not enable the separate DCF4 producer-stage trace.

There were 59 raster performance windows. Representative windows varied substantially: e.g. 1,682 batches / 3,364 triangles at 1.54 seconds batch wall and 5.49 seconds summed worker-active, and later 5,409 batches / 10,818 triangles at 0.58 seconds wall and 0.80 seconds summed worker-active. These records establish heavy CPU raster work but do not establish a monotonic render queue or explain the audio crash.

## Supported immediate crash mechanism

At tick `359803750`, two `[DS-COMMIT-INVALID-NODE]` records describe a malformed DirectSound deferred-settings list at argument `0x010810A4`, sentinel `0x010810B4`. The walker saw node `0xFF000000`, then node zero; predecessor `0x8038C098` had `next`, `prev`, and owner values `0xFF000000`.

The crash logger recorded a read access violation at host address `0x10000FFF4`, corresponding to guest VA `0xFFFFFFF4`. Guest registers were `EBX=0`, `ESI=0xFFFFFFEC`, `EDI=0x010810A4`. Generated `sub_0021FE7C` (`recomp_0016.c`, guest return site `0x0021FECA`) computes `EBX - 20` and calls `sub_0021ED29`; that callee dereferences `[ESI+8]` at generated line 1708. With the recorded ESI, this is exactly `0xFFFFFFF4`. Thus the immediate fault is supported as an invalid DirectSound list-node dereference. The earlier write or failed initialization that corrupted the node/link remains unlocated. This is an audio-list crash before loading, not the historical DCF4 wait or a proven loading failure. No fix was made.

## Trace limits and next step

The r89 executable contains only the new opt-in bounded ordinary-wait trace in addition to the existing diagnostic instrumentation. Marker counts show no loader state/pass/helper, file lifecycle, or loader stack records before the crash. The crash dump and guest register/stack summary support the immediate fault; stack-scan output is not a complete native unwind. No current frame beyond the pilot menu was captured.

Next, keep the new-pilot route and AOT behavior, but instrument DirectSound deferred-list insert, unlink, initialization, and commit writes with bounded before/after node and owner fields. Do not patch or seed from the bad node alone. Reproduce until the bad predecessor/edge is first written or the path remains stable; then resume the loader trace to `NOW LOADING`. Keep DCF4, audio-list corruption, raster cost, and loader progress as separate questions. Preserve controller mapping, guest fences, and rasterizer baseline `1ea1871`.
