# Steel Battalion project status

**Current milestone:** 3 — boot and compatibility.
**Next acceptance point:** first visually verified mission frame.

## Progress

Overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · earliest blocker diagnosis `███░ 3/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

## Latest completed evidence — r275

See [r275 report](../analysis/m3-r275-newpilot-black-frame-stall-20261029.md). PID 163124 followed the visible new-pilot route through name `A5`, default birth date, `YES`, and `HAI SHI DAO 2080 [NORMAL]`. After confirming Normal, the last retained framebuffer was black. `NOW LOADING` and a mission frame were not verified. The process stopped producing traces at 01:46:30 CDT and was marked unresponsive; only this diagnostic child was stopped at 01:49:35. Exact r275 EXE/PDB/MAP identities and logs are preserved alongside the run.

Input reached XID and guest edge consumption: byte 2 transitioned at tick 504274343; cell `0x004AFC08` changed 0→1 at `0x000C8064`, parent `0x000E081F`. The visible LIST AS NEW path reached the already identified `sub_000E1820` / branch `0x000E193B` / action `0x83`.

The new bounded `sub_00216B10` queue trace emitted 583 samples, 145 with processed work and none at its 1,024-row cap. DCF4 callbacks, DMA/semaphore, NV2A timer and raster telemetry continued close to the last trace row. The sampled DCF4 waits returned; no persistent DCF4 wait is supported at the black-frame stop. File reads succeeded in the sampled records, but path/lifecycle and pending-token correlation were not enabled. The final sampled completion was n=9000, an 8-byte successful read. No first missing dependency or validated native/guest stack was identified. The 250 KB r275 dump contains thread metadata only, not thread contexts or stacks.

Raster windows completed while running, but cost roughly 2.0–2.4 seconds per batch window with 4 worker threads. This confirms severe performance cost, not that rendering alone blocked loading. Keep rendering cost separate from file loading, title DCF4 waits, DirectSound corruption and guest-CPU waits. No runtime behavior fix was made.

## Storage and source recovery

The latest post-run inventory measured 57,903,628,452 allocated bytes (about 53.93 GiB) and 1,381,557,088,341 logical bytes. Compared with the 01:29 inventory, the increase is 189,780,315 allocated bytes and 235,773,753 logical bytes. Eight allocation queries failed and 13 reparse points were skipped; use the total as approximate. No space was reclaimed; the prior deletion review rejected cache removal and no alternate method was attempted. Preserve r275’s matched symbols and current route save; its `Partition5.img` hash changed at run launch and remains in place.

Dirty checkout recovery: [source preservation manifest](../analysis/source-preservation-manifest-20261029.md). It records project and XboxRecomp patch hashes/base commits plus the 27-file generated-source manifest; generated game code stays out of Git. The warm build remains available; r275 completed in about 17.6 seconds without cache purge.

## Next discriminating test

Before another behavior change, add only bounded rolling failure-window evidence for the post-difficulty transition: recent loader read request/completion identities and failed path opens, loader helper progress, last completed raster batch, and DCF4 wait/set results. On a global no-progress stall, capture a normal thread-context dump rather than thread metadata only. Confirm a missing dependency only when a specific outstanding read has no completion and its owning thread waits on it; confirm a raster stall only when the final worker batch is incomplete while loader state otherwise advances. Reject either if its producer completes and state continues to advance. Keep AOT, controller mapping, guest fences and rasterizer `1ea1871` unchanged.

**Still unverified:** `NOW LOADING`, first mission frame, loading dependency/call chain, audio correctness, full controller behavior, 60 FPS, mission completion and campaign progression.
