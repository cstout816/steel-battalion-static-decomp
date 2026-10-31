# r476–r480 title route, DCF4 wait, DirectSound watch, and storage (2026-10-30)

## Current result

Milestone 3 remains in progress. The first mission frame is **not verified**. No game fix or generated-code change was made, and no build was run. AOT execution, guest fences, controller mapping, and rasterizer `1ea1871` remain unchanged.

Two failure paths must remain distinct:

- **r479, Campaign path:** the screen-gated new-pilot route changed the visible screen from the title prompt to “Unable to load Player Record,” then to the Campaign menu. On the next input, the process exited with an access violation. DirectSound traversal recorded an invalid node: `node=0xFF000000`, `predecessor=0x8038C098`, and predecessor `next/prev/owner=0xFF000000`; the list head remained nonzero. The read fault was Xbox VA `0xFFFFFFF4` (host RIP `0x7FF62DAF5448`). These records establish the malformed list at consumption, but **not the write that corrupted it**. There was no `NOW LOADING`, file-open/preload callback, or loader evidence.
- **r480, title wait:** one title input edge was delivered and advanced through `0x000E0840` to `0x002A6BFA`, but the main thread then stopped making UI progress. No pilot-list callback, DirectSound list failure, or loader callback occurred. DCF4 event handle `0xF28` was unsignaled in the watchdog snapshot, matching guest object `0x0021DCF4`. DMA `PUT=GET=0x0004D4C4`, PGRAPH pending `0`, guest CPU turns `113`, kernel calls `248816`, switches `41`, waits `104`. This is a distinct title-stage wait, not evidence for the post-difficulty loading plateau.

## Exact run and artifact identity

### r479 — `m3-dcf4-title-advance-writer-trace-r479-20261030`

- Run directory: `iso/local-analysis/logs/m3-dcf4-title-advance-writer-trace-r479-20261030`
- PID: `14692` (diagnostic run; exited on its own with `-1073741819`)
- AOT EXE SHA-256: `40FA690382BEE9D0E510A400693B193299092912700B678DAF41A2B3960B8832`
- PDB SHA-256: `94BA09B77C5D1B241EC68479848F00B23316BEC4CC93A2E81492DEAC4A99AEC8`
- MAP SHA-256: `A0C3D2B5E03B5C0FED8C76167BAE846479031BA7E2B327D844679A9AA8DFA8FC`
- `recomp_0015.c` SHA-256: `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`
- Screen-gated input evidence: XID byte 2 reached guest edge cell `0x004AFC08`; the title route advanced from `0x000E0840` to `0x002A6E07`. Live observation reached the Campaign menu. One `MENU-RESOURCE` row references object `0x006B9E1C` and label VA `0x0026AF04` (`LIST AS NEW`), but no retained screenshot shows that row selected. Pilot callback trace had 113 rows and every row selected branch `0x000E18DC` with input 0; no row-post or loader callback.
- DCF4 producer tracing remained active: 1,290 callback rows; index 5 returned through `0x0021702F` and index 1 through `0x00216EC9`. Thus the title DCF4 wait was not reproduced as the terminal state in this run.
- Failure-window trace cap: guest-frame trace emitted 65, dropped 191 after cap 256. Other relevant cap/drop values are in `trace-counts.txt` and `run-manifest.json`.
- The single retained BMP shows the player-record error overlay, not Campaign; Campaign was observed in the live window only. No minidump was captured for this crash.

### r480 — `m3-dsound-link-first-writer-r480-20261030`

- Run directory: `iso/local-analysis/logs/m3-dsound-link-first-writer-r480-20261030`
- PID: `38176`, verified against the exact r461 executable path, captured, then stopped because it remained stalled. No other process was stopped.
- Same r461 EXE/PDB/MAP and generated-source hashes as r479 above. Reused empty save root `iso/local-analysis/saves-m3-newpilot-empty-r366-20261029`; no save copy or hard link.
- Dsound link watch monitored guest words `0x8038C08C`, `0x8038C098`, and `0x8038C09C` (cap 20,000). It emitted nine writes during initial list construction: zero initialization; self-links; then owner `0x010810A4`, next `0x010810B4`, previous `0x803B0C10`, and next `0x8038C4E0`. **None wrote `0xFF000000`**, and the process stalled before the later list traversal. This run therefore does not identify the r479 corrupting writer.
- Captured `ui-plateau-stall.dmp` (1,228,351 bytes) before stopping. The exact-bundle offline unwind for TID `20620` reaches `NtWaitForSingleObject`, `WaitForSingleObjectEx`, `xbox_KeWaitForSingleObject+0x29`, and stops at non-module handle `0xF28`. This is a valid native unwind to the wait; the deeper guest call chain in the watchdog snapshot is an in-process snapshot, not a validated native unwind.
- UI probe counts: 3 edge-consumer rows, 8 input-predicate rows, 0 pilot-list callbacks, 0 menu resources, 0 loader callbacks. No visually verified screen beyond the title-stage transition; no first mission frame.

## Hypothesis status and next diagnostic

**DirectSound hypothesis:** a list link or node becomes invalid between valid construction and traversal. r479 supports the malformed-consumption side; r480 only captured normal initial writes. The writer, exact time of corruption, and whether the same writer runs on the Campaign route remain unknown. A supported next experiment is one exact-r461 AOT run that reproduces the r479 screen-gated route while watching these same three link words through the Campaign transition and preserving a crash dump. Compare the first write whose value becomes invalid with the r479 consumer snapshot. Do not change list semantics until that write and call path are captured.

**Title DCF4 hypothesis:** r480’s thread waited on `0x0021DCF4` with event `0xF28` unsignaled at capture, while DMA was drained and PGRAPH pending was zero. This alone does not establish the missing producer or explain the UI plateau. Keep this title wait separate from DirectSound corruption and from any `NOW LOADING` plateau. No producer/signal forcing or fence bypass is justified.

Before a new run, retain the existing r150/r151/r153 dumps with their exact matching image/PDB and unwind records as prior evidence; do not treat raw stack-address scans as unwinds. The r130 `ObReferenceObjectByHandle` null-output implementation’s completion semantics also remain a separate review item. After reproducing a route, the acceptance target is a visually captured first mission frame. Loader dependencies can only be investigated after the route visibly reaches `NOW LOADING`.

## Storage and changes

- Fresh whole-workspace path-summed measurement after r480: **79,479 files; 39,822,753,979 allocated bytes (37.088 GiB); 1,399,672,470,449 logical bytes (1,303.547 GiB); 13 reparse entries skipped**. C: free space at measurement: `45,559,189,504` bytes.
- r476–r480 closed run trees together: **52 files; 5,207,555 allocated bytes; 11,312,573 logical bytes**. r480 alone: 13 files; 1,900,403 allocated; 3,564,953 logical. These remain because their exact bundles, screen route, watched writes, and failure states are unresolved evidence.
- Reclaimed space this pass: **0 bytes**. No files, saves, ISO contents, caches, source checkouts, or prior captures were deleted, moved, compressed, or compacted. The warm incremental cache is unchanged, so build-efficiency impact is unchanged. Prior deletion/compression actions were rejected; this report does not retry those operations through another route.
- No source/build change. No tests or build were run. The two diagnostic runs used the existing r461 AOT executable. The run folders and exact dumps/logs remain retained.