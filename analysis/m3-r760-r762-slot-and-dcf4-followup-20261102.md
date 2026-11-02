# r760–r762 save-slot and DCF4 follow-up (2026-11-02)

## Current result

The first mission frame remains **0/1**. No loading screen, mission scene, or guest progression into mission gameplay was verified. No game behavior or generated source was changed, and no build or test ran. All three runs reused the same r756 AOT executable, PDB, MAP, generated source, and save root.

| Area | Progress | Evidence |
| --- | --- | --- |
| New-pilot slot availability | [##########] 1/1 | Eight verified blank slot records were moved out of the active title-data directory and preserved with hashes. |
| Screen-gated input delivery | [##########] 1/1 | XID report, guest DMA byte, edge copy, pilot callback, selected branch, and row post-state align at tick 277421890–277421906. |
| DCF4 publication/consumption | [######--------------] 3/5 | One publication and wait return succeeded; the next wait has no matching publication, with an empty callback queue. Cause upstream of that publication remains unknown. |
| DirectSound list writer | [####----------------] 2/5 | r760 reproduces an invalid per-object list read; r761 did not capture a malformed write. |
| First mission frame | [--------------------] 0/1 | Not reached. |
| Storage/build | [##########] 1/1 | Reused candidate; r762 used 4,038,167 allocated bytes across 16 files, below the 64 MiB run cap. No build/cache change. |

## Save-slot change and route

The active save root was `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. Before moving files, the eight `TitleData/43430002/user00.sav`–`user07.sav` records each had exactly 2,812 bytes. For every file, the 2,792-byte pilot payload was verified all-zero; only the 20-byte trailer differed. Their original SHA-256 values and move paths are in `iso/local-analysis/save-rollback/r761-empty-pilot-slots-20261102/move-manifest.json`. The records were moved—not deleted—to `iso/local-analysis/save-rollback/r761-empty-pilot-slots-20261102/TitleData/43430002/`. `user99.sav`, all partition images, and cache assets stayed in place. After the run, no `user00`–`user07` file had been recreated.

This same-drive move freed all eight game-visible pilot-slot file entries but reclaimed **0 bytes**. The rollback directory contains nine files (eight saves plus the manifest), 24,691 logical and allocated bytes. This preserves the originals for restoration.

Run r762 reused PID 99404's verified r756 AOT candidate:

- EXE SHA-256 `03FC192D56C9CF4F33BD7B84A156FE706DB2CB18BD2556C912F284A96C594081`
- PDB SHA-256 `38F1798EC2CF497AF1DC083AC9D044E154C7FC143DDF78A0499C1B74A3A45C44`
- MAP SHA-256 `514D77579EA3C9FD9AB840940C4EA8AA179D574A730964372D8CAC3459A33D76`
- Generated AOT source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
- Save root: the existing path above; no save copy was made.

Screen-gated input continued past the title's `Unable to load Player Record` overlay to the Campaign screen and then the pilot list. The pilot list visibly showed `LIST AS NEW`; selecting it changed the menu item state and the row callback accepted input, but the window then stopped drawing at 0 FPS on a black/partial `LIST AS NEW` frame. It did not reach name entry or `NOW LOADING`.

The final retained framebuffer is `iso/local-analysis/logs/m3-r762-freed-pilot-slots-20261102/frame-history/capture-0005.bmp`, SHA-256 `E4FD59BE7F34E438137C3A7A50718E4C009465F7D5CE18B952AD6BDD0ECAFADD`. It is not a mission image. The run retained 16 files totaling 12,334,099 logical and 4,038,167 allocated bytes. A same-run dump is `dcf4-stall.dmp`, SHA-256 `09B4C3D6FABC4D17A226D506636716779E5391C08DB6BABF9D5411053E1E37DF`. PID 99404 was verified against the exact executable path, dumped, then stopped after the screen and wait state stayed unchanged. No other game process or application was stopped.

## Synchronized input evidence

The accepted pilot-list input has this same-clock chain:

1. At tick `277421890`, XID port 0 delivered a 26-byte report with byte 2 set to `01`. `[XID-DMA0]` wrote byte 2=`01` to guest buffer `0x01081763` (bus address `0x81081763`). The release report set byte 2 back to `00` at tick `277422500`.
2. At tick `277421906`, guest input edge handling copied `0x004B0160:0` into `0x004AFC08:1`. The input predicate at `0x000C8064`, parent `0x000E18D8`, returned 1 for `(1,6,9)`.
3. The active row handler `sub_000E1820` site `0x000E18D8` took branch `0x000E193B` with `owner=8`, selected row 0, and item pointer `0x002E4C34`. The XBE string table identifies that item as `LIST AS NEW`.
4. The row post-state at `0x000E19CF` recorded action 83, `button_cell=1`, `xid2=1`, `flow=0`, and `state=1`. This is a real accepted guest action; it does not establish that the subsequent render/synchronization stage completed.

## Earliest reproduced blocker: later DCF4 wait

At tick `277423796`, the earlier DCF4 handoff completed normally: callback n=3453 on TID 107288 received argument `5`, selecting guest branch `0x0021701E`. That branch calls the guest event function pointer at `0x0025D1E8` with the event at `context+0x1A4 = 0x0021DCF4`. The bridge recorded `set-DCF4` on host event `0xDC0`; `RASTER-SYNC` shows the host event set, and TID 101724 returned from the matching wait successfully at the same tick.

A second wait began on TID 101724 at tick `277423812`. There is no later `set-DCF4` or `wait-after` before the dump. The callback thread continued: n=3454 argument `0x01080021` and n=3455 argument `0x03600021` both select branch `0x00216EC9` (index 1), not the event-publication branch. Gate output `out100` was zero for both. The two-slot queue trace then repeatedly showed `ptr0=0`, `ptr1=0`, `result=0`, and unchanged slot sequences while the sequence counter advanced. The final NV2A heartbeat recorded guest DCF4 signal word zero, raster `batches=0`, `workers=0`, `pending=0`, and no changes to the displayed frame/counter/target/fence values. This separates the wait from rendering backlog.

The dump's validated native unwind for waiting TID 101724 reached `ntdll.dll+0x166464`, `KERNELBASE.dll+0x1427F`, and a host executable frame; it stopped at non-module address `0xDC0`. No guest EIP or guest register snapshot was captured. Treat the queue polling rows as queue evidence, not as a full guest stack unwind. The earlier successful `SetEvent`/wait return rules out a blanket bridge failure, but the missing subsequent guest publication's upstream condition is still unknown. No event was forced, no guest check was bypassed, and no fix is supported.

This is consistent with, but still distinct in exact route and run identity from, the earlier title-stage r747 DCF4 gap. It is not the same as r519's post-resource-`0x1E` loading plateau.

## Separate DirectSound observations

- **r760**, PID 106304, used the same EXE/PDB/MAP. It crashed after Campaign input at `sub_0021ED29+0x88`, reading `ESI+8` where `ESI=0xFFFFFFEC` (guest VA `0xFFFFFFF4`). Caller `sub_0021FE7C` passed `EBX-20` with `EBX=0`. The retained Campaign frame is `iso/local-analysis/logs/m3-r760-watchdog-loader-snapshot-20261102/frame-history/capture-0003.bmp`. This reproduces an invalid per-object DirectSound list traversal; it does not identify the bad write that created it.
- **r761**, PID 108372, enabled the existing DirectSound write watch and stopped on its separate DCF4 wait. Ten watched writes showed node initialization/linking, and the sampled list had valid links. The watch covered three fixed guest words; it did not capture the r760 malformed state or prove all list writes safe. Its DCF4 wait had drained raster work and DMA PUT=GET=`0x4DB8`. Keep this wait distinct from the r760 DirectSound crash and the r762 pilot-list wait.

## Remaining blocker and next action

The route can now see `LIST AS NEW`, but selection stalls before name entry because TID 101724 waits on DCF4 after the queue drains. The precise remaining question is which guest producer condition should enqueue/publish the next event after callback n=3453. Use the matching r762 dump, callback source at `sub_00216EA0` / gate `sub_00217130`, queue consumer `sub_00216B10`, and producer-stage rows to identify that condition before changing code. Do not repeat an equivalent route with unchanged instrumentation. Keep the DirectSound writer investigation separate. Preserve the moved blank files in rollback until the game either successfully creates a new pilot or the original records are restored.
