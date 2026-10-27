# Steel Battalion r78 AOT pilot/loading trace (2026-10-26)

## Run identity and scope

- Run: `m3-dcf4-producer-r78-20261026`
- Process: PID `111756`, `your_game_recomp.exe`; still active at the time of this note. This PID is the current r78 game and has not been terminated.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r78-low-overhead-dsound-watch-20261026/Release/your_game_recomp.exe`
- SHA-256: `A726F81957B2EEADF23DC42D3EFDB402B9B7D816EA5AA129EAE3A279BD17B254` (recomputed from file).
- AOT generated source directory: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; manifest records hashes for the linked generated units and `recomp_types.h`.
- Save root reused in place: `iso/local-analysis/saves-m3-known-save-copy-20261023`.
- Trace: `iso/local-analysis/logs/m3-dcf4-producer-r78-20261026/stderr.log`; separate wait trace and periodic framebuffer captures are beside it. Trace output mode is bounded asynchronous relay, queue capacity 32,768 lines.
- Environment records producer/callback target, file lifecycle/read/caller/I/O/copy, thread/preload, pilot/menu/input, guest fence, DCF4, semaphore, and raster performance diagnostics enabled. Generic kernel trace budget is zero; this is not evidence of a missing trace because the dedicated probes above are enabled. Generated-source snapshot probe is enabled but has emitted zero `[SB-SNAPSHOT]` records.
- r78 is a diagnostic-only candidate relative to r77: DSound writer-watcher rescan 250 ms and one `[DS-WATCH-ARM]` record per armed thread. The AOT game, controller mapping, guest fence behavior, and existing rasterizer baseline `1ea1871` were retained. No gameplay fix, seed, or code injection was made during this run.

## Screen and pilot callback correlation

The periodic framebuffer capture at `frame.bmp` shows the text `NOW LOADING` on a black background; no mission image is present. Earlier captures in this run show the campaign, pilot list with `LIST AS NEW` highlighted, name-entry screen containing `A`, date `01/01/2002`, confirmation `YES`, and normal difficulty. This is visual correlation from sampled frames, not per-input-frame capture.

The new-pilot row callback is correlated with the visible pilot-list path:

- The XBE string `LIST AS NEW` is at guest VA `0x0026AF04`, resolved from row item `0x002E4C34`.
- Generated `sub_000E1820` logs the row callback at guest site `0x000E18D8`; row branch is `0x000E193B`, owner/index `8`, table `0x002E5A88`, selected row `0`, item `0x002E4C34`.
- A screen-gated input delivered report byte 2=`01` through XID to guest DMA VA `0x01081763` (bus `0x81081763`). At tick `315807437`, edge handling copied `0` to `1` at `0x004AFC08`, through path-table entry `0x48DF8[6] -> 0x48CBB`; predicate at `0x000E18D8` returned true, and the row callback recorded action `0x83` and item `+0x28` changing `0x3F800000 -> 0`. The later capture shows name entry.
- `[MENU-CALLBACK-GATE]` rows at the visible route skip `sub_000E0870`; that function remains an uncorrelated candidate, not the observed list handler.
- Current log emitted 389 `[PILOT-LIST-CB]` rows and one `[PILOT-ROW-POST]`; the callback guard is 512, so this probe did not reach its cap.

Input limitation: the diagnostic source does not emit `[SB-SNAPSHOT]` in this run (0 rows), so the raw XID report through DMA and guest edge/callback is evidenced, but any intermediate snapshot/copy stage is not. Input-to-screen association uses periodic framebuffer captures rather than a same-tick capture.

## Loading evidence

Before the controlled probe below, at tick `316545640`, main guest thread TID `68004`, caller `0x0018E758`, opened source `D:\media\BIN\TEX00.BIN`, mapped to the user's extracted game files; host handle `0x12A4` received only a file metadata query (class `0x22`) at tick `316545656`, then closed. That host-handle/path interval has no content read. The trace reuses guest handle tokens across opens, so correlation uses host handle plus timestamp and path, not token alone. At tick `316545890`, the same guest thread/caller attempted `Z:\TEX00.BIN`; the save-root `Cache\TEX00.BIN` open returned `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`). Repeated misses continued until the controlled copy. Source size is 702,976 bytes; no game-originated file-copy/write completion for TEX00 was recorded.

The loader is not parked inside a blocking file wait in these samples. `sub_000C319A` (return site `0x000C319A`) repeats the paired-open/compare resource scan. Latest sampled `[LOAD-PASS-OUT]` is pass 220 at tick `316993546`, mode 2, indices 2..11, last index 28, branch `scan`, result 0, pair `0x011E2E00/0`, unchanged from old pair `0x011E2E00/0`. No progress change is visible. Latest framebuffer remains NOW LOADING.

The initial trace identifies missing `Z:\TEX00.BIN` as the first observed unresolved cache object in this repeated resource scan. It does not establish the sole stall cause; the controlled probe below tests the effect of a byte-identical cache copy.

## Graphics and synchronization telemetry

DCF4 callback execution and producer markers continue advancing during the loader scan: latest observed callback indices 1/5 select `0x00216EC9` / `0x0021701E`; producer rows show both `stage=written` and `stage=pfb-flush-return`; frame/counter/semaphore fields advance. Sampled DMA PUT/GET pointers catch up (for example `0x13BE8/0x13BE8` and `0x17670/0x17670` in earlier samples). This does not reproduce the historical terminal DCF4 wait in r77; it does not show a sustained DMA backlog.

At indirect call site `0x00217029`, guest slot `0x0025D1E8` consistently resolves to `0xFE000108`. The generated code accepts this `0xFE000000 + slot*4` synthetic kernel-thunk range; it is a valid bridge target and should not be seeded as game code. Target trace cap is 1,000 calls and logging is sampled (first four, target changes, and each hundred); 14 rows have emitted, all showing the same target. Exact Xbox ordinal/API name remains unresolved.

Raster telemetry shows severe work cost: recent two-second windows report 27–49 batches and 56–102 triangles, about 2.0–3.2 s batch wall time and 7.8–12.2 s summed raster-active time across four workers. These counters demonstrate expensive raster work, but there is no per-worker identity or pending-queue depth. They cannot establish that rendering backlog causes the loader's unchanged resource state. The traces distinguish continuing DCF4/frame progress and severe raster cost from the repeated loader scan, but causal interaction remains open. The 60 FPS target is not met; the window has reported 0.0 FPS.

## Trace counts, caps, and limitations (latest observed scan)

- `DCF4-CB`: 7,947 rows at the previous scan, source guard 100,000; no cap hit.
- `SB-DCF4-MARKER`: 7,744 rows; source guard 100,000; no cap hit.
- `SB-DCF4-THRESHOLD`: 3,872 rows; still advancing; no evidence of cap exhaustion.
- `LOAD-PASS-IN/OUT`: 220 each; source guard 8,192; no cap hit.
- `LOAD-HELPER-BRANCH`: 3,528 at previous scan; source guard 8,192; no cap hit.
- `FILE-CALL`: exactly 6,000; source emits only while `n <= 6000`, so this cap is reached and later call rows are absent.
- `FILE-LIFECYCLE-OPEN/CLOSE`: 10,538 / 10,325 at previous scan; 50,000 per-type cap; no cap hit.
- `FILE-IO`: 6,421; 8,192 cap; no cap hit at that scan.
- `[READ]`: 6,953 emitted; all-reads mode logs each request through 30,000 then every 1,000; no evidence the sampling cap is reached.
- `PILOT-LIST-CB` 389 / cap 512; `PILOT-ROW-POST` 1.
- `SB-CB-TARGET`: sampled records, call cap 1,000; 14 rows emitted through sampled logging.
- `FILE-COPY-ENTER/RETURN`: 21/21; these do not carry path names and cannot be attributed to TEX00.
- `[GUEST-FRAME] kind=wait-DCF4`: 3,895 rows; emitted as repeated wait/callback frame evidence, not proof of a terminal wait.
- `[SB-SNAPSHOT]`: 0 rows; raw-to-snapshot stage remains unverified.
- Latest trace directory contains a ~61 MB stderr log and periodic 0.92 MB framebuffer BMPs. Keep the run evidence until diagnosis is complete; no cleanup was performed.

## Current result and next diagnostic step

Verified: the new-pilot route reached the visible loading screen, and its screen-gated selection input is correlated through XID delivery, guest DMA, edge transition, predicate, and row callback. The current loader repeatedly scans with unchanged progress after a missing cache open for `Z:\TEX00.BIN`; producer/frame synchronization continues. Raster work is very slow but queue backlog is not measured.

Unverified: first mission frame, successful TEX00 cache population/read, precise root cause of missing cache entry, snapshot-stage input handling, complete native thread stacks/worker mapping, raster queue depth, 60 FPS, and exact identity of synthetic thunk `0xFE000108`.

No fix is justified yet. Continue passive observation of this existing process/run until a first mission frame is captured or the trace fails/proves no progress. Do not close PID 111756 without explicit authorization. If it remains in this state, the next useful evidence is a native thread-state/stack snapshot plus cache-write/file-copy provenance for the loader's required resources, without changing emulated behavior.

Follow-up observation at 2026-10-26 21:34 CDT: PID 111756 is still alive. Latest screenshot remains a black loading frame with the small loading indicator; no mission frame. The repeated scan reached pass n=258 at tick 317066140, still result 0 with pair `0x011E2E00/0`; `Z:\TEX00.BIN` again returned `STATUS_OBJECT_NAME_NOT_FOUND` on the same loader thread/caller. Raster window at tick 317065968 remained ~2.11s batch wall / 8.15s summed worker active. Continue leaving this process open; do not alter loader/cache behavior. First mission frame remains unverified.

## Controlled TEX00 cache probe (after initial report)

The r78 thread and trace continued after the prior report; PID 111756 is still active. Review of the actual file-copy worker records corrected the earlier limitation: worker TID 99948 did have path-correlated copy traces. It completed 17 `D:\media` → `Z:\` copies (nine `STRM00..08.WAV` and eight BIN files including `TEXOBJ.BIN` and `TEXMOVIE.BIN`), each with `FILE-COPY-RETURN result=1`. That list did not include `TEX00.BIN`. The cache directory likewise lacked TEX00 before the probe. `TEXOBJ.BIN` source and cache were byte-identical (47,159,808 bytes; SHA-256 `70770E70991737D28898BABF814DD603AFD9E085D740F3A64BB24FB37BFB7C7A`), validating the copy pattern for one comparison asset.

As a reversible runtime diagnostic, I copied the extracted source `game_files\media\BIN\TEX00.bin` into the ignored save-cache path `saves-m3-known-save-copy-20261023\Cache\TEX00.BIN`. Source and copied file both measure 702,976 bytes, SHA-256 `F728F66092482F17115A0A5E6C941F9AF9AC3C91D475435495ABC3BC732D11E1`. The original ISO and source extraction were not modified. The game subsequently opened both `Z:\TEX00.BIN` and `D:\media\BIN\TEX00.BIN` successfully (first observed tick `317269984`), but it issued only the loader's open/metadata probes; no read/copy completion for TEX00 was observed. Passes continued returning 0 with pair `0x011E2E00/0` unchanged (latest observed pass n=449 at tick `317438453`), and the framebuffer remained NOW LOADING. Thus missing cache TEX00 was a confirmed unresolved input before the probe, but supplying it did not clear the loading state; it is not the sole cause. Keep the 703 KB cache copy in place while this run is active; do not remove it while the process could still be using it.

The main guest thread TID 68004 repeatedly enters `sub_000C3020` from caller return `0x00102063` approximately every two seconds (mode 2; logged state `0/0/0`), returns via `0x000C32D6`, scans indices 2..11 and through index 28, and sleeps between scans. This confirms an active polling loop rather than a thread blocked waiting for the TEX00 file open. At the same snapshot TID 68004 was in Windows `Wait/UserRequest`; four other process threads were `Running` and accumulated most CPU time (TIDs 111456, 111588, 110472, 69244). Windows CIM did not expose their native start addresses (`0`) and no WinDbg/CDB/ProcDump command was installed, so their native stacks and mapping to raster workers remain unverified. Existing guest `[LOAD-STACK]` records are available for the initial pass only.

The DCF4/frame/semaphore traces continue advancing; this is still distinct from the historical DCF4 terminal wait. Raster windows remain expensive, but no worker queue depth is available and the cache probe did not establish rasterization as the loader cause. Current root cause remains open. Next evidence should capture the state and indirect callback targets at `sub_00101A60` call sites `0x00102017`, `0x0010203A`, `0x0010205A`, and `0x0010208A` during this polling loop, then identify what condition prevents the update object from leaving NOW LOADING. Do not change gameplay/fence/rasterizer behavior without that evidence.

## 2026-10-26 callback-state trace preparation and latest live check

The user authorized terminating PID 103904 only. A process lookup found no PID 103904, so no process was terminated. PID 111756 remains the separate r78 diagnostic process and was left running. Latest live stderr records show pass 607 at tick 317743546, still mode 2 / branch `scan` / result 0 with unchanged pair `0x011E2E00/0`. It successfully opens both cache `Z:\TEX00.BIN` and source `D:\media\BIN\TEX00.BIN`; no content completion is evidenced. DCF4 threshold/frame values advanced between ticks 317739703 and 317743562. Raster windows still show high cost: 48 batches / 100 triangles / 3.08 s batch wall / 12.09 s summed active at tick 317740812, then 29 / 60 / 2.06 s / 8.02 s at tick 317742906. These current records continue to distinguish the polling loader state from a terminal DCF4 wait; they do not establish raster backlog as causal.

Prepared opt-in AOT callback/state instrumentation in the ignored generated `recomp_0005.c` around all ten indirect-call sites in `sub_00101A60` (guest sites `0x00101E6B`, `0x00101E8B`, `0x00101F70`, `0x00101F90`, `0x00101FF6`, `0x00102017`, `0x0010203A`, `0x0010205A`, `0x0010206B`, `0x0010208A`). It records chosen branch, indirect target, EAX result, and before/after mode, phase, gates, progress/status words, object word, ESI/EDI; runtime logging is opt-in via `RECOMP_LOAD_STATE_CALLBACK_TRACE=1`, capped at 8,192 records. Added build-source marker checks and `-EnableLoadStateCallbackTrace` to the run harness. PowerShell parsing, source-marker validation, and `git diff --check` passed. The instrumentation has not been compiled or emitted in a runtime trace. No behavior, indirect target, seed, guest fence, controller mapping, or rasterizer code was changed. A side-by-side build/run is still pending; preserve PID 111756 and its measurement interval. The first mission frame and loading cause remain unverified.

## Native thread snapshot and r79 callback-state candidate (2026-10-26)

A thread-info minidump was captured from live PID 111756 at 2026-10-26 21:47:47 CDT without stopping the process. It is in Windows temp, outside the project: `%TEMP%\steel-battalion-r78-thread-snapshot-20261026.dmp`, 1,050,884 bytes, SHA-256 `53E117EDC7ED761F237A88B23D5D3A83722BF83C8A737DC9C1AF4AD4F85511A6`. The exact image/map/PDB used are the r78 candidate under `ProducerTrace-Candidates\r78-low-overhead-dsound-watch-20261026\Release`; r78 EXE SHA remains `A726F81957B2EEADF23DC42D3EFDB402B9B7D816EA5AA129EAE3A279BD17B254`.

The 37-thread dump's x64 unwind for TID 68004 reaches `ntdll` → `KERNELBASE` → r78 image RVA `0x64A68E9`, which the matching link map resolves to `xbox_KeWaitForSingleObject+0x29`. The unwinder then stops at an invalid return (`0xE2C`), consistent with the custom guest/kernel dispatch boundary; the raw stack scan also contains candidate guest frames but is not treated as a verified call chain. This snapshot is evidence of a wait at one instant, not a permanently blocked file request. TIDs 111456, 110472, 69244, and 42616 have stack addresses that map into the NV2A transform/raster pipeline (`xf_rows`, `xf_rows_parallel`, `s_xf_queue_tris`, `raster_worker`); because raw stack slots are not all unwind-validated, exact worker-to-thread attribution remains a candidate. TID 111588's stack addresses map into the APU DSP path. The dump does not include full process memory, queue depth, or a reliable user-mode stack past the guest bridge.

File lifecycle errors for loader caller `0x0018E758` were grouped across the actual r78 log. The 361 `Z:\TEX00.BIN` misses ended at tick `317267953`; after placing the exact extracted TEX00 asset in the save cache, later source and cache opens succeeded, but no TEX00 content read/copy completion was recorded. Other missing `T:\*.sav` files correspond to save slots and are not established as loading dependencies; a single `Z:\st00_0.rep` failure was at startup. At the latest live observation, loading pass `n=782`, tick `318086437`, still returned 0 with unchanged pair `0x011E2E00/0`; DCF4 `frame=0x1233`, `counter=0x1CF9F`, `target=0x1CF97`, `semaphore=0x1CF91` were advancing. Latest raster windows remain expensive (~2.0–3.0 s batch wall time; ~7.7–11.3 s aggregate worker time). The sampled framebuffer still shows `NOW LOADING`; no first mission frame.

Built a side-by-side r79 callback-state diagnostic candidate from current generated AOT sources, preserving the running r78 image and not changing guest behavior. Candidate EXE SHA-256 `1E4912C18306EA8F105C7DB656F140473750ED945CAFCFC6A19A368FDEE21541`; size 112,354,816 bytes, matching PDB size 41,504,768 bytes. The build linked successfully and contained the `[LOAD-STATE-CB]` format string and all branch labels. The first build invocation's post-build script check failed because it expected `your_game_recomp_diag.exe` / `.pdb` while MSBuild emitted `your_game_recomp.exe` and `your_game_recomp.pdb`; corrected the staging paths in `tools/Build-ProducerTrace.ps1` and staged the built EXE/PDB into the isolated candidate directory. Added `[LOAD-STATE-CB]` to post-exit trace counts and updated `Read-ProducerTraceMiniDump.ps1` to recognize both normal and producer-trace executable names. PowerShell parsing and `git diff --check` passed. Candidate is built but not launched; PID 111756 is still active and was not terminated. The build overlapped r78 briefly, so exclude that interval from performance comparisons. No fix, seed, rasterizer, controller, or fence change was made. Next: run r79 with `-EnableLoadStateCallbackTrace` only after the current live process exits; require emitted callback records to validate target/branch/state; keep stopping condition at first mission frame.
