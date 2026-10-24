# Astra handoff: Steel Battalion AOT pilot input and loading investigation

Prepared 2026-10-24 from local source, generated AOT C, retained logs, binary diagnostic strings, and upstream release/PR pages. The initial review was read-only; the later r9 appendix records a screen-gated run of the existing diagnostic executable. No game code, AOT translation, controller mapping, graphics behavior, guest synchronization, or save contents were changed. No root cause is established.

## Establish the three separate observations

1. **Pilot list:** `m3-known-save-route-v19-screen-gated-20261024` reached `LIST AS NEW`. Its configured `UserData` is empty. The game's `UDATA/43430002` directory has only `SaveImage.xbx`, `TitleImage.xbx`, and `TitleMeta.xbx`, not a pilot-slot payload. Local `kernel_path.c` maps `U:\` to `<RECOMP_SAVE_DIR>/UserData`; the hard-disk partition-1 title-metadata path maps through the game directory. This is a new-pilot input/state investigation, not evidence of a failed saved-pilot load.
2. **NOW LOADING:** the separate `m3-first-level-cs-watch2-20261023` route created a new pilot and reached loading. Project records report very heavy CPU raster work, roughly 0.43 guest FPS, 334,778 triangles and 1.68 billion pixel writes. Treat these as historical aggregate observations; they do not locate the blocked loading task or establish a growing worker queue.
3. **DCF4 wait:** `m3-first-mission-writewatch-20261024` stopped at Campaign, before loading. Recorded state was frame `0xEC`, counter/target/fence `0x403/0x3F7/0x3FF`, DMA PUT=GET=`0xBEA0`, callback count 294, and DCF4 clear. Its last raster window was 113 batches/226 triangles, 44.81 ms wall and 146.90 ms summed worker-active. These are different runs and stages.

The v19 pilot-list sample instead had DCF4 signaled, callbacks through 478, DMA PUT=GET=`0x5D240`, and advancing semaphore/frame state. Neither DCF4 failure nor raster overload is established as the cause of that menu stop.

## First make diagnostic coverage provable

- The local toolkit is `v0.13.1-dirty`, HEAD `193e2995ffaec871bb3be43a43bd66aa5fccfeb1`. Preserve its patch set and record generator/runtime commits, XBE hash, executable hash, matching PDB, generated-input directories, actual child-process environment, save root, and framebuffer stage per run.
- The build cache selects `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`, not the default generated directory. Check the configured build inputs before editing another generation.
- That generation's `recomp_types.h` lines 395–400 currently define `RECOMP_TRACE_ENTER`, `RECOMP_TRACE_EXIT`, and `RECOMP_TRACE_ESP` as no-ops. `RECOMP_TRACE_ARGS`, `RECOMP_TRACE_DEREF`, or a runtime filter cannot activate hooks compiled this way. `tools.recomp --trace-functions FILE` exists, but confirm both emitted callsites and effective macro definitions, then demonstrate an actual trace record in the rebuilt diagnostic executable.
- Dedicated menu instrumentation already exists in `recomp_0004.c`. Its logger checks `RECOMP_MENU_STATE_TRACE` and shares a **2,048-record** limit across its sites. The retained v19 environment enables that flag, but v19 `stderr.log` has **zero `[MENU-STATE]` records**. The currently stored diagnostic and ProducerTrace executables contain the menu-trace and producer-trace strings; that does not prove those exact bytes ran historically. Verify run identity, trace activation, and callback reachability before treating absent rows as evidence.
- The old persistent DCF4 run's executable predates producer instrumentation, according to the binary/source audit. Its missing producer rows are inconclusive. Another trace recorded 25,872 aggregate callbacks but only 16,384 detailed callback rows. Current producer source raises several limits to 100,000; do not assume a previously built executable incorporates those edits. Record counts and dropped/capped rows explicitly.

## Highest-priority static discovery: find the active pilot callback

Use the existing Ghidra Xbox import, original guest instructions, disassembly xrefs, and translated dispatch table together. Find the object/callback that owns the visible pilot list, then follow its update/selection path. Dataflow through a table is often more useful than another direct-call search.

Fresh static anchors found during this inspection:

| UI/resource anchor | Guest address | Pointer occurrence in the original XBE |
| --- | --- | --- |
| `LIST AS NEW` | `0x0026AF04` | pointer word at `0x002E4C34` |
| `NOW LOADING` | `0x0026A794` | pointer word at `0x002E764C` |
| `.sav` | `0x0026A7A0` | pointer word at `0x002E7648` |

These are string/data anchors, not proven handler entries. Follow references to the containing tables and their indexed consumers. The generated C reads the NOW LOADING pointer in `sub_000F68F0` and `sub_000F734B`; guest sites include `0x000F7829` and `0x000F811B`, followed by text-draw calls. Work backward from the screen renderer to its owning state/update callback. Check function/alias boundaries against guest instructions before classifying the two generated bodies as independent behaviors. The `.sav` pointer has numerous consumers and may help connect enumeration/creation to the pilot state.

At runtime, record the active UI object pointer/type, callback slot and guest target, selected item/index, menu mode, and registration/activation/deactivation. A callback that is registered but absent from the AOT dispatch table is a discovery lead; one that is never selected is a state-flow lead. Distinguish them.

## Trace the input consumer, not only transport/pollers

Existing evidence proves host Main Weapon/A reports can reach XID DMA and return positive from some guest predicates. Callers `0x000E18D8`, `0x000E290B`, and `0x000E2D10` are per-object update routines, not established pilot-selection consumers. `sub_000E0780` at the `0x000E081F` query is the title-prompt handler; do not reuse title success as pilot-menu acceptance evidence.

`sub_000E0870` is an existing **candidate**, not a confirmed pilot handler:

- It takes an object pointer, reads an index from that object, bounds it by `0x36`, reads a state byte at `0x000E1794 + index`, then selects an 11-entry table at `0x000E1768`.
- In one branch, global `0x00687484 == 2` gates calls to `sub_000C8260`, `sub_000C8290`, and `sub_000C82C0`. Their input tuples passed to `sub_00048B80` are `(1,6,9)`, `(1,6,8)`, and `(1,6,1)`. Determine the tuple semantics from code; do not assume all are Main Weapon.
- The first two positive helpers take a different branch and write latch `0x0066658C = 0`; the third positive helper writes the latch to 1 and reaches `0x000E0934` and setup `sub_00191864`. The corresponding helper return sites are `0x000E0912`, `0x000E091F`, and `0x000E092C`; a setup return site is `0x000E096A`.

Log the actual branch and before/after state at those points, including object pointer/index, selected case, helper return, latch, and globals `0x00687484`, `0x006BA354`, `0x006715D8`, and `0x006BA3A0`. If this candidate is not active at the pilot screen, follow the observed callback instead.

Connect one input end to end: host input sequence -> XID report/DMA completion -> guest input snapshot -> edge/hold/repeat/consume logic -> active callback -> selected branch -> state/object change -> next framebuffer token. Observe press, release, and at least one subsequent guest update. At low guest FPS, a host-time pulse alone does not prove an input update observed it. Use one screen-gated action at a time, with no fixed-time route script.

## Targeted AOT function discovery

Inspect `tools/disasm/{disasm.py,functions.py,xrefs.py}`, `tools/func_id/vtable_scanner.py`, `tools/seed_from_log/__main__.py`, and `tools/recomp/icall_feedback.py` in the local toolkit. The existing hand-maintained seed file is `analysis/steel-battalion-xbe-function-seeds.json`.

1. Capture indirect-call **site and target**, callback registration arguments, thread start routines, object/vtable/slot, guest registers/ESP, and resolution outcome around pilot activation and loading. Cover rejected non-code targets as well as unresolved code targets; the generated macros have separate paths, and both can return zero without executing the intended guest callee.
2. For observed missing targets, validate the actual guest bytes, instruction boundary, containing section, body/control-flow ownership, and calling convention. Distinguish true entries, shared tails/interior continuations, jump-table data, and corrupted pointers. Do not seed arbitrary constants or every address from `identified_functions.json`.
3. `tools.seed_from_log` supports `--dry-run`, `--functions`, `--seeds`, and `--analysis-json`; it checks executable-section membership and probes a body. Treat these as preliminary gates, especially for interior targets. `tools.disasm` supports repeatable `--seed-functions JSON` and `--extra-sections`; select extra code sections from evidence. A `.text`-only pass cannot establish coverage of XDK callbacks in D3D, DSOUND, or XPP.
4. Regenerate disassembly, identification/ABI inputs, AOT C and dispatch entries consistently, and build an isolated diagnostic executable. Trace discovery requires an offline rebuild; runtime target observation does not itself supply a missing AOT body.
5. Compare v0.13.1 with v0.16.0 using the same XBE, seeds, section set, options and fresh caches. Existing local summaries have different method/section coverage: 9,083 functions in the older seeded output versus 7,028 in a newer focused output. Those totals are not a correctness comparison. Diff entries, ends, aliases and dispatch coverage near observed callbacks.

Upstream leads:

- [PR #239](https://github.com/sp00nznet/xboxrecomp/pull/239): discovery of functions after NOP padding, with ordered gap passes.
- [PR #236](https://github.com/sp00nznet/xboxrecomp/pull/236): table entries ending through proven tail exits and separation of byte-index data from code/jump tables.
- [v0.16.0 release](https://github.com/sp00nznet/xboxrecomp/releases/tag/v0.16.0): includes those changes and 16-bit PUSH/POP width fixes. Audit instruction fixes only where the actual path uses them. Its relative RootDirectory save-path change is for POSIX; it is not evidence explaining this Windows empty save directory.
- [v0.13.1 release](https://github.com/sp00nznet/xboxrecomp/releases/tag/v0.13.1): explicitly discusses function-boundary fixes and held callback recovery that could accept data as code. This supports validating seeds rather than indiscriminate discovery.

These are selective analysis/generator comparisons, not a diagnosed Steel Battalion fix or a request for a wholesale runtime update. If a relevant translation defect is identified, run the corresponding generator regression/conformance tests and compare original instructions with the emitted C.

## Diagnose NOW LOADING with progress and dependency evidence

Once the new-pilot path reaches loading, bracket the transition and loader tasks with entry/exit, state/progress fields, work-item IDs, outstanding jobs, and completion/error results. Obtain multiple per-thread CPU/native-stack samples with a matching PDB. Map translated `sub_*` functions back to guest addresses, and corroborate with guest-stack dumps; `tools/stackwalk.py` scans plausible return addresses, so its output requires validation. `RECOMP_WATCHDOG_NATIVE_PC` exists locally. Function-call counts alone cannot identify a function that enters once and spins.

Trace the guest-visible file contract at `kernel_path.c`, `kernel_file.c`, and the **linked runtime** `src/kernel/kernel_bridge.c`: create/open/directory enumeration/read path, resolved host path, handle/RootDirectory, offset, requested and actual bytes, return NTSTATUS, IOSB status/information, event/APC/callback identity, completion and consuming thread. `RECOMP_FILE_TRACE` exists locally, but verify which fields it provides. Do not presume the separate I/O-contract patch or a duplicate bridge source is linked. STATUS_PENDING is not a terminal error; follow completion through the guest's next dependency.

On the same monotonic timeline, record framebuffer token, guest frame/state, loader progress, DMA PUT/GET and ring wrap, semaphore/target, DCF4 reset/set/wait/return, submitted/completed raster batch IDs, **actual queued/in-flight counts**, raster wall time, summed worker time, and producer blocking time. A completed batch, equal PUT/GET snapshot, or active worker total cannot independently diagnose end-to-end progress. If work continues, distinguish loading-animation redraws from loader completion. If progress stops, identify the dependency with an outstanding request and its expected producer.

## If the separate DCF4 wait reproduces

Follow the producer already visible in generated `recomp_0015.c`:

`sub_00211E10` reset/marker descriptor (`0x00040100`, data 5) -> `sub_00211C40` PFB flush request/return -> `sub_00211AB0` ring-space result -> `sub_00211C70` publication/USER_DMA_PUT -> DMA consumption of that descriptor -> PB notification/PGRAPH acknowledgement -> dispatcher payload/branch -> set of the same event object -> wait return.

The PFB helper requests bit `0x10000` at `NV2A + 0x100410` and polls for clearance. The ring-space result below `0x2000` takes a cleanup path; at/above it the code can wait on `device + 0x2564` (event `0x0021DCF4` in the historical capture). Branch 5 at `0x0021701E` signals that event. Match the marker's ring address/bytes and submission sequence across publication and consumption, including wrap/overwrite, not just equal PUT/GET snapshots.

The historical trace had branch-5 callback 292 before reset, then branch-1 callbacks 293/294 without a later event set. It establishes an unsignaled wait, but its absent producer instrumentation cannot distinguish marker publication, flush, consumption, or later state-flow causes. Log the first missing stage and that thread's stack. Preserve guest synchronization semantics.

## Requested result from Astra

Identify the active pilot-list input callback and the first missing transition or loading dependency, citing guest addresses, generated/native source locations, the exact executable/run, and synchronized evidence. Separate verified facts from candidates and trace-coverage limits. Keep AOT recompilation, current controller mapping, guest fences, and existing rasterizer `1ea1871` intact while diagnosing. Do not interrupt an existing user game process or share copyrighted XBE/generated game code/assets.

## 2026-10-24 — r9 title-route input and loading evidence

Run `m3-pilot-loading-trace-20261024-r9-new-pilot` used PID 51292 and the current `ProducerTrace\Release\your_game_recomp_producer_trace.exe` (SHA-256 `0A98A0DCD0B6CA93471293CA668AF4DADC7B47A4A570464D84901CF5AF00540C`). It used generated source `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen` and existing save root `iso/local-analysis/saves-m3-known-save-copy-20261023`; `UserData` remains empty. PID 50696, the earlier Codex-launched ProducerTrace, was force-closed after the user asked not to let it block progress; PID 41760 was already absent. PID 51292 was our own diagnostic and was force-closed after it remained at the title prompt. No unrelated game process was stopped.

The retained frame sequence shows CAPCOM -> Nude Maker -> Dolby -> the title prompt, then remains at `PRESS MAIN WEAPON BUTTON`. The screen-gated input file has 13 actions (A holds of 800 ms, 3 s, 5 s, 10 s, and 30 s plus the earlier splash actions); no fixed route script was used. The 30 s A hold on the visible title prompt produced XID report byte 2 `00 -> 01` at guest buffer `0x01081763` / bus `0x81081763`, then `01 -> 00` on release. In the same input window, `sub_000E0780` reached site `0x000E081F`: `[TITLE-ROUTE-HANDLER] result=1`, object `0x006B9E1C`, id 0, mode 0, gate 0, latch 0. Site `0x000E0840` then logged route pointer `0x006715D8` advancing to `0x001CF258`. This verifies the title callback branch and route-pointer update. The screen did not leave the title prompt afterward; later short A input did not advance the route. Trace lines do not carry a shared tick/thread id across XID DMA, guest snapshots, and the route handler, so they establish ordering within the same action window, not a fully synchronized single-sample proof of snapshot/edge causality.

The `[TITLE-ROUTE-ANIM-CONSUMER]` record at `0x000E281C` identifies object `0x006B9E1C` with id 0 and a changing animation timer. Generated source shows this is in `sub_000E2730`, which updates animation and calls `sub_000E2130`; it is not the pilot-selection dispatcher. The generic `sub_000E18D8` row update remains correlated with the Campaign table, not the pilot list. `sub_000E0870` remains a candidate only. No `LIST AS NEW`, pilot list callback, `NOW LOADING`, or first mission frame was reached in r9.

The historical `m3-first-level-cs-watch2-20261023` run has a retained image (`frame.bmp00050.bmp`) visibly showing `NOW LOADING`, but its environment has no file-open/read completion trace or raster timing trace. It has two native minidumps and stackwalks, but the stack scan is not mapped to guest loader frames and does not identify an outstanding I/O dependency. Its later aggregate GPU report is 336,234 triangles and 1,700,745,846 pixel writes; this shows very heavy CPU-side raster work, not a measured growing queue or the first blocked loader request. Thus the first stalled loader dependency is still unknown. The r9 telemetry shows advancing NV2A ticks/semaphores and no persistent DCF4 wait; the historical DCF4 wait remains a separate run/stage.

No code, AOT target, controller mapping, guest fence, renderer, or rasterizer change was made; no rebuild occurred. The r9 run retained 20 distinct numbered 640x480 captures (~18 MiB) plus its latest frame and logs; none of the captures are byte-identical, so none were moved/deleted. Next: statically trace activation and indirect dispatch around `sub_000E0780`/the object `0x006B9E1C` and route target `0x001CF258`, then run a minimal-capture screen-gated route only after proving the active next callback. Separately, the loading diagnosis requires a run reaching `NOW LOADING` with file completion/IOSB, per-thread guest/native stacks, loader progress, and synchronized raster/event telemetry enabled. Do not patch based on the current traces.

## 2026-10-24 — current-source callback and loading follow-up

### Executable, source, and trace coverage

The current `ProducerTrace` executable is `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace/Release/your_game_recomp_producer_trace.exe`, SHA-256 `0A98A0DCD0B6CA93471293CA668AF4DADC7B47A4A570464D84901CF5AF00540C`, size 112,321,024 bytes. Its build tree pins `RECOMP_GEN_DIR` to `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; the generated menu and input sources are `recomp_0004.c` and `recomp_0001.c`. The current diagnostic source is newer than the old v19 `your_game_recomp_diag.exe` run. v19 used SHA-256 `68AEDF88AFCEED35D79C31C909FE2C1A4C12C7020DCE72628610F1DF3D4EF555`; its zero menu-trace count is not evidence about the current generated code.

In current `recomp_types.h:396-400`, generic `RECOMP_TRACE_ENTER`, `RECOMP_TRACE_EXIT`, and `RECOMP_TRACE_ESP` compile to no-ops. Dedicated AOT trace sites are independent: menu state shares a 2,048-row cap; pilot-list rows cap at 512; input-table rows cap at 512. The source at `recomp_0004.c:125486-125502` emits `[PILOT-LIST-CB]` only when `RECOMP_PILOT_LIST_TRACE` is set. The r1 environment set both menu and pilot-list flags, title input/route flags, XID report tracing, file path/read tracing, DCF4 callback tracing, and raster timing. `RECOMP_PAD_SCRIPT` was unset.

### Visible pilot callback remains unconfirmed

Read-only Ghidra string xrefs locate `LIST AS NEW` at `0x0026AF04`; the pointer table entry is `0x002E4C34`, inside table record `0x002E5A8C`. The string is copied at `0x000CFBFC` by generic `sub_000CF990`. `sub_000E0870` calls that copier at `0x000E0AF6` and `0x000E0C43`, then dispatches an 11-entry state table at `0x000E1768` using a byte at `0x000E1794 + index`. Static call references to `sub_000E0870` come from `sub_000E17D0` and `sub_000E2130`.

The row/input routine is `sub_000E1820`; trace site `0x000E18D8` queries the `(1,6,9)` input tuple and logs owner, row table, item, selected index, and branch. r5 and r7 records show it is a generic row updater: r7 emitted 18 rows while the visible framebuffer showed the Campaign Mission Log, with owner `0x006B9E1C`, selected index 1, row table `0x002E59E8`, and item `0x002E4BBC`. Therefore `sub_000E1820` is not uniquely the pilot-list callback. r5/r7 emitted no `[MENU-STATE]` rows despite the flag, but neither showed `LIST AS NEW` alongside dispatch. The actual pilot-list object and callback have not been identified.

### Screen-gated current-source run r1

Run `m3-pilot-callback-trace-20261024-r1`, PID 51408, used the current executable above, the current generated-source directory, and the existing save root `iso/local-analysis/saves-m3-known-save-copy-20261023`; no saves were copied. It progressed CAPCOM -> Nude Maker -> Dolby -> title prompt. After a screen-gated 30-second A hold, the title screen remained visible. The run was force-stopped because it made no further route progress; only our diagnostic PID was stopped.

Observed counts: 120 `[SB-INPUT-TABLE]`, 78 `[TITLE-INPUT]`, 120 `[TITLE-ROUTE-QUERY]`, 9 XID-DMA records, 220 file opens, 13 expected user-slot file misses, 224 `[READ]` records, 194 DCF4 callbacks, 0 sampled `wait-DCF4`, and 38 raster windows. It emitted 0 `[PILOT-LIST-CB]`, 0 `[MENU-STATE]`, 0 `[SB-INPUT-DISPATCH]`, 0 `[TITLE-ROUTE-HANDLER]`, and 0 `[TITLE-ROUTE-ADVANCE]`. The A report byte 2 toggled in guest buffer `0x01081763` / bus `0x81081763`. Input-table rows under parent `0x000E281C` selected `0x00048CBB` at table `0x00048DF8`, index 6, for `(1,6,9)`; the row logged `xid2=01` while three guest snapshot fields and `raw` stayed zero. A positive predicate at `0x000E281C` updated the title animation timer, but did not change the route. No pilot-list callback ran in this title-only run. These records do not share a single monotonic tick across USB delivery, guest poll, callback, and framebuffer, so they do not prove same-sample edge consumption.

The earlier r7 route is the clean positive title-input sample: XID byte 2 changed `00 -> 01`, table `0x48DF8[6]` selected `0x48CBB`, `sub_000C8050` returned 1 at caller `0x000E081F`, and branch `0x000E0840` changed `0x006715D8` to `0x00170FD1`. r7 reached Campaign/Mission Log but did not reach the pilot list. This title input chain is not proof of pilot-list acceptance.

### Route address and loading-stage disposition

The r9 route field `0x001CF258` is not a missing callback. Saved Ghidra disassembly places it inside the immediate operand of instruction `CMP dword ptr [EBP-0x40],0x3000` at `0x001CF254`, within `FUN_001CF1E0` (`0x001CF1E0-0x001CF7FC`). It is not an instruction boundary, has no direct call reference, and is absent from the current generated dispatch and seed file. At `0x000E0840`, the game reads `0x006715D8`, compares it with `0x101C`, and either updates state or tail-calls `sub_000DF770`; it does not call/jump through the logged route value. Do not seed or rebuild `0x001CF258` as code. Treat the route value's deeper data meaning as unresolved.

No current-source run reached `NOW LOADING`. The 220 opens and 224 read records in r1 are title/startup work; they do not identify a loading dependency. The older `m3-first-level-cs-watch2-20261023` screenshot proves a new-pilot route once reached `NOW LOADING`, but it lacks per-file completion and guest-mapped loader stacks. Its aggregate raster counts do not establish a growing worker backlog. r1's DCF4 callbacks and NV2A/semaphore counters advanced through its last samples; a persistent DCF4 wait did not reproduce. Keep that historical DCF4 wait, CPU raster cost, and loading dependency separate. No cause supports a behavior fix, no target was seeded, and AOT execution, controller map, guest fences, and rasterizer commit `1ea1871` remain unchanged.

Next: correlate a clean, current-source framebuffer showing `LIST AS NEW` with the runtime object/callback dispatch and a single menu action; only then trace that callback's branch/state change. Separately, rerun the authorized new-pilot path with per-request file completion/IOSB and per-thread guest/native stacks if it reaches `NOW LOADING`; stop at the first verified mission frame. Do not patch based on the current title-only traces.
