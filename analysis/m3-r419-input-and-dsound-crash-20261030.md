# r419 input route and DirectSound list crash — 2026-10-30

## Result

r419 validated a screen-gated Steel Battalion input transition from XID delivery through the guest edge cell and predicate into a menu resource lookup. It then exited on an access violation while traversing the DirectSound voice list. The latest blocker in this run is the null list node at guest address `0x00000000`, followed by a guest read at `0xFFFFFFF4`. This is separate from the title DCF4 wait in r271/r274/r416/r418 and from the post-difficulty mode-2 loader plateau in r415. No gameplay/runtime behavior changed; no build ran; no mission frame was reached.

## Run identity and protection

- Run: `m3-input-mode-dispatch-r419-20261030`, PID 180652, started 2026-10-30 06:01:12 CDT. The process exited naturally on its logged access violation by 06:02:54 CDT.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-mode2-readiness-producer-consumer-r409-20261030/Release/your_game_recomp_producer_trace.exe`.
- Exact EXE/PDB/MAP SHA-256: `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A` / `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17` / `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`.
- Generated-source root recorded by the run: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Save root: `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`, reused without copying or hard-linking. The original ISO and save payloads were not intentionally modified.
- The separate r414 dump-analysis process PID 191704 was still running at the end and was left untouched. No game process remains active.
- The run did not request an in-process crash minidump. Its crash log, exact bundle, run manifest, two framebuffer captures, input transcript and bounded traces remain available. Guest stack values in the crash log are stack-address candidates, not a validated guest unwind; the native stack addresses are explicitly raw candidates, not a native unwind.

## Input and visible route

The first `a:800` press reached the title screen's visible “Unable to load Player Record / Press Main Weapon Button to continue” prompt. On the next press, the trace recorded XID report byte 2 changing to `01`, then the identical byte in the guest DMA buffer (`cbp=0x01081763`, bus `0x81081763`), then the guest edge consumer copied the press into `0x004AFC08=1` from source cell `0x004B0160`. The input predicate returned 1 at tick `606697718` under parent `0x000DF7F0`; its release cleared the copied edge cell and returned 0.

At tick `606697734`, a `MENU-RESOURCE` record at caller `0x000E27AA` referenced slot `0x002E4C34`, string VA `0x0026AF04`. Existing string-table analysis identifies that VA as “LIST AS NEW.” This proves the resource lookup, not a successful row selection or handler execution. Run counts were zero `[SB-SNAPSHOT]`, zero `[SB-INPUT-DISPATCH]`, zero `[PILOT-LIST-CB]`, and zero `[PILOT-ROW-POST]`; the actual pilot callback and selected branch remain unverified in r419. The final frame is black. The new-pilot route did not reach `NOW LOADING`.

The screen-gated evidence confirms XID → DMA report → edge consumption → input predicate for this press. It does not capture the guest snapshot or dispatch stage. The r69 known-good pilot-list handler at `sub_000E1820`/callsite `0x000E18D8` remains the validated handler from prior evidence; r419 does not supersede that identification.

## Mode dispatch and separate loader hypothesis

The worker trace recorded one mode request: caller `0x000E0109` requested mode 0 at tick `606614453`; worker entry at `0x00017E40` read mode 0 and selected `preload-mode0`. No mode-2 request, mode-2 worker branch, or loader pass occurred before the DirectSound crash. This run therefore neither confirms nor rejects a mode-global race for the later mode-2 plateau; it does verify that its observed worker took mode 0.

The mode-race hypothesis for r415 is tested only by matching a mode-2 schedule request to the mode read at worker entry. r419 lacks that pair. r415 remains the latest run with a post-difficulty mode-2 plateau and an already-completed worker/status handoff.

## DirectSound fault path

At tick `606700109`, immediately before the crash, the DirectSound commit trace reported argument `0x010810A4`, sentinel `0x010810B4`, null current node, and predecessor `0x8038C098` whose next/prev/owner fields were all zero. The current generated code in `recomp_0016.c` at `sub_0021FEC1` then computes `ebx - 0x14`; with `ebx=0`, that becomes `0xFFFFFFEC`, passed to `sub_0021ED29`. The helper's read at `esi+8` faults at `0xFFFFFFF4`. The log labels the faulting guest site `sub_0021ED29+0x88` and the source location `recomp_0016.c:1717`.

This establishes the proximate list-walk and invalid-address sequence. It does not yet establish who introduced the null link or whether the underlying inconsistency belongs to guest list construction, object lifetime, or DirectSound compatibility semantics. The crash helper's emitted guest stack and native stack entries are not validated unwind frames. Do not patch in a sentinel check, skip the callback, or force list repair from this evidence alone.

The same trace reported 43 raster performance windows; one window measured 2,210 batches / 4,420 triangles, 1,403.80 ms wall and 5,112.68 ms summed worker-active time. This establishes substantial rendering cost in the run, but the crash record independently names the DirectSound list path. No causal connection between raster load and the null link is established. DCF4 producer tracing was not enabled; DCF4 wait was not the observed terminal condition.

## Trace coverage and limitations

- `[XID0]` and `[XID-DMA0]`: five rows each.
- `[SB-EDGE-CONSUME]`: six rows; `[SB-INPUT-PRED]`: ten rows.
- `[MENU-RESOURCE]`: one row; `[PILOT-LIST-CB]`, `[PILOT-ROW-POST]`, `[SB-SNAPSHOT]`, `[SB-INPUT-DISPATCH]`: zero rows.
- `[PRELOAD-WORKER-SCHEDULE]` and `[PRELOAD-WORKER-ROUTE]`: one each, both mode 0.
- `[RASTER-PERF]`: 43 windows. Loader passes and mode-2 readiness callbacks: none.
- No trace cap/drop or 64 MiB storage-budget trigger was reported. No minidump was captured; therefore there is no exact crash-time thread-context unwind from this run.

## Storage and next test

The closed r419 folder retained 12 files, 3,540,011 logical bytes. NTFS lossless compression reduced allocated space from 983,083 to 977,238 bytes, reclaiming **5,845 allocated bytes**; every file's length and SHA-256 matched before and after. Both framebuffer captures are retained. The shared warm build cache was not built, purged or changed.

Next use the existing r415/r418 exact-symbol traces and r419's failure window to isolate the DirectSound list owner and insertion/removal events. Add only a bounded transition trace for the list head, affected node, and operation that leaves `0x8038C098->next` null; enable an in-process crash dump only if a native unwind is needed. Preserve guest fences, XID mapping, AOT execution and rasterizer `1ea1871`. Do not change runtime semantics until the first corrupting list operation is observed. Separately, a later route reaching mode 2 must record requested mode and worker-entry mode together, plus path-completion/loader state. The acceptance target remains the first visually verified mission frame.

**Unverified:** cause of the malformed DirectSound link; valid native/guest unwind at r419 fault; full guest snapshot/dispatch; pilot-list callback selection; mode-2 dispatch race; first post-worker loader dependency; `NOW LOADING`; first mission frame; audio/controller behavior in mission; campaign completion; stable 60 FPS.
