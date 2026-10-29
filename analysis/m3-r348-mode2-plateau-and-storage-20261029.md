# r348: screen-gated AOT route, mode-2 plateau, and storage

Milestone 3 remains active. This run used the existing AOT diagnostic executable and route save; it did not rebuild or change game behavior. It reproduced the visible new-pilot path through Normal difficulty and exercised the mode-2 readiness scan, but did not capture a `NOW LOADING` frame or a mission scene. First mission frame remains **0/1**.

## Test and run identity

The focused test asked whether the known Campaign DirectSound-list overwrite would recur when the surface-overlap trace was enabled. Run `m3-dsound-surface-target-r348-20261029`, PID `178544`, started `2026-10-29T21:42:36Z`. It reused:

- AOT EXE `your_game_recomp_producer_trace.exe`, SHA-256 `727864FBDF2F3623D8BCEF7C9D8EB310E8F28CD4BC75BE340F875FDFCACED998`
- Matching PDB SHA-256 `464EFC33C802737BCBA0C196798CA385B687789C8E421EFBD2E33FD098A20C8F`
- Matching MAP SHA-256 `865A1CF63C77553A73404FE00E6CD35AA6E347119314E5C805101C5201BD7912`
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
- Existing save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`

The run reached the title, the invalid-player-record prompt, Campaign, `LIST AS NEW`, the name editor, date `01/01/2002`, confirmation `YES`, and `HAI SHI DAO 2080 [NORMAL]`. The recorded screen-gated input is in `pad-live.txt`. `trace-counts.txt` records 279 pilot-list callbacks and one row-post, 23 input edges, 66 loader-helper entries, 342 helper branches/returns, 19 mode-2 load-pass pairs, 228 sampled reads, 267 DMA acknowledgements, 80 NV2A ticks, and 115 raster windows. The final saved frame remains the difficulty screen; it is not a loading or mission screenshot.

## Synchronized stall evidence

The last mode-2 pass (`n=19`, guest tick `558930437`, TID `160244`) returned result 0, range 2–11, last index 28, and output pair `0x000ABA00/0`. The pilot UI did not visibly transition after the difficulty input. A later `xbox_HeapAlloc` message reported a 4 MiB request at 47,443,968 of 50,855,936 bytes used. The exact bridge source halves that reserve request until it fits; the emitted message says 2 MiB was granted, and the bridge returns success with the actual smaller size. This is a successful compatibility fallback, not evidence that the allocation failed or caused the stall. It is not a behavior-fix target without a guest-side size/status correlation.

The last observed DCF4 wait #4224 returned successfully with the signal set at tick `558928359`. Because the wait trace was not synchronized beyond its last observed row, this does not rule out a later unrecorded wait. The exact failure-window NV2A signature at stop was callbacks `0`, frame `0x1212`, counter `0x1F749`, target `0x1F743`, fence `0x1F743`; the child-only NV2A progress watchdog stopped this run after 120 seconds without graphics progress. It saved `nv2a-progress-stall.dmp` (SHA-256 `76946EE79C1D7ED32C1ADFBFD1ECCBCAC2EC24F4DC6584503C6D748F2C955E68`) and `frame.bmp` (SHA-256 `2AB0330A2467D0FB8219C4D4535131C458FEB07BAF6252EE7EAD13DC071F9C46`). The 64 MiB evidence budget was not reached; relay drops were zero and the writer drained.

With the matching r342 image and symbols, the valid native unwind for guest main TID `160244` reaches `ntdll.dll → ucrtbase.dll → EXE+0x4E94BCA`, which the matching MAP resolves to translated `sub_00048B80+0x52A`. That generated guest routine is the controller/input predicate. The unwind stops inside AOT code; it does not validate a complete guest call chain or identify another thread's owner. The file `analysis/r348-main-thread-valid-unwind-20261029.txt` contains the unwind. The raw dump scan was interrupted because it was consuming sustained CPU; it is not used as stack evidence.

The focused surface test did **not** reproduce the DirectSound corruption: zero `[DS-SURFACE-PIXEL]` rows and zero watched writes were recorded. This is a valid negative for this run's observed window, not a rejection of r340: the final screen remained the difficulty menu and the run did not reach the mission. The exact r340 crash and historical title DCF4 wait remain separate.

## Result and next test

The earliest current blocker is the post-difficulty transition: the input-driven route and mode-2 scans run, but the framebuffer stays on the difficulty screen, readiness output remains `0x000ABA00/0`, and NV2A progress later stops. No particular file, worker, DCF4 wait, fence, or renderer defect is established. Do not change allocation fallback, guest checks, preload, fences, input, or renderer behavior from this sample.

Next, reproduce this exact route with narrowly bounded allocation caller/result tracing and loader pair/file-completion correlation in the failure window. Include the expected and actual reserve sizes and guest status for the 4 MiB-to-2 MiB fallback, plus the helper's readiness pair producer. Keep the matching r342 bundle and route save, preserve AOT/fence behavior, and stop at the first visually verified mission frame.
