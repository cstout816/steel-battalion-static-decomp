# r374–r375 loading and storage follow-up — 2026-10-30

## Result

Milestone 3 remains active. No mission frame was verified. r375 reached the new-pilot route, confirmed a pilot named `A` with date `10/01/2002`, chose Normal difficulty, and then showed a black frame. This run did not show a visible `NOW LOADING` label. AOT, controller mapping, guest fences, and rasterizer baseline `1ea1871` were preserved. No runtime change or build was made.

The r375 evidence supports a **post-difficulty loading/progress plateau**: mode-2 readiness scans ended at pass 15 with result 0 and output pair `0x000ABA00/0`; sampled reads stopped at 8,000; and at the last NV2A samples the callback/frame/counter/target/fence values were unchanged, with zero raster jobs. DCF4 remained signaled. The expected producer for the readiness pair and the first missing loader dependency are not identified by this run.

## r374 DirectSound exception

Run `m3-title-nv2a-irq-handoff-r374-20261030`, PID `175408`, reused the r367 executable, matching PDB/MAP, generated source, and r368 save root. EXE SHA-256: `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`; PDB: `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`; MAP: `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`.

The saved screen was the name editor with `A` entered. The DirectSound guest list then contained an invalid `0xFF000000` link and the process faulted reading guest VA `0xFFFFFFF4` in `sub_0021ED29+0x88`. Its trace had no DS write watch or synchronized surface trace, so it does not establish the corrupting writer. The run recorded active NV2A IRQ/DCF4 callbacks through the exception; this is not evidence of a DCF4 wait. Keep it separate from the earlier r340 writer-correlated pixel store and from the post-difficulty plateau.

## r375 bounded surface test and loading plateau

Run: `m3-surface-overlap-route-r375-20261030`, diagnostic PID `173684`. It used the same r367 bundle and r368 save root. The process was ended by its own 900-second external watchdog; no other game process was interrupted. There was no build. Exact bundle hashes are the same as r374 above.

The run enabled `RECOMP_DSOUND_WRITE_WATCH` and the capped `RECOMP_DSOUND_SURFACE_TRACE`. The write watch recorded nine expected initialization/link-insertion stores to `0x8038C08C`, `0x8038C098`, and `0x8038C09C`. It recorded **no later write** to those words, and there was no `[DS-SURFACE-PIXEL]` overlap row, invalid-node row, or crash. This is a valid negative only for this r375 route; it does not reject r340’s direct writer evidence or explain r374’s exception.

The visually checked route was:

- title prompt → Campaign → `LIST AS NEW` → pilot name/date editor;
- name `A` → date `10/01/2002` → confirmation → Normal difficulty;
- difficulty confirmation → black framebuffer.

The date differs from the earlier saved route because three `ldown:500` pulses changed the day. This is not known to explain the plateau.

At the last mode-2 pass (n=15, tick `574832796`), the output pair changed from `0/0` to `0x000ABA00/0`, with `result=0`. There were no later mode-2 pass records. The last sampled successful read was n=8,000 at tick `574832937`; file-path/lifecycle tracing was disabled, so the record cannot identify an asset. No `NOW LOADING` image was captured.

The last NV2A signature remained callback count `18278`, frame `0x256C`, counter `0x3EF6D`, target `0x3EF67`, fence `0x3EF6B`, DCF4 `1`, and zero batches/workers/pending. The kernel timer and IRQ polling continued. A watchdog sample taken at 180 seconds put the guest-main host thread in `xbox_KeWaitForSingleObject+0x29`; its guest-stack words were raw snapshots, not a validated guest unwind. No final minidump was produced. Thus the exact stopped guest wait object, expected readiness producer, and first incomplete file dependency remain unverified. `WAIT-DCE4` reached its 8,192-record cap and `DCF4-GATE` reached its 16,384-record cap plus a cap marker; no stdout/stderr relay drops occurred.

## Older evidence checked first

Before r375, the exact r149 bundle used for r150/r151/r153 was checked offline: EXE `D503E6DA6325E9771364C9160F358A21550128B34AAC7B500A34C0EE0642A15C`, PDB `1741EA1E29FEF3DF22182C934AF3E30BAECCCB0DFFB93C1649080095A2A94287`, MAP `4AE43B0B58C029D290E9041297232C303E9EBF0E8FC04D54761EB5BBFE4A6A37`. r150/r151 validate the historical title DCF4 guest wait and normal idle raster-worker waits; r153’s point sample does not identify a loading-stage owner. These reports do not identify r375’s expected pair producer.

Correction to the r372–r373 handoff report: exact r367 symbol resolution maps callback-thread address `EXE+0x6498042` to `kernel_timer_thread+0xE2`, the expected `Sleep(10)` in the timer loop. The subsequent apparent frame at `EXE+0x6AC30A0` is `.data`, not a return address. The timer thread was not shown stuck. r373’s main-thread DCF4 wait and missing subsequent index-5 callback remain observed, but the callback worker’s wait object/wake producer were not proven. Do not carry forward the prior claim that this thread was blocked before the next DCF4 handoff.

## Storage and build impact

Fresh scan `C:\Project\sb-inventory-current-r375-20261030.csv`: 77,402 ordinary workspace files, **41,312,184,180 bytes allocated** and **1,396,896,367,723 bytes logical**; 13 reparse entries were measured separately at **165,381,632 allocated bytes**. Combined workspace allocation is **41,477,565,812 bytes (38.629 GiB)**; combined logical length is about **1,300.961 GiB**. The path inventory had zero allocation-query failures. The warm `build-xpp-seeded` cache is **6,918,921,034 allocated bytes**; canonical generated AOT source is **155,887,568 bytes**; r368 route saves are **110,700,940 allocated / 5,422,134,482 logical bytes**; logs use **2,996,373,183 allocated / 1,035,968,311,324 logical bytes**.

r375 evidence uses **9,128,795 allocated / 31,287,784 logical bytes**. Lossless NTFS compression changed no allocation and all 19 file hashes matched. No hot cache or source was removed. No build ran, so build efficiency is unchanged; the last measured warm incremental build remains about 9.1 seconds (r336).

The external `C:\Project\SteelBattalion-Delete-Later-20261026` archive currently uses **1,329,496,337 allocated / 2,092,257,079 logical bytes**. A fresh hash/retained-copy audit found 269 unreferenced duplicate screenshots, 2 filename-reference exceptions retained conservatively, and 3 duplicate tool archives; the 274 candidates together account for **983,048,192 allocated bytes**. Exact retained copies and hashes are in the local validation manifest. The exact-file deletion attempt was rejected by automatic file-action review before execution; **actual deletion savings are 0 bytes**. No alternate deletion route was used. The 104 inactive build artifacts were left untouched because exact dump/symbol bundle dependencies were not re-audited for deletion.

## Next test

Use a bounded route with file lifecycle/open/completion paths, thread-object pending-to-completion transitions, preload-worker scheduling, and a captured final minidump at the internal plateau stop. Correlate the first mode-2 scan result/pair with the expected worker and last successful file completion. Keep the r374 DirectSound exception, r373 title DCF4 wait, expensive rendering, and this r375 post-difficulty plateau separate. Do not change runtime behavior until one cause is supported. The acceptance point remains a visually verified first mission frame.
