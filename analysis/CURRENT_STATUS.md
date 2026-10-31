# Steel Battalion AOT — current status (r461–r466, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r463/r465 reached the post-difficulty loader plateau. r466 is a separate title-stage run and did not reach the pilot list or loader. No gameplay fix or AOT behavior change is established.

Read [r466 title and loader evidence](m3-r466-title-route-and-loader-evidence-20261030.md) and [r461–r465 loader evidence](m3-r461-r465-loader-and-storage-20261030.md) before repeating earlier theories. The r466 title wait, r463/r465 loader branch, r150/r151 DCF4 evidence, r153 queue/DSP snapshots, DirectSound corruption, and measured raster cost remain distinct.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT execution retained; no emulation substitution
Boot and campaign entry         [#############-------] 65%  r463/r465 reached loader transition; r466 title route stalled
Kernel/runtime compatibility   [########------------] 40%  0x3FFF poll follows a skipped setup branch; producer unknown
Graphics / rendering           [###-----------------] 15%  Title/post-difficulty frames only; no mission frame
Controller compatibility       [########------------] 40%  r466 confirms XID delivery; guest edge/callback unverified
Audio / DSP                     [###-----------------] 15%  Campaign audio remains unverified
Debugging and evidence          [###################-] 98%  Exact bundles, bounded logs, and r466 dump retained
Storage control                 [##################--] 95%  37.067 GiB measured allocated; 0 bytes reclaimed this pass
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Current loader candidate

In both r463 and r465, AOT function `sub_000450C0` reads `MEM32(0x51E078)==0` at guest `0x451C5`, takes `skip-45287`, and bypasses the call at `0x45287`. In r463, repeated lookups of handle `0x3FFF` return `0x88760828` and the target slot remains invalid. r465 ends in the corresponding `sub_0001D980+0xA2` polling path. This supports the observed path but does not identify the intended global producer or prove why the setup branch should run. Do not seed or bypass it.

r466 did not reach this path. Its UI watchdog snapshot validates a native wait through `xbox_KeWaitForSingleObject+0x29`; deeper guest-looking addresses are raw stack-scan candidates only. DCF4 had repeated set/return cycles through sampled wait #512, while callback detail was disabled; final handoff state is unknown. No DCF4, input, pilot-list, or loader root cause is established by r466.

## Storage and preserved working set

Post-r466 inventory: 79,220 files, 39,799,862,841 measured allocated bytes (37.067 GiB), and 1,399,613,305,721 logical bytes (1,303.491 GiB). Eight small Cargo fingerprint allocation queries failed; see the current cleanup manifest. C: free space was 46,022,909,952 bytes at scan time. The r466 evidence directory uses 1,994,082 allocated bytes. No files were deleted or moved; actual reclaimed space: **0 bytes**. The automatic review rejection of the 534 screenshot deletion candidates remains in effect.

Preserve the warm incremental build and all exact symbols for unresolved dumps, the ISO/assets, unique saves, dirty source checkouts, generated code and license files. The r154 report/logs and exact r149 bundle remain present. No Steel Battalion project directory was found on D:.

## Next action

Run a new screen-gated trace only after the exact new-pilot route reaches the pilot list. Have the write-watch helper wait for `0x51E078` memory to commit before arming, then capture the writer RIP and value transition alongside the existing branch and `0x3FFF` lookup. Keep input/edge tracing enabled; retain AOT execution, controller mapping, guest fences, and rasterizer baseline `1ea1871`. Make no gameplay change until the producer condition is established. Stop at the first visually verified mission frame.
