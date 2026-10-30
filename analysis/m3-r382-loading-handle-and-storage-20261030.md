# r382 loading-stage and storage report — 2026-10-30

## Current result

Milestone 3 remains active. The first mission frame is **0/1**. r382 reproducibly reached the visible `NOW LOADING` screen through the new-pilot route, then remained there. It did not reach gameplay. No game behavior, generated code, graphics code, controller mapping, guest fence behavior, or rasterizer code changed.

The post-difficulty mode-2 worker completed, so a still-pending worker is not the current explanation. Loader progress then stopped at `0xABA00`, with the mode-2 output pair back at zero. At the same time, the guest thread repeatedly retried handle `0x3FFF` through `sub_0001D980`; the referenced table entry continued to contain `FFFFFFFF`. Later NV2A samples showed no queued batches, workers, or pending raster jobs. This is a strong immediate stall candidate, but the component expected to clear the table entry has not yet been identified. No fix is justified yet.

## Run identity and protected inputs

- Run: `m3-loader-status-without-open-target-r382-20261030`
- PID `184428`, launched 2026-10-29 22:30:17 CDT and stopped by this diagnostic after its dump was captured at 22:35:21 CDT. Its image path and creation time matched the run manifest before it was stopped. No other game process was stopped.
- A fresh process check found no other XboxRecomp, xemu, or Cxbx game process running. The only paths under the workspace in that query belonged to Codex's own computer-use/runtime tools.
- Reused the existing save directory `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`; no save copy or hard link was made.
- Generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`.
- The run manifest binds generated input and exact matching r367 artifacts. SHA-256: EXE `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`; PDB `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`; MAP `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`.
- Dump: `iso/local-analysis/logs/m3-loader-status-without-open-target-r382-20261030/r382-now-loading-minidump.dmp`, 1,026,376 logical bytes, SHA-256 `BC5DD4CAAC2A63F4A8ADCFFD2EEA545CC06640AE937F989DBE30C14803CE8B07`.

The retained frame-history image `capture-0014.bmp` visibly shows `NOW LOADING` (SHA-256 `1EC44083D89CF04B7FBB4172CF019E62632DB163FA7823DE0FEB2C13059858C9`). The manifest's hashes and logical lengths matched all eight retained history captures. `capture-0015.bmp` is a later white frame, not a mission frame. The 8-image history cap evicted seven captures and recorded one dropped copy due to a source/copy hash mismatch; the final retained image was not dropped.

## Effective tracing and limits

r382 used the 64 MiB run budget and a bounded asynchronous relay with 32,768-line capacity. Eight framebuffer-history slots were retained. The selector-only guest device trace was enabled for handle `0x3FFF`, state-change sampled, capped at 256 records; it emitted 21 records, suppressed repeated records, and dropped none. The asynchronous relay reported no overflow. No global wait trace was enabled because no matching DCF4 wait was reproduced.

The run enabled load-state callback/pair/helper/worker/thread-object traces, file lifecycle/read/path/failure traces, DCF4 callback/gate/producer traces, DMA ACK, PB semaphore, NV2A signature/IRQ, and raster-performance telemetry. File-open-target and file-read-target traces were disabled; their begin/done counts are therefore zero by configuration, not evidence of absent file activity. File-read tracing sampled the first 220 and periodic later completions; it was not a complete read ledger. Thirty-six file misses were recorded, with no required missing asset correlated to the stall.

Trace-counts records: 172 load-state callbacks; 20 loader-pair outputs; 66 helper-entry records and 360 helper branches/returns; 1959 lifecycle opens and 1550 closes; 230 sampled read records; 6912 DCF4 callbacks; 339 DMA-publish records; 310 DMA ACK records; 127 NV2A tick signatures; 88 raster-performance samples. No configured trace cap or async-relay overflow was reported.

## Loader and thread-object evidence

The screen-gated path reached Campaign → `LIST AS NEW` → name `A` → date `01/01/2002` → confirmation → Normal difficulty. At helper index `0x1E`, mode 2 was requested and the loader pair briefly carried candidate pointer values. The final helper sample returned `0xFFFF0001`; the progress field then reached `0xABA00`. Subsequent callbacks kept mode 2, progress `0xABA00/0`, and status zero. The output pair returned to `0/0`.

The mode-2 worker object at guest `0x013BB000` was created pending (`0x103`) and transitioned to completed with status/exit value `1` after 57 polls. A later guest thread object at `0x019204A0` also transitioned from pending to completed with value `1`. This verifies the current `ObReferenceObjectByHandle` completion path for these observed worker threads and rejects the old “worker remains pending” explanation for this run.

The last sampled read record was successful. Lifecycle records show successful opens/closes for `strm08.wav`, save files `user99.sav` and `user02.sav`, and no matched failing read at the stall. This does not rule out every unobserved dependency because read tracing was sampled and file-open-target tracing was disabled.

## Handle retry and synchronized graphics evidence

At guest caller `0x000151F3`, `sub_0020F260` returned the entry address for handle `0x3FFF` (`0x82A9BFF0`) and the publish call returned success. Both records showed entry words `00000000/00000000/00000000/FFFFFFFF` at `0x82A9BFF0`. About half a second later, `sub_0001D980` called `sub_0020EC00` at guest return site `0x0001D992`. That lookup returned `0x88760828` from guest PC `0x0020EC2B` because entry word `+0xC` was still `FFFFFFFF`. In generated AOT source, `sub_0001D980` branches straight back to its lookup when it sees `0x88760828`; the invalid lookup trace then recurred at 65,536-call intervals through at least 327,680 iterations.

This confirms a repeated guest retry path while the loading screen is present. It does not yet prove that this loop alone prevents the loader transition or identify the expected completion writer. Source `sub_0020F1F0` initializes an entry to the sentinel under the corresponding flags; the next trace must identify whether a later guest/runtime producer should clear it and whether that write occurs.

The exact-bundle minidump was reviewed with `Walk-ProducerTraceMiniDump.ps1`. Its validated native unwind reached `recomp_trace_guest_device_entry`, the CRT/UCRT, and then stopped at a non-module address with zero memory-read failures. The separate raw stack-address scan surfaced guest candidates `sub_0020EC00`, `sub_0001D980`, and their callers, but these are **not validated guest unwind frames** and are not reported as such. Runtime guest-PC/caller records and the generated AOT branch are the evidence for the guest retry.

After the loading transition, NV2A signatures remained at frame `0xF8D`, counter `0x1130B`, target `0x112A5`, fence `0x11309`; DCF4 stayed signaled (`1`). Batches, active workers, and pending work were all zero, with the raster pool idle at four workers. DMA PUT/GET stabilized at `0x38014`. Earlier in the route the rasterizer processed heavy batches, so render cost remains a separate performance concern; the later plateau is not an outstanding raster queue. The title DCF4 wait, DirectSound list corruption, and this loader-stage guest retry remain distinct failure families.

## Testable next hypothesis

Hypothesis: after successful create/publish, the guest `0x3FFF` table entry remains at the pending sentinel and the main guest thread spins waiting for a completion producer that does not write it.

- Confirm if a write watch on guest `0x82A9BFFC` (the entry's `+0xC`) identifies the expected completion producer and value transition, and the mode-2 progress remains stuck only when that transition is absent.
- Reject if the field becomes non-sentinel before the stall while the guest loop continues, or if a valid stack/callback shows the loader is blocked on another dependency.
- The run logged a memory offset of `+65536`; the corresponding host watch address is `0x82AABFFC`. `tools/GuestWriteBreakpoint.c` is already available for a hardware data breakpoint. It observes writes without patching guest code or modifying the entry. Record the writer RIP, thread, old/new value, DMA PUT/GET, DCF4 target/state, loader pair/progress, and exact screen frame together.
- Do not seed the table entry, force a signal, bypass guest checks, force preload, alter guest fences, or change the rasterizer until this producer is identified.

## Storage and build impact

Fresh scan `C:\Project\sb-inventory-current-r382-20261030.csv` recorded 77,577 ordinary files: 41,335,077,621 allocated bytes and 1,396,989,869,866 logical bytes. The 13 Rust tool reparse files separately allocate 165,381,632 bytes. After lossless compression of closed logs/dumps, measured allocation decreased by **11,709,326 bytes** across 2,665 files, with all logical lengths unchanged. A separately measured r382 top-level evidence compression reclaimed **826,192 bytes** across 11 files; all 11 logical lengths and SHA-256 hashes matched. Combined measured allocation reclaimed: **12,535,518 bytes**. The eight retained r382 history screenshots match their run-manifest hashes and lengths.

Current working-set allocation after those operations is **41,488,749,927 bytes (38.639 GiB)**; logical size is unchanged from the scan because NTFS compression preserves file contents. This is about **5,743,339 bytes above** the r378 scan after intervening r379–r382 evidence was retained and closed traces compressed. The 64 MiB build tree remains **6,918,921,034 allocated bytes**; canonical generated AOT source remains **155,887,568 bytes**; r368 saves remain **110,706,564 allocated / 5,422,140,106 logical bytes**. No source/build cache was purged, no files were deleted or moved, and no save was copied or hard-linked. The latest measured incremental build remains 9.1 seconds; no build ran in r379–r382.

The Ghidra 12.1.4 and 12.2 archives have different hashes and remain distinct versions. The repeated JDK `lib/modules` files have the same hash but belong to separate retained runtime trees, so neither tree was removed. The large ISO, unique save images, source checkouts, generated source, licenses, and unresolved EXE/PDB/MAP bundles were preserved.

## Next action and acceptance

Run one bounded screen-gated replay with the exact r367 bundle and a hardware write watch on the `0x3FFF` entry's fourth word. Reuse the existing save directory. Capture the first writer or prove no writer occurs while synchronized DMA/DCF4 and loader-state telemetry are sampled. Make the smallest fix only if the missing producer is established, then verify progression beyond `NOW LOADING`. Stop at the first visually verified mission frame and report the campaign, audio, controller, frame-rate, and mission progression work that remains unverified.
