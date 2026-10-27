# Steel Battalion global write watch — r108

## Outcome

r108 reproduced the screen-gated route through the title screen, Campaign, pilot list, and new-pilot name editor. It did **not** reach `NOW LOADING` or the first mission frame. A hardware data breakpoint captured the earlier initialization of guest global `0x00311CC8`, but this run did not observe its later transition to zero. Therefore it does not identify what clears the object pointer seen as null in r107.

The diagnostic was stopped after the pilot editor remained the active screen through several minutes of live-input attempts. Only the exact process launched for r108 was stopped. Its input transcript and logs were preserved.

## Run identity

- Run: `m3-global-write-watch-r108-20261027`
- Diagnostic PID: `131792`; exact executable path was rechecked before stop.
- Executable SHA-256: `20FD6B08C769CC529E6F5F47E7128D92FDE5BC31427B767E6834C01FADDA1345`
- Matching PDB SHA-256: `18C54073CB87BE0C5D21C8A2B4871F1B3A9A04D4458C2931B1B50520D797537F`; the matching map places RVA `0x612597` inside `sub_0001DAA0` (function start RVA `0x6122C0`, next function RVA `0x612680`). This is the same guest helper that performed the earlier mode-0 initialization in r107.
- AOT generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
- Save root: `iso/local-analysis/saves-m3-route-file-read-copy-20261023`
- Helper: `local-tools/GuestWriteBreakpoint.exe`, built from `tools/GuestWriteBreakpoint.c`; helper SHA-256 `C6BC227B18BA3098A14D33F3C14B6F43BD3F4376EC5CC8BB88D96D49BE3098D3`
- Watch: guest VA `0x00311CC8`, runtime memory offset `0x10000`, host VA `0x0000000000321CC8`
- ASLR module base observed while running: `0x7FF752FA0000`
- Framebuffer captures: title, Campaign, pilot list, and name editor. Latest in-game frame is `iso/local-analysis/logs/m3-global-write-watch-r108-20261027/frame.bmp`.

## Hardware-breakpoint evidence

The debugger attached shortly after launch and armed the same hardware breakpoint slot (DR0) on 49 guest-process threads, including subsequently created threads. The one hit was:

```text
WRITE tick=376308906 tid=131724 old=00000000 new=48000078 native_rip=00007FF7535B2597
```

The native instruction address is module RVA `0x612597`, within AOT function `sub_0001DAA0`. It corroborates the r107 observation that this helper initialized `0x00311CC8` to `0x48000078`; generated source has one direct absolute store to that global at `recomp_0000.c:63445`. No later write to the watched DWORD was observed before PID `131792` exited. The debugger reported a process-exit event; the producer-trace relay reported zero dropped lines and a stopped writer.

The watch avoided PAGE_GUARD and did not patch guest code or data. It started after process creation, so it cannot exclude a write before attachment. It monitored writes to this aligned DWORD only; it did not detect reads or writes to neighboring globals.

## Route and telemetry

The display reached Campaign and then the pilot list with `LIST AS NEW` selected. It entered the new-pilot name editor and remained there. r108 recorded 105 XID reports, 105 XID DMA rows, 34 edge-consumer records, 26 input-predicate rows, one pilot-row post-action, and 65 pilot-list callback rows. The final frame shows an incomplete name-edit screen, not the loading screen.

The process emitted 6,114 DCF4 callback rows, 250 NV2A tick rows, and 339 raster-performance windows while it was active. These counters establish continued graphics/event activity during the menu route; they do not identify a loading dependency. The loading probes were not reached: zero load-state callback, scheduler-gate, file-preload, file-call, and load-pass records.

The run reached about 4 FPS in the menu. No loading-stage or mission-performance conclusions can be drawn from it. The ISO, generated AOT code, controller mapping, guest fences, and rasterizer baseline were not modified. No missing indirect target was seeded.

## Files and follow-up

The five retained desktop captures are in the run directory. Sixteen repeated desktop captures (20,409,990 bytes) were moved, not deleted, to `C:\Project\SteelBattalion-Delete-Later\workspace\iso\local-analysis\logs\m3-global-write-watch-r108-20261027`; `moved-captures.csv` records their hashes.

The run harness now has an opt-in hardware-write watch and a 300-second UI plateau watchdog. The UI watchdog compares the captured framebuffer and live-input transcript, revalidates the launched executable path, and stops only that run’s child. The PowerShell file parsed cleanly after the change; the new UI-watchdog branch has not yet been exercised.

Next: correct the pilot name-editor route using the saved successful input/frame sequence, then repeat the new-pilot route with the same hardware watch. Continue to preserve full AOT behavior. Stop the investigation at the first verified mission frame; until then, distinguish the menu-route failure from r107's loader gate, the TEX00 cache candidate, and the historical DCF4 wait.
