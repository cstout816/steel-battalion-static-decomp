# Why boot is still stalling

## Current finding

The latest synchronized saved-pilot run reached the Steel Battalion title/logo stage but did not reach a mission. Its final state is best explained by a guest DCF4 completion event that is reset and then never signaled again. This identifies the immediate blocker, not yet the producer-side defect that prevents the signal.

At the last captured DCF4 wait, the guest requested target `0x2FF` while the semaphore was `0x2FB`. The semaphore subsequently advanced to `0x305`, but the DCF4 event stayed unsignaled, frame counters stayed fixed, and DMA PUT and GET remained equal at `0x457C`. The callback stream selected switch index 1 (`0x03600021`), while the DCF4 `KeSetEvent` branch requires index 5 (argument low five bits equal 5). The last raster aggregate near the wait was 24.20 ms of batch wall time and 84.14 ms summed across workers; raster work then stopped. That evidence separates this wait from a continuously overloaded renderer.

The translated guest interrupt handler calls this dispatcher only for NV097 `NO_OPERATION` notifications and forwards the method payload as the callback argument. Thus the trace confirms that no payload 5 reached the DCF4 signal branch after the last reset. Repeated NV2A interrupt snapshots after that point show PGRAPH interrupt status 0 while the PCRTC vblank bit remains set. The current logs cannot yet distinguish whether the title stopped submitting the payload-5 notification or whether the runtime failed to deliver/dispatch it.

The frozen frame is not an idle process: a synchronized 3.047-second read-only sample measured 3.547 CPU-seconds across the process (116% of one logical processor). Native thread 27524 used 3.359 CPU-seconds and thread 22600 used 0.516; the DCF4 wait thread 35728 used no measurable CPU, while the NV2A IRQ thread 37288 used 0.094 CPU-seconds. DMA, frame counters, and DCF4 remained unchanged through the sample, with no intervening raster batches. Runtime kernel-call summaries were dominated by critical-section enter/leave calls, but the hot thread's guest call stack was not captured. The source raster workers block on an event when idle, making them an unlikely source of this continuous CPU use. This supports a separate guest/runtime busy-loop or lock-polling path, but does not prove that it caused the missing DCF4 signal.

## Two distinct failures

- In the current run, the title/logo route stalled at DCF4. No rendering, guest-fence, callback, or gameplay fix has been made.
- A companion run reached the Campaign menu and then exited on a DirectSound voice-list access violation at guest address `0xFFFFFFF4`. That is a separate audio failure. The list-corruption source is not known.
- An earlier window did show a large raster spike (about 1.08 seconds batch wall time and 4.17 seconds summed worker time). CPU raster performance remains a real issue, but it does not account for the current run's idle DMA and absent raster batches after the event wait.

The current executable used the default push-buffer segment scanner. The opt-in DMA walk was not enabled. XboxRecomp upstream documents a software-method interrupt limitation for its DMA-walk fence path; because this run did not use that walker, the upstream warning is not sufficient to explain this capture. See the [XboxRecomp release notes](https://github.com/sp00nznet/xboxrecomp/releases).

The small-triangle batch rasterizer from local commit `1ea1871` is already present and was not re-ported. The ahead-of-time static-recompilation architecture and guest fence behavior remain unchanged.

## What is still unknown

The traces do not show why the callback producer stops delivering the DCF4 signal payload. The first mission framebuffer, mission loading completion, gameplay, audio output, campaign completion, and 60 FPS are unverified. The full raw logs and captures remain in the user's local analysis folders and are not part of this repository.

Next diagnostic: enable the existing opt-in push-buffer NOP/PGRAPH-notify enter-and-ack trace and obtain a guest stack/PC sample for the hot native thread. Correlate submitted `NO_OPERATION` payloads with the guest handler branch, interrupt state, waiting thread, event reset/set, and semaphore. Keep the same saved-pilot route and preserve guest synchronization while collecting evidence. Do not change synchronization behavior based only on the upstream DMA-walk note.
