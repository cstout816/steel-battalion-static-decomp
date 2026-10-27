# Steel Battalion loader callback and mode-1 scheduling trace (r128–r130)

## Finding

The r130 trace supports a concrete compatibility-layer cause for the `NOW LOADING` plateau. The loading scheduler does not begin its mode-1 worker or mode-1 file-preload path. Its readiness helper calls the XBE's `ObReferenceObjectByHandle` import (ordinal 246). The current kernel bridge returns `STATUS_SUCCESS` while writing a null object through the output parameter. The guest helper consequently selects `STATUS_PENDING` (`0x103`), and the scheduler skips mode 1. This happens before a mode-1 file dependency can be requested.

This is a supported cause for the loader not starting. It is not yet a verified fix or a first-mission boot. No compatibility behavior was changed in these runs.

## Runs and provenance

| Run | Diagnostic process | Executable SHA-256 | PDB SHA-256 | Outcome |
|---|---:|---|---|---|
| `m3-new-pilot-pairtrace-r128-20261027` | 138040 | `DB5C94F6502D19AFDE428BBC790AD6924E18C33E8C75851C005D643BC4D24092` | `FF6C8087AF5B82E615DB0C4656C4EC24BA61B6A5DA8A46F29F0364648F6A25A7` | New-pilot route reached `NOW LOADING`; no first mission frame. |
| `m3-new-pilot-worker-pointer-r129-20261027` | 137680 | `DB5C94F6502D19AFDE428BBC790AD6924E18C33E8C75851C005D643BC4D24092` | `FF6C8087AF5B82E615DB0C4656C4EC24BA61B6A5DA8A46F29F0364648F6A25A7` | New-pilot route reached `NOW LOADING`; exact-child plateau watchdog stopped it. |
| `m3-helper-arg-r130-20261027` | 133252 | `BA5B98EDBDFAED3FDFE8B4FDDA018241FAFCEB6E57A885175BDB0811DEFA01D0` | `5962815525D5E68A376493E7915B2B69798BDB32ED562D25313BB6A763E204D6` | Side-by-side diagnostic build reached `NOW LOADING`; exact-child watchdog stopped it after a 120-second plateau. |

r130 started 2026-10-27 17:49:14 CDT. It used the AOT-generated sources in `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen`, source XBE `iso/local-analysis/default.xbe` (SHA-256 `1D4E006A2EAB0694B32562C453FDEB4C3B077EEC8C6ED6B75BD6FE4059D8200A`), and the existing save root `iso/local-analysis/saves-m3-route-file-read-copy-20261023`. The diagnostic-only generated-source change was in `recomp_0008.c` (SHA-256 `E3079DA4040B7CC07161A03EA808CE1210727D8EACF5FE9D48BCF6C74E5F65F2`): bounded before/after logging around the indirect callback. It did not change guest state or call behavior. The run manifest reports zero dropped stdout/stderr lines, complete marker counts, and a triggered 120-second loader-plateau watchdog. The run's last captured frame, `frame.bmp00022.bmp`, visibly shows `NOW LOADING`; the first mission frame was not reached.

## Correlated guest and host evidence

1. `sub_0001DAA0` was called from guest `0x000E0109` for mode 0. `[LOAD-OBJECT-INIT]` recorded global `0x00311CC8` changing from `0` to `0x48000078`. The associated worker was TID 137808 at entry `0x00017E40`, mode 0, branch `preload-mode0`. The initialization trace recorded `thread_handle=0`.
2. At r130 ticks `390487984` onward, guest `sub_00017E80` (return site `0x00017E90`, TID 134776) entered `sub_00191451`. The new pre-call record showed `object_pre=0x48000078`, global `0x00311CC8=0x48000078`, output state at `0x00311BA4`, callback thunk `0xFE0000A8`, and context `0x00740040`.
3. The parsed Steel Battalion XBE import table maps guest thunk address `0x0025D188` to ordinal 246, `ObReferenceObjectByHandle`; `0x0025D180` maps to ordinal 250, `ObfDereferenceObject`. At runtime those slots resolve to `0xFE0000A8` and `0xFE0000A0`, respectively. These are valid kernel imports, not unresolved game-code indirect targets; no code seeding or hook was used.
4. In `local-tools/xboxrecomp/src/kernel/kernel_bridge.c`, `bridge_ObReferenceObjectByHandle` takes the guest output pointer, unconditionally writes zero to it, then sets `g_eax=0` (`STATUS_SUCCESS`). In r130 the output pointer was the stack argument slot `0x00F7FE7C`: after the callback, `object_post=0` while global `0x00311CC8` remained `0x48000078`. This reconciles r129's hardware watch, which observed the initial global write but no later global clear. The callback zeroed the copied stack argument, not the global.
5. The guest helper then logged `valid=0`, selected state `0x103`, and returned false. At scheduler gate `0x00101FC0`, every mode-1 request had `helper_result=0`, `decision=skip`, `active_mode=0`, `load_index=1`, and `load_stage=0`. r130 emitted 81 helper-callback/state rows and 81 mode-1 scheduler-gate rows. The first was tick `390487984`; the final callback/gate rows were at tick `390612687`.
6. The mode-1 path did not start: `[FILE-PRELOAD-ENTER]`, `[FILE-PRELOAD-RETURN]`, `[FILE-COPY-ENTER]`, and `[FILE-COPY-RETURN]` each counted zero. `[LOAD-OBJECT-INIT]` and `[PRELOAD-WORKER-SCHEDULE]` each counted one, both for mode 0. Thus the first blocked dependency is object resolution/readiness in the runtime compatibility bridge, ahead of any mode-1 file read. r130's `[FILE-IO]` completion marker count was zero, so this run does not establish completion of mission assets; the recorded file open/close activity is startup/menu I/O only.
7. The mode-2 scan still repeated state `0/0/0`, pair `0x011E2E00/0`, range `2..11`, `last_index=28`, result 0. The scan end index is not a resource ID. Graphics/event activity continued (`[DCF4-CB]` 18,509; `[NV2A-TICK]` 241; `[RASTER-PERF]` 347), so this is not evidence of the historical unsignaled DCF4 wait. Raster work may be expensive but is not supported as the cause of the mode-1 gate skip.

## Trace limits and remaining validation

- r130 helper/callback and scheduler probes are capped at 2,048 each; 81 callback/state and 81 scheduler records were emitted. The callback boundary probe records arguments before and after the callback but is not a general kernel object dump.
- The r130 manifest reports `[FILE-IO]=0`; therefore no mission asset completion records exist in that run. Mode 1 was not scheduled, so a first missing or pending mission file cannot be named from this trace.
- The XBE parser JSON is retained beside the r130 run as `xbe-analysis.json`; the original XBE remains outside version control. No XBE/XDK content was added to the repository.
- DCF4 producer-stage tracing was not enabled: callbacks signaled and NV2A counters advanced, with no separate unsignaled event wait. Guest fences, controller mapping, AOT execution, and rasterizer commit `1ea1871` were preserved.
- The `ObReferenceObjectByHandle` return object must be represented safely in the guest address space and have semantics appropriate for the thread/preload readiness fields. Returning the tagged host-handle token as a guest pointer would be invalid under the 64 MB guest mapping. That object-model implementation and its effect on mode-1 scheduling remain unverified; no speculative pointer substitution was made.
- The campaign, first mission frame, in-mission audio/input/save behavior, and stable 60 FPS remain unverified.

## Next action and progress

Implement or reuse a guest-visible thread-object representation for the existing handle path, preserving the guest's fence and thread semantics. Then rebuild a side-by-side diagnostic executable, replay the same new-pilot route, verify that the mode-1 worker is scheduled, correlate its actual file-completion records and thread wait state, and stop at the first visibly verified mission frame. Apply no rendering, timing, controller, or DCF4 changes as part of that fix.

Progress: overall `██░░░░░░` 2/8; XBE/decompilation `██░░` 2/4; boot/compatibility `████░` 4/5; loader-cause tracing `████` 4/4 (cause supported; fix not verified); startup rendering `██░░` 2/4; controller `██░` 2/3; audio/DSP `█░` 1/2; first mission frame `░` 0/1; stable 60 FPS `░` 0/1.
