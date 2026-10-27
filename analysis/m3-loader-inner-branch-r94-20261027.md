# r94 mode-2 loader inner-branch trace — 2026-10-27

## Result

The screen-gated new-pilot route reached the visible `NOW LOADING` screen for `HAI SHI DAO 2080 [NORMAL]`. It remained there through the final framebuffer capture at 11:03:38 CDT. No first mission frame was verified. I stopped only diagnostic PID `125848` at about 11:03:56 CDT after verifying its executable path. The external 900-second watchdog did not fire, and the first automatic plateau rule did not fire; the full-frame hash was too sensitive to the loading animation. The runner has since been changed to exclude the narrow loading-indicator band from its framebuffer signature. That revised guard is not yet runtime-validated.

The strongest loader dependency evidence is a repeated missing-cache branch for `Z:\TEX00.BIN`, correlated to helper index `0x1E`. On each observed scan the first open fails, the second open is not attempted, and the helper returns raw `EAX=0xFFFF0001` through the paired-open branch. The outer mode-2 pass nevertheless continues to its normal scan return. This establishes the exact missing-cache operation, not that it alone blocks mission entry. No behavior fix, cache seed, indirect-target seed, or renderer change was made.

## Run identity and route

- Run: `m3-loader-inner-branch-r94-20261027`, PID `125848`, started `2026-10-27 10:49:10 CDT`, stopped at about `11:03:56 CDT`.
- Executable: `local-tools/steel-battalion-game/build-xpp-seeded/ProducerTrace/Release/your_game_recomp_producer_trace.exe`, SHA-256 `3C298BB7880DB89D11318D9C2CDC614F9136399AC2EE2F77020F6939DAAB58BF`.
- Generated source: ignored local directory `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`; helper instrumentation was limited to `recomp_0004.c` / `sub_000C2EB0`. It recorded input pointers and index, raw open handles, inner exit stage, full EAX, and low 16 bits. No guest branch or operation was changed.
- Save root: existing `iso/local-analysis/saves-m3-route-file-read-copy-20261023`; no save images were copied or edited.
- Screen-gated route: title prompt → Campaign → `LIST AS NEW` → pilot name `AA` → birth date `01/01/2002` → `OK? YES` → `HAI SHI DAO 2080 [NORMAL]` → `NOW LOADING`.
- Run directory: `iso/local-analysis/logs/m3-loader-inner-branch-r94-20261027/`. The manifest reports exit `-1` from the verified manual stop, watchdog false, zero dropped relay lines, and complete marker counts.

## Loader and file evidence

- First mode-2 pass began at tick `365227406` on guest TID `125628`. Each pass covered range `2..11`, then the additional helper calls, and returned through `0x000C32D6`. There were 191 matching pass entries/returns. The tracked pair changed once from `0/0` to `0x011E2E00/0`, then remained stable through final pass n=191 at tick `365572250`; source and trace do not establish the pair's meaning.
- At tick `365227046`, the extracted source `D:\media\BIN\TEX00.BIN` opened successfully. Token `0x48000085` received only 56-byte metadata queries (`class=0x22`); no content read was logged for this token.
- At tick `365227531`, helper n=18 on the same guest thread entered `sub_000C2EB0`, returning to `0x000C32A1` with argument index `0x1E`, selector 0 (`paired-open-compare`), and stack pointers `path0=0x00F7FDF8`, `path1=0x00F7FD78`. On the same tick and thread, `NtCreateFile` for `Z:\TEX00.BIN` returned `STATUS_OBJECT_NAME_NOT_FOUND` (`0xC0000034`). The helper trace recorded `open1=0xFFFFFFFF`, `open2=0`, `open3=0`, and exit stage `0x000C300D`. Source control flow at `0x000C2F3E` takes the first-open failure edge to `0x000C300D`; the second open therefore does not occur on this path.
- The helper returned at tick `365227531` with raw `EAX=0xFFFF0001` (`LO16=1`). Other sampled resource indexes returned `EAX=1`. The same index-`0x1E` failure repeated throughout the mode-2 scans. The immediate caller at `0x000C32A1` overwrites EAX from its local stack before the following comparison; the return value itself is not checked there. Whether missing output-buffer writes indirectly hold later state remains unverified.
- `Z:\st00_0.rep` was the earlier empty-save cache probe. Among the recorded `Z:` opens, TEX00 was the only later non-save missing cache path. The observed preload worker again copied 21 other resources successfully and did not call its copy helper with table index `0x1C`; this does not prove it is the only expected TEX00 producer. The prior r78 cache copy did not advance loading.
- Guest TID `125628` continued metadata polling and loader scans after its last observed content reads. Later 18,432-byte completions on TID `126228`, token `0x48000069`, map through lifecycle records to cached `Z:\bgm02.wav` and are audio-stream reads. No pending loader-thread content read is shown. Guest stack samples were captured; no native Windows thread stack was captured.

## Graphics and synchronization evidence

- Final sampled raster window at tick `365571890`: 27 batches, 56 triangles, 2,071.19 ms batch-wall time, 8,002.22 ms aggregate raster-active time across four workers, and 1,339.65 ms maximum single-batch wall time. Queue depth and a causal link to the loader are not measured.
- DCF4 callbacks and frame counters continued. Final callback sample n=19,559 used argument `5`, index `5`, selected target `0x0021701E`; final NV2A tick was frame `0x271C`, counter `0x40173`, target `0x4016B`, fence `0x40165`. The final reset sample also showed semaphore `0x40165`. This run did not reproduce a terminal unsignaled DCF4 wait.
- `RECOMP_LOAD_STATE_CALLBACK_TRACE` was disabled, so this run did not capture the indirect callback targets and before/after state around `sub_000C3020`. This is the main missing synchronized state transition evidence. No indirect target was seeded.

## Findings and next step

**Verified:** AOT execution reached `NOW LOADING`; loader index `0x1E` is correlated to the repeated TEX00 cache miss; its first open fails and helper returns `0xFFFF0001`; the caller continues through 191 mode-2 passes; the tracked pair stabilizes; no loader-thread content read remains pending in the completion log; audio reads continue separately; DCF4 progresses; CPU raster cost remains severe.

**Not established:** that the TEX00 cache miss is fatal or sufficient to block mission entry; whether failed open leaves an output buffer stale and that state gates progression; the meaning of pair `0x011E2E00/0`; the callback targets/state changes around the scan; any native worker stack; a first mission frame; or stable 60 FPS.

**Next diagnostic:** replay the same new-pilot route with `-EnableLoadStateCallbackTrace`, correlating each validated indirect target and its before/after mode, phase, gates, progress, status, and object fields with the mode-2 pass and TEX00 open. Keep AOT, controller mapping, guest fences, and rasterizer baseline `1ea1871`. Do not seed or fix from the cache miss alone. The runner's new plateau signature ignores only the animated loading strip; validate it during this run and stop at the first mission frame if reached.

## Storage

Four byte-identical numbered captures were moved—not deleted—to `iso/local-analysis/obsolete-for-user-review/m3-loader-inner-branch-r94-duplicate-frames/`; the adjacent manifest records their common hash and retained representative. The original ISO, extracted game assets, and save images were untouched.
