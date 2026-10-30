# r427–r431 loader and storage update — 2026-10-30

## Result

The first mission frame remains unverified (0/1). r427 is still the latest run to visibly reach `NOW LOADING`; r430 and r431 both stopped before the pilot list and mode-2 loading path. No source or runtime behavior change is supported by these runs. No build was performed.

The earliest reproducible *loading-stage* observation remains the r427 post-difficulty plateau: the screen showed `NOW LOADING`, mode-2 load-pass calls 6–15 returned 0, the last scan covered indices 2–11 with `last_index=28`, and the subsequent framebuffer/progress fields stopped advancing. This does not identify a specific missing file or prove that file I/O is the blocker. r427 did not enable file-lifecycle tracing; its 224 `READ` rows are sampled completion records, and their gaps cannot establish that a request stayed incomplete.

## Exact runs and evidence

All three runs used the same r426 diagnostic bundle and canonical generated source:

- EXE: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r426-dcf4-heartbeat-cap-20261030/Release/your_game_recomp_producer_trace.exe` — SHA-256 `6E2494623A1048E35DE2C18C68513719DDEA0AF1532F80EB4E85E8DC5C803C45`.
- PDB SHA-256 `9B6466B280BB89AC626F75F71340E476B0030B430041D6B9FAC9AE510CE2714D`; MAP SHA-256 `D678DE9183B8DB733D3E52CB1887EF61DB9A0A44CCDDB9020CEF1724FC9BC40A`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0015.c` SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`.

| Run | Screen and synchronized state | Dump/unwind |
| --- | --- | --- |
| r427 `m3-known-new-pilot-to-loading-r427-20261030`, PID 33664 | Screen-gated new-pilot route reached a visually verified `NOW LOADING` image, `frame-history/capture-0018.bmp` (SHA-256 `D0D514FC8795F53240C5720840E40E538316B0D2D0A79EB9310F2BD9D09F6DFC`). Mode-2 passes 6–15 returned 0; last range 2–11, last index 28. At the plateau, frame `0x117A`, counter `0x17591`, target `0x1758B`, fence `0x1758F`, DCF4 signaled, raster active/pending workers 0. The saved-pilot path was empty; no user save was copied. | `mode2-plateau-snapshot-2.dmp`. Native StackWalk on TID 17312 reached `xbox_DispatchGateEnter+0xE1` and stopped with error 487. TID 1736 reached `guest_cpu_acquire+0x6E` and stopped with error 487. The accompanying raw address scan contains candidate guest addresses but is **not** a guest unwind. No synchronized owner snapshot proves a lock cycle or identifies the expected producer. |
| r430 `m3-newpilot-loader-locktrace-r430-20261030`, PID 8672 | Initial title route only. 325 DCF4 callback and 323 gate rows; 309 file opens, 264 closes, 212 targeted opens/completions, 224 sampled reads, 3 thread-object creations, 2 polls, 0 state transitions. No pilot-list callback, mode-2 pass, or loader file request. Terminal sample: frame `0xF0`, counter `0x411`, target `0x407`, fence `0x40D`, DMA PUT=GET `0x4F80`, raster workers idle. | `title-transition-snapshot.dmp`, SHA-256 `F0F684FCD8E70EC5003D210319046ADC2AFC70EF48B4C98EEC4587F211727323`. TID 31616 unwound through `ntdll` and `KERNELBASE` to EXE RVA `0x64AA319` (`xbox_KeWaitForSingleObject+0x29` in this exact MAP), then stopped at non-module value `0xF4C`. This is a partial native unwind, not a validated guest caller chain. |
| r431 `m3-known-route-loader-locktrace-r431-20261030`, PID 11876 | Reused the r427 r368 empty-save root and the first six known-route inputs. XID and guest edge records were emitted; one title route advance at `0x000E0840` selected `0x002B29B0`. The visible presentation then froze on black/title transition. 314 DCF4 callbacks, 312 gates, 321 opens, 283 closes, 222 targeted open/completions, 224 sampled reads, 3 thread-object creations, 2 polls, 0 state transitions. No pilot-list or mode-2 records. Terminal sample: frame `0xEB`, counter `0x3FD`, target `0x3F3`, fence `0x3F9`, DMA PUT=GET `0x6BC0`, raster workers idle. | `title-transition-snapshot.dmp`, SHA-256 `7A6C7588E6E876E37E40808FEA2FA0EE2329CAD27AA4D4F387E682941010D187`. TID 22160 unwound through `ntdll` and `KERNELBASE` to the same exact-bundle RVA `0x64AA319` (`xbox_KeWaitForSingleObject+0x29`), then stopped at non-module value `0xEEC`. This is also partial native unwind only. The reused r368 root still has an empty `UserData`; the run updated `Cache/COPYCHECK.DAT` (76 bytes, 11:39 AM), which was preserved. |

Both r430/r431 manifests report zero relay drops and zero trace-cap hits. The wait trace retained only 64 DCF4 wait rows and reported 47 skipped rows. Its last retained r431 wait at index 64 was set and returned at the same tick; later missing rows cannot prove that no later wait occurred. Thus these title-transition runs do not establish a persistent DCF4 wait. Keep them distinct from the r427 loading plateau.

The title input edge reached the XID DMA buffer. r431 also recorded the guest edge consumption and route advance. The route transition is not the loading callback. The already identified pilot-list callback remains `sub_000E1820` at `0x000E18D8`; it did not execute in r430/r431. `sub_000E0870` is not reopened as a candidate.

## Kernel thread-object contract check

The current `bridge_ObReferenceObjectByHandle` at `local-tools/xboxrecomp/src/kernel/kernel_bridge.c:5658` calls `bridge_thread_object_for_handle` even when the guest output pointer is null; only copying the object pointer is conditional. The helper at lines 3871–3897 performs a zero-time host wait, returns `STATUS_PENDING` on `WAIT_TIMEOUT`, and writes the completed thread status into guest object `+0x120` when the host thread has exited. The null-output path therefore does not skip completion polling in the current implementation. r430/r431 created three thread objects and polled twice each, with no state transition, but neither run reached the loader. Runtime completion semantics remain unverified; the old r130 stub diagnosis is not repeated.

## Cause assessment and next discriminating test

- **Confirmed:** the r427 run reached the loading screen and then its mode-2 scan/progress stopped. Raster workers were idle and DCF4 was signaled at the terminal sample, so an active raster backlog or unsignaled DCF4 is not demonstrated as the r427 cause.
- **Not confirmed:** which file, thread object, guest CPU owner, event producer, or helper branch first prevented loader progress. r427 lacks file lifecycle/request-completion tracing and synchronized guest-CPU ownership at the final plateau.
- **Separate title case:** r430/r431 stopped before loader dispatch. Their final native wait-wrapper frame does not establish that the loader wait or DCF4 caused r427.
- **Separate audio case:** DirectSound list corruption was not established by these runs. Preserve the prior crash report separately.

Next test: repeat the same r427 new-pilot route and save root with file lifecycle/open-target completion, thread-object state, guest-CPU owner/wait snapshots, mode-2 helper enter/branch/return, and a non-stopping plateau dump enabled. Correlate all records at the first stopped progress transition. The confirming evidence is a specific outstanding file request, incomplete thread object, or owner/wait handoff whose producer has stopped; reject that hypothesis if the relevant operation completed and the guest scan advanced. Add no behavior patch until this correlation exists. Preserve AOT, guest fences, controller mapping, and rasterizer `1ea1871`.

## Storage and build impact

A fresh path-based inventory after r431 found 78,410 ordinary files with 1,398,556,822,470 logical bytes and 41,919,136,250 allocated bytes. Thirteen Rust toolchain reparse entries added 165,381,632 allocated bytes, for **42,084,517,882 bytes / 39.194 GiB allocated**. Ordinary logical length is about 1.27 TiB; sparse capacity is not allocated usage. Inventory: `C:\Project\sb-inventory-current-r431-final-20261030.csv.gz`, raw CSV hash `734AA762796DE9E0FCF82646190080EAE5F05E3F10977A0259A61233F9CF22D3`, decompression-verified.

Closed text evidence from r430/r431 was gzip-compressed only after verifying every decompressed SHA-256 and length, then the original text files were removed. **Actual allocated bytes reclaimed: 816,717** across 19 logs/text files. The per-file audit is `analysis/r430-r431-closed-evidence-compression-20261030.csv`. Dumps, captures, saves, ISO, source, symbols, and build outputs were retained. The resulting full workspace is 4,743,467 allocated bytes above the preceding full inventory because new diagnostic artifacts were retained; compression reduced their footprint but did not make these runs net-negative storage additions.

Current key allocation measurements from that inventory: `build-xpp-seeded` 7,354,916,122 bytes; historical/current log tree 3,113,447,292 bytes; extracted game files 1,800,138,464 bytes; canonical generated source 155,890,474 bytes. The r368 sparse save root is 5,422,148,542 logical bytes but 110,715,000 allocated bytes. The two retained r430/r431 run directories occupy 4,019,952 path-summed allocated bytes. The warm build tree was not purged, no rebuild ran, and incremental build efficiency is unchanged. Exact duplicate ZIP candidates remain quarantined because the previous delete attempt was rejected by automatic file-action review; no alternate deletion was attempted.

## Verification limits

No code change, build, focused regression, successful audio check, controller verification, performance measurement, or first mission frame resulted from r430/r431. r427 verifies only the loading screen and plateau. Campaign completion, loading dependency, title-transition cause, thread completion, and mission rendering remain unverified.
