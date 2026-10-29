# r271 title-stage DCF4 and outer-loop trace

**Run:** `m3-title-dcf4-outer-r271-20261029`, diagnostic PID 164380, 2026-10-29 04:59:53–05:05:55 UTC. The run was stopped by its own 300-second NV2A no-progress watchdog. It captured `iso/local-analysis/logs/m3-title-dcf4-outer-r271-20261029/nv2a-progress-stall.dmp` and verified the executable path before stopping. No other game process was stopped.

**Exact AOT bundle:**

- EXE SHA-256 `4B4B4D1992EE121D174F3E5D9C42A60345731B1BD66CB7B775E372F8D7612BE4`
- PDB SHA-256 `24B951DCE31F5CE2DA61BFF70CBFA7D14D865D208EBA0BB7F6768EB8040130FA`
- MAP SHA-256 `D84AD7E0B146605F0F4888041AA302A18C8182FD85AEE4C6935F76FF590F9A10`
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r271-dcf4-outer-loop/Release/`
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0015.c` SHA-256 `02DE12F904FF5909615229F80BEE3DF6F5D43DB149B3CFCC72BC46AFED662201`.

## Result

This run does **not** verify the new-pilot route. The visible title prompt was observed after the guest had already stopped advancing. The single `a:2000` pulse was sent later: XID report byte 2 changed `00→01` at tick 498597140 and returned to `00` at 498599140. The last guest input predicate was at tick 498552234, and its only edge-consume record was earlier at 498529859. No guest input predicate or edge-consume followed the injected XID pulse. So the pulse reached XID DMA, but the trace does not show the guest accepting it. The saved final framebuffer is black; no pilot-list callback, `NOW LOADING`, loader dependency, or first mission frame was reached.

The earliest reproducible blocker in this run is the title-stage DCF4 wait:

- Guest wait 128 entered at tick 498578156 on TID 143608, object `0x0021DCF4`, signal 0, type 0, reason 6, mode 1, caller hint `0x00211F3B` (`sub_00211E10`). It has no matching return. The previous wait 127 returned after DCF4 set 127 at tick 498578125.
- The native unwind for TID 143608 reaches `xbox_KeWaitForSingleObject+0x29` at EXE offset `+0x64A6F69`, then stops at non-module address `0xD8C`. The guest wait callsite comes from the explicit wait-entry record, not a raw stack scan. TID 14264 unwinds to `kernel_timer_thread+0xE2` at EXE offset `+0x6496732`; the saved dump and exact r271 symbols were used. See `analysis/r271-valid-native-unwinds-20261029.txt`.
- DCF4 callback 453 selected index 5 / target `0x0021701E`; its indirect callback at guest cell `0x0025D1E8` had already been validated as the existing `KeSetEvent` synthetic thunk. It produced DCF4 set 127. Callback 454 at tick 498578250 selected index 1 / target `0x00216EC9`. Its gate record has reason 7, `in100=0x00100000`, `in108=1`, `in704=0x100`, `in708=0x01080021`, and returned `out100=0`. No following index-5 callback or DCF4 set 128 appears. This localizes the missing handoff after callback 454; it does not establish why guest state selected index 1 or whether that selection is itself erroneous.
- The main wait is independent of raster backlog in the final samples: callbacks/frame/counter/target/fence stayed `454 / 0x143 / 0x57D / 0x573 / 0x579`; raster batches, active workers and pending batches were zero, all seven workers were waiting, and NV2A line stayed 1. DCF4 remained unsignaled while PMC/PCRTC timer status and DCE4 signaling continued. DMA-ACK samples had GET equal PUT (`0x5E5C`) at ticks 498886546 and 498888562. These records do not prove the rasterizer or all graphics behavior is correct; they reject an active queued raster backlog as the cause of this final wait.

## Hypothesis test and trace limits

The test was whether `sub_002173A0` stopped being called after its `sub_00217130` helper returned zero. The trace rejects that as the immediate cause: outer record 7 shows `loop=0`, and record 8 enters `sub_002173A0` again 16 ms later. The records continue to the 2,048-row cap. The cap was reached before the final stall, so r271 cannot show the later outer-loop state. `DCF4-OUTER-POLL` emitted zero records.

The runner recorded 0 dropped stdout lines, 0 dropped stderr lines, no relay error, no 64-MiB storage-budget event, and complete marker counts. Its only trace limit was `[DCF4-OUTER-CAP] limit=2048`; this is an explicit first-N truncation, and the failure window is missing from that marker. Trace counts include 454 DCF4 callbacks and gates, 6 input predicates, 1 edge-consume, 224 DMA-ACK rows, 73 PB semaphore rows and 120 NV2A timer samples. No file-open/read, loader, load-state or preload marker appeared. Run folder: 4,865,396 logical / 2,422,431 allocated bytes. Candidate EXE/PDB/MAP bundle: 169,853,890 allocated bytes.

The diagnostic-only source change adds bounded outer-loop and poll records. It does not change guest instructions, callbacks, input mapping, guest fences, AOT execution, or rasterizer `1ea1871`. No runtime fix is supported yet. The warm-cache r271 build completed in about 30 seconds; no cache was purged and no comparative benchmark was run.

## Next test

Keep the title DCF4 wait separate from DirectSound list corruption, the earlier post-difficulty mode-2 loading plateau, and expensive rendering windows. Improve the outer-loop trace so the final failure window survives without first-N exhaustion, while retaining explicit emitted/capped/dropped counts. Correlate callback 454's handler return and its state fields with the next producer decision. Do not force a DCF4 signal, bypass guest checks/fences, seed valid imports, force preload mode, or change the rasterizer. Do not claim the input route was tested until a guest predicate/edge record follows the XID pulse. Stop once a first mission frame is visually verified.
