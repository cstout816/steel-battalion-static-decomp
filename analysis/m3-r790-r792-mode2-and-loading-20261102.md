# r790–r792 mode-2 route and loading checkpoint (2026-11-02)

Milestone 3 remains active. First mission frame: **0/1**. This report supersedes the r789 mode-2 readiness diagnosis as the current checkpoint; title-stage DCF4, DirectSound corruption, and loading observations remain separate.

## Run identity and route

R790 and R791 produced side-by-side diagnostic AOT bundles with additional readiness instrumentation. R790 traced only index `0x1E`; R791 broadened that marker to match either the index or object. Neither emitted a readiness split marker. The build script's PDB staging path was corrected so the staged PDB is the one generated beside the project, not a stale file under `Release`.

R792 was an environment-only A/B run using the existing R791 executable and its matching symbols. It disabled detailed per-I/O output, retained bounded file lifecycle/copy and STRM02-targeted read traces, and reused the existing save root in place. No build or source change occurred for R792.

- Run: `m3-r792-low-io-detail-route-20261102`; PID `110640`; started `2026-11-02T22:59:28Z`, stopped by us at `2026-11-02T23:17:01Z` after 900+ seconds with no usable UI frame and 0.0 FPS.
- Executable: `r791-mode2-target-object-filter-20261102/Release/your_game_recomp_producer_trace.exe`, SHA-256 `AF575D6C65DC4BEAE15F6070E08DFD275B672BFF3291CA38CCBB2E51B46D7C5B`.
- Matching PDB: SHA-256 `6E8F46B6DDFDC5EAC480F8661F3494D0F68BC4D96ED0C7CA146B6F1CD8040D00`; RSDS GUID `{015F5C37-54BE-456F-977A-38919923BB0F}`, age `25`. The bundle's MAP is retained beside the EXE/PDB.
- Generated sources: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- Save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`, reused without cloning or clearing.
- Route: 37 screen-gated actions from the retained r781 targeted-STRM02 input sequence, followed by the recorded new-pilot flow. The route visibly passed name/date (`01/01/2002`), confirmation, and Normal difficulty, then entered loading. This was not an exact replay of the original r519 executable/environment/40-action bundle, so it does not establish exact r519 route equivalence.
- No `user*.sav` file was created in that root. No save was deleted, moved, cloned, or cleared during R790–R792. The previously moved blank pilot records remain in their rollback folders; all pilot slots are already open.

## Verified loader findings

R792 confirms that resource `0x1E` is no longer the current not-ready condition:

1. At tick `301072656`, loader TID `104868` read VA `0x00351F22=0` (expected `1`); helper decision `5`, mode-2 pass result `0`.
2. At tick `301076125`, worker TID `105432` entered preload asset index `0x1E`. Its open/metadata result was `1`, compare was unequal, and the copy call returned `1` with size `0`.
3. At tick `301076250`, the producer trace recorded `0x00351F22=1`. The next load pass, tick `301076375`, retained mode `2`, returned result `0`, and reported progress pair `0x000ABA00/0` (previous `0/0`). The copy's return value is recorded as observed; its success/failure meaning has not been validated.

After this, the load-state callback repeatedly polled mode `2` without changing progress `0x000ABA00/0` or status `0/0`. At the 900-second snapshot, TID `104868` was still active. Sites `0x00101F70`, `0x00101F90`, `0x00101FF6`, and `0x00102017` alternated synthetic targets `0xFE000004` / `0xFE000000`; existing thunk mapping identifies these as critical-section imports, so their zero return values are not a loader completion result. The awaited final predicate and its producer remain unknown.

The file traces recorded 90 targeted read entries and 90 completions; STRM02 accounted for 41 reads and `Z:\STRM02.WAV` for 8. These successful reads do not identify the outstanding loader dependency. The file-open-path trace hit its 256-row cap. A 10,640-byte `NtReadFile` request with a null guest buffer returned `STATUS_ACCESS_VIOLATION`; this run did not correlate that handle to a file path, so it cannot be attributed to `s00ev01j.bik` or treated as the cause.

## Separate memory, rendering, and synchronization evidence

The same run reported guest heap exhaustion. TID `111268` failed a 4 MiB request with `47,443,968 / 50,855,936` bytes used. TID `104868` later failed 1,323,152 bytes at `50,634,752 / 50,855,936`, then 2 MiB, 1 MiB, 512 KiB, and 256 KiB requests; subsequent failures occurred with `50,770,524` and `50,844,252` bytes used. The allocation traces retain only six raw stack words and do not establish the requesting guest operation or its failure branch. OOM is a strong candidate, not a supported fix or proven cause.

Raster timing remained expensive: late samples used four workers and reported about 4.7–5.9 seconds of aggregate raster-active time per two-second sampling interval. The window showed `FPS: 0.0` and one draw at stop; the final retained framebuffer was blank/white. This establishes substantial raster work but does not show that raster backlog caused the loader state to remain in mode 2.

The wait trace showed DCF4 waits returning, and the 900-second snapshot recorded DCF4 signaled, PGRAPH pending `0`, NV2A USER PUT=GET=`0x5410C`, and PFIFO PUT=GET=`0`. A persistent event or DMA wait was not present at that snapshot. Keep the historical title DCF4 wait separate.

The bounded watchdog guest snapshot had ESP `0x00F7FBB0`; raw stack words include addresses `0x002457B6` and `0x002460AF` in generated `sub_00245430`. This is a stack-address correlation, not a validated guest unwind. A same-run native minidump was captured at `stacks/r792-15min-threads.dmp` (1,031,119 bytes). Walking TID `104868` against the exact R791 image/symbol bundle produced one frame and stopped at a non-module address; there were zero stack-read failures, but no useful complete native or guest unwind.

## Storage and build impact

R792 retained 25 files: **15,032,419 logical bytes / 3,389,726 allocated bytes**, including the bounded 8-frame history and the 1,031,119-byte minidump. The reused R791 EXE/PDB/MAP bundle occupies **72,609,792 allocated bytes**; R792 created no duplicate bundle. No build cache was changed, and no actual project storage was reclaimed in this run. The 64 MiB run budget was not reached; asynchronous relay reported no drops and marker counts were complete. Per-run caps did fire (including file-open, wait, guest-frame, DCE4, and heap-OOM traces), so absence of a capped row is not evidence that an event did not occur.

## Conclusion and next step

The verified new handoff is: the `0x1E` ready byte was set and observed after the first consumer sample, then mode 2 continued polling with progress `0x000ABA00/0`. The remaining blocker is the later mode-2 predicate and producer; memory exhaustion and the null-buffer file read are correlated observations whose causal branches remain unverified. The framebuffer never showed the first mission scene.

Next, inspect the existing R792 guest snapshot and allocation/file-operation source paths to identify the first failed operation and its caller/branch before another route. If another route is needed, use one focused changed instrumentation candidate, the original r519 executable/environment/input reference, and the existing save root. Capture the allocation failure return, file handle/path, and the mode-2 state producer together; preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`. Do not force readiness, bypass guest checks, change synchronization, or seed already-valid imports.

| Area | Progress | Verified state |
| --- | --- | --- |
| Screen-gated pilot route | [##########] 1/1 | R792 passed date, confirmation, Normal, and entered loading. |
| Resource `0x1E` | [##########] 1/1 | Ready byte changed `0→1`; later consumer passed. |
| Later mode-2 completion | [####----------------] 2/5 | Mode `2`, progress `0xABA00/0`, status `0/0`; producer unknown. |
| Heap/OOM branch | [####----------------] 2/5 | Repeated OOMs recorded near heap limit; caller/branch unknown. |
| First mission frame | [--------------------] 0/1 | No mission scene; final frame blank/white. |
| Save slots | [##########] 8/8 | Slots open; no save modified during these runs. |
| Storage/build | [##########] 1/1 | R792 3.39 MB allocated; R791 bundle reused; no build/cache impact. |
