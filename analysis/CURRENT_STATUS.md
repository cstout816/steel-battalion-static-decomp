# Steel Battalion AOT — current status (r509, 2026-10-31)

**Milestone 3: boot and compatibility. First visually verified first-mission frame: 0/1.** r508 followed the new-pilot route to a visibly confirmed `NOW LOADING` screen, then stalled before gameplay. r509 separately reproduced a title-stage wait before Campaign. No game fix is supported yet. AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` remain intact.

## Progress

| Field | Progress | Current evidence |
| --- | --- | --- |
| XBE decompilation / AOT | [##########----------] 50% | Exact r502 EXE/PDB/MAP reused; no source change or rebuild. |
| Campaign boot / progression | [################----] 80% | New pilot passed profile and Rookie difficulty to `NOW LOADING`; first mission frame remains unverified. |
| Kernel/runtime compatibility | [#########-----------] 45% | r508 has two threads waiting at `xbox_DispatchGateEnter`; owner is unknown. r509 title wait is separate. |
| Graphics / rendering | [###-----------------] 15% | r508 raster work drained and DCF4 was signaled after the loader stopped. No gameplay render verified. |
| Controller path | [############--------] 60% | r509 first A correlated XID→guest edge→title advance; later pulses reached XID but were not consumed. |
| Audio | [###-----------------] 15% | No audible campaign acceptance test. |
| Debugging / evidence | [###################-] 99% | Matched bundles, four live dumps, bounded logs and lossless screenshots retained. |
| Storage control | [###################-] 99% | r508/r509 compression reclaimed 3,454,611 allocated bytes; hashes unchanged. |
| Whole project | [######--------------] 30% | Full campaign and first mission frame remain unverified. |

## Current blocker and investigation index

Read [r506–r509 stall discrimination](m3-r506-r509-stall-discrimination-20261031.md) first. For the prior baseline, see [r505 post-difficulty plateau](m3-r505-postdifficulty-plateau-20261031.md), [r502 loader plateau](m3-r502-mode2-plateau-and-device-entry-20261031.md), and [r487 new-pilot loading stall](m3-r487-newpilot-loading-stall-and-storage-20261031.md). Older DCF4, DirectSound, and import theories remain separate.

r508 completed 27/27 mode-2 loader passes; the last returned result 0, pair `000ABA00/00000000`. The read sampler's last successful row lacks a filename mapping. Native unwinds for TIDs 49060 and 18768 both reached `xbox_DispatchGateEnter+0xE1`; the gate owner and guest caller are not known. Later NV2A telemetry showed no pending raster work and DCF4 signaled. Thus graphics backlog is not supported in the final plateau window, but no loader dependency or synchronization root cause is established.

r509's main TID 33988 unwound through `xbox_KeWaitForSingleObject+0x29`. Nearby DCF4 resets and missing later wait/return records are consistent with the historical title DCF4 wait; the exact outstanding wait object is not captured. The first A advanced to the player-record prompt; later XID A reports had no guest edge. r507's AV was not reproduced in r508.

| Theory / stage | Current disposition | Evidence needed to reopen |
| --- | --- | --- |
| Title DCF4 wait | Reproduced separately in r509 before Campaign; exact outstanding terminal wait is incomplete. | Pair the final wait object with DCF4 producer/set/return records and a matched stack. |
| Post-difficulty dispatch gate | r508 loader TID plus another thread stopped at `xbox_DispatchGateEnter+0xE1`; owner not captured. | Reproduce at loading with gate-owner and guest CPU snapshot evidence. |
| Loader file dependency | Unresolved; r508 read samples lack filename correlation and pass 27 returned result 0. | Correlate the final loader index, file handle/path, read completion, and consuming thread. |
| Raster backlog | Not supported at r508's later stall: NV2A showed zero batches/workers/pending and DCF4 signaled. | Reopen only if synchronized telemetry shows persistent backlog. |
| DirectSound list corruption | Historical separate issue; not causally linked to either current wait. | Reproduce the invalid write and show its effect on the stalled thread. |
| r130 null-output / 0x3FFF retry | Not observed in r508/r509. Current bridge completion behavior remains implemented. | New creator/poll/completion evidence before revisiting. |
| r507 access violation | Not reproduced in r508; r507 had no in-process dump. | Reopen only on a new matching crash with faulting-thread dump. |

## Storage and build efficiency

Full scan: 80,010 regular files; 40,025,676,898 bytes allocated (**37.277 GiB**) and 1,402,623,196,602 logical bytes (**1,306.295 GiB**). Thirteen zero-length Rust symlinks to the same `rustup.exe` were skipped to avoid double-counting their target. See [current cleanup manifest](current-cleanup-manifest-r509-20261031.md) and inventory `C:\Project\sb-inventory-final-r509-20261031.csv`.

The closed r508/r509 trees retain 5,805,025 allocated bytes after compression, down 3,454,611 bytes with all 28 file hashes preserved. The current workspace is up 10,803,711 allocated bytes versus r505 because diagnostic evidence and reports were added. No project files were deleted or moved; save images and build cache remain unchanged. Last measured warm incremental build remains 8.2 seconds from r502.

## Next action

Use the same AOT bundle and a 64 MiB diagnostic cap. Reach the post-difficulty loader through the new-pilot route with dispatch-gate owner tracing, guest CPU snapshots, and capped file lifecycle/read-completion correlation enabled. Enable DCF4 producer tracing when the title DCF4 wait reproduces. Do not change guest checks, signals, fences, preload behavior, controller mapping, or rasterizer without a supported cause. Stop after the first visually verified mission frame.
