# r481–r482 title input, DCF4 dispatch, and DirectSound watch (2026-10-30)

## Finding

The first mission frame remains **0/1**. No gameplay fix, source/generated-code edit, build, or cache change was made. AOT, guest fences, controller mapping, and rasterizer `1ea1871` are unchanged.

r482 is the best synchronized title-stage trace so far. A screen-gated A press reached the game as XID byte 2 = 1, the guest edge cell `0x004AFC08` changed `0→1`, the input predicate returned 1, and title callback `0x000E0840` selected `next=0x002A625E`. The live framebuffer visibly changed to “Unable to load Player Record.” This proves one end-to-end input and resulting visible state change. The overlay was inspected before the second pulse; the final retained frame-history capture is black, so the overlay image itself is not retained.

A second `a:5000` pulse reached XID byte 2 and was released, but there was no second guest edge-consumer record. The framebuffer was later captured black with the window at 0 FPS / 74 draws. Therefore the black state is observed after the second pulse, but the trace does **not** prove that pulse caused it. Campaign, `LIST AS NEW`, pilot-list callback, `NOW LOADING`, loader/file callbacks, and mission frame were not reached in r482.

### Exact r481/r482 bundle identities

Both runs used r461 AOT executable SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`, PDB `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`, MAP `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`, and generated `recomp_0015.c` `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`.

- r481 `iso/local-analysis/logs/m3-dsound-campaign-writer-r481-20261030`, diagnostic PID `9628`, matching dump `title-no-edge.dmp`.
- r482 `iso/local-analysis/logs/m3-dcf4-repro-and-dsound-watch-r482-20261030`, diagnostic PID `7796`, matching dump `post-error-black-stall.dmp`.

Both were stopped only after verifying the process path matched that run's executable. The bounded asynchronous relay reported zero dropped lines. Both reused the same empty new-pilot save root.
## DCF4 evidence in r482

Run `m3-dcf4-repro-and-dsound-watch-r482-20261030` used the exact r461 AOT EXE/PDB/MAP and generated-source bundle. DCF4 callback detail covered all 325 callbacks with no callback cap. Argument/selected-jump counts:

| Argument | Index | Selected target | Count |
|---|---:|---:|---:|
| `0x01080021` | 1 | `0x00216EC9` | 119 |
| `0x03600021` | 1 | `0x00216EC9` | 119 |
| `0x00000005` | 5 | `0x0021701E` | 80 |
| `0x00000009` | 9 | `0x0021707C` | 6 |
| `0x00000028` | 8 | `0x00217053` | 1 |

Gate telemetry sampled reason 7 at caller `0x002173C7`, which follows the `edi==0x100` branch in guest `sub_00217130` and dispatches through `sub_00216EA0` at `0x002171C9`. Its jump table selects the targets above. Its jump table is at guest `0x00217094`. In the generated source `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen/recomp_0015.c`, `sub_00217130` reaches reason 7 at `0x002171BF` and calls `sub_00216EA0` at `0x002171C9`; the index-5 body at `0x0021701E` calls through `MEM32(0x0025D1E8)` at `0x00217029` and returns at `0x0021702F`. The runtime trace associates that return site with DCF4 setting, but the pointer value itself was not captured or resolved; do not assume its current target before validating it. The last callbacks were #324 (`arg=5`, index 5, target `0x0021701E`) and #325 (`arg=0x03600021`, index 1, target `0x00216EC9`). The index-5 path makes an indirect call through guest pointer slot `0x0025D1E8`; `set-DCF4[80]` records its return site `0x0021702F` after callback #324. No later callback was recorded before process stop.

After callback #325, the outer loop continued. Later queue samples had `idx=0`, `ptr0=0`, `ptr1=0`, `result=0`; sampled queue sequence advanced while those slot pointers stayed empty. At the 60-second watchdog snapshot, the UI guest thread TID `6180` had guest `ESI=0x0021DCF4`, event signal 0, and was in the `KeWaitForSingleObject` wrapper. Exact-bundle offline unwind ends at `xbox_KeWaitForSingleObject+0x29` and non-module handle `0xEB0`. This is a validated native unwind to the host wait; the guest stack words printed by the watchdog are only a memory snapshot, not an unwind.

The last fully correlated sampled wait, `wait-DCF4[64]`, returned 234 ms after entry. Wait logging samples waits 1–16 and then 64; returns sample the first eight and then 64. The snapshot thus does not prove all later waits were blocked. It does establish that by capture the event was unsignaled while the thread was in the wait wrapper and the DCF4 callback stream had ended at #325. This supports a later DCF4 synchronization/empty-queue lead, but does not identify why the queue was not replenished or prove the callback stop caused the black output.

At the same snapshot: NV2A DMA `PUT=GET=0x00005DEC`; PGRAPH pending 0; raster active 0 and pending 0; semaphore `0x80003000=0x40D` versus guest put-counter `0x411`. Thus this sampled black state is not a raster-worker backlog, and the ring had drained. Keep the semaphore discrepancy and event/queue state as separate synchronized fields; do not force a signal or fence.

## DirectSound watch and r481 control

The r482 watch monitored `0x8038C08C`, `0x8038C098`, `0x8038C09C` and recorded nine writes, all during list construction: zero initialization, self-links, then owner `0x010810A4`, next `0x010810B4`, previous `0x803B0C10`, and next `0x8038C4E0`. No write of `0xFF000000` occurred. No invalid node or pilot-list callback followed. This is consistent with r480 and still does not expose the r479 writer.

r481 used the same exact bundle and watch. It visually remained at the title prompt. Its A pulse reached XID byte 2 = 1 but produced no guest edge. It recorded recurring DCF4 waits and matched event returns through sampled wait #64, plus setter rows through #85. A 60-second dump unwinds TID `8828` to the wait wrapper and handle `0xE68`; the framebuffer remained at the title prompt. r481 did not reach the DirectSound traversal. It was stopped only after capture because the screen did not progress.

## Prior dump review and current kernel source

The retained r150/r151/r153 dumps were reviewed with their exact matching r149 bundle: EXE `D503E6DA6325E9771364C9160F358A21550128B34AAC7B500A34C0EE0642A15C`, PDB `1741EA1E29FEF3DF22182C934AF3E30BAECCCB0DFFB93C1649080095A2A94287`, MAP `4AE43B0B58C029D290E9041297232C303E9EBF0E8FC04D54761EB5BBFE4A6A37`.

- r150/r151 main-thread native unwinds validate the host wait wrapper, not a recovered guest caller chain. r151 telemetry correlates wait #73 with guest event `0x0021DCF4`; set #72 woke the preceding wait, then callback #391 selected index 1 (`0x00216EC9`), with no following index-5/`KeSetEvent` before that run stopped.
- r150/r151 raster workers unwind to the normal infinite wait in `raster_worker+0x9F`; their snapshot does not prove a stuck raster queue.
- r153 is a post-difficulty black graphics plateau with DCF4 signal 1 and a capped DMA-ack trace. Its dump shows ordinary guest-CPU queue waits but does not prove deadlock or a final DMA state. These are distinct from the r482 title-stage wait and r479 DirectSound list corruption. Raw stack-address scans were not treated as unwinds.
- Current `kernel_bridge.c` source confirms thread objects start with `STATUS_PENDING`; `bridge_thread_object_for_handle` polls the native handle, keeps pending on `WAIT_TIMEOUT`, and writes the `GetExitCodeThread` value to guest object `+0x120` after `WAIT_OBJECT_0`. `ObReferenceObjectByHandle` writes the object address only when its output pointer is non-null and returns success only when a valid view exists. The write is performed on lookup/poll, not asynchronously at thread exit. Runtime proof that a completed worker status is consumed by the readiness helper remains unverified; do not repeat the old null-output diagnosis.

## Next discriminating work

Before another run, statically follow the r482 `sub_00217130 → sub_00216EA0` dispatch, its queue producer(s), and the guest target stored at `0x0025D1E8` using the exact current generated source and import/runtime maps. Validate any indirect target before seeding or rebuilding it. The next bounded run should preserve the r482 event, queue, gate, callback, DMA/semaphore, and screen-gated input telemetry; keep the DirectSound link watch enabled so it can catch the r479 list writer if Campaign is reached. Do not change guest checks, signals, fences, preload modes, mapping, or rasterizer.

For storage and exact run identities, see [the r482 cleanup manifest](current-cleanup-manifest-r482-20261030.md). The full run manifests retain executable/PDB/MAP/generated-source hashes, trace limits, and saved paths. No trace lines were dropped by the asynchronous relay; callback/gate caps remained at zero. No source changes or build/tests were run.
## Storage and build impact

Fresh full-workspace measurement is recorded in the linked cleanup manifest: **79,516 files; 39,826,663,835 allocated bytes (37.091 GiB); 1,399,680,036,456 logical bytes (1,303.554 GiB); 13 reparse entries skipped**. The r476–r482 run trees account for 78 files, 9,085,252 allocated bytes, and 18,846,421 logical bytes. Actual reclaimed space was **0 bytes**. No artifacts or warm caches were removed/compressed; incremental build efficiency is unchanged. No tests/builds ran.