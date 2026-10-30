# Steel Battalion AOT project — current status

**Current milestone:** 3 — boot and compatibility. **First visually verified mission frame: 0/1.** Latest diagnostic: r406, 2026-10-30.

## Progress

```text
Decompilation / AOT execution   [##########----------] 50%  AOT path retained
Boot and campaign entry         [########------------] 40%  New-pilot route reaches mode-2 loader
Kernel/runtime compatibility   [######--------------] 30%  Loader handoff still unresolved
Graphics / rendering            [###-----------------] 15%  Mission rendering and 60 FPS unverified
Controller compatibility       [#####---------------] 25%  XID route traced; full mapping unverified
Audio / DSP                     [###-----------------] 15%  Complete in-game audio unverified
Debugging and evidence          [###############-----] 75%  r406 bundle, dump and source patch retained
Storage control                 [################----] 80%  4,592,754 bytes recovered this pass
Overall project                 [#####---------------] 26%  Mission frame remains 0/1
```

Bars are rough engineering estimates; first mission frame remains the acceptance point for this milestone.

## Current findings

- r402–r404 are separate title/input or DirectSound cases. r403 reproduces the r400 invalid-list read at guest VA `0xFFFFFFF4`; r404 does not reach Campaign. Neither is the current loader evidence.
- r405 reached Normal and mode-2 loading, then logged a failed 4 MiB heap allocation with about 3.41 MiB remaining. Its caller was not recorded.
- r406 repeated the new-pilot route through Normal with the same r368 save root. It recorded nine mode-2 scans, ending at helper index `0x1E`, decision 5, with progress returned to `0/0`. No missing file or failed sampled read was found; the first stalled dependency remains unknown.
- r406 did not reproduce r405's OOM. The new failure-only `[HEAP-OOM-TRACE]` did not fire. No heap limit was increased.
- Exact r406 unwinds show the main thread and one file worker in `fprintf`; another thread reaches `xbox_KeDelayExecutionThread+0xD8` before an incomplete unwind. This supports synchronous trace-output contention as a diagnostic candidate, not a proven gameplay cause.
- r406's wait trace hit the DCE4 cap, and terminal DMA/PB semaphore state was not enabled. No persistent DCF4 wait was established. Do not combine this with the title DCF4, r153 graphics plateau, or DirectSound list crash.
- Existing thread-object pending/completion semantics remain intact; the r130 null-output diagnosis is not repeated. A prior worker's pending-to-exit-status transition was observed, but the mode-2 readiness consumer is still unidentified.
- Preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`. No guest check, signal, preload mode, or import was forced.

## Storage

Final post-status scan: 77,892 ordinary files, **41,580,673,698 bytes allocated** and **1,397,678,346,351 bytes logical**, plus **165,381,632 allocated bytes** for 13 separately measured Rust/Cargo executable reparse entries. Combined: **41,746,055,330 bytes allocated (38.88 GiB)**. Logical length is not disk use; it includes sparse save images. The scan is `C:\Project\sb-inventory-current-r406-poststatus-20261030.csv` with a `.skipped.txt` list.

Hash-verified lossless compression saved 3,777,586 bytes across r402–r405 and 815,168 bytes for the r406 dump, totaling **4,592,754 bytes**. No files were deleted. Automatic file-action review rejected deletion of 269 duplicate screenshots as “blocked by policy”; that command did not execute. Historical logs and captures are already NTFS-compressed: 9,218 BMPs use 983,547,904 allocated bytes, 6,063 logs use 1,219,333,360 bytes, and 418 dumps use 98,368,002 bytes. Preserve the 12.1 MiB of not-yet-compressed dumps for unresolved evidence; only 8,964 bytes of logs are uncompressed. The 7,064,232,890-byte warm build tree and unique save root remain intact. Details: [r402–r406 report](m3-r402-r406-loader-storage-followup-20261030.md), [cleanup manifest](current-cleanup-manifest-r406-20261030.md), [source patch](preservation-heap-oom-trace-r406.patch).

**Next:** use the r406 bundle and existing save root. Add bounded mode-2 thread-start identity and terminal producer/consumer state; reduce synchronous high-volume output before interpreting another thread stopped in `fprintf`. Change runtime behavior only after one producer/consumer failure is confirmed. Stop at the first visually verified mission frame.
