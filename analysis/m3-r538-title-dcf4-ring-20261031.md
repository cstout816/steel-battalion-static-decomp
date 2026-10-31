# r538 title-route, ring poll, and DCF4 wait — 2026-10-31

## Run identity

- Run: `iso/local-analysis/logs/m3-r538-ring-and-surface-screen-gated-20261031`
- Diagnostic PID: `51648`; stopped by the configured 120-second DCF4 wait watchdog at `2026-10-31T21:01:25.0432990Z`.
- AOT executable: r513 `your_game_recomp_producer_trace.exe`, SHA-256 `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`.
- Matching PDB SHA-256: `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`; matching MAP SHA-256: `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- Existing save root reused in place: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. No save copy, build, source edit, or cache purge occurred.
- Process is closed. The run used the 64 MiB diagnostic budget and did not reach that cap. No concurrent route was launched.
- Dump SHA-256: `FCDAA4AC9D5FF89E761AE857D1739EAB6AF2A15E89F02FCD368ABEDBEED19A14`.

## Screen-gated route result

The single retained frame is the visible title prompt, “PRESS MAIN WEAPON BUTTON,” SHA-256 `744C1B86F75BE3922320E1C6520480BC44EE1968BB5EE6C225954D951FC404CD`. `frame.bmp` and `frame-history/capture-0001.bmp` were exact duplicates; the history capture is the canonical retained image. The route watcher detected the title prompt and replayed the retained r519 40-step timing. Six guest edge transitions were recorded, including title callback caller `0x000E081F` and later `0x000DF7F0`; `[PILOT-LIST-CB]`, name editor, loader, and mission-frame records were all zero. The run therefore did not verify a transition beyond the title screen.

## DCF4 and graphics synchronization

The last successful `[RASTER-SYNC] stage=wait-after` for guest event `0x0021DCF4` was tick `120305015`, TID `13572`, result `0`. It reported raster `pending=0`, `workers=0`. The same thread entered the next wait at tick `120305031`, caller hint `0x00211F3B`, event handle `0xE78`; no later wait-after was recorded before the watchdog. This caller hint maps to the wait in `sub_00211E10`.

The matching in-process dump was processed with the locally retained minidump stackwalk tool and the r513 image. TID `13572` has a native unwind through `NtWaitForSingleObject`, `WaitForSingleObjectEx`, `xbox_KeWaitForSingleObject`, `bridge_KeWaitForSingleObject`, and `kernel_thunk_dispatch_body`; the host wait handle is `0xE78`, matching the guest wait trace. The native unwind stops at the translated/guest boundary. The displayed guest stack words are raw stack contents, not a validated guest unwind.

The final DCF4 signal was produced by callback `n=520`, argument `5`, selected index 5 / target `0x0021701E`, at tick `120305015`. Callback `n=521` then selected index 1 / target `0x00216EC9` at tick `120305265`; no subsequent `set-DCF4` record was emitted. The callback/outer dispatcher continued through the captured tail, while its work slots were sentinel `1`, aggregate result was zero, and its sequence advanced. At heartbeat tick `120432031`, the event remained clear, raster active/pending were zero, and DMA PUT=GET=`0x52B0`. This supports the final DCF4 producer path ceasing after the last branch-5 signal, with an empty dispatcher queue; it does not establish why that guest work item stopped being produced. It is separate from r519's post-difficulty mode-2 plateau and r533's DirectSound list fault.

The initial ring-poll sample showed queue/cursor progress in `sub_00211E10`. The bounded trace emitted 256 samples at a 16,777,216-iteration stride and reported `seen=4,294,967,296`; the 4,294,967,040 “dropped” count is unsampled loop iterations, not lost log records. The last retained poll sample was tick `120266546`, so the trace does not expose ring state at the final DCF4 wait or the indirect target loaded through the device field corresponding to `0x25D1EC`. Do not interpret this instrumentation-heavy loop count as a performance benchmark.

No `[DS-SURFACE-PIXEL]`, invalid-list commit node, or pilot-list callback was recorded. r538 cannot confirm or reject the r340 DirectSound writer evidence. Raster and DMA progress do not explain this final wait, but the queue-empty state alone is not a supported game-code defect and no synchronization behavior was changed.

## Storage and next reading

The closed run had 4,965,224 path-summed logical bytes (the runner manifest reports 4,956,980, a 1,756-byte discrepancy). Its measured allocated size fell from 3,213,384 to 1,527,240 bytes after lossless NTFS compression, reclaiming **1,686,144 allocated bytes**. Every file's length and SHA-256 was checked unchanged. The exact dump and the two byte-identical title captures were retained; the capture is not a mission frame. No compiler/Cargo cache was touched, so incremental build efficiency is unchanged.

Next, use a bounded reading to capture the indirect target at `0x25D1EC` and the enqueue/dequeue transition that precedes the final branch-5 callback. Retain the exact r513 bundle, AOT execution, original input mapping and guest fences; do not force event signals or bypass guest checks. Reproduce the route through the pilot callback before enabling the DirectSound surface probe. Stop at the first visually verified mission frame.
