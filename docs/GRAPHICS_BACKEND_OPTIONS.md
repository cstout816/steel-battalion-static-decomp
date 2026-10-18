# Graphics Backend Decision Record

**Status:** Research complete; implementation approval required  
**Current milestone:** Milestone 3, Boot and Compatibility  
**Static recompilation architecture:** Retained. The options below change only how translated NV2A rendering is produced; none replaces the project with full-system emulation.

## Evidence from the current build

- The observed Steel Battalion startup workload writes NV2A pushbuffers. The runtime scan routes decoded methods into `nv2a_pb_exec_method()` and its partial CPU rasterizer.
- A clean, untraced 90-second run remained on the CAPCOM splash, reported 27 flips and about 0.44 guest FPS near the end, and measured about 16 million pixel writes across the captured period.
- A temporary timing probe measured 2.18–2.40 seconds inside `raster_batch()` for each sampled splash frame after the initial frame. The instrumented source was restored and the clean Release target rebuilt.
- The runtime already contains a Windows D3D8 compatibility layer backed by D3D11, an NV2A vertex-microcode-to-HLSL compiler in `src/d3d/d3d8_vsh.c`, and a combiner-to-HLSL path in `src/d3d/d3d8_combiners.c`.
- The standalone `src/nv2a/nv2a_pgraph_d3d11.c` translator is not wired to the normal pushbuffer path. It assumes five-word screen-space vertices and an optional fixed texture lookup for a reference menu. It cannot accept the observed game path as-is.
- In the captured startup run, the executor reported 52 vertex-program batches / 208 vertices and attributes in slots `v0`–`v15`. It observed texture state in 51 batches, but reported no batches with a usable texture stage; successful texture sampling is not established.
- No renderer option has reached title-screen parity, and no runtime option is validated for Steel Battalion gameplay.

## Options

| Option | What it would do | Fit with current requirements | Main work and risk |
| --- | --- | --- | --- |
| **A. Integrate the existing D3D11 path as an interim boot renderer** | Keep the pushbuffer decoder and guest state interpretation, then submit equivalent geometry/state through the existing D3D11 device and shader helpers. Keep a software fallback for image comparisons. | Reuses the checked-out XboxRecomp implementation and stays within the static recompilation architecture. | Uses D3D11 during the first hardware-rendered boot path, while the requested final API is D3D12. Needs guest texture/surface synchronization, PGRAPH-to-device state mapping, and image parity evidence. Existing helpers are not proven complete for this title. |
| **B. Implement a Direct3D 12 NV2A raster backend** | Preserve the decoder and state model, but build a native D3D12 renderer and shader pipeline. | Matches the requested target graphics API directly. | Largest renderer implementation and validation effort; the existing D3D11 device code is not directly reusable as a D3D12 device. Pixel, depth, texture, blend, and surface behavior must be validated before boot claims. |
| **C. Integrate a Vulkan NV2A renderer** | Reuse or adapt a Vulkan PGRAPH renderer while retaining the static-recompiled CPU/kernel path. | Vulkan is viable on the target GPU and could use existing community NV2A work. | The upstream xemu project is GPL-2, while the local XboxRecomp guidance prohibits porting GPL code. Direct reuse requires an explicit licensing and distribution review; a fresh Vulkan backend is still substantial work. This is not permission to package or launch xemu as the game runtime. |

## Recommended decision

Approve **Option A as a temporary, isolated boot-path experiment** only if D3D11 is acceptable as an interim renderer. It has the shortest route to compare hardware raster output against the current software path using code already in the chosen runtime. This would not satisfy the final D3D12 graphics requirement; the project would keep that requirement open and record the remaining migration work. The Xbox x86 code would remain statically translated, and the NV2A command stream would remain handled by compatibility code.

If D3D11 is not acceptable even for an interim boot path, Option B is the aligned choice. Option C should not proceed without the project-wide license decision and review described above. No implementation starts until one option is approved.

## Validation gates after approval

1. Keep the software renderer available as the reference path.
2. Compare identical guest frames at 640×480 before changing resolution or effects.
3. Verify clear, depth, blend, texture sampling, vertex-program outputs, and guest framebuffer/surface updates independently.
4. Measure frame time and image differences across the splash and title screen; do not infer gameplay compatibility from the intro.
5. Advance no graphics or boot progress bars until a repeatable title-screen run and the corresponding feature behavior are verified.
