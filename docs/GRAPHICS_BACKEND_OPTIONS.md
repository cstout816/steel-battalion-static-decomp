# Graphics Backend Decision Record

**Status:** Vulkan selected as the primary NV2A backend for the best available performance path; direct D3D12-versus-Vulkan Steel Battalion performance is not measured
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
| **A. Integrate the existing D3D11 path as an interim boot renderer** | Keep the pushbuffer decoder and guest state interpretation, then submit equivalent geometry/state through the existing D3D11 device and shader helpers. Keep a software fallback for image comparisons. | Reuses the checked-out XboxRecomp implementation and stays within the static recompilation architecture. | D3D11 is not the selected performance backend. Needs guest texture/surface synchronization, PGRAPH-to-device state mapping, and image parity evidence. Existing helpers are not proven complete for this title. |
| **B. Implement a Direct3D 12 NV2A raster backend** | Preserve the decoder and state model, but build a native D3D12 renderer and shader pipeline. | Native Windows API and fits the requested target. | Current prototype is narrow and performs synchronous full-surface transfers. It has no visible game-texture parity or performance result. |
| **C. Integrate/adapt the xemu Vulkan NV2A renderer** | Reuse the NV2A PGRAPH renderer while retaining the statically recompiled CPU/kernel path; do not run the Xbox machine emulator. | Most mature existing hardware-accelerated NV2A path found, with ongoing upstream optimization and a Steel Battalion Vulkan community branch. The renderer source examined declares LGPL-2.1-or-later, so component-by-component license review and compliance are required. | Integration boundaries and full dependency licenses need review. The community Steel Battalion fork reports inconsistent campaign performance, and it provides no matched Vulkan-versus-D3D12 benchmark. |

## Recommended decision

**Select Vulkan as the primary NV2A backend for the best available performance path on Windows and the RTX 4070 Super.** This is an evidence-based architecture choice, not a measured API-level victory. No public matched Steel Battalion capture compares Vulkan and D3D12. The reason to choose Vulkan is implementation maturity: xemu has a real, continually optimized NV2A Vulkan PGRAPH renderer, and the Steel Battalion community fork has a Vulkan variant. The local D3D12 work is only an experimental startup-draw prototype with synchronous full-surface upload/readback; it is not a complete or performant game renderer. The measured software bottleneck is 2.18–2.40 seconds in `raster_batch()` per sampled splash frame, so replacing CPU pixel work and avoiding CPU/GPU synchronization are the dominant performance requirements.

Current upstream XboxRecomp v0.14.0 documents D3D8-to-D3D11 on Windows; it does not provide a ready D3D12 NV2A backend. Its runtime describes the xemu-derived NV2A component as LGPL-2.1-or-later. The examined xemu Vulkan renderer source also carries an LGPL-2.1-or-later header. Reuse is therefore plausible for those specific files, subject to auditing every copied file, dependencies, notices, modification/source obligations, and the final distribution model; do not characterize the whole xemu repository as LGPL or import its full emulator. The static-recompiled CPU and kernel architecture remains unchanged, and no emulator process is part of the chosen runtime.

The community [Xemu-SB-VK fork](https://github.com/quizerno/Xemu-SB-VK) reports that original Steel Battalion performance varies between users and campaigns; it does not publish an API comparison. That is a warning not to treat a Vulkan build as proof of campaign compatibility. The decision is that Vulkan currently offers the strongest performance potential because it lets this project build on an existing NV2A GPU renderer instead of developing a D3D12 renderer from scratch. Direct D3D12-versus-Vulkan speed remains **unverified**. If an equivalent D3D12 path is later available, compare both on identical 640×480 guest captures and representative campaign scenes before calling either faster.

The local D3D12 prototype remains useful as a correctness/reference experiment. It verifies a synthetic triangle and byte-identical output for two synchronized startup passes (opaque-black depth pass and following transparent textured pass), but no visible texture, title-screen parity, or speedup. It is not the selected performance backend. D3D11 stays a compatibility/interim path only.

### Experimental patch sequence

The D3D12 prototype is isolated from the local XboxRecomp checkout as two patches against XboxRecomp v0.13.1 commit `193e299`. Apply `patches/xboxrecomp-v0.13.1-d3d12-flat-triangle-experimental.patch` first, then `patches/xboxrecomp-v0.13.1-d3d12-strip-depth-experimental.patch`. The second patch adds a narrow six-vertex strip path, depth preservation through the software reference, and an opt-in transformed-draw capture hook. Both patches are experimental and opt-in; they do not provide a complete NV2A renderer. The second patch applies cleanly after the first and passes `git diff --check` in a clean temporary baseline. The Windows target build and synchronized captures were verified from the corresponding local dependency checkout.

### Research sources

- [NVIDIA Vulkan Dos and Don'ts](https://developer.nvidia.com/blog/vulkan-dos-donts/) — Vulkan can reduce overhead when the application parallelizes recording, pipeline creation, and allocation; results depend on implementation.
- [Khronos Vulkan profiling guide](https://docs.vulkan.org/guide/latest/profiling.html) — emphasizes measuring CPU work, GPU timestamps, batching, and synchronization rather than assuming API submission time equals GPU time.
- [NVIDIA Nsight Graphics](https://developer.nvidia.com/nsight-graphics) — profiles both Direct3D 12 and Vulkan for a future matched-workload comparison.
- [XboxRecomp upstream](https://github.com/sp00nznet/xboxrecomp) — current README documents Windows D3D11, not a ready D3D12 NV2A path; its `xbox_nv2a` runtime component is described as xemu-derived LGPL-2.1+.
- [xemu Vulkan renderer source](https://github.com/xemu-project/xemu/blob/master/hw/xbox/nv2a/pgraph/vk/blit.c) — examined renderer source identifies LGPL-2.1-or-later licensing; each reused file still needs review.
- [Microsoft D3D12 rasterizer-ordered views](https://learn.microsoft.com/en-us/windows/win32/direct3d12/rasterizer-order-views) and [Khronos Vulkan fragment shader interlock](https://registry.khronos.org/vulkan/specs/latest/man/html/VK_EXT_fragment_shader_interlock.html) — ordered pixel access options that can support blending/order-sensitive legacy rendering; availability and cost must be measured on the target device.
- [Xemu-SB-VK project notes](https://github.com/quizerno/Xemu-SB-VK) — community Steel Battalion fork and its stated Vulkan/non-Vulkan limitations.
- [xemu NV2A Vulkan renderer](https://github.com/xemu-project/xemu/tree/master/hw/xbox/nv2a/pgraph/vk) — reference implementation for research; licensing and project policy constrain direct reuse.

## Validation gates

1. Keep the software renderer available as the reference path.
2. Compare identical guest frames at 640×480 before changing resolution or effects.
3. Verify clear, depth, blend, texture sampling, vertex-program outputs, and guest framebuffer/surface updates independently.
4. Measure CPU and GPU frame time on identical splash and title-screen captures; compare frame pacing and image differences.
5. Do not infer campaign performance from the intro or advance graphics/boot progress bars until a repeatable title-screen run and the corresponding behavior are verified.
6. Before Vulkan integration, create a file-level license inventory and an adapter plan that reuses only NV2A graphics components; retain software captures as the image reference. Later compare Vulkan and D3D12 only if both can execute the same guest work without readback stalls.

The user asked for the best-performing native NV2A backend after research. Vulkan is selected for its mature reusable NV2A renderer and performance potential; actual comparative speed is not measured. Limited renderer research remains within Milestone 3. Do not advance the milestone until the game reaches a verified title screen with rendering, audio, and input checked.
