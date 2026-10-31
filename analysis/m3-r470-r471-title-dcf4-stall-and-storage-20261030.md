# r470–r471 title transition, DCF4 wait, and storage — 2026-10-30

## Outcome

The authorized empty-save new-pilot route did not reach the pilot list, loading screen, or mission. r470 and r471 both started from the visible Steel Battalion title prompt and changed to a black framebuffer after the Main Weapon input. In r471, the final retained screenshot is black (`frame-history/capture-0002.bmp`); the original title screen remains in `frame.bmp`. Neither run emitted a pilot-list callback or load-state callback. This is an earlier title-transition blocker, not the post-difficulty loading plateau.

The r471 dump validates a host thread waiting through `xbox_KeWaitForSingleObject` on host handle `0xF9C`, matching the trace's guest object `0x0021DCF4` on TID `10092` at caller hint `0x00211F3B`. Sampled wait records 1–8 returned; records 9–16 did not return before capture. The final sampled wait was tick `47887281`, frame `0x16A`, counter `0x5E1`, target `0x5D7`, fence `0x5D3`, guest signal 0. This supports an outstanding title DCF4 wait. It does not identify the missing causal producer or prove that this wait alone caused the black frame.

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

The final `[DCF4-HEARTBEAT]` sample (tick `48068296`) had DCF4 state `0x00040000`, signal 0, raster active workers 0, pending work 0, and DMA PUT=GET=`0x5A04`. Raster batch `1682` had only two triangles. The DCF4 outer loop continued to emit after the callback-specific trace stopped at its bounded 466 rows. Sampled `[SB-DCF4-MARKER]` records ended at `pfb-flush-return` with PFB/PUT/GET/signal all zero; no `[SB-PFB-POLL]` occurred. This argues against an active raster backlog at the later sampled wait, but the asynchronous trace streams and framebuffer capture are not an atomic snapshot. Earlier rendering cost was high and remains a separate performance concern.

The host unwind for TID `10092` reaches `xbox_KeWaitForSingleObject+0x29`, then stops at non-module handle `0xF9C`; it is a valid native unwind to the wrapper, not a guest call-chain unwind. TID `9040` has an incomplete native unwind through a file bridge, but no file records for that TID; it is not evidence of a file dependency. TID `30932` did not produce an informative unwind. Do not interpret raw guest-looking stack values as unwound frames.

## Hypothesis and disposition

**Tested hypothesis:** the black title-transition frame is caused by expensive raster batches backing up the renderer. **Not supported by the captured stall window:** r471's later heartbeat shows no active or pending raster workers, DMA PUT equals GET, and only two triangles in the latest batch, while the guest DCF4 object remains unsignaled and a host wait is outstanding. Earlier raster cost remains a separate issue; this trace does not exclude every renderer timing effect.

**Supported immediate state:** an outstanding DCF4 wait correlates with the black title-transition state. **Still unknown:** which producer should signal DCF4, whether it ran or failed, and the causal path from that state to the screen transition. No loading-stage dependency can be assessed from these runs because `NOW LOADING`, file-preload callbacks, loader state callbacks, and a mission frame were not reached.

No code, game behavior, controller mapping, guest fences, build cache, or rasterizer was changed. No build or test ran. The r130 `ObReferenceObjectByHandle` completion semantics, post-difficulty `0x3FFF` poll, DirectSound list corruption, and expensive raster performance remain separate findings. The existing rasterizer baseline `1ea1871` is preserved.

## Trace and storage limits

The asynchronous trace relay queue capacity was 32,768 and recorded zero dropped stdout or stderr lines. The 64 MiB per-run storage budget did not trigger; the r471 manifest reports zero trace-limit hits. Frame history was capped at four and retained two lossless 640×480 captures with no drops. DCF4 wait history was a bounded sample (16 waits), not a complete lifetime history. The run manifest reports `AllocatedSizeQueryFailureCount=0` for its own exit-time query, but its allocated-byte fields are `-1`; a post-exit `GetCompressedFileSizeW` scan measured the evidence folder instead.

Post-exit evidence measurements:

| Run | Logical bytes | Allocated bytes | Files |
|---|---:|---:|---:|
| r470 | 4,719,183 | 2,162,462 | 18 |
| r471 | 5,188,091 | 2,361,921 | 20 |
| Combined | 9,907,274 | 4,524,383 | 38 |

The allocation scan counts sparse allocation separately from logical size. The current last full workspace scan remains r466 at 39,799,862,841 allocated bytes (37.067 GiB); adding r469–r471 evidence gives an approximate 39,805,973,243 bytes (37.072 GiB), not a new full scan. No bytes were reclaimed in this pass. The warm incremental build cache was untouched, so build-efficiency impact is zero. A proposed lossless compression/replacement of the closed raw trace logs was rejected by the automatic file-action review; no raw logs were removed or altered.

## Next discriminating step

Use the retained r471 callback arguments, gate records, wait samples, and matched dump to trace the expected DCF4 signaling path from the dispatch table/owner into the event producer. Add only bounded producer-side evidence if static call/data-flow plus this run cannot resolve whether the producer executed. Reproduce the screen-gated transition only after locating a reliable title input sequence; do not force a signal, bypass the title check, seed an import, or alter guest fence behavior. Keep the historical title DCF4 wait separate from DirectSound corruption and post-difficulty loading. Stop gameplay acceptance at the first visually verified mission frame.
