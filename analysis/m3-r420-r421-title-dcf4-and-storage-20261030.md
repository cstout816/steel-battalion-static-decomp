# r420–r421 title wait and storage — 2026-10-30

## Result

r420 and r421 both stopped before pilot-list dispatch at the title-stage DCF4 path. r421 reproduced an unsignaled wait with producer and gate tracing enabled. Its main guest thread remained in the host wait wrapper for 120 seconds without a DCF4 wait return, and the configured watchdog stopped only diagnostic PID 9324. The immediate blocker is the missing post-reset DCF4 handoff. The trace does not establish why the callback state stopped selecting the signaling branch, so no runtime fix is justified.

The original DirectSound hypothesis was not reproduced: r421 recorded normal list insertions and one unlink, no watched write to `0x8038C098/9C/8C`, no invalid-node walk, and no DirectSound crash. Because the process stalled earlier, this is inconclusive about the prior r419 corruption.

## Run identities and protected inputs

| Run | Identity | Result |
| --- | --- | --- |
| r420 | `m3-dsound-link-writer-r420-20261030`, PID 193364, exact r409 AOT bundle, existing r368 save root | Reached a separate title DCF4 wait before any DirectSound invalid-list fault. The final sampled wait was `0x0021DCF4` at caller hint `0x00211F3B`; event/fence telemetry did not return. Main TID 189552 unwound to `xbox_KeWaitForSingleObject+0x29`, then stopped at synthetic boundary `0xD40`. The run did not enable producer-stage tracing. Its dump SHA-256 is `1EB801C6A244CF6B01F2918347A713EED56E877053F3C4C96F5E253BEF36D043`. |
| r421 | `m3-campaign-branch-and-list-watch-r421-20261030`, PID 9324, 06:16:11–06:19:26 CDT | Three screen-gated `a:800` actions were appended. XID report/DMA records show the presses, but only the first guest edge was consumed before the black frame. No pilot-list callback, menu resource lookup, loader pass, or mission frame occurred. The DCF4 watchdog captured the terminal dump and stopped only PID 9324. |

Both runs used the exact r409 executable/PDB/MAP bundle, generated-source directory `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`, and existing save root `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`. r421 executable/PDB/MAP SHA-256: `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A` / `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17` / `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`.

## r421 synchronized evidence

- Run folder: `iso/local-analysis/logs/m3-campaign-branch-and-list-watch-r421-20261030`.
- The last completed DCF4 wait return was followed by another wait on guest object `0x0021DCF4`, caller hint `0x00211F3B`. The exact last synchronization snapshot is at tick `607568750`, TID `193124`: one raster batch, four workers, three pending, `start=07`, `wake=07`, `complete=00`, `waiting=00`; the main thread never recorded a later wait return. The 120-second watchdog wrote `dcf4-wait-stop.txt` and `dcf4-stall.dmp`.
- The exact-bundle native unwind for TID `193124` is `ntdll.dll+0x161DD4` → `KERNELBASE.dll+0x1BE9F` → executable RVA `0x64A9F89`, mapped to `xbox_KeWaitForSingleObject+0x29`. StackWalk ends at non-module value `0xD8C`; there is no validated guest unwind.
- The most recent callback before the stalled wait selected index 1, target `0x00216EC9` (`[DCF4-CB] n=584`, tick `607568781`, event state 0). The preceding index-5 callback selected `0x0021701E` and signaled DCF4 via caller `0x0021702F` at tick `607568718`. After the subsequent reset/wait, no later index-5 callback, `KeSetEvent`, or wait return was recorded. This verifies the missing handoff symptom, not the state/condition that prevented the producer branch.
- TID `10404` has a partial native unwind through executable RVA `0x64983F2`, which the matching map resolves to `kernel_timer_thread+0xE2`. StackWalk then fails with error 487 at `0x6AC30A0`; that value is not accepted as a caller. The dump alone does not show why later callbacks cease.
- Raster telemetry near the stall showed 2,546 two-triangle batches over a two-second sampling window, 1,638 ms batch-wall time and 5,956 summed worker-ms across four workers; the last synchronized snapshot had three workers pending. This is heavy rendering work, but it does not prove rendering caused the DCF4 branch/handoff failure.
- DirectSound tracing recorded 49 inserts and one unlink (`node=0x019201B8`). The hardware write watch logged no writes to the three watched list-link addresses. No invalid node, DirectSound crash, mode-2 load, or loader dependency reproduced.
- The run emitted 584 DCF4 callback rows, 582 gate rows, 51 DMA-publish rows and 19 raster-performance windows. No configured cap marker or relay drop occurred. Five framebuffer captures were retained; history cap was eight with zero evictions/drops. Final framebuffer remains black. `NOW LOADING`, title-to-Campaign progression, audio, and mission rendering remain unverified.

## Dump and screenshot identities

- `dcf4-stall.dmp` (1,265,297 bytes): SHA-256 `E1003FF2C47FBF0C06C1634EA15BD5DDB539132C1260E01E7711D70C5ED1110A`; captured by the 120-second DCF4 watchdog.
- `black-frame-snapshot.dmp`: SHA-256 `ADDF5BC96FD1AA03C941D1C9F0886D25DA51E7768B3A110A8465C10FEDF33394`.
- Final image `frame-history/capture-0005.bmp`: SHA-256 `7B418FAB6A9FBCF5A8A8ED137A7F0CD989930DAEAC480DD9F43A088F8C3ABC30`.
- The run manifest hashes and exact EXE/PDB/MAP bundle remain beside the logs. r153/r151/r150 dumps were reviewed first with their matching r149 symbols; those older main-thread waits also unwind only to the Xbox wait wrapper and do not supply a guest caller chain.

## Storage and build impact

After both runs had closed, NTFS lossless compression of all r421 run files reduced allocated bytes from 4,406,325 to 2,351,909 (**2,054,416 bytes reclaimed**). Logical length stayed 9,183,090 bytes across 18 files, and all SHA-256 hashes and lengths matched. r420 closed evidence retained 4,499,730 logical bytes and 1,150,966 allocated bytes after compression; its 876,445-byte compression saving was hash-verified. Combined r420/r421 savings: **2,930,861 allocated bytes**. With the previously verified r416–r419 savings of 1,628,069 bytes, cumulative r416–r421 evidence compression is **4,558,930 bytes**.

The last complete workspace scan remains r419: 41,833,223,267 allocated bytes total including 13 separately counted reparse entries; ordinary-file logical length was 1,397,954,975,965 bytes. Adding the measured compressed r420/r421 directories yields a pre-documentation derived estimate of 41,836,726,142 allocated bytes and 1,397,968,658,785 ordinary-file logical bytes. This is not a fresh full-tree rescan. The warm incremental build cache remains 7,136,856,349 allocated bytes; canonical generated source and the exact r409 symbol bundle remain protected. No build or cache purge ran, so incremental-build efficiency was unchanged.

I revalidated three exact duplicate archive files already quarantined under `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`. Each SHA-256 matches a retained project archive, each has a single hardlink path, and no runtime/code/config dependency references the duplicate paths. Their current path-summed allocation is 976,265,216 bytes. The user-authorized deletion attempt was rejected by automatic file-action review as “blocked by policy”; no files were removed. A follow-up hash check confirms the candidate and retained copies remain intact. The validation CSV is `analysis/r421-archive-duplicate-revalidation-20261030.csv`.

No source, generated code, controller mapping, guest fences, rasterizer, ISO, or save data changed. No behavior patch, seeded import, or preload override was made.

## Next evidence step

Inspect the generated guest path around callback dispatcher `0x002171C9`, index selection for `0x00216EC9` versus `0x0021701E`, and the state values consumed at gate `0x002173C7`, using the r421 exact bundle and synchronized final records. Determine why the post-reset state no longer selects index 5. Keep raster backlog as a separate candidate until a completion/branch trace supports causality. Then retry the known-good new-pilot route with bounded captures and preserve the r368 save root. Do not patch, seed imports, or alter fences unless the missing producer state is established. Stop when the first mission frame is visually verified.

## Read-only source and dump follow-up

The generated file `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen/recomp_0015.c` currently hashes to `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`, matching the hash recorded in the r421 run manifest. No generated source was edited.

The callback dispatcher at `0x00216EA0` selects a table target from `arg & 0x1f`. The last index-5 callback was n=583 at tick `607568718`, target `0x0021701E`; it reached the indirect call at `0x00217029` and returned through `0x0021702F`, setting DCF4. The next and final callback was n=584 at tick `607568781`, index 1 / target `0x00216EC9`, with argument `0x01080021`. Its gate input was `PGRAPH_INTR=0x00100000`, `PGRAPH_NSOURCE=1`, `PGRAPH_INTR_EN=0x100`, and context value `0x01080021`; it did not take the index-5 signal path.

At `0x002173A0`, the DCF4 gate is called only while PGRAPH bit `0x1000` is set. After the last signal, sampled outer-handler rows report only `0x01000000` and `called=4`, through tick `607698656`; the context-switch gate is no longer dispatched. The source shows `called=4` is the single-step handler `sub_00216BE0`. That handler is called only when context fields `+0x820` and `+0x824` are both zero; it returns zero in the sampled rows. This rules out the earlier interpretation that those outer rows showed a wait on nonzero handler fields. The wait trace continues to show periodic DCE4 signals after DCF4 callbacks stop, so the timer/dispatch activity did not cease globally.

At the final DCF4 wait snapshot, raster telemetry simultaneously reports batch 10474, 4 workers, 3 pending, start/wake mask `0x07`, completion mask `0`, and no recorded start/wait/join failures. The trace does not identify worker thread IDs or show whether those workers made progress after that instant. A fresh read-only StackWalk over all 37 threads in `dcf4-stall.dmp` found no validated guest worker unwind; the main wait unwind stops after Windows wait frames, and the timer-thread unwind stops at a failed StackWalk boundary. Raw stack address candidates were not treated as callers. Therefore neither the pending raster work nor an individual worker is established as the reason the next PGRAPH context-switch interrupt failed to arrive.

**Current testable hypothesis:** the command stream stops producing the context-switch interrupt that re-enters the gate, while the game thread waits on DCF4. To confirm or reject it, the next bounded diagnostic run needs per-worker thread ID, batch ID, and progress counters (snapshotted at the wait watchdog), alongside DMA PUT/GET and PGRAPH interrupt status. A frozen worker-progress counter and frozen DMA GET would support a raster/command-consumption cause; worker completion or DMA advancement without a new context-switch would reject that cause and direct the next investigation to interrupt generation/dispatch. No behavior change is justified yet. Preserve the r409 bundle, AOT path, guest fences, controller mapping, and rasterizer `1ea1871`.
