# Steel Battalion AOT — current status (r461–r469, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r463/r465 reached the post-difficulty loader plateau. r466 and r469 stalled at the title player-record prompt. r468 confirmed guest delivery/edge consumption and reached the visible Campaign menu, then exited in a separate DirectSound list-corruption access violation. No run in r466–r469 reached a visible pilot list or the loader. No gameplay fix or AOT behavior change is established.

Read [r469 title prompt and dump review](m3-r469-title-prompt-stall-and-dump-20261030.md), [r468 input route and DirectSound crash](m3-r468-input-route-and-directsound-crash-20261030.md), [r466 title and loader evidence](m3-r466-title-route-and-loader-evidence-20261030.md), and [r461–r465 loader evidence](m3-r461-r465-loader-and-storage-20261030.md) before repeating earlier theories. The title route, r463/r465 loader branch, r150/r151 DCF4 evidence, r153 queue/DSP snapshots, DirectSound corruption, and measured raster cost remain distinct.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution retained; no emulation substitution
Boot and campaign entry         [#############-------] 65%  r468 reached Campaign menu; r469 input did not reach pilot list
Kernel/runtime compatibility   [########------------] 40%  0x3FFF poll follows a skipped setup branch; producer unknown
Graphics / rendering           [###-----------------] 15%  Title/post-difficulty frames only; no mission frame
Controller compatibility       [#########-----------] 45%  r468/r469 confirm XID delivery and guest edge consumption; pilot handler unverified
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 98%  Exact bundles, bounded logs, and r466/r468 evidence retained
Storage control                 [##################--] 95%  37.067 GiB last full scan; 0 bytes reclaimed; r469 adds 1.51 MiB
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Current loader candidate

In both r463 and r465, AOT function `sub_000450C0` reads `MEM32(0x51E078)==0` at guest `0x451C5`, takes `skip-45287`, and bypasses the call at `0x45287`. In r463, repeated lookups of handle `0x3FFF` return `0x88760828` and the target slot remains invalid. r465 ends in the corresponding `sub_0001D980+0xA2` polling path. This supports the observed path but does not identify the intended global producer or prove why the setup branch should run. Do not seed or bypass it.

r466 did not reach this path. Its UI watchdog snapshot validates a native wait through `xbox_KeWaitForSingleObject+0x29`; deeper guest-looking addresses are raw stack-scan candidates only. DCF4 had repeated set/return cycles through sampled wait #512, while callback detail was disabled; final handoff state is unknown. No DCF4, input, pilot-list, or loader root cause is established by r466.

r468 kept input and menu probes enabled. An A press reached XID byte 2, the guest predicate, and edge-consumer transition 2; four screen-gated A pulses cleared the player-record prompt and brought up the visible Campaign menu. The pilot row updater is already known: `sub_000E1820`, return site `0x000E18D8`, active row branch `0x000E193B`, and `LIST AS NEW` row action `0x83` at `0x000E19CF`. r468 emitted the probe at the return site but always took the zero-input branch `0x000E18DC`; it never resolved the `LIST AS NEW` string or reached row action `0x83`. The report label is instrumentation naming, not evidence that the list was visible. The run exited at `sub_0021ED29+0x88`, reading guest VA `0xFFFFFFF4`, after invalid DirectSound list-node records. Keep this crash separate from the post-difficulty loader; no NOW LOADING state or `0x51E078` write was observed. See the r468 report for exact hashes and counters.

r469 repeated the new-pilot route using the exact r461 EXE/PDB/MAP and the existing empty-save root. Its captured framebuffer remained at `Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.` A press was delivered through XID byte 2 and guest edge transition 2, but pilot/menu/load callbacks were all zero. The r469 dump’s validated host unwind reaches `xbox_KeWaitForSingleObject+0x29` on TID 37176, then stops at a non-module value; it does not expose the guest object/producer. TID 34872 has a faulting PC at `nv2a_ack_thread+0x8C` with repeated first-chance access violations, but no valid unwind or proven causal link. Rendering workers also report 5.4–5.6 aggregate seconds of raster-active time per sampled window; that cost remains a separate candidate, not a proven cause. The title prompt rules out the loader as r469’s blocker. See the r469 report and exact dump/bundle.

## Storage and preserved working set

Last full inventory (r466): 79,220 files, 39,799,862,841 measured allocated bytes (37.067 GiB), and 1,399,613,305,721 logical bytes (1,303.491 GiB). Eight small Cargo fingerprint allocation queries failed; see the current cleanup manifest. A later C: query showed 45,949,026,304 bytes free. r469 evidence uses 1,586,019 allocated bytes (1.51 MiB), measured after process exit. The run made no deletions and reclaimed no existing space. The automatic review rejection of the 534 screenshot deletion candidates remains in effect.

Preserve the warm incremental build and all exact symbols for unresolved dumps, the ISO/assets, unique saves, dirty source checkouts, generated code and license files. The r154 report/logs and exact r149 bundle remain present. No Steel Battalion project directory was found on D:.

## Diagnostic helper regression (r467)

`tools/GuestWriteBreakpoint.exe` was rebuilt from the existing local helper. It now attaches to a reserved but uncommitted page when the initial `ReadProcessMemory` fails with error 299, then reports the first write after the page becomes readable. The regression target reserved a page, committed it after attach, and wrote `0xA55AA55A`; the watcher logged `initial=unreadable error=299`, `ARMED`, and the expected write RIP/value, then exited cleanly. This verifies the helper path only; it is not yet evidence from an XboxRecomp run. The target and run log are outside the canonical build tree. No game behavior or AOT output changed.

## Next action

Review r469’s exception context/disassembly around `nv2a_ack_thread+0x8C` and compare the exact input mapping to the known-good saved-pilot route before another diagnostic. Then require the visible pilot list, `sub_000E1820` active branch `0x000E193B`, label `LIST AS NEW` (`0x0026AF04`), and post-action `0x83` at `0x000E19CF`. For loader work, first reproduce visible `NOW LOADING` with file-completion/thread/event traces active, then correlate `0x51E078` only if it occurs. Use exact matching symbols and saves. Keep AOT, controller mapping, guest fences, and rasterizer baseline `1ea1871`. Make no gameplay change until a producer/dependency condition is established. Stop at the first visually verified mission frame.
