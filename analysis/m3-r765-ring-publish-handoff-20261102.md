# r765 ring-publish and DCF4 trace — 2026-11-02

## Run identity and route

- Run: `m3-r765-ring-publish-handoff-20261102`; diagnostic PID `108640`, stopped by the configured DCF4 wait watchdog after the event failed to return for 120 seconds.
- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r765-ring-publish-handoff-20261102/Release/your_game_recomp_producer_trace.exe`, SHA-256 `4A528AA005E98FCA87E5FCC82EC5E6C42A1092F578E4D76ED65ADF5CD6F91ACB`. Matching PDB and MAP are beside it; SHA-256 values: PDB `A0D917244280E7822EE239270EBD08B1CAA30324C8DA983E494B72130E700034`, MAP `0325EE4051016EE84029271CDCE7DF4DAFB38152EEDD7DB76728539D01661E0C`.
- Existing save root reused in place: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. No save data was copied or changed; eight blank pilot records remained reversibly moved in the r761 rollback folder.
- Two screen-gated `a:600` inputs were sent. The title briefly showed `Unable to load Player Record`, and a black transition frame was observed after the second input; no more input was sent while the screen was black. The watchdog's final retained `capture-0004.bmp` returned to the title error overlay (SHA-256 `5EF5B174229DCAA7AAF2319763D48C638F7A6785D1941B54A0B72B30E6BBD419`). No Campaign, pilot-list, or mission transition was verified.

## DCF4 evidence

The new bounded source trace in `gen/recomp_0015.c` compiled into r765. It recorded 114 `[SB-DCF4-WAIT]` before-entries and 113 returns. The final wait began on guest event `0x0021DCF4` at guest device `0x0021B790`, TID `105056`, guest site `0x00211F21`, tick `279192390`. Its callback field (`device+0x21AC`) and cursor were both zero; queue was `0x4D9`, queue pointer `0x80003000`, descriptor `0x80082FE0`, and descriptor words were `00041D70/000004CF/00040110/00000000/00040100/00000005`. Signal was zero. No matching return was logged before the watchdog stopped this run.

This run does **not** show a general failure to execute method-5 notifications. The last recorded method-5 pushbuffer packet before the final wait was header `0x80080238`, parameter `0x8008023C`, data `5`; PGRAPH acknowledged it. Guest DCF4 callback argument `5` selected branch `0x0021701E` at tick `279192359`, shortly before the final wait. The preceding trace similarly contains repeated method-5 packet consumption and successful wait returns. At the final sampled heartbeat, tick `279319562`, DCF4 remained unsignaled; raster active/pending were zero, PGRAPH interrupt was zero, and DMA PUT equaled GET at `0x00005FC8` (5,965 raster batches, 2 triangles in the last batch).

There were zero `[SB-RING-PUBLISH]` records: the conditional indirect callback site at `0x00211EEE` was not taken in this capture. This is an observed branch condition, not proof that a callback was required there or that it is the root defect. The trace narrows the failure to the missing next DCF4 publication/consumer handoff after an earlier successful method-5 completion; it does not identify which guest condition should publish it. No fix is supported. Keep this separate from the r763 DirectSound invalid-list crash and the r519 loading plateau.

## Storage and limits

- Run evidence: 6,958,405 logical bytes and 2,567,888 allocated bytes after close. The run stayed under its 64 MiB cap; no trace lines were dropped.
- New candidate EXE/PDB/MAP bundle: 169,970,416 logical bytes, 75,308,752 allocated bytes. Existing incremental caches and prior bundles were left intact. No cleanup or save move occurred in this run.
- Trace limits: ring-publish 1,024; DCF4 wait 2,048; frame-history cap 8. The capture ended before the ring-publish branch became active; the wait trace stopped at the blocked final call.

## Next action

Do not repeat this unchanged route. Correlate the guest state/condition that should generate the next DCF4 publication with the exact final wait and the empty-slot title path. Reproduce the screen transition using the existing save root only after a visible screen accepts the next input. Preserve AOT, guest event semantics, controller mapping, guest fences, and rasterizer `1ea1871`. Mission entry remains unverified.
