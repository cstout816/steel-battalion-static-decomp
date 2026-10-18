# Vulkan Graphics Migration Map

## Decision

Vulkan is the single selected host graphics backend. This document maps the current implementation and the remaining route to GPU-rendered Steel Battalion frames. The migration is incomplete; no alternative backend is being developed.

## Current paths

| Layer | Current implementation | Evidence | Status |
|---|---|---|---|
| Windows Xbox D3D8 compatibility | `src/d3d/CMakeLists.txt` builds `d3d8_device.c`, resources, shaders, states, combiners, and VSH against D3D11, DXGI, and D3DCompiler | The layer documentation and CMake file identify the Windows D3D11 implementation | Present in the build; startup traces reviewed so far do not show it initializing for Steel Battalion |
| NV2A PGRAPH translator | `src/nv2a/nv2a_pgraph_d3d11.c`; `nv2a_core.c:pgraph_method()` calls it for PGRAPH methods | The NV2A target compiles this source and `pgraph_method()` dispatches to it | D3D11 code exists; the observed Steel Battalion pushbuffer scan does not dispatch through this route |
| Steel Battalion pushbuffer execution | `src/kernel/nv2a_pb_scan.c` parses guest packets and calls `nv2a_pb_exec_packet()`; `nv2a_pb_exec.c` interprets VSH/combiner state and rasterizes on CPU | Source call path plus startup traces and rasterizer timing capture | Observed guest draw path; software rasterizer is very slow and incomplete |
| Guest framebuffer presentation | `src/video/fb_present.c` snapshots guest memory and calls `xbox_vulkan_presenter_present()` | The bounded run selected the RTX 4070 SUPER, created the swapchain, and successfully presented the copied image | Vulkan host presentation verified; no NV2A scene rendering |

The XboxRecomp umbrella target links `xbox_kernel`, `xbox_d3d8`, `xbox_nv2a`, and `xbox_video`. Build inclusion alone does not establish which library handled a specific Steel Battalion draw. The latest examined Vulkan startup logs show Vulkan presentation and no D3D8/D3D11 initialization messages. Absence of those log messages is limited evidence; runtime instrumentation is needed to prove or rule out calls through those paths.

## Implementation boundary

The most direct path for the observed game workload is the decoded draw state in `nv2a_pb_exec.c`. The CPU vertex interpreter and software rasterizer provide a behavior reference. A Vulkan implementation can consume decoded vertices, texture data, combiner state, surface state, and depth/blend state at that boundary. It must preserve the guest's Xbox x86 execution and kernel/runtime behavior.

The current framebuffer presenter is a separate display path. It copies an already completed CPU framebuffer into host staging memory, then uses Vulkan to blit it to a swapchain image. It cannot be counted as a Vulkan NV2A renderer. A production path should submit guest draws to Vulkan and keep the rendered image on the GPU through presentation; a readback and re-upload loop would add overhead and is suitable only for diagnostics.

## Migration order

1. Keep the CPU implementation as a correctness reference and add explicit instrumentation to identify which guest graphics paths execute.
2. Define a backend-neutral decoded draw packet at the `nv2a_pb_exec` boundary. Include the guest surface, clip/viewport, vertex output, texture sources, combiner state, depth, blending, and primitive topology.
3. Create one Vulkan device/resource owner shared by guest rendering and presentation. Keep the Vulkan API fixed; do not add runtime backend selection.
4. Implement the first supported guest clear and untextured draw with matching clipping, color/depth writes, and ordering. Compare Vulkan output against the CPU reference using captured guest state.
5. Add textures, vertex-program semantics, combiners, depth/blend details, and cache/synchronization coverage until the observed Steel Battalion frame has matching pixels.
6. Present the Vulkan-rendered image directly through the Vulkan swapchain, then measure frame time and pacing.
7. Audit the Windows D3D8 compatibility path and PGRAPH D3D11 translator against actual title call traces. Replace any required calls with the same Vulkan device/resource path before claiming the Windows runtime has completed its Vulkan migration.

## Licensing boundary

No xemu Vulkan renderer source has been copied. xemu's PGRAPH implementation is a behavior reference. Its shader-generation path includes GPL-licensed files and transitive compiler dependencies, so independently authored renderer/shader code or a separately approved license strategy is required before source reuse. See [VULKAN_REUSE_AUDIT.md](VULKAN_REUSE_AUDIT.md).

## Verified and unverified

- Verified: Vulkan loader/device selection, RTX 4070 SUPER selection, 640×480 swapchain creation, and successful presentation of the copied framebuffer.
- Verified: Steel Battalion pushbuffer packets reach the CPU executor under the diagnostic startup configuration; CPU rasterization is a measured performance bottleneck in the captured logo workload.
- Unverified: Vulkan guest draw execution, Vulkan-rendered NV2A pixels, complete D3D8/PGRAPH runtime call coverage, title-screen boot, audio, controller behavior, and campaign playability.
