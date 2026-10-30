# r414–r416 loader plateau and title DCF4 evidence — 2026-10-30

## Current result

The mode-2 loader plateau remains the earliest reproducible blocker after the screen-gated new-pilot route. No first mission frame, visible `NOW LOADING` screen, or runtime fix was verified. r415 rules out exhaustive read-trace volume as the sole explanation: it used sampled reads and reached the same mode-2 plateau. It does not identify the missing loader dependency or expected consumer. Keep the separate title-stage DCF4 wait from r416 distinct.

## r414 and r415: same mode-2 plateau, different read-trace load

Both runs used the exact r409 AOT executable, PDB, MAP, and the existing r368 save root; neither rebuilt or changed runtime behavior.

- r414 (`m3-mode2-fullread-followup-r414-20261030`) enabled full read tracing. It reached mode 2 and plateaued after 33 completed load passes. The output pair briefly advanced and returned to `0/0`. The trace stopped at 5,328 read records. TID 191332 unwound through `bridge_create_file_impl+0x200`; TID 192788 through `bridge_trace_output+0x37`; the non-module boundaries prevent a deeper guest-chain claim. Trace contention was plausible, not proven. Its sampled DCF4/DCE4 waits returned signaled.
- r415 (`m3-mode2-sampled-read-sync-followup-r415-20261030`) used sampled read logging and the same exact executable/symbol bundle and saves. The screen-gated route confirmed pilot `A`, DOB `01/01/2002`, and Normal difficulty. The mode-2 worker TID 9592 completed with status 1, the ready byte at `0x00351F22` became 1, and the output pair advanced to `0x000ABA00/0`. The last load pass was #34 at tick `604011281`; no later pass followed. Sampled read completions through sequence 10,000 all had `got == want` and zero I/O, NT, or guest status errors. The same plateau remained, so full-read trace volume alone is rejected as its cause. Sampling still cannot identify an unobserved failing or unconsumed dependency.
- At r415’s terminal mode-2 sample, raster batches/workers/pending were zero and DMA PUT/GET matched. This rejects a continuing raster backlog at that plateau. The DCF4 wait/return counters were sampled independently; their row numbers cannot be paired. Therefore r415 neither confirms nor rejects a terminal DCF4 wait.
- r415 did not show a visually verified `NOW LOADING` label or mission image. Its framebuffer was white. No mission progression is claimed.

## r416: separate title-stage DCF4 wait

Run `m3-mode2-dcf4-producer-followup-r416-20261030`, diagnostic PID 134228, used the same r409 executable/PDB/MAP and r368 save root. It remained on the title screen: pilot-list, menu-dispatch, and load-state callback counts stayed zero. The run was stopped by its own 120-second DCF4 watchdog at `2026-10-30T10:26:50.5533208Z`; no other run was stopped.

Exact bundle hashes: EXE `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A`, PDB `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17`, MAP `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994`. Dump `dcf4-stall.dmp` SHA-256 `B037BEA7B55802B7E64E26CA1E032FB6262FE858759E4AC1E3B74E3E6A3BB411`. The two retained BMPs have the same SHA-256 `ECC67875D38659B4A467463714F6559B7CBAB30C4C9CB23B715FE2A722012DD1`; both are kept at their standard final-frame and history paths.

Evidence for this title run:

- Main TID 188104's exact-bundle StackWalk64 reaches EXE+`0x64A9F89`, MAP `xbox_KeWaitForSingleObject+0x29`, then stops at non-module `0xDF4`. The native wait agrees with the guest DCF4 `wait-before`; it does not validate a deeper guest call chain.
- The last logged main DCF4 `wait-before` is tick `604416062`, with no later `wait-after` before watchdog stop. At tick `604416031`, the preceding wait did return; a subsequent wait began at tick `604416062`.
- Timer/callback TID 188504 reaches EXE+`0x64983F2` = `kernel_timer_thread+0xE2`. The next apparent frame, EXE+`0x6AC30A0`, resolves to `g_dpc_queue` in `.data`, so it is rejected as a return frame. DCF4 callback #512 at tick `604416203` selected index 1 / target `0x00216EC9` with event state 0; no later callback or DCF4 set was recorded. DCE4 signals continued. This supports a title-stage DCF4 handoff stall, but does not explain the loader plateau.
- Raster TIDs 186932, 191724, and 180724 unwind to `raster_worker+0x9F` and then non-module worker IDs `0x1E0`, `0x1E1`, and `0x1E2`. The synchronized snapshots later show `batches=0`, `workers=0`, `pending=0`, pool size 4, while the NV2A frame/counter/target/fence values remain unchanged. This rejects a sustained rendering backlog as the title stall’s explanation. A transient queued batch was present earlier.
- The diagnostic’s frame/callback progress stopped at frame `0x1CC`, counter `0x781`, target `0x777`, fence `0x77D`; the DCF4 register sample was zero. These GPU/event facts are title-only.

## Storage and evidence handling

The r416 run directory initially measured 4,048,853 logical bytes and 1,955,807 allocated bytes. After it closed, all files were NTFS-compressed losslessly; the 13 SHA-256 hashes were unchanged. The dump and other seven previously uncompressed files reduced from 1,005,203 bytes allocated to 215,920 bytes, reclaiming **789,283 allocated bytes**. No files were deleted. The 64 MiB run cap was not reached; relay drops and trace-cap hits were zero. The r409 executable/PDB/MAP bundle, canonical generated source, warm build cache, and unique r368 saves remain retained; no dense save copy or hard link was made.

## Next discriminating test

Stay on the existing r409 AOT/symbol bundle and r368 save root. Reproduce r415’s screen-gated new-pilot route and capture a terminal mode-2 snapshot that correlates the last loader pass/output pair, completed and outstanding file operations by guest path, worker completion, main/loader thread native stacks, and synchronized DCF4/NV2A state. Test the hypothesis that the plateau is a missing post-worker loader-state handoff: confirm it only if a valid loader stack is polling a specific state while its expected producer or dependency completion is absent; reject it if those handoffs completed and another wait is shown. Keep reads sampled/bounded, reserve space for stop-time evidence, and do not patch behavior until that relation is observed. Do not seed imports, bypass checks, force signals/preload, alter fences, or change the rasterizer.
