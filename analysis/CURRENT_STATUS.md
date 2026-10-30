# Steel Battalion AOT — current status (r421, 2026-10-30)

**Milestone 3: boot and compatibility. First visually verified mission frame: 0/1.** The newest r421 run reproduced the title-stage DCF4 wait; it did not reach Campaign or the loader. The immediate blocker is a missing post-reset DCF4 signal. Why the guest callback stops selecting the signaling branch is still unknown. No runtime fix is supported.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  Exact-bundle AOT diagnosis retained
Boot and campaign entry         [########------------] 40%  Prior mode-2 plateau remains separate
Kernel/runtime compatibility   [######--------------] 30%  DCF4 producer handoff unresolved
Graphics / rendering            [###-----------------] 15%  Heavy raster cost; mission frame unverified
Controller compatibility       [#####---------------] 25%  Screen-gated XID path retained
Audio / DSP                     [###-----------------] 15%  Mission audio unverified
Debugging and evidence          [##################--] 90%  r150–r153 and r271–r421 evidence retained
Storage control                 [##################--] 92%  r421 evidence compressed and hash-verified
Overall project                 [#####---------------] 26%  Mission acceptance remains 0/1
```

## Latest verified findings

- r421 used the exact r409 EXE/PDB/MAP and existing r368 saves. Three live A presses reached XID/DMA, but only the first guest edge was consumed before the framebuffer went black. There were no pilot-list callback, menu resource, loader pass, or mission frame records.
- Main TID 193124 unwound through native wait APIs to `xbox_KeWaitForSingleObject+0x29`; StackWalk stopped at synthetic boundary `0xD8C`. At tick `607568750`, it waited on `0x0021DCF4` from caller hint `0x00211F3B`. The wait did not return for 120 seconds; the watchdog captured `dcf4-stall.dmp` and stopped only diagnostic PID 9324.
- The last post-reset callback selected index 1 / target `0x00216EC9`. No later index-5 / `0x0021701E` callback, `KeSetEvent` at `0x0021702F`, or wait return was recorded. This confirms the missing handoff symptom, not why the callback state ceased selecting the signaling branch.
- Raster telemetry showed 2,546 two-triangle batches per two-second sample, 1,638 ms batch wall time, and 5,956 summed worker-ms across four threads. The final wait snapshot had three workers pending. High render cost is measured, but it has not been shown to cause the missing DCF4 producer branch.
- The DirectSound watch did not reproduce r419's corrupt list: r421 recorded 49 inserts and one unlink, but no watched link writes, invalid node, or DirectSound crash. Because it stalled earlier, the prior corruption remains unresolved.
- r415 remains the latest post-difficulty mode-2 plateau. r421 did not reach that stage. Keep title DCF4, rendering cost, DirectSound corruption, and loader readiness separate.
- No code, generated source, import seed, controller mapping, guest fence, or rasterizer change was made. No build ran.

## Storage

r420 and r421 retained 13,682,820 logical bytes in 31 evidence files; after lossless NTFS compression they occupy 3,502,875 allocated bytes, reclaiming **2,930,861 bytes** with every hash and length unchanged. Combined r416–r421 closed-evidence compression reclaimed **4,558,930 allocated bytes**. Last full-tree inventory was r419 at 41,833,223,267 allocated bytes including 13 reparse entries, and 1,397,954,975,965 ordinary-file logical bytes. Adding the measured r420/r421 directories gives a derived current estimate of 41,836,726,142 allocated bytes; refresh with a full scan before broader cleanup.

The warm incremental build cache remains 7,136,856,349 allocated bytes; no cache purge or build occurred. Exact r409 symbols, canonical generated source, original ISO and unique saves remain protected. Three ZIP copies are confirmed exact duplicates of retained archives, totaling 976,265,216 allocated bytes. Their deletion was rejected by automatic file-action review as “blocked by policy”; all copies remain in place and their hashes were rechecked.

Detailed evidence: [r420–r421 title wait](m3-r420-r421-title-dcf4-and-storage-20261030.md). Storage record: [r421 cleanup manifest](current-cleanup-manifest-r421-20261030.md). Prior distinct findings: [r419 DirectSound/input](m3-r419-input-and-dsound-crash-20261030.md), [r417–r418 title wait](m3-r417-r418-title-wait-and-storage-20261030.md), [r414–r416 loading/DCF4](m3-r414-r416-loading-and-title-wait-20261030.md).

## Next step

The exact generated-source hash matches the r421 manifest. r421's last index-5 DCF4 signal (callback n=583) is followed by index 1 (n=584); sampled PGRAPH outer-handler rows then have only single-step bit `0x01000000`, so the context-switch gate is no longer called. DCE4 signals continue, while the DCF4 wait remains blocked. The final raster snapshot shows batch 10474 with three pending workers, but no worker identity/progress series; existing dump unwinds do not validate worker guest stacks. Raster backlog remains a candidate, not a proven cause. Next add bounded per-worker batch/progress counters and capture DMA GET/PUT plus PGRAPH status at the DCF4 watchdog, then rerun the same known-good route. Preserve the r409 bundle, AOT, guest fences, controller mapping, rasterizer `1ea1871`, and r368 saves. Do not change behavior until the trace supports one cause. Stop at the first visually verified mission frame.
