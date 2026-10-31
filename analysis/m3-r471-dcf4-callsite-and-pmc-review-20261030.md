# r471 DCF4 callsite and PMC review — 2026-10-30

## Scope and exact run identity

Offline review of completed run `m3-title-dcf4-producer-followup-r471-20261030`, PID `35748`, using its retained `stderr.log`, `wait-trace.log`, dump, generated source directory, and matching AOT bundle. No new game process was launched or stopped, and no runtime or generated code was changed.

The run manifest identifies the AOT executable at `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-open-target-skip2048-r461-20261030/Release/your_game_recomp_producer_trace.exe` (SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`), PDB (SHA-256 `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`), and matching MAP (SHA-256 `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`). Its `recomp_0015.c` is under `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen/` (SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`). The run manifest omits the MAP from its file list; its hash was read directly from the co-located matching bundle.

## Verified wait path

The r471 wait rows report caller hint `0x00211F3B`, guest object `0x0021DCF4`, wait reason 6, mode 1, alertable 0, and no timeout. The exact matching generated source places that return address immediately after the indirect call at `0x00211F39` in `sub_00211E10`; the target is loaded from guest import cell `0x0025D1EC`. The dynamic kernel wait records confirm this import reached `KeWaitForSingleObject`. This is a verified caller correlation, not a guest frame recovered by native stack unwinding.

In `sub_00211E10`, the wait occurs after `sub_00211AB0` returns at least `0x2000`. The routine resets the DCF4 event, submits the `0x40100` / parameter `5` descriptor through `sub_00211C40`, recalculates the threshold, and waits on `device+0x2564` if the threshold is still met. The threshold probe in r471 recorded values such as `0x2510` and `0x24F8`, with DMA ring base/end `0x80004000`/`0x80084000` and guest DMA register pointer `0xFD800000`. The trace does not prove the exact semantic meaning of the returned threshold, so this report classifies the site as a graphics/DMA ring synchronization path without assigning a more specific queue meaning.

The r150/r151 exact-bundle offline review independently reports the same guest path through `sub_00211E10+0xDD2`; r151's event trace records wait #73 after reset with no subsequent index-5 signal before that run stopped. These older runs corroborate the title-stage wait, but do not identify why the signal producer stopped. r153 is a separate post-difficulty graphics plateau: its selected-thread native unwind identifies `DspState::read_memory+0x82` and does not validate a guest wait chain or loader dependency.

## Interrupt-field correlation and limitation

The r471 outer-loop trace reports `owner=0xFD000000` and `flags=0x01000000` after callback #466. Generated code at `0x002173A0` reads `owner+0x100` (`0xFD000100`). The NV2A register definitions identify this offset as `NV_PMC_INTR_0`; bit `0x01000000` is its PCRTC source. The PGRAPH gate is a separate read of `0xFD400100`, where bit `0x00001000` selects the context-switch path. At the later r471 heartbeat, `PGRAPH_INTR=0`, DMA PUT=GET=`0x5A04`, and raster active/pending counts are zero. Thus the later outer-loop rows show the PCRTC branch continuing while the PGRAPH callback path is no longer selected.

This register-name mapping does not prove that a real PCRTC interrupt produced the guest-visible bit. The run’s guest NV2A aperture is plain mapped memory; the host `nv2a_vblank_tick()` updates the separate NV2A model, and the existing source does not show that state being mirrored into guest address `0xFD000100`. The acknowledgment worker also treats PMC status specially by clearing the plain-memory value. No r471 record captures the writer of `0xFD000100`, so the bit’s producer and exact transition timing remain unverified.

## Finding and remaining evidence

- **Verified:** r471’s observed DCF4 caller is the `sub_00211E10` graphics/DMA synchronization routine, not a file or mission-loader wait.
- **Verified:** index-5 callback `0x0021701E` signaled DCF4 through `KeSetEvent` at caller return `0x0021702F` 57 times. Callback #465 was the last observed index-5 signal; #466 selected index 1. The callback trace then stopped at 466 while outer-loop telemetry continued.
- **Supported but not causal:** the later sampled state had no PGRAPH interrupt, no raster backlog, and equal DMA PUT/GET; an unsignaled DCF4 wait remained in the native wrapper. This separates the later wait from rendering backlog but does not explain why the producer stopped or connect that stop to the black frame.
- **Unverified:** exact terminal wait number/callsite at dump time, the writer and lifecycle of guest PMC status at `0xFD000100`, why PGRAPH context-switch dispatch ceased, a reliable route into the pilot list, any `NOW LOADING` dependency, and the first mission frame.

The r471 wait logger retains waits 1–16 and then every 256th entry; return records retain the first eight and then every 64th. Therefore the final wait is not paired with an exact entry/return record. The host unwind for TID `10092` reaches `xbox_KeWaitForSingleObject+0x29` and stops at handle `0xF9C`; it does not unwind into guest AOT frames. Raw guest-stack words are not treated as call frames.

## Next diagnostic boundary

Do not change guest behavior, fences, renderer, or kernel signaling. First establish a reproducible screen-gated input path back to the pilot UI. If a new run is required, retain a bounded recent tail for DCF4 reset/wait/set and callback dispatch, and add narrowly scoped observation of guest writes to `0xFD000100` plus PGRAPH status transitions. Keep `PGRAPH_INTR` producer loss distinct from the PCRTC status bit. Only investigate file-completion dependencies after the visible `NOW LOADING` stage is reached. Gameplay acceptance remains the first visually verified mission frame.
