# r506–r509 input, loading, and stall discrimination (2026-10-31)

## Outcome

Milestone 3 remains open; a first mission frame is still **0/1**. r508 reached a visually verified `NOW LOADING` screen through the new-pilot route, but did not reach a mission frame. Its final loader thread was blocked in the host dispatch-gate entry path; the gate owner was not captured, so this is a supported wait location, not an established root cause. r509 instead stalled earlier at the title/player-record prompt in a wait path consistent with the separate title DCF4 issue. Do not combine these stages.

No game/runtime/generated-source edit, build, synchronization change, input-mapping change, preload change, or rasterizer change was made. AOT execution, controller mapping, guest fences, and rasterizer commit `1ea1871` remain as before. The r507 access violation was not reproduced in r508.

## Exact executable and source bundle

- AOT executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-device-entry-r502-20261031/Release/your_game_recomp_producer_trace.exe`, SHA-256 `5CEA9DCA013BA97E5312F36D3C03616975FABE19F84E81BC21DCCC2AC1DEFC0A`.
- Matching PDB: `your_game_recomp_producer_trace.pdb`, SHA-256 `AEAE30C5F8063A91475B4DEC0A20AD94E9CCDB048226E23FFC4E9FA9F565BC0F`.
- Matching MAP: `your_game_recomp_producer_trace.map`, SHA-256 `854B51CD36944A8DB4CF7C5EB5883054E15A4160529D1E7B664074EF6F571892`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0015.c` SHA-256 `65EDF05FC26AE1B4BD842572279C6B90EF11E781B030A1C54F7F510C24047B10`.
- Both new-pilot runs reused `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. No save image was copied, linked, or removed.

## Run findings

| Run | Identity and result | Verified screen / state |
| --- | --- | --- |
| r506 `m3-saved-pilot-read-completion-r506-20261031` | PID 50468; same r502 bundle; 64 MiB run cap; 9,260,641 logical bytes at exit. | Title → player-record error. Its later A report was delayed and a DCF4 wait was observed. No loading screen. |
| r507 `m3-dcf4-callback-target-r507-20261031` | PID 47048; same bundle; exit `0xC0000005`; no in-process dump. | Reached the name editor with `A`; crashed before pilot completion. The later `lright` line had no matching XID report before exit, so it is not shown to cause the crash. DCF4 waits did return in this run. |
| r508 `m3-new-pilot-access-violation-r508-20261031` | PID 48880; same bundle; exit `-1` after two live dumps and a stable loading stall; 0 relay drops, no trace caps, 64 MiB budget not hit. The AV did not reproduce. | Visually confirmed title → player-record prompt → Campaign → `LIST AS NEW` → name `A` → DOB `01/01/2002` → `YES` → Rookie → `NOW LOADING`. The last window reading was 0.0 FPS / 28 draws. No mission frame. |
| r509 `m3-dispatch-gate-owner-r509-20261031` | PID 46304; same bundle and save root; dispatch-gate tracing, guest CPU trace/snapshot, load-stack, thread-object, and mode-2 readiness flags enabled. Exit `-1` after two live dumps. 0 relay drops and no trace caps. | First A progressed to the record-error prompt. Two later A pulses reached XID but were not consumed by the guest. The screen did not reach Campaign or the loader. The final main-thread stack and nearby wait records match the separate title-stage DCF4 wait pattern. |

### r508 post-difficulty loader state

- `LOAD-PASS-IN` and `LOAD-PASS-OUT` each reached 27. Pass 27 returned at tick `100209921`, mode 2, range `2..11`, last index `28`, branch `scan`, result `0`, pair `000ABA00/00000000`. The sampled helper last emitted at tick `100209640`, with progress fields `00000000/00000000/0000`.
- The read sampler reached 9,000 successful records; the last sampled read was at tick `100210171`, handle token `480000EF`, 20 bytes requested and read with success status. That stream had no filename mapping in this run, and file lifecycle tracing was disabled. It cannot identify a missing asset or prove which file the final loader consumer expected.
- Loader TID 49060 and another guest thread, TID 18768, had matching partial native unwinds in both live dumps. Each reached `your_game_recomp_producer_trace.exe+0x64A6791`, which the exact MAP resolves to `xbox_DispatchGateEnter+0xE1` in `kernel_hal.obj`; the walk then stopped at the native unwind boundary. These are genuine partial native unwinds, not raw stack scans. No owner was recorded because `RECOMP_DISPATCH_GATE_TRACE` was off in r508.
- At tick `100210218`, raster telemetry still showed one batch and three pending workers. Later NV2A samples (first after that state at tick `100224625`) showed zero batches, workers, and pending work, with DCF4 signaled. The last DMA ACK (#249, tick `100209921`) ended with PUT=GET=`0006A748`. This rules against a continuing graphics backlog in the later plateau window; it does not identify the dispatch-gate owner.
- Both dumps: `loader-stall-pid48880.dmp` SHA-256 `03EAC057382754F7E954EDAB56B9D5A151DD6BABE4D94DC851F6384CC7F6CC68`; `loader-stall-later-pid48880.dmp` SHA-256 `AF808D4D26514DE9911C94D064FCF093A972D74283810F0FC441809D66E918B4`. The latter repeated the same partial frames. The final retained screenshot is `frame-history/capture-0008.bmp`, SHA-256 `0AAB28529804FE6D2CFC0A560678CAD1FB4241E1AF6DA02246FDEF24B1707E22`.

### r509 title wait and input state

- Initial A was delivered in XID report byte 2 at tick `100479484`; guest edge handling at tick `100479578` used table `00048DF8`, index 6, target `00048CBB`, changed guest cell `004AFC08` from 0 to 1, and the title callback advanced to `0026D59B`.
- Later XID A pulses were recorded at ticks `100514109` and `100572734`, with releases at `100514609` and `100573234`. Neither had a matching guest edge/predicate or route change. The visible capture remained on the player-record prompt.
- Main guest TID 33988 has a valid partial unwind through `KERNELBASE.dll+0x1427F` to EXE `+0x64ABBC9`; the exact MAP resolves the latter to `xbox_KeWaitForSingleObject+0x29`. The walk stops at guest-looking address `0xDEC`; no caller chain is inferred from that value.
- `wait-trace.log` records repeated DCF4 and DCE4 traffic. The last fully paired sampled DCF4 wait/return was wait #320 at tick `100486109` / return at `100486125`. DCF4 set rows continued through #382 at tick `100490328`, then `reset-DCF4[384]` was logged at tick `100490375` (frame `0x332`, counter `0xDFD`, target `0xDF3`, semaphore `0xDF1`). Later DCE4 signals continued through tick `100638500`. The final dump still shows TID 33988 in the single-object wait wrapper. The wait stream did not emit a matching later DCF4 wait/return record, so the exact outstanding object and producer at dump time remain unverified; the timing and address are consistent with the historical title DCF4 failure.
- Owner tracing was enabled in r509 with cap 256 / 250 ms threshold, but it emitted zero `[DISPATCH-GATE]` rows before the title wait. Thus r509 does not reproduce r508’s post-difficulty gate contention. Guest CPU snapshot support was enabled but no snapshot row was emitted.
- Dumps: `title-stall-pid46304.dmp` SHA-256 `2C4BD32FB2FEE12815DDE9D743A0C8B8208734F4345E25D02012719CFEF158E0`; later `title-dcf4-later-pid46304.dmp` SHA-256 `F0B3C50352CBE953E49D5DD6B495574E567D82B7B25A8DD01562B6D538FA6309`. The final retained screenshot is `frame-history/capture-0002.bmp`, SHA-256 `9CD6FF8AEF8532F79D6D77905B18971AFCEC7C7DF99FBE3E0704CD91FA778303`.

## Storage, bounds, and build impact

- Final full inventory after reports: 80,010 regular files, 40,025,676,898 allocated bytes (**37.277 GiB**) and 1,402,623,196,602 logical bytes (**1,306.295 GiB**). Thirteen zero-length Rust tool symlinks to the same `rustup.exe` were skipped to avoid counting their target repeatedly.
- Compared with r505’s 40,014,873,187 allocated and 1,402,584,774,300 logical bytes, current totals are up 10,803,711 allocated bytes (10.30 MiB) and 38,422,302 logical bytes. That net addition includes new evidence and reports; the run logs themselves were compressed below their pre-compression allocation.
- Closed r508/r509 evidence: 28 files, 22,981,022 logical bytes. NTFS compression reclaimed **3,454,611 allocated bytes**, from 9,259,636 to 5,805,025. All 28 SHA-256 values matched before and after. No evidence, screenshots, dumps, source, saves, or build artifacts were deleted.
- Current inventory components: canonical generated source 155,904,044 allocated bytes; the reused save root 952,918,462 allocated / 5,422,148,542 logical bytes; `build-xpp-seeded` 7,863,535,031 allocated / 16,082,205,888 logical bytes; all `iso/local-analysis/logs` 3,519,669,485 allocated / 1,039,341,091,337 logical bytes.
- No build cache or source tree changed. Last measured warm incremental build remains 8.2 seconds from r502. The two new runs total 5,805,025 allocated bytes after compression.
- Inventory CSV: `C:\Project\sb-inventory-final-r509-20261031.csv`. Closed-evidence audit: `analysis/r508-r509-closed-evidence-compression-20261031.csv`.

## Current hypothesis and next action

The strongest r508 lead is a dispatch-gate wait on loader TID 49060 after loader pass 27 returned, with two threads blocked at `xbox_DispatchGateEnter`; the missing owner prevents a causal fix. The separate r509 lead is a title-stage wait at `xbox_KeWaitForSingleObject`, aligned with DCF4 reset and absent later DCF4 progress; its terminal wait record is incomplete. Neither is evidence for a missing file, raster backlog, DirectSound corruption, or the old r130 null-output issue.

Next, retain the same AOT bundle and bounded budget. On a route that reaches the post-difficulty loader, enable dispatch-gate owner tracing, guest CPU snapshots, and capped file lifecycle/read-completion correlation so the gate owner, guest waiter state, and exact last file handoff share a time window. Keep DCF4 producer tracing enabled only when the title DCF4 wait reproduces. Do not alter guest checks, signals, fences, preload behavior, or rasterizer until one cause is supported. Stop after the first visually verified mission frame.
