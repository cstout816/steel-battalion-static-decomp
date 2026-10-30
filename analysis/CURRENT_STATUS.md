# Steel Battalion AOT project — current status

**Current milestone:** Milestone 3, boot and compatibility. **First visually verified mission frame: 0/1.**

## Progress bars

```text
Decompilation / AOT execution   [##########----------] 50%  AOT route active; mission frame not reached
Boot and campaign entry         [####----------------] 20%  Pilot flow and loading stage are partly reached
Runtime compatibility           [######--------------] 30%  Kernel, input, audio, graphics paths still incomplete
Rendering and performance       [###-----------------] 15%  Raster path measured; no 60 FPS claim
Controller compatibility        [####----------------] 20%  XID path traced; full Steel Battalion controller unverified
Launcher and installation       [##------------------] 10%  Not the current milestone
Debugging and evidence           [############--------] 60%  Bounded traces and exact symbol bundles retained
Storage control                  [##############------] 70%  About 11.5 MB reclaimed by verified compression; no r393 cleanup
Overall project                  [#####---------------] 25%  Early compatibility work; campaign not playable yet
```

Bars are rough engineering estimates, not completion claims. The current milestone acceptance check is one visually verified first mission frame.

## Current findings

- r382 remains the best loader-stage evidence: visible `NOW LOADING`; mode-2 progress stopped at `0x000ABA00`; repeated guest handle `0x3FFF` lookup at `sub_0001D980`, guest address `0x82A9BFF0`, with `0x82A9BFFC == 0xFFFFFFFF`.
- r391 reached Normal difficulty but left a white framebuffer; it did not verify a mission frame.
- r393 reproduced a separate title-stage wait on guest event `0x0021DCF4` (caller `0x00211F3B`). Main thread's validated native unwind ends at the AOT guest-wait wrapper. Three raster workers were at their start-event wait in the dump, while telemetry still reported pending=3. This mismatch and the missing expected DCF4 producer keep the title-stage cause unresolved.
- r392/r393 did not reach the loader route. The pilot handler remains identified; do not reopen discovery of `sub_000E0870`.
- The existing r130 `ObReferenceObjectByHandle` implementation is present; worker pending/completion propagation was verified in r386–r391. Do not repeat that diagnosis.
- No runtime fix, build, or test was performed in r392/r393. Keep AOT execution, guest fences, controller mapping, and rasterizer `1ea1871` unchanged.

## Storage and next action

Current path-summed footprint including 13 separately measured executable reparse entries is **41,527,779,219 allocated bytes (38.67 GiB)**; logical sparse capacity is 1,397,127,080,506 bytes. r392/r393 added a net 4,004,411 allocated bytes versus r391. This turn reclaimed 0 bytes. Previous verified lossless compression saved 11,522,408 allocated bytes. Warm incremental build tree is 6,918,921,034 allocated bytes; retain it for build efficiency.

Next: use exact matching r382/r367 evidence to pursue the first reproducible loader handoff; if a new route run is necessary, keep the trace focused on the `0x3FFF` entry's fourth dword and its writer, with an actually screen-gated new-pilot route. Keep the title DCF4 branch as a separate follow-up. Do not modify behavior until the expected producer or missing handoff is established. See [r392–r393 report](m3-r392-r393-title-dcf4-and-storage-20261030.md), [r386–r391 review](m3-r386-r391-loader-and-storage-review-20261030.md), and [r382 loader report](m3-r382-loading-handle-and-storage-20261030.md).
