# Steel Battalion AOT — current status (r482, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** r482 verified one screen-gated A input end to end through XID delivery, guest edge cell `0x004AFC08`, predicate, callback `0x000E0840`, and visible player-record error overlay. The following black state has a DCF4 callback-queue/wait lead; the missing queue producer is not identified. r479 separately reached a live Campaign menu and crashed consuming an invalid DirectSound node. No fix or build change is established.

Read [r481–r482 diagnostic report](m3-r481-r482-title-dcf4-dsound-followup-20261030.md), [r482 cleanup manifest](current-cleanup-manifest-r482-20261030.md), [r476–r480 report](m3-r476-r480-title-dcf4-dsound-followup-20261030.md), and [r150/r153 exact-bundle unwind review](m3-dump-unwind-review-r150-r153-20261028.md) before repeating old theories.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact AOT path retained; no emulation substitution
Boot and campaign entry         [##############------] 70%  r479 visibly reached Campaign; r482 visible error overlay
Kernel/runtime compatibility   [########------------] 40%  DCF4 callback queue/wait traced; source completion path reviewed
Graphics / rendering           [###-----------------] 15%  Black title-stage output; snapshot has no raster backlog
Controller compatibility       [##########----------] 50%  r482 verified XID → guest edge → title branch → screen change
Audio / DSP                     [###-----------------] 15%  r479 invalid DirectSound list; corrupting write unknown
Debugging and evidence          [###################-] 98%  Exact bundles, r482 callbacks, queue, wait, and minidump retained
Storage control                 [##################--] 95%  37.091 GiB allocated; 1,303.554 GiB logical; savings 0
Overall project                 [######--------------] 30%  First-mission acceptance remains 0/1
```

## Current leads and next action

r482 recorded 325 DCF4 callbacks with no cap. Callback #324 took index 5 (`0x0021701E`) and set DCF4 through return site `0x0021702F`; #325 took index 1 (`0x00216EC9`). Later queue samples were empty while the UI thread snapshot was in the DCF4 wait with signal 0. DMA was drained (`PUT=GET=0x5DEC`), PGRAPH pending was 0, and raster workers had no active/pending work. This points toward an exhausted synchronization queue rather than rendering backlog, but does not identify why it was not replenished.

The next action is static source/data correlation of `sub_00217130`, `sub_00216EA0`, the queue producer, and indirect target slot `0x0025D1E8`; then a bounded run with those traces plus the existing DirectSound link watch. Validate indirect targets before any seeding/rebuild. Keep title DCF4, DirectSound invalid-list crash, and post-difficulty loader plateau distinct. The loader has no evidence in r482 because `NOW LOADING` was not reached. Preserve AOT, guest fences, controller mapping, and rasterizer `1ea1871`.

Current kernel source already implements pending-to-completed thread-object status; guest readiness consumption of a completed status remains unverified. r150/r151/r153 exact-bundle evidence did not prove a shared deadlock or raster backlog.