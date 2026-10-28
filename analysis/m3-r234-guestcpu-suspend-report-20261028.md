# r234 guest CPU owner suspension report

**Run:** `m3-thread-suspend-snapshot-r234-20261028`

**Diagnostic PID:** 147720 (the runner's own plateau watchdog stopped this child at 2026-10-28 18:58:30 UTC; no other process was stopped)

**Result:** black post-difficulty frame; no legible `NOW LOADING` screen and no first-mission frame.

**Save root:** `iso/local-analysis/saves-m3-route-file-read-copy-20261023` (shared existing save; left unchanged).

## Exact executable and dump

The dump at `iso/local-analysis/logs/m3-thread-suspend-snapshot-r234-20261028/mode2-plateau-stall.dmp` was analyzed against the run's retained r232 executable/map/PDB bundle at `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r232-thread-suspend-cause/Release/`.

- EXE SHA-256: `0AB8F72660FDAB802981FBC374F3FA382E288961066DC40E4193C7607190F8B5`
- PDB SHA-256: `F41B2AEF0227C4A36DB4631F66F0DBF3F5D3E792243F50C5F388357515576462`
- MAP SHA-256: `017F534DCE85252F60B2381FDF0772E860DE56D2BE8B07461AC9AE71494B5DF5`
- dump: 990,906 bytes; mode-2 plateau signature remained unchanged for 600 seconds.

## Supported cause

Direct read-only process snapshots at 13:48:42, 13:49:46, and 13:52:04 CDT showed the same scheduler state: `free=0`, `granted=0`, `head=740`, `next_ticket=742`, `waiting=2`, `owner_tid=148640`. Owner TID 148640 had Win32 suspend count 1 and wait reason `Suspended`. The exact trace records the main thread TID 144900 successfully calling `NtSuspendThread` on TID 148640 (guest caller `0x001913AD`); there was no matching resume before the plateau. The target is worker #6, created earlier by main TID 144900. Its preload-worker route did not appear before suspension.

This supports the earliest reproducible blocker as **a guest CPU lock retained by a worker that the title/runtime suspends**. Two guest threads (TIDs 144396 and 93316, ticket numbers 740 and 741) remained queued behind that owner. This is a scheduler handoff/suspension interaction before any file dependency is reached, not an identified missing asset.

## Native-stack confidence and limits

Using the matching image and symbols, the owner unwind reaches the runtime thread bridge and a CRT `fprintf` call (`your_game_recomp_producer_trace.exe+0x543C1D`, resolved through the module list to `fprintf+0x3D`); the saved stack also contains the worker-entry and trace-output path. This is consistent with the worker being frozen while still inside a host-side trace call with the guest CPU held. The unwind stops at a non-module address, so no deeper guest call chain is claimed.

The waiter unwinds reach Windows wait frames but terminate at invalid/non-module frame data before a guest call chain can be validated. Their queue tickets and the owner/suspend state are supported by the synchronized live-memory snapshots, not by raw stack-address scans. See `analysis/r234-unwind-144396-20261028.txt`, `analysis/r234-unwind-93316-20261028.txt`, `analysis/r234-owner-unwind-20261028.txt`, and `analysis/r234-dump-addresses-20261028.txt` for the raw tool output and its limitations.

## Other telemetry and separate failures

- 15 mode-2 loader passes entered and returned; the final pass stayed at `range=2..11`, `index=28`, `branch=scan`, `result=0`, pair `0/0`. No file-open/read/preload completion record was emitted, so no loader dependency was reached.
- Relay drops, trace caps, and the 64 MiB run budget counter were all zero. The run emitted 244 DMA ACKs, 77 NV2A ticks, 108 raster samples, and 33 XID records.
- DCF4 was signaled in the sampled terminal interval; this is not the historical title DCF4 wait.
- Raster cost increased substantially after the route began, but the terminal owner was a loader worker, not a raster worker. Rendering backlog remains a separate performance issue and is not the supported terminal cause here.
- r233 separately crashed in the DirectSound voice-list path at guest VA `0xFFFFFFF4`, before this route. Keep that failure separate.
- The r150/r151/r153 exact-bundle unwind review remains authoritative for those older runs. It found an unmatched title DCF4 wait in r151 and lacked owner/free queue-state proof for r153. r234 supplies that missing live scheduler-state correlation for this separate run.

## Change and next verification

No runtime behavior, guest fences, controller mapping, generated game code, or rasterizer was changed. The r232 binary bundle is retained for its dump. The next focused change should make guest-thread suspension cooperative with the guest CPU scheduler, with a regression case that suspends the current owner, confirms queued guest work can proceed, and resumes the suspended thread without altering guest synchronization semantics. Only after that test passes should the same AOT new-pilot route be replayed. Acceptance remains a visually verified first-mission frame; none was reached here.
