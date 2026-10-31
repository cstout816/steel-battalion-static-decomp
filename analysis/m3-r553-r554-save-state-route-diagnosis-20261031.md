# r553–r554 route and save-state diagnosis — 2026-10-31

## Result

The current saved-pilot route is blocked by the state of the retained save directory. Using the exact r519 executable and the same save root, r554 reached the campaign pilot list, but all eight pilot slots were occupied by records whose 2,792-byte payloads are zero. The new-pilot option displayed the game's full-roster warning. Selecting DATA-000 displayed blank pilot details; attempting to load it displayed `Unable to load DATA-000.`

This is not a reproduced read failure, DCF4 stall, or mode-2 loader plateau. No first mission frame was reached. Saves were not edited, deleted, copied, or replaced.

## Run identity and process handling

- r553: `m3-r553-user00-read-correlation-20261031`, PID 56936, used the existing r551b invalid-wait diagnostic executable. It captured the same `T:\user00.sav` read path; allocated run evidence was 767,433 bytes. Its own diagnostic process was stopped after capture.
- r554: `m3-r554-r513-title-dcf4-20261031`, PID 65252, used the exact r519 AOT bundle and save root. Its own diagnostic process was stopped after the listed-record error was captured. The async relay finalized with zero dropped stdout/stderr lines.
- r554 executable SHA-256: `A52F6D3D3C93DA54B629382BD74A4E3AC1B878FFCA34520163A6FD365907EF84`.
- Matching PDB SHA-256: `6B503653208BE8DD774C42BE6ACEF569F1AD071D3D4B10D74CA77916D5648653`.
- Matching MAP SHA-256: `01FADBED2D9F0F3A09DF4FA05F735B0E4EB082C84F5DD17AB1D16DAD6695E9EF`.
- Both runs used `iso/local-analysis/saves-m3-route-file-read-copy-20261023` in place. No other Steel Battalion process was active after r554 exited. Unrelated applications were left alone.

## Screen-gated r554 route

The retained input log is `iso/local-analysis/logs/m3-r554-r513-title-dcf4-20261031/pad-live.txt`. The retained final framebuffer is `iso/local-analysis/logs/m3-r554-r513-title-dcf4-20261031/frame-history/capture-0005.bmp`.

1. Title prompt; first A showed `Unable to load Player Record.`
2. Second A advanced to the Campaign menu.
3. Third A opened the pilot menu with `LIST AS NEW` selected.
4. A on `LIST AS NEW` showed “The number of pilots you can enlist has exceeded the limit.”
5. A dismissed the warning. `ldown` selected `LISTED PILOT`.
6. A opened the listed records. DATA-000 was selected with blank name, sex, birth date, rank, points, and next-mission fields.
7. A focused COMPLETE; a second A attempted the load and visibly showed `Unable to load DATA-000.`

The UI also offers `DELETE PILOT`; it was not selected because the task requires preserving the current saves.

## File and callback evidence

The save directory currently has `user00.sav` through `user07.sav`, plus `user99.sav`. Each is 2,812 bytes. Inspection found the first 2,792 bytes of each file are all zero; the final 20 bytes vary. The eight `user00`–`user07` paths therefore correspond to the eight occupied pilot slots, while their displayed records are blank.

The focused r554 read trace contains two operations against `T:\user00.sav`, both from guest caller `0x0018E149` and guest handle token `0x48000085`:

| Tick | Host handle | Requested | Completed | I/O / NT / guest status |
|---:|---:|---:|---:|---|
| 127803140 | `0xEBC` | 2,792 bytes | 2,792 bytes | all `0` |
| 127803140 | `0xEC4` | 20 bytes | 20 bytes | all `0` |
| 127936984 | `0xE28` | 2,792 bytes | 2,792 bytes | all `0` |
| 127936984 | `0xE28` | 20 bytes | 20 bytes | all `0` |

The title and DATA-000 record reads both completed fully. This rules out a failed host read/status as the cause of the displayed record error. The second read sequence coincides with the DATA-000 load attempt; its payload is empty, and the UI then rejects the record. Runtime tracing does not yet show the exact validation return and error-overlay conditional, so that specific guest branch remains to be instrumented before any runtime fix.

Generated callback source identifies the pilot-list route as `sub_000E1820`. At `0x000E18D8`, the screen-gated DATA-000 input selected branch `0x000E193B`; the post-callback marker at `0x000E19CF` reported action `0x83`. That marker documents the selected-row callback, not the later record-validation result. r554 emitted 1,460 pilot-list callback records, 23 input predicates, and 17 consumed edges; the capture did not hit the configured DCF4 trace caps. The campaign and pilot-list transitions completed, so r554 does not support attributing this save error to the historical DCF4 or raster wait.

In r550, `user07.sav` was still reported missing in several early `OPEN_EXISTING` probes. Its filesystem timestamp is 2026-10-31 17:41, during r550's 17:38–17:46 run; `user99.sav` was also last-written at 17:41. r550 did not have detailed write tracing, so those timestamps do not establish which operation created or changed either file. They do establish that the current roster state differs from the earlier seven-slot state observed during that run. No file was touched to recreate the earlier state.

## Storage and build impact

- r553 retained 2,715,636 logical bytes / **767,433 allocated bytes**.
- r554 retained 14,019,957 logical bytes / **3,599,577 allocated bytes**.
- Combined retained diagnostic evidence added **4,367,010 allocated bytes** (about 4.16 MiB). Both runs stayed below the 64 MiB per-run budget; r554 kept five framebuffer-history captures and recorded one dropped history capture. The closed-log relay reported no dropped text lines.
- No files were removed or compressed in this investigation; actual disk savings: **0 bytes**.
- No source change or build occurred. Both existing executables were reused, preserving incremental-build caches and build efficiency.

## Next step / blocker

The current save root contains no valid pilot record and all eight slots are occupied. Do not patch the runtime to ignore the game's slot check or to fabricate a record. To resume the new-pilot route, the save root must have a valid free slot or a valid user-supplied pilot record. Because the current instruction is to preserve this save root, the in-game DELETE PILOT option was left unused. After a safe valid pilot state is available, continue from the exact r513 bundle and screen-gate the remaining route. Then trace the record-validation branch if it still rejects a non-empty record, and proceed to the first mission frame.
