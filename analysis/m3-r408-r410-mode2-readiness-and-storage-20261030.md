# r408–r410 mode-2 loader and storage follow-up — 2026-10-30

## Outcome

Milestone 3 remains active; **first visually verified mission frame: 0/1**. r410 completed the screen-gated new-pilot route through Normal and the mode-2 loader path. It then held a white 640×480 frame for the 240-second plateau window. The capture does not show a mission, and the run did not visually confirm a `NOW LOADING` label. No gameplay/runtime behavior was changed.

The focused r410 test rejects one hypothesis: **resource `0x1E` does not remain unready**. Its consumer first saw ready byte `0` at `0x00351F22`; the worker later set it to `1`, a subsequent helper decision changed from 5 to 6, and the final mode-2 output pair advanced to `0x000ABA00/0`. This is progress past that readiness check, but not a complete explanation of the stall. The downstream state producer/consumer remains unresolved.

## Run identity and process protection

| Field | Value |
|---|---|
| Run | `m3-mode2-readiness-producer-consumer-r410-20261030` |
| Process | Diagnostic child PID `24144`; own plateau watchdog stopped it after 240 seconds without loader/frame change |
| Start | `2026-10-30 08:40:01 UTC` |
| Save root | `iso/local-analysis/saves-m3-dsound-surface-isolated-r368-20261030`, reused directly; no copy or hard link |
| Generated source | `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen` |
| Executable | r409 producer-trace candidate; SHA-256 `13486060C5977578207377CE47CFEA82760C48D3FCC57B9DA1C0821A5FB2A23A` |
| PDB | SHA-256 `0FF3A109EFEAEE7E16BA222CCED7638C37E119F92681413538FF201DEE389F17` |
| MAP | SHA-256 `51FE8DB2E420EC0C44C2556F398434995FA0C72EB2B0FB118851B2B1DBC91994` |
| Stop dump | `mode2-plateau-stall.dmp`; SHA-256 `1D2A715DA9D0FAB09C365ABC926DFCBBCEADB247724497757FC9E8C865EA2D65` |
| Final image | `frame-history/capture-0024.bmp`; SHA-256 `BB134B2A2CF95E56D036855B53F8B2A782D3185BEE005782B0B4913961DDA9D2` |

r408 was a separate title-input run and ended before the pilot list; it is not loader evidence. At the initial and final process checks, no Steel Battalion/XboxRecomp game process was active. The only matching Xbox-named process was the Xbox PC app shell. No other chat's process was interrupted.

## Test and observed handoff

**Hypothesis:** after the new-pilot route, loader progress is blocked because mode-2 resource `0x1E` never becomes ready. **Confirmation criteria:** its ready byte remains zero and the downstream consumer keeps selecting the pre-ready branch. **Rejection criteria:** the producer sets the byte and the consumer demonstrably takes a post-ready branch.

**Result:** the hypothesis was rejected for this run.

One screen-gated A press is correlated end-to-end at tick `598279578–598279625`: XID report byte 2 was `1` in DMA buffer `0x01081763`; guest edge caller `0x000C8064` (parent `0x000E07EC`) consumed button cell `0x004AFC08=1` and the guest predicate returned 1. The active pilot callback then ran at `0x000E18D8`, selected branch `0x000E193B`, and the row handler at `0x000E19CF` performed action `0x83`. It changed `0x002E4C34+0x28` from `0x3F800000` to zero. This identifies the active pilot-list callback through runtime dispatch; `sub_000E0870` was not used for this press.

- r410 recorded 19 mode-2 passes over the observed startup interval. At helper index `0x1E`, the ready byte was `0` at tick `598832015` (decision 5). Worker TID `189152`, started at guest entry `0x00014171`, then logged open/copy results of `1` and set ready byte `0x00351F22` to `1` at tick `598834093`.
- At tick `598834203`, the helper evidence showed decision 6 and the last pair became `0x000ABA00/0`. The worker object transitioned from pending `0x103` to completed exit status `1`. A later mode-2 worker (TID `191392`, guest entry `0x00017E40`) also completed with exit status `1`; no loader worker remained pending in the plateau evidence.
- After this handoff, load-state callback rows continued to return zero while pre/post mode remained `2`, phase `0`, progress stayed `0x000ABA00/0`, status stayed `0/0`, and the gate bytes stayed `1/1/0`. Inspection of the exact XBE import table records slots 0 and 1 as ordinals 294 and 277. The retained kernel bridge labels these as `RtlLeaveCriticalSection` and `RtlEnterCriticalSection`; the ordinal names are candidate labels for this XDK 4627 XBE. These are void lock calls whose zero return is expected, not a loader completion result. Their repeated returns do not show a stuck lock.
- File lifecycle logged 1,918 opens and 1,515 closes; 30 cache-path misses were recorded. The relevant `ATARI.BIN`, `MODEL.BIN`, `MOTION.BIN`, `LSQ.BIN`, `SOUND.BIN`, `TEXOBJ.BIN`, and `TEXMOVIE.BIN` probes were followed by successful media-tree opens. Sampled read completions through sequence 6,000 showed `ios=0`, `nt=0`, `guest=0`, and `async=0`. No file failure was logged. The sampling interval and trace caps mean this does not prove every file was fully consumed or identify all file completions.
- The loader later repeated the same white framebuffer and mode-2 signature for 240 seconds: `mode=0002|range=2..11|index=28|branch=scan|result=0|pair=000ABA00/00000000|frame=7267251269A9FFD848AA38A4B452E0605DD06BCAF2ADC5D5D01C3547E60BF04F`.

## Exact-bundle stack and synchronization evidence

All 36 dump threads were unwound using the matching r409 executable and MAP/PDB set. The main host TID `190340` had one EXE frame at `+0x6154566`; StackWalk stopped at synthetic FP `0x10270` after 3 stack reads and 0 read failures. This is **not** a validated guest call chain. The other useful native frames resolve against the exact MAP to normal runtime workers: TID `30380` `nv2a_ack_thread+0x8C`, `182804` `mcpx_apu_frame_thread+0x201`, `189832` `ohci_thread+0x13B`, `190396` `watchdog_wait_with_progress+0xA7`, `181164` `kernel_timer_thread+0xE2`, `186936` `fb_thread+0x5B1`, `190436` `xbox_KeDelayExecutionThread+0xD8`, and three raster workers at `raster_worker+0x9F`. These are native unwinds; the non-module boundaries are not promoted into guest frames. The raster workers were at their pool-worker path, not evidence of queued rendering backlog.

DCF4 waits occurred during r410's mode-2 run, but the sampled waits returned successfully with `status=0` and guest signal `1`; the final recorded DCF4 wait returned at tick `598843921`. DCE4 also continued returning signaled through frame sequence `0x39FD`. This run therefore does **not** reproduce a persistent DCF4 wait. The title DCF4 case from r150/r151 remains separate. r410 did not enable DCF4 producer-stage detail or synchronized DMA/PB telemetry. Earlier r391 synchronized graphics telemetry showed no terminal raster backlog; do not infer renderer cause from r410's 350 periodic raster samples alone.

Keep separate: the old title DCF4 wait; DirectSound list corruption; the earlier rendering-slowdown reports; and this post-difficulty mode-2 plateau. The r405 4 MiB allocation failure did not recur in r410. The existing `ObReferenceObjectByHandle` pending/completion implementation remains unchanged; this evidence does not reopen its old r130 null-output diagnosis.

## Trace/build limitations

- r410 used AOT execution and the existing screen-gated controller route. A bounded asynchronous relay used a 32,768-line queue; stdout/stderr relay drops were zero. The run remained under its 64 MiB cap and retained eight framebuffer-history images, including the final failure frame.
- File reads were sampled (initial records and every thousandth completion); file lifecycle was bounded; thread suspend logging reached its 128-record cap with a dropped counter. There is no complete file-to-consumer attribution or guest stack chain at the final plateau.
- The final image is solid white. It does not verify a mission frame, audio in mission, 60 FPS, or campaign progression.
- r408's title route did not reach the pilot list. Its DCF4 wait rows returned after matching signals and do not explain r410.

## Storage and working set

Final fresh inventory: `C:\Project\sb-inventory-current-r410-final-20261030.csv` and `.skipped.txt`. Ordinary files total **41,649,335,590 allocated bytes** and **1,397,880,810,882 logical bytes**. The 13 Rust/Cargo executable reparse entries add **165,381,632 allocated bytes**; their reparse logical lengths were reported as zero by this scan. Combined allocated size is **41,814,717,222 bytes (38.94 GiB)**. Logical length is not disk use; it includes sparse partition images.

| Retained area | Allocated | Logical |
|---|---:|---:|
| Warm `build-xpp-seeded` tree | 7,136,856,349 | 14,381,973,554 |
| Canonical generated source | 155,890,474 | 155,890,474 |
| r368 save root | 110,709,376 | 5,422,142,918 |
| Extracted `game_files` | 1,800,138,464 | 1,808,250,705 |
| Historical/current logs | 3,076,745,350 | 1,036,314,234,953 |

Hash-verified NTFS compression of closed r410 logs/captures/dump reclaimed **887,624 allocated bytes** across 23 verified files. A second pass compressed 13 older closed diagnostic logs/dumps that were still uncompressed, reclaiming another **11,046,834 bytes**. All 36 SHA-256 hashes remained unchanged, for **11,934,458 allocated bytes recovered** in total. The r409 bundle remains because its exact EXE/PDB/MAP are required for the unresolved r410 dump. The warm incremental cache was preserved; the r409 trace build rebuilt two generated chunks and linked in about 40 seconds. No save image or source tree was deleted or copied. Older compression results are recorded in `r410-older-closed-evidence-compression-20261030.csv`.

Three old tool archives in `C:\Project\SteelBattalion-Delete-Later-20261026\duplicate-tool-archives` were rehashed against retained copies and match byte-for-byte (two distinct payloads, three duplicate files; path-summed allocation **976,265,216 bytes**). The duplicate Ghidra name is present in a cleanup script and an old size report; the specific path named by the script is absent, but this reference is documented. Automatic file-action review rejected the removal attempt before it ran, so **archive deletion savings are zero**. No alternate deletion route was attempted. Current source/retained hashes are in `r410-archive-duplicate-current-hash-check-20261030.csv`; the bounded project-text reference scan is in `r410-archive-duplicate-reference-check-20261030.csv`.

The prior r406 combined inventory was 41,746,055,330 allocated bytes. The current scan is higher by 68,661,892 bytes because r409's exact bundle and new run/evidence/status records were retained; the 11,934,458-byte compression recovery is included in the current scan. Build efficiency was preserved by retaining the warm tree. No hot compiler/Cargo cache was removed.

## Next diagnostic

Do not change runtime behavior on this evidence. Instrument one bounded post-worker handoff: record the exact mode-2 state input and the first producer that can advance the mode/progress pair after `0x1E` is ready, together with its owner thread and completion status. Correlate that with the specific file-consumer record; capture a plateau dump only if the callback/state stops again. Keep the XID mapping, AOT execution, guest fences, and rasterizer `1ea1871` intact. Stop once the first mission frame is visually verified.
