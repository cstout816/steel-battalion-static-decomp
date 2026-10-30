# r372–r373 title-stage DCF4 handoff — 2026-10-30

## Finding

The earliest reproducible blocker in this pair is a title-stage guest wait on DCF4 `0x0021DCF4`, before loading. r373 strongly supports a stopped callback/event handoff rather than a queued-DMA backlog: the guest main thread remained in `KeWaitForSingleObject` with DCF4 unsignaled, while the DCF4 callback stream stopped and DCE4 signaling continued. At the captured terminal state, NV2A USER PUT equaled GET and PFIFO PUT/GET/REF/SUBR were zero. The route remained on a black framebuffer; neither run reached `NOW LOADING` or a mission frame.

This is a synchronization observation, not yet a supported code defect or fix. The snapshot identifies the waiting callback thread only to a native wait and an executable code address; the wait object/releasing producer is still not resolved. No guest signal was forced, and AOT execution, controller mapping, guest fences, and rasterizer `1ea1871` were unchanged.

## Run identities and exact binary

| Run | PID / stop | Route and result |
| --- | --- | --- |
| `m3-crash-context-repro-r372-20261030` | 173580; this task stopped only this child after its 75-second snapshot | Reused r367 AOT and r368 save root. One title input took branch `0x000E0840 -> 0x00313D99`; framebuffer became black. No NVIDIA crash reproduced. In-process crash dump was enabled, but no crash dump was produced because no fatal exception occurred. |
| `m3-title-dcf4-handoff-r373-20261030` | 173684; this task stopped only this child after its 75-second snapshot | Reused r367 AOT and r368 save root. At tick `573389281`, XID report byte 2 became 1 at guest buffer `0x01081763`; edge consumer `0x000C8064` / parent `0x000E081F` selected `0x00048DF8[6] -> 0x00048CBB`, copied 1 to `0x004AFC08`, and the input predicate returned 1. The route branch was `0x000E0840 -> 0x003145BC`; the next retained capture was black. The DCF4 callback/handoff stall reproduced. |

Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-tdataroot-isolation-r367-20261029/Release/your_game_recomp_producer_trace.exe`, SHA-256 `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`.

Matching PDB SHA-256: `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`. MAP SHA-256: `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`. Generated source remains `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`. Both runs used `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`; no save copy or hard link was made.

## r372 crash-context check and first wait sample

r372 enabled the executable's existing `RECOMP_CRASH_DUMP` option and the external relay. It remained under the 64 MiB run budget, used 2,590,064 logical bytes, dropped no stdout/stderr lines, and ended without watchdog or crash. The title input reached the branch above, then a 75-second watchdog snapshot captured the main guest thread in the same wait wrapper used by the older title-wait family:

`NtWaitForSingleObject+0x14 -> WaitForSingleObjectEx+0xAF -> xbox_KeWaitForSingleObject+0x29 -> bridge_KeWaitForSingleObject+0x144 -> kernel_thunk_dispatch_body+0x35A -> kernel_thunk_dispatch+0x46 -> sub_00211E10+0xDD0 -> sub_0020E520+0x1FE -> sub_000DF470+0x10C0 -> sub_000DF770+0x323 -> sub_000E0780+0x4CB -> sub_000E2730+0x5FD`.

At the snapshot, guest event `0x0021DCF4` had signal 0; USER PUT and GET both equaled `0x0001C8D0`, and PFIFO registers were zero. The r372 trace was not configured for DCF4 callback branch detail, so it was not sufficient to identify the handoff.

## r373 synchronized producer and unwind evidence

r373 enabled bounded DCF4 callback/gate/queue/ring-poll, all-wait, DMA-ack, PB-semaphore, timer, guest-CPU snapshot, and in-process crash-dump options. Its 64 MiB evidence budget was not reached. The asynchronous relay finalized with zero drops; marker trace caps were not reached. Counts included 2,102 DCF4 callbacks, 2,100 gate records, 601 outer records, 60 DMA publishes, 54 marker records, 2,809 raster-sync rows, 162 DMA-ack rows, 103 PB-semaphore rows, and 32 raster-performance rows. Loader pass/state/preload traces were zero because the run never entered loading.

Observed DCF4 callback dispatches: index 1 / target `0x00216EC9` occurred 1,393 times (argument `0x01080021`: 697; `0x03600021`: 696); index 5 / target `0x0021701E` occurred 702 times; index 9 / `0x0021707C` occurred 6 times; index 8 / `0x00217053` occurred once. No callback cap was hit.

The final completed index-5 callback was #2100 at tick `573412593`. Its event set was `set-DCF4[702]`, caller hint `0x0021702F`. The next main-thread DCF4 reset was #704 at tick `573412640`, frame `0x571`, counter `0x187B`, target `0x1871`, semaphore `0x186F`. Callback #2101 at that tick selected index 1; callback #2102 at tick `573412687` also selected index 1. No later index-5 dispatch or DCF4 event set was captured before the 75-second snapshot. At the snapshot DCF4 remained unsignaled. Meanwhile the separate DCE4 event continued to be signaled with callback count fixed at 2,102.

Validated same-host StackWalk64 using the exact r367 image/PDB:

- Guest main host TID `182860`: `ntdll+0x161DD4 -> KERNELBASE+0x1BE9F -> exe+0x64A9A59`, resolving to `xbox_KeWaitForSingleObject+0x29`; unwind stops at non-module `0xD8C`. Reads 69, failures 0.
- DCF4 callback host TID `175284`: `ntdll+0x1623D4 -> ntdll+0xD0FD4 -> KERNELBASE+0x8B9C1 -> exe+0x6498042`. StackWalk then reports `exe+0x6AC30A0`, but PE-section inspection places that address in `.data`, so it is **not accepted as a genuine return frame**. Reads 119, failures 0. The valid native frames prove the callback thread was in a host wait entering executable code, but they do not yet resolve its wait object or wake producer.

At the snapshot, NV2A USER PUT = GET = `0x0001C8D0`; PFIFO PUT/GET/REF/SUBR were zero; PGRAPH pending was zero. The separate DCF4 marker showed PUT/GET zero, PFB zero, and event zero. These observations do not support queued DMA backlog as the cause of this specific title wait. They do not explain why the callback thread stopped.

Dump: `iso/local-analysis/logs/m3-title-dcf4-handoff-r373-20261030/producer-stall-snapshot.dmp`, 982,496 bytes, SHA-256 `4CAB6D4F6AB68714E50472B533AC0428AA1DBA6B5DA701526F9214B053856C9A`. The minidump has thread stacks but no exception stream; this was a deliberate live snapshot, not a crash dump. Captures 1 and 2 preserve the title prompt and the subsequent black frame; final capture SHA-256 is `7EACC084F17C7D7A73D4AF44903EDB866ECB6795A533C3478E336B265051020F`.

## Hypothesis and next discriminating work

**Supported hypothesis:** the title route’s DCF4 consumer waits after the last event set, while its callback worker blocks in a host wait before producing the next index-5 handoff. This predicts a missing DCF4 signal after the reset even while unrelated DCE4 signals continue. r373 meets that prediction. It rejects a simple “no callbacks ever ran” theory and does not establish the native wait’s object or releasing producer.

Next, use the exact r367 PDB and source to resolve executable RVA `0x6498042`, identify the callback worker’s native wait object and the producer that should wake it, and correlate that with the last queue/ring handoff at tick `573412687`. Keep this title/menu wait separate from the r371 NVIDIA-driver crash, DirectSound list corruption, expensive rendering, and post-difficulty loader plateaus. Do not patch, force a signal, or start another runtime until that offline correlation is complete. Then verify whether the same handoff is present on the path that reaches `NOW LOADING`; stop at the first visually verified mission frame.

## Storage and build impact

Fresh allocated/logical inventory after r373: **77,346 files**, **41,463,405,666 bytes allocated (38.616 GiB)**, **1,396,848,441,688 bytes logical (about 1.270 TiB)**. The 13 reparse-point Rust toolchain executables were separately sized and included in the allocation total. Current retained slices: warm build cache **6,918,921,034 allocated / 13,871,927,762 logical bytes**; generated AOT source **155,887,568 bytes**; route saves **110,700,940 allocated / 5,422,134,482 logical bytes**; logs **2,982,438,620 allocated / 1,035,920,610,872 logical bytes**.

The previously verified **763,160,973-byte** lossless-compression reduction remains intact. r372 and r373 added 3,684,718 allocated bytes across their run folders; their combined logical size is 9,655,250 bytes. No source, ISO, save, or cache was deleted; no hot cache was purged; no build ran. Warm incremental build efficiency was preserved, but this turn did not measure build time.
