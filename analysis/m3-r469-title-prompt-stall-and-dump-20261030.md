# r469 title prompt stall and dump review — 2026-10-30

## Run identity and retained evidence

- Run: `m3-known-newpilot-route-r469-20261030`; diagnostic PID `23704` (stopped after its frame remained unchanged; no other game process was stopped).
- AOT executable: r461 `your_game_recomp_producer_trace.exe`, SHA-256 `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`.
- Matching PDB: SHA-256 `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`.
- Matching MAP: SHA-256 `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`.
- Canonical generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; exact source file hashes are recorded in the run manifest.
- Reused save directory: `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`; no save copy or hard link was made.
- Run evidence: `iso/local-analysis/logs/m3-known-newpilot-route-r469-20261030`, including `black-frame-stall.dmp`, `frame.bmp`, bounded traces, and `run-manifest.json`.
- Manifest records 3,790,766 logical bytes at close. A post-stop allocation scan measured 1,586,019 allocated bytes (about 1.51 MiB). The 64 MiB diagnostic budget did not trigger; trace cap hits and relay drops were zero. The dump is 1,331,765 logical bytes. No project files were deleted or compressed during this run.

## Screen and route result

The retained 640×480 framebuffer shows the title prompt `Unable to load Player Record. Press MAIN WEAPON BUTTON to continue.` r469 did not reach the Campaign menu, visible pilot list, `NOW LOADING`, or a mission frame. The input transcript contains `a:6000`, `a:800`, `a:6000`. A press at tick `47056203` changed XID report byte 2 from `00` to `01`; the AOT guest input predicate under parent `0x000E081F` returned 1, and edge-consumer transition 2 at tick `47056359` changed copied cell `0x004AFC08` from 0 to 1. The subsequent release consumed transition 3 at `0x000DF7F0` and returned the predicate to 0. The last long press also reached XID at ticks `47115531`/`47121531`, but no subsequent pilot-list callback was recorded.

The current Steel Battalion USB profile maps host A to `RightJoyMainWeapon` in `usb_gamepad.c` (`standard[4]` to Steel report byte 2 bit 0); r469’s received byte `0x01` is consistent with that control. The known pilot-row handler remains `sub_000E1820` (call return `0x000E18D8`, active branch `0x000E193B`, row action `0x83` at `0x000E19CF`). r469 emitted zero `[PILOT-LIST-CB]`, `[PILOT-ROW-POST]`, `[MENU-RESOURCE]`, and `[LOAD-STATE-CB]` records. Thus the visible prompt and delivered edge do not establish that the pilot-row handler ran. The input-to-row route remains unverified; this is not evidence of a loader failure.

## Dump review and independent rendering evidence

The captured same-host minidump contains 44 threads. Exact r461 EXE/PDB/MAP were used for x64 unwinding:

- TID `37176`: frame 0 is in `ntdll`; the only recovered caller is `KERNELBASE` then `xbox_KeWaitForSingleObject+0x29` (MAP-relative host offset `0x64AA6E9`). StackWalk then reached non-module value `0xF74`; this is not a validated guest call chain and does not identify the waited-on object or producer.
- TID `34872`: PC maps to `nv2a_ack_thread+0x8C` (native module offset `0x649E65C`). The watcher logged repeated first-chance `0xC0000005` events at this native thread. The dump did not provide a valid unwind beyond frame 0, so the accessed address/operation and whether this thread explains the screen state remain unverified.
- TID `17896`: recovered frames include `watchdog_wait_with_progress+0xA7`; it is the progress watchdog waiting, not the guest loader.

The dump supports a host wait in the game thread and a faulting PC in the NV2A acknowledgement thread, but not a causal link between them. Guest stacks were not enabled. Do not treat raw stack values as unwound guest frames.

Rendering was unusually expensive in this run: sampled `[RASTER-PERF]` windows reported 4,020–4,258 triangles and 5,443–5,649 aggregate raster-active milliseconds across four workers, with 1,470–1,526 ms total batch wall time in the respective sample windows. This makes rendering backlog a live candidate for overall responsiveness, but no matched frame-completion timeline proves it caused the title prompt or the host wait. The main rasterizer remains untouched.

DCF4 samples include wait/return cycles; sample `wait-DCF4[64]` returned with guest signal 1 and fence at target. No DCF4 callback arguments/branches were traced in r469, and the final wait state at stop is unknown. This does not clear the historical title DCF4 issue. There were no loader callbacks, file-completion traces, or writes to `0x0051E078`; the post-difficulty loader and its `0x3FFF` poll remain a separate candidate from r463/r465.

## Hypothesis and disposition

Tested hypothesis: the current r469 stop is the post-difficulty loader dependency. Rejected for this run: the visible frame is still the title player-record prompt, loader callback counters are zero, and the guest ready byte `0x0051E078` watch recorded no write. The first reproducible blocker in r469 is earlier: the new-pilot input route did not reach the known row handler. Evidence confirms XID delivery and a guest edge only. No gameplay fix is supported.

## Next discriminating action

Before another run, inspect the exact native disassembly around `nv2a_ack_thread+0x8C` with the matching PDB and recover the exception access details if the dump allows it. The control mapping itself is present: host A maps to the on-screen `MAIN WEAPON` control. Compare r469’s three actions and title object/timer progression with the known-good r69 screen/input trace, then replay the verified progression one observed screen at a time with bounded framebuffer/callback capture. Do not change guest state, force synchronization, seed `0x0051E078`, or modify AOT/game behavior from the current evidence. The next accepted milestone remains a visually verified first-mission frame.
