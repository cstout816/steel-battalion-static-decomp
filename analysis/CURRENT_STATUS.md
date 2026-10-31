# Steel Battalion AOT — current status (r461–r471, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r470/r471 transitioned from the title prompt to a black frame and correlate an outstanding guest DCF4 wait with an unsignaled event; its causal producer remains unknown. Neither run reached the pilot list or loader. r463/r465's post-difficulty plateau, r468's DirectSound list-corruption crash, and prior rendering cost remain separate findings. No gameplay fix or AOT behavior change is established.

Read [r470–r471 title DCF4 and storage report](m3-r470-r471-title-dcf4-stall-and-storage-20261030.md), [r469 title prompt and dump review](m3-r469-title-prompt-stall-and-dump-20261030.md), [r468 input route and DirectSound crash](m3-r468-input-route-and-directsound-crash-20261030.md), [r466 title and loader evidence](m3-r466-title-route-and-loader-evidence-20261030.md), and [r461–r465 loader evidence](m3-r461-r465-loader-and-storage-20261030.md) before repeating earlier theories. Keep the title DCF4 wait, post-difficulty loader branch, r150/r151 DCF4 evidence, r153 queue/DSP snapshots, DirectSound corruption, and measured raster cost distinct.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution retained; no emulation substitution
Boot and campaign entry         [#############-------] 65%  r468 reached Campaign menu; r469 input did not reach pilot list
Kernel/runtime compatibility   [########------------] 40%  0x3FFF poll follows a skipped setup branch; producer unknown
Graphics / rendering           [###-----------------] 15%  Title/post-difficulty frames only; no mission frame
Controller compatibility       [#########-----------] 45%  r470/r471 confirm title input delivery; title predicate and pilot handler unverified
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 98%  Exact bundles, bounded logs, and r470/r471 DCF4/dump evidence retained
Storage control                 [##################--] 95%  37.067 GiB last full scan; 0 bytes reclaimed; r469–r471 add about 5.83 MiB
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Current loader candidate

In both r463 and r465, AOT function `sub_000450C0` reads `MEM32(0x51E078)==0` at guest `0x451C5`, takes `skip-45287`, and bypasses the call at `0x45287`. In r463, repeated lookups of handle `0x3FFF` return `0x88760828` and the target slot remains invalid. r465 ends in the corresponding `sub_0001D980+0xA2` polling path. This supports the observed path but does not identify the intended global producer or prove why the setup branch should run. Do not seed or bypass it.

r466 did not reach this path. Its UI watchdog snapshot validates a native wait through `xbox_KeWaitForSingleObject+0x29`; deeper guest-looking addresses are raw stack-scan candidates only. DCF4 had repeated set/return cycles through sampled wait #512, while callback detail was disabled; final handoff state is unknown. No DCF4, input, pilot-list, or loader root cause is established by r466.

r468 kept input and menu probes enabled. An A press reached XID byte 2, the guest predicate, and edge-consumer transition 2; four screen-gated A pulses cleared the player-record prompt and brought up the visible Campaign menu. The pilot row updater is already known: `sub_000E1820`, return site `0x000E18D8`, active row branch `0x000E193B`, and `LIST AS NEW` row action `0x83` at `0x000E19CF`. r468 emitted the probe at the return site but always took the zero-input branch `0x000E18DC`; it never resolved the `LIST AS NEW` string or reached row action `0x83`. The report label is instrumentation naming, not evidence that the list was visible. The run exited at `sub_0021ED29+0x88`, reading guest VA `0xFFFFFFF4`, after invalid DirectSound list-node records. Keep this crash separate from the post-difficulty loader; no NOW LOADING state or `0x51E078` write was observed. See the r468 report for exact hashes and counters.

r469 repeated the new-pilot route using the exact r461 EXE/PDB/MAP and the existing empty-save root. Its captured framebuffer remained at `Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.` A press was delivered through XID byte 2 and guest edge transition 2, but pilot/menu/load callbacks were all zero. The r469 dump’s validated host unwind reaches `xbox_KeWaitForSingleObject+0x29` on TID 37176, then stops at a non-module value; it does not expose the guest object/producer. TID 34872 has a faulting PC at `nv2a_ack_thread+0x8C` with repeated first-chance access violations, but no valid unwind or proven causal link. Rendering workers also report 5.4–5.6 aggregate seconds of raster-active time per sampled window; that cost remains a separate candidate, not a proven cause. The title prompt rules out the loader as r469’s blocker. See the r469 report and exact dump/bundle.

r470/r471 used the exact r461 bundle and same empty-save route. The visible title prompt changed to a black final capture after the Main Weapon input; both traces recorded XID/guest edge activity but zero pilot-list, row-post, menu-resource, and load-state callbacks. r471 emitted 466 DCF4 callback rows (all observed argument/branch pairs are tabulated in the linked report), 464 reason-7 gate rows, 48 DMA publish rows, and synchronized wait/heartbeat evidence. TID 10092's native unwind reaches `xbox_KeWaitForSingleObject+0x29` and stops at handle `0xF9C`, matching the trace's guest object `0x0021DCF4`; the last eight of the 16 retained wait samples had no recorded return. Later heartbeat showed signal 0, raster workers/pending work at zero, and DMA PUT=GET=`0x5A04`. This supports an outstanding title DCF4 wait and makes an active raster backlog less likely at that sample; it does not identify the expected signal producer or prove sole causation. No loader callback or mission frame was reached.

## Storage and preserved working set

Last full inventory (r466): 79,220 files, 39,799,862,841 measured allocated bytes (37.067 GiB), and 1,399,613,305,721 logical bytes (1,303.491 GiB). Eight small Cargo fingerprint allocation queries failed; see the current cleanup manifest. r469–r471 evidence adds 6,110,402 allocated bytes in total (about 5.83 MiB), yielding an approximate working set of 39,805,973,243 bytes (37.072 GiB); this is not a fresh full scan. r470/r471 account for 4,524,383 allocated bytes; the two folders contain 9,907,274 logical bytes because allocation and logical sparse-file length differ. The closed-log compression/replacement action was rejected by automatic file-action review, so no files were removed and reclaimed space is 0. The warm build cache was not touched. The automatic review rejection of the 534 screenshot deletion candidates remains in effect.

Preserve the warm incremental build and all exact symbols for unresolved dumps, the ISO/assets, unique saves, dirty source checkouts, generated code and license files. The r154 report/logs and exact r149 bundle remain present. No Steel Battalion project directory was found on D:.

## Diagnostic helper regression (r467)

`tools/GuestWriteBreakpoint.exe` was rebuilt from the existing local helper. It now attaches to a reserved but uncommitted page when the initial `ReadProcessMemory` fails with error 299, then reports the first write after the page becomes readable. The regression target reserved a page, committed it after attach, and wrote `0xA55AA55A`; the watcher logged `initial=unreadable error=299`, `ARMED`, and the expected write RIP/value, then exited cleanly. This verifies the helper path only; it is not yet evidence from an XboxRecomp run. The target and run log are outside the canonical build tree. No game behavior or AOT output changed.

## Next action

Trace the expected producer for the title DCF4 callback/event from its dispatch targets and data flow; add a narrowly bounded producer marker only if existing r471 records cannot establish execution or absence. Independently recover a reliable screen-gated title input sequence before the pilot handler, and require the visible list plus active branch `0x000E193B`, label `LIST AS NEW` (`0x0026AF04`), and row action `0x83` at `0x000E19CF`. Investigate the post-difficulty `0x3FFF` path only after a new-pilot route reaches visible `NOW LOADING`. Do not force a signal, seed/bypass guest state, change fences, or alter the rasterizer. Stop gameplay acceptance at the first visually verified mission frame.
