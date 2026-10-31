# Steel Battalion AOT — current status (r487, 2026-10-31)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r487 used the authorized new-pilot route and reached `NOW LOADING`, then stopped on a black, unresponsive screen. The first mission has not been reached. No gameplay fix is supported yet.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact r461 AOT bundle retained
Boot and campaign entry         [###############-----] 75%  Campaign → pilot setup → loading; mission frame 0/1
Kernel/runtime compatibility   [########------------] 40%  Loader stall localized to an incomplete pass; cause unknown
Graphics / rendering           [###-----------------] 15%  DMA drained at last telemetry; no mission render verified
Controller compatibility       [##########----------] 50%  Screen-gated XID route reached new-pilot setup
Audio / DSP                     [###-----------------] 15%  Earlier DirectSound list-corruption case remains separate
Debugging and evidence          [###################-] 98%  Bounded trace, lossless BMPs, exact-bundle dump retained
Storage control                 [##################--] 95%  37.103 GiB allocated; 1,303.592 GiB logical; logs compressed
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Latest result

Run `m3-newpilot-loader-ring-immediate-r487-20261031` used the exact r461 AOT executable/PDB/MAP and the existing save root `iso/local-analysis/saves-m3-known-save-copy-20261023`; it did not copy or hard-link saves. Screen-gated inputs traversed Campaign, `LIST AS NEW`, name/date entry, Rookie difficulty, and `NOW LOADING`. The live screenshot showed `NOW LOADING`; the on-disk four-frame history ends at the difficulty screen, followed by the retained black-stall capture.

The last completed loader pass was #36 at guest tick `56387015`. Pass #37 began at `56387031` and stopped after entering the paired-open helper at guest index `0x02`; no matching pass-out was emitted. The preceding pass repeatedly returned result 0. The media fallback for `D:\media\BIN\TEX00.BIN` was opened and fully read (702,976 bytes); a separate cache-path attempt returned a sharing violation. The fallback read and copy completion mean that cache miss is not established as the cause.

Last synchronized GPU/event records show `DMA-ACK` PUT=GET `0x00004018`, DCF4 event state 1, and no worker/pending raster backlog in the latest NV2A tick. DCF4 callbacks continued through #8014. This r487 post-difficulty stall is distinct from the r486 title DCF4 wait, r479 DirectSound list corruption, and the historical r153 loading plateau.

## Current blocker and limits

- The loader pass stops before returning, but traces do not identify a specific file dependency or the guest wait/poll condition. TEX00 cache fallback succeeded; do not patch it based on the miss.
- Current source check: `bridge_thread_object_for_handle` records `STATUS_PENDING` on timeout and the thread exit code after `WAIT_OBJECT_0`; `bridge_ObReferenceObjectByHandle` reports invalid handle when no view exists. Guest helper `0x00191451` reads the valid byte and `+0x120` status. r487 observed the pending `0x103` value consumed by this helper. The completed-state runtime path remains unverified; do not repeat the old r130 null-output diagnosis. Optional `THREAD-OBJECT` counters were 0.
- Exact r461 native unwinds for TIDs 11460 (loader/main guest thread), 35176 (file-copy worker), and 38336 (DCF4/NV2A worker) are partial. TID 11460's last complete native unwind ends at EXE+`0x64937A0` before a non-module stack value. The dump contains no guest CPU-state snapshot. Raw stack-address scans were not treated as unwinds.
- The open-target trace reached its 2,048-attempt cap (one cap marker); the independent file lifecycle/read logs continued. Ring polling was enabled from process start and emitted 59 periodic samples, below its 256-row cap. Relay dropped 0 stdout/stderr lines. Four-frame history retained 4 of 7 captures, evicted 3, dropped 0.
- A C++ exception marker (`0xE06D7363`) appeared on TID 27492 in the DSound watch formatting path. It was not correlated with the loader thread and does not establish the separate DirectSound list corruption cause.
- FPS shown during setup/loading is diagnostic-overlay output, not a performance benchmark. No mission FPS, 1% lows, frame pacing, audio, or gameplay correctness has been verified.

## Next action

Use the exact r487 bundle and dump to resolve the loader worker's guest state and call site around pass #37 / helper index `0x02`, correlating the final successful read/copy, open status, loader progress fields, and synchronized framebuffer/GPU/event timestamps. Add only bounded per-index completion/guest-state capture if existing traces cannot answer it. Reproduce the same new-pilot route, retain failure-window screenshots, and stop at a visually verified first mission frame. Do not force signals, bypass guest checks, seed imports, change preload modes, alter AOT execution/controller mapping/fences, or port another rasterizer.

## Storage snapshot

The final post-compression scan found 79,610 files: **39,839,269,867 allocated bytes (37.103 GiB)** and **1,399,720,906,505 logical bytes (1,303.592 GiB)**; 0 allocation-size failures and 13 reparse entries skipped. Top-level allocated space is `local-tools` 18.727 GiB and `iso` 18.154 GiB. The 1,571 sparse `.img` files account for about 0.763 GiB allocated versus about 1,244.23 GiB logical. The original ISO remains untouched.

Lossless compression of previously uncompressed closed log/screenshot files reduced path-summed allocation by **3,220,011 bytes**. r487 evidence is retained and compressed. The prior full scan was 39,836,630,299 allocated bytes; after adding this diagnostic and its report, the project is net **2,639,568 bytes larger** than that pre-run scan. Build caches were not changed and no build ran.

Read [r487 loading and storage report](m3-r487-newpilot-loading-stall-and-storage-20261031.md) and [r487 cleanup manifest](current-cleanup-manifest-r487-20261031.md). The exact duplicate Ghidra trees and inactive build trees remain untouched; previous cleanup policy had blocked recursive Ghidra removal.
