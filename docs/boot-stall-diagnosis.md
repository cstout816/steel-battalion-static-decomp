# Why boot is still stalling

## Current finding

The newest instrumented run reached the title and pilot menus, then exited on its own with an access violation in the guest DirectSound path. The guest DCF4 event continued to reset and signal, and DMA PUT/GET remained caught up at the sampled points, so this run does not support a DCF4 deadlock or a growing render backlog. The malformed DirectSound list is the immediate crash site; its corrupting writer is still unknown.

The earlier saved-pilot run described below remains a separate loading-screen stall. Its DCF4 producer/delivery issue is not explained by this newer audio crash. Do not combine the two failures or change guest fence behavior based on either trace alone.

At the last captured DCF4 wait, the guest requested target `0x2FF` while the semaphore was `0x2FB`. The semaphore subsequently advanced to `0x305`, but the DCF4 event stayed unsignaled, frame counters stayed fixed, and DMA PUT and GET remained equal at `0x457C`. The callback stream selected switch index 1 (`0x03600021`), while the DCF4 `KeSetEvent` branch requires index 5 (argument low five bits equal 5). The last raster aggregate near the wait was 24.20 ms of batch wall time and 84.14 ms summed across workers; raster work then stopped. That evidence separates this wait from a continuously overloaded renderer.

The translated guest interrupt handler calls this dispatcher only for NV097 `NO_OPERATION` notifications and forwards the method payload as the callback argument. Thus the trace confirms that no payload 5 reached the DCF4 signal branch after the last reset. Repeated NV2A interrupt snapshots after that point show PGRAPH interrupt status 0 while the PCRTC vblank bit remains set. The current logs cannot yet distinguish whether the title stopped submitting the payload-5 notification or whether the runtime failed to deliver/dispatch it.

The frozen frame is not an idle process: a synchronized 3.047-second read-only sample measured 3.547 CPU-seconds across the process (116% of one logical processor). Native thread 27524 used 3.359 CPU-seconds and thread 22600 used 0.516; the DCF4 wait thread 35728 used no measurable CPU, while the NV2A IRQ thread 37288 used 0.094 CPU-seconds. DMA, frame counters, and DCF4 remained unchanged through the sample, with no intervening raster batches. Runtime kernel-call summaries were dominated by critical-section enter/leave calls, but the hot thread's guest call stack was not captured. The source raster workers block on an event when idle, making them an unlikely source of this continuous CPU use. This supports a separate guest/runtime busy-loop or lock-polling path, but does not prove that it caused the missing DCF4 signal.

## Two distinct failures

- An earlier title run stalled at DCF4 after a reset without a later signal. That producer/delivery cause remains unresolved; it is separate from the newer run, where DCF4 continued to reset and signal.
- The newest run exited in the guest DirectSound path on a malformed list node at guest VA `0xFFFFFFF4`. This is a reproducible crash signature from prior runs, but the list's corrupting writer is still unknown.
- Raster reports include large CPU worker spikes. They show workload cost, but without queue-depth growth they do not prove a growing rendering backlog or explain either the earlier DCF4 wait or this audio-list crash.

The current executable used the default push-buffer segment scanner. The opt-in DMA walk was not enabled. XboxRecomp upstream documents a software-method interrupt limitation for its DMA-walk fence path; because this run did not use that walker, the upstream warning is not sufficient to explain this capture. See the [XboxRecomp release notes](https://github.com/sp00nznet/xboxrecomp/releases).

The small-triangle batch rasterizer from local commit `1ea1871` is already present and was not re-ported. The ahead-of-time static-recompilation architecture and guest fence behavior remain unchanged.

## Latest synchronized run (2026-10-23 local)

The current source and four-worker build ran with the saved-pilot route and copied save directory. The first feeder launch failed because its PowerShell script path contained spaces and was split into separate arguments. The corrected feeder began about two minutes after game launch, shifting the time-based route. The observed framebuffer stages were Dolby startup, `PRESS MAIN WEAPON BUTTON`, Campaign menu, then pilot selection with `LIST AS NEW` highlighted. The first mission frame was not reached. A later route input was delivered through the Steel Battalion XID report, but this run did not enable the guest title-input query trace.

The synchronized DCF4 wait trace reached wait #205: frame sequence `0x179`, counter `0xD81`, semaphore target `0xD59`, semaphore `0xD77`, and callback count 584. The matching event set occurred at tick `65596468` from guest caller `0x0021702F`, with callback count 586. The last NV2A tick recorded counter `0xD89`, target `0xD59`, fence `0xD85`, and DCF4 signaled. Sampled DMA PUT/GET values matched, advancing from `0x9250` to `0x96C8` before the crash handler finished collecting state.

The callback logger captured 512 callback argument/branch pairs before its generated-code cap. Among those: `0x03600021` selected branch 1 to `0x00216EC9` (169 calls); `0x01080021` selected branch 1 to `0x00216EC9` (168); `0x00000005` selected branch 5 to `0x0021701E` (168); `0x00000009` selected branch 9 to `0x0021707C` (6); and `0x00000028` selected branch 8 to `0x00217053` (1). The event trace shows 586 callbacks overall, so arguments for callbacks 513–586 were not captured individually. Expand that diagnostic cap before claiming full callback coverage.

Across 137 raster reports with four workers, batches ranged from 4 to 485, with 1–2 triangles per batch. `batch_wall_ms` ranged from 4.01 to 391.15 ms; summed worker `raster_active_ms` ranged from 8.17 to 1,387.03 ms. The largest single batch wall time was 86.35 ms and largest single-worker active time was 331.41 ms. These are sampled raster costs, not a queue-depth measurement; no accumulating render backlog was observed. The existing small-triangle batch rasterizer from commit `1ea1871` was not re-ported.

The process exited on an access violation while in guest function `sub_0021ED29` (`game_audio`), faulting on guest VA `0xFFFFFFF4` (host mapped address `0x10000FFF4`). Immediately beforehand, the generated DirectSound commit trace found owner/argument `0x010810A4`, sentinel `0x010810B4`, node `0xFF000000`, and predecessor `0x8038C098`; a second scan reached a null node. The crash registers held `EAX=ESI=0xFFFFFFEC` and `EDI=0x010810A4`. This is evidence of malformed guest list state at the crash, not yet evidence of which guest/runtime write corrupted it. The device voice-list head at `0x01081014` is a distinct structure and must not be conflated with the `owner+0x10` list.

No behavior fix was made. The raw crash dump, logs, and distinct framebuffer captures are local only under `iso/local-analysis/logs/m3-dcf4-wait-caller-20261024/`; no game assets or captures were added to Git. No exact duplicate framebuffer images were found to move from this run. The next diagnostic should start the feeder at process launch, enable the title-input consumer trace, raise the callback-detail cap above 586, and trace the first writer that changes the malformed DirectSound list links. Preserve the AOT architecture and guest fence behavior.

## Community/tooling review (2026-10-24)

The local XboxRecomp checkout is pinned at v0.13.1. Upstream's current README and guides describe newer lifter/discovery coverage, unresolved-stub tracing, XBE conformance checks, and optional live inspection through xemu's GDB stub. The upstream candidate-game guide specifically calls out custom NV2A push-buffer use and multithreading as harder recompilation targets. These are selective analysis/tooling leads, not a reason to wholesale-upgrade this project or replace its AOT runtime. See [XboxRecomp](https://github.com/sp00nznet/xboxrecomp), its [getting-started guide](https://github.com/sp00nznet/xboxrecomp/blob/main/docs/GETTING_STARTED.md), and its [candidate-game criteria](https://github.com/sp00nznet/xboxrecomp/blob/main/docs/technical/candidate-games.md).

The public [Steel Battalion Xemu fork](https://github.com/quizerno/Xemu-SB-VK) is an emulator fork, so it can inform controller and visual-state comparisons but is not an AOT implementation to port wholesale. A [community discussion reports reaching the first level in Xemu](https://www.reddit.com/r/steelbattaliononline/comments/1v53hau/xemu_steel_battalion_current_status/); that is useful as an external behavior reference, not proof about this runtime's audio-list or DCF4 failure.

## What is still unknown

The earlier DCF4 freeze still lacks a producer-versus-delivery explanation, and the DirectSound list still lacks a proven corrupting writer/lifetime cause. The first mission framebuffer, mission loading completion, gameplay, audio output, campaign completion, and 60 FPS are unverified. The full raw logs and captures remain in the user's local analysis folders and are not part of this repository.

Next diagnostic: enable the existing opt-in push-buffer NOP/PGRAPH-notify enter-and-ack trace and obtain a guest stack/PC sample for the hot native thread. Correlate submitted `NO_OPERATION` payloads with the guest handler branch, interrupt state, waiting thread, event reset/set, and semaphore. Keep the same saved-pilot route and preserve guest synchronization while collecting evidence. Do not change synchronization behavior based only on the upstream DMA-walk note.

## Synchronized trace recheck (2026-10-23 22:50 local)

A read-only recheck of the same live saved-pilot run confirms the event-wait sequence and narrows how to interpret DMA: the reset/wait at tick `61261328` has target `0x2FF` and semaphore `0x2FB`; semaphore samples later reach `0x305`. Callback `n=199` at tick `61262359` carries `0x03600021`, selecting index 1 / target `0x00216EC9`, and the DCF4 event remains clear. DMA PUT/GET are equal at each sampled point, but the pointers advanced from `0x7AF54` to `0x7F974` before wrapping to `0x457C`; do not describe that as a channel that never progressed. The frame sequence/counter/target stay at `0xB6` / `0x309` / `0x2FF` in later snapshots.

The last raster aggregate remains tick `61259343`: 27 batches, 54 triangles, 24.20 ms batch wall time, 84.14 ms summed worker time, maximum batch wall time 16.67 ms, and maximum active raster time 61.73 ms. No new raster aggregate follows the final wait in the trace. The saved image captured at 22:35 local shows the title prompt (`PRESS MAIN WEAPON BUTTON`), not a mission frame; it is an earlier image, not a fresh capture of the current display.

Critical-section samples show contention on guest lock `0x0023FE18` during earlier loading intervals. They include acquisition/release progress, and the final sampled lock events are well before the DCF4 wait at tick `61261328`; they do not prove that an audio lock caused the later stall. The process (PID 41236) was still alive at 22:50 local and was left open. No runtime or gameplay fix was made.

The supported immediate blocker remains the missing DCF4 signal-branch callback after the final reset. The producer-versus-delivery cause, mission-frame entry, audio, controls in gameplay, full campaign, and 60 FPS remain unverified. Keep the next run bounded and synchronized, adding the existing push-buffer notification trace and a guest PC/stack sample for the hot thread before considering any fix.

## Live recheck (2026-10-23 23:22 local)

The game process was still responsive and was left open. A fresh framebuffer capture shows the Steel Battalion title prompt, `PRESS MAIN WEAPON BUTTON`; the first mission frame is not verified. The display reports 0.00 FPS and 181 flips. The title capture remains identical across repeated snapshots.

The latest synchronized state remains frame sequence `0xB6`, counter `0x309`, target `0x2FF`, DCF4 `0`, callback count 204, and DMA PUT=GET=`0x457C`. DCF4 wait #17 has no return or later set. Callback #202 carried `0x00000005` and selected branch 5 (`0x0021701E`, the guest DCF4 set path). Callbacks #203 and #204 carried `0x03600021` and selected branch 1 (`0x00216EC9`), which does not signal DCF4. No later callback or push-buffer batch appears.

A critical interpretation correction: the runtime's `fence_mirrors_tick()` copies DMA PUT into the guest location reached through GET. Therefore the observed fence/semaphore value `0x305` is a runtime mirror and is not independent proof of NV2A completion or release of the guest wait. Preserve the guest's fence behavior.

Raster worker timing stopped before the frozen interval. The preceding windows measured 28–56 batches, 56–112 triangles, 36–82 ms batch wall time, and 132–286 ms summed worker active time. The later 2,446-triangle figure is cumulative process statistics, not new raster work. DMA is idle and no work queue is accumulating, so this stall is separate from the earlier CPU raster cost. PCRTC and USB polling continue. A short native-thread sample again found TID 43464 CPU-active, but its guest PC/stack is still missing; that does not establish a lock or rendering cause.

Community/tooling review found upstream XboxRecomp v0.15.0 documentation covering function discovery, x86 lifting correctness, optional Ghidra naming, guest-stack/argument tracing, unresolved-stub logging, and XBE conformance comparison. The local fork is v0.13.1, so compare specific tool improvements after recording the current hot thread and DCF4 producer rather than replacing the runtime wholesale. The [Steel Battalion Xemu fork](https://github.com/quizerno/Xemu-SB-VK) and [community status discussion](https://www.reddit.com/r/steelbattaliononline/comments/1v53hau/xemu_steel_battalion_current_status/) are useful for controller and compatibility context; their emulator-side progress does not prove an AOT runtime cause. The local small-triangle batch rasterizer from commit `1ea1871` is already present and was not re-ported.

The immediate blocker is still the unsignaled guest DCF4 event; the reason its signal producer stopped remains unproven. No fix or build was made. The next evidence step is a synchronized guest PC/stack and critical-section-owner sample for the hot thread, plus tracing the PGRAPH payload writer, DCF4 producer/waiter, and title-input consumer. Preserve AOT execution and guest fence semantics. Stop once the first mission frame is verified.

## Hot-thread identity (2026-10-23 23:25 local)

A read-only Windows thread query mapped the hot native TID 43464's start address through the running executable's map file to `nv2a_ack_thread` in `xbox_memory_layout.c`. The DCF4 waiter TID 44900 is the process's main thread; its current state is waiting. This is an entry-routine mapping, not a current instruction pointer or guest stack.

The NV2A acknowledgement thread intentionally loops over busy/idle register acknowledgements, mirror/counter updates, and push-buffer scanning, then calls `Sleep(0)`. That explains why the thread can consume CPU while the game is frozen. It is not evidence of raster work or proof that this helper caused the missing DCF4 signal. The latest raster queue remains idle, and the producer-versus-delivery cause remains unresolved. No behavior change follows from this observation.

An attempted Windows CPU profile could not start because this session lacks the system profiling privilege; it produced no capture. The next useful step is a guest PC/stack sample and DCF4 producer trace using a permitted debugger/profiling path. Do not change the guest fence or the acknowledgement loop based on the thread start address alone.

## Watchdog guest stack (2026-10-23 23:28 local)

The 1,800-second watchdog captured the main guest thread while DCF4 was still unsignaled. Guest stack reconstruction against the XBE function boundaries gives sub_0020E520+0xA0 → sub_001914F8+0x72 → xbe_entry_point+0x59. The top frame is immediately after the call at 0x0020E5B8 into sub_00211E10 from a function classified as game rendering. The final framebuffer still shows PRESS MAIN WEAPON BUTTON; there is no mission frame.

This supports the immediate DCF4 wait diagnosis and localizes the blocked title/render path. It still does not show why the callback producer stopped. TID 43464 starts in the runtime's nv2a_ack_thread, whose source polls NV2A busy/idle state and yields; this explains the CPU-heavy helper sample but does not establish a rendering backlog or missing-event cause. TID 44900 is the main process thread and DCF4 waiter. No guest synchronization or renderer behavior was changed. A Windows CPU profile could not be collected because the session lacks the profiling privilege.

The game process is now absent after the watchdog interval; it was not closed by this diagnostic. No matching Windows crash event was found. The exact exit trigger remains unverified. Continue by tracing the producer feeding the DCF4 callback and the title input consumer; preserve AOT execution and guest fence behavior.
