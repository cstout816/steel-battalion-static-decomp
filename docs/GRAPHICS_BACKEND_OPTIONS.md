# Graphics Backend Decision Record

**Status:** D3D12 selected as the primary Windows backend; comparative game-workload performance is not yet verified
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

**Select native Direct3D 12 as the primary Windows NV2A backend.** Research does not establish a universal performance winner between D3D12 and Vulkan on NVIDIA GPUs, nor a controlled Vulkan advantage for Steel Battalion. Both APIs expose explicit command submission and ordered per-pixel mechanisms (D3D12 ROVs and Vulkan fragment shader interlock) relevant to emulating NV2A render ordering. The decisive measured bottleneck in this project is that the current software rasterizer spends 2.18–2.40 seconds per sampled splash frame in `raster_batch()`. Replacing that CPU pixel loop with a correct, batched hardware renderer is expected to matter far more than an API-wide difference that has not been measured here.

D3D12 is the selected primary API for this Windows-only application and RTX 4070 Super: it is native to the target, matches the requested Windows graphics stack, and avoids porting xemu's GPL-licensed Vulkan renderer against the checked-out XboxRecomp contribution policy. The Steel Battalion community fork [Xemu-SB-VK](https://github.com/quizerno/Xemu-SB-VK) is useful controller and Vulkan research, but its README says original Steel Battalion performance is inconsistent and does not publish a controlled Vulkan-versus-D3D12 benchmark. A new Vulkan backend could be considered only if a matched capture benchmark shows a reproducible performance win while preserving output parity. The current evidence therefore supports D3D12 as the best-supported performance path for this project's target, but does not prove D3D12 is faster than Vulkan.

This is a reasoned architecture choice, **not a measured API benchmark**. The local prototype verifies only a synthetic triangle and has no game-frame parity or speedup evidence. No usable D3D12 game renderer is verified. The Windows static-recompilation CPU/kernel architecture stays unchanged. D3D11 remains an interim-only option and is not the selected final backend.

### Research sources

- [NVIDIA Advanced API Performance: Descriptors](https://developer.nvidia.com/blog/advanced-api-performance-descriptors/) — discusses resource-binding performance practices for Direct3D 12 and Vulkan.
- [NVIDIA Nsight Graphics](https://developer.nvidia.com/nsight-graphics) — supports profiling Direct3D 12 and Vulkan applications, enabling a later matched-workload comparison.
- [Microsoft D3D12 rasterizer-ordered views](https://learn.microsoft.com/en-us/windows/win32/direct3d12/rasterizer-order-views) and [Khronos Vulkan fragment shader interlock](https://registry.khronos.org/vulkan/specs/latest/man/html/VK_EXT_fragment_shader_interlock.html) — ordered pixel access options that can support blending/order-sensitive legacy rendering; availability and cost must be measured on the target device.
- [Xemu-SB-VK project notes](https://github.com/quizerno/Xemu-SB-VK) — community Steel Battalion fork and its stated Vulkan/non-Vulkan limitations.
- [xemu NV2A Vulkan renderer](https://github.com/xemu-project/xemu/tree/master/hw/xbox/nv2a/pgraph/vk) — reference implementation for research; licensing and project policy constrain direct reuse.

## Validation gates

1. Keep the software renderer available as the reference path.
2. Compare identical guest frames at 640×480 before changing resolution or effects.
3. Verify clear, depth, blend, texture sampling, vertex-program outputs, and guest framebuffer/surface updates independently.
4. Measure CPU and GPU frame time on identical splash and title-screen captures; compare frame pacing and image differences.
5. Do not infer campaign performance from the intro or advance graphics/boot progress bars until a repeatable title-screen run and the corresponding behavior are verified.

No implementation starts until the user approves moving from research into renderer work.
