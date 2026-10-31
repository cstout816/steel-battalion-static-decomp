# r470–r471 title transition, DCF4 wait, and storage — 2026-10-30

## Outcome

The authorized empty-save new-pilot route did not reach the pilot list, loading screen, or mission. r470 and r471 both started from the visible Steel Battalion title prompt and changed to a black framebuffer after the Main Weapon input. In r471, the final retained screenshot is black (`frame-history/capture-0002.bmp`); the original title screen remains in `frame.bmp`. Neither run emitted a pilot-list callback or load-state callback. This is an earlier title-transition blocker, not the post-difficulty loading plateau.

The r471 dump validates a host thread waiting through `xbox_KeWaitForSingleObject` on host handle `0xF9C`, matching the trace's guest object `0x0021DCF4` on TID `10092` at caller hint `0x00211F3B`. Wait-entry logging records the first 16 waits and then every 256th; successful returns are logged only for the first eight and then every 64th. The absence of matching return rows for waits 9–16 is **not** evidence those calls stayed blocked. The last sampled entry was tick `47887281`, frame `0x16A`, counter `0x5E1`, target `0x5D7`, fence `0x5D3`, guest signal 0; it does not identify which wait was active at dump time.

## Run and exact-bundle identity

Both runs used only the diagnostic executable PID shown below and the same existing empty-save directory; no save copy or hard link was made. The process was stopped only after verifying PID `35748` still referred to the r461 diagnostic executable and the frame had remained black. No other game process was stopped.

| Run | PID | Evidence directory | Result |
|---|---:|---|---|
| r470 | 10380 | `iso/local-analysis/logs/m3-title-route-replay-r470-20261030` | Title input did not enter pilot list; black transition frame |
| r471 | 35748 | `iso/local-analysis/logs/m3-title-dcf4-producer-followup-r471-20261030` | Same route; producer and DCF4 callback tracing enabled; black transition frame |

Both used the r461 AOT image and matching generated-source tree. The EXE SHA-256 is `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`; PDB SHA-256 is `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`; MAP SHA-256 is `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`. Generated source is `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. Save root: `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`.

The r470 dump is `title-black-frame-01.dmp`, with its unwind in `unwind-t37100.txt`. The r471 dump is `dcf4-black-frame-02.dmp`, with unwinds in `unwind-t10092.txt`, `unwind-t30932.txt`, and `unwind-t9040.txt`. Both manifests record the exact input bundle hashes.

## Screen-gated input and route

The displayed title prompt was `PRESS MAIN WEAPON BUTTON`. In both runs the injected Main Weapon input reached the XID report (byte 2 bit 0), the guest input/edge probes recorded six predicate samples and one edge-consumer transition, and the screen then went black. The title route query remained zero. r471's final counters were `[TITLE-ROUTE-QUERY] 383`, `[PILOT-LIST-CB] 0`, `[PILOT-ROW-POST] 0`, `[MENU-RESOURCE] 0`, and `[LOAD-STATE-CB] 0`. The counters and records do not show entry into `sub_000E1820`, its active branch `0x000E193B`, or the `LIST AS NEW` row action `0x83` at `0x000E19CF`.

The pilot handler remains a known candidate, not an active handler in these runs. The route currently fails before any evidence of pilot-list dispatch; the input's delivery and edge consumption do not prove the game's title-route predicate was satisfied.

## DCF4 callback and graphics/event evidence

r471 emitted 466 `[DCF4-CB]` rows and 464 `[DCF4-GATE]` rows, with no probe cap hits. Every gate row selected reason 7. The callback's complete observed argument/branch histogram was:

| Argument | Index | Selected target | Rows |
|---:|---:|---:|---:|
| `0x01080021` | 1 | `0x00216EC9` | 201 |
| `0x03600021` | 1 | `0x00216EC9` | 201 |
| `0x00000005` | 5 | `0x0021701E` | 57 |
| `0x00000009` | 9 | `0x0021707C` | 6 |
| `0x00000028` | 8 | `0x00217053` | 1 |

The selected targets agree with the callback dispatch table at `0x00217094`; the callback call site is `0x002171C9`, with context `0x0021DB50`. Keep the full argument-level records in the run's `stderr.log`.

Static code and runtime records identify a working signal path for index 5. At `0x0021701E`, the guest calls the function pointer at `0x0025D1E8` with the event at `context+0x1A4`; the indirect call returns to `0x0021702F`. The r471 wait trace contains 57 `set-DCF4` rows, all from TID `9040`, guest object `0x0021DCF4`, host handle `0xF9C`, caller hint `0x0021702F`. Existing import evidence maps the synthetic thunk at `0xFE000108` (original XBE cell value `0x80000091`) to `KeSetEvent`. Thus the signal producer executed repeatedly and signaled the same valid host event used by the wait. Do not describe this as a missing event implementation or a lost signal during those cycles.

The final callback rows narrow the later stall window. Callback #465 at tick `47891671` selected index 5 and was followed by `set-DCF4[57]`; callback #466 at tick `47891734` selected index 1 and did not signal DCF4. The callback count then stayed at 466 while the DCF4 outer loop continued emitting through at least tick `48071828`. No later `set-DCF4` row appeared (the DCF4 setter trace allows 4,096 events and did not reach its cap). At the later heartbeat, DCF4 signal remained 0, raster workers and pending batches were zero, and DMA PUT=GET=`0x5A04`. TID `10092` was still in the native wait wrapper on handle `0xF9C` in the live dump. This supports a later wait after callback/signal production ceased, but sparse wait-entry/return logging leaves its exact wait number and entry time unknown. The trace does not establish why the index-5 callback stopped.

The final `[DCF4-HEARTBEAT]` sample (tick `48068296`) had DCF4 state `0x00040000`, signal 0, raster active workers 0, pending work 0, and DMA PUT=GET=`0x5A04`. Raster batch `1682` had only two triangles. The DCF4 outer loop continued to emit after the callback-specific trace stopped at its bounded 466 rows. Sampled `[SB-DCF4-MARKER]` records ended at `pfb-flush-return` with PFB/PUT/GET/signal all zero; no `[SB-PFB-POLL]` occurred. This argues against an active raster backlog at the later sampled wait, but the asynchronous trace streams and framebuffer capture are not an atomic snapshot. Earlier rendering cost was high and remains a separate performance concern.

The host unwind for TID `10092` reaches `xbox_KeWaitForSingleObject+0x29`, then stops at non-module handle `0xF9C`; it is a valid native unwind to the wrapper, not a guest call-chain unwind. TID `9040` has an incomplete native unwind through a file bridge, but no file records for that TID; it is not evidence of a file dependency. TID `30932` did not produce an informative unwind. Do not interpret raw guest-looking stack values as unwound frames.

## Hypothesis and disposition

**Tested hypothesis:** the black title-transition frame is caused by expensive raster batches backing up the renderer. **Not supported by the captured late stall window:** r471's heartbeat shows no active or pending raster workers and DMA PUT equals GET. The DCF4 index-5 callback signaled the event 57 times; afterward, the callback count stopped at 466 and the next sampled heartbeats showed signal 0 while the outer loop still ran. The dump then found TID `10092` in a wait wrapper. This supports a later synchronization wait after index-5 signal production ceased, rather than an active raster backlog. Earlier rendering cost remains a separate performance issue.

**Supported immediate state:** the guest DCF4 producer path worked and repeatedly called `KeSetEvent`; its index-5 callback then stopped after callback #465 while the outer loop continued. A later live dump shows the guest thread waiting on the same DCF4 host event with signal 0. This supports a late DCF4 wait following cessation of the signaling callback, but the reason index 5 stopped and the relation to the black screen are not established. No loading-stage dependency can be assessed because `NOW LOADING`, file-preload callbacks, loader state callbacks, and a mission frame were not reached.

No code, game behavior, controller mapping, guest fences, build cache, or rasterizer was changed. No build or test ran. The r130 `ObReferenceObjectByHandle` completion semantics, post-difficulty `0x3FFF` poll, DirectSound list corruption, and expensive raster performance remain separate findings. The existing rasterizer baseline `1ea1871` is preserved.

## Trace and storage limits

The asynchronous trace relay queue capacity was 32,768 and recorded zero dropped stdout or stderr lines. The 64 MiB per-run storage budget did not trigger; the r471 manifest reports zero trace-limit hits. Frame history was capped at four and retained two lossless 640×480 captures with no drops. DCF4 wait-entry rows emit waits 1–16 then every 256th; successful returns emit the first eight then every 64th; DCF4 sets emit every event up to 4,096. Thus the trace does not pair every wait and return in the later stall window. The run manifest reports `AllocatedSizeQueryFailureCount=0` for its own exit-time query, but its allocated-byte fields are `-1`; a post-exit `GetCompressedFileSizeW` scan measured the evidence folder instead.

Post-exit evidence measurements:

| Run | Logical bytes | Allocated bytes | Files |
|---|---:|---:|---:|
| r470 | 4,719,183 | 2,162,462 | 18 |
| r471 | 5,188,091 | 2,361,921 | 20 |
| Combined | 9,907,274 | 4,524,383 | 38 |

The allocation scan counts sparse allocation separately from logical size. A fresh read-only full scan after r471 measured 79,343 files, 39,806,838,262 allocated bytes (37.073 GiB), 1,399,630,939,024 logical bytes (1,303.508 GiB), 13 skipped reparse points, and zero allocation-query failures. C: had 45,906,464,768 bytes free. No bytes were reclaimed in this pass. The warm incremental build cache was untouched, so build-efficiency impact is zero. A proposed lossless compression/replacement of the closed raw trace logs was rejected by automatic file-action review; no raw logs were removed or altered.

## Next discriminating step

Use retained r471 callback, setter, gate, wait, and dump evidence to trace what stops delivery of the index-5 callback after #465. Focus on the callback queue/source and PGRAPH/DMA handoff immediately after the final `0x0021702F` signal; add bounded evidence only if static call/data flow cannot locate that stopping edge. Reproduce the title transition only after finding a reliable input sequence. Do not force a signal, bypass the title check, seed an import, or alter guest fence behavior. Keep this title wait distinct from DirectSound corruption and post-difficulty loading. Stop gameplay acceptance at the first visually verified mission frame.
