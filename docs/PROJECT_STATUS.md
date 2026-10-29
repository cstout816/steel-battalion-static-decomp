# Steel Battalion project status

**Current milestone:** 3 — boot and compatibility.
**Next acceptance point:** first visually verified mission frame.

## Progress

Overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · earliest blocker diagnosis `███░ 3/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

## Current verified finding — r271

The [r271 evidence report](../analysis/m3-r271-title-dcf4-outer-loop-20261029.md) supersedes the r267–r270 current theory. The 300-second watchdog captured an unsignaled guest wait on `0x0021DCF4` at guest callsite `0x00211F3B` (`sub_00211E10`). DCF4 set 127 returned the prior wait; wait 128 had no matching set or return. The main thread's valid native unwind reaches `xbox_KeWaitForSingleObject+0x29`, then stops at non-module `0xD8C`; the guest callsite comes from the explicit wait-entry record.

Callback 453 selected index 5 / target `0x0021701E` and produced DCF4 set 127. Callback 454 selected index 1 / target `0x00216EC9`; its gate returned `out100=0`. No later index-5 callback or DCF4 signal appeared. The final NV2A sample had callbacks/frame/counter/target/fence `454 / 0x143 / 0x57D / 0x573 / 0x579`, line 1, and zero raster batches, workers, or pending batches. This supports an event/producer handoff stall, not an active raster queue backlog. The reason guest state chose index 1 remains unknown.

The test also rejects one narrow theory: `sub_002173A0` was called again after its inner loop recorded `loop=0`. Its 2,048-record first-N trace cap was reached before the final stall, so later outer-loop behavior is not known. Runner output reported no relay drops and only this trace cap. The title prompt was observed after callback progress had already frozen. A later `a:2000` reached XID DMA, but no guest input predicate or edge-consume followed it; the new-pilot route was not tested in r271. No pilot-list callback, `NOW LOADING`, or mission frame was reached.

Earlier r267–r270 evidence remains historical context in [its report](../analysis/m3-title-dcf4-r267-r270-evidence-20261029.md). Keep this title-stage wait distinct from r258's post-difficulty mode-2 plateau, DirectSound list corruption, and expensive rendering windows. The r130 null-output `ObReferenceObjectByHandle` implementation remains unverified for completion semantics because no loader route ran.

## Keep these findings separate

- r258's post-difficulty mode-2 scan plateau at `NOW LOADING` is a later, distinct blocker; it is not the cause of the title DCF4 wait.
- The historical divide-by-zero, DirectSound list corruption, and expensive raster windows are separate investigations.
- The r130 null-output `ObReferenceObjectByHandle` theory is obsolete as a current diagnosis; verify completion semantics only when the loader route is reached.
- Raw dump stack-address scans are candidate addresses, not call chains. r264's valid native unwind stops at the host wait; its guest callsite comes from the instrumented wait-entry record.

## Next test

Preserve failure-window outer-loop evidence with a bounded sample/ring policy and explicit emitted/capped/dropped counts. Trace callback 454's handler return/state into the next producer decision. Apply screen-gated input only while guest predicates are still advancing; do not count an XID pulse without a following guest edge record as route progress. Do not alter guest behavior, force a signal, bypass fences, force preload, or seed valid imports. Keep AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` intact. Stop at the first visually verified mission frame.

## Storage

Latest allocated/logical measurements and protected files are in the [current cleanup manifest](../analysis/current-cleanup-manifest-20261029.md). The post-r271 full scan, adjusted for the four status/report text files written afterward, totals 57,530,266,619 allocated bytes (53.579236 GiB) and 1,381,116,557,578 logical bytes (1,286.265028 GiB) across 75,680 files. Thirteen Rust tool reparse entries were skipped; no other scan errors occurred. The r271 bundle used 169,853,890 allocated bytes and its run folder used 2,422,431 allocated bytes. This pass reclaimed 0 workspace bytes. The run stayed below its 64 MiB budget and had no relay drops, but the outer trace cap was hit. The warm cache was retained; the build completed in about 30 seconds.
