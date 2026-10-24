# Campaign menu input trace plan

## Static findings

Generated AOT code is local-only under `iso/local-analysis/xboxrecomp-generated/gen/` and must remain out of Git. Review of the current generated code changes how the v14 input results should be interpreted:

- The observed poll callsites `0x000E18D8`, `0x000E290B`, and `0x000E2D10` sit in per-object update routines (`sub_000E1820`, `sub_000E2840`, and `sub_000E2C70`). A positive Main Weapon query skips the secondary `sub_000C8080` poll and continues to `sub_000E2130`; that branch alone does not establish that the menu selection handler accepted the input.
- `sub_000E0780` is a separate object callback. Its `0x000E081F` path queries Main Weapon and, on success, enters `sub_000C35A0` before updating title-transition fields. This is the title prompt handler observed in v14.
- `sub_000E0870` is a state dispatcher. It reads an object index from the caller object, validates it, then dispatches through a state byte at `object_index + 0x000E1794`. Its case-0 branch, when global `0x687484` equals 2, calls `sub_000C8260`, `sub_000C8290`, and `sub_000C82C0` in sequence. Those helpers poll input tuples `(1,6,9)`, `(1,6,8)`, and `(1,6,1)`. When the third helper returns nonzero, the branch enters setup code that calls `0x00191864` and subsequent initialization routines. This is a candidate menu/transition path, but the v14 capture did not log its state byte or helper returns, so it cannot yet be tied to the Campaign screen.

## Correction to v14 interpretation

The v14 trace proves that A reached the XID DMA report and that animation/update pollers ran. It does not prove that a Campaign menu-selection handler rejected A. One `0x000E18D8` result of 1 explains the observed animation update path; the remaining zero results are from these object update callsites. No cause is established for the Campaign-to-pilot transition.

## Next screen-gated diagnostic

Keep the same save folder, AOT executable, USB profile, DCF4 argument/branch tracing, framebuffer stage, raster batch and worker-time samples, DMA PUT/GET, and semaphore target/value. Add logging-only records for:

1. `sub_000E0870` entry: object pointer/index, selected state byte, and transition globals `0x687484`, `0x6BA354`, and `0x6715D8`.
2. The exact return values and caller return sites for `sub_000C8260`, `sub_000C8290`, and `sub_000C82C0`; include the helper's input tuple, raw/snapshot input state, and latch before/after.
3. Entry/exit and return code around the `0x00191864` setup path, plus the state/object values at the next framebuffer sample.
4. A monotonically increasing framebuffer token in the synchronized trace so each image can be compared with the guest state and GPU counters.

Do not alter input mapping, menu state, raster behavior, or fence behavior until one trace connects a delivered input to the relevant dispatcher branch and resulting state change. Do not re-port the existing `1ea1871` rasterizer. Continue until the first mission frame is visually verified.
