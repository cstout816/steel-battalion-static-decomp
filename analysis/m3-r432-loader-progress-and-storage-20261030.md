# r432 loader plateau and storage — 2026-10-30

## Result

Milestone 3 remains active. r432 reproduced the known new-pilot route with the exact r426 AOT diagnostic, entered the difficulty screen, and visibly reached `NOW LOADING`. It remained there; no first mission frame, audio confirmation, or playable control was verified. The last retained lossless frame is `iso/local-analysis/logs/m3-known-route-loader-forensics-r432-20261030/frame-history/capture-0011.bmp` (SHA-256 `BB7D7A9B7BC93CBFB22CF0E65A7B59E70191831AC01E101315D2C4EE9E8D42F5`). The route proves progression to the loading screen only.

PID 16480 used `your_game_recomp_producer_trace.exe` SHA-256 `6E2494623A1048E35DE2C18C68513719DDEA0AF1532F80EB4E85E8DC5C803C45`, PDB `9B6466B280BB89AC626F75F71340E476B0030B430041D6B9FAC9AE510CE2714D`, and MAP `D678DE9183B8DB733D3E52CB1887EF61DB9A0A44CCDDB9020CEF1724FC9BC40A`. Exact generated inputs were validated against r427's manifest. The canonical generated source, controller mapping, guest fences, AOT path, and rasterizer commit `1ea1871` were unchanged. No build or behavior patch ran.

The run ended at 12:06:23 local when its own 64 MiB per-run evidence guard stopped PID 16480, reserving 16 MiB for final failure evidence. Its stop record reports 57,900,971 logical / 57,906,498 allocated evidence bytes, a saved final frame, zero relay drops, and no app crash. No other game process was stopped. Current process enumeration shows no `your_game_recomp*` process.

## Loader and I/O evidence

The new-pilot route delivered the screen-gated XID input through guest edge handling and reached the normal difficulty choice before `NOW LOADING`. Mode-2 load passes emitted 42 paired enter/return records. The final pass at tick `19560937` was range `2..11`, `last_index=28`, branch `scan`, result 0, output pair `000ABA00/00000000`. The callback trace then reached 410 records through tick `19564437`; mode stayed 2, phase 0, gate `1/1/0`, statuses remained 0, and progress stayed `000ABA00/0`. No callback changed that state.

File lifecycle recorded 2,770 opens and 2,685 closes. The 85-count difference is failed opens, not evidence of 85 live handles. At the tail of the worker's asset sequence, each observed successful open was closed; the last was `D:\Media\Sedata\SEPARAM.SED` at tick `19563218`. Read tracing recorded 8,234 completed reads; the final sampled reads at tick `19564437` completed with `ios=nt=guest=0`, including an 8,784-byte WAV chunk. No outstanding read or first incomplete file dependency is demonstrated. `FILE-OPEN-TARGET` hit its configured cap of 2,048 begin/done pairs on a successful `D:\media\bgm\STRM05.WAV` request. Thus open-target path coverage is capped, though the broader lifecycle/read records continue beyond that point.

There were 53 failed path probes in the complete marker counts, including expected absent save slots and `Z:` cache lookups. These are not evidence that a mission asset is missing: no correlated blocked loader request or expected producer was identified. Keep this separate from the earlier TEX00/cache hypothesis.

## Thread and synchronization evidence

Three relevant native stackwalks were checked against the exact r426 image and PDB using `tools/Walk-ProducerTraceMiniDump.ps1`:

- TID 21320 unwinds through the native wait wrapper to EXE+`0x64A6A91`, mapped to `xbox_RtlEnterCriticalSection+0x1A1`; the walk stops at guest address `0x0023FE18`.
- TID 22460 reaches the same native critical-section entry and the same non-module guest address.
- TID 22124 reaches `guest_cpu_acquire+0x26C`; a following frame resolves to `s_acquire_traces` data and is not accepted as a caller. This is a partial native unwind, not a guest call chain.

The runtime `[CS]` records show TIDs 21320 and 22460 repeatedly contending for guest critical section `0x0023FE18`, with handoffs attributed to guest site `0x0021E7DD` at depths 1/2. The traces do not establish a lock cycle or identify the terminal owner. TID 22124 was started as guest target `0x00017E40` and performed the successful asset reads; its thread-object poll remained pending at the last poll, but that alone does not show it stopped, since it continued file activity afterward. `RECOMP_GUEST_CPU_SNAPSHOT` was enabled, but r432 configured no watchdog snapshot (`WatchdogSnapshotSeconds=0`), so no synchronized owner/waiter snapshot was scheduled. `[SB-SNAPSHOT]` is a separate controller-copy trace in guest routine `sub_00048890`; its absence does not indicate whether guest CPU owner data was captured.

The last synchronized NV2A sample had frame/counter/target/fence `0x16E3/0x27757/0x2774F/0x27755`, DCF4 signaled, and zero raster batches, workers, and pending jobs. DMA PUT/GET was stationary at `0x14388` in its final acknowledgements. This separates r432's mode-2 plateau from a reproduced title DCF4 wait and from a raster backlog; it does not identify the loader's missing handoff.

### Testable hypothesis; no fix yet

The testable candidate remains a guest CPU/critical-section handoff stall after the asset worker's observed I/O: loader state stops advancing while the main and companion guest threads contend at `0x23FE18`, and the asset worker's native stack is in `guest_cpu_acquire`. This is not a confirmed cause. r432 did not schedule a watchdog owner snapshot. Confirm only with a synchronized in-process guest CPU owner/waiter snapshot plus critical-section owner/depth and loader state at the same timestamp. Reject it if the guest CPU owner and lock release progress normally while the loader pair remains unchanged. Do not change locks, seed state, force a signal, bypass guest checks, preload, or alter fences before that test.

## Dumps and evidence retention

- `storage-budget-stall.dmp`: 1,100,966 bytes; SHA-256 `F57250F5CF6AB5BDC85F35F9CD18603EFDB24F7F872C3E5DAE3862962F1EAED0`. This compact failure dump reproduces the relevant partial stacks above.
- `loader-plateau-live-threads-r432.dmp`: 45,621,907 bytes; SHA-256 `A04E584E7F350CB5156D84A12EA8A94968506D0C5F22D81DCEDA37FFCE4064F3`. It was captured live at 12:06:20. Its analyzed thread stacks match the compact dump, but its broader memory data has not been exhausted for guest-owner state; preserve it pending that check.
- The four-frame ring retained captures 0008–0011 losslessly; 11 were saved, 7 evicted, and none dropped. Trace marker counts are in `trace-counts.txt`; effective flags, caps, route transcript, and process data are in `environment.txt` and `run-manifest.json`.

## Storage and build impact

Full allocated-size scan: `C:\Project\sb-inventory-current-r432-20261030.csv` plus `.skipped.txt` (both losslessly NTFS-compressed). It found 78,448 ordinary files using 41,969,512,837 allocated bytes and 1,398,616,220,280 logical bytes. The 13 Rust toolchain reparse executables add 165,381,632 allocated bytes, for **42,134,894,469 bytes / 39.241178 GiB** total path-summed allocation. Sparse logical length is about 1.30 TiB and is not disk usage.

Against r431's exact path-level inventory, r432 added 50,487,122 allocated bytes, removed 248,433, and changed existing files by +137,898, for a **net increase of 50,376,587 bytes**. This is mostly the retained 45.6 MB live dump plus bounded r432 evidence. No files were deleted. NTFS compression of closed r432 text/metadata reclaimed **7,439 allocated bytes** after hash/length validation. Screenshot BMPs were already losslessly NTFS-compressed (the final 921,654-byte BMP uses 16,384 allocated bytes). The failed ZIP duplicate cleanup is still blocked; reclaimable candidate archive size remains 976,265,216 bytes but actual deletion savings are zero.

The current incremental build tree remains 7,354,916,122 allocated bytes; generated AOT source 155,890,474. No compiler/Cargo cache was purged and no build ran, so incremental build efficiency was not changed or remeasured. The 29 files in the existing r368 save root are byte-length/allocation-identical to r431's inventory; no save was copied or hard-linked. The r431 manifest's 110,715,000-byte allocation summary conflicts with both path-level inventories, which total 952,898,778 allocated / 5,422,128,858 logical bytes for that save path; use the path-level figure. Preserve the whole root.

Prior verified duplicate ZIPs remain at `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`; deletion was previously rejected by file-action review, and no alternate path was attempted. Exact candidate/keeper hashes are in `analysis/r421-archive-duplicate-revalidation-20261030.csv`.

## Next action and acceptance

This report is historical; use `analysis/CURRENT_STATUS.md` for the active r433 blocker index. r432 did not schedule a watchdog owner snapshot. The next same-route check should capture a bounded owner/wait snapshot before the 600-second NV2A watchdog, synchronized to lock `0x23FE18`, loader state, worker completion, file completions, and NV2A event state. Reuse r426 and the existing save root. Do not conflate this with historical title DCF4, DirectSound list corruption, or raster cost.



**Deletion attempt on 2026-10-30:** After fresh candidate/keeper SHA-256 validation, Windows rejected removal of the three exact duplicate ZIP candidates as blocked by policy. No candidate was removed; no alternate deletion method was attempted. Reclaimed bytes from archive deletion: 0. The exact paths and keeper hashes remain listed above.
