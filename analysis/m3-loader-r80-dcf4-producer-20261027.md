# Steel Battalion loader trace checkpoint — r80 (2026-10-27)

## Run identity and scope

- Run: `m3-loader-r80-dcf4-producer-20261027`
- Diagnostic PID: `117004` (still running; leave open)
- Started: 2026-10-27 06:13:26 CDT
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace-Candidates/r79-load-state-callbacks-20261026/Release/your_game_recomp_producer_trace.exe`
- SHA-256: `1E4912C18306EA8F105C7DB656F140473750ED945CAFCFC6A19A368FDEE21541`
- AOT source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`
- Save root: `iso/local-analysis/saves-m3-known-save-copy-20261023` (reused; not cloned)
- Manifest and effective environment: `iso/local-analysis/logs/m3-loader-r80-dcf4-producer-20261027/run-manifest.json` and `environment.txt`
- The run enabled load-state callback, DCF4 producer, failed-open path, file caller, file I/O detail, dense read, framebuffer, raster, DMA, and semaphore traces. `RECOMP_PAD_SCRIPT` remained unset; inputs were appended one at a time to this run's `pad-live.txt` after reading the framebuffer.
- No source-code edit, build, patch, target seed, fence change, controller change, or rasterizer change was made. The authorized new-pilot route may have written pilot data to the existing save partition.

## Screen-gated new-pilot route

Guest framebuffer captures verified this sequence: title prompt → Campaign → `LIST AS NEW` → name editor with `A` entered → birth date `01/01/2002` → YES → `HAI SHI DAO 2080 [NORMAL]` → `NOW LOADING`.

At tick `348267359`, the selected `LIST AS NEW` row was correlated with the active callback: XID report byte 2 was `1`, OHCI DMA wrote byte `1` to guest VA `0x01081763` / bus `0x81081763`, predicate `(1,6,9)` returned true at parent `0x000E18D8`, and `sub_000E1820` took branch `0x000E193B`. The row action `0x83` at `0x000E19CF` changed item `0x002E4C34+0x28` from `0x3F800000` to zero. Its string slot resolves to `LIST AS NEW` at `0x0026AF04`.

The visible `NOW LOADING` frame is confirmed. The first mission frame is not verified.

## Loader and file evidence

The first sampled `[LOAD-PASS-OUT]` is n=1 at tick `348730937`, TID `121864`, return `0x000C32D6`, mode 2, scan indices 2..11, branch `scan`, result 0, pair changing from `0/0` to `0x011E2E00/0`. By tick `349431781`, pass n=442 returns through the same branch with result 0 and the pair unchanged. Sampled load-state fields stay at mode 0, phase 0, gates `1/1/0`, and progress `0x011E2E00/0` before and after the lock-boundary probes.

Static source classification matters here: `sub_000C3020` and its `sub_000C2EB0` helper perform a resource/cache metadata scan. These pass returns are not a direct asset-read completion and do not identify a missing mission file. The sampled helper cycles through resource-table entries and returns 1; that value is not a load-completion result.

There are 25 sampled failed-open path rows. The last is the expected empty pilot-slot `user00.sav` check at tick `348690031`; no later failed path is present. Earlier static empty-save misses are not mission dependency evidence. The 6,000-row `[FILE-CALL]` limit was reached; its last records show successful source/cache opens through `LSQ.BIN`. `[READ]` emitted 5,842 completions; its last is n=5842 at tick `348735718`, TID `118764`, token `0x48000069`, with all 18,432 requested bytes returned successfully. No later read completion is logged. The trace's caller limit and absent open/close lifecycle tracing mean a file path cannot be assigned to that handle token from this run alone.

File-I/O detail rows show successful writes through tick `348154312`, before the first loader pass, and successful metadata queries during the scan. No failed file-I/O completion is recorded. The sampled reads do not show a failed dependency. The 25 failed paths do not identify one. The first stalled loader dependency therefore remains unknown.

## Thread and synchronization evidence

Two lightweight thread-info minidumps were written outside the project and left the process alive:

- `%TEMP%\\steel-battalion-r80-thread-snapshot-20261027.dmp` — 997,473 bytes, captured 06:26:21 CDT.
- `%TEMP%\\steel-battalion-r80-thread-snapshot-20261027-2.dmp` — 1,021,408 bytes, captured 06:28:48 CDT.

Using the matching r79 image and map, TID `121864` repeatedly unwinds through `xbox_KeWaitForSingleObject+0x29` and stops at the custom guest boundary `0xE0C`. TID `118764` unwinds through `xbox_NtWaitForSingleObjectEx+0x28` and stops at non-module value `0x1273F78`. The second snapshot repeats these native stacks; it does not validate a guest call frame for the file-reader wait or prove it is the loader's missing dependency.

DCF4 producer traces are active. Marker writes and PFB-flush returns repeat; ring queue observations vary around 5–13 of 15; frame/counter/semaphore values advance; DCF4 callback and wait-trace records continue; synchronized DMA PUT/GET catches up. This run does not reproduce the earlier terminal unsignaled DCF4 wait. Keep that historical pilot-menu wait separate from this `NOW LOADING` interval.

At tick `349426328`, the four-thread raster sample measured 31 batches / 64 triangles, 2,034.88 ms batch wall time, 7,804.55 ms summed worker-active time, and 1,059.64 ms maximum batch wall time. The window reports 0–1 FPS / 30 draws. This verifies expensive CPU raster work during loading, but does not show a growing multi-frame queue or establish that raster time caused the unchanged loader state.

## Indirect target validation

The observed values `0xFE000004` and `0xFE000000` at generated `sub_00101A60` probe sites are synthetic Xbox kernel-thunk addresses, not missing game-code targets. The Ghidra flow listing classifies the corresponding sites as `RtlEnterCriticalSection` and `RtlLeaveCriticalSection`; the kernel bridge assigns its synthetic thunk range at `0xFE000000+`. No target should be seeded or rebuilt from these rows. Runtime `[ICALL]` failure rows: zero.

## Limits and current progress

- `[FILE-CALL]` reached its 6,000-row cap.
- `[LOAD-STACK]` reached its n=2048 sampled-stack limit; raw stack words do not prove a full guest call chain.
- `[READ]` reached n=5842 but did not reach its configured high-volume cap; it simply emitted no later completion.
- `[FILE-MISS-PATH]` emitted 25 rows and did not reach its sampled cap.
- Generic generated function tracing remains disabled/no-op; named probes emitted independently.
- Run logs are ignored local diagnostics. No screenshots, ISO/XBE, or game assets were added to Git.

Progress bars use verified acceptance points rather than estimated effort:

- Overall milestones: **[██░░░░░░] 2/8 complete (25%); milestone 3 active**
- Screen-gated title-to-NOW-LOADING route: **[███████] 7/7 transitions verified**
- First mission framebuffer: **[░░░░░░░░] 0/1**
- First stalled dependency identified: **[░░░░░░░░] 0/1**
- Screen-gated XID → DMA → pilot callback → row-state change: **[█████] 5/5**
- Full controller coverage / audio / campaign completion / 60 FPS: **[░░░░░░] 0/4 verified**

Next: leave PID `117004` and its save root alone, continue the current run, and stop diagnostic progression at the first verified mission frame. Do not make a code fix until one cause is supported by a trace chain.

## Live follow-up — 2026-10-27 06:42 CDT

PID `117004` remains responsive. The latest saved guest frame (`frame.bmp`, 06:42:26 CDT) still shows `NOW LOADING`; no first mission frame has appeared. Loader pass n=726 at tick `349901234` (TID `121864`) still takes the mode-2 scan/return `0x000C32D6`, result 0, pair `0x011E2E00/0`; callback samples before and after keep mode 0, phase 0, gates `1/1/0`, progress pair, and status pair unchanged. The source around `sub_000C3020` confirms this path iterates resource entries through `sub_000C2EB0` and paired metadata lookups, while the pass return 0 is the no-pair-change path. It is not evidence of a named mission-file failure.

The file trace remains inconclusive for an exact dependency: no failed path has appeared after the expected empty-slot `user00.sav` probe; `[FILE-CALL]` remains capped at 6,000; `[READ]` has emitted no completion after n=5842 at tick `348735718`; the run lacks handle open/close lifecycle correlation. Thread snapshots are still the 06:26 and 06:28 captures, so they do not show a later loader wait chain.

Rendering cost remains independently measurable and severe. The tick `349900593` raster sample processed 49 batches / 102 triangles in 2,733.26 ms batch wall time, with 10,421.05 ms summed worker-active time and a 1,061.19 ms maximum batch; the UI is still 0–1 FPS / 30 draws. During the same interval DCF4 marker writes and PFB-flush returns repeat, the frame/counter/semaphore advance, and DMA PUT=GET was `0x0001534C`. This separates active graphics/event progress from the unchanged loader state, but does not establish that raster work is the loader gate or identify a missing dependency. The historical r79 menu DCF4 wait remains a separate condition and is not reproduced here.

Current conclusion: a first stalled loader dependency is still **unidentified**. No seed, source fix, rebuild, or synchronization change is justified by this evidence. Keep PID `117004` and its save root untouched; continue until a first mission frame is visibly verified or stronger synchronized evidence identifies the gate.

## Live follow-up — 2026-10-27 06:44 CDT

The run manifest revalidates the same AOT producer-trace executable SHA-256 `1E4912C18306EA8F105C7DB656F140473750ED945CAFCFC6A19A368FDEE21541`, generated source directory `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`, and run identity/PID. The latest saved framebuffer still reads `NOW LOADING`.

The effective environment shows `RECOMP_FILE_LIFECYCLE_TRACE=0`; `[FILE-OPEN]` and `[FILE-CLOSE]` therefore emitted zero rows. `[FILE-MISS-PATH]` remains at 25 rows, ending at the expected `user00.sav` empty-slot probe; `[FILE-CALL]` is at its 6,000-row cap; `[READ]` remains at 5,842 completions with the last at tick `348735718`. This is the instrumentation gap preventing exact open/close/read-handle continuity. Current loader pass n=828 at tick `350085828` remains result 0 with pair `0x011E2E00/0`; callbacks keep state/progress/status unchanged.

A fresh read-only thread minidump was captured outside the project at `%TEMP%\steel-battalion-r80-thread-snapshot-20261027-3.dmp` (193,923 bytes, 06:44:08 CDT); PID `117004` remained responsive afterward. Matching the image/map, TID `121864` has stack references resolving to `bridge_KeWaitForSingleObject+0x12F` (image VA `0x14648509F`) and `xbox_KeWaitForSingleObject+0x29` (`0x1464A7309`), but the guest return frame remains unvalidated. TID `118764` resolves at the captured stack to `bridge_KeDelayExecutionThread+0x6D` and `xbox_KeDelayExecutionThread+0xD8`, so it was sleeping at snapshot time rather than visibly blocked in a file-wait routine. The caller/purpose of that delay is still unknown.

The bounded wait trace had already hit the DCF4 wait cap: its last recorded unsignaled wait is n=4096 at tick `348493734`, guest caller hint `0x00211F3B`. Successful DCF4 returns continue through n=8640 at tick `350243843` with status 0 and guest signal 1; DCE4 successful returns continue through n=9152 at tick `350237984`. These later returns establish that the historical terminal DCF4 wait does not persist through this loading interval, although the wait cap prevents reconstructing every later wait.

A read-only handle snapshot found 874 process handles, including 40 disk-file handles. Current open paths include cache assets `ADVANCE.BIN`, `ATARI.BIN`, `BGM00.WAV`, `bgm01.wav`, `bgm02.wav`, `LSQ.BIN`, `MODEL.BIN`, `MOTION.BIN`, `RTN.BIN`, `SOUND.BIN`, and `TEXOBJ.BIN`, plus source BGM files and source `RTN.bin`. This confirms valid media/cache files remain open; it does not identify an outstanding request or prove which files a mission needs. Handle `0xD30` currently resolves to cached `bgm02.wav`, but because historical handle reuse cannot be ruled out, it is not assigned to the old read record as a verified path.

Updated conclusion: current evidence supports heavy rendering cost and an active, repeatedly waking guest/kernel loop, but still does not identify the first stalled loader dependency. The next clean run needs lifecycle open/close tracing with raised caller/read limits and the same screen-gated new-pilot route after the current process naturally exits; do not reuse the active save concurrently. No code or runtime fix is supported yet.
