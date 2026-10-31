# Steel Battalion AOT — current status (r461–r472, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r472 verifies the screen-gated route through visible `LIST AS NEW` and pilot name entry on the current r461 AOT executable. It then reproduces the separate DirectSound invalid-list-node crash at `sub_0021ED29+0x88`; the corrupting writer remains unknown. The run did not reach difficulty or loading. Keep this separate from r463/r465's post-difficulty plateau, r470/r471's title-stage DCF4 wait, and measured rendering cost. No gameplay fix or AOT behavior change is established.

Read [r472 route and DirectSound crash](m3-r472-screen-gated-name-entry-directsound-crash-20261030.md), [r471 DCF4 callsite and PMC review](m3-r471-dcf4-callsite-and-pmc-review-20261030.md), [r470–r471 title DCF4 and storage report](m3-r470-r471-title-dcf4-stall-and-storage-20261030.md), [r469 title prompt and dump review](m3-r469-title-prompt-stall-and-dump-20261030.md), [r468 input route and DirectSound crash](m3-r468-input-route-and-directsound-crash-20261030.md), and [r461–r465 loader evidence](m3-r461-r465-loader-and-storage-20261030.md) before repeating earlier theories. Keep title DCF4, the post-difficulty loader branch, r150/r151 DCF4 evidence, r153 queue/DSP snapshots, DirectSound corruption, and measured raster cost distinct.

The offline r471 callsite review confirms caller hint `0x00211F3B` maps to a DCF4 wait inside guest `sub_00211E10`, after its graphics/DMA threshold and flush path. This is not a loader file wait. The later outer-loop flag at `0xFD000100` maps to PMC PCRTC status bit `0x01000000`; it is separate from PGRAPH context-switch bit `0x1000` at `0xFD400100`. Since the guest aperture is plain memory and no writer of the PMC value was captured, the register name alone does not prove a hardware vblank producer. See [r471 DCF4 callsite and PMC review](m3-r471-dcf4-callsite-and-pmc-review-20261030.md).

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution retained; no emulation substitution
Boot and campaign entry         [##############------] 70%  r472 reached visible LIST AS NEW and name entry
Kernel/runtime compatibility   [########------------] 40%  0x3FFF poll follows a skipped setup branch; producer unknown
Graphics / rendering           [###-----------------] 15%  Title/post-difficulty frames only; no mission frame
Controller compatibility       [##########----------] 50%  r472 correlates XID, guest edge, and pilot row action
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 98%  Exact bundles, bounded logs, and r470/r471 DCF4/dump evidence retained
Storage control                 [##################--] 95%  37.076 GiB allocated; 1,303.517 GiB logical; 0 bytes reclaimed this pass
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## r472 result

r472's AOT executable/PDB/MAP hashes, generated-source hash, environment, trace counts, and dump identity are recorded in the linked report. One run correlates XID byte 2, guest edge cell `0x004AFC08`, pilot updater branch `0x000E193B`, visible `LIST AS NEW` at `0x0026AF04`, and action `0x83` at `0x000E19CF`. The exact-bundle native unwind reaches `sub_0021ED29+0x88` and stops at the synthetic guest boundary after the DirectSound invalid-node read; the earlier corrupting write is still unknown. No loader callback ran.

Fresh whole-workspace scan after r472: 79,375 files; 39,810,510,383 allocated bytes (37.076 GiB); 1,399,640,834,790 logical bytes (1,303.517 GiB); zero query failures. r472 itself is 3,606,351 allocated bytes (3.44 MiB). No files were deleted or moved, so actual reclaimed space is 0 bytes. Build caches and saves are unchanged. See [current r472 cleanup manifest](current-cleanup-manifest-r472-20261030.md).

## Current loader candidate

In both r463 and r465, AOT function `sub_000450C0` reads `MEM32(0x51E078)==0` at guest `0x451C5`, takes `skip-45287`, and bypasses the call at `0x45287`. In r463, repeated lookups of handle `0x3FFF` return `0x88760828` and the target slot remains invalid. r465 ends in the corresponding `sub_0001D980+0xA2` polling path. This supports the observed path but does not identify the intended global producer or prove why the setup branch should run. Do not seed or bypass it.

r466 did not reach this path. Its UI watchdog snapshot validates a native wait through `xbox_KeWaitForSingleObject+0x29`; deeper guest-looking addresses are raw stack-scan candidates only. DCF4 had repeated set/return cycles through sampled wait #512, while callback detail was disabled; final handoff state is unknown. No DCF4, input, pilot-list, or loader root cause is established by r466.

r468 kept input and menu probes enabled. An A press reached XID byte 2, the guest predicate, and edge-consumer transition 2; four screen-gated A pulses cleared the player-record prompt and brought up the visible Campaign menu. The pilot row updater is already known: `sub_000E1820`, return site `0x000E18D8`, active row branch `0x000E193B`, and `LIST AS NEW` row action `0x83` at `0x000E19CF`. r468 emitted the probe at the return site but always took the zero-input branch `0x000E18DC`; it never resolved the `LIST AS NEW` string or reached row action `0x83`. The report label is instrumentation naming, not evidence that the list was visible. The run exited at `sub_0021ED29+0x88`, reading guest VA `0xFFFFFFF4`, after invalid DirectSound list-node records. Keep this crash separate from the post-difficulty loader; no NOW LOADING state or `0x51E078` write was observed. See the r468 report for exact hashes and counters.

r469 repeated the new-pilot route using the exact r461 EXE/PDB/MAP and the existing empty-save root. Its captured framebuffer remained at `Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.` A press was delivered through XID byte 2 and guest edge transition 2, but pilot/menu/load callbacks were all zero. The r469 dump’s validated host unwind reaches `xbox_KeWaitForSingleObject+0x29` on TID 37176, then stops at a non-module value; it does not expose the guest object/producer. TID 34872 has a faulting PC at `nv2a_ack_thread+0x8C` with repeated first-chance access violations, but no valid unwind or proven causal link. Rendering workers also report 5.4–5.6 aggregate seconds of raster-active time per sampled window; that cost remains a separate candidate, not a proven cause. The title prompt rules out the loader as r469’s blocker. See the r469 report and exact dump/bundle.

r470/r471 used the exact r461 bundle and same empty-save route. The visible title prompt changed to a black final capture after the Main Weapon input; both traces recorded XID/guest edge activity but zero pilot-list, row-post, menu-resource, and load-state callbacks. r471 emitted 466 DCF4 callback rows (all argument/branch pairs are in the linked report), 464 reason-7 gate rows, 48 DMA publish rows, and wait/heartbeat evidence. TID 10092's native unwind reaches `xbox_KeWaitForSingleObject+0x29` and stops at handle `0xF9C`, matching guest object `0x0021DCF4`. Correction: wait entries are sampled for waits 1–16 then every 256th; successful returns are sampled for the first eight then every 64th, so absent return rows for waits 9–16 do not mean they remained blocked. Runtime/source correlation confirms the index-5 callback calls `KeSetEvent` at return site `0x0021702F`; 57 sets reached the same host event. Callback #465 selected index 5 and set the event; #466 selected index 1, after which callback activity stopped while the outer loop continued. The later heartbeat showed signal 0, raster workers/pending work at zero, and DMA PUT=GET=`0x5A04`; the live dump still found TID 10092 in the wait wrapper. This supports a later DCF4 wait after the index-5 signal producer ceased, but not why callback dispatch stopped or whether it caused the black frame. No loader callback or mission frame was reached.

## Storage and preserved working set

Fresh read-only full inventory after r471: 79,343 files; 39,806,838,262 allocated bytes (37.073 GiB); 1,399,630,939,024 logical bytes (1,303.508 GiB); 13 reparse points skipped; zero allocation-query failures. C: free space was 45,906,464,768 bytes. r470/r471 account for 4,524,383 allocated bytes and 9,907,274 logical bytes; sparse logical length is distinct from actual allocation. The closed-log compression/replacement action was rejected by automatic file-action review, so no files were removed and reclaimed space is 0. The warm build cache was not touched. The automatic review rejection of the 534 screenshot deletion candidates remains in effect.

Preserve the warm incremental build and all exact symbols for unresolved dumps, the ISO/assets, unique saves, dirty source checkouts, generated code and license files. The r154 report/logs and exact r149 bundle remain present. No Steel Battalion project directory was found on D:.

## Diagnostic helper regression (r467)

`tools/GuestWriteBreakpoint.exe` was rebuilt from the existing local helper. It now attaches to a reserved but uncommitted page when the initial `ReadProcessMemory` fails with error 299, then reports the first write after the page becomes readable. The regression target reserved a page, committed it after attach, and wrote `0xA55AA55A`; the watcher logged `initial=unreadable error=299`, `ARMED`, and the expected write RIP/value, then exited cleanly. This verifies the helper path only; it is not yet evidence from an XboxRecomp run. The target and run log are outside the canonical build tree. No game behavior or AOT output changed.

## Next action

The screen-gated route and pilot row are now correlated. Before another run, analyze the retained exact-bundle r153/r151/r150 evidence and the deeper r158/r463/r465 post-difficulty records to choose one loader handoff hypothesis. Keep the DirectSound invalid-node crash distinct until its writer is found. Do not force signals, seed/bypass guest state, change fences, or alter rasterizer `1ea1871`. Pursue file-completion dependencies only after visible `NOW LOADING`; stop gameplay acceptance at the first visually verified mission frame.
