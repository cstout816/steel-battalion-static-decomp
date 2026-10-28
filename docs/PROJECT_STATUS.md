# Steel Battalion project status

**Current milestone:** Milestone 3 — boot and compatibility.

**Next acceptance point:** first visually verified mission frame.

**Latest diagnostic:** r234 (`m3-thread-suspend-snapshot-r234-20261028`).

**Progress:** overall `██░░░░░░ 2/8` · AOT/XBE `██░░ 2/4` · boot/compatibility `████░ 4/5` · loader diagnosis `███░ 3/4` · rendering `██░░ 2/4` · controller `██░ 2/3` · audio/DSP `█░ 1/2` · first mission frame `░ 0/1` · stable 60 FPS `░ 0/1`.

## Current finding

r234 supports a guest CPU scheduler handoff failure: the title successfully suspended a newly created loader worker while that worker still owned the guest CPU lock. Two guest threads remained queued behind it. The state repeated in three synchronized snapshots, and the worker's saved native unwind reaches the runtime thread bridge and CRT trace-output path. No file I/O began, so this is before the asset dependency stage. See [r234 guest CPU suspension report](../analysis/m3-r234-guestcpu-suspend-report-20261028.md).

The dump's owner unwind is partly validated; the two waiters unwind only through Windows wait frames. Their guest call chains remain unverified. No runtime behavior fix has been applied yet. The next focused change is cooperative guest-thread suspension through the guest CPU scheduler, with a regression test for suspend, queued progress, and resume before another AOT route.

The r234 run ended on a black post-difficulty frame. It did not show a verified `NOW LOADING` screen or a mission frame. A separate r233 DirectSound list crash, earlier title DCF4 waits, and expensive CPU raster work remain distinct issues. Preserve AOT execution, controller mapping, guest fences, and rasterizer `1ea1871`.

## Storage and retained working set

Latest scan: **64.675781 GiB allocated**, **1,284.616413 GiB logical**, 74,960 files; C: had **26.963 GiB free**. `iso` accounts for 42.27 GiB allocated; `local-tools` for 22.24 GiB. A current exact-path cleanup manifest is [here](../analysis/current-cleanup-manifest-20261028.md). This pass reclaimed **0 bytes**: the duplicate Ghidra removal was blocked by automatic deletion policy, and sparse BMP compression had no measurable benefit. The incremental build cache, dirty source checkouts, original game data, saves, and dump-matched symbol bundles remain preserved.

## Most useful reports

- [r234 guest CPU suspension diagnosis](../analysis/m3-r234-guestcpu-suspend-report-20261028.md)
- [r150–r153 exact-bundle unwind review](../analysis/m3-dump-unwind-review-r150-r153-20261028.md)
- [r227–r229 read/plateau evidence](../analysis/m3-read-target-mode2-r227-r229-20261028.md)
- [Storage cleanup manifest](../analysis/current-cleanup-manifest-20261028.md)

Older run reports remain historical evidence; use this index before restarting a theory.
