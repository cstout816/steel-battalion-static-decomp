# r441: handle-slot writer trace and loading stall

**Milestone 3 remains active. First mission frame: 0/1.** This run reached the visible `NOW LOADING` screen through the new-pilot route. It did not reach a mission frame. The host window showed the loading caption, while the final retained guest framebuffer was solid white; these are separate observations.

## Run identity and retained evidence

- Run: `m3-loader-3fff-writer-r441-20261030`; start `2026-10-30T18:54:21.698Z`, stop `2026-10-30T19:04:21.404Z`.
- Diagnostic game PID 22740 and write-watch helper PID 34624. The r441 NV2A-progress watchdog stopped only PID 22740 after 180 seconds without a callback/frame/counter/fence change. The runner verified the executable path. No other game process was stopped.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r426-dcf4-heartbeat-cap-20261030/Release/your_game_recomp_producer_trace.exe`, SHA-256 `6E2494623A1048E35DE2C18C68513719DDEA0AF1532F80EB4E85E8DC5C803C45`.
- Matching PDB SHA-256 `9B6466B280BB89AC626F75F71340E476B0030B430041D6B9FAC9AE510CE2714D`; MAP SHA-256 `D678DE9183B8DB733D3E52CB1887EF61DB9A0A44CCDDB9020CEF1724FC9BC40A`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; relevant files `recomp_0000.c`, `recomp_0015.c`, and `recomp_0018.c`. No generated source or runtime behavior changed.
- Save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`, reused in place. The temporary pilot name on this route was `AA3`; the default date and Normal difficulty were used.
- Minidump `nv2a-progress-stall.dmp`, 1,124,429 bytes, SHA-256 `A08FC4E07C4DA7A2602E703A45632DC87875E26E206B78E11167F763DE418BA6`.
- Final 640×480 guest framebuffer `frame-history/capture-0013.bmp`, SHA-256 `BB134B2A2CF95E56D036855B53F8B2A782D3185BEE005782B0B4913961DDA9D2` (solid white). Thirteen captures were made; nine were evicted; four remain. No capture or trace records were dropped, and the 64 MiB evidence budget was not reached.

## Handle-slot writer, consumer, and handoff

The watch targeted guest VA `0x82A9BFFC` with the documented guest-memory offset `0x10000` (host VA `0x82AABFFC`). It recorded:

```text
WRITE tick=26823796 tid=26752 old=00000000 new=00000000 native_rip=00007FFEE05EE75B
WRITE tick=26823843 tid=26752 old=00000000 new=FFFFFFFF native_rip=00007FF71FCB657A
```

The second native RIP was inside the exact r426 image at RVA `0x615657A` (image base `0x7FF719B60000`), MAP VA `0x14615657A`, within `sub_0020F1F0` at `+0x2CA`. The matching generated source's `loc_0020F250` stores `0xFFFFFFFF` to `entry + 0xC` when the slot flags do not include bit `0x4`.

At the same guest tick, the r426 guest trace recorded `sub_0020F260` being called with handle `0x3FFF` from `caller=0x000151F3`. That return site is inside `sub_000151D0`, whose generated loop initializes handle indices 0 through `0x3FFF` by calling `sub_0020F260`. The trace then records `create-entry-return` at guest PC `0x0020F26B`, result `0x82A9BFF0`, and `create-publish-return` at `0x0020F2B5`, result 0; the entry's fourth word remains `0xFFFFFFFF`. This is the observed table-initialization write, not evidence of a later valid binding.

The consumer is explicit in the generated AOT. `sub_0001D980` repeatedly calls `sub_0020EC00(0x3FFF, ...)` and branches from `0x0001D992` back to `0x0001D981` on `0x88760828`. r441 correlated that loop at runtime: TID 26752 receives `0x88760828` at guest PC `0x0020EC2B`, caller `0x0001D992`, for entry `0x82A9BFF0`; sampled failed lookup counts advanced through 262,144 with zero dropped records. The write watch saw no later change to `0x82A9BFFC` before the 180-second stop.

This establishes the immediate observed stall condition: AOT guest code is polling an empty object-table entry, and no producer binds that entry during this route's stall window. It does not yet identify which game operation is expected to bind handle `0x3FFF`, whether the handle is supposed to be valid at this point, or prove this is the sole cause of the absent mission transition. No seeding, guest-check bypass, fence signaling, or code fix was attempted.

## Loader, file, graphics, and wait evidence

- The final mode-2 load-pass record was n=30 at tick `26811968`: range `2..11`, last index 28, branch `scan`, result 0, pair `0x000ABA00/0`. There were 30 pass records total. The mode-2 asset worker for index `0x1E` opened and copied successfully and set ready byte VA `0x00351F22` to 1. Guest worker objects `0x013BA000`, `0x013BB000`, and `0x019204A0` reached exit status 1; the latter two completed after 89 and 80 polls.
- File lifecycle recorded 2,499 opens and 2,090 closes, ending at tick `26820781` with a successful `user02.sav` open/close. No `FILE-MISS-PATH` record occurred. The read sampler emitted 231 records; per-target read begin/done tracing was disabled, so file completion for every dependency is not established. There were no further lifecycle operations after the last logged close.
- At the 180-second stop, NV2A callback count was 0 and frame/counter/target/fence remained `0x7C3 / 0x90B9 / 0x9053 / 0x90B7`; DCF4 was signaled. DMA PUT/GET stayed at `0x1F014`; batches, workers, and pending raster work were zero. The final state does not support a raster backlog or an unsignaled DCF4 wait as the reproduced stall.
- Exact-bundle native unwind for TID 26752 read 67 stack regions with zero failures, reached `recomp_trace_guest_device_entry` / UCRT, then stopped at a non-module address. It did not validate a guest unwind. TID 27620's native unwind stopped with Win32 error 487. The explicit guest PCs, caller fields, and generated AOT branch above are direct evidence; raw stack-address candidates are not treated as frames.

## Storage and build impact

The full workspace inventory measured **39,432,518,326 allocated bytes (36.724 GiB)** and **1,398,728,252,909 logical bytes (1,302.667 GiB)** across 78,644 ordinary files; 13 reparse entries were skipped. Compared with the r440 scan, allocation increased by 2,423,578 bytes. The r441 folder used 2,334,966 allocated bytes and 8,150,792 logical bytes. The route save root used 952,910,026 allocated / 5,422,140,106 logical bytes; the retained warm `build-xpp-seeded` tree remained 7,354,916,122 allocated / 14,892,036,516 logical bytes.

No build or cache purge ran; build efficiency is unchanged. No allocated bytes were reclaimed this turn. The earlier three exact duplicate tool archives remain outside the workspace in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives`, totaling 976,265,216 allocated bytes. Candidate and keeper SHA-256 values still match and no active code/config reference was found. The exact-path removal command was rejected by the local policy gate; no candidate was deleted and no alternate deletion method was attempted. The keeper archives remain intact.

## Next step

Identify the game-side owner and expected producer for handle `0x3FFF` by tracing the call path into `sub_0001D980` and the allocation/binding call that should publish its object pointer. Keep the same r426 AOT bundle, screen-gated new-pilot route, guest fences, controller mapping, and rasterizer `1ea1871`. Do not change behavior until the valid-binding expectation is supported. First mission frame remains the next gameplay acceptance point.
