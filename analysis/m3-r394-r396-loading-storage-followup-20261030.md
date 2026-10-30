# r394–r396 loading and storage follow-up — 2026-10-30

## Summary

r396 used the screen-gated new-pilot route and visibly reached `NOW LOADING` in the guest framebuffer. It did not reach a first mission frame. Mode-2 loader progress stopped at `0x000ABA00/0`; sampled reads succeeded, but file lifecycle/per-handle completion tracing was disabled. The diagnostic then remained in a wait on guest event `0x0021DCF4` without a return for 180 seconds. This confirms a wait in the loading run, but does not prove that DCF4 is the missing mode-2 readiness producer or first file dependency. No game fix or rebuild is justified by these traces.

The previous r394/r395 closed-evidence cleanup reclaimed **5,021,696 allocated bytes**. A further exact duplicate cache set was identified, but the automatic execution review rejected the file removal command. No cache file was deleted. The project remains about 38.67 GiB allocated.

## Review inputs and run identity

The handoff in `analysis/project-review-and-luna-high-handoff-20261027.md` and completed reports through r393 were reviewed before r396. r150/r151/r153 were already unwound with their exact r149 binary/PDB in the r386–r391 review; they did not reach the loader. r154 was not running when the process inventory was checked. No other game process was active at r396 launch or stopped during this work.

Run `m3-3fff-screen-gated-writer-r396-20261030` started as PID 19912 at 2026-10-30 01:09:42 CDT. The runner stopped only that PID at 01:18:47 CDT after 180 seconds without a DCF4 wait return. The helper process attached to PID 19912 exited after its target stopped.

- AOT EXE: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/m3-tdataroot-isolation-r367-20261029/Release/your_game_recomp_producer_trace.exe`, SHA-256 `037E8DE482ABB57BDD33B6D36E6FF65B0925CA35E371E51BD53AC763BB26A760`.
- Matching PDB SHA-256: `0D05E2F2A699D0BF9E7AD5D30CA4EB9FA26F2CB74341E33D3437EEC3DB9E41A5`.
- Matching MAP SHA-256: `D3FC42DF4EA0028D052C35911548B585F38970FB19D50695B5D924E8C8601FD8`.
- Generated source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; `recomp_0004.c` SHA-256 `AECF7130AD3E02B7D53CE078F5A3835E0D43448A1321565CDB13AE06776F7CD8`; `recomp_0015.c` SHA-256 `60E50CF36735E871B985EFFED45BF3F0AA0D9522AB8AA919FA930A1B31AFCDC1`.
- Existing save root reused without a clone or hard link: `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`.

## Screen-gated route and input evidence

The route reached the name editor, entered `A`, kept the default birth date `01/01/2002`, accepted YES, selected `HAI SHI DAO 2080 [NORMAL]`, and entered the loading screen. The final retained guest framebuffer is `frame-history/capture-0030.bmp`, SHA-256 `68F412055E78714112013C5936556AD6CCDA0BCBD235D6A9277C652827D0F08E`; it visibly shows `NOW LOADING`. No cockpit, HUD, or mission frame was captured. The host window later displayed a black client area at 0.0 FPS while the guest framebuffer capture remained on the loading image; those are distinct observations.

One screen-gated confirmation of `LIST AS NEW` is time-correlated through the input path:

1. At tick `589278531`, XID report byte 2 became `01` and DMA copied 26 bytes to guest buffer `0x01081763` / bus address `0x81081763`.
2. At tick `589278562`, `sub_000C8064` (parent `0x000E07EC`) consumed the edge: transition 12, copied cell `0x004AFC08=1`, and XID byte 2 was `01`. The predicate returned 1.
3. At tick `589278578`, pilot callback `0x000E18D8` selected branch `0x000E193B`, owner 8, with `input=1`, `xid2=01`, and button cell 1.
4. The same tick, row action `0x83` at `0x000E19CF` changed the selected item field `+0x28` from `0x3F800000` to zero. The subsequent screen sequence entered the new-pilot editor.

This confirms the input-to-pilot-row action for the observed press. It does not establish the behavior of every name-editor control or the full Steel Battalion controller.

## Loader and synchronization evidence

The final loader pass record at tick `589465578`, thread 187972, reported mode 2, range 2–11, helper index `0x1E`, and pair `0x000ABA00/0`. The final load-state callback was at tick `589465906`, still mode 2, with progress `0x000ABA00/0`, gates `1/1/0`, and no status or phase change. This matches the previously observed post-difficulty readiness plateau.

`file-read.log` emitted its first 220 completions and then every 1,000th; the last sampled record was read 11,000 at tick `589465875`. Sampled records have `got=want` and zero IOS, NT, and guest status. This run had file lifecycle, file-open path, and per-handle read-completion tracing disabled; zero `FILE-MISS-PATH` rows therefore cannot rule out an unobserved dependency. No read was tied to a loader object or consuming stack.

The run also reproduced a DCF4 wait during loading. The final wait-before row was tick `589468609`, thread 187972, object `0x0021DCF4`, signal/result still unsignaled, with one batch, four workers, three pending, and no completion bits. There was no later wait-after row. The DCF4 watchdog captured `dcf4-stall.dmp` and stopped the diagnostic after 180 seconds without a wait return.

DCF4 callback records total 4,621. The observed argument-to-target counts were: `arg=00000005` → index 5 / target `0x0021701E` (1,950); `arg=01080021` → index 1 / target `0x00216EC9` (1,332); `arg=03600021` → index 1 / target `0x00216EC9` (1,332); `arg=00000009` → index 9 / target `0x0021707C` (6); and `arg=00000028` → index 8 / target `0x00217053` (1). The last callback was n=4621 at tick `589468656`, thread 187312, arg `0x03600021`, index 1, target `0x00216EC9`.

The sampled producer marker n=1920 at tick `589467156` recorded the DCF4 descriptor write and PFB flush return, with signal 0 and PUT/GET 0. Later NV2A ticks continued while frame `0xA70`, counter `0x852F`, target `0x8525`, and fence `0x852B` remained fixed; the final synchronized NV2A row showed no batches, workers, or pending work and a static last batch `201988`. The final DMA acknowledgement remained PUT/GET `0x6608`; the last semaphore release before the stall stored `0x8527`. Raster cost was high during the transition (last sample: 1,216 batches / 2,432 triangles, 1.477 seconds batch wall time and 5.424 seconds summed worker-active time), but the later static counters do not establish an ongoing rendering backlog as the cause. The loading readiness pair, DCF4 wait, and earlier raster workload remain separate evidence.

### Stack and guest-writer limitations

The exact r367 StackWalk64 pass on TID 187972 from `dcf4-stall.dmp` reached `ntdll.dll+0x161DD4`, `KERNELBASE.dll+0x1BE9F`, and the executable at `+0x64A9A59`, then stopped at synthetic address `0xF34`. This is a partial native unwind, not a validated guest call chain. A separate raw stack-address scan found `xbox_KeWaitForSingleObject+0x29`, `bridge_KeWaitForSingleObject+0x144`, and guest candidates including `sub_00211E10`; those stack-address hits are not treated as unwound frames. The relevant loader consumer, expected producer, and first file dependency remain unidentified.

The guest-write helper watched guest VA `0x82A9BFFC` via host address `0x82AABFFC` and read initial value zero. It logged no data-breakpoint write before the run stopped. Because the observed initial value did not match the older `0xFFFFFFFF` table candidate, and no write hit occurred, r396 does not validate the r382 writer hypothesis. No target was seeded or rebuilt.

## Saves and storage

r396 reused the r368 writable save root; no save clone or hard link was made. `UserData` remained empty and existing `TitleData` saves were retained. Partition image last-write times advanced at process start and `Cache\\COPYCHECK.DAT` changed during the run. No pre-run content hashes were captured for those writable files, so their contents are not asserted unchanged. They have been left untouched since r396 exited.

The r394/r395 evidence transform reclaimed **5,021,696 allocated bytes**, with source hashes checked before and after the lossless transforms. Current r396 run files occupy **4,488,397 allocated bytes / 12,011,389 logical bytes** across 20 files, measured with `GetCompressedFileSizeW`. Its 64 MiB storage budget did not trigger; stderr/stdout relay drops and trace-cap hits were both zero. Framebuffer retention was capped at four: 30 saved, 26 evicted, 2 drops while a frame changed, and the final loading frame was retained.

The audit `analysis/r396-redundant-cache-audit-20261030.csv` lists 22 closed-run cache files whose lengths and SHA-256 values match retained extracted media byte-for-byte. The cache copies account for 178,721,934 logical / 143,407,758 allocated bytes; each file had one hard-link path. The automatic execution review rejected the removal command, so no cache files were deleted and **these are not claimed as savings**. A second exact screenshot duplicate exists: `frame.bmp` and `frame-history/capture-0030.bmp` share SHA-256 `68F412...D08E` and `frame.bmp` uses 16,384 allocated bytes; both remain because the run manifest names the history capture as its final frame and the configured dump path is in the environment/logs.

The reconciled path-summed working set before the new report/manifest/status edits was **41,534,877,698 allocated bytes** and **1,397,141,591,461 logical bytes**, using the r393 inventory plus measured post-r395 changes and exact r396/helper/audit additions. The r393 inventory itself measured 41,527,779,219 allocated bytes including 13 separately measured executable reparse entries; the 2,435,259-byte pre-r396 net increase is reconciled in the r395 manifest. Logical size includes sparse capacity and is not disk usage. The warm game build tree remains 6,918,921,034 allocated bytes. No game rebuild or benchmark ran; the ~9.1-second incremental build figure is historical and unchanged by this work.

## Changes, checks, and next blocker

No runtime code, generated source, input mapping, kernel semantics, guest fence behavior, renderer, or rasterizer `1ea1871` was changed. The local breakpoint helper was compiled from its existing source with installed Visual Studio Build Tools; no system dependency was installed. The verified check for this milestone was the live screen-gated AOT route through `NOW LOADING`, plus exact-bundle dump stack analysis. No game build or test suite was run.

The immediate observed stop is an unsignaled DCF4 wait after the mode-2 loader pair stopped at `0x000ABA00/0`; the evidence does not say which producer failed first or which file/object the loader awaits. Next, add only bounded, per-handle file completion and producer/consumer state evidence around the mode-2 transition, with a genuine thread snapshot at the exact wait. Keep title-stage DCF4, DirectSound-list corruption, raster cost, and loader readiness separate. Do not patch until one cause is supported; stop after the first visually verified mission frame.
