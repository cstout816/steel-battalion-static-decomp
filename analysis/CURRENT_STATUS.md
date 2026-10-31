# Steel Battalion AOT — current status (r510, 2026-10-31)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r508 reached `NOW LOADING` through new-pilot creation, then stopped before gameplay. r510 separately reproduced the earlier title/player-record DCF4 wait. Keep these as distinct blockers. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` remain intact.

## Progress

| Field | Progress | Current evidence |
| --- | --- | --- |
| XBE decompilation / AOT | [##########----------] 50% | Side-by-side r510 trace build; no game logic change. |
| Campaign boot / progression | [################----] 80% | r508 visibly reached `NOW LOADING`; no mission frame. |
| Kernel/runtime compatibility | [#########-----------] 45% | r510 native main-thread unwind reaches `xbox_KeWaitForSingleObject+0x29`; guest caller/cause unresolved. |
| Graphics / rendering | [###-----------------] 15% | Terminal r510 telemetry had no raster queue backlog; gameplay rendering unverified. |
| Controller path | [############--------] 60% | r510 first A correlated XID → guest edge → title route. Later A reached XID without guest consumption. |
| Audio | [###-----------------] 15% | No campaign audio acceptance test. |
| Debugging / evidence | [###################-] 99% | r510 expanded failure tail retained; zero cap hits or relay drops. |
| Storage control | [##############------] 70% | Sparse allocation measured; no caches purged; attempted duplicate deletion rejected, compression reclaimed 0. |
| Whole project | [######--------------] 30% | Full campaign and first mission frame remain unverified. |

## Current blocker

Latest report: [r510 title wait and storage](m3-r510-title-dcf4-tail-and-storage-20261031.md). r510's stopped thread waited on DCF4 guest object `0x0021DCF4` after callback 946 selected target `0x00216EC9`; the last observed signaling callback was #944 through target `0x0021701E`. DCF4 outer tracing retained 473 rows without reaching its 32,768 cap. The final screenshot remained at the player-record error prompt. The callback producer's cessation and guest caller state are unknown.

r508 is the separate loading-stage case: 27/27 mode-2 passes returned, then two threads reached `xbox_DispatchGateEnter+0xE1`; owner unknown. No missing loader dependency is established. The r130 `ObReferenceObjectByHandle` completion path is implemented and not supported as the current cause. Keep historical DirectSound list corruption and expensive title rendering separate.

## Storage and build efficiency

Post-r510 full inventory: **40,101,826,806 allocated bytes (37.348 GiB)** vs **1,402,801,379,020 logical bytes (1.276 TiB)**, 80,057 regular files. Compared with pre-r510, allocated workspace grew **76,100,669 bytes** while retaining the new build and diagnostic evidence. Current components include ISO 7.83 GB allocated, extracted game files 1.80 GB, canonical generated tree 155.9 MB, saves 952.9 MB allocated / 5.42 GB logical, build tree 7.94 GB allocated, and local-analysis logs 3.52 GB allocated.

A 312-file exact-duplicate set (2,379,096,064 allocated bytes) was validated but its deletion was rejected by automatic action review. **No candidate was removed; deletion savings are 0 bytes.** Compression of 40 verified duplicate TEXOBJ caches preserved hashes but reclaimed **0 bytes**. No save, ISO, source, symbol bundle, or warm cache was removed. r510 incremental build completed in about 14 seconds, recompiling only generated `recomp_0015.c` and relinking; no comparable timing baseline was run.

## Next action

First re-evaluate retained r150/r151/r153 dumps with dump-compatible Windows module metadata and their exact executable/symbol bundles; the attempted local rewalk was inconclusive. Then reproduce the authorized new-pilot route with guest CPU state captured in the failure window. Enable loader completion and dispatch-gate owner diagnosis only after visible `NOW LOADING`. No behavior fix until one cause is supported. Stop at the first visually verified mission frame.

Earlier context: [r506–r509 stall discrimination](m3-r506-r509-stall-discrimination-20261031.md), [r505 post-difficulty plateau](m3-r505-postdifficulty-plateau-20261031.md), [r502 mode-2 plateau](m3-r502-mode2-plateau-and-device-entry-20261031.md), and [r487 new-pilot loading stall](m3-r487-newpilot-loading-stall-and-storage-20261031.md). These preserve the distinct loading, title, DirectSound, and renderer findings.


