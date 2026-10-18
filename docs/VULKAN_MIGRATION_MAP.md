# Vulkan Graphics Migration Map

## Decision

Vulkan is the single selected host graphics backend. This document maps the current implementation and the remaining route to GPU-rendered Steel Battalion frames. The migration is incomplete; no alternative backend is being developed.

## Current paths

| Layer | Current implementation | Evidence | Status |
|---|---|---|---|
| Windows Xbox D3D8 compatibility | `src/d3d/CMakeLists.txt` builds `d3d8_device.c`, resources, shaders, states, combiners, and VSH against D3D11, DXGI, and D3DCompiler | The layer documentation and CMake file identify the Windows D3D11 implementation | Present in the build; startup traces reviewed so far do not show it initializing for Steel Battalion |
| NV2A PGRAPH translator | `src/nv2a/nv2a_pgraph_d3d11.c`; `nv2a_core.c:pgraph_method()` calls it for PGRAPH methods | The NV2A target compiles this source and `pgraph_method()` dispatches to it | D3D11 code exists; the observed Steel Battalion pushbuffer scan does not dispatch through this route |
| Steel Battalion pushbuffer execution | `nv2a_pb_exec.c` interprets VSH/combiner state; an exact splash-logo draw now calls `xbox_vulkan_raster_textured_triangles()`, while other draws use the CPU rasterizer | The seeded startup log reports `[Vulkan] textured logo fade completed at 640x480`; it later stalls at three flips | Narrow Vulkan draw submission verified; pixels, general NV2A coverage, and progression are not |
| Guest framebuffer presentation | `fb_present.c` snapshots guest memory and calls `xbox_vulkan_presenter_present()` | The bounded run selected the RTX 4070 SUPER, created the swapchain, and presented a copied image | Vulkan host presentation verified; presenter still displays the guest-memory copy |

The XboxRecomp umbrella target links `xbox_kernel`, `xbox_d3d8`, `xbox_nv2a`, and `xbox_video`. Build inclusion alone does not establish which library handled a specific Steel Battalion draw. The latest examined Vulkan startup logs show Vulkan presentation and no D3D8/D3D11 initialization messages. Absence of those log messages is limited evidence; runtime instrumentation is needed to prove or rule out calls through those paths.

## Implementation boundary

The direct path for the observed game workload is the decoded draw state in `nv2a_pb_exec.c`. The CPU vertex interpreter and software rasterizer provide a behavior reference. The first project-owned Vulkan slice recognizes only the captured 640x480 DXT1 splash-logo state, supplies transformed screen vertices and a decoded RGBA texture, and reads the render result back into the guest surface. It does not yet cover arbitrary decoded vertices, combiners, formats, clipping, depth/blend combinations, or subsequent guest draws. It preserves the guest's Xbox x86 execution and kernel/runtime behavior.

The concrete extraction point is `raster_batch_program()`: it transforms the current `s_gpu.idx[]` vertices once into `s_xf[]` (`Nv2aVshOutput`), then dispatches triangle, strip, fan, quad, and quad-strip topology to `raster_xf_clipped()`. Each vertex contains screen/depth position, two diffuse outputs, fog, and four texture-coordinate outputs. The global decoded state supplies the color surface and pitch, clip rectangle, texture sources, combiner words, depth test/write, blending, and alpha test. The `XfTri` structure then packages the three transformed vertices and interpolation/raster bounds used by the CPU pixel loop. A backend-neutral packet should capture the transformed vertex array plus this per-draw state before topology expansion; Vulkan can expand topology and preserve clipping/interpolation while the CPU path remains the pixel-reference implementation.

The framebuffer presenter copies guest memory into a Vulkan image for swapchain presentation. The new splash draw also renders into that Vulkan image, then reads the result back into guest memory so the following CPU path sees it. This is an integration and fidelity probe; the host-side readback/re-upload loop is not a performance-ready frame architecture.

## Migration order

1. Completed narrow Vulkan/CPU logo comparison at six nonzero fade states. Continue capturing matched states as the draw path expands; the guest still has a later queue-fence lag.
2. Generalize the handoff at `raster_batch_program()` to carry transformed `Nv2aVshOutput` vertices, topology, surface/pitch, clip/viewport, texture sources, combiner words, depth, blending, and alpha-test state.
3. Add arbitrary clears and untextured draws, then textures, vertex-program semantics, combiners, depth/blend details, and cache/synchronization coverage with CPU-reference comparisons.
4. Keep one Vulkan device/resource owner for guest rendering and presentation; keep the Vulkan API fixed and avoid a runtime selector.
6. Present the Vulkan-rendered image directly through the Vulkan swapchain, then measure frame time and pacing.
7. Audit the Windows D3D8 compatibility path and PGRAPH D3D11 translator against actual title call traces. Replace any required calls with the same Vulkan device/resource path before claiming the Windows runtime has completed its Vulkan migration.

## Licensing boundary

No xemu Vulkan renderer source has been copied. xemu's PGRAPH implementation is a behavior reference. Its shader-generation path includes GPL-licensed files and transitive compiler dependencies, so independently authored renderer/shader code or a separately approved license strategy is required before source reuse. See [VULKAN_REUSE_AUDIT.md](VULKAN_REUSE_AUDIT.md).

## Verified and unverified

- Verified: Vulkan loader/device selection, RTX 4070 SUPER selection, 640×480 swapchain creation, and successful presentation of the copied framebuffer.
- Verified: Steel Battalion pushbuffer packets reach the CPU executor under the diagnostic startup configuration; CPU rasterization is a measured performance bottleneck in the captured logo workload.
- Exact pixel equality is verified across six nonblack 640×480 splash fade frames: Vulkan `frame_00003.bmp`–`frame_00008.bmp` match CPU-reference `frame_00005.bmp`, `frame_00007.bmp`, `frame_00009.bmp`, `frame_00011.bmp`, `frame_00013.bmp`, and `frame_00015.bmp` respectively by full-file SHA-256. The first and last matched hashes are `8D9944BEA318126E177D0CAE585D0344F4852033BD9D5F58DC65D21451D8A64D` and `AC9273FF3FCD34D083A05FD42CA3C09CD0B1AE66C5740FEFD0B3A2B6B08D134D`. Captures are ignored and local, not distributed game images. This verifies parity for the narrow splash draw at six states, not general NV2A rendering.
- The bounded Vulkan capture runs explicitly enabled modeled vblank (`RECOMP_VBLANK=1`) and title-event shadows (`RECOMP_TITLE_KEVENTS=1`). The event at `0x0021DCE4` reached signal state 1, and the guest device query advanced. The 120-second repetition reached 41 flips and captured the CAPCOM splash. At its watchdog the guest queue fence on `0x80003000` remained 12 behind (completed `0xAB`, submitted `0xB7`, threshold 8), USER PUT=`0x128A0`, GET=`0x11E08`; GET had continued advancing from `0x9ED0` at 60 seconds. This is an outstanding queue lag while startup progresses, not proof of a permanent GPU deadlock. It does not reach the title screen.
- A later 45-second bounded Vulkan launch used a dedicated watchdog log stream because concurrent guest logging can delay reports written to shared `stderr`. The rebuilt target exited through the watchdog with code 3 after 171 flips; sampled NV2A USER PUT and GET were both `0x6AAB8`. Startup read `STRM00.WAV` and `STRM01.WAV`; the guest stack included return address `0x0020EC83`, immediately after a call to `KeWaitForSingleObject` in `sub_0020EC60`. This is a single wait-state sample, not a diagnosis of the boot blocker or proof that either stream played.
- A trace-free Release build removed generated function-trace hooks from guest objects while preserving the current dispatch table. In a 180-second Vulkan run, the CAPCOM logo faded to black after 51 flips. At the watchdog, completion at `0x80003000` was `0xD9` versus submitted `0xE5` (12 outstanding; guest threshold 8), USER PUT=`0x162FC`, GET=`0x15318`. The queue lag recurs without guest function-trace overhead. The Steel Battalion title screen remains unverified; unsupported draws still use the CPU reference rasterizer.
- At the earlier Vulkan run's logo wait, the guest stack was in `sub_0002DB50`, called from `sub_000DFBC0` at return address `0x000DFE7C`. The helper compares its saved value at `0x355730` against an output pair written by `sub_0020F2C0`; the second output at `0x351F5C` is copied from the game's device field at offset `0x2580`. Generated code updates that field in `sub_0020DBC0` only after an indirect callback reports a changed low bit. This is a guest-side device/query wait, not a host vblank counter; the modeled event/vblank run now demonstrates that this sampled wait can progress.
- Unverified: general Vulkan-rendered NV2A pixel correctness outside the exact splash draw, complete D3D8/PGRAPH runtime call coverage, title-screen boot, audio, controller behavior, and campaign playability.
