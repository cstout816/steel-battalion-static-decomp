# r271 DCF4 outer-loop trace source manifest

Generated game code remains local under `iso/local-analysis`; do not commit or publish it.

- Source: `iso/local-analysis/xboxrecomp-generated-xpp-untraced-current/gen/recomp_0015.c`
- Guest function: `sub_002173A0`, range `0x002173A0–0x00217477`
- Baseline SHA-256 (the r270 source used to build the exact r270 dump bundle): `E33AFEECB68995C4C31DB65406E3E87A855864127F67183941D8F5A5F2D733E7`
- Edited SHA-256: `02DE12F904FF5909615229F80BEE3DF6F5D43DB149B3CFCC72BC46AFED662201`
- Activation: `RECOMP_SB_DCF4_GATE_TRACE=1` enables this trace and the existing `[DCF4-GATE]` trace.
- `[DCF4-OUTER]`: at each completed outer iteration, records caller/object/owner, object flags from `owner+0x100`, which child helpers ran, each child return value, the aggregate return, and whether guest code takes the loop edge. Hard cap: 2,048 rows, then one cap row.
- `[DCF4-OUTER-POLL]`: when the existing flag poll at guest `0x00217410` runs, records the object flag value on the first iteration and each 256th iteration. Hard cap: 64 rows, then one cap row.
- `tools/Start-ProducerTrace.ps1` counts both trace and cap markers. Run output is still bounded by the 64 MiB supervisor budget.
- Behavior: only opt-in local counters and diagnostics; no guest return, test, loop edge, synchronization, AOT dispatch, controller, or rasterizer behavior was intentionally changed.

The exact edited source remains in the workspace at the source path above. The r270 source hash and patch description needed to reproduce this edit are retained here; preserve all generated source outside public commits.
