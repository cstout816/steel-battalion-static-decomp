# Steel Battalion AOT project — current status

**Current milestone:** Milestone 3, boot and compatibility. **First visually verified mission frame: 0/1.** Latest completed diagnostics: r400/r401, 2026-10-30.

## Progress bars

```text
Decompilation / AOT execution   [##########----------] 50%  AOT retained; mission frame not reached
Boot and campaign entry         [#######-------------] 35%  Campaign entry reached in r400, then crashed
Runtime compatibility          [######--------------] 30%  Kernel, audio, graphics remain incomplete
Rendering and performance       [###-----------------] 15%  60 FPS unverified
Controller compatibility       [#####---------------] 25%  XID delivery is traced; full support unverified
Launcher and installation      [##------------------] 10%  Not the current milestone
Debugging and evidence          [##############------] 70%  Matching r399 bundle and r400/r401 evidence retained
Storage control                 [###############-----] 75%  80,239,114 bytes saved by lossless compression this pass
Overall project                 [#####---------------] 25%  Campaign is not yet playable
```

Bars are rough engineering estimates. Acceptance remains one visually verified first mission frame.

## Current findings

- r400 (`m3-apu-guard-loader-r400-20261030`) used the exact r399 diagnostic EXE/PDB/MAP and existing r368 save root. It reached the Campaign menu and crashed on a later input before the pilot list or loader.
- r400 captured invalid DirectSound-list values at guest node `0x8038C098` / predecessor state, followed by a null node and AV at host `0x7FF6B8B04F08`, guest VA `0xFFFFFFF4`. Guest callsite `0x0021FECA` passes `EBX-0x20`; `EBX=0` yields `ESI=0xFFFFFFEC` in `sub_0021ED29+0x88`, source `recomp_0016.c:1717`. This explains the immediate read fault, not the earlier corrupting write.
- Exact-bundle native unwind for r400 TID 177512 stopped after the faulting module frame at a non-module address. Source/callsite and guest registers correlate the failure, but this is not a complete validated guest unwind.
- r401 (`m3-dsound-node-writer-r401-20261030`) armed a cross-thread hardware write watch at guest `0x8038C098` / host `0x8039C098`, but did not reach the same Campaign failure and recorded no write hit. It therefore does not identify or rule out the writer. Its visible screen went black at 0 FPS during the title transition.
- r401’s snapshot TID 186840 has a valid native unwind through `xbox_KeWaitForSingleObject+0x29`; it does not expose the guest object at capture. An earlier DCF4 wait returned 15 ms after a signal. A persistent DCF4 hang was not reproduced, and sparse/first-window traces leave the later terminal wait state unknown.
- The r399 APU bounds guard addresses a separate invalid voice index observed in r398. It did not fire in r400. It is not established as a fix for the current blocker.
- r400/r401 never reached pilot selection or loading. The mode-2 first missing file/dependency, mission frame, audio, full controller behavior, campaign progression, and 60 FPS remain unverified. Keep title DCF4, DirectSound list corruption, rendering cost, and post-difficulty loading plateaus distinct.
- Preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`. No guest checks were bypassed, no signals forced, and no imports seeded.

## Storage and next action

Final scan: 77,780 ordinary files, **41,498,777,888 allocated bytes** plus **165,381,632 allocated bytes** for 13 separately measured executable reparse entries: **41,664,159,520 allocated bytes (38.803 GiB)** total. Logical file lengths total **1,397,464,756,894 bytes** plus the separately measured reparse files; the logical total is not disk use because save images are sparse. Inventory CSV and skipped-path list are stored outside the repository as `sb-inventory-current-r401-final3-20261030.csv` and its `.skipped.txt` companion.

Lossless, hash-verified compression reclaimed **80,239,114 allocated bytes** this pass. No files were deleted. The warm seeded build tree is **6,991,569,062 allocated bytes**; it was preserved. The candidate build took about 6.5 seconds and emitted no compiler warnings. The 22 hash-matched historical cache copies remain because automatic execution review rejected their deletion command as “blocked by policy”; no deletion savings are claimed. Details: [r400/r401 report](m3-r400-r401-first-blocker-followup-20261030.md), [cleanup manifest](current-cleanup-manifest-r401-20261030.md), and [r401 source preservation manifest](r401-source-preservation-manifest.md).

**Next:** analyze existing r150/r151/r153 dumps with their exact executable/symbol bundles before another run. Then reproduce only the r400 Campaign list fault with a write watch and failure-window telemetry, ensuring the screen-gated route actually reaches the same state. Identify the first writer to `0x8038C098`; do not change list semantics without that evidence. Once this blocker is resolved, return to the new-pilot route and trace loader completion dependencies. Stop at the first visually verified mission frame.
