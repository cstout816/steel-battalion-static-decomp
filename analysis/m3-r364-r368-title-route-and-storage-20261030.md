# r364–r368 title route and storage follow-up — 2026-10-30

## Current result

Milestone 3 remains active. The first visually verified mission frame is **0/1**. r368 was a bounded attempt to capture the active color-surface state at the previously verified DirectSound-corrupting pixel stores. It reused the exact r367 AOT executable and enabled the existing surface-overlap probe, but remained at the title screen. The two screen-gated inputs reached XID without a new guest edge or menu callback. No DirectSound pixel/list write occurred, so r368 is not a negative test of the Campaign corruption. The title-route stall, pilot-limit screen, DCF4 wait, DirectSound list corruption, and post-difficulty loading remain distinct evidence families.

## r368 run identity and test

- Run: `m3-dsound-surface-r368-20261030`; PID `181856`; stopped by this task after the title screen remained unchanged after two screen-gated A pulses. No other game process was running at launch or stopped.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-tdataroot-isolation-r367-20261029/Release/your_game_recomp_producer_trace.exe`.
- Matched hashes: EXE `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`; PDB `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`; MAP `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`.
- Run source included r367's temporary `Partition1\TDATA\` routing rule. `RECOMP_DSOUND_SURFACE_TRACE=1` was verified in `environment.txt`. No build ran; the existing incremental tree was left warm.
- New isolated save root: `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`. This avoids changing either the original route save or the r366 diagnostic root.

## Evidence and limits

- The lossless framebuffer capture and live desktop capture show the title's “PRESS MAIN WEAPON BUTTON” screen, with the game window reporting 0.0 FPS and 57 draws.
- `a:500` pulses at ticks `570611750` and `570644750` appear in XID/DMA reports (`report[2]=01`, then release). The only `[SB-EDGE-CONSUME]` occurred earlier at tick `570553250`; neither pulse produced a later guest edge, pilot-list callback, or menu transition. The run contains 425 title-route queries and 53 menu-object-gate rows.
- `[DS-SURFACE-PIXEL]` and `[DS-COMMIT-INVALID-NODE]` rows: zero. This only means the run never reached the relevant Campaign state. Trace-limit hits and async relay drops: zero. The runner finalized cleanly after this task stopped the diagnostic child. No crash or native dump was captured.
- The title route did not reach Campaign, pilot selection, `NOW LOADING`, or a mission frame. This run does not establish a title DCF4 wait or identify why the guest did not consume the two later inputs.

## Storage actions

- Closed r368 evidence was losslessly NTFS-compressed. All 12 files retained identical lengths and SHA-256 hashes; allocated use decreased from 2,447,837 to 2,442,927 bytes, recovering **4,910 bytes**.
- The r368 Cache contained 22 files. Twenty-one matched the exact hashes already audited as copies of extracted game-media assets in the r366 cache audit; the unique `COPYCHECK.DAT` (76 bytes) was retained. Lossless NTFS compression preserved the hashes and lengths of all 22, reducing allocated use from 178,019,034 to 109,873,556 bytes and recovering **68,145,478 bytes**. Audit: `analysis/r368-save-cache-compression-20261030.csv`.
- No saves, source trees, generated AOT code, executable/symbol bundle, or warm compiler cache were deleted or rewritten. No hard links were created. The full refreshed allocated/logical scan and net workspace delta are in `analysis/current-cleanup-manifest-20261029.md`.

## Current interpretation and next step

The r150/r151/r153 dumps were already reviewed against their exact r149 EXE/PDB/MAP bundle in `analysis/m3-dump-unwind-review-r150-r153-20261028.md`: r151 is a title DCF4 wait with no subsequent index-5 callback/`KeSetEvent`; r153 is a point sample during a later graphics-progress plateau and does not identify a blocked guest owner or loader dependency. Do not restart those investigations from raw stack scans.

The DirectSound mechanism remains the strongest concrete code-level defect: r340's matched trace attributed stores to `put_pixel+0x4AC` and observed `FF000000` written into guest list words `0x8038C08C`, `0x8038C098`, and `0x8038C09C`. The active color-surface state at those exact stores remains unrecorded. r367 reproduced invalid list nodes without enabling the surface trace; r368 enabled it but never reached Campaign. Next, reproduce the known Campaign transition and retain the bounded surface trace through the exact stores. If the route stalls before Campaign, record the accepted guest input edge and resulting menu state before branching again. Do not change rendering, guest fences, controller mapping, AOT, DCF4 behavior, or rasterizer `1ea1871` without a supported causal trace. Investigate the loader only after `NOW LOADING` is visible, and stop at the first visually verified mission frame.
