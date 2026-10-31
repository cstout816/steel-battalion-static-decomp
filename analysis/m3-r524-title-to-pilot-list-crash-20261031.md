# r524 title-to-pilot-list route and crash — 2026-10-31

## Run identity and safety

- Run: `m3-r524-r519-replay-open-paths-20261031`; diagnostic PID `15544`.
- Started 2026-10-31 19:16:07 UTC and stopped by the runner's fatal-exception guard at 19:20:25 UTC. It ran at `BelowNormal` priority. The guard verified and stopped only PID 15544. Call of Duty HQ PID `52452` remained open and was not interrupted.
- Exact AOT bundle: r513 `your_game_recomp_producer_trace.exe`, SHA-256 `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`; PDB `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`; MAP `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- Reused `iso/local-analysis/saves-m3-route-file-read-copy-20261023` in place. No save clone or build was made. The run ended before new-pilot name entry or pilot creation.
- Run budget was 64 MiB; it did not trigger. Async trace relay dropped 0 lines. Final run directory measured **6,398,137 logical bytes and 2,154,735 allocated bytes (2.05 MiB)**. This is retained diagnostic evidence, not reclaimed space.

## Verified route and crash

Screen captures verified the title prompt, Campaign menu, and pilot list with `LIST AS NEW` selected. Seven screen-gated live actions were sent: five `a:600`, then `right:200`, then `a:600`. The last press produced a positive guest predicate at caller `0x000C8064` under parent `0x000E07EC`, then the active pilot-list callback at `0x000E18D8` took branch `0x000E193B`; `[PILOT-ROW-POST]` recorded action `0x83`, owner `8`, row `0x002E5A88`, item `0x002E4C34`. This correlates the input edge to the pilot-list callback, but it did not reach the name editor.

At guest tick `114367359`, DirectSound commit tracing found an invalid voice-list node `0xFF000000`; its predecessor's next, previous, and owner fields were all `0xFF000000`. A second check observed node `0`. The captured voice-list head had `next=0`, `prev=0x00004000`. The following crash record reported:

- Host RIP `0x7FF7DF806928`, read fault at host address `0x10000FFF4`.
- Guest fault VA `0xFFFFFFF4`; guest `ESI=0xFFFFFFEC`, `EBX=0`, `EDI=0x010810A4`, `ESP=0x00F7FDB8`.
- Runner captured `exception-stall.dmp` with the same r513 image/symbol bundle and stopped only the diagnostic process.
- The dump contains 38 threads. TID `51764`'s validated x64 unwind reaches `your_game_recomp_producer_trace.exe+0x61A6928` and `+0x6523428`, then stops at guest VA `0x0021ED29`, which is outside host modules. The dump has no exception stream, so this is a post-exception supervisor-thread snapshot, not the fault-time host context. The explicit crash log's guest registers and fault address remain the reliable exception evidence; the dump does not identify the list writer.

Source correlation narrows the immediate fault: `sub_0021FE7C` walks the per-object list at argument `0x010810A4` with sentinel `0x010810B4`; after following the invalid `0xFF000000` link, the next pointer is zero. Its guest path subtracts `0x14` from that zero node and calls `sub_0021ED29`, producing `ESI=0xFFFFFFEC`; that callee's first `[ESI+8]` read is precisely guest VA `0xFFFFFFF4`. This explains the crash but not the earlier write that poisoned the link. The crash handler's separate device-level list snapshot at `0x01081014` (`next=0`, `prev=0x4000`) is a different list head from the per-object sentinel `0x010810B4`; it is not evidence that the failing per-object list was empty.

This independently reproduces the immediate DirectSound invalid-list traversal also seen in r521. It does **not** establish which writer or invalidation corrupted the links. No code fix is supported by this run. Keep this failure separate from the r519/r502 mode-2 loading plateaus, the r495/r501 GET_REPORT candidate, and the historical DCF4 wait.

## Trace coverage and limits

The effective environment enabled the bounded contiguous-allocation trace, guest device-entry trace, successful file-open path trace, paired-open target trace (cap 2,048), sampled file-failure path trace, mode-2 readiness trace, and loader pair-output trace. Runtime records included 237 paired-open begin/done attempts, 15 sampled missing paths, and 224 read completions. These occurred at title/menu stage; the paired opens include empty save-slot enumeration and do not identify a loading dependency.

The run emitted **zero** `[CONTIG-EX]`, `[PB-REPORT]`, GET_REPORT executor, and mode-2 readiness records. It never entered the loader stage, so it provides no evidence for or against the allocator/report address-alias candidate. The missing file-open evidence from r519 was enabled, but the run crashed before it could serve the mode-2 dependency question. No DCF4 producer-stage investigation was warranted because the relevant wait did not reproduce.

The next discriminating trace already exists in `local-tools/steel-battalion-game/src/dsound_write_watch.c`. It arms four-byte x64 hardware write breakpoints on `0x8038C098` (the corrupted predecessor's next field), `0x8038C09C` (previous), and `0x8038C08C` (owner), recording host RIP and guest ESP. CMake includes this source, the exact r513 executable contains its `[DS-WATCH-START]`/`[DS-LINK-WRITE]` markers, and its timestamp is newer than the watch source. The r524 environment did not enable `RECOMP_DSOUND_WRITE_WATCH`. A follow-up can therefore reuse the exact r513 EXE/PDB/MAP without a build and enable `-EnableDsoundWriteWatch`; the watch is limited to 20,000 events and the same run budget remains 64 MiB. It covers these three words only, so zero writes would not rule out corruption through another address or before the watched threads are armed.

## Build, storage, and next step

No source, generated code, build cache, controller mapping, guest fence, or rasterizer was changed; there was no build, so incremental-build performance is unchanged. The existing route save root was reused and retained. No storage was deleted or reclaimed; the new run retains 2.05 MiB allocated evidence, including its matched dump and screen captures.

First mission frame remains **0/1**. Use the existing write watch on the exact r513 bundle and same save root to identify whether and when the three corrupted predecessor words change, with screen-gated inputs and a 64 MiB cap. Do not patch the symptom alone. Once a specific writer is supported, test the smallest fix; preserve the allocation/report and loader probes for any run that reaches those stages. Stop at the first visually verified mission frame.
